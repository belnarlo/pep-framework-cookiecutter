#Requires -Version 5.1
<#
PEP Management Tools (PowerShell edition)
Version: 2.0
Command-line tools for managing Project Enhancement Packages on Windows.
Mirrors tools/pep-tools.sh — same commands, same file/ID formats, same .peprc config.
#>

param(
    [Parameter(Position = 0)]
    [string]$Command = "help",

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$Rest = @()
)

$ErrorActionPreference = "Stop"

# ----------------------------------------------------------------------------
# Configuration (defaults, then overridden by .peprc / .peprc.local if present)
# ----------------------------------------------------------------------------
$script:PEP_DIR = "docs/peps"
$script:BLOG_DIR = "docs/blogs"
$script:TEMPLATE_DIR = "docs/templates"
$script:CONFIG_FILE = ".peprc"

function Import-PepConfig {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return }
    foreach ($rawLine in Get-Content -Path $Path) {
        $line = $rawLine.Trim()
        if ($line -eq "" -or $line.StartsWith("#")) { continue }
        if ($line -match '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$') {
            $key = $matches[1]
            $value = $matches[2].Trim()
            if ($value -match '^"(.*)"$') { $value = $matches[1] }
            elseif ($value -match "^'(.*)'$") { $value = $matches[1] }
            Set-Variable -Name $key -Value $value -Scope Script
        }
    }
}

Import-PepConfig -Path $script:CONFIG_FILE
Import-PepConfig -Path "$($script:CONFIG_FILE).local"

function Get-EnableBlogs {
    if ($script:ENABLE_BLOGS) { return $script:ENABLE_BLOGS }
    return "y"
}

# ----------------------------------------------------------------------------
# Logging
# ----------------------------------------------------------------------------
function Write-PepLog {
    param([string]$Level, [string]$Message)
    switch ($Level) {
        "INFO"  { Write-Host "[INFO] $Message" -ForegroundColor Green }
        "WARN"  { Write-Host "[WARN] $Message" -ForegroundColor Yellow }
        "ERROR" { Write-Host "[ERROR] $Message" -ForegroundColor Red }
        "DEBUG" { if ($script:DEBUG -eq "true") { Write-Host "[DEBUG] $Message" -ForegroundColor Cyan } }
    }
}

# ----------------------------------------------------------------------------
# ID / filename helpers
# ----------------------------------------------------------------------------

# Returns the lowercase file prefix used in filenames (e.g. "pep-pe-mon-" or "pep-")
function Get-FilePrefix {
    $project = $script:PROJECT_CODE
    $repo = $script:REPO_CODE
    if ($project -and $repo) {
        return "pep-" + ("$project-$repo").ToLower() + "-"
    } elseif ($repo) {
        return "pep-" + $repo.ToLower() + "-"
    } elseif ($project) {
        return "pep-" + $project.ToLower() + "-"
    } else {
        return "pep-"
    }
}

# Returns the display ID used in file content, list, and commit messages
# e.g. "PEP-PE-MON-001"  /  "PEP-001"
function Get-PepId {
    param([int]$Num)
    $project = $script:PROJECT_CODE
    $repo = $script:REPO_CODE
    if ($project -and $repo) {
        return "PEP-{0}-{1}-{2:D3}" -f $project, $repo, $Num
    } elseif ($repo) {
        return "PEP-{0}-{1:D3}" -f $repo, $Num
    } elseif ($project) {
        return "PEP-{0}-{1:D3}" -f $project, $Num
    } else {
        return "PEP-{0:D3}" -f $Num
    }
}

# Maps a PEP type name to a short slug used in filenames
function Get-TypeSlug {
    param([string]$Type)
    switch ($Type) {
        "Project"        { return "proj" }
        "Feature"        { return "feat" }
        "Process"        { return "proc" }
        "Infrastructure" { return "infra" }
        "Documentation"  { return "docs" }
        "Bug"            { return "bug" }
        "Enhancement"    { return "enh" }
        "Research"       { return "research" }
        "Security"       { return "sec" }
        "Performance"    { return "perf" }
        default {
            $lower = $Type.ToLower()
            return $lower.Substring(0, [Math]::Min(8, $lower.Length))
        }
    }
}

# ----------------------------------------------------------------------------
# Metadata extraction helpers
# ----------------------------------------------------------------------------

# Extract a metadata field from a PEP file, e.g. Get-PepField $file "Status"
# Trailing whitespace is trimmed — template lines end in two spaces (a markdown
# line break) which would otherwise break exact-match status/date comparisons.
function Get-PepField {
    param([string]$FilePath, [string]$Field)
    $pattern = "^\*\*$([regex]::Escape($Field)):\*\*"
    $line = Get-Content -Path $FilePath -ErrorAction SilentlyContinue | Where-Object { $_ -match $pattern } | Select-Object -First 1
    if (-not $line) { return "" }
    return ($line -replace $pattern, '').Trim()
}

# Extract the abstract paragraph — the first non-blank line after "## Abstract"
function Get-PepAbstract {
    param([string]$FilePath)
    $inAbstract = $false
    foreach ($line in (Get-Content -Path $FilePath -ErrorAction SilentlyContinue)) {
        if ($line -match '^## Abstract\s*$') { $inAbstract = $true; continue }
        if ($inAbstract -and $line -match '^## ') { break }
        if ($inAbstract -and $line.Trim() -ne '') { return $line.Trim() }
    }
    return ""
}

# Extract the 3-digit PEP number from a PEP filename
function Get-PepNumFromFile {
    param([string]$FilePath)
    $name = Split-Path $FilePath -Leaf
    if ($name -match '(\d{3})') { return $matches[1] }
    return $null
}

function Get-GitConfigValue {
    param([string]$Key)
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { return $null }
    $val = git config $Key 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $val) { return $null }
    return $val
}

