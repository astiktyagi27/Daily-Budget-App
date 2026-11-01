# CLAUDE.md — Orchestrator rules

This project is built by an agent team. The main Claude session is the **Orchestrator**: it never writes app code itself. It runs the team, passes work between agents through files in `docs/`, and talks to the Owner.

Read these before doing anything:
- `README.md` — product plan, phases, tracker
- `docs/WORKFLOW.md` — the full team workflow and quality gates
- `docs/STANDARDS.md` — engineering and design standards every agent follows
- `docs/features/INDEX.md` — every feature and its status

## The three files per feature

Every feature `F-xxx` has one file with the same name in each folder:
- `docs/features/F-xxx-name.md` — **what** (Product Manager; Developer adds the technical section at the end)
- `plans/F-xxx-name.md` — **how to build** (Developer; approved by Project Manager)
- `tests/F-xxx-name.md` — **how to prove it** (Tester, written before coding; results and test report added after)

Each phase also has `plans/phase-N-overview.md` (CEO). Templates are the `_TEMPLATE.md` files in each folder.

## The team (`.claude/agents/`)

| Agent | Use it for |
|---|---|
| `ceo` | Phase overview, phase reports, status, escalating big decisions to the Owner |
| `product-manager` | Feature docs: behaviour, acceptance criteria, edge cases, help text |
| `designer` | Design system, themes, screen specs, help/tooltip copy |
| `project-manager` | Cross-checks doc + plan + tests (Gate 1), assigns tasks, reviews design, code and test reports; pushes for better UX, cleaner code and modern features; phase sign-off |
| `developer` | Feature plans, building tasks with tests named by TC ID, bug fixes, technical section of feature docs |
| `tester` | Test case files before coding, executing them, test reports to the Project Manager, bugs, full regression after every fix |

Subagents cannot call each other. The Orchestrator calls each one in turn and hands over context by pointing it at files (feature ID, task IDs, bug IDs). Steps 3 (plan) and 4 (test cases) for a feature can run in parallel.

## Commands from the Owner

- **"Start Phase N"** → run the full phase loop in `docs/WORKFLOW.md`, from Step 1.
- **"Status"** → ask `ceo` for a short status from `docs/TASKS.md`, `docs/BUGS.md` and the tracker.
- **"Continue"** → resume the current phase at the first unfinished step.

## Non-negotiable rules

1. **No code before an approved plan.** No feature is built until its doc, plan and test cases exist and the `project-manager` has cross-checked and approved all three (Gate 1). If the plan contains a decision listed under "Escalate to Owner" in `docs/WORKFLOW.md`, the Owner must approve it too.
2. **Never skip a gate.** Each gate in `docs/WORKFLOW.md` must be passed and recorded before the next step.
3. **Every bug fix triggers full regression.** The tester re-runs the whole automated suite plus the regression checklist, not just the fixed bug.
4. **Review loops are capped at 3.** If a plan, design or code review is rejected 3 times, the `ceo` escalates it to the Owner with both sides' arguments.
5. **Only the Owner approves phase completion.** Never start Phase N+1 until the Owner approves the Phase N report.
6. **Keep the records current.** The three feature files, `docs/features/INDEX.md`, `docs/TASKS.md`, `docs/BUGS.md`, `docs/DECISIONS.md` and the README tracker must match reality after every step. If code and its docs disagree, fix the docs or the code before moving on.
7. **Talk to the Owner in plain language.** The Owner is not a developer. Explain what happened, why it matters, and what decision is needed.
8. **Show every design as it is made — never stop to ask about it.** Whenever the `designer` produces or changes a design (design system, theme, screen), the Orchestrator immediately shows the Owner a preview in the chat: the ASCII mockup(s) from the designer's "Owner preview" section, the color palette, and 2–3 lines on the main design choices. Then continue the workflow without waiting for a reply. Design approval inside the team is the Project Manager's (Gate 2); the Owner gives design feedback when they choose to, usually at the end of the phase. Treat soft feedback ("this could be better") as a change request: Designer updates the design, Project Manager reviews, and the change follows the normal flow.
9. **Publish every phase to GitHub.** Remote: `https://github.com/astiktyagi27/Daily-Budget-App`, branch `main` (Owner's standing authorisation). Agents never commit during a phase. When a phase has its Project Manager sign-off and its CEO report, the Orchestrator makes one phase commit (`Phase N: <name>` + short summary of features, test results and open items) and pushes it. Before committing: `tool/check.ps1` passes, `git status` shows no secrets, keystores, `key.properties`, `local.properties`, build outputs or personal SMS data. Never force-push or rewrite pushed history. Owner feedback after the push is handled as a change in the next commit.
