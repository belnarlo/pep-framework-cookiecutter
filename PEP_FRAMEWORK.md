# pep-framework-cookiecutter

PEP framework: cookiecutter template, pep-tools.sh and setup script

**Author:** Timo Vlot
**Type:** General Project
**Framework:** PEP (Project Enhancement Packages)

## This repo uses its own framework

Since 2026-11-03 this repo tracks its own changes as PEPs (`PEP-PF-FWK-NNN`,
`docs/peps/`). PEPs 001–007 were raised retroactively from the commit history.

- **Nothing at the root reaches other repos.** cookiecutter, `setup-existing.sh`,
  `update-tools` and `update-templates` only read `{{cookiecutter.project_slug}}/`.
  This repo's `docs/`, `tools/`, `.peprc` and `.claude/` stay here.
- **Edit the template copy, never `tools/pep-tools.sh` at the root.** The root copy is
  this repo's installed version. Refresh it like any other repo:
  `./tools/pep-tools.sh update-tools --source '{{cookiecutter.project_slug}}/tools/pep-tools.sh'`.
- Commits go straight to main (`BRANCH_PER_PEP=false`).

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
# PEP Management
./tools/pep-tools.sh new-pep [number] [title]    # Create new PEP
./tools/pep-tools.sh list                        # List all PEPs
./tools/pep-tools.sh status                      # Show status summary

# BLOG Management
./tools/pep-tools.sh new-blog [blog-num] [pep-num]  # Create implementation blog

# Help
./tools/pep-tools.sh help                        # Show all commands
```

## Getting Help

- **Tool usage:** `./tools/pep-tools.sh help`
- **Project issues:** Contact Timo Vlot (timo@vlot.org.uk)
- **Git integration:** Check `.git/hooks/commit-msg` for validation rules
