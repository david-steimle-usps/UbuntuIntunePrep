#!/bin/bash

# Check for arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --pwsh | --powershell) install_pwsh=true ;;
        --dotnet) install_dotnet=true ;;
        --vscode) install_vscode=true ;;
        --azure-cli) install_azure_cli=true ;;
        --installoptional) install_pwsh=true; install_dotnet=true; install_vscode=true; install_azure_cli=true ;;
        --help) 
            echo "Usage: script.sh [options]"
            echo "Options:"
            echo "  --pwsh           Install PowerShell"
            echo "  --dotnet         Install .NET"
            echo "  --vscode         Install Visual Studio Code"
            echo "  --azure-cli      Install Azure CLI"
            echo "  --installoptional Install all optional items"
            exit 0
            ;;
        *) 
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

# Install logic based on flags
if [ "$install_pwsh" = true ]; then
    echo "Installing PowerShell..."
    # Installation commands here
fi
if [ "$install_dotnet" = true ]; then
    echo "Installing .NET..."
    # Installation commands here
fi
if [ "$install_vscode" = true ]; then
    echo "Installing VSCode..."
    # Installation commands here
fi
if [ "$install_azure_cli" = true ]; then
    echo "Installing Azure CLI..."
    # Installation commands here
fi
