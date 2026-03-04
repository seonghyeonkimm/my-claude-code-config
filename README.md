# my-claude-code-config

Personal Claude Code workflows — design commands, TDD pipeline, skills, and hooks.

## Install

```bash
# Via Claude Code CLI
/install github:seonghyeonkimm/my-claude-code-config
```

## What's included

### Commands

| Command | Description |
|---------|-------------|
| `/design` | RADIO framework-based design workflow |
| `/pr` | Commit and create PR |
| `/think` | Self-consistency reasoning (3 parallel approaches) |
| `/paper` | Interactive paper reading workflow |
| `/wrap` | Extract patterns from session |
| `/tdd start` | Lightweight TDD workflow (Red-Green-Refactor) |
| `/tdd spec` | Generate FE TechSpec with test cases |
| `/tdd design` | Design data models and components from TechSpec |
| `/tdd issues` | Create Linear issues from TechSpec |
| `/tdd implement` | Full Red→Green→Refactor workflow |
| `/tdd sync` | Gap analysis between spec and implementation |

### Skills

- **design-radio** — RADIO framework checklists
- **design-ddd** — DDD domain modeling criteria
- **design-library** — Library/API design criteria
- **be-techspec** — Backend TechSpec template
- **fe-techspec** — Frontend TechSpec template
- **entity-object-pattern** — Entity Object pattern
- **claude-config-patterns** — Agent/Skill/Command file patterns
- **seed-design** — Seed Design component reference
- **playwright-cli** — Browser automation reference
- **code-dojo** — Interactive code learning
- **skill-creator** — Skill generation guide

### Agents

- **design-explorer** — Codebase exploration for design context
- **tdd-red/green/refactor** — TDD phase agents
- **tdd-designer** — Design phase agent
- **tdd-issue-planner** — Issue planning agent
- **tdd-integrate** — Integration QA agent
- **tdd-gap-analyzer** — Gap analysis agent
- **tdd-visual** — Visual verification agent

### Hooks

- **Stop** — Desktop notification + session memory save
- **Notification** — Desktop notification
- **SessionStart** — Memory restore
- **PreCompact** — Memory snapshot before compaction
- **PreToolUse (Edit|Write)** — Strategic compact suggestion
- **PostToolUse (Edit|Write)** — Code quality check (Biome + TypeScript)

## License

MIT
