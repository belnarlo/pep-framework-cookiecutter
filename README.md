# PEP Framework Cookiecutter Template

A cookiecutter template for creating projects with the **Project Enhancement Package (PEP)** framework — a structured approach to project planning and documentation inspired by Python's PEP system.

## What is the PEP Framework?

The PEP Framework provides:

- **PEPs (Project Enhancement Packages)** — Planning documents created BEFORE implementation
- **BLOGs (Build Logs)** — Implementation records documenting what was actually built (optional)
- **Git Integration** — Automatic linking between code changes and planning documents
- **Claude AI Integration (optional)** — Embedded prompts for AI-assisted implementation, off by default

Perfect for system engineers, DevOps teams, homelabbers, and anyone managing infrastructure or software projects — especially across ADO or GitHub project/repo hierarchies.

---

## Quick Start

```bash
# Install cookiecutter
pip install cookiecutter

# Create new project with PEP framework
cookiecutter https://github.com/belnarlo/pep-framework-cookiecutter.git

# Follow prompts, then:
cd your-new-project
./tools/pep-tools.sh new-pep "Project Foundation"
```

---

## Template Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `project_name` | Human-readable project name | "Platform Engineering — Monitoring Stack" |
| `project_slug` | Directory name (auto-generated) | "platform-engineering-monitoring-stack" |
| `project_code` | Short ADO/GitHub project code | "PE" (leave blank for homelab/single-project repos) |
| `repo_code` | Short repository identifier | "MON" (leave blank to use just project code) |
| `author_name` | Your name for templates | "Jane Engineer" |
| `author_email` | Your email address | "jane@company.com" |
| `project_description` | Brief project description | "Monitoring stack for the PE platform" |
| `project_type` | Project category | infrastructure / homelab / monitoring / software / automation / general |
| `use_blogs` | Enable Build Logs feature | y / n (set n for work repos that don't need implementation logs) |
| `include_ai_block` | Include the Claude Prompt Context section in the PEP template | y / n (default n — toggle anytime with `ai-block on\|off`) |
| `default_editor` | Preferred editor | vi / vim / nano / code / zed / emacs |
| `use_git_hooks` | Install git commit validation hook | y / n |
| `require_pep_reference` | Strict mode: all commits must reference a PEP | y / n |
| `zabbix_host` | Monitoring server (optional) | "zabbix.company.com" |
| `grafana_url` | Dashboard URL (optional) | "https://grafana.company.com" |

---

## PEP Naming Scheme

PEP identifiers are built from your `PROJECT_CODE`, `REPO_CODE`, and a sequence number. The type (Feature, Bug, etc.) appears in the filename.

| Config | Display ID | Filename |
|--------|-----------|----------|
| `PROJECT_CODE=PE`, `REPO_CODE=MON` | `PEP-PE-MON-003` | `pep-pe-mon-003-feat-monitoring-setup.md` |
| `REPO_CODE=MON` only | `PEP-MON-003` | `pep-mon-003-feat-monitoring-setup.md` |
| Neither set | `PEP-003` | `pep-003-feat-monitoring-setup.md` |

**10 PEP types**, each with a short slug embedded in the filename:

| Type | Slug | Type | Slug |
|------|------|------|------|
| Project | `proj` | Documentation | `docs` |
| Feature | `feat` | Bug | `bug` |
| Process | `proc` | Enhancement | `enh` |
| Infrastructure | `infra` | Research | `research` |
| Security | `sec` | Performance | `perf` |

**Git commit format** mirrors the filename prefix:

```
pep-pe-mon-003: Add Prometheus scrape configuration
```

---

## What Gets Created

```
your-new-project/
├── .peprc                          # Project config: PROJECT_CODE, REPO_CODE, ENABLE_BLOGS
├── .peprc.local.example            # Personal config template (copy to .peprc.local)
├── README.md                       # Project documentation
├── docs/
│   ├── peps/                       # Project Enhancement Packages
│   ├── blogs/                      # Build Logs (only if ENABLE_BLOGS=y)
│   └── templates/
│       ├── pep-template.md         # PEP template (active — used by new-pep)
│       ├── pep-template-ai.md      # PEP template variant, with the AI block
│       ├── pep-template-no-ai.md   # PEP template variant, without the AI block
│       └── blog-template.md        # BLOG template
├── tools/
│   ├── pep-tools.sh                # Management CLI
│   └── git-hooks/
│       └── commit-msg              # Git validation hook
└── .gitignore
```

---

## Core Workflow

```bash
# 1. Create a PEP — prompts for type, priority, and abstract
./tools/pep-tools.sh new-pep "Monitoring Stack Setup"

# 2. Create the feature branch when you're ready to implement
./tools/pep-tools.sh new-branch 3
# → creates and switches to: feature/pep-pe-mon-003-feat-monitoring-stack-setup

# 3. Implement and commit
./tools/pep-tools.sh commit 3 "Add Prometheus scrape config"
# → git commit -m "pep-pe-mon-003: Add Prometheus scrape config"

# 4. Document with a BLOG (if enabled)
./tools/pep-tools.sh new-blog 1 3
```

---

## CLI Commands

```bash
# PEP management
./tools/pep-tools.sh new-pep [number] [title]     # Create PEP (interactive prompts)
./tools/pep-tools.sh new-branch [pep-num]         # Create feature branch
./tools/pep-tools.sh commit <pep-num> [message]   # Commit with correct format
./tools/pep-tools.sh list                         # List all PEPs with type/status
./tools/pep-tools.sh status                       # Status summary
./tools/pep-tools.sh next                         # Draft/Active PEPs by priority — what to work on next
./tools/pep-tools.sh stubs [--threshold N]        # PEPs still mostly template boilerplate

# Build Logs (when ENABLE_BLOGS=y)
./tools/pep-tools.sh new-blog [blog-num] [pep-num]

# Framework management
./tools/pep-tools.sh migrate [--dry-run]          # Rename old-format PEPs to new scheme
./tools/pep-tools.sh ai-block <on|off|status>     # Switch the PEP template's AI block on/off
./tools/pep-tools.sh strip-ai-block [--dry-run]   # Remove the AI block from existing PEPs
./tools/pep-tools.sh update-tools                 # Update pep-tools.sh from source
./tools/pep-tools.sh update-templates             # Update PEP/BLOG templates from source
./tools/pep-tools.sh help                         # Full help with current repo's ID format
```

---

## Using with Existing Projects

### Method 1: setup-existing.sh

```bash
curl -O https://raw.githubusercontent.com/belnarlo/pep-framework-cookiecutter/main/setup-existing.sh
chmod +x setup-existing.sh
./setup-existing.sh
```

### Method 2: Manual copy

```bash
cookiecutter https://github.com/belnarlo/pep-framework-cookiecutter.git
# Use any project_name, e.g. "temp"

cd /path/to/existing/project
cp -r ../temp/{docs,tools,.peprc,.peprc.local.example,.gitignore} .
./tools/pep-tools.sh init
```

---

## Upgrading an Existing PEP Framework Installation

### Projects that already have `update-tools` (v1.0+)

```bash
# Update the script and templates from your local cookiecutter checkout
./tools/pep-tools.sh update-tools --source /path/to/pep-framework-cookiecutter/\{\{cookiecutter.project_slug\}\}/tools
./tools/pep-tools.sh update-templates

# Re-install the git hook to pick up the new commit format
./tools/pep-tools.sh init
```

### Projects without `update-tools` (original version)

The original `pep-tools.sh` did not include `update-tools`. Copy the new script manually:

```bash
# Option A — from a local checkout of this repo
cp /path/to/pep-framework-cookiecutter/\{\{cookiecutter.project_slug\}\}/tools/pep-tools.sh tools/pep-tools.sh
cp /path/to/pep-framework-cookiecutter/\{\{cookiecutter.project_slug\}\}/tools/git-hooks/commit-msg tools/git-hooks/commit-msg
cp /path/to/pep-framework-cookiecutter/\{\{cookiecutter.project_slug\}\}/docs/templates/pep-template.md docs/templates/pep-template.md
cp /path/to/pep-framework-cookiecutter/\{\{cookiecutter.project_slug\}\}/docs/templates/pep-template-ai.md docs/templates/pep-template-ai.md
cp /path/to/pep-framework-cookiecutter/\{\{cookiecutter.project_slug\}\}/docs/templates/pep-template-no-ai.md docs/templates/pep-template-no-ai.md
cp /path/to/pep-framework-cookiecutter/\{\{cookiecutter.project_slug\}\}/docs/templates/blog-template.md docs/templates/blog-template.md
chmod +x tools/pep-tools.sh tools/git-hooks/commit-msg

# Option B — download directly
curl -o tools/pep-tools.sh \
  https://raw.githubusercontent.com/belnarlo/pep-framework-cookiecutter/main/\{\{cookiecutter.project_slug\}\}/tools/pep-tools.sh
chmod +x tools/pep-tools.sh
```

### After upgrading: configure and migrate

1. Add `PROJECT_CODE`, `REPO_CODE`, and `ENABLE_BLOGS` to your `.peprc`:

```bash
# .peprc — add these lines
PROJECT_CODE="PE"     # short ADO/GitHub project code, or leave blank
REPO_CODE="MON"       # short repo identifier, or leave blank
ENABLE_BLOGS="y"      # set to "n" to disable Build Logs
```

2. Re-install the git hook (it now reads `.peprc` for your ID prefix):

```bash
./tools/pep-tools.sh init
```

3. Preview and apply the PEP rename:

```bash
./tools/pep-tools.sh migrate --dry-run   # see what would change
./tools/pep-tools.sh migrate             # apply
git add -A && git commit -m "chore: migrate PEPs to new naming scheme"
```

---

## Configuration

### `.peprc` (project-level — commit this)

```bash
PROJECT_NAME="My Project"
PROJECT_CODE="PE"         # ADO/GitHub project code (empty = no prefix)
REPO_CODE="MON"           # Repo identifier (empty = no prefix)
ENABLE_BLOGS="y"          # "n" disables Build Logs entirely
REQUIRE_PEP_REFERENCE=false
ZABBIX_HOST=""
GRAFANA_URL=""
```

### `.peprc.local` (personal — gitignored)

```bash
PEP_AUTHOR="Jane Engineer"
DEFAULT_EDITOR="code"
AUTO_OPEN_EDITOR="true"
PEP_FRAMEWORK_SOURCE="/path/to/pep-framework-cookiecutter/{{cookiecutter.project_slug}}/tools"
```

`PEP_FRAMEWORK_SOURCE` is used by `update-tools` and `update-templates` when no `--source` flag is given.

---

## Project Type Customisations

The template generates type-specific README guidelines based on your chosen `project_type`:

| Type | Focus |
|------|-------|
| `infrastructure` | Terraform, Ansible, Saltstack; monitoring and rollback |
| `homelab` | Proxmox, Docker, TrueNAS; power and network |
| `monitoring` | Grafana, Zabbix, Prometheus; SLAs and alerting |
| `software` | CI/CD, testing, API design |
| `automation` | Ansible workflows, scheduling, error handling |
| `general` | Generic best practices |

---

## Claude AI Integration

The PEP template can optionally include a **Claude Prompt Context** section. It's **off by default** — set `include_ai_block=y` when generating the project, or toggle it anytime:

```bash
./tools/pep-tools.sh ai-block on      # switch docs/templates/pep-template.md to the with-AI-block variant
./tools/pep-tools.sh ai-block off     # switch back to the plain variant
./tools/pep-tools.sh ai-block status  # check which one is active
```

`ai-block` only affects the template used by `new-pep` going forward. To remove the Claude Prompt
Context section from PEPs that were already created with it:

```bash
./tools/pep-tools.sh strip-ai-block --dry-run   # preview which PEPs would change
./tools/pep-tools.sh strip-ai-block             # apply
```

With the block enabled:

```bash
# 1. Create PEP with context
./tools/pep-tools.sh new-pep "Database Migration"

# 2. Copy the "Claude Prompt Context" section from the PEP file

# 3. Paste into Claude with your request:
#    "Using the context below, help me design the migration strategy..."
```

---

## Repository Structure (template developers)

```
pep-framework-cookiecutter/
├── README.md                          # This file
├── cookiecutter.json                  # Template prompts and variables
├── sample-pep.md                      # Example PEP showing correct format
├── setup-existing.sh                  # Script for adding framework to existing projects
├── hooks/
│   └── post_gen_project.py            # Post-generation setup
└── {{cookiecutter.project_slug}}/     # Template directory
    ├── .peprc                         # Templated project config
    ├── .peprc.local.example           # Personal config example
    ├── README.md                      # Generated project README
    ├── docs/templates/                # PEP and BLOG templates
    └── tools/
        ├── pep-tools.sh               # Management CLI (v2.0)
        └── git-hooks/
            └── commit-msg             # Commit validation hook
```
