# UbuntuIntunePrep
Prepare an Ubuntu system for Intune join.

## installEdgeAndIntune.sh
`installEdgeAndIntune.sh` is a remediation-and-install script for Ubuntu 24.04 (amd64) that sets up Microsoft Edge and the Microsoft Intune Portal using a clean, conflict-free APT configuration. It optionally scans for and backs up any existing APT source files that reference `packages.microsoft.com`, removes them to eliminate common “Signed-By”/keyring conflicts, then installs a single Microsoft signing key and recreates the required Microsoft `prod` and `edge` repositories before installing `microsoft-edge-stable` and `intune-portal`. The script also performs a **report-only** check for likely full-disk encryption (LUKS/dm-crypt) and supports a `--dry-run` mode to preview actions without making changes.
