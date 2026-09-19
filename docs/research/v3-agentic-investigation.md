# V3: agentic investigation. Proposed, not built

**Status: a research question and a sketch. Nothing below is implemented, designed past this
document, scheduled, or evaluated. No manager exists, no investigator runtime exists, no reviewer
selects tools iteratively. The current implementation is V2 as described in
[v2-hybrid-review.md](v2-hybrid-review.md).**

**Question this would answer.** Does review quality improve when fixed reviewers become managed
investigators, able to gather evidence iteratively, select tools, revise hypotheses, and be directed
to continue investigating when their evidence is incomplete?

**What precedes it.** V2's evaluations ([v2-hybrid-review.md](v2-hybrid-review.md), sections 5 to 8),
which showed the V2 mechanisms behaving as designed and left one structural property untouched: every
reviewer still receives a task, investigates once, and returns a completed report. The execution
graph is fixed before any evidence exists. The arbiter reasons over finished reports only, by design,
and so cannot send anyone back to look.

**Evidence that motivates the question, such as it is.** Two moments in the record. In Experiment
001, the single reviewer given tools ran a bcrypt timing benchmark and a 72-byte truncation
reproduction on its own initiative, turning a code-read claim into a demonstrated one; nothing asked
it to, and nothing would have asked a V1 or V2 reviewer to. In the arbiter's `disagreement` seed, the
right next step was obvious (open `session.py`, settle which of two descriptions is true) and the
architecture forbade it, correctly, because the arbiter is not a reviewer and nobody else was
chartered to go back. Two moments are an observation, not a measurement.

## The progression this belongs to: who decides what happens next

```
Simple prompt       a human decides the single call
Structured prompt   a human still decides the single call, with more in it
V1                  the workflow decides a fixed parallel graph: six calls, then a merge
V2                  the workflow still decides execution; synthesis becomes evidence-aware
V3 (proposed)       intermediate evidence begins deciding subsequent execution;
                    a manager and the investigators choose parts of the path as they go
```

The word for that last step is **bounded agentic investigation**, not autonomy. Humans still define
the objectives, the roles, the permissions, the available tools, the budgets, the stopping conditions,
and the arbiter's rules. What becomes model-directed is the investigative path inside those bounds.

## The shape, as currently imagined

```
                    CHANGE
                      |
                      v
             INVESTIGATION MANAGER
                      |
          +-----------+-----------+
          |           |           |
          v           v           v
      Security     Systems      Tests ...
    Investigator Investigator Investigator
          |           |           |
          +-----------+-----------+
                      |
               evidence / state
                      |
                      v
             INVESTIGATION MANAGER
                      |
          +-----+-----+------+----+
          |     |            |    |
      continue redirect  complete stop
          |
          +------> investigator
                       |
                       +-----> manager
                                 |
                                loop
                                 |
                             complete
                                 v
                              ARBITER
                                 |
                       findings + assurance record
```

Three roles, kept apart on purpose.

**The manager operates during investigation.** It asks: what remains unknown? Is the claim proven or
only asserted? Should this investigator continue, and with what? Should the investigation redirect to
a boundary another investigator has reached? Is more work unlikely to change the conclusion? It
decides continue, redirect, complete, or stop, within a budget. It does not review code and it does
not write findings.

**An investigator investigates its domain.** It may form a hypothesis, select a tool, gather evidence,
revise or disprove the hypothesis, follow a boundary into another component, propose its own next
action, and eventually submit a result whose every claim carries the evidence that supports it. The
V2 charters are the starting point for what each investigator is for; what changes is that "how you
work" stops being a fixed procedure.

**The arbiter operates after investigations are complete.** It is the V2 arbiter, unchanged in
principle: it synthesizes completed evidence, assigns severity and confidence to unowned findings from
that evidence, records disagreements, caps the verdict on incomplete coverage, and produces the
findings and the assurance record. It does not manage investigation. Merging the manager and the
arbiter would put "should this continue" and "what does this add up to" in one place, and the
assurance record would no longer be able to say who decided what.

## What would have to be true for V3 to be worth building

- V2 has been used on real pull requests and its failures are in seeds. It has reviewed zero so far.
- The V2 baseline is tagged so V3 can be compared against something fixed.
- There is a subject with real tests, CI, infrastructure and business logic, so that iterative
  investigation has somewhere to go.
- Predictions are sealed before the first run, including the ones that will be embarrassing: that
  the manager mostly says "complete," that cost rises faster than findings, that redirects introduce
  the cross-contamination V1 and V2 were designed to avoid.
- The comparison is V2 against V3 on the same subject with the same model, and includes cost,
  latency, false positives, and whether the manager's decisions were ever load-bearing.

## What is not being claimed

That V3 will find more. That iteration is worth its cost. That a manager can judge "proven" better
than a reviewer can. That any of this is agentic in more than the bounded sense above. Those are the
things the experiment would measure.

**What came next:** nothing yet. This document is the last node in the research chain as of
2026-09-19.
