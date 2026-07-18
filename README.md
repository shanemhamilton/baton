# 🏃‍♂️➡️🏃 Baton

**Pass the baton cleanly.** Baton is a portable, framework-agnostic AI **session-handoff skill**: it writes one self-contained operational entrypoint so a fresh session resumes without relying on the prior chat — and it tells that next session exactly how to operate.

> **Website:** https://shanemhamilton.github.io/baton/

Most handoffs answer *what to do next*. Baton also preplans **how the next session should operate**:

- **Main agent** — normally the session orchestrator, explicitly following **`$efficient-frontier`** (or an embedded equivalent contract when the skill is unavailable) and retaining architecture, risk, integration, synthesis, and final review.
- **Specialists and models** — verified domain-specific agent types and fit-for-purpose models for each likely lane: frontier choices such as Claude Opus or GPT-5.6 Sol for judgment, balanced choices such as Claude Sonnet or GPT-5.6 Terra for bounded work, and Codex-Spark only when available and suited to tight latency-sensitive iteration.
- **Deployment waves** — launch triggers, dependencies, disjoint ownership, single-writer surfaces, authority/approval boundaries, verification, and copy-ready subagent packets.
- **Optimal concurrency** — the smallest high-value parallel batch that fits the runtime and collision map, followed by independent review. `SOLO` is the justified exception, not the default.

Every handoff ends with one unambiguous sentence:

> **Read `docs/handoffs/handoff-<timestamp>.md` and do `<the next concrete action>`.**

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

1. Reconstruct the objective, definition of done, and current status (done/verified vs unverified vs in-progress vs not-started).
2. List the exact required reading with `file:line` anchors and *why each matters*.
3. Record the receiving session's orchestration contract (main-agent role, verified specialist/model routing, deployment waves, review depth, and dispatch packets).
4. Write `docs/handoffs/handoff-<timestamp>.md`.
5. Emit the single `Read <file> and do <action>.` sentence to paste into the next session.

---

## What's in a Baton handoff

| Section | Purpose |
|---|---|
| **0. Receiving Session Orchestration** | `$efficient-frontier` main agent · specialist/model routing · waves · ownership · dispatch packets · review |
| 1. Objective | What we're accomplishing and why |
| 2. Definition of Done | Verifiable acceptance criteria |
| 3. Current Status | Done/verified · done/unverified · in-progress · not-started · working tree |
| 4. Required Reading | Table of paths + why + what to look for |
| 5. Key Decisions | Settled choices + rationale (so they aren't reopened) |
| 6. Code Map | Where the load-bearing code lives |
| 7. How to Verify | The exact test/lint/build commands |
| 8. Open Questions / Blockers | What needs the user or an external dependency |
| 9. Next Action | The one concrete next step, expanded |
| 10. Remaining Work | Everything after the next action |

---

## Attribution

Baton is a derivative of the **handoff** skill from [**metaswarm**](https://github.com/dsifry/metaswarm) by **Dave Sifry** (MIT License). The core document structure, method, template, and anti-patterns come from metaswarm; Baton adds Section 0's `$efficient-frontier` orchestration contract, verified specialist/model routing, collision-aware deployment waves, and copy-ready dispatch packets, plus a framework-agnostic generalization. Full detail in [`NOTICE`](./NOTICE). Grateful thanks to Dave and the metaswarm project.

## License

[MIT](./LICENSE) — © 2026 Shane Hamilton, with portions © 2026 Dave Sifry (metaswarm).