function Get-PepAuthor {
    if ($script:PEP_AUTHOR) { return $script:PEP_AUTHOR }
    $name = Get-GitConfigValue "user.name"
    if ($name) { return $name }
    return "Unknown Author"
}

# ----------------------------------------------------------------------------
# Directory setup
# ----------------------------------------------------------------------------
function Confirm-Directories {
    $dirs = @($script:PEP_DIR, $script:TEMPLATE_DIR, "tools/git-hooks")
    if ((Get-EnableBlogs) -eq "y") { $dirs += $script:BLOG_DIR }
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-PepLog INFO "Created directory: $dir"
        }
    }
}

function Get-NextPepNumber {
    $maxNum = 0
    if (Test-Path $script:PEP_DIR) {
        Get-ChildItem -Path $script:PEP_DIR -Filter "pep-*.md" -File -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.Name -match '(\d{3})') {
                $n = [int]$matches[1]
                if ($n -gt $maxNum) { $maxNum = $n }
            }
        }
    }
    return $maxNum + 1
}

function Get-NextBlogNumber {
    $maxNum = 0
    if (Test-Path $script:BLOG_DIR) {
        Get-ChildItem -Path $script:BLOG_DIR -Filter "blog-*.md" -File -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.Name -match '(\d{3})') {
                $n = [int]$matches[1]
                if ($n -gt $maxNum) { $maxNum = $n }
            }
        }
    }
    return $maxNum + 1
}

# ----------------------------------------------------------------------------
# Create a new PEP
# ----------------------------------------------------------------------------
function New-Pep {
    param([string[]]$Arguments)

    $openCode = $false
    $args2 = @()
    foreach ($a in $Arguments) {
        if ($a -eq "--code") { $openCode = $true } else { $args2 += $a }
    }

    $pepNum = $null
    $title = $null

    if ($args2.Count -eq 0) {
        $pepNum = Get-NextPepNumber
        Write-PepLog INFO "Auto-assigned PEP number: $pepNum"
        $title = Read-Host "Enter PEP title"
    } elseif ($args2.Count -eq 1) {
        if ($args2[0] -match '^\d+$') {
            $pepNum = [int]$args2[0]
            $title = Read-Host "Enter PEP title"
        } else {
            $title = $args2[0]
            $pepNum = Get-NextPepNumber
            Write-PepLog INFO "Auto-assigned PEP number: $pepNum"
        }
    } elseif ($args2.Count -eq 2) {
        if ($args2[0] -match '^\d+$') {
            $pepNum = [int]$args2[0]
            $title = $args2[1]
        } else {
            Write-PepLog ERROR "When providing two arguments, first must be a number"
            Write-PepLog INFO "Usage: pep-tools.ps1 new-pep [--code] [number] [title]"
            exit 1
        }
    } else {
        Write-PepLog ERROR "Too many arguments"
        exit 1
    }

    if (-not $title) {
        Write-PepLog ERROR "Title is required"
        exit 1
    }

    $pepTypes = @("Project", "Feature", "Process", "Infrastructure", "Documentation", "Bug", "Enhancement", "Research", "Security", "Performance")
    Write-Host ""
    Write-Host "Select PEP type:"
    for ($i = 0; $i -lt $pepTypes.Count; $i++) {
        Write-Host ("  {0,2}) {1}" -f ($i + 1), $pepTypes[$i])
    }
    $typeChoice = Read-Host "Type [1-$($pepTypes.Count), default 2 (Feature)]"
    $pepType = "Feature"
    if ($typeChoice -match '^\d+$' -and [int]$typeChoice -ge 1 -and [int]$typeChoice -le $pepTypes.Count) {
        $pepType = $pepTypes[[int]$typeChoice - 1]
    } else {
        Write-PepLog INFO "Defaulting to type: $pepType"
    }

    $priorityChoice = (Read-Host "Priority [H)igh / M)edium / L)ow, default M]").ToLower()
    $pepPriority = "Medium"
    if ($priorityChoice -eq "h" -or $priorityChoice -eq "high") { $pepPriority = "High" }
    elseif ($priorityChoice -eq "l" -or $priorityChoice -eq "low") { $pepPriority = "Low" }

    $pepAbstract = Read-Host "Brief abstract (2-3 sentences)"

    $typeSlug = Get-TypeSlug $pepType
    $titleSlug = ($title.ToLower() -replace '[^a-z0-9]+', '-').Trim('-')
    $filePrefix = Get-FilePrefix
    $paddedNum = "{0:D3}" -f $pepNum
    $filename = Join-Path $script:PEP_DIR "$filePrefix$paddedNum-$typeSlug-$titleSlug.md"

    if (Test-Path $filename) {
        Write-PepLog ERROR "PEP $pepNum already exists: $filename"
        exit 1
    }

    Confirm-Directories

    $templatePath = Join-Path $script:TEMPLATE_DIR "pep-template.md"
    if (-not (Test-Path $templatePath)) {
        Write-PepLog ERROR "PEP template not found: $templatePath"
        Write-PepLog INFO "Run '.\tools\pep-tools.ps1 update-templates' to pull templates from source"
        exit 1
    }

    Copy-Item $templatePath $filename

    $author = Get-PepAuthor
    $today = Get-Date -Format "yyyy-MM-dd"
    $pepId = Get-PepId $pepNum

    $content = Get-Content -Path $filename -Raw
    $content = $content.Replace("PEPID", $pepId)
    $content = $content.Replace("[Title]", $title)
    $content = $content.Replace("YYYY-MM-DD", $today)
    $content = $content.Replace("[Your Name]", $author)
    $content = $content.Replace("[Type]", $pepType)
    $content = $content.Replace("[Priority]", $pepPriority)
    if ($pepAbstract) {
        $content = $content.Replace("Brief summary of the enhancement (2-3 sentences).", $pepAbstract)
    }
    Set-Content -Path $filename -Value $content -NoNewline

    Write-PepLog INFO "Created $pepId`: $filename"

    if ($openCode) {
        if (Get-Command code -ErrorAction SilentlyContinue) {
            Write-PepLog INFO "Opening in VS Code..."
            code $filename
        } else {
            Write-PepLog WARN "VS Code not found"
            Write-PepLog INFO "Edit with: code $filename"
        }
    } elseif ($script:AUTO_OPEN_EDITOR -eq "true" -and $script:DEFAULT_EDITOR -and (Get-Command $script:DEFAULT_EDITOR -ErrorAction SilentlyContinue)) {
        Write-PepLog INFO "Opening in $($script:DEFAULT_EDITOR)..."
        & $script:DEFAULT_EDITOR $filename
    } else {
        $editor = if ($script:DEFAULT_EDITOR) { $script:DEFAULT_EDITOR } else { "notepad" }
        Write-PepLog INFO "Edit with: $editor $filename"
        Write-PepLog INFO "Create branch when ready: .\tools\pep-tools.ps1 new-branch $pepNum"
    }
}

