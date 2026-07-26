# Troubleshooting

This document covers the most common installation and runtime issues for the **Sub Domain Enumeration Tool for Linux**.

---

# Table of Contents

- [Installation Issues](#installation-issues)
- [Go PATH Issues](#go-path-issues)
- [ProjectDiscovery httpx Conflict](#projectdiscovery-httpx-conflict)
- [Missing Dependencies](#missing-dependencies)
- [Permission Denied](#permission-denied)
- [Go Installation Issues](#go-installation-issues)
- [PureDNS Issues](#puredns-issues)
- [MassDNS Issues](#massdns-issues)
- [Findomain Issues](#findomain-issues)
- [SecLists Issues](#seclists-issues)
- [crt.sh Timeout](#crtsh-timeout)
- [HTTP Probing Issues](#http-probing-issues)
- [ffuf Not Working](#ffuf-not-working)
- [Installer Problems](#installer-problems)
- [General Debugging](#general-debugging)

---

# Installation Issues

## install.sh: Permission denied

### Problem

```bash
./install.sh
```

returns

```text
Permission denied
```

### Solution

```bash
chmod +x install.sh
chmod +x sub_enum.sh
```

Run again

```bash
./install.sh --install
```

---

# Go PATH Issues

## subfinder: command not found

or

```text
dnsx: command not found
```

### Cause

Go binaries are installed in

```text
~/go/bin
```

but this directory is not in your PATH.

### Solution

For Bash

```bash
echo 'export PATH="$HOME/go/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

For Zsh

```bash
echo 'export PATH="$HOME/go/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Verify

```bash
which subfinder
```

---

# ProjectDiscovery httpx Conflict

## Wrong httpx Installed

### Symptoms

```text
Error:
No such option: -l
```

or

```text
No such option: -status-code
```

### Cause

The Python package named **httpx** is installed instead of the ProjectDiscovery tool.

### Verify

```bash
type -a httpx
```

Correct binary

```text
~/go/bin/httpx
```

Wrong binary

```text
/usr/bin/httpx
```

### Fix

Remove Python version

```bash
pip uninstall httpx
```

or

```bash
pip3 uninstall httpx
```

Install ProjectDiscovery version

```bash
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
```

Verify

```bash
httpx -h
```

---

# Missing Dependencies

Check all installed tools

```bash
./install.sh --check
```

or

```bash
sub_enum --check
```

---

# Permission Denied

If the tool cannot write output files

Check permissions

```bash
ls -la
```

Change ownership if necessary

```bash
sudo chown -R "$USER":"$USER" .
```

---

# Go Installation Issues

Verify Go

```bash
go version
```

If Go is missing

Ubuntu/Debian

```bash
sudo apt install golang
```

Arch

```bash
sudo pacman -S go
```

Fedora

```bash
sudo dnf install golang
```

---

# PureDNS Issues

## puredns not found

Install

```bash
go install github.com/d3mondev/puredns/v2@latest
```

---

## PureDNS returns no results

Possible reasons

- Resolver list is outdated
- MassDNS missing
- Network restrictions
- Invalid domain

Try another resolver list.

---

# MassDNS Issues

Verify

```bash
massdns --help
```

If missing

```bash
git clone https://github.com/blechschmidt/massdns.git

cd massdns

make

sudo make install
```

---

# Findomain Issues

Some Linux distributions do not provide Findomain packages.

Download the latest release

https://github.com/findomain/findomain/releases

Verify

```bash
findomain --help
```

---

# SecLists Issues

Verify

```bash
ls /usr/share/seclists
```

If missing

```bash
git clone https://github.com/danielmiessler/SecLists.git

sudo mv SecLists /usr/share/seclists
```

---

# crt.sh Timeout

Sometimes crt.sh may become slow or unavailable.

Symptoms

- Request timeout
- Empty output
- HTTP 503

This is expected.

The script will continue using the remaining passive sources.

---

# HTTP Probing Issues

If HTTP probing finds no live hosts

Check connectivity

```bash
ping google.com
```

Verify httpx

```bash
httpx -version
```

Test manually

```bash
echo example.com | httpx
```

---

# ffuf Not Working

Verify installation

```bash
ffuf -V
```

Install

Ubuntu

```bash
sudo apt install ffuf
```

or

```bash
go install github.com/ffuf/ffuf/v2@latest
```

---

# Installer Problems

If installation stops unexpectedly

Run

```bash
bash -x install.sh --install
```

This enables Bash debugging and prints every executed command.

---

# General Debugging

Verify installed tools

```bash
subfinder -version

assetfinder

amass -version

dnsx -version

httpx -version

ffuf -V

gobuster version
```

Check PATH

```bash
echo $PATH
```

Locate a command

```bash
which httpx
```

List all matching binaries

```bash
type -a httpx
```

---

# Still Need Help?

If you're still experiencing issues:

1. Run

```bash
./install.sh --check
```

2. Collect the output.

3. Open a GitHub Issue and include:

- Linux distribution
- Kernel version
- Go version
- Bash version
- Error message
- Output of `./install.sh --check`

This information helps reproduce and resolve the issue quickly.

---

## Reporting Bugs

Before opening an issue, please verify:

- You are using the latest version.
- All dependencies are installed.
- Go binaries are available in your PATH.
- ProjectDiscovery `httpx` is installed (not the Python package).

If the problem persists, open an issue on GitHub with the requested diagnostic information.
