# {{ cookiecutter.project_name }}

{{ cookiecutter.project_description }}

**Author:** {{ cookiecutter.author_name }}  
**Type:** {{ cookiecutter.project_type.title() }} Project  
**Framework:** PEP (Project Enhancement Packages)

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

```bash
# 1. Plan your work
./tools/pep-tools.sh new-pep "Nutanix Integration"

# 2. Implement with git integration
git checkout -b feature/pep-002-nutanix-integration
git commit -m "pep-002: Add Nutanix API client"
git commit -m "pep-002: Implement cluster monitoring"

# 3. Document implementation
./tools/pep-tools.sh new-blog 1 2
```

## Project-Specific Guidelines

{% if cookiecutter.project_type == 'infrastructure' %}

### Infrastructure Project Guidelines

**Focus Areas:**

- Infrastructure as Code (Terraform, Ansible, Saltstack)
- System deployment and configuration management
- Monitoring and alerting setup
- Disaster recovery and backup procedures

**PEP Requirements:**

- Include infrastructure diagrams and architecture decisions
- Define monitoring requirements and SLAs
- Specify deployment and rollback procedures
- Document security and compliance considerations

**Common Tools Integration:**

```bash
# Reference Terraform configs in PEPs
terraform plan -var-file="vars/pep-XXX.tfvars"

# Document Ansible playbooks in BLOGs  
ansible-playbook -i inventory/pep-XXX playbooks/deploy.yml

# Saltstack state management
salt '*' state.apply pep-XXX-states
```

**Monitoring Integration:**

{% if cookiecutter.zabbix_host %}

- **Zabbix:** {{ cookiecutter.zabbix_host }}
{% endif %}
{% if cookiecutter.grafana_url %}
- **Grafana:** {{ cookiecutter.grafana_url }}
{% endif %}
- All infrastructure changes require monitoring setup
- Include alert thresholds and escalation procedures

{% elif cookiecutter.project_type == 'homelab' %}

### Homelab Project Guidelines

**Focus Areas:**

- Virtual machine and container management
- Network configuration and security
- Service deployment and maintenance
- Hardware upgrades and power management

**PEP Requirements:**

- Document power consumption and cooling impact
- Include network topology changes
- Specify backup and recovery procedures
- Consider family/household impact

**Common Tools Integration:**

```bash
# Proxmox VM management
qm create/start/stop pep-XXX-vm

# Docker service deployment
docker-compose -f docker/pep-XXX-compose.yml up -d

# TrueNAS storage configuration
# Document dataset and share changes

# Network configuration
# Document VLAN and firewall changes
```

**Service Management:**

- Document service dependencies and startup order
- Include troubleshooting procedures for family members
- Plan for maintenance windows and service disruption

{% elif cookiecutter.project_type == 'monitoring' %}

### Monitoring Project Guidelines

**Focus Areas:**

- Dashboard creation and metric visualization
- Alerting configuration and escalation
- Log aggregation and analysis
- Performance monitoring and capacity planning

**PEP Requirements:**

- Define SLAs and alert thresholds
- Include dashboard mockups and metric definitions
- Specify data retention and storage requirements
- Document escalation procedures and on-call processes

**Tools Integration:**

```bash
# Grafana dashboard management
grafana-cli admin export-dashboard pep-XXX

# Zabbix configuration
zabbix_cli trigger create --template pep-XXX

# Prometheus rule management
promtool check rules alerts/pep-XXX-rules.yml
```

**Monitoring Stack:**
{% if cookiecutter.zabbix_host %}

- **Zabbix:** {{ cookiecutter.zabbix_host }}
{% endif %}
{% if cookiecutter.grafana_url %}
- **Grafana:** {{ cookiecutter.grafana_url }}
{% endif %}
- Document all metric sources and collection methods
- Include alert testing and validation procedures

{% elif cookiecutter.project_type == 'software' %}

### Software Project Guidelines

**Focus Areas:**

- Feature development and API design
- Testing strategies and quality assurance
- CI/CD pipeline configuration
- Documentation and user experience