# ----------------------------------------------------------------------------
# Create a git feature branch for a PEP
# ----------------------------------------------------------------------------
function New-PepBranch {
    param([string[]]$Arguments)

    $pepRef = $Arguments[0]
    if (-not $pepRef) { $pepRef = Read-Host "Enter PEP number or ID (e.g. 3 or PEP-PE-MON-003)" }

    if ($pepRef -notmatch '(\d+)$') {
        Write-PepLog ERROR "Could not parse PEP number from: $pepRef"
        exit 1
    }
    $pepNum = [int]$matches[1]

    $filePrefix = Get-FilePrefix
    $padded = "{0:D3}" -f $pepNum
    $pepFiles = Get-ChildItem -Path $script:PEP_DIR -Filter "$filePrefix$padded-*.md" -File -ErrorAction SilentlyContinue

    if (-not $pepFiles) {
        Write-PepLog ERROR "PEP $padded not found (looked for $filePrefix$padded-*.md)"
        exit 1
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue) -or -not (Test-Path ".git")) {
        Write-PepLog ERROR "Not in a git repository"
        exit 1
    }

    $branchName = "feature/" + [System.IO.Path]::GetFileNameWithoutExtension($pepFiles[0].Name)

    git rev-parse --verify $branchName *>$null
    if ($LASTEXITCODE -eq 0) {
        Write-PepLog WARN "Branch already exists: $branchName"
        $response = Read-Host "Switch to it? [Y/n]"
        if ($response -notmatch '^[Nn]') {
            git checkout $branchName
            Write-PepLog INFO "Switched to: $branchName"
        }
    } else {
        git checkout -b $branchName
        Write-PepLog INFO "Created and switched to: $branchName"
    }
}

# ----------------------------------------------------------------------------
# Commit staged changes (or the PEP file itself) with the correct message format
# ----------------------------------------------------------------------------
function Invoke-PepCommit {
    param([string[]]$Arguments)

    $pepRef = $Arguments[0]
    $message = ""
    if ($Arguments.Count -ge 2) {
        $message = ($Arguments[1..($Arguments.Count - 1)] -join ' ')
    }

    if (-not $pepRef) { $pepRef = Read-Host "Enter PEP number or ID (e.g. 3 or PEP-PE-MON-003)" }
    if ($pepRef -notmatch '(\d+)$') {
        Write-PepLog ERROR "Could not parse PEP number from: $pepRef"
        exit 1
    }
    $pepNum = [int]$matches[1]

    if (-not (Get-Command git -ErrorAction SilentlyContinue) -or -not (Test-Path ".git")) {
        Write-PepLog ERROR "Not in a git repository"
        exit 1
    }

    $filePrefix = Get-FilePrefix
    $padded = "{0:D3}" -f $pepNum
    $pepFiles = Get-ChildItem -Path $script:PEP_DIR -Filter "$filePrefix$padded-*.md" -File -ErrorAction SilentlyContinue
    if (-not $pepFiles) {
        Write-PepLog ERROR "PEP $padded not found"
        exit 1
    }

    if (-not $message) {
        $message = Read-Host "Commit message (prefix '$filePrefix$padded`: ' will be added)"
    }
    if (-not $message) {
        Write-PepLog ERROR "Message is required"
        exit 1
    }

    git diff --cached --quiet *>$null
    if ($LASTEXITCODE -eq 0) {
        Write-PepLog INFO "Nothing staged — staging $($pepFiles[0].FullName)"
        git add $pepFiles[0].FullName
    }

    $fullMessage = "$filePrefix$padded" + ": $message"
    git commit -m $fullMessage
    Write-PepLog INFO "Committed: $fullMessage"
}

