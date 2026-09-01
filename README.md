# 🏃‍♂️➡️🏃 Baton

**Pass the baton cleanly.** Baton is a portable, harness- and project-agnostic AI **session-handoff skill**: it preserves every important result, decision, work-in-progress boundary, and next move in one evidence-backed operational entrypoint so a fresh session resumes without relying on the prior chat or losing momentum.

> **Website:** https://shanemhamilton.github.io/baton/

Most handoffs answer *what to do next*. Baton also preserves **exactly where useful work stopped, how far the next session should go, and the most efficient reliable way to get there**:

- **Comprehensive continuity** — every material verified or unverified result, in-progress lane, decision, artifact, blocker, failed approach worth preserving, recovery state, and remaining obligation is captured without turning the handoff into a transcript dump.
- **No momentum loss** — the receiving session gets the exact stopping point, next concrete move, active/background work, and a do-not-redo boundary so it refreshes volatile facts and resumes instead of restarting the investigation.
- **Ranked capability and MCP activation** — Baton independently inspects the receiving Claude or Codex runtime, ranks installed and installable paths from authoritative structured connectors through manual fallbacks, and queues each consequential capability with its first use and fallback.
- **Better-tool installation gate** — before accepting CLI, browser, pasted-data, or custom-glue work, Baton researches current provider-primary and runtime-catalog options. If the optimal relevant connector is missing, it recommends the exact Claude/Codex install path and asks the human to connect it or explicitly defer to the documented fallback.
- **Least-sufficient model assignment** — every nontrivial lane gets a mandatory model route: FAST/economy for deterministic legwork such as Haiku-class workers, BALANCED/workhorse for bounded coding and analysis such as Sonnet-class workers, and FRONTIER only for judgment-bearing work with a written lower-tier insufficiency case.
- **Capable-model orchestration** — the strongest main model stays on planning, architecture, synthesis, integration, and final review while efficient workers handle search, inventory, extraction, logs, mechanical coding, and tests. A direct execution shape must still use the lowest sufficient model tier. Baton explicitly evaluates `$efficient-frontier`, `$ponytail`/`ponytail:ponytail`, and more specific installed skills.
- **Right-sized execution and detail** — the handoff author chooses the most efficient adequate `DIRECT`, `LEAN`, `STRUCTURED`, or `METASWARM` shape from dependency, collision, risk, coordination overhead, and main-model opportunity cost, then chooses compact, standard, or governed document depth.
- **Human leverage gate** — when one to three unresolved human-owned choices would materially improve the next session, Baton pauses before finalization with practical options, a recommended default, and an explicit defer path. It repeats the gate until clear and does not stop for facts or technical questions the agent can resolve safely.
- **Adversarial evidence** — live-state claims carry evidence, a falsification pass hunts contradictions, and a fresh challenger reviews every nontrivial handoff when the runtime supports it. Review rigor scales independently from orchestration weight.
- **One-shot momentum** — the next session gets a complete safe execution horizon, milestone-level outcome ladder, verification loop, and hard stop conditions. It keeps going after each green milestone instead of stopping for a recap.
- **Structure before detail** — substantial product and feature work starts with a minimal working architecture or end-to-end walking skeleton, then expands the highest-value slices. Narrow work stays narrow and reuses the existing design.

Every handoff ends with one unambiguous sentence:

> **Read `docs/handoffs/handoff-<timestamp>.md` and do the continuation mission through its stop conditions, starting by `<the first concrete move as a gerund phrase>`.**

---

## Install

Baton is a single Markdown skill file. Install the same file globally for Codex, Claude Code, or both.

### Codex (global — every project)

```bash
mkdir -p ~/.agents/skills/baton
curl -fsSL https://raw.githubusercontent.com/shanemhamilton/baton/main/skills/baton/SKILL.md \
  -o ~/.agents/skills/baton/SKILL.md
```

Or per-project: put it at `.agents/skills/baton/SKILL.md` inside the repo.

### Claude Code (global — every project)

```bash
mkdir -p ~/.claude/skills/baton
curl -fsSL https://raw.githubusercontent.com/shanemhamilton/baton/main/skills/baton/SKILL.md \
  -o ~/.claude/skills/baton/SKILL.md
```

Or per-project: put it at `.claude/skills/baton/SKILL.md` inside the repo.

### Clone

