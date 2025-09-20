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
    
    cd "$TEMP_DIR"
    
    if command -v git >/dev/null 2>&1; then
        git clone --depth 1 "$TEMPLATE_REPO" template 2>/dev/null || {
            log "WARN" "Could not clone template repository"
            log "INFO" "Creating framework files manually..."
            create_framework_manually
            return
        }
        
        if [ -d "template/{{cookiecutter.project_slug}}" ]; then
            cp -r "template/{{cookiecutter.project_slug}}"/* .
        else
            log "ERROR" "Template directory not found in repository"
            create_framework_manually
        fi
    else
        create_framework_manually
    fi
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
    
    # Check for existing files
    local conflicts=()
    for file in .peprc docs/templates tools/pep-tools.sh; do
        if [ -e "$file" ]; then
            conflicts+=("$file")
        fi
    done
    
    if [ ${#conflicts[@]} -gt 0 ]; then
        log "WARN" "The following files already exist:"
        for conflict in "${conflicts[@]}"; do
            echo "  - $conflict"
        done
        echo -n "Overwrite existing files? [y/N]: "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log "INFO" "Installation cancelled"
            exit 0
        fi
    fi
    
    # Copy framework files
    cp -r "$TEMP_DIR"/* "$original_dir/" 2>/dev/null || true
    
    # Make scripts executable
    if [ -f "tools/pep-tools.sh" ]; then
        chmod +x tools/pep-tools.sh
        log "INFO" "Made pep-tools.sh executable"
    fi
    
    if [ -f "tools/git-hooks/commit-msg" ]; then
        chmod +x tools/git-hooks/commit-msg
        log "INFO" "Made git hook executable"
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