# ----------------------------------------------------------------------------
# Migrate existing PEPs to the current naming scheme
# ----------------------------------------------------------------------------
function Invoke-PepMigrate {
    param([string[]]$Arguments)

    $dryRun = $Arguments -contains "--dry-run"

    if (-not (Test-Path $script:PEP_DIR)) {
        Write-PepLog WARN "PEP directory not found: $($script:PEP_DIR)"
        return
    }

    $filePrefix = Get-FilePrefix
    $typeSlugs = @("proj", "feat", "proc", "infra", "docs", "bug", "enh", "research", "sec", "perf")
    $typeMap = @{
        proj = "Project"; feat = "Feature"; proc = "Process"; infra = "Infrastructure"
        docs = "Documentation"; bug = "Bug"; enh = "Enhancement"; research = "Research"
        sec = "Security"; perf = "Performance"
    }

    $migrated = 0
    $skipped = 0

    $oldFormatFiles = Get-ChildItem -Path $script:PEP_DIR -Filter "pep-*.md" -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^pep-\d{3}-' }

    foreach ($pep in $oldFormatFiles) {
        $basenamePep = $pep.Name
        if ($basenamePep -notmatch '^pep-(\d{3})-') { continue }
        $num = $matches[1]
        $afterNum = $basenamePep -replace "^pep-$num-", ''

        $hasTypeSlug = $false
        $existingTypeSlug = ""
        foreach ($ts in $typeSlugs) {
            if ($afterNum.StartsWith("$ts-")) { $hasTypeSlug = $true; $existingTypeSlug = $ts; break }
        }

        if ($filePrefix -eq "pep-" -and $hasTypeSlug) {
            Write-PepLog INFO "Already up-to-date, skipping: $basenamePep"
            $skipped++
            continue
        }

        $content = Get-Content -Path $pep.FullName -Raw
        $lines = $content -split "`r?`n"
        $titleLine = $lines | Where-Object { $_ -match '^\*\*Title:\*\*' } | Select-Object -First 1
        $title = if ($titleLine) { ($titleLine -replace '^\*\*Title:\*\*\s*', '').Trim() } else { "" }
        $typeLine = $lines | Where-Object { $_ -match '^\*\*Type:\*\*' } | Select-Object -First 1
        $pepType = if ($typeLine) { ($typeLine -replace '^\*\*Type:\*\*\s*', '').Trim() } else { "" }

        Write-PepLog INFO "Migrating: $basenamePep"
        if ($title) { Write-Host "  Title: $title" }

        if ($hasTypeSlug -and ($pepType -match '\|' -or -not $pepType)) {
            $pepType = $typeMap[$existingTypeSlug]
        } elseif ($pepType -match '\|' -or -not $pepType) {
            $pepTypesArr = @("Project", "Feature", "Process", "Infrastructure", "Documentation", "Bug", "Enhancement", "Research", "Security", "Performance")
            $shown = if ($pepType) { $pepType } else { "none" }
            Write-Host "  Type unclear (content shows: $shown)"
            for ($i = 0; $i -lt $pepTypesArr.Count; $i++) {
                Write-Host ("    {0,2}) {1}" -f ($i + 1), $pepTypesArr[$i])
            }
            $typeChoice = Read-Host "  Select type [1-$($pepTypesArr.Count), default 2 (Feature)]"
            if ($typeChoice -match '^\d+$' -and [int]$typeChoice -ge 1 -and [int]$typeChoice -le $pepTypesArr.Count) {
                $pepType = $pepTypesArr[[int]$typeChoice - 1]
            } else {
                $pepType = "Feature"
            }
        }

        $finalTypeSlug = Get-TypeSlug $pepType

        $titleSlug = $afterNum -replace '\.md$', ''
        if ($hasTypeSlug) { $titleSlug = $titleSlug -replace "^$existingTypeSlug-", '' }

        $newFilename = Join-Path $script:PEP_DIR "$filePrefix$num-$finalTypeSlug-$titleSlug.md"
        $newPepId = Get-PepId ([int]$num)

        Write-Host "  -> $(Split-Path $newFilename -Leaf)  (ID: $newPepId)"

        if ($dryRun) { continue }

        # Do the global inline "PEP-NNN" -> newPepId replace FIRST. With codes
        # placed between "PEP" and the number (PEP-CODES-NNN), newPepId no
        # longer contains the old "PEP-NNN" text as a substring, but keeping
        # this global replace first is still the safe order in case
        # PROJECT_CODE/REPO_CODE are both unset (newPepId == "PEP-NNN", i.e.
        # an idempotent no-op replace).
        $oldRef = "PEP-{0:D3}" -f [int]$num
        $newContent = $content.Replace($oldRef, $newPepId)

        # Heading — no-op if the global replace above already rewrote it
        $newContent = [regex]::Replace($newContent, "(?m)^# PEP-${num}: ", "# $newPepId`: ")
        # **PEP:** NNN -> **ID:** ...
        $newContent = [regex]::Replace($newContent, "(?m)^\*\*PEP:\*\* $num\s*$", "**ID:** $newPepId")
        # Normalise any existing **ID:** line
        $newContent = [regex]::Replace($newContent, "(?m)^\*\*ID:\*\*.*$", "**ID:** $newPepId")
        # Fix Type if still pipe-separated
        if ($newContent -match '(?m)^\*\*Type:\*\*.*\|') {
            $newContent = [regex]::Replace($newContent, "(?m)^\*\*Type:\*\*.*$", "**Type:** $pepType")
        }
        # Add Priority after Type if missing
        if ($newContent -notmatch '(?m)^\*\*Priority:\*\*') {
            $newContent = [regex]::Replace($newContent, "(?m)^(\*\*Type:\*\*.*)$", "`$1`n**Priority:** Medium")
        }

        Set-Content -Path $newFilename -Value $newContent -NoNewline
        Remove-Item $pep.FullName

        $migrated++
        Write-PepLog INFO "  Done"
    }

    if (($migrated + $skipped) -eq 0) {
        Write-PepLog INFO "No PEP files found to migrate"
        return
    }

    if ($dryRun) {
        Write-PepLog INFO "Dry run: $migrated would be migrated, $skipped already up-to-date"
    } else {
        Write-PepLog INFO "Done: $migrated migrated, $skipped already up-to-date"
        if ($migrated -gt 0 -and (Test-Path ".git")) {
            Write-PepLog INFO "Commit the changes: git add -A; git commit -m 'chore: migrate PEPs to new naming scheme'"
        }
    }
}

