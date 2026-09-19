The guide pushed back on the answer and asked one follow-up question. No document has been written.

> "Faster and better for the team" isn't something I can write down yet. I couldn't tell whether it had been achieved, and someone reading this document later couldn't either. It also doesn't say what's wrong today, which is what intake is meant to capture.
>
> I'll take "faster" first and come back to "better" afterward.
>
> What is the specific thing that's slow right now, and who on the team runs into it? For example, "Sam spends half a day every Friday assembling the weekly report by hand" names a task, a person, and a cost. Use your own words and describe it as it happens today.

To continue, reply with your answer and I'll pass it to the same guide (agent `ac9ba3a2983bdb76a`) so it keeps its context.
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

**Date:**
**Decision:** _build it / don't build it / build something smaller_

This is where you find out whether the thing in `01-intake.md` is worth doing, and what it would actually take.

It ends in a decision. That's the whole point of the file. Everything above the decision is evidence for it.

Don't skip to building because you already opened the editor. This is the moment where stopping is still cheap.

---

## What you looked at

Where you went, what you read, who you talked to. Keep it short, this is just so someone can tell how much digging actually happened.

> 

## What you found

The facts that matter. What their environment actually looks like, what already exists, where the data really lives, what's already been tried.

Be specific. "Their auth is complicated" doesn't help anyone. "They use Okta for staff and a separate Cognito pool for customers, and the two don't talk" does.

> 

## Assumptions

This is the section that saves you.

An assumption is something you're treating as true but haven't verified. Every project rests on a few. The dangerous ones are the ones nobody wrote down, because nobody can check them.

For each one, say what happens if it turns out to be wrong. That's the part that makes people take it seriously.

| What you're assuming | How you'd confirm it | What breaks if it's wrong |
| --- | --- | --- |
|  |  |  |
|  |  |  |

If "what breaks" is "the whole approach," go confirm that one before you write another line of anything.

## Constraints

Things that limit what you can build. Different from assumptions. An assumption might be wrong. A constraint is just true.

- Technical:
- Access (what can you actually get into):
- Time:
- Money:
- Political (who needs to be on board):

## Options you considered

At least two. If you only came up with one option, you haven't finished thinking.

Doing nothing counts as an option and is sometimes the right one.

**Option A:**
- How it works:
- Good because:
- Bad because:

**Option B:**
- How it works:
- Good because:
- Bad because:

## What it would take

Rough. Nobody expects precision here, they expect honesty.

- Effort:
- What it costs to run:
- What you'd need access to:
- Biggest thing that could go wrong:

---

## Decision

Pick one and say why.

**Build it.** You believe it's worth doing and you know roughly how. Go write `03-scope.md`.

**Don't build it.** The idea doesn't survive contact with reality. Write down why in enough detail that nobody re-opens it in three months and repeats the whole exercise. Then stop. This is a good outcome.

**Build something smaller.** The original ask is too big or too vague, but there's a real question buried in it worth answering. Say what the smaller thing is, then go write `03-scope.md` for that.

> **Decision:**
>
> **Because:**

### If you're building: what would make you stop

Write this now, while you're still objective about it.

Pick something specific and pick a date. "This is worth continuing if I can get the extraction step working end to end by the 20th. If I can't, I stop."

The version of you three weekends from now is emotionally invested and will keep going out of stubbornness. This line is the only thing that gets a vote against that.

> **Still worth it if:**
>
> **Check by:**

---

## Prompt for your AI assistant

This one is a research partner and a skeptic. It should be arguing with you, not agreeing.

A warning that matters here more than anywhere else in this folder: do not let an assistant write your assumptions. An assumption you didn't personally make isn't an assumption, it's a guess in your handwriting. When it turns out wrong you'll have no idea why you believed it.

```
I'm doing discovery for a proof of concept. Here's the intake document:

[paste 01-intake.md]

Help me work through discovery. Interview me one question at a time.

Cover: what I've actually looked at, what I found, my assumptions and what
breaks if each one is wrong, real constraints, at least two options I
considered, and rough effort and cost.

Then help me reach one of three decisions: build it, don't build it, or build
something smaller.

Rules:
- One question at a time.
- Be skeptical. If my reasoning is thin, say so and ask me to back it up.
- Never write an assumption I didn't state. If I haven't thought about
  something, ask me about it, don't fill it in.
- Push me on "don't build it." It's a legitimate answer and I'm biased
  against it because I've already started thinking about how to build it.
- If I only give you one option, make me come up with another.
- Anything I don't know goes down as "unknown," not as a plausible guess.
- When we're done, output the completed markdown and nothing else.
```
