#!/usr/bin/env python3
"""
Post-generation hook for PEP Framework cookiecutter template.
Runs after the project is generated to set up permissions, git, and framework.
"""

import os
import subprocess
import sys

def run_command(cmd, description, fail_ok=False):
    """Run a shell command and handle errors."""
    try:
        result = subprocess.run(cmd, shell=True, check=True, capture_output=True, text=True)
        print(f"✓ {description}")
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        if fail_ok:
            print(f"⚠ {description} (skipped): {e.stderr.strip()}")
            return None
        else:
            print(f"✗ {description} failed: {e.stderr.strip()}")
            return None

def setup_permissions():
    """Make scripts executable."""
    print("Setting up file permissions...")
    
    scripts = [
        ("tools/pep-tools.sh", "PEP management script"),
        ("tools/git-hooks/commit-msg", "Git commit hook")
    ]
    
    for script, description in scripts:
        if os.path.exists(script):
            run_command(f"chmod +x {script}", f"Made {description} executable")
        else:
            print(f"⚠ {script} not found, skipping")
    
    # Also fix any other shell scripts
    run_command("find . -name '*.sh' -type f -exec chmod +x {} +", "Made all .sh files executable", fail_ok=True)

def setup_git():
    """Initialize git repository if needed."""
    print("Setting up git integration...")
    
    # Check if already in a git repo
    if os.path.exists('.git'):
        print("✓ Git repository already exists")
    else:
        # Initialize new git repo
        if run_command("git init", "Initialized git repository"):
            # Set up initial commit
            run_command("git add .", "Added files to git")
            run_command('git commit -m "Initial commit: PEP framework setup"', "Created initial commit")

def setup_framework():
    """Initialize PEP framework."""
    print("Initializing PEP framework...")
    
    if os.path.exists('tools/pep-tools.sh'):
        # Run framework initialization
        run_command("./tools/pep-tools.sh init", "Initialized PEP framework")
        
        # Create .gitkeep files if directories are empty
        for directory in ['docs/peps', 'docs/blogs']:
            if os.path.exists(directory) and not os.listdir(directory):
                gitkeep_path = os.path.join(directory, '.gitkeep')
                with open(gitkeep_path, 'w') as f:
                    f.write('')
                print(f"✓ Created {gitkeep_path}")
    else:
        print("⚠ pep-tools.sh not found, skipping framework initialization")

def show_next_steps():
    """Display next steps for the user."""
    project_name = "{{ cookiecutter.project_name }}"
    project_slug = "{{ cookiecutter.project_slug }}"
    use_git_hooks = "{{ cookiecutter.use_git_hooks }}"
    
    print("\n" + "="*60)
    print(f"🎉 {project_name} is ready!")
    print("="*60)
    
    print("\n📋 Next steps:")
    print(f"   cd {project_slug}")
    print("   ./tools/pep-tools.sh new-pep 'Project Foundation'")
    
    print("\n🔧 Available commands:")
    print("   ./tools/pep-tools.sh help          # Show all commands")
    print("   ./tools/pep-tools.sh list          # List all PEPs")
    print("   ./tools/pep-tools.sh status        # Show status summary")
    
    print("\n📖 Documentation:")
    print("   README.md                          # Project-specific guide")
    print("   docs/templates/                    # PEP and BLOG templates")
    
    if use_git_hooks.lower() == 'y':
        print("\n🔗 Git integration enabled:")
        print("   Branch naming: feature/pep-XXX-description")
        print("   Commit format: pep-XXX: description")
        print("   Validation: Automatic PEP reference checking")
    
    print("\n⚙️  Configuration:")
    print("   .peprc                             # Edit project settings")
    
    print("\n🚀 Workflow example:")
    print("   1. ./tools/pep-tools.sh new-pep 'New Feature'")
    print("   2. git checkout -b feature/pep-002-new-feature")
    print("   3. # Make changes...")
    print("   4. git commit -m 'pep-002: Implement new feature'")
    print("   5. ./tools/pep-tools.sh new-blog 1 2")

def main():
    """Main setup function."""
    print("🔧 Setting up PEP Framework project...")
    print()
    
    try:
        setup_permissions()
        print()
        
        setup_git()
        print()
        
        setup_framework()
        print()
        
        show_next_steps()
        
    except Exception as e:
        print(f"\n❌ Setup failed: {e}")
        print("You may need to complete setup manually.")
        sys.exit(1)

if __name__ == "__main__":
    main()