I wrote `engagement/02-discovery.md`. The file contains plain `>` blockquotes, not the escaped `&gt;` the subagent's report showed. Anything you didn't know is marked "unknown", and gaps are flagged inline as "Open question" blockquotes.

Here is the finished document:

---

# 2. Discovery

**Date:** 2026-09-19
**Decision:** build it

Every "Open question" below is a gap or a vague answer from the discovery interview. Nothing in this document was filled in beyond what the builder said. Where they did not know, it says unknown.

---

## What you looked at

- The last three months of vendor CSV exports.
- One conversation with one person in finance.

> **Open question:** Who is the person in finance (role, and whether they are the person who would use this)? unknown, not recorded.
>
> **Open question:** `01-intake.md` is still the blank template. The original ask, the underlying problem and the success criteria were never written down, so this discovery cannot be checked against them.

## What you found

> "All the exports have the same five columns. Dates are in two different formats depending on which system produced them."

- The five columns are the same across every export in the three-month sample.
- Date format varies by producing system: two formats seen.

> **Open question:** Which five columns? unknown, not recorded.
>
> **Open question:** Which two date formats, and which systems produce each? unknown, not recorded.
>
> **Open question:** What the finance contact said, and what the exports are used for today. unknown, nothing recorded from that conversation.

## Assumptions

| What you're assuming | How you'd confirm it | What breaks if it's wrong |
| --- | --- | --- |
| The two date formats are the only two. The builder has not checked older exports. | Check older exports. The builder has not said how far back they go or how many there are (unknown). | The parser throws on a third format and the whole run fails. |

> **Open question:** The builder's own words: "I haven't checked older exports." Until they are checked, "same five columns, two date formats" is only known for the last three months.

## Constraints

- Technical: unknown, not discussed.
- Access (what can you actually get into): the builder needs the export folder. Whether they have it yet, where it lives and who controls it are unknown.
- Time: unknown. "Haven't asked about budget or timeline."
- Money: unknown. Not asked.
- Political (who needs to be on board): unknown. Only one person in finance has been spoken to. Who else needs to agree is not recorded.

> **Open question:** "Don't know yet. Haven't asked about budget or timeline." Budget, timeline and approvers are all unasked. Any of them could end the project, so they need to be asked before scope is written.

## Options you considered

**Option A: a script that reads the folder**
- How it works: a script that reads the export folder. What it produces (merged file, cleaned data, a report) is unknown, not stated.
- Good because: the builder says it is small, about a few evenings, and costs nothing to run.
- Bad because: the one failure named is a third date format, which makes the parser throw and fails the whole run. Other downsides were not discussed (unknown).

**Option B: do nothing**
- How it works: nothing is built. What finance does with the exports today is unknown.
- Good because: not evaluated. The builder said only, "I guess doing nothing is an option too."
- Bad because: not evaluated. The cost of the current situation is unknown.

> **Open question:** Option B is a placeholder, not an assessed option. Only one real approach was considered. A second real alternative (or a real look at what doing nothing costs) is still missing.

## What it would take

- Effort: "A few evenings." No breakdown given.
- What it costs to run: "Costs nothing to run." Where it would run and who runs it are unknown.
- What you'd need access to: the export folder.
- Biggest thing that could go wrong: the builder was not asked this directly. The one failure they named is a third date format in older exports, which fails the whole run.

> **Open question:** The "few evenings" estimate assumes only two date formats. If older exports have more, the estimate is unverified.

---

## Decision

> **Decision:** Build it.
>
> **Because:** "It's small."

> **Open question:** "It's small" is a statement about cost, not about value. No reason was given for why the script is worth doing, and no problem, user or benefit is recorded. This is the thinnest part of the decision.

**The argument against building (required in discovery; this is the skeptic's case, not the builder's position):**

- The decision rests on size. A small thing that nobody needs is still not worth doing.
- The problem is unrecorded. `01-intake.md` is blank, and nothing from the finance conversation is written down.
- Doing nothing was never assessed. If finance handles these exports quickly today, the script saves little.
- Budget, timeline and approvers were never asked. Any of them could end this.
- Access is not secured. The builder needs the export folder, and if they cannot get it there is nothing to build.
- The evidence is thin: three months of exports, one person, and older exports unchecked. If older exports hold more date formats, "small" may not hold.
- There is no stop condition (below).