**PEP Requirements:**

- Include API specifications and interface definitions
- Define testing strategies (unit, integration, performance)
- Specify deployment and rollback procedures
- Document breaking changes and migration paths

**Development Integration:**

```bash
# Feature development with PEP tracking
git flow feature start pep-XXX-feature-name

# Testing with PEP reference
pytest tests/test_pep_XXX.py -v --cov

# CI/CD pipeline configuration
# Reference PEP numbers in pipeline definitions
```

**Quality Standards:**

- Code review requirements and approval processes
- Testing coverage thresholds and quality gates
- Documentation requirements for new features
- Performance benchmarks and monitoring

{% elif cookiecutter.project_type == 'automation' %}

### Automation Project Guidelines

**Focus Areas:**

- Workflow automation and process improvement
- Script development and job scheduling
- Error handling and recovery procedures
- Integration between systems and tools

**PEP Requirements:**

- Document workflow diagrams and process flows
- Include error scenarios and recovery procedures
- Specify scheduling and dependency requirements
- Define success criteria and monitoring

**Automation Tools:**

```bash
# Ansible automation workflows
ansible-playbook automation/pep-XXX-workflow.yml

# Cron job and systemd timer setup
systemctl enable pep-XXX-automation.timer

# Saltstack event-driven automation
salt-run reactor.start
```

**Operational Considerations:**

- Include failure scenarios and rollback procedures
- Document manual intervention procedures
- Specify logging and audit requirements
- Plan for maintenance and updates

{% else %}

### General Project Guidelines

**Focus Areas:**

- Clear documentation of all changes
- Structured approach to problem-solving
- Traceability between planning and implementation
- Knowledge sharing and team collaboration

**PEP Requirements:**

- Describe the problem and proposed solution
- Include implementation timeline and milestones
- Define success criteria and validation methods
- Document risks and mitigation strategies

**Best Practices:**

- Create PEPs for significant changes or new features
- Use BLOGs to document deviations from original plans
- Maintain git commit discipline with PEP references
- Regular review and update of documentation

{% endif %}

## Configuration

Current project settings (edit `.peprc` to modify):

- **Author:** {{ cookiecutter.author_name }}
- **Editor:** {{ cookiecutter.default_editor }}
- **Project Type:** {{ cookiecutter.project_type }}
{% if cookiecutter.use_git_hooks == 'y' %}
- **Git Hooks:** Enabled (validates PEP references)
{% endif %}
{% if cookiecutter.require_pep_reference == 'y' %}
- **Strict Mode:** All commits must reference a PEP
{% endif %}
{% if cookiecutter.zabbix_host %}
- **Zabbix:** {{ cookiecutter.zabbix_host }}
{% endif %}
{% if cookiecutter.grafana_url %}
- **Grafana:** {{ cookiecutter.grafana_url }}
{% endif %}

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

## Git Integration

{% if cookiecutter.use_git_hooks == 'y' %}
**Git hooks are enabled** - commit messages are automatically validated.

**Branch Naming Convention:**

- `feature/pep-XXX-description` - New features
- `fix/pep-XXX-issue` - Bug fixes  
- `docs/pep-XXX-update` - Documentation updates

**Commit Message Format:**

- `pep-XXX: description` - Changes related to specific PEP
- `docs: update README` - Documentation-only changes
- `chore: maintenance tasks` - Non-PEP maintenance

**Validation Rules:**

- Commits referencing PEPs must use correct format
- Referenced PEPs must exist
- Warnings for commits to rejected/superseded PEPs

{% else %}
**Git hooks are disabled** - manual discipline required for commit messages.

**Recommended Conventions:**

- Use `pep-XXX: description` format for PEP-related commits
- Create feature branches with `feature/pep-XXX-description` naming
- Reference PEP numbers in pull request descriptions

{% endif %}

## Claude AI Integration

Each PEP includes a **Claude Prompt Context** section designed for AI assistance:

