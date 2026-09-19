# Eval log

What the seeds caught, in the order it happened. Kept because the misses are more instructive than the passes, and because "we tested it" means nothing without saying what the tests found.

## 2026-09-13, first full run

**Result: 34 of 34 seeds passing, after fixes.** Seven agents. Roughly forty individual seed runs to get there.

### Runner bugs (three)

- `must_not_mention: BLOCK` on every clean seed matched the section header `### Blocking`. Every clean seed would have failed forever. Fix: the check skips markdown headers.
- Agents were reviewing the `.claude/agents/` files the runner installs into the scratch directory, and reporting on the charters' own example text. Fix: the default prompt tells the agent to ignore `.claude/`.
- `must_not_mention` scanned the Noted section, so an agent correctly explaining why a rule *didn't* apply got penalized for naming the rule. Fix: only Blocking and Should fix are scanned.

### Charters that were too soft (two)

- **security-reviewer** recognized `AKIAIOSFODNN7EXAMPLE` as AWS's documented example key and downgraded to WARN. Technically right about the value, wrong about the pattern. The charter's "obviously fake" exception was too broad. Now: code that uses a credential-shaped value as a credential is BLOCK regardless of whether the value is a known placeholder. Placeholders in docs and example files are fine.
- **security-reviewer** filed `aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}` under Should fix, apparently because no key value was visible. Now the charter says a secret referenced by name in a static-credential slot is a static credential, and that's Blocking.

### Charters that were too strict or ambiguous (two)

- **infra-reviewer** was told a missing `permissions:` block is always BLOCK. The agent gave WARN on a job that only runs `npm test`, and it was right: no credentials, small blast radius. Now: BLOCK if the job deploys, publishes, has secrets, or assumes a role. Should fix otherwise.
- **test-reviewer** said BLOCK on an untested `raise KeyError` where the seed expected WARN. The charter had "new branch with no test" under BLOCK and "happy path only" under WARN, and those overlap. The agent drew the right line in its own reasoning: an explicitly coded error path is behavior; an implicit one (an exception that would just propagate) is not. That line is now in the charter.

### Seeds that were wrong (seven)

- **security/hardcoded-aws-key** demanded the literal string `AKIA` in the report. The agent deliberately didn't echo the key. Better hygiene than the test asked for. Check changed to substance.
- **docs/clean** got rejected four times, each time for a real gap: README referenced a `requirements.txt` and `infra/` that didn't exist; a stub function the README described as working; a teardown line made stale by a fix thirty seconds earlier; no setup section for the Terraform; no Python version stated for code using a 3.9+ method. Every rejection was legitimate. A genuinely clean project is harder to write than a broken one.
- **infra/clean** got rejected for having no remote Terraform backend, meaning state would live on the ephemeral CI runner and `terraform destroy` would remove nothing. Also referenced a `prod.tfvars` that didn't exist. Both real.
- **infra/no-permissions-block** used `must_not_mention: SHA` to test lane discipline. The agent mentioned SHA pinning in Noted to explain why it *didn't* apply. Correct behavior, bad check.
- **engagement-guide/does-not-invent** used `must_not_mention: budget:` to catch invented budgets. The correct output was `Budget: unknown`. Check inverted to assert the right text positively.
- **engagement-guide/marks-unknown** demanded "Do nothing" and the agent wrote "doing nothing." Loosened to "nothing".
- **engagement-guide/does-not-invent** flagged "weeks" as an invented timeline. The template's own guidance text says "Six weeks from now." Check removed.

### Pattern worth remembering

Of the fourteen fixes, three were in the runner, four were in charters, and seven were in the seeds themselves. The agents were right more often than the tests were. The seeds still earned their keep: every runner bug and every charter fix came from a seed failing, and none of them would have been found by reading.

`must_mention` and `must_not_mention` should test substance, never phrasing. Three separate seeds failed because the agent said the right thing in different words.

## 2026-09-14, first real PR