# ----------------------------------------------------------------------------
# Create a new BLOG
# ----------------------------------------------------------------------------
function New-PepBlog {
    param([string]$BlogNum, [string]$PepNum)

    if ((Get-EnableBlogs) -ne "y") {
        Write-PepLog ERROR "Blogs feature is disabled. Set ENABLE_BLOGS=y in .peprc to enable."
        exit 1
    }

    if (-not $PepNum) { $PepNum = Read-Host "Enter PEP number for this blog" }
    if (-not $BlogNum) {
        $BlogNum = Get-NextBlogNumber
        Write-PepLog INFO "Auto-assigned BLOG number: $BlogNum"
    }
    if (-not $PepNum) {
        Write-PepLog ERROR "PEP number is required"
        exit 1
    }

    $filePrefix = Get-FilePrefix
    $pepPadded = "{0:D3}" -f [int]$PepNum
    $pepFiles = Get-ChildItem -Path $script:PEP_DIR -Filter "$filePrefix$pepPadded-*.md" -File -ErrorAction SilentlyContinue
    if (-not $pepFiles) {
        Write-PepLog ERROR "PEP $pepPadded does not exist"
        exit 1
    }

    $blogPadded = "{0:D3}" -f [int]$BlogNum
    $filename = Join-Path $script:BLOG_DIR "blog-$blogPadded-pep-$pepPadded-implementation.md"

    Confirm-Directories

    $templatePath = Join-Path $script:TEMPLATE_DIR "blog-template.md"
    if (-not (Test-Path $templatePath)) {
        Write-PepLog ERROR "BLOG template not found: $templatePath"
        exit 1
    }
    Copy-Item $templatePath $filename

    $author = Get-PepAuthor
    $today = Get-Date -Format "yyyy-MM-dd"
    $pepId = Get-PepId ([int]$PepNum)

    $content = Get-Content -Path $filename -Raw
    $content = $content.Replace("XXX", $blogPadded)
    $content = $content.Replace("PEPID", $pepId)
    $content = $content.Replace("YYYY-MM-DD", $today)
    $content = $content.Replace("[Your Name]", $author)
    Set-Content -Path $filename -Value $content -NoNewline

    Write-PepLog INFO "Created BLOG-$blogPadded`: $filename"

    if ($script:AUTO_OPEN_EDITOR -eq "true" -and $script:DEFAULT_EDITOR -and (Get-Command $script:DEFAULT_EDITOR -ErrorAction SilentlyContinue)) {
        & $script:DEFAULT_EDITOR $filename
    } else {
        $editor = if ($script:DEFAULT_EDITOR) { $script:DEFAULT_EDITOR } else { "notepad" }
        Write-PepLog INFO "Edit with: $editor $filename"
    }
}

# ----------------------------------------------------------------------------
# List all PEPs
# ----------------------------------------------------------------------------
function Show-PepList {
    if (-not (Test-Path $script:PEP_DIR)) {
        Write-PepLog WARN "PEP directory does not exist: $($script:PEP_DIR)"
        return
    }

    Write-Host "Project Enhancement Packages:" -ForegroundColor Blue
    Write-Host "=============================="

    $files = Get-ChildItem -Path $script:PEP_DIR -Filter "pep-*.md" -File -ErrorAction SilentlyContinue | Sort-Object Name
    if (-not $files) {
        Write-Host "No PEPs found."
        return
    }

    foreach ($pep in $files) {
        $num = Get-PepNumFromFile $pep.FullName
        if (-not $num) { continue }
        $pepId = Get-PepId ([int]$num)
        $title = Get-PepField $pep.FullName "Title"
        $status = Get-PepField $pep.FullName "Status"
        $type = Get-PepField $pep.FullName "Type"
        $author = Get-PepField $pep.FullName "Author"

        $color = "White"
        switch ($status) {
            "Draft"       { $color = "Yellow" }
            "Active"      { $color = "Blue" }
            "Implemented" { $color = "Green" }
            "Rejected"    { $color = "Red" }
        }

        Write-Host ("{0} [{1}]: {2,-40} (" -f $pepId, $type, $title) -NoNewline
        Write-Host $status -ForegroundColor $color -NoNewline
        Write-Host ") by $author"
    }
}

