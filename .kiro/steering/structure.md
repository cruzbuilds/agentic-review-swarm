# Repository structure

```
.
├── .claude-plugin/marketplace.json   one plugin per agent, installable separately
├── agents/
│   └── <name>/
│       ├── README.md                 install, what it blocks on, seeds
│       ├── charter.md                the source of truth
│       ├── adapters/*.yaml           frontmatter per tool
│       ├── dist/<tool>/<name>.md     generated, committed, never hand-edited
│       ├── seeds/<case>/             one planted defect + expected.md; systems-reviewer seeds are multi-file interactions; swarm seeds are saved reports
│       └── .claude-plugin/plugin.json
├── shared/                           output format + review contract, prepended into every dist
├── scripts/                          build, run-seeds, install-kiro, check
├── engagement/                       intake, discovery, scope, handoff for this repo itself
├── docs/design.md                    the shape and the reasoning
├── docs/decisions/                   ADRs
├── docs/research/                    the research record: map, Experiment 001, V2, proposed V3, paper
├── docs/evals/                       frozen evaluation runs with raw reports; never edited after freezing
├── docs/eval-log.md                  chronological log of what evaluation found
├── AGENTS.md                         working agreement for agents changing this repo
└── .kiro/steering/                   these files
```

## Rules

- `charter.md` is edited. `dist/` is generated. Never the other way around.
- Every agent has at least five seeds and one of them is clean.
- `shared/` changes are the most expensive changes in the repo. Every agent inherits them.
- No `src/` or `tests/`. This repo has no application code. The seeds are the tests.
