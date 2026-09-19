**Verdict:** BLOCK

### Blocking

- `projects.py:19-25` **Restore bypasses the free-plan limit, and so does the downgrade.**
  - **Invariant:** `README.md:5` says a free plan has at most 3 active projects. `create_project` (`projects.py:6`) enforces it, and `downgrade_to_free` (`billing.py:12-19`) enforces it "the moment the plan changes".
  - **Interaction:**
    1. A free user has 3 active projects and 1 archived project (`archive_project`, `projects.py:13`).
    2. The user calls `restore_project` on the archived one. It only checks ownership and `status == "archived"`, then sets `status = "active"` with no count check.
    3. The user now has 4 active projects.
  - **Failure:**
    - The invariant is broken at will on the free plan. The agent ran it and got 4 active projects for a free user.
    - The downgrade is undone the same way. A team user with 6 projects is downgraded and left with 3 active, then restores the 3 archived ones. Result: 6 active projects on `plan == "free"`.
    - `upgrade_prompt_needed` (`billing.py:9`) uses `>= 3`, so it fires forever but nothing stops the user.
  - **Fix:** Put the plan-limit check on the transition into `active`. Extract one `assert_can_activate(store, user)` that uses `FREE_ACTIVE_LIMIT`, and call it from `create_project`, `restore_project` and `transfer_project`. `restore_project` should raise `PlanLimit`.

- `transfers.py:14-17` **Transfer pushes a free receiver over the limit.**
  - **Invariant:** A free account never holds more than 3 active projects.
  - **Interaction:**
    1. Sender is on the team plan (or is a free user with a spare slot) and owns an active project.
    2. Receiver is a free user with 3 active projects.
    3. `transfer_project` checks the sender's ownership and that the receiver exists, then sets `owner_id = to_user_id`. It never looks at the receiver's plan or count.
  - **Failure:** The receiver ends up with 4 active projects on the free plan (the agent ran it and got 4). Anyone can also push projects onto a free user without their consent.
  - **Fix:** Call the same activation check for the receiver in `transfer_project` when `project.status == "active"`. Raise `PlanLimit`, or decide explicitly that the transfer lands archived. That is a product decision, and the code has to pick one.

### Should fix

- `projects.py:6-9` **The limit check in `create_project` is check-then-insert.**
  - Two create requests from the same free user with 2 active projects (two tabs, or a double-click) can each read a count of 2 and each insert. The result is 4 active projects.
  - `models.py:22` says the real store is Postgres, and that implementation isn't in the change. Confirming this needs its transaction and isolation behavior.
  - Enforce the limit in a transaction that locks the user row, for example `SELECT ... FOR UPDATE` on the user.
  - The same window applies to `restore_project` and `transfer_project` once they check.

- `billing.py:9` **The limit is hardcoded as `3` instead of `FREE_ACTIVE_LIMIT`.**
  - `billing.py:9` and `billing.py:18` both hardcode 3, while `projects.py:6` uses the constant. If the limit changes, the prompt and the downgrade drift from the create check silently.
  - Import `FREE_ACTIVE_LIMIT` in `billing.py`.

- `billing.py:12-19` **The downgrade is not atomic with plan changes.**
  - `user.plan = "free"` is set before the archive loop, and `downgrade_to_free` isn't guarded against concurrent `create_project`, `restore_project` or `transfer_project` calls on the same user.
  - A transfer that lands between the count and the archive leaves the account over the limit.
  - This also needs the real store's transaction behavior to confirm.

- `billing.py:13-19` **"Newest first" is ambiguous, and the code keeps the newest 3.**
  - The list is sorted newest first, then `active[3:]` is archived. That archives the oldest projects and keeps the newest 3 (ids 13, 14, 15 stayed active out of 6).
  - "Archived, newest first" can also be read as the newest being archived. Confirm which behavior is intended, because users will notice which projects vanished.
  - Ordering by `id` also assumes id order equals age. That holds today because `transfer_project` doesn't change ids.

### Noted

- Traced entities: `Project` (status and owner transitions across `projects.py`, `transfers.py` and `billing.py`) and `User.plan`. Ownership checks in `_owned` and `transfer_project` are consistent with each other.
- There is no `engagement/` or `docs/decisions/` folder. The README is the only statement of the rules.
- The Postgres store is not in the change. The race findings depend on it.
- `store.users[user_id]` in `create_project` and `upgrade_prompt_needed` raises a bare `KeyError` for unknown users, where `NotFound` is defined. That is a local issue.

### Out of my lane

- `__pycache__/*.pyc` files are committed to the repository. That is repository hygiene, and the agent found no owner for it in the roster. infra-reviewer is the closest fit.
- No tests exist for any of the modules. That is test-reviewer's call. The restore, transfer and downgrade-then-restore sequences above are the ones to cover.