# ----------------------------------------------------------------------------
# Status summary, unexpected-status flags, grouped-by-status listing, and
# (with --since) a changes-since-date section — built for meeting prep.
# ----------------------------------------------------------------------------
function Show-PepStatus {
    param([string[]]$Arguments)

    $since = $null
    for ($i = 0; $i -lt $Arguments.Count; $i++) {
        if ($Arguments[$i] -eq "--since") {
            $since = $Arguments[$i + 1]
            $i++
        } else {
            Write-PepLog ERROR "Unknown option: $($Arguments[$i])"
            Write-PepLog INFO "Usage: pep-tools.ps1 status [--since YYYY-MM-DD]"
            exit 1
        }
    }

    if ($since -and $since -notmatch '^\d{4}-\d{2}-\d{2}$') {
        Write-PepLog ERROR "--since expects a date in YYYY-MM-DD format"
        exit 1
    }

    if (-not (Test-Path $script:PEP_DIR)) {
        Write-PepLog WARN "PEP directory does not exist: $($script:PEP_DIR)"
        return
    }

    $knownStatuses = @("Draft", "Active", "Implemented", "Rejected", "Superseded")
    $exampleId = Get-PepId 1
    $idFormat = $exampleId -replace '001$', ''

    Write-Host "PEP Status Summary (ID format: ${idFormat}NNN):" -ForegroundColor Blue
    Write-Host "============================================="

    $files = @(Get-ChildItem -Path $script:PEP_DIR -Filter "pep-*.md" -File -ErrorAction SilentlyContinue)

    # Cache field lookups once per file
    $meta = @{}
    foreach ($pep in $files) {
        $meta[$pep.FullName] = @{
            Status  = Get-PepField $pep.FullName "Status"
            Title   = Get-PepField $pep.FullName "Title"
            Created = Get-PepField $pep.FullName "Created"
            Updated = Get-PepField $pep.FullName "Updated"
        }
    }

    $total = 0
    foreach ($status in $knownStatuses) {
        $count = @($files | Where-Object { $meta[$_.FullName].Status -eq $status }).Count
        Write-Host ("{0,-12}: {1}" -f $status, $count)
        $total += $count
    }
    Write-Host "-------------"
    Write-Host ("{0,-12}: {1}" -f "Total", $total)

    # Flag PEPs whose status doesn't match one of the known values
    $unexpected = @($files | Where-Object { $knownStatuses -notcontains $meta[$_.FullName].Status })
    if ($unexpected.Count -gt 0) {
        Write-Host ""
        Write-Host "PEPs with unexpected or missing status (needs fixing):" -ForegroundColor Red
        foreach ($pep in $unexpected) {
            $num = Get-PepNumFromFile $pep.FullName
            $pepId = Get-PepId ([int]$num)
            $status = $meta[$pep.FullName].Status
            if (-not $status) { $status = "<none>" }
            Write-Host ("  {0,-20} {1,-20} {2}" -f $pepId, $status, $pep.FullName)
        }
    }

    # Grouped listing by status — formatted for copy/paste into meeting notes
    Write-Host ""
    Write-Host "PEPs by Status" -ForegroundColor Blue
    Write-Host "=============="
    foreach ($status in $knownStatuses) {
        $matching = @($files | Where-Object { $meta[$_.FullName].Status -eq $status })
        if ($matching.Count -eq 0) { continue }

        Write-Host ""
        Write-Host "## $status ($($matching.Count))"
        foreach ($pep in $matching) {
            $num = Get-PepNumFromFile $pep.FullName
            $pepId = Get-PepId ([int]$num)
            $title = $meta[$pep.FullName].Title
            $abstract = Get-PepAbstract $pep.FullName
            Write-Host "- ${pepId}: $title"
            if ($abstract) { Write-Host "    $abstract" }
        }
    }

    # Changes since a given date
    if ($since) {
        Write-Host ""
        Write-Host "Changes since $since" -ForegroundColor Blue
        Write-Host "============================="

        $raised = @()
        $completed = @()
        $updated = @()
        foreach ($pep in $files) {
            $m = $meta[$pep.FullName]
            $isNew = $false
            if ($m.Created -and $m.Created -ge $since) {
                $raised += $pep
                $isNew = $true
            }
            $isTerminal = @("Implemented", "Rejected", "Superseded") -contains $m.Status
            if ($m.Updated -and $m.Updated -ge $since) {
                if ($isTerminal) { $completed += $pep }
                elseif (-not $isNew) { $updated += $pep }
            }
        }

        Write-Host ""
        Write-Host "New PEPs raised ($($raised.Count)):"
        if ($raised.Count -eq 0) { Write-Host "  None" }
        else {
            foreach ($pep in $raised) {
                $num = Get-PepNumFromFile $pep.FullName
                $pepId = Get-PepId ([int]$num)
                $m = $meta[$pep.FullName]
                Write-Host "  - ${pepId}: $($m.Title) (created $($m.Created))"
            }
        }

        Write-Host ""
        Write-Host "Completed ($($completed.Count)):"
        if ($completed.Count -eq 0) { Write-Host "  None" }
        else {
            foreach ($pep in $completed) {
                $num = Get-PepNumFromFile $pep.FullName
                $pepId = Get-PepId ([int]$num)
                $m = $meta[$pep.FullName]
                Write-Host "  - ${pepId}: $($m.Title) — now $($m.Status) (updated $($m.Updated))"
            }
        }

        Write-Host ""
        Write-Host "Other updates ($($updated.Count)):"
        if ($updated.Count -eq 0) { Write-Host "  None" }
        else {
            foreach ($pep in $updated) {
                $num = Get-PepNumFromFile $pep.FullName
                $pepId = Get-PepId ([int]$num)
                $m = $meta[$pep.FullName]
                Write-Host "  - ${pepId}: $($m.Title) — $($m.Status) (updated $($m.Updated))"
            }
        }
    }
}

# ----------------------------------------------------------------------------
# Initialize PEP framework in current directory
# ----------------------------------------------------------------------------
function Initialize-PepFramework {
    Write-PepLog INFO "Initializing PEP framework..."

    Confirm-Directories

    if (-not (Test-Path $script:CONFIG_FILE)) {
        $projectName = Split-Path (Get-Location) -Leaf
        @"
# PEP Framework Configuration — project-level settings (commit this file)
PROJECT_NAME="$projectName"

# PEP identifier codes — combined to build IDs like PEP-PROJECT_CODE-REPO_CODE-001
# Leave blank to fall back to the default PEP-001 format
PROJECT_CODE=""
REPO_CODE=""

# Enable/disable the Blogs (Build Logs) feature
ENABLE_BLOGS="y"

# Integration settings
ZABBIX_HOST=""
GRAFANA_URL=""

# Notification settings (optional)
SLACK_WEBHOOK=""
EMAIL_NOTIFICATIONS="false"

# Git integration — require all commits to reference a PEP
REQUIRE_PEP_REFERENCE=false

# Debug mode
DEBUG="false"
"@ | Set-Content -Path $script:CONFIG_FILE
        Write-PepLog INFO "Created configuration file: $($script:CONFIG_FILE)"
    }

    $localConfig = "$($script:CONFIG_FILE).local"
    if (-not (Test-Path $localConfig)) {
        $authorName = Get-GitConfigValue "user.name"
        if (-not $authorName) { $authorName = "Your Name" }
        @"
# PEP Framework — personal settings (do NOT commit this file)
PEP_AUTHOR="$authorName"
DEFAULT_EDITOR="notepad"
AUTO_OPEN_EDITOR="true"
"@ | Set-Content -Path $localConfig
        Write-PepLog INFO "Created personal configuration: $localConfig"
    }

    Test-PepTemplates
    Install-PepGitHooks

    Write-PepLog INFO "PEP framework initialized successfully!"
    Write-PepLog INFO "Edit $($script:CONFIG_FILE) to set your PROJECT_CODE and REPO_CODE"
    Write-PepLog INFO "Create your first PEP with: .\tools\pep-tools.ps1 new-pep 'Project Foundation'"
}