1. **Copy context** from your PEP's "Claude Prompt Context" section
2. **Paste into Claude** with your specific request
3. **Get tailored help** based on your project's requirements and constraints

Example workflow:

```bash
# 1. Create PEP with Claude context
./tools/pep-tools.sh new-pep "Database Migration"

# 2. Copy the "Claude Prompt Context" section from PEP-003

# 3. Use with Claude:
# "Using the context below, help me design the database migration strategy..."
```

## Directory Structure

```bash
{{ cookiecutter.project_slug }}/
├── .peprc                      # Project configuration
├── README.md                   # This file
├── docs/
│   ├── peps/                   # Project Enhancement Packages
│   │   └── pep-001-foundation.md (create this first)
│   ├── blogs/                  # Build Logs (implementation records)
│   └── templates/              # PEP and BLOG templates
│       ├── pep-template.md
│       └── blog-template.md
├── tools/
│   ├── pep-tools.sh           # Management CLI tool
│   └── git-hooks/
│       └── commit-msg         # Git integration hook
└── .gitignore
```

## Best Practices

### PEP Creation

1. **Start with PEP-001** - Document current project state and foundation
2. **Be specific** - Clear requirements and success criteria
3. **Include monitoring** - How will you know it's working?
4. **Plan phases** - Break large changes into manageable pieces
5. **Prepare AI context** - Include information for Claude assistance

### Implementation

1. **Create feature branches** - Use `feature/pep-XXX-description`
2. **Commit frequently** - Reference PEP numbers in all commits
3. **Document deviations** - When implementation differs from plan
4. **Test thoroughly** - Include validation in your implementation
5. **Monitor results** - Verify success criteria are met

### Documentation  

1. **Create BLOGs** - Document what was actually built
2. **Record lessons** - What worked, what didn't, what changed
3. **Update PEPs** - Revise plans when understanding evolves
4. **Maintain traceability** - Link code changes to planning documents
5. **Share knowledge** - Help others understand your decisions

## Getting Help

- **Tool usage:** `./tools/pep-tools.sh help`
- **Framework concepts:** See cookiecutter template documentation
- **Project issues:** Contact {{ cookiecutter.author_name }} ({{ cookiecutter.author_email }})
- **Git integration:** Check `.git/hooks/commit-msg` for validation rules

## Example: Your First PEP

```bash
# Create foundation PEP
./tools/pep-tools.sh new-pep "Project Foundation"

# This creates docs/peps/pep-001-project-foundation.md
# Edit it to document:
# - Current state of the project
# - Technology stack and architecture
# - Development standards and practices  
# - Future enhancement roadmap
```

This PEP-001 becomes your project's "constitution" - a reference document that evolves as your project grows.# {{ cookiecutter.project_name }}

{{ cookiecutter.project_description }}

## PEP Framework Integration

This project uses the **Project Enhancement Package (PEP)** framework for structured development and documentation.

### Quick Guide

```bash
# List current PEPs
./tools/pep-tools.sh list

# Create a new PEP for your enhancement
./tools/pep-tools.sh new-pep "Your Feature Name"

# Work on the feature
git checkout -b feature/pep-XXX-your-feature
# ... make changes ...
git commit -m "pep-XXX: Implement your feature"

# Document implementation
./tools/pep-tools.sh new-blog XXX YYY
```

### Project Information

- **Author:** {{ cookiecutter.author_name }}
- **Type:** {{ cookiecutter.project_type.title() }} Project
- **Framework Version:** 1.0

### Project-Specific Guidelines

{% if cookiecutter.project_type == 'infrastructure' %}

#### Infrastructure Project Guidelines

- **PEPs should address:** Infrastructure changes, system deployments, configuration management
- **Common tools:** Terraform, Ansible, Saltstack, cloud platforms
- **Monitoring:** All infrastructure changes require monitoring setup
- **Testing:** Include infrastructure testing and validation procedures

#### Terraform Integration

```bash
# Reference Terraform configs in PEPs
terraform plan -var-file="vars/pep-XXX.tfvars"
```

#### Ansible Integration  

