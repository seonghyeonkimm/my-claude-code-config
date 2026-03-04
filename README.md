# devkit

Design commands, TDD pipeline, skills, agents, and hooks for Claude Code.

## Plugins

| Plugin | Description | Install |
|--------|-------------|---------|
| **tdd** | TDD pipeline (Red-Green-Refactor) | `devkit@tdd` |
| **design** | RADIO framework design workflow | `devkit@design` |
| **workflow** | PR, review, utilities, hooks | `devkit@workflow` |

## Install

### Personal (user scope)

```bash
/plugin marketplace add seonghyeonkimm/my-claude-code-config
/plugin install devkit@tdd
/plugin install devkit@design
/plugin install devkit@workflow
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
    "devkit@tdd": true,
    "devkit@design": true,
    "devkit@workflow": true
  }
}
```

Install only what you need — each plugin is independent.

## What's included

### `devkit@tdd` — TDD Pipeline

**Commands:**

| Command | Description |
|---------|-------------|
| `/tdd start` | Lightweight TDD workflow (Red-Green-Refactor) |
| `/tdd spec` | Generate FE TechSpec with test cases |
| `/tdd design` | Design data models and components from TechSpec |
| `/tdd issues` | Create Linear issues from TechSpec |
| `/tdd implement` | Full Red→Green→Refactor workflow |
| `/tdd sync` | Gap analysis between spec and implementation |

**Agents:** tdd-designer, tdd-red, tdd-green, tdd-visual, tdd-refactor, tdd-issue-planner, tdd-integrate, tdd-gap-analyzer

**Skills:** fe-techspec, be-techspec, entity-object-pattern, test-case-design, test-file-location

### `devkit@design` — Design Workflow

**Commands:**

| Command | Description |
|---------|-------------|
| `/design` | RADIO framework-based design workflow |

**Agents:** design-explorer

**Skills:** design-radio, design-ddd, design-library

### `devkit@workflow` — Developer Workflow

**Commands:**

| Command | Description |
|---------|-------------|
| `/pr` | Commit and create PR |
| `/think` | Self-consistency reasoning (3 parallel approaches) |
| `/paper` | Interactive paper reading workflow |
| `/wrap` | Extract patterns from session |
| `/do-review` | PR code review (P1/P2/P3) |
| `/pr-review` | Apply reviewer comments |
| `/config-trim` | Remove redundant AI config |

**Skills:** claude-config-patterns, seed-design, playwright-cli, code-dojo, skill-creator

**Hooks:** Stop (notification + memory save), Notification, SessionStart (memory restore), PreCompact (memory snapshot), PreToolUse (strategic compact), PostToolUse (code quality check)

## Sync personal settings

Use `sync.sh` to sync personal config (settings.json, statusline.sh) to `~/.claude/`:

```bash
./sync.sh export   # ~/.claude/ → repo
./sync.sh import   # repo → ~/.claude/
./sync.sh diff     # compare
```

## License

MIT
