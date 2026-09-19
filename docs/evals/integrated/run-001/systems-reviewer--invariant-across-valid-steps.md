## systems-reviewer

**Verdict:** BLOCK

### Blocking
- `projects.py:19-25` (with `projects.py:6`, `billing.py:12-19`) **Restore bypasses the free-plan limit.**
  - Invariant: `README.md:5` says a free user has at most 3 active projects. `create_project` enforces this at `projects.py:6`, and `downgrade_to_free` enforces it at `billing.py:17-19`.
  - Interaction: a free user has 3 active projects and archives one (`archive_project`). `create_project` then passes the check, because 2 are active, and creates a new one. `restore_project` flips the archived project back to `active` with no count check.
  - Why each step looks fine: archiving is always valid. Creating is valid at 2 active. Restoring a project you own that is archived is valid on its own. The limit is checked only in `create_project`, so the third operation never looks at it.
  - Failure: I ran this. The user ends with 4 active projects. The same path defeats a downgrade. After `downgrade_to_free` archives a team user's 5 projects down to 3, the user restores two of them and holds 5 active projects on the free plan. `billing.py:13-14` promises the account is "inside the limit the moment the plan changes", and restore silently undoes that. `upgrade_prompt_needed` would say the limit is hit, while the account is over it and creating still fails.
  - Fix: put the limit check in one function, for example `assert_can_activate(store, user)`. Call it from `create_project`, from `restore_project` before setting `active`, and from any other path that adds an active project. Don't repeat the count check per handler.

- `transfers.py:16` (with `projects.py:6`) **Transfer bypasses the recipient's free-plan limit.**
  - Invariant: same as above. A free user has at most 3 active projects.
  - Interaction: a team user (or any owner) calls `transfer_project` to a free user. The handler checks that the sender owns the project and that the recipient exists. It then sets `owner_id` and never looks at the recipient's plan or active count.
  - Why each step looks fine: the ownership check is correct, the recipient lookup is correct, and reassigning an owner is the documented purpose of the function. The limit lives in a different module, which `transfers.py` doesn't import.
  - Failure: I ran this. A free user with 3 active projects who receives 5 transfers ends with 8 active projects. The transfer path has no limit at all. This is also the natural leave-the-team flow described in the docstring, `transfers.py:7`.
  - Fix: run the same shared limit check against `to_user_id` before reassigning an active project. Decide explicitly what happens to a transfer that would exceed the limit. Reject it, or archive the transferred project on arrival. Archived projects don't count, so they can transfer freely.

### Should fix
- `transfers.py:12-16` **Transfer needs no consent from the recipient, and it consumes the recipient's limited slots.** Any user can push projects onto any other user id. Combined with the free limit, a victim with 0 active projects who receives 3 unsolicited projects gets `PlanLimit` on their next `create_project` until they archive someone else's work. The `NotFound(to_user_id)` at line 15 also tells the caller which user ids exist. I did not confirm how the real service authenticates callers. Add an accept step, or restrict transfers to users who share a team with the sender.

- `projects.py:6-8` **The limit check is a count followed by a write, with no lock.** The real store is Postgres per `models.py:20`, so requests can interleave, though I could not see that store's transaction handling.
  - Sequence: two `create_project` calls arrive for a free user with 2 active projects. Both read a count of 2, both pass, and both insert, leaving 4 active. The same window exists between `downgrade_to_free` and an in-flight create that read `plan == "team"` before the downgrade.
  - To confirm, I would need the Postgres `Store` and its isolation level. The fix is to hold a row lock on the user (`SELECT ... FOR UPDATE`) around check and write, or to use a constraint or advisory lock.

### Noted
- I traced `User`, `Project`, and every writer of `status`, `owner_id` and `plan` across `projects.py`, `transfers.py` and `billing.py`. I ran the sequences above with a script that does not write to the repo. I could not see the real Postgres `Store`, any HTTP layer or authentication, or any team model that `transfer_project` refers to.
- The blocking findings here come from four separate places that each have to remember the limit (`create`, `restore`, `transfer`, `downgrade`). Only one of them is a real shared function.

### Out of my lane
- `billing.py:9` -> no owner. The limit is hardcoded as `>= 3`, while `models.py:35` exports `FREE_ACTIVE_LIMIT`, which `projects.py` imports. The upgrade prompt will drift from the real limit when it changes. Import and use the constant.
- `billing.py:13-19` -> no owner. The docstring says projects are archived "newest first". The code sorts newest first with `reverse=True` and archives `active[3:]`, so it keeps the newest 3 and archives the oldest. I ran it: with ids 14 to 18, the kept ids were 16, 17 and 18. If "archived newest first" is the intent, the slice or sort is wrong. If keeping the newest is the intent, the docstring is wrong. Either way, decide which and make them agree.
- `models.py:27-29` -> no owner. `new_id` increments before returning, so ids start at 2 and id 1 is never issued. This is harmless in memory, but it will not match Postgres sequences. Return the value first, then increment, if the ids are meant to line up.