What would have to be true for "don't build it" to be right: finance already handles these exports cheaply, the export folder cannot be accessed, or older exports turn out to be messy enough that it isn't small. The builder has not established whether any of these is true. All three are unknown.

### If you're building: what would make you stop

> **Still worth it if:** unknown. The builder was asked and said, "I don't know."
>
> **Check by:** unknown. No date given.

> **Open question:** There is no stop condition. This should be set before building starts. Example of the shape needed: "worth continuing if the script runs cleanly over all older exports by [date]; if a third date format shows up that can't be handled simply, stop." The builder has to supply the real condition and date.

---

- **Date:** I used today's date, 2026-09-19, because `answers.md` didn't give one.
- **Structure:** The template has no open-questions section, so the open questions sit inline.
- **Decision:** It stays "Build it", as you answered.
- **Stop condition:** The biggest gaps to fill before building are the stop condition, the budget and timeline questions, and the export folder access.
# 1. Intake

**Date:**
**Who asked:**
**Who's building it:**

Fill this out before you do anything else. Before research, before design, definitely before code.

The job of this file is to freeze the original ask in writing, while it's still fresh and before you've started reinterpreting it. Six weeks from now somebody will say "I thought this was also going to do X." This file is how you find out whether they said that, whether it changed along the way, or whether it never came up. Without it you're arguing from memory.

If this is your own idea, put your own name in "who asked." Write it down anyway. The version of you that's three weekends deep and chasing a tangent needs something to argue with.

---

## What they asked for

Write it the way they said it. Don't tidy it up and don't translate it into architecture yet.

If they said "we need a chatbot that reads our S3 bucket," write exactly that. The messy original wording is the useful part. Later you'll want to know what was actually said, as opposed to what you decided they must have meant.

> 

## Why they want it

What's the problem underneath the request?

People ask for solutions, not problems. Somebody asking for a chatbot usually has a problem more like "our team burns an hour a day hunting for documents." That problem is the thing you're actually solving. The chatbot is one possible answer to it, and it might not be the best one.

This matters because if you only build what was asked for, you can ship exactly what they requested and still not help them.

If you can't answer this yet, good. That's your first discovery question.

> 

## What does success look like

How will they know it worked? Push for something you could actually go check.

"It's faster" isn't checkable. "Someone can find a policy document in under 30 seconds without messaging the ops team" is. If you can't measure it, you can't tell whether you're done, and neither can they.

> 

## Constraints already on the table

Anything that limits your options, as far as you know right now:

- Budget:
- Deadline:
- Tools or platforms they have to use:
- Tools or platforms they can't use:
- Security or compliance requirements:
- Who has to approve things:

You'll find more of these in discovery. This is just what's been said so far.

## What you don't know yet

List the questions you can't answer. These become your discovery checklist.

Be honest here, it costs you nothing. "I don't know what format their data is in" is a real gap, and writing it down is how it gets closed. Pretending you know is how you find out the expensive way.

- [ ] 
- [ ] 

---

## Prompt for your AI assistant

Paste this into Claude, Kiro, or whatever you use. It interviews you and writes the file from your answers.

Here's what it deliberately will not do: make things up. If it starts inventing constraints or guessing what the customer wants, stop it. The point of this document is that you thought about it. An assistant that fills it in for you hands back a page of reasonable sounding text you never actually considered, and you won't spot the wrong parts until they cost you something.

```
I'm starting intake for a new proof of concept. Interview me one question at a
time and then write an intake document from my answers.

Cover these sections:
- What was asked for, in the asker's own words
- The underlying problem behind the request
- What success looks like, in terms someone could actually verify
- Constraints already known (budget, deadline, required tools, banned tools,
  security requirements, approvers)
- What I don't know yet

Rules:
- Ask one question at a time. Wait for my answer before moving on.
- If my answer is vague, push back and ask for something specific. "It should
  be faster" is not an acceptable success criterion.
- Never invent, assume, or fill in anything I haven't told you. If I don't
  know something, write "unknown" and add it to the open questions list.
- Don't suggest solutions. This document is about the problem.
- When we're finished, output the completed markdown and nothing else.
```
# 2. Discovery

**Date:** 2026-09-19
**Decision:** build it

Every "Open question" below is a gap or a vague answer from the discovery interview. Nothing in this document was filled in beyond what the builder said. Where they did not know, it says unknown.

---

## What you looked at

- The last three months of vendor CSV exports.
- One conversation with one person in finance.