# Warn if templates are missing (they come from cookiecutter or update-templates)
function Test-PepTemplates {
    if (-not (Test-Path (Join-Path $script:TEMPLATE_DIR "pep-template.md"))) {
        Write-PepLog WARN "PEP template not found: $($script:TEMPLATE_DIR)/pep-template.md"
        Write-PepLog INFO "Run '.\tools\pep-tools.ps1 update-templates --source <path>' to pull templates from source"
    }
    if ((Get-EnableBlogs) -eq "y" -and -not (Test-Path (Join-Path $script:TEMPLATE_DIR "blog-template.md"))) {
        Write-PepLog WARN "BLOG template not found: $($script:TEMPLATE_DIR)/blog-template.md"
        Write-PepLog INFO "Run '.\tools\pep-tools.ps1 update-templates --source <path>' to pull templates from source"
    }
}

# ----------------------------------------------------------------------------
# Update pep-tools.ps1 from a source path or URL
# ----------------------------------------------------------------------------
function Update-PepTools {
    param([string[]]$Arguments)

    $source = $null
    $saveSource = $false
    for ($i = 0; $i -lt $Arguments.Count; $i++) {
        switch ($Arguments[$i]) {
            "--source" { $source = $Arguments[$i + 1]; $i++ }
            "--save"   { $saveSource = $true }
            default    { Write-PepLog ERROR "Unknown option: $($Arguments[$i])"; exit 1 }
        }
    }

    if (-not $source -and $script:PEP_FRAMEWORK_SOURCE) { $source = $script:PEP_FRAMEWORK_SOURCE }
    if (-not $source) {
        Write-PepLog ERROR "No source specified. Provide --source <path|url> or set PEP_FRAMEWORK_SOURCE in .peprc.local"
        exit 1
    }

    $dest = "tools/pep-tools.ps1"
    $backup = "$dest.bak"
    Copy-Item $dest $backup -Force
    Write-PepLog INFO "Backed up current tools to $backup"

    try {
        if ($source -match '^https?://') {
            Invoke-WebRequest -Uri $source -OutFile $dest
        } else {
            $srcFile = $source
            if (Test-Path $source -PathType Container) { $srcFile = Join-Path $source "pep-tools.ps1" }
            if (-not (Test-Path $srcFile)) {
                Write-PepLog ERROR "Source file not found: $srcFile"
                Copy-Item $backup $dest -Force
                exit 1
            }
            Copy-Item $srcFile $dest -Force
        }
    } catch {
        Write-PepLog ERROR "Update failed: $_"
        Copy-Item $backup $dest -Force
        exit 1
    }

    Write-PepLog INFO "Updated $dest from $source"

    $localConfig = "$($script:CONFIG_FILE).local"
    if ($saveSource -or -not $script:PEP_FRAMEWORK_SOURCE) {
        if ((Test-Path $localConfig) -and (Select-String -Path $localConfig -Pattern "PEP_FRAMEWORK_SOURCE" -Quiet)) {
            (Get-Content $localConfig) -replace 'PEP_FRAMEWORK_SOURCE=.*', "PEP_FRAMEWORK_SOURCE=`"$source`"" | Set-Content $localConfig
        } else {
            Add-Content -Path $localConfig -Value "PEP_FRAMEWORK_SOURCE=`"$source`""
        }
        Write-PepLog INFO "Saved PEP_FRAMEWORK_SOURCE to $localConfig"
    }
}

# ----------------------------------------------------------------------------
# Update template files from a source path
# ----------------------------------------------------------------------------
function Update-PepTemplates {
    param([string[]]$Arguments)

    $source = $null
    for ($i = 0; $i -lt $Arguments.Count; $i++) {
        if ($Arguments[$i] -eq "--source") { $source = $Arguments[$i + 1]; $i++ }
        else { Write-PepLog ERROR "Unknown option: $($Arguments[$i])"; exit 1 }
    }

    if (-not $source -and $script:PEP_FRAMEWORK_SOURCE) { $source = $script:PEP_FRAMEWORK_SOURCE }
    if (-not $source) {
        Write-PepLog ERROR "No source specified. Provide --source <path> or set PEP_FRAMEWORK_SOURCE in .peprc.local"
        exit 1
    }
    if ($source -match '^https?://') {
        Write-PepLog ERROR "URL sources are not supported for update-templates — use a local path."
        Write-PepLog INFO "Set PEP_FRAMEWORK_SOURCE to the local tools/ directory of your cookiecutter checkout."
        exit 1
    }

    $srcDir = $source
    if (Test-Path $source -PathType Leaf) { $srcDir = Split-Path $source -Parent }

    $templateSrc = Join-Path (Split-Path $srcDir -Parent) "docs/templates"
    if (-not (Test-Path $templateSrc)) {
        Write-PepLog ERROR "Templates directory not found. Expected at: $templateSrc"
        exit 1
    }

    Confirm-Directories

    $updated = 0
    foreach ($template in @("pep-template.md", "blog-template.md")) {
        $src = Join-Path $templateSrc $template
        if (Test-Path $src) {
            Copy-Item $src (Join-Path $script:TEMPLATE_DIR $template) -Force
            Write-PepLog INFO "Updated $($script:TEMPLATE_DIR)/$template"
            $updated++
        } else {
            Write-PepLog WARN "Not found in source: $src"
        }
    }
    Write-PepLog INFO "Updated $updated template(s) from $templateSrc"
}

