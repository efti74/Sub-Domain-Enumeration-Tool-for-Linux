#!/usr/bin/env bash
#
# ============================================================
#  Sub Domain Enumeration Installer
#  Author : Efti74
#  Version: 1.0.0
# ============================================================

set -Eeuo pipefail

########################################
# Configuration
########################################

TOOL_NAME="Sub Domain Enumeration"
VERSION="1.0.0"

INSTALL_DIR="/usr/local/bin"
COMMAND_NAME="sub_enum"

SCRIPT_NAME="sub_enum.sh"

GO_TOOLS=(
"github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
"github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
"github.com/projectdiscovery/httpx/cmd/httpx@latest"
"github.com/projectdiscovery/alterx/cmd/alterx@latest"
"github.com/tomnomnom/assetfinder@latest"
)

APT_PACKAGES=(
curl
wget
git
jq
golang
python3
python3-pip
ffuf
gobuster
amass
)

DNF_PACKAGES=(
curl
wget
git
jq
golang
python3
python3-pip
ffuf
gobuster
amass
)

PACMAN_PACKAGES=(
curl
wget
git
jq
go
python
python-pip
ffuf
gobuster
amass
)

########################################
# Colours
########################################

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RESET="\033[0m"

########################################
# Logging
########################################

info() {
echo -e "${BLUE}[INFO]${RESET} $*"
}

ok() {
echo -e "${GREEN}[ OK ]${RESET} $*"
}

warn() {
echo -e "${YELLOW}[WARN]${RESET} $*"
}

error() {
echo -e "${RED}[FAIL]${RESET} $*"
}

########################################
# Banner
########################################

banner() {

cat <<EOF

============================================================
          Sub Domain Enumeration Installer
                  Created by Efti74
============================================================

Version : ${VERSION}

EOF

}

########################################
# Error Handler
########################################

trap 'error "Installation failed on line $LINENO"' ERR

########################################
# Root Check
########################################

need_sudo() {

if [[ $EUID -ne 0 ]]; then
SUDO="sudo"
else
SUDO=""
fi

}

########################################
# Detect Package Manager
########################################

PKG_MANAGER=""

detect_package_manager() {

if command -v apt >/dev/null 2>&1; then

PKG_MANAGER="apt"

elif command -v dnf >/dev/null 2>&1; then

PKG_MANAGER="dnf"

elif command -v pacman >/dev/null 2>&1; then

PKG_MANAGER="pacman"

elif command -v zypper >/dev/null 2>&1; then

PKG_MANAGER="zypper"

else

error "Unsupported Linux Distribution."

exit 1

fi

ok "Package Manager : $PKG_MANAGER"

}

########################################
# Install Base Packages
########################################

install_packages() {

case "$PKG_MANAGER" in

apt)

info "Updating apt..."

$SUDO apt update

info "Installing packages..."

$SUDO apt install -y "${APT_PACKAGES[@]}"

;;

dnf)

$SUDO dnf install -y "${DNF_PACKAGES[@]}"

;;

pacman)

$SUDO pacman -Sy --noconfirm "${PACMAN_PACKAGES[@]}"

;;

zypper)

$SUDO zypper install -y \
curl wget git jq go python3 python3-pip ffuf gobuster

;;

esac

}

########################################
# Install Go Tools
########################################

install_go_tools() {

if ! command -v go >/dev/null; then

error "Go is not installed."

exit 1

fi

export PATH="$PATH:$HOME/go/bin"

for tool in "${GO_TOOLS[@]}"; do

info "Installing $tool"

go install "$tool"

done

}
########################################
# Check if command exists
########################################

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

########################################
# Install SecLists
########################################

install_seclists() {

    if [[ -d "/usr/share/seclists" ]]; then
        ok "SecLists already installed."
        return
    fi

    info "Installing SecLists..."

    $SUDO git clone https://github.com/danielmiessler/SecLists.git /usr/share/seclists

    ok "SecLists installed."

}

########################################
# Install Findomain
########################################

install_findomain() {

    if command_exists findomain; then
        ok "findomain already installed."
        return
    fi

    warn "findomain was not found."

    warn "Please install it manually from:"
    echo "https://github.com/findomain/findomain/releases"

}

########################################
# Install Sublist3r
########################################

install_sublist3r() {

    if command_exists sublist3r; then
        ok "Sublist3r already installed."
        return
    fi

    info "Installing Sublist3r..."

    if command_exists pip3; then

        pip3 install --user Sublist3r || true

    fi

}

########################################
# Install PureDNS
########################################

install_puredns() {

    if command_exists puredns; then
        ok "PureDNS already installed."
        return
    fi

    info "Installing PureDNS..."

    go install github.com/d3mondev/puredns/v2@latest

}

########################################
# Install MassDNS
########################################