```bash
git clone https://github.com/shanemhamilton/baton.git
mkdir -p ~/.agents/skills ~/.claude/skills
cp -r baton/skills/baton ~/.agents/skills/
cp -r baton/skills/baton ~/.claude/skills/
```

Run either copy command or both. The skill is plain Markdown with YAML frontmatter, so it also works with other agents that read a `skills/` directory.

---

## Use

At the end of a session — or when context is about to compact, or you're switching machines — invoke the installed skill:

- **Codex:** `$baton`
- **Claude Code:** `/baton`

Or say “hand this off” / “I'm running low on context, write a handoff.” Baton will:

1. Reconstruct the objective, definition of done, complete material progress, exact continuity boundary, and remaining obligations.
2. Refresh live repository, tracker, lock, runtime, and external state, then classify load-bearing claims as observed, derived, volatile, or unknown.
3. Pause if one to three human-owned decisions would materially change the outcome or useful one-shot horizon; the human can answer, give feedback, or explicitly defer to an option-preserving boundary. Re-run the gate until clear; otherwise continue without interruption.
4. Discover and rank relevant installed and installable skills, plugins, tools, workers, apps, and MCP connectors in the receiving Claude or Codex runtime.
5. Research provider-primary and runtime-catalog options before accepting a lower-efficiency path; ask the human to install/connect the optimal relevant missing option or explicitly defer to a fallback.
6. Assign every execution lane to its lowest sufficient model tier: Haiku-class/fast for deterministic legwork, Sonnet-class/balanced for bounded coding and analysis, and frontier only with a written lower-tier insufficiency case.
7. Prefer capable-model orchestration for delegable work, explicitly evaluating `$efficient-frontier`, `$ponytail`/`ponytail:ponytail`, and more specific installed skills.
8. Choose the most efficient adequate execution shape and explain what would justify changing it at startup.
9. Choose compact, standard, or governed document depth so narrow work does not inherit orchestration or evidence theater.
10. Define a long one-shot continuation mission, including a walking skeleton first when the work needs new structure.
11. Run a contradiction-seeking pass and right-sized fresh independent challenge.
12. Write `docs/handoffs/handoff-<timestamp>.md`.
13. Emit the single `Read <file> and do ...` sentence to paste into the next session.

---

## What's in a Baton handoff

Narrow, low-uncertainty work uses a compact six-section variant. Standard and governed handoffs use the fuller structure below, expanding evidence only when risk and coordination needs earn it.

| Section | Purpose |
|---|---|
| **0. Receiving Session Contract** | Ranked capability/MCP activation · model-assignment matrix · missing-tool install decision · efficient execution · continuity boundary · one-shot horizon · hard stops |
| 1. Objective | What we're accomplishing and why |
| 2. Definition of Done | Verifiable acceptance criteria |
| 3. Current Status | Done/verified · done/unverified · in-progress · do-not-redo boundary · active/background work · not-started · working tree |
| 4. Truth Ledger & Required Reading | Evidence classes · volatile refreshes · paths + why + what to inspect |
| 5. Key Decisions | Settled or deferred human/technical choices + rationale and revisit triggers |
| 6. Architecture / Walking Skeleton | Existing boundaries · first structural proof · value-ordered expansion |
| 7. Verification Loop | Exact checks and what each proves or cannot prove |
| 8. Questions, Risks & Hard Stops | What truly requires the user, external state, or a safety gate |
| 9. Continuation Mission | Full safe one-shot target · concrete start · keep-going and stop rules |
| 10. Later Horizons | Outcome-level work intentionally outside this session |

---

## Attribution

Baton is a derivative of the **handoff** skill from [**metaswarm**](https://github.com/dsifry/metaswarm) by **Dave Sifry** (MIT License). The core self-contained handoff structure and exact closing-sentence contract come from metaswarm; Baton adds a pre-finalization human leverage gate with explicit defer semantics, comprehensive momentum preservation, capability and MCP activation planning, mandatory least-sufficient model assignment, efficient capable-model orchestration, an evidence-led adversarial review spine, a long one-shot continuation mission, and architecture/walking-skeleton-first guidance for substantial product work. Metaswarm remains a supported choice when its coordination and governance machinery is justified. Full detail in [`NOTICE`](./NOTICE). Grateful thanks to Dave and the metaswarm project.

## License

[MIT](./LICENSE) — © 2026 Shane Hamilton, with portions © 2026 Dave Sifry (metaswarm).