# ----------------------------------------------------------------------------
# Setup git hooks
# ----------------------------------------------------------------------------
function Install-PepGitHooks {
    $hookFile = ".git/hooks/commit-msg"
    $sourceHook = "tools/git-hooks/commit-msg"

    if (-not (Test-Path $sourceHook)) {
        Write-PepLog WARN "Git hook source not found: $sourceHook"
        return
    }

    if (Test-Path ".git") {
        Copy-Item $sourceHook $hookFile -Force
        Write-PepLog INFO "Installed git commit-msg hook"
    } else {
        Write-PepLog WARN "Not in a git repository, skipping hook installation"
    }
}

# ----------------------------------------------------------------------------
# Help
# ----------------------------------------------------------------------------
function Show-PepHelp {
    $filePrefix = Get-FilePrefix
    $exampleId = Get-PepId 1
    $idFormat = $exampleId -replace '001$', ''
    $enableBlogs = Get-EnableBlogs

    Write-Host "PEP Management Tool v2.0 (PowerShell)" -ForegroundColor Blue
    Write-Host "========================"
    Write-Host ""
    Write-Host "Usage: .\tools\pep-tools.ps1 <command> [arguments]" -ForegroundColor Green
    Write-Host ""
    Write-Host "PEP commands:" -ForegroundColor Green
    Write-Host "  new-pep [number] [title]              Create a new PEP (prompts for type, priority, abstract)"
    Write-Host "  new-branch [pep-num]                  Create git feature branch for a PEP"
    Write-Host "  commit <pep-num> [message]            Commit with correct PEP message format"
    if ($enableBlogs -eq "y") {
        Write-Host "  new-blog [blog-num] [pep-num]         Create implementation blog for a PEP"
    }
    Write-Host "  list                                   List all PEPs with status"
    Write-Host "  status [--since YYYY-MM-DD]            Status summary, by-status listing (copy/paste-ready),"
    Write-Host "                                          flags PEPs with an unexpected/missing status, and with"
    Write-Host "                                          --since adds a Changes section (raised/completed/updated)"
    Write-Host "  migrate [--dry-run]                    Rename existing PEPs to current naming scheme"
    Write-Host ""
    Write-Host "Framework commands:" -ForegroundColor Green
    Write-Host "  init                                    Initialize PEP framework in current directory"
    Write-Host "  update-tools [--source <path|url>]     Update pep-tools.ps1 from source"
    Write-Host "  update-templates [--source <path>]     Update PEP/BLOG templates from source"
    Write-Host "  help                                    Show this help message"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Green
    Write-Host "  .\tools\pep-tools.ps1 new-pep `"Monitoring Integration`""
    Write-Host "  .\tools\pep-tools.ps1 new-branch 5"
    Write-Host "  .\tools\pep-tools.ps1 commit 5 `"Add Prometheus scrape config`""
    Write-Host "  .\tools\pep-tools.ps1 status --since 2026-07-01"
    if ($enableBlogs -eq "y") {
        Write-Host "  .\tools\pep-tools.ps1 new-blog 3 5"
    }
    Write-Host "  .\tools\pep-tools.ps1 migrate --dry-run"
    Write-Host "  .\tools\pep-tools.ps1 migrate"
    Write-Host "  .\tools\pep-tools.ps1 update-tools --source \path\to\cookiecutter\{{cookiecutter.project_slug}}\tools"
    Write-Host "  .\tools\pep-tools.ps1 update-templates"
    Write-Host ""
    Write-Host "PEP Types:" -ForegroundColor Green
    Write-Host "  Project | Feature | Process | Infrastructure | Documentation | Bug | Enhancement | Research | Security | Performance"
    Write-Host ""
    Write-Host "ID & file naming (this repo):" -ForegroundColor Green
    Write-Host "  ID format:   ${idFormat}NNN   (e.g. $exampleId)"
    Write-Host "  File format: ${filePrefix}NNN-type-slug.md"
    Write-Host "  Commit:      $($filePrefix.ToLower())NNN: description"
    Write-Host "  Branch:      feature/${filePrefix}NNN-type-slug"
    Write-Host ""
    Write-Host "Configuration:" -ForegroundColor Green
    Write-Host "  .peprc       — project settings: PROJECT_CODE, REPO_CODE, ENABLE_BLOGS (commit this)"
    Write-Host "  .peprc.local — personal settings: PEP_AUTHOR, DEFAULT_EDITOR, PEP_FRAMEWORK_SOURCE (gitignored)"
}

# ----------------------------------------------------------------------------
# Main dispatch
# ----------------------------------------------------------------------------
switch ($Command) {
    "init"             { Initialize-PepFramework }
    "new-pep"          { New-Pep -Arguments $Rest }
    "new-branch"       { New-PepBranch -Arguments $Rest }
    "commit"           { Invoke-PepCommit -Arguments $Rest }
    "new-blog"         { New-PepBlog -BlogNum $Rest[0] -PepNum $Rest[1] }
    "list"             { Show-PepList }
    "status"           { Show-PepStatus -Arguments $Rest }
    "migrate"          { Invoke-PepMigrate -Arguments $Rest }
    "update-tools"     { Update-PepTools -Arguments $Rest }
    "update-templates" { Update-PepTemplates -Arguments $Rest }
    "help"             { Show-PepHelp }
    "-h"               { Show-PepHelp }
    "--help"           { Show-PepHelp }
    default {
        Write-PepLog ERROR "Unknown command: $Command"
        Show-PepHelp
        exit 1
    }
}
