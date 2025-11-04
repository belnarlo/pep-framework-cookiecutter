#!/bin/bash
# Setup script for adding PEP framework to existing projects
# This script automates the process of adding the framework without cookiecutter

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

TEMPLATE_REPO="https://github.com/belnarlo/pep-framework-cookiecutter.git"
TEMP_DIR=$(mktemp -d)

log() {
    local level="$1"
    shift
    local message="$*"
    
    case "$level" in
        "INFO")
            echo -e "${GREEN}[INFO]${NC} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message" >&2
            ;;
        "STEP")
            echo -e "${BLUE}[STEP]${NC} $message"
            ;;
    esac
}

show_help() {
    cat << EOF
${BLUE}PEP Framework Setup for Existing Projects${NC}

This script adds the PEP framework to an existing project by:
1. Prompting for project configuration
2. Downloading framework files
3. Setting up directory structure
4. Configuring git integration

Usage: $0 [options]

Options:
  -h, --help     Show this help message
  -i, --interactive  Interactive configuration (default)
  -q, --quiet    Minimal prompts, use defaults

Examples:
  $0              # Interactive setup
  $0 --quiet      # Quick setup with defaults

Prerequisites:
  - git
  - curl or wget
  - Existing git repository (recommended)
EOF
}

cleanup() {
    log "INFO" "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

check_prerequisites() {
    log "STEP" "Checking prerequisites..."
    
    if ! command -v git >/dev/null 2>&1; then
        log "ERROR" "git is required but not installed"
        exit 1
    fi
    
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        log "ERROR" "curl or wget is required but neither is installed"
        exit 1
    fi
    
    if [ ! -d ".git" ]; then
        log "WARN" "Not in a git repository"
        echo -n "Continue anyway? [y/N]: "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
    
    log "INFO" "Prerequisites satisfied"
}

get_user_input() {
    local quiet_mode="$1"
    
    if [ "$quiet_mode" = "true" ]; then
        PROJECT_NAME=$(basename "$(pwd)")
        AUTHOR_NAME=$(git config user.name 2>/dev/null || echo "Unknown Author")
        AUTHOR_EMAIL=$(git config user.email 2>/dev/null || echo "user@example.com")
        PROJECT_DESCRIPTION="Project with PEP framework"
        PROJECT_TYPE="general"
        DEFAULT_EDITOR="vi"
        USE_GIT_HOOKS="y"
        REQUIRE_PEP_REFERENCE="n"
        ZABBIX_HOST=""
        GRAFANA_URL=""
        return
    fi
    
    log "STEP" "Gathering project information..."
    
    echo -n "Project name [$(basename "$(pwd)")]: "
    read -r PROJECT_NAME
    PROJECT_NAME=${PROJECT_NAME:-$(basename "$(pwd)")}
    
    echo -n "Author name [$(git config user.name 2>/dev/null || echo "Your Name")]: "
    read -r AUTHOR_NAME
    AUTHOR_NAME=${AUTHOR_NAME:-$(git config user.name 2>/dev/null || echo "Your Name")}
    
    echo -n "Author email [$(git config user.email 2>/dev/null || echo "your.email@example.com")]: "
    read -r AUTHOR_EMAIL
    AUTHOR_EMAIL=${AUTHOR_EMAIL:-$(git config user.email 2>/dev/null || echo "your.email@example.com")}
    
    echo -n "Project description: "
    read -r PROJECT_DESCRIPTION
    PROJECT_DESCRIPTION=${PROJECT_DESCRIPTION:-"Project with PEP framework"}
    
    echo "Project type:"
    echo "  1) infrastructure"
    echo "  2) homelab" 
    echo "  3) monitoring"
    echo "  4) software"
    echo "  5) automation"
    echo "  6) general"
    echo -n "Choose [1-6, default 6]: "
    read -r project_type_choice
    
    case "$project_type_choice" in
        1) PROJECT_TYPE="infrastructure" ;;
        2) PROJECT_TYPE="homelab" ;;
        3) PROJECT_TYPE="monitoring" ;;
        4) PROJECT_TYPE="software" ;;
        5) PROJECT_TYPE="automation" ;;
        *) PROJECT_TYPE="general" ;;
    esac
    
    echo "Default editor:"
    echo "  1) vi"
    echo "  2) vim"
    echo "  3) nano"
    echo "  4) code (VS Code)"
    echo "  5) emacs"
    echo -n "Choose [1-5, default 1]: "
    read -r editor_choice
    
    case "$editor_choice" in
        1) DEFAULT_EDITOR="vi" ;;
        2) DEFAULT_EDITOR="vim" ;;
        3) DEFAULT_EDITOR="nano" ;;
        4) DEFAULT_EDITOR="code" ;;
        5) DEFAULT_EDITOR="emacs" ;;
        *) DEFAULT_EDITOR="vi" ;;
    esac
    
    echo -n "Install git hooks for PEP validation? [Y/n]: "
    read -r USE_GIT_HOOKS
    USE_GIT_HOOKS=${USE_GIT_HOOKS:-y}
    
    echo -n "Require all commits to reference a PEP? [y/N]: "
    read -r REQUIRE_PEP_REFERENCE
    REQUIRE_PEP_REFERENCE=${REQUIRE_PEP_REFERENCE:-n}
    
    echo -n "Zabbix host (optional): "
    read -r ZABBIX_HOST
    
    echo -n "Grafana URL (optional): "
    read -r GRAFANA_URL
}

