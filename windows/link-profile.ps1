# Symlinks the repo's PowerShell profile into the real profile location, and makes
# sure script execution is allowed for the current user (both required for the
# profile to actually load). Safe to re-run.

$ErrorActionPreference = "Stop"

$currentUserPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($currentUserPolicy -eq "Undefined" -or $currentUserPolicy -eq "Restricted") {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Write-Output "Set CurrentUser execution policy to RemoteSigned (was $currentUserPolicy)."
}

$target = Join-Path $HOME "Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
$source = Join-Path $PSScriptRoot "Microsoft.PowerShell_profile.ps1"

New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null

if (Test-Path $target) {
    $existing = Get-Item $target
    if ($existing.LinkType -eq "SymbolicLink" -and $existing.Target -eq $source) {
        Write-Output "Profile already linked."
        return
    }
    Remove-Item $target -Force
}

try {
    New-Item -ItemType SymbolicLink -Path $target -Target $source | Out-Null
    Write-Output "Linked $target -> $source"
} catch {
    # Developer Mode's symlink privilege only applies to new logon tokens, so this
    # can fail right after enabling it. Fall back to a plain copy so the profile still
    # works today; re-running after a fresh sign-in will upgrade it to a real symlink.
    Copy-Item $source $target -Force
    Write-Warning "Could not create symlink (enable Windows Developer Mode and sign out/in, or run as Administrator) - copied instead of linking for now."
}
