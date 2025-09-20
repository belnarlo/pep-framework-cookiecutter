# PEP Framework Cookiecutter Template

A cookiecutter template for creating projects with the **Project Enhancement Package (PEP)** framework - a structured approach to project planning and documentation inspired by Python's PEP system.

## What is the PEP Framework?

The PEP Framework provides:

- **PEPs (Project Enhancement Packages)** - Planning documents created BEFORE implementation
- **BLOGs (Build Logs)** - Implementation records documenting what was actually built
- **Git Integration** - Automatic linking between code changes and documentation
- **Claude AI Integration** - Embedded prompts for AI-assisted implementation

Perfect for system engineers, DevOps teams, homelabbers, and anyone managing infrastructure or software projects.

## Quick Start

```bash
# Install cookiecutter
pip install cookiecutter

# Create new project with PEP framework
cookiecutter https://github.com/your-org/pep-framework-cookiecutter.git

# Follow prompts, then:
cd your-new-project
./tools/pep-tools.sh new-pep "Project Foundation"
```

## Template Variables

When you run cookiecutter, you'll be prompted for:

| Variable | Description | Example |
|----------|-------------|---------|
| `project_name` | Human-readable project name | "Infrastructure Automation" |
| `project_slug` | Directory name (auto-generated) | "infrastructure-automation" |
| `author_name` | Your name for templates | "Jane Engineer" |
| `author_email` | Your email address | "jane@company.com" |
| `project_description` | Brief project description | "Nutanix platform automation" |
| `project_type` | Project category | infrastructure/homelab/monitoring/software |
| `default_editor` | Preferred editor | vi/vim/nano/code/emacs |
| `use_git_hooks` | Install git hooks | y/n |
| `require_pep_reference` | Strict commit validation | y/n |
| `zabbix_host` | Monitoring server (optional) | "zabbix.company.com" |
| `grafana_url` | Dashboard URL (optional) | "https://grafana.company.com" |

## What Gets Created

```bash
your-new-project/
├── .peprc                          # Project configuration
├── README.md                       # Project-specific documentation
├── docs/
│   ├── peps/                      # Project Enhancement Packages
│   ├── blogs/                     # Build Logs (implementation docs)sh
│   └── templates/
│       ├── pep-template.md        # PEP template
│       └── blog-template.md       # BLOG template
├── tools/
│   ├── pep-tools.sh              # Management CLI
│   └── git-hooks/
│       └── commit-msg            # Git integration
└── .gitignore
```

## Using with Existing Projects

### Method 1: Generate in New Directory and Copy

```bash
# Generate framework
cookiecutter https://github.com/your-org/pep-framework-cookiecutter.git
# project_name: "My Existing Project"
# project_slug: temp-pep-framework

# Copy to existing project
cd /path/to/existing/project
cp -r ../temp-pep-framework/{docs,tools,.peprc,.gitignore} .
rm -rf ../temp-pep-framework

# Initialize
./tools/pep-tools.sh init
```

### Method 2: Use Setup Script (if provided)

```bash
# Download and run setup script
curl -O https://raw.githubusercontent.com/your-org/pep-framework-cookiecutter/main/setup-existing.sh
chmod +x setup-existing.sh
./setup-existing.sh
```

## Core Workflow

### 1. Plan with PEPs

```bash
# Create enhancement planning document
./tools/pep-tools.sh new-pep "Nutanix Integration"
# Edit PEP-002 with requirements, approach, Claude AI prompts
```

### 2. Implement with Git Integration

```bash
# Create feature branch
git checkout -b feature/pep-002-nutanix-integration

# Make changes with proper commit messages
git commit -m "pep-002: Add Nutanix API client"
git commit -m "pep-002: Implement cluster monitoring"
```

### 3. Document with BLOGs

```bash
# Document what was actually built
./tools/pep-tools.sh new-blog 1 2
# Edit BLOG-001 with deviations, lessons learned, ops impact
```

## Project Type Customizations

The template creates project-specific documentation based on your chosen type:

### Infrastructure Projects

- Focus on Terraform, Ansible, Saltstack integration
- Monitoring and alerting requirements
- Deployment and rollback procedures

### Homelab Projects

- Docker and Proxmox integration
- Power and network considerations
- Backup and maintenance procedures

### Monitoring Projects

- Dashboard and alerting setup
- SLA definitions and escalation
- Metric collection and retention

### Software Projects

- CI/CD integration
- Testing strategies
- API documentation requirements

## CLI Tool Usage

```bash
# List all PEPs
./tools/pep-tools.sh list

# Show status summary
./tools/pep-tools.sh status

# Create PEP (auto-numbers if not specified)
./tools/pep-tools.sh new-pep "Feature Description"

# Create implementation blog
./tools/pep-tools.sh new-blog 1 5  # blog-001 for pep-005

# Get help
./tools/pep-tools.sh help
```

## Git Integration Features

- **Branch naming**: `feature/pep-XXX-description`
- **Commit format**: `pep-XXX: description`  
- **Validation**: Git hooks ensure PEP references exist
- **Traceability**: Link all code changes back to planning documents

## Claude AI Integration

Each PEP includes a "Claude Prompt Context" section with:

- Project background and constraints
- Technology stack information
- Specific AI assistance tasks
- Current implementation status

Example usage:

```bash
# Copy Claude context from PEP-005
# Paste into Claude with: "Help me implement the Nutanix API integration"
```

## Configuration

Edit `.peprc` to customize:

- Author information and editor preferences
- Integration URLs (Zabbix, Grafana)
- Git hook behavior
- Project-specific settings

## Best Practices

1. **Start with PEP-001** - Document project foundation
2. **Plan before coding** - Create PEPs for significant changes
3. **Document deviations** - Use BLOGs to record what actually happened
4. **Use consistent naming** - Follow git branch/commit conventions
5. **Include monitoring** - Define success metrics and health checks

## Examples for Linux System Engineers

### Nutanix Migration Project

```bash
cookiecutter pep-framework-cookiecutter
# project_name: "Nutanix Platform Migration" 
# project_type: infrastructure
# zabbix_host: "monitoring.company.com"

cd nutanix-platform-migration
./tools/pep-tools.sh new-pep "Assessment of Packer/Terraform Needs"
./tools/pep-tools.sh new-pep "Saltstack Integration with Nutanix"
```

### Homelab Setup

```bash
cookiecutter pep-framework-cookiecutter
# project_name: "Homelab Infrastructure"
# project_type: homelab
# grafana_url: "http://192.168.1.100:3000"

cd homelab-infrastructure  
./tools/pep-tools.sh new-pep "Proxmox TrueNAS Integration"
./tools/pep-tools.sh new-pep "Docker Service Migration"
```

## Repository Structure for Template Developers

If you're setting up this cookiecutter template:

```bash
pep-framework-cookiecutter/
├── README.md                          # This file
├── cookiecutter.json                  # Template configuration
├── setup-existing.sh                  # Script for existing projects
├── hooks/
│   └── post_gen_project.py           # Post-generation setup
└── {{cookiecutter.project_slug}}/    # Template directory
    ├── .peprc                         # Templated configuration
    ├── README.md                      # Generated project README
    ├── docs/templates/                # PEP/BLOG templates
    ├── tools/                         # Management scripts
    └── .gitignore                     # Standard ignores
```

## Support and Contributing

- **Issues**: GitHub issues for bugs and feature requests
- **Documentation**: All workflows documented in generated project README
- **Customization**: Fork and modify templates for organization needs

## License

MIT License - Feel free to adapt for your organization's needs.