install_massdns() {

    if command_exists massdns; then
        ok "MassDNS already installed."
        return
    fi

    warn "MassDNS not found."

    warn "Installing from source..."

    mkdir -p /tmp/sub_enum_install

    cd /tmp/sub_enum_install

    git clone https://github.com/blechschmidt/massdns.git

    cd massdns

    make

    $SUDO cp bin/massdns /usr/local/bin/

    cd

}

########################################
# Detect Wrong httpx
########################################

verify_httpx() {

    if ! command_exists httpx; then

        error "httpx not installed."

        return

    fi

    if httpx -h 2>&1 | grep -qi "status-code"; then

        ok "ProjectDiscovery httpx detected."

    else

        error ""
        error "Wrong httpx detected!"
        error ""
        echo "Python HTTPX package is installed."
        echo ""
        echo "ProjectDiscovery httpx is REQUIRED."
        echo ""
        echo "Fix:"
        echo ""
        echo "pip uninstall httpx"
        echo ""
        echo "OR"
        echo ""
        echo "pip3 uninstall httpx"
        echo ""

        exit 1

    fi

}

########################################
# Install Main Tool
########################################

install_tool() {

    if [[ ! -f "$SCRIPT_NAME" ]]; then

        error "$SCRIPT_NAME not found."

        exit 1

    fi

    info "Installing ${COMMAND_NAME}..."

    $SUDO install -m755 "$SCRIPT_NAME" "${INSTALL_DIR}/${COMMAND_NAME}"

    ok "Installed."

}

########################################
# Verify Installed Commands
########################################

verify_tools() {

    echo

    info "Verifying installed tools..."

    REQUIRED_TOOLS=(

        subfinder
        assetfinder
        amass
        sublist3r
        gobuster
        ffuf
        findomain
        alterx
        dnsx
        httpx
        jq
        curl
        git
        puredns
        massdns

    )

    for tool in "${REQUIRED_TOOLS[@]}"; do

        if command_exists "$tool"; then

            printf "\033[32m[✓]\033[0m %-15s\n" "$tool"

        else

            printf "\033[31m[✗]\033[0m %-15s\n" "$tool"

        fi

    done

    echo

}

########################################
# Check PATH
########################################

verify_path() {

    if command_exists "${COMMAND_NAME}"; then

        ok "${COMMAND_NAME} available globally."

    else

        warn "${COMMAND_NAME} not found in PATH."

        warn "Try restarting your terminal."

    fi

}

########################################
# Install Everything
########################################

perform_install() {

    banner

    need_sudo

    detect_package_manager

    install_packages

    install_go_tools

    install_findomain

    install_sublist3r

    install_puredns

    install_massdns

    install_seclists

    verify_httpx

    install_tool

    verify_tools

    verify_path

}
########################################
# Check Installation
########################################

perform_check() {

    banner

    echo

    verify_tools

    verify_httpx

    verify_path

    echo
    ok "System check completed."

}

########################################
# Update Go Tools
########################################

perform_update() {

    banner

    info "Updating Go tools..."

    export PATH="$PATH:$HOME/go/bin"

    for tool in "${GO_TOOLS[@]}"; do

        info "Updating $tool"

        go install "$tool"

    done

    ok "Go tools updated."

}

########################################
# Uninstall
########################################

perform_uninstall() {

    banner

    info "Removing ${COMMAND_NAME}..."

    if [[ -f "${INSTALL_DIR}/${COMMAND_NAME}" ]]; then

        $SUDO rm -f "${INSTALL_DIR}/${COMMAND_NAME}"

        ok "${COMMAND_NAME} removed."

    else

        warn "${COMMAND_NAME} is not installed."

    fi

}

########################################
# Installation Summary
########################################

summary() {

cat <<EOF

============================================================
                 Installation Complete
============================================================

Tool Name : ${TOOL_NAME}

Version   : ${VERSION}

Command   : ${COMMAND_NAME}

Run:

    ${COMMAND_NAME}

Examples:

    ${COMMAND_NAME}

    ${COMMAND_NAME} -d example.com

    ${COMMAND_NAME} --help

============================================================

GitHub:
https://github.com/efti74/Sub-Domain-Enumeration-Tool-for-Linux

Happy Hunting!

============================================================

EOF

}

########################################
# Help
########################################

show_help() {

cat <<EOF

============================================================
          Sub Domain Enumeration Installer
============================================================

Usage:

./install.sh --install

./install.sh --check

./install.sh --update

./install.sh --uninstall

./install.sh --help

============================================================

Options

--install      Install dependencies and tool

--check        Verify installation

--update       Update Go tools

--uninstall    Remove installed command

--help         Show help

============================================================

EOF

}

########################################
# Main
########################################

main() {

need_sudo

case "${1:---install}" in

--install)

perform_install

summary

;;

--check)

perform_check

;;

--update)

perform_update

;;

--uninstall)

perform_uninstall

;;

--help|-h)

show_help

;;

*)

echo

error "Unknown option: $1"

echo

show_help

exit 1

;;

esac

}

main "$@"
