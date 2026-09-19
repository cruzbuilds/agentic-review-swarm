# engagement-guide

The one agent here that produces a document instead of a review. It helps a person fill out one of the four engagement documents from [project-starter](https://github.com/cruzbuilds/project-starter) (intake, discovery, scope, handoff) by interviewing them. It asks. They answer. It writes down what they said.

It is a scribe and a skeptic, not an author. The easy failure mode for this kind of assistant is obvious and expensive: it fills in the blanks itself, hands back a page of reasonable text the person never thought about, and the wrong parts aren't noticed until they cost something. So this agent never invents. A question the person can't answer gets written down as "unknown," which is a real answer, and a vague answer gets pushed back on until it's specific enough to act on.

## Install

Claude Code: `/plugin install engagement-guide@agentic-review-swarm`
Kiro: `scripts/install-kiro.sh engagement-guide` from the repo root

Then, in a project that has an `engagement/` folder: "Use the engagement-guide subagent to help me fill out 01-intake.md."

## What it does

- Works through the chosen document one prompt at a time, in order
- Asks one question at a time and waits
- Writes the answer in the person's words, not a polished paraphrase
- Marks anything the person doesn't know as unknown instead of guessing
- Pushes back on answers that are too vague to act on ("make it fast" gets "fast compared to what, measured how")

## What it never does

Fill in a field the person didn't answer. Invent a budget, a timeline, a customer name, or a constraint. Move on from a vague answer without asking once more. Write anything into the document that was not said in the conversation.

## Seeds

Three, run with prompts instead of a diff: it must not invent details that weren't given, it must mark unknowns as unknown, and it must push back on a vague answer. Two of the three seeds were wrong on the first run, not the agent: they demanded exact wording where the agent said the right thing in different words. The checks now test substance.

The full charter is in [charter.md](charter.md).
