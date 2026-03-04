# devkit

Design commands, TDD pipeline, skills, agents, and hooks for Claude Code.

## Install

### Personal (user scope)

```bash
/plugin marketplace add seonghyeonkimm/my-claude-code-config
/plugin install devkit@devkit
```

### Team project

Add to your project's `.claude/settings.json`:

```jsonc
{
  "extraKnownMarketplaces": {
    "devkit": {
      "source": {
        "source": "github",
        "repo": "seonghyeonkimm/my-claude-code-config"
      }
    }
  },
  "enabledPlugins": {
    "devkit@devkit": true
  }
}
```

Team members will be prompted to install the plugin when they trust the project folder.

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
- **test-case-design** — Test case deduplication rules
- **test-file-location** — Test file co-location convention

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

## Sync personal settings

Use `sync.sh` to sync personal config (settings.json, statusline.sh) to `~/.claude/`:

```bash
./sync.sh export   # ~/.claude/ → repo
./sync.sh import   # repo → ~/.claude/
./sync.sh diff     # compare
```

## License

MIT
