# {{ cookiecutter.project_name }}

{{ cookiecutter.project_description }}

**Author:** {{ cookiecutter.author_name }}  
**Type:** {{ cookiecutter.project_type.title() }} Project  
**Framework:** PEP v2.0

---

## Quick Start

```bash
# Create your first PEP (prompts for type, priority, abstract)
./tools/pep-tools.sh new-pep "Project Foundation"

# When ready to implement, create the feature branch
./tools/pep-tools.sh new-branch 1

# Commit with the correct format
./tools/pep-tools.sh commit 1 "Add initial project structure"

# List all PEPs
./tools/pep-tools.sh list

# Full help (shows this repo's ID format and commit prefix)
./tools/pep-tools.sh help
```

> **Windows:** use `tools/pep-tools.ps1` instead — same commands, same output, e.g. `.\tools\pep-tools.ps1 new-pep "Project Foundation"`.

---

## PEP Naming in This Repo

{% set ns = namespace(pep_id="PEP-001", file_prefix="pep-001-feat-slug.md", commit="pep-001: description") %}
{% if cookiecutter.project_code and cookiecutter.repo_code %}
{% set ns.pep_id = "PEP-" + cookiecutter.project_code + "-" + cookiecutter.repo_code + "-001" %}
{% set ns.file_prefix = "pep-" + cookiecutter.project_code|lower + "-" + cookiecutter.repo_code|lower + "-001-feat-slug.md" %}
{% set ns.commit = "pep-" + cookiecutter.project_code|lower + "-" + cookiecutter.repo_code|lower + "-001: description" %}
{% elif cookiecutter.repo_code %}
{% set ns.pep_id = "PEP-" + cookiecutter.repo_code + "-001" %}
{% set ns.file_prefix = "pep-" + cookiecutter.repo_code|lower + "-001-feat-slug.md" %}
{% set ns.commit = "pep-" + cookiecutter.repo_code|lower + "-001: description" %}
{% elif cookiecutter.project_code %}
{% set ns.pep_id = "PEP-" + cookiecutter.project_code + "-001" %}
{% set ns.file_prefix = "pep-" + cookiecutter.project_code|lower + "-001-feat-slug.md" %}
{% set ns.commit = "pep-" + cookiecutter.project_code|lower + "-001: description" %}
{% endif %}

| | Format |
|---|---|
| **Display ID** | `{{ ns.pep_id }}` |
| **Filename** | `{{ ns.file_prefix }}` |
| **Commit** | `{{ ns.commit }}` |
| **Branch** | `feature/{{ ns.file_prefix[:-3] }}` |

Run `./tools/pep-tools.sh help` at any time to see the current repo's exact format.

---

## Workflow

```bash
# 1. Plan — create PEP (type, priority, abstract captured at creation time)
./tools/pep-tools.sh new-pep "Feature Name"

# 2. Branch — when you're ready to start work
./tools/pep-tools.sh new-branch <num>

# 3. Commit — correct format enforced automatically
./tools/pep-tools.sh commit <num> "What this commit does"
# or: git commit -m "{{ ns.commit }}"

{% if cookiecutter.use_blogs == 'y' %}
# 4. Document — record what was actually built vs. the plan
./tools/pep-tools.sh new-blog <blog-num> <pep-num>
{% endif %}
```

---

## Project-Specific Guidelines

{% if cookiecutter.project_type == 'infrastructure' %}

### Infrastructure Guidelines

- **PEPs should cover:** Infrastructure changes, system deployments, configuration management
- **Common tools:** Terraform, Ansible, Saltstack, cloud platforms
- **Required in every PEP:** Deployment procedure, rollback plan, monitoring requirements

```bash
# Reference Terraform configs in PEPs
terraform plan -var-file="vars/{{ ns.pep_id }}.tfvars"

# Document Ansible playbooks in BLOGs
ansible-playbook -i inventory/{{ ns.pep_id }} playbooks/deploy.yml
```

{% if cookiecutter.zabbix_host %}
**Zabbix:** {{ cookiecutter.zabbix_host }} — all infrastructure changes require monitoring setup.
{% endif %}
{% if cookiecutter.grafana_url %}
**Grafana:** {{ cookiecutter.grafana_url }}
{% endif %}

{% elif cookiecutter.project_type == 'homelab' %}

### Homelab Guidelines

- **PEPs should cover:** Service deployments, network changes, hardware upgrades
- **Common tools:** Proxmox, Docker, TrueNAS, home automation
- **Required in every PEP:** Power impact, network changes, backup implications

```bash
# Proxmox VM management
qm create/start/stop  # reference {{ ns.pep_id }} in notes

# Docker service deployment
docker-compose -f docker/{{ ns.pep_id }}-compose.yml up -d
```

{% elif cookiecutter.project_type == 'monitoring' %}