**Result: one swarm defect found by real use, fixed, 35 of 35 seeds after adding one.**

The swarm reviewed its first real pull request (shelflife (then called expiry-tracker) PR 1, logged in that repo's `docs/review-log.md`). It returned BLOCK with three blocking findings and four should-fix, all of which held up. The defect was in how it handled the one finding nobody owned.

### The swarm invented a teammate

- **scope-reviewer** noticed a dead code branch, correctly decided it wasn't a scope problem, and handed it off under Out of my lane to "code-reviewer". There is no code-reviewer; ADR 0004 says there never will be. The swarm's merge step caught the bad route and listed the finding under "Handoffs nobody picked up" instead of dropping it, which is the right failure mode. But the agent had no way to know the name was wrong, because nothing it was given lists who exists.
- Fix, in three parts. `shared/review-contract.md` now carries the roster with a one-line lane for each agent, says plainly that there is no general code reviewer, and gives the agent the words to use when nothing fits: "no owner in the roster." The runner now fails any report that names an agent not present under `agents/`, for every seed, so this can't come back quietly. And **scope-reviewer/handoff-has-no-owner** reproduces the situation: an in-scope change with an unused function in it. First run came back WARN for a real reason (the scope named an `expected-summary.csv` that the seed didn't include, the same mistake as `docs/clean` last time). With the fixtures added it passes, and the dead code lands under Noted with no invented name.

### Pattern worth remembering

A charter tells an agent what to look for. It also has to tell the agent what the rest of the team looks like, or the agent fills in the gap with the most common name it has seen. The seeds could never have found this because every seed exercises one agent alone. It took a real PR with a finding that fell between the lanes.

## 2026-09-17, the rename

Not an eval finding. Recording it here because it is the same class of problem the eval log exists for: something that was correct when written and stopped being correct later, with nothing watching.

The GitHub account was renamed from `Cruzcodez` to `cruzbuilds`. Every install line in this repository still named the old account:

```
/plugin marketplace add Cruzcodez/agentic-swarm
```

GitHub redirects a retired username until someone else claims it. For a normal link that means a dead link one day. For this line it means worse: a user pastes it into Claude Code, which fetches a marketplace manifest from whoever owns that name now and installs agent files from it. Those files are instructions an agent then follows. A stale install line in an agent repository is a supply chain link, not a broken hyperlink.

Swept: the marketplace manifest, all seven plugin manifests, the README, and three agent READMEs. `dist/` needed no change, since the built agent files never named the account.

Worth remembering: no agent flagged this, and no agent could have. The links were right when they were written. The seeds test whether an agent catches a defect in a diff; nothing here tests whether the world moved under a file that has not changed.

## 2026-09-18, the reviewers ran a whole study with their tools denied

Found by running the swarm as the subject of an experiment rather than as a tool, which is the only
reason it was found at all.

Three runs of the full swarm against a generated application. Every agent completed. Every report
looked normal. In each one, the Noted section said some version of this:

> security-reviewer: a Bash call was denied. gitleaks, semgrep, `pnpm audit` and the tracked-secret
> file check did not run.
> infra-reviewer: checkov is installed but was denied by the Bash permission.
> test-reviewer: nothing was run and no coverage was measured. Everything was read only.

The agents behaved correctly. They said plainly what they could not do, which is what the contract
asks for, and that is the only reason this was visible at all.

Two causes, both in `scripts/review.sh`, both mine.

**The gate was shut.** `--allowedTools Read,Grep,Glob,Task` did not name `Bash`. I removed it on
2026-09-17 while narrowing permissions after a security finding (ADR 0005), believing the
command-level allow list in `.claude/settings.json` would scope it. It does not work that way.
`--allowedTools` decides which tools exist; the permission rules only decide which commands those
tools may run. With `Bash` absent from the flag, every shell call was refused before the rules were
consulted. The allow list I had carefully written was never reached.

**The allow list named the wrong package manager.** It permitted `npm audit` but not `pnpm audit`, and
the subject was a pnpm project. Even with the gate open, the dependency audit would have been denied.

