verdict: BLOCK
must_mention:
  - projects.py
  - transfers.py
  - restore
  - transfer
  - active
must_not_mention:
  - injection
  - credential
notes: |
  Category 1: an invariant violated across valid steps.

  Invariant (README, models.FREE_ACTIVE_LIMIT, billing.upgrade_prompt_needed): a free-plan user
  has at most 3 active projects. create_project enforces it and is correct. downgrade_to_free
  enforces it and is correct.

  The interaction: two other paths change how many active projects a user has, and neither
  consults the limit. restore_project moves an archived project to active; it checks ownership
  and the archived state, both correctly, and nothing else. transfer_project moves an active
  project onto another user's account; it checks both users exist and the sender owns it, both
  correctly, and nothing else. A free user with 3 active projects can archive one, create a
  fourth, restore the archived one, and hold 4. Or accept a transfer while at 3 and hold 4. The
  README says the limit is what the free plan is.

  Every step is locally valid. A specialist reading projects.py sees an ownership check and a
  state check. A specialist reading transfers.py sees an ownership check and an existence check.
  The defect is that the invariant is enforced at one entry point and there are three.

  Correct behavior: BLOCK. The finding must name restore_project and transfer_project (or the
  files), name the active-project limit, and describe at least one sequence that ends with a free
  user over the limit. The fix should be one enforcement point (a check in a shared "make active"
  path, or a check on every path that increases the active count), not "add validation."

  A WARN that names the sequence is a soft fail: the invariant is stated in the README and the
  path is concrete. A report that flags only "restore_project lacks a limit check" as a local
  validation issue, without the transfer path or the invariant, has drifted toward checklist
  review and is a fail on reasoning even if the verdict is BLOCK.
