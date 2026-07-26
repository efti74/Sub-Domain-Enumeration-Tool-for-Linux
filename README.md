# 🔍 Sub Domain Enumeration Tool for Linux

A powerful Bash-based subdomain enumeration tool that automates passive and active reconnaissance for bug bounty hunting, penetration testing, and security assessments.

Designed for **Kali Linux**, **Ubuntu**, **Debian**, **Parrot OS**, and other Linux distributions.

---

## ✨ Features

- Passive Subdomain Enumeration
  - Subfinder
  - Assetfinder
  - Amass
  - Findomain
  - Sublist3r
  - crt.sh

- Active Enumeration
  - Gobuster
  - PureDNS

- DNS Validation
  - dnsx
  - PureDNS

- Subdomain Permutation
  - AlterX

- HTTP Probing
  - ProjectDiscovery httpx
  - Status Code
  - IP Address
  - Title
  - CNAME
  - Technologies

- Optional Virtual Host Discovery
  - ffuf

- Interactive Mode

- CLI Mode

- Automatic Tool Verification

- Organized Output Directory

---

# Installation

## Clone the Repository

```bash
git clone https://github.com/efti74/Sub-Domain-Enumeration-Tool-for-Linux.git

cd Sub-Domain-Enumeration-Tool-for-Linux
```

---

## Make Scripts Executable

```bash
chmod +x install.sh
chmod +x sub_enum.sh
```

---

## Install

```bash
./install.sh --install
```

The installer will

- Install required packages
- Install Go-based tools
- Verify dependencies
- Install the command globally

After installation you can run

```bash
sub_enum
```

from **any directory**.

---

# Verify Installation

```bash
./install.sh --check
```

or

```bash
sub_enum --help
```

---

# Update Installed Tools

```bash
./install.sh --update
```

---

# Uninstall

```bash
./install.sh --uninstall
```

---

# Usage

## Interactive Mode

Simply run

```bash
sub_enum
```

You will be prompted for

- Target Domain
- Wordlist
- Resolver List
- Output Directory
- Threads
- Active Enumeration
- Virtual Host Scan

---

## Command Line Mode

Example

```bash
sub_enum -d example.com
```

Example

```bash
sub_enum -d example.com \
-w wordlists/subdomains.txt \
-r resolvers/resolvers.txt \
-o recon_example
```

---

# Workflow

```
                    Target Domain
                           │
          ─────────────────┼─────────────────
                           │
              Passive Enumeration
                           │
     ┌─────────────────────────────────────┐
     │                                     │
Subfinder  Assetfinder  Amass  Findomain  crt.sh
     │                                     │
     └─────────────────────────────────────┘
                           │
                    Merge & Deduplicate
                           │
                     Active Enumeration
                   Gobuster + PureDNS
                           │
                      AlterX Permutation
                           │
                      DNS Validation
                     dnsx / PureDNS
                           │
                      HTTP Probing
                          httpx
                           │
                Optional VHost Discovery
                           │
                           ffuf
                           │
                       Final Results
```

---

# Output Structure

```
recon_example/

│
├── passive_unique.txt
├── all_candidates_unique.txt
├── resolved_subdomains.txt
├── dns_records.txt
├── httpx.jsonl
├── live_urls.txt
├── live_with_status.txt
├── dns_alive_but_no_http.txt
├── vhost_candidates_ffuf.txt
│
└── raw/
```

---

# Manual Dependencies

Some tools may require manual installation depending on your Linux distribution.

## Findomain

https://github.com/findomain/findomain/releases

---

## MassDNS

https://github.com/blechschmidt/massdns

---

## SecLists

https://github.com/danielmiessler/SecLists

---

# Troubleshooting

## Wrong httpx Installed

If you see

```
No such option: -l
```

or

```
Error: No such option: -status-code
```

you are probably using the **Python HTTPX package**.

Check

```bash
type -a httpx
```

The correct binary should be the **ProjectDiscovery** version.

---

## Go PATH

If Go tools are not found

```bash
echo 'export PATH=$HOME/go/bin:$PATH' >> ~/.bashrc

source ~/.bashrc
```

For Zsh

```bash
echo 'export PATH=$HOME/go/bin:$PATH' >> ~/.zshrc

source ~/.zshrc
```

---

## Verify Installed Tools

```bash
./install.sh --check
```

---

# Recommended Environment

- Kali Linux
- Debian
- Ubuntu
- Parrot OS

---

# Disclaimer

This tool is intended **only for authorised security assessments, penetration testing, educational purposes, and bug bounty programmes where you have permission to test**.

The author is **not responsible** for any misuse or damage caused by this software.

Always obtain proper authorisation before testing any target.

---

# Contributing

Contributions are welcome.

If you find a bug or have an idea for improvement:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Open a Pull Request

---

# Author

**Md. Sibgatur Rahman Efti**

GitHub

https://github.com/efti74

---

# License

This project is licensed under the MIT License.

---

⭐ If you find this project useful, consider giving it a star.
