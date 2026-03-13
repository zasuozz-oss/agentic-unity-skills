# Setup Unity Skills for current project (Windows)
# Usage: powershell -ExecutionPolicy Bypass -File /path/to/antigravity-unity-skills/setup-project.ps1
#
# Installs Unity skills into the current project's .agents\skills-unity\ directory
# and updates the project's GEMINI.md with skill references.

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Get-Location
$SkillsSrc = Join-Path $ScriptDir "global-config\skills"
$SkillsDst = Join-Path $ProjectDir ".agents\skills-unity"
$GeminiMd = Join-Path $ProjectDir "GEMINI.md"

# Block markers
$BlockStart = "<!-- BEGIN antigravity-unity-skills -->"
$BlockEnd = "<!-- END antigravity-unity-skills -->"

Write-Host "╔════════════════════════════════════════════════════════════╗"
Write-Host "║     Unity Skills — Project Setup                          ║"
Write-Host "║     Install 70 Unity skills into current project          ║"
Write-Host "╚════════════════════════════════════════════════════════════╝"
Write-Host ""

# Check source
if (-not (Test-Path $SkillsSrc)) {
    Write-Host "❌ Error: global-config\skills\ not found" -ForegroundColor Red
    Write-Host "   Make sure the script path is correct"
    exit 1
}

# Step 1: Install skills
Write-Host "📚 Step 1: Installing Unity skills..."

if (Test-Path $SkillsDst) {
    Remove-Item -Recurse -Force $SkillsDst
}

New-Item -ItemType Directory -Path (Split-Path $SkillsDst -Parent) -Force | Out-Null
Copy-Item -Recurse -Force $SkillsSrc $SkillsDst

$SkillCount = (Get-ChildItem -Path $SkillsDst -Filter "SKILL.md" -Recurse).Count
Write-Host "   ✓ $SkillCount skills installed to .agents\skills-unity\"
Write-Host ""

# Step 2: Update GEMINI.md (block-based, non-destructive)
Write-Host "📝 Step 2: Updating project GEMINI.md..."

$UnityBlock = @"
$BlockStart
@.agents/skills-unity/INDEX.md
$BlockEnd
"@

if (Test-Path $GeminiMd) {
    $content = Get-Content $GeminiMd -Raw
    if ($content -match [regex]::Escape($BlockStart)) {
        # Replace existing block
        $pattern = [regex]::Escape($BlockStart) + "[\s\S]*?" + [regex]::Escape($BlockEnd)
        $content = [regex]::Replace($content, $pattern, $UnityBlock)
        Set-Content -Path $GeminiMd -Value $content -NoNewline
        Write-Host "   ✓ Updated existing block in: GEMINI.md"
    } else {
        # Append block
        Add-Content -Path $GeminiMd -Value "`n$UnityBlock"
        Write-Host "   ✓ Appended block to: GEMINI.md"
    }
} else {
    # Create new file
    Set-Content -Path $GeminiMd -Value $UnityBlock
    Write-Host "   ✓ Created: GEMINI.md"
}
Write-Host ""

# Step 3: Verify
Write-Host "✅ Step 3: Verification..."
Write-Host "   Skills:    $SkillCount"
Write-Host "   Location:  .agents\skills-unity\"
Write-Host "   GEMINI.md: ✓"
Write-Host ""

# Summary
Write-Host "╔════════════════════════════════════════════════════════════╗"
Write-Host "║     Setup Complete                                        ║"
Write-Host "╚════════════════════════════════════════════════════════════╝"
Write-Host ""
Write-Host "📊 Summary:"
Write-Host "   - Project:  $ProjectDir"
Write-Host "   - Skills:   $SkillCount Unity skills installed"
Write-Host "   - Config:   GEMINI.md updated"
Write-Host ""
Write-Host "🚀 Next steps:"
Write-Host "   1. Open Antigravity in this project"
Write-Host "   2. Unity skills auto-load via GEMINI.md"
Write-Host ""
Write-Host "✅ Done!"