download_framework() {
    log "STEP" "Downloading framework files..."

    local current_dir="$(pwd)"
    cd "$TEMP_DIR"

    if command -v git >/dev/null 2>&1; then
        if git clone --depth 1 "$TEMPLATE_REPO" template; then
            log "INFO" "Successfully cloned template repository"

            if [ -d "template/{{cookiecutter.project_slug}}" ]; then
                log "INFO" "Found cookiecutter template directory"
                # Copy both regular files and dotfiles
                shopt -s dotglob
                cp -r "template/{{cookiecutter.project_slug}}"/* .
                shopt -u dotglob
            else
                log "WARN" "Template directory not found in expected location"
                log "INFO" "Creating framework files manually..."
                create_framework_manually
            fi
        else
            log "WARN" "Could not clone template repository"
            log "INFO" "Creating framework files manually..."
            create_framework_manually
        fi
    else
        log "WARN" "git not available"
        create_framework_manually
    fi

    cd "$current_dir"
}

process_template() {
    local template_file="$1"
    local output_file="$2"

    # Capitalize first letter of project type for title case
    local project_type_title="$(echo "$PROJECT_TYPE" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')"

    # Create project slug (lowercase with dashes)
    local project_slug="$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"

    # Convert y/n to 'y' or 'n' strings for template
    local use_git_hooks_val="$USE_GIT_HOOKS"
    local require_pep_val="$REQUIRE_PEP_REFERENCE"

    # Copy the template and process all cookiecutter variables
    cp "$template_file" "$output_file"

    # Replace all cookiecutter variables
    sed -i.bak "s/{{ cookiecutter.project_name }}/$PROJECT_NAME/g" "$output_file"
    sed -i.bak "s/{{ cookiecutter.project_description }}/$PROJECT_DESCRIPTION/g" "$output_file"
    sed -i.bak "s/{{ cookiecutter.author_name }}/$AUTHOR_NAME/g" "$output_file"
    sed -i.bak "s/{{ cookiecutter.author_email }}/$AUTHOR_EMAIL/g" "$output_file"
    sed -i.bak "s/{{ cookiecutter.project_type }}/$PROJECT_TYPE/g" "$output_file"
    sed -i.bak "s/{{ cookiecutter.project_type.title() }}/$project_type_title/g" "$output_file"
    sed -i.bak "s/{{ cookiecutter.project_slug }}/$project_slug/g" "$output_file"
    sed -i.bak "s/{{ cookiecutter.default_editor }}/$DEFAULT_EDITOR/g" "$output_file"
    sed -i.bak "s/{{ cookiecutter.use_git_hooks }}/$use_git_hooks_val/g" "$output_file"
    sed -i.bak "s/{{ cookiecutter.require_pep_reference }}/$require_pep_val/g" "$output_file"
    sed -i.bak "s|{{ cookiecutter.zabbix_host }}|$ZABBIX_HOST|g" "$output_file"
    sed -i.bak "s|{{ cookiecutter.grafana_url }}|$GRAFANA_URL|g" "$output_file"

    # Handle Jinja conditionals - remove {% if %} blocks where condition is false
    # For now, we'll use a simple approach: process the file based on our variables

    # Remove Jinja2 template syntax for conditionals if they exist
    # This is a simplified approach - for complex templates, would need a proper Jinja2 processor

    # Handle {% if cookiecutter.zabbix_host %} blocks
    if [ -z "$ZABBIX_HOST" ]; then
        sed -i.bak '/{% if cookiecutter.zabbix_host %}/,/{% endif %}/d' "$output_file"
    else
        sed -i.bak 's/{% if cookiecutter.zabbix_host %}//g' "$output_file"
        sed -i.bak 's/{% endif %}//g' "$output_file"
    fi

    # Handle {% if cookiecutter.grafana_url %} blocks
    if [ -z "$GRAFANA_URL" ]; then
        sed -i.bak '/{% if cookiecutter.grafana_url %}/,/{% endif %}/d' "$output_file"
    else
        sed -i.bak 's/{% if cookiecutter.grafana_url %}//g' "$output_file"
        sed -i.bak 's/{% endif %}//g' "$output_file"
    fi

    # Handle project type conditionals (keep only the matching type)
    for type in infrastructure homelab monitoring software automation; do
        if [ "$PROJECT_TYPE" != "$type" ]; then
            # Remove blocks for non-matching project types
            sed -i.bak "/{% if cookiecutter.project_type == '$type' %}/,/{% elif cookiecutter.project_type/d" "$output_file"
            sed -i.bak "/{% elif cookiecutter.project_type == '$type' %}/,/{% elif cookiecutter.project_type/d" "$output_file"
            sed -i.bak "/{% elif cookiecutter.project_type == '$type' %}/,/{% else %}/d" "$output_file"
            sed -i.bak "/{% elif cookiecutter.project_type == '$type' %}/,/{% endif %}/d" "$output_file"
        fi
    done

    # Clean up remaining Jinja2 syntax
    sed -i.bak "s/{% if cookiecutter.project_type == '$PROJECT_TYPE' %}//g" "$output_file"
    sed -i.bak "s/{% elif cookiecutter.project_type == '$PROJECT_TYPE' %}//g" "$output_file"
    sed -i.bak 's/{% else %}//g' "$output_file"
    sed -i.bak 's/{% endif %}//g' "$output_file"
    sed -i.bak "s/{% if cookiecutter.use_git_hooks == 'y' %}//g" "$output_file"
    sed -i.bak "s/{% if cookiecutter.require_pep_reference == 'y' %}//g" "$output_file"

    rm -f "$output_file.bak"
}

create_readme() {
    local readme_file="$1"
    log "INFO" "Creating $(basename "$readme_file") with project information..."

    # Capitalize first letter of project type
    local project_type_capitalized="$(echo "$PROJECT_TYPE" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')"

    cat > "$readme_file" << 'EOFMARKER'
# PROJECT_NAME_PLACEHOLDER

PROJECT_DESCRIPTION_PLACEHOLDER

**Author:** AUTHOR_NAME_PLACEHOLDER
**Type:** PROJECT_TYPE_PLACEHOLDER Project
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

## Configuration

Current project settings (edit `.peprc` to modify):

- **Author:** AUTHOR_NAME_PLACEHOLDER
- **Editor:** EDITOR_PLACEHOLDER
- **Project Type:** PROJECT_TYPE_PLACEHOLDER
GIT_HOOKS_PLACEHOLDER
STRICT_MODE_PLACEHOLDER
ZABBIX_PLACEHOLDER
GRAFANA_PLACEHOLDER

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
- **Project issues:** Contact AUTHOR_NAME_PLACEHOLDER (EMAIL_PLACEHOLDER)
- **Git integration:** Check `.git/hooks/commit-msg` for validation rules
EOFMARKER

    # Replace placeholders
    sed -i.bak "s/PROJECT_NAME_PLACEHOLDER/$PROJECT_NAME/g" "$readme_file"
    sed -i.bak "s/PROJECT_DESCRIPTION_PLACEHOLDER/$PROJECT_DESCRIPTION/g" "$readme_file"
    sed -i.bak "s/AUTHOR_NAME_PLACEHOLDER/$AUTHOR_NAME/g" "$readme_file"
    sed -i.bak "s/EMAIL_PLACEHOLDER/$AUTHOR_EMAIL/g" "$readme_file"
    sed -i.bak "s/PROJECT_TYPE_PLACEHOLDER/$project_type_capitalized/g" "$readme_file"
    sed -i.bak "s/EDITOR_PLACEHOLDER/$DEFAULT_EDITOR/g" "$readme_file"

    # Handle optional fields
    if [ "$USE_GIT_HOOKS" = "y" ]; then
        sed -i.bak "s/GIT_HOOKS_PLACEHOLDER/- **Git Hooks:** Enabled (validates PEP references)/" "$readme_file"
    else
        sed -i.bak "s/GIT_HOOKS_PLACEHOLDER//" "$readme_file"
    fi

    if [ "$REQUIRE_PEP_REFERENCE" = "y" ]; then
        sed -i.bak "s/STRICT_MODE_PLACEHOLDER/- **Strict Mode:** All commits must reference a PEP/" "$readme_file"
    else
        sed -i.bak "s/STRICT_MODE_PLACEHOLDER//" "$readme_file"
    fi

    if [ -n "$ZABBIX_HOST" ]; then
        sed -i.bak "s|ZABBIX_PLACEHOLDER|- **Zabbix:** $ZABBIX_HOST|" "$readme_file"
    else
        sed -i.bak "s/ZABBIX_PLACEHOLDER//" "$readme_file"
    fi

    if [ -n "$GRAFANA_URL" ]; then
        sed -i.bak "s|GRAFANA_PLACEHOLDER|- **Grafana:** $GRAFANA_URL|" "$readme_file"
    else
        sed -i.bak "s/GRAFANA_PLACEHOLDER//" "$readme_file"
    fi

    rm -f "$readme_file.bak"
}

create_framework_manually() {
    log "INFO" "Creating framework structure manually..."

    mkdir -p docs/{peps,blogs,templates}
    mkdir -p tools/git-hooks
    
    # Create basic .peprc
    cat > .peprc << EOF
# PEP Framework Configuration
PEP_AUTHOR="$AUTHOR_NAME"
DEFAULT_EDITOR="$DEFAULT_EDITOR"
PROJECT_NAME="$PROJECT_NAME"
PROJECT_TYPE="$PROJECT_TYPE"
ZABBIX_HOST="$ZABBIX_HOST"
GRAFANA_URL="$GRAFANA_URL"
REQUIRE_PEP_REFERENCE=$([ "$REQUIRE_PEP_REFERENCE" = "y" ] && echo "true" || echo "false")
SLACK_WEBHOOK=""
EMAIL_NOTIFICATIONS="false"
DEBUG="false"
EOF
    
    # Create basic README
    cat > README.md << EOF
# $PROJECT_NAME

$PROJECT_DESCRIPTION

## PEP Framework

This project uses the Project Enhancement Package (PEP) framework for structured development.

### Quick Start

\`\`\`bash
# Create your first PEP
./tools/pep-tools.sh new-pep "Project Foundation"

# List all PEPs
./tools/pep-tools.sh list

# Get help
./tools/pep-tools.sh help
\`\`\`

### Configuration

- **Author:** $AUTHOR_NAME
- **Type:** $PROJECT_TYPE
- **Editor:** $DEFAULT_EDITOR

See the PEP framework documentation for complete usage information.
EOF
    
    # Create .gitignore
    cat > .gitignore << 'EOF'
# PEP Framework specific
.peprc.local
*.tmp

# Common ignores
.DS_Store
*.log
*.swp
*.swo
*~

# IDE files
.vscode/
.idea/
*.sublime-*

# Backup files
*.bak
*.orig
EOF
    
    # Create directory markers
    touch docs/peps/.gitkeep
    touch docs/blogs/.gitkeep
    
    log "WARN" "Framework created with basic structure"
    log "INFO" "You'll need to manually add:"
    log "INFO" "  - tools/pep-tools.sh (management script)"
    log "INFO" "  - tools/git-hooks/commit-msg (git integration)"
    log "INFO" "  - docs/templates/pep-template.md"
    log "INFO" "  - docs/templates/blog-template.md"
    log "INFO" "Visit the framework repository for complete files"
}

install_framework() {
    local original_dir="$(pwd)"

    log "STEP" "Installing framework files..."

    # Check for existing files (but not README.md since we preserve it)
    local conflicts=()
    shopt -s dotglob
    for file in .peprc .gitignore docs/templates tools/pep-tools.sh; do
        if [ -e "$file" ]; then
            conflicts+=("$file")
        fi
    done
    shopt -u dotglob

    if [ ${#conflicts[@]} -gt 0 ]; then
        log "WARN" "The following files already exist and will be updated:"
        for conflict in "${conflicts[@]}"; do
            echo "  - $conflict"
        done

        # Check if this is an initial install or a re-run
        if [ -f "tools/pep-tools.sh" ]; then
            log "INFO" "Detected existing PEP framework installation"
            echo -n "Update existing framework files? [y/N]: "
        else
            echo -n "Overwrite existing files? [y/N]: "
        fi

        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log "INFO" "Installation cancelled"
            exit 0
        fi
    fi

    # Copy framework files
    log "INFO" "Copying files from $TEMP_DIR to $original_dir"

    # List what we're about to copy (excluding template directory and README.md for existing projects)
    if [ "$(ls -A "$TEMP_DIR")" ]; then
        log "INFO" "Files to copy:"
        for item in "$TEMP_DIR"/*; do
            basename_item=$(basename "$item")
            # Skip the template directory and README.md for existing projects
            if [ "$basename_item" != "template" ] && [ "$basename_item" != "README.md" ]; then
                echo "  - $basename_item"
            fi
        done

        # Copy files, excluding the template directory and README.md
        for item in "$TEMP_DIR"/*; do
            basename_item=$(basename "$item")
            # Skip template directory and README.md (we'll handle README separately)
            if [ "$basename_item" != "template" ] && [ "$basename_item" != "README.md" ]; then
                if ! cp -rv "$item" "$original_dir/" 2>&1 | sed 's/^/  /'; then
                    log "ERROR" "Failed to copy $basename_item"
                    exit 1
                fi
            fi
        done

        # Handle README: Create PEP_FRAMEWORK.md instead of overwriting README.md
        if [ ! -f "$original_dir/README.md" ]; then
            log "INFO" "No existing README.md found, creating one"
            create_readme "$original_dir/README.md"
        else
            log "INFO" "Existing README.md preserved, creating PEP_FRAMEWORK.md"
            create_readme "$original_dir/PEP_FRAMEWORK.md"

            # Also create the full template README for reference
            if [ -f "$TEMP_DIR/README.md" ]; then
                log "INFO" "Creating README_PEP_TEMPLATE.md with full cookiecutter template for reference"
                process_template "$TEMP_DIR/README.md" "$original_dir/README_PEP_TEMPLATE.md"
            fi
        fi

        log "INFO" "Framework files copied successfully"
    else
        log "ERROR" "No files found in temporary directory to copy"
        exit 1
    fi

    # Customize .peprc with user's settings
    if [ -f ".peprc" ]; then
        sed -i.bak "s/PEP_AUTHOR=.*/PEP_AUTHOR=\"$AUTHOR_NAME\"/" .peprc
        sed -i.bak "s/DEFAULT_EDITOR=.*/DEFAULT_EDITOR=\"$DEFAULT_EDITOR\"/" .peprc
        sed -i.bak "s/PROJECT_NAME=.*/PROJECT_NAME=\"$PROJECT_NAME\"/" .peprc
        sed -i.bak "s/ZABBIX_HOST=.*/ZABBIX_HOST=\"$ZABBIX_HOST\"/" .peprc
        sed -i.bak "s|GRAFANA_URL=.*|GRAFANA_URL=\"$GRAFANA_URL\"|" .peprc
        sed -i.bak "s/REQUIRE_PEP_REFERENCE=.*/REQUIRE_PEP_REFERENCE=$([ "$REQUIRE_PEP_REFERENCE" = "y" ] && echo "true" || echo "false")/" .peprc
        rm -f .peprc.bak
        log "INFO" "Customized .peprc with your settings"
    else
        log "WARN" ".peprc not found, creating one..."
        cat > .peprc << EOF
# PEP Framework Configuration
PEP_AUTHOR="$AUTHOR_NAME"
DEFAULT_EDITOR="$DEFAULT_EDITOR"
PROJECT_NAME="$PROJECT_NAME"
ZABBIX_HOST="$ZABBIX_HOST"
GRAFANA_URL="$GRAFANA_URL"
REQUIRE_PEP_REFERENCE=$([ "$REQUIRE_PEP_REFERENCE" = "y" ] && echo "true" || echo "false")
SLACK_WEBHOOK=""
EMAIL_NOTIFICATIONS="false"
DEBUG="false"
EOF
    fi

    # Make scripts executable
    if [ -f "tools/pep-tools.sh" ]; then
        chmod +x tools/pep-tools.sh
        log "INFO" "Made pep-tools.sh executable"
    else
        log "WARN" "tools/pep-tools.sh not found after copy"
    fi

    if [ -f "tools/git-hooks/commit-msg" ]; then
        chmod +x tools/git-hooks/commit-msg
        log "INFO" "Made git hook executable"
    else
        log "WARN" "tools/git-hooks/commit-msg not found after copy"
    fi

    # Initialize framework
    if [ -f "tools/pep-tools.sh" ] && [ "$USE_GIT_HOOKS" = "y" ]; then
        ./tools/pep-tools.sh init
        log "INFO" "Framework initialized"
    fi
}

main() {
    local quiet_mode=false
    
    case "${1:-}" in
        "-h"|"--help")
            show_help
            exit 0
            ;;
        "-q"|"--quiet")
            quiet_mode=true
            ;;
        "-i"|"--interactive"|"")
            quiet_mode=false
            ;;
        *)
            log "ERROR" "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
    
    check_prerequisites
    get_user_input "$quiet_mode"
    download_framework
    install_framework
    
    log "INFO" "PEP framework installed successfully!"
    log "INFO" ""
    log "INFO" "Next steps:"
    log "INFO" "  ./tools/pep-tools.sh new-pep 'Project Foundation'"
    log "INFO" "  ./tools/pep-tools.sh help"
    
    if [ -d ".git" ]; then
        log "INFO" "  git add . && git commit -m 'Add PEP framework'"
    fi
}

main "$@"