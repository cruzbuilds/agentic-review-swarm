# The security charter, observed under Experiment 001

**Status:** an observation, not a change. `security-reviewer`'s charter is unchanged in V2.0.

## What was observed

In [Experiment 001](https://github.com/cruzbuilds/Five-Critics-or-One-Good-Prompt), confirmed security
findings on the subject application were: strong generalist 11, naive generalist 11, `security-reviewer` 7.
One generalist was told to check security; the other was given twenty-four words with no domain map.
Both out-found the specialist in its own lane.

## What the charter is shaped for

Read from first principles rather than from the findings it missed, the charter's Blocking tier is:
credentials in source, untrusted input reaching a query or shell or path, a mutating operation with no
authorization check, IAM and cloud permissions wider than the work needs, long-lived cloud credentials in
CI, and critical dependency vulnerabilities. Its tools are gitleaks, semgrep, and a dependency audit.

That is one threat model, stated well: **this repository leaks or grants access it should not.** It fits the
engagements the charter was written for, where the reviewed change is usually infrastructure, a workflow,
or a handler that touches cloud resources.

Application security is a second threat model: **this application is attacked by its own users and
traffic.** Session lifecycle and revocation, account enumeration, secret strength at boot, security
headers, CSRF posture, rate limiting as a capacity problem, what a share link exposes. In the current
charter those live in the Should fix tier (rate limiting, expiry) or are absent, and "Performance" is
explicitly out of lane. The findings the generalists made and the specialist did not are almost entirely
in this second model.

## Why this is not being fixed by editing the checklist

Adding the eight missed findings to the Blocking list would make the charter pass Experiment 001 and
teach nothing about the next application. The observation is structural: the charter has one threat
model and applications have two, and the second one depends on reasoning across handlers, state and
identity together, which a single lane is not positioned to do. One data point in the experiment
supports that reading: in one swarm run the account-enumeration leak was noticed by `test-reviewer`,
not by `security-reviewer`, which had read the same file.

## What V2.0 does instead

`systems-reviewer`'s mandate includes the interactions between security, identity, state, data and
business logic. That is where the second threat model lives. The specialist keeps the first. Whether
that division recovers the gap is something Experiment 002 can measure, because the specialist's charter
is the same in both versions.

## What would justify a charter change later

Evidence from more than one subject that the first threat model alone is the wrong scope for a
specialist called `security-reviewer`, or that the systems reviewer does not in fact pick up the
second model. Either would be a reason to give the specialist two mandates, documented as its own ADR.
