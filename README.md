# 🏃‍♂️➡️🏃 Baton

**Pass the baton cleanly.** Baton is a portable, framework-agnostic AI **session-handoff skill**: it writes one self-contained document so a fresh session resumes your work with *zero context loss* — and it tells that next session exactly what shape to take.

> **Website:** https://shanemhamilton.github.io/baton/

Most handoffs answer *what to do next*. Baton also answers **who should do it**:

- **Model tier** — the latest **Sonnet** for a bounded task, the latest **Opus** to orchestrate. Written as "latest", never a pinned version, so handoffs never age out.
- **Mode** — `SOLO` (one agent) vs `SWARM` (an orchestrator fanning work out across subagents).
- **Review depth** — a single gate for a small change, or the full adversarial review flow for user-facing / safety-critical work.
- **Parallelism (SWARM)** — front-load planning, then launch the **maximum safe number of subagents at once**. Wide fan-out buys *both* comprehensiveness and speed, because wall-clock is the slowest single agent, not the sum.

Every handoff ends with one unambiguous sentence:

> **Read `docs/handoffs/handoff-<timestamp>.md` and do `<the next concrete action>`.**

---

## Install

Baton is a single Markdown skill file. Drop it where your agent looks for skills.

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
cp -r baton/skills/baton ~/.claude/skills/
```

The skill is plain Markdown with YAML frontmatter, so it also works with Codex and Gemini CLI setups that read a `skills/` directory.

---

## Use

At the end of a session — or when context is about to compact, or you're switching machines — just say:

```
/baton
```

…or "hand this off" / "I'm running low on context, write a handoff." Baton will:

1. Reconstruct the objective, definition of done, and current status (done/verified vs unverified vs in-progress vs not-started).
2. List the exact required reading with `file:line` anchors and *why each matters*.
3. Record the receiving session's config (model tier, mode, review depth, parallelism directive).
4. Write `docs/handoffs/handoff-<timestamp>.md`.
5. Emit the single `Read <file> and do <action>.` sentence to paste into the next session.

---

## What's in a Baton handoff

| Section | Purpose |
|---|---|
| **0. Receiving Session Config** | Model tier · SOLO/SWARM · subagents · review depth · boot command · SWARM fan-out directive |
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

Baton is a derivative of the **handoff** skill from [**metaswarm**](https://github.com/dsifry/metaswarm) by **Dave Sifry** (MIT License). The core document structure, method, template, and anti-patterns come from metaswarm; Baton adds Section 0, the SWARM parallel-fan-out directive, the "latest, never pinned" model rule, and a framework-agnostic generalization. Full detail in [`NOTICE`](./NOTICE). Grateful thanks to Dave and the metaswarm project.

## License

[MIT](./LICENSE) — © 2026 Shane Hamilton, with portions © 2026 Dave Sifry (metaswarm).
