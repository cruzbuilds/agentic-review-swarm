# Output format

Every review agent reports in exactly this shape. No exceptions, no additions, no reordering.

The reason is mechanical. When several agents review the same change at once, something has to merge their reports. That only works if every report has the same sections in the same order with the same meaning. An agent that improvises its own format breaks the merge for everyone.

It also helps the human. Once you've read one report you can read all of them.

---

## The template

```markdown
## <agent-name>

**Verdict:** BLOCK | WARN | PASS

### Blocking
- `path/to/file.py:42` What's wrong, in one sentence. Why it matters. What to do about it.

### Should fix
- `path/to/file.py:88` Same shape. Real problems that don't stop the merge on their own.

### Noted
- Things worth knowing that need no action. Keep this short or leave it empty.

### Out of my lane
- `README.md` -> docs-reviewer. Doesn't mention the new environment variable.
- `src/billing.py:31` -> no owner. Hardcodes the plan limit as 3 while `models.py` exports it as a constant. The two will drift silently when the limit changes. Import the constant.
```

## What each verdict means

**BLOCK.** At least one finding under Blocking. This change should not merge until it's fixed. The agent has to be able to say exactly why, with a file and a line.

**WARN.** Nothing blocking, but something under Should fix, or the agent isn't sure about something in its lane and is saying so rather than guessing. WARN is the honest verdict when the agent can see a problem but can't prove it.

**PASS.** The agent looked at everything in its lane and found nothing to report. PASS does not mean "looks good." It means "I checked the things I'm responsible for and none of them are wrong."

An agent that returns PASS without having actually checked is worse than one that returns nothing, because someone will trust it.

## Rules for every finding

**Name the file and the line.** "There might be an auth issue" is not a finding. `src/api/users.py:117` with what's wrong is a finding. If the agent can't point at a line, it goes under Noted, not Blocking.

**Say why it matters.** Not just what's wrong. A hardcoded key is wrong because it's live the moment it's pushed and stays live in git history after it's deleted. That second sentence is what makes someone act.

**Say what to do.** One concrete next step. The person reading this is trying to get unblocked, not trying to learn security.

**One finding per bullet.** If a bullet needs the word "and," it's two findings.

## The "Out of my lane" section

This is the section that makes a swarm work instead of a pile of agents talking over each other.

Every agent has a narrow job and is told what it does not comment on. But it still has eyes. When the security reviewer notices the README is out of date, it shouldn't comment on it, because that's not its job and the docs reviewer will handle it better. It also shouldn't pretend it didn't see it.

So it goes here, in one of two forms.

**Routed:** `-> <agent>`. One line. The named agent owns it; the arbiter checks whether that agent reported it, and if not, the handoff becomes an unowned finding with your name on it.

**Unowned:** `-> no owner`. Use this when the problem is real and nobody in the roster owns the category. This line carries more than one sentence, because the arbiter has to assign it a severity from what you wrote and nothing else: the file and line, what is wrong, why it matters, and what to do. If you can give a concrete sequence or you reproduced it, say so; that is what lets it be taken seriously. If you cannot name a line, it is not ready for this section; put it under Noted.

Nothing gets lost and nobody steps on anyone. What you write under `-> no owner` is the whole case; the arbiter will not open the file to strengthen it.

## What never appears in a report

- Style, formatting, or naming opinions. A linter does that. An agent doing it is noise.
- "Consider..." or "You might want to..." Either it's a finding with a file and line, or it isn't in the report.
- Praise. "Nice use of..." is filler. The person reading this wants to know what's wrong, not what's fine.
- Restating the diff. They can read the diff.