> **Open question:** Who is the person in finance (role, and whether they are the person who would use this)? unknown, not recorded.
>
> **Open question:** `01-intake.md` is still the blank template. The original ask, the underlying problem and the success criteria were never written down, so this discovery cannot be checked against them.

## What you found

> "All the exports have the same five columns. Dates are in two different formats depending on which system produced them."

- The five columns are the same across every export in the three-month sample.
- Date format varies by producing system: two formats seen.

> **Open question:** Which five columns? unknown, not recorded.
>
> **Open question:** Which two date formats, and which systems produce each? unknown, not recorded.
>
> **Open question:** What the finance contact said, and what the exports are used for today. unknown, nothing recorded from that conversation.

## Assumptions

| What you're assuming | How you'd confirm it | What breaks if it's wrong |
| --- | --- | --- |
| The two date formats are the only two. The builder has not checked older exports. | Check older exports. The builder has not said how far back they go or how many there are (unknown). | The parser throws on a third format and the whole run fails. |

> **Open question:** The builder's own words: "I haven't checked older exports." Until they are checked, "same five columns, two date formats" is only known for the last three months.

## Constraints

- Technical: unknown, not discussed.
- Access (what can you actually get into): the builder needs the export folder. Whether they have it yet, where it lives and who controls it are unknown.
- Time: unknown. "Haven't asked about budget or timeline."
- Money: unknown. Not asked.
- Political (who needs to be on board): unknown. Only one person in finance has been spoken to. Who else needs to agree is not recorded.

> **Open question:** "Don't know yet. Haven't asked about budget or timeline." Budget, timeline and approvers are all unasked. Any of them could end the project, so they need to be asked before scope is written.

## Options you considered

**Option A: a script that reads the folder**
- How it works: a script that reads the export folder. What it produces (merged file, cleaned data, a report) is unknown, not stated.
- Good because: the builder says it is small, about a few evenings, and costs nothing to run.
- Bad because: the one failure named is a third date format, which makes the parser throw and fails the whole run. Other downsides were not discussed (unknown).

**Option B: do nothing**
- How it works: nothing is built. What finance does with the exports today is unknown.
- Good because: not evaluated. The builder said only, "I guess doing nothing is an option too."
- Bad because: not evaluated. The cost of the current situation is unknown.

> **Open question:** Option B is a placeholder, not an assessed option. Only one real approach was considered. A second real alternative (or a real look at what doing nothing costs) is still missing.

## What it would take

- Effort: "A few evenings." No breakdown given.
- What it costs to run: "Costs nothing to run." Where it would run and who runs it are unknown.
- What you'd need access to: the export folder.
- Biggest thing that could go wrong: the builder was not asked this directly. The one failure they named is a third date format in older exports, which fails the whole run.

> **Open question:** The "few evenings" estimate assumes only two date formats. If older exports have more, the estimate is unverified.

---

## Decision

> **Decision:** Build it.
>
> **Because:** "It's small."

> **Open question:** "It's small" is a statement about cost, not about value. No reason was given for why the script is worth doing, and no problem, user or benefit is recorded. This is the thinnest part of the decision.

**The argument against building (required in discovery; this is the skeptic's case, not the builder's position):**

- The decision rests on size. A small thing that nobody needs is still not worth doing.
- The problem is unrecorded. `01-intake.md` is blank, and nothing from the finance conversation is written down.
- Doing nothing was never assessed. If finance handles these exports quickly today, the script saves little.
- Budget, timeline and approvers were never asked. Any of them could end this.
- Access is not secured. The builder needs the export folder, and if they cannot get it there is nothing to build.
- The evidence is thin: three months of exports, one person, and older exports unchecked. If older exports hold more date formats, "small" may not hold.
- There is no stop condition (below).

What would have to be true for "don't build it" to be right: finance already handles these exports cheaply, the export folder cannot be accessed, or older exports turn out to be messy enough that it isn't small. The builder has not established whether any of these is true. All three are unknown.

### If you're building: what would make you stop

> **Still worth it if:** unknown. The builder was asked and said, "I don't know."
>
> **Check by:** unknown. No date given.

> **Open question:** There is no stop condition. This should be set before building starts. Example of the shape needed: "worth continuing if the script runs cleanly over all older exports by [date]; if a third date format shows up that can't be handled simply, stop." The builder has to supply the real condition and date.