```bash
# Reference Ansible playbooks in BLOGs
ansible-playbook -i inventory/pep-XXX playbooks/implementation.yml
```

{% elif cookiecutter.project_type == 'homelab' %}

#### Homelab Project Guidelines

- **PEPs should address:** Service deployments, network changes, hardware upgrades
- **Common tools:** Docker, Proxmox, TrueNAS, home automation
- **Documentation:** Include power requirements, network topology changes
- **Backup:** Document backup implications of changes

#### Docker Integration

```bash
# Reference docker-compose files in BLOGs
docker-compose -f docker/pep-XXX-compose.yml up -d
```

#### Service Management

```bash
# Document service dependencies and startup order
systemctl enable pep-XXX-service
```

{% elif cookiecutter.project_type == 'monitoring' %}

#### Monitoring Project Guidelines

- **PEPs should address:** Dashboard creation, alerting setup, metric collection
- **Common tools:** Zabbix, Grafana, Prometheus, ELK stack
- **SLAs:** Define monitoring SLAs and thresholds
- **Escalation:** Document alert escalation procedures

#### Dashboard Development

```bash
# Reference Grafana dashboards in BLOGs
grafana-cli admin export-dashboard pep-XXX-dashboard
```

#### Alert Configuration

```bash
# Document Zabbix trigger configuration
zabbix_cli trigger create --pep-XXX-config
```

{% elif cookiecutter.project_type == 'software' %}

#### Software Project Guidelines

- **PEPs should address:** Feature development, API changes, architecture decisions
- **Common tools:** CI/CD pipelines, testing frameworks, deployment tools
- **Testing:** Include unit, integration, and performance tests
- **Documentation:** Update API docs and user guides

#### Development Workflow

```bash
# Feature development with PEP reference
git flow feature start pep-XXX-feature-name
```

#### Testing Integration

```bash
# Reference test cases in BLOGs
pytest tests/test_pep_XXX.py -v
```

{% elif cookiecutter.project_type == 'automation' %}

#### Automation Project Guidelines

- **PEPs should address:** Workflow automation, script development, process improvements
- **Common tools:** Ansible, Saltstack, Jenkins, GitLab CI
- **Error handling:** Include failure scenarios and rollback procedures
- **Scheduling:** Document automation scheduling and dependencies

#### Script Development

```bash
# Reference automation scripts in BLOGs
ansible-playbook automation/pep-XXX-workflow.yml
```

#### Job Scheduling

```bash
# Document cron/systemd timer setup
systemctl enable pep-XXX-automation.timer
```

{% else %}

#### General Project Guidelines

- **PEPs should address:** Any significant project changes or enhancements
- **Documentation:** Maintain clear documentation for all changes
- **Testing:** Include appropriate testing for your project type
- **Monitoring:** Set up health checks where applicable
{% endif %}

### Configuration

Project-specific settings in `.peprc`:
{% if cookiecutter.zabbix_host %}

- **Zabbix Host:** {{ cookiecutter.zabbix_host }}
{% endif %}
{% if cookiecutter.grafana_url %}
- **Grafana URL:** {{ cookiecutter.grafana_url }}
{% endif %}
- **Default Editor:** {{ cookiecutter.default_editor }}
{% if cookiecutter.require_pep_reference == 'y' %}
- **Strict Mode:** All commits must reference a PEP
{% endif %}

### Current PEPs

| PEP | Title | Status | Author |
|-----|-------|--------|--------|
| 001 | Project Foundation | Draft | {{ cookiecutter.author_name }} |

*Use `./tools/pep-tools.sh list` for current status*

### Getting Help

- **PEP Framework:** See main framework documentation
- **Project Issues:** Contact {{ cookiecutter.author_name }} ({{ cookiecutter.author_email }})
- **Tool Usage:** `./tools/pep-tools.sh help`

### Contributing

1. Create a PEP describing your proposed change
2. Get PEP reviewed and approved
3. Implement following git workflow conventions
4. Document implementation in a BLOG
5. Update this README if needed
