# pep-framework-cookiecutter

PEP framework: cookiecutter template, pep-tools.sh and setup script

**Author:** Timo Vlot
**Type:** General Project
**Framework:** PEP (Project Enhancement Packages)

## This repo uses its own framework

Since 2026-11-03 this repo tracks its own changes as PEPs (`PEP-PF-FWK-NNN`,
`docs/peps/`). PEPs 001–007 were raised retroactively from the commit history; from 008
on they are raised as the work happens. A new challenge gets its own PEP, never a number
reused as a "follow-up" (`./tools/pep-tools.sh new-pep`).

- **Nothing at the root reaches other repos.** cookiecutter, `setup-existing.sh`,
  `update-tools` and `update-templates` only read `{{cookiecutter.project_slug}}/`.
  This repo's `docs/`, `tools/`, `.peprc` and `.claude/` stay here.
- **Edit the template copy, never `tools/pep-tools.sh` at the root.** The root copy is
  this repo's installed version. Refresh it like any other repo:
  `./tools/pep-tools.sh update-tools --source '{{cookiecutter.project_slug}}/tools/pep-tools.sh'`.
- Commits go straight to main (`BRANCH_PER_PEP=false`), each with a `PEP-PF-FWK-NNN:` prefix.
- **`pep-tools.sh` and `pep-tools.ps1` stay feature-identical.** Every change goes into
  both, with the same behaviour. The root `tools/` copies and the template copies must be
  byte-identical (`cmp tools/pep-tools.sh '{{cookiecutter.project_slug}}/tools/pep-tools.sh'`).
- **Tests before push:** `tests/test-commit-msg-hook.sh` (both scripts, needs `pwsh` for the
  PowerShell half) and `tests/test-ask.sh`. Neither uses the network.
- **Releasing:** put the change in `CHANGELOG.md`, make sure the version in both script
  headers and help banners matches it, and update `README.md` (command list and upgrade
  notes) and the template's `README.md` where the change is user-visible. Pushing is a
  separate, deliberate step.

## Quick Start

```bash
# Create your first PEP (planning document)
./tools/pep-tools.sh new-pep "Project Foundation"

# List all PEPs
./tools/pep-tools.sh list

# Get help with commands
./tools/pep-tools.sh help
```

## PEP Framework Overview

This project uses **Project Enhancement Packages (PEPs)** for structured development:

- **PEP** = Planning document created BEFORE implementation
- **BLOG** = Build log documenting what was actually implemented
- **Git Integration** = Automatic linking between code and documentation

### Core Workflow

1. **Plan**: Create a PEP describing what you want to build
2. **Implement**: Write code with proper git commit references
3. **Document**: Create a BLOG recording what was actually built

## Configuration

Current project settings (project settings in `.peprc`, personal settings in `.peprc.local`):

- **Author:** Timo Vlot
- **Editor:** vi
- **Project Type:** General
- **Git Hooks:** Enabled (validates PEP references)




## Available Commands

```bash
# PEP management
./tools/pep-tools.sh new-pep [flags] [number] [title]  # Create a PEP (--type, --priority, --abstract, --no-open)
./tools/pep-tools.sh new-branch [pep-num]        # Feature branch (this repo stays on main)
./tools/pep-tools.sh commit <pep-num> [message]  # Commit with the right prefix
./tools/pep-tools.sh list                        # All PEPs with type/status
./tools/pep-tools.sh status                      # Status summary
./tools/pep-tools.sh next                        # Draft/Active PEPs by priority
./tools/pep-tools.sh stubs                       # PEPs still mostly template text
./tools/pep-tools.sh ask <term>                  # Which PEP is about <term>?

# BLOG management
./tools/pep-tools.sh new-blog [blog-num] [pep-num]  # Create implementation blog

# Framework maintenance
./tools/pep-tools.sh doctor [--offline] [--quiet]   # Check config, source, both scripts, the hook
./tools/pep-tools.sh update-tools [--add-ps1]       # Refresh the scripts (see the rule above on the root copy)
./tools/pep-tools.sh update-templates               # Refresh the PEP/BLOG templates
./tools/pep-tools.sh update-hooks                   # Refresh and reinstall the commit-msg hook
./tools/pep-tools.sh ai-block | strip-ai-block | claude-skills | migrate | fix-naming

# Help
./tools/pep-tools.sh help                        # Show all commands
```

## Getting Help

- **Tool usage:** `./tools/pep-tools.sh help`
- **Project issues:** Contact Timo Vlot (timo@vlot.org.uk)
- **Git integration:** Check `.git/hooks/commit-msg` for validation rules