So a set of specialists whose charters name gitleaks, semgrep, checkov, tflint, hadolint and a test
runner reviewed an application without running any of them. Five readers, not five specialists.

Fixed: `Bash` is back in `--allowedTools`, with a comment saying why leaving it out is not a
narrowing, and the allow list covers pnpm, npx, tsc, eslint and node.

**What this cost.** Three swarm runs measuring something other than what the swarm is. Those runs are
not discarded. They become the reading-only condition of a two-condition experiment, which is a more
useful design than the one originally registered, and it exists because of this bug.

**What it says about the eval suite.** Thirty-five seeded defects, all passing, and not one of them
would have caught this. Every seed tests whether an agent finds a planted defect in a small tree that
needs no tools. Nothing tests whether an agent can still reach its tools. A seed that plants a
credential only `gitleaks` would catch, in a repository large enough that reading will not find it,
would have failed loudly the day this broke.

## 2026-09-19, systems-reviewer Run 001: the reviewer found bugs in its own seeds

First eval of the V2 systems reviewer against six interaction seeds at `53445c2`. Five defect
seeds: BLOCK, intended interaction reconstructed, five-part finding present, no checklist item in
any blocking section. Full matrix and raw reports in `docs/evals/systems-reviewer/run-001/`.

The clean seed came back BLOCK, and it was right. `reopen` in the tickets fixture relied on
`satisfaction is None` instead of checking for RESOLVED, and the shared transition table let it move
a PENDING ticket to OPEN with no reply, which the README and the function's own docstring both
forbid. I wrote that fixture as clean and missed it. The reviewer also found a README diagram that
disagrees with `refund` in the orders fixture, and a second real interaction in the jobstats fixture
that I had not designed in. Three fixtures, three things the author missed, found by the thing under
test. Recorded as a research result, not a grading problem.

### Patterns worth remembering

- Local correctness nits have no owner in the roster, so the reviewer keeps them in Should fix and
  labels them local. That is ADR 0004's gap one level down. The arbiter's unowned-finding path is
  the fix; the charter should route them there. Not changed yet.
- Severity is binary in the charter and was binary in practice. A real interaction with a mild
  consequence got BLOCK. One sentence of severity guidance is warranted. Not changed yet.
- Every seed directory carried `__pycache__` from the author's import checks, and every report
  flagged it. Same class of harness leak as Experiment 001's settings file. Runner fix pending.
- Three of six reports dropped the `## systems-reviewer` heading. The relay through the main
  session is the likely cause.

## 2026-09-19, swarm (arbiter) Run 001: nine of nine, and the arbiter would not open the file

First eval of the V2 arbiter at `c6352b5`: eight deterministic seeds (saved reviewer reports as
input) plus the V1 live seed with six reviewers. All nine correct on verdict and on the rule each
seed tests. Matrix and raw reports in `docs/evals/swarm/run-001/`.

The elevation guardrail worked in both directions on the same location: blocking/high when the
reviewer wrote a reproduction and a consequence, should-fix/low when it hedged, each with a basis
line quoting the reviewer. The no-file-access rule held when it cost something: the `disagreement`
fixture is internally inconsistent (a `.py` file with JavaScript types, and two conflicting
coverage lines, both my authoring errors), the arbiter noticed from the reports, said it could not
resolve it without opening the file, and did not.

On the live seed, four reviewers' handoffs that infra-reviewer did not pick up became one unowned
finding at should-fix with all four credited. In V1 that was four lines with no severity. And the
systems reviewer declined to raise the unconditional overwrite as a finding because no invariant
was stated, which is the false-positive behavior Run 001's invalid clean seed could not measure.

### Patterns worth remembering

- A reviewer's "I could not check this" is not a disagreement with another reviewer's Blocking.
  The arbiter resolved it correctly and classified it wrong. One sentence, deferred.
- Generated fixtures need the same review as hand-written ones. Two of my eight had defects the
  arbiter found.