### Monitoring Guidelines

- **PEPs should cover:** Dashboard creation, alerting setup, metric collection
- **Common tools:** Zabbix, Grafana, Prometheus, ELK
- **Required in every PEP:** SLA definition, alert thresholds, escalation path

```bash
# Export Grafana dashboard
grafana-cli admin export-dashboard {{ ns.pep_id }}

# Check Prometheus rules
promtool check rules alerts/{{ ns.pep_id }}-rules.yml
```

{% if cookiecutter.zabbix_host %}
**Zabbix:** {{ cookiecutter.zabbix_host }}
{% endif %}
{% if cookiecutter.grafana_url %}
**Grafana:** {{ cookiecutter.grafana_url }}
{% endif %}

{% elif cookiecutter.project_type == 'software' %}

### Software Guidelines

- **PEPs should cover:** Feature development, API changes, architecture decisions
- **Required in every PEP:** Testing strategy, API spec, deployment procedure, rollback

```bash
# Feature branch
git checkout -b feature/{{ ns.file_prefix[:-3] }}

# Run tests referencing the PEP
pytest tests/test_{{ ns.pep_id|lower|replace("-", "_") }}.py -v
```

{% elif cookiecutter.project_type == 'automation' %}

### Automation Guidelines

- **PEPs should cover:** Workflow automation, script development, process improvements
- **Required in every PEP:** Error handling, rollback procedure, scheduling, audit logging

```bash
# Reference automation scripts
ansible-playbook automation/{{ ns.pep_id }}-workflow.yml

# Document timer setup
systemctl enable {{ ns.pep_id|lower }}-automation.timer
```

{% else %}

### General Guidelines

- **PEPs should cover:** Any significant project changes or enhancements
- **Required in every PEP:** Problem description, proposed solution, success criteria, risks
- Create PEPs for significant changes; use commits with `{{ ns.commit }}` format

{% endif %}

---

## Available Commands

```bash
# PEP management
./tools/pep-tools.sh new-pep [number] [title]     # Create PEP
./tools/pep-tools.sh new-branch [pep-num]         # Create feature branch
./tools/pep-tools.sh commit <pep-num> [message]   # Commit with correct prefix
./tools/pep-tools.sh list                         # List all PEPs
./tools/pep-tools.sh status [--since YYYY-MM-DD]  # Status summary, by-status listing, flags bad
                                                   # statuses, and (with --since) a changes report
./tools/pep-tools.sh migrate [--dry-run]          # Rename PEPs to current scheme

{% if cookiecutter.use_blogs == 'y' %}
# Build Logs
./tools/pep-tools.sh new-blog [blog-num] [pep-num]
{% endif %}

# Framework maintenance
./tools/pep-tools.sh update-tools                 # Update pep-tools.sh
./tools/pep-tools.sh update-templates             # Update PEP/BLOG templates
./tools/pep-tools.sh help                         # Full help
```

On Windows, use `tools/pep-tools.ps1` with the same commands and arguments (e.g. `.\tools\pep-tools.ps1 status --since 2026-07-01`).

---

## Configuration

| File | Purpose |
|------|---------|
| `.peprc` | Project settings — `PROJECT_CODE`, `REPO_CODE`, `ENABLE_BLOGS` — **commit this** |
| `.peprc.local` | Personal settings — author, editor, `PEP_FRAMEWORK_SOURCE` — **gitignored** |

```bash
# Key .peprc settings
PROJECT_CODE="{{ cookiecutter.project_code }}"
REPO_CODE="{{ cookiecutter.repo_code }}"
ENABLE_BLOGS="{{ cookiecutter.use_blogs }}"
```

{% if cookiecutter.use_git_hooks == 'y' %}

## Git Integration

Git hooks are **enabled** — commit messages are validated automatically.

- Commits referencing a PEP must use format: `{{ ns.commit }}`
- Referenced PEP file must exist
- Warns on commits to Rejected or Superseded PEPs
- Non-PEP commits: use `docs:`, `chore:` prefixes

{% if cookiecutter.require_pep_reference == 'y' %}
**Strict mode is on** — all commits must reference a PEP (except `docs:`, `chore:`, merges).
{% endif %}

{% endif %}

---

## Claude AI Integration

Each PEP includes a **Claude Prompt Context** section. To use it:

1. Create a PEP: `./tools/pep-tools.sh new-pep "Your Feature"`
2. Fill in the context section in the PEP file
3. Copy that section and paste it into Claude with your request

---

## Getting Help

- **Tool commands:** `./tools/pep-tools.sh help`
- **Project questions:** {{ cookiecutter.author_name }} ({{ cookiecutter.author_email }})
- **Git hook rules:** `.git/hooks/commit-msg` (installed from `tools/git-hooks/commit-msg`)
