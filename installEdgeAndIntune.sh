#!/bin/bash

# STEP 1 — Remove ALL Microsoft repo files
## This resets your system so we can rebuild cleanly.
sudo rm -f /etc/apt/sources.list.d/microsoft-*.list
sudo rm -f /etc/apt/sources.list.d/microsoft-*.sources
sudo rm -f /etc/apt/sources.list.d/packages-microsoft-prod.list

## Also remove any leftover key files:
sudo rm -f /usr/share/keyrings/microsoft*.gpg

## Update
sudo apt update

# STEP 2 — Install the Microsoft signing key (ONE key only)
## This is the only key we will use for all Microsoft products.
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
| gpg --dearmor \
| sudo tee /usr/share/keyrings/microsoft-prod.gpg > /dev/null

# STEP 3 — Add the unified Microsoft repo for Ubuntu 24.04
## This single repo covers:
## - Intune
## - PowerShell
## - .NET
## - VS Code
## - Azure CLI
## - Microsoft identity packages
##
## Everything except Edge.
sudo tee /etc/apt/sources.list.d/microsoft-prod.sources > /dev/null << 'EOF'
Types: deb
URIs: https://packages.microsoft.com/ubuntu/24.04/prod/
Suites: noble
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/microsoft-prod.gpg
EOF

# STEP 4 — Add the Microsoft Edge repo (also using the SAME key)
sudo tee /etc/apt/sources.list.d/microsoft-edge.sources > /dev/null << 'EOF'
Types: deb
URIs: https://packages.microsoft.com/repos/edge
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/microsoft-prod.gpg
EOF

# STEP 5 — Update APT (no errors should appear)
## If this runs cleanly, your repo configuration is now perfect.
sudo apt update

# STEP 6 — Install Microsoft Edge (if not already installed)
sudo apt install microsoft-edge-stable

# STEP 7 — Install the Microsoft Intune App
## This will now install without any Signed-By conflicts.
sudo apt install intune-portal
