# Tools Used

This document explains the purpose of every tool used by the **Sub Domain Enumeration Tool for Linux**, why it is included in the workflow, and how it contributes to discovering subdomains.

---

# Workflow Overview

```
Target Domain
      │
      ▼
Passive Enumeration
      │
      ▼
Merge & Remove Duplicates
      │
      ▼
Active Enumeration
      │
      ▼
Subdomain Permutation
      │
      ▼
DNS Validation
      │
      ▼
HTTP Probing
      │
      ▼
Optional Virtual Host Discovery
      │
      ▼
Final Results
```

---

# Passive Enumeration

Passive enumeration discovers subdomains without directly interacting with the target's infrastructure. It relies on publicly available data sources.

---

## Subfinder

**Purpose**

Fast passive subdomain enumeration using numerous online sources.

**Why it's included**

Subfinder is one of the fastest and most reliable passive enumeration tools.

**Strengths**

- Fast
- Low false positives
- Supports multiple passive sources
- Widely used in bug bounty

**Limitations**

- Only passive
- Dependent on available public sources

Project

https://github.com/projectdiscovery/subfinder

---

## Assetfinder

**Purpose**

Discover subdomains using public APIs and certificate sources.

**Why it's included**

Finds unique assets that may not appear in other tools.

**Strengths**

- Very fast
- Lightweight
- Excellent for quick reconnaissance

**Limitations**

- Limited data sources
- Passive only

Project

https://github.com/tomnomnom/assetfinder

---

## Amass

**Purpose**

Comprehensive attack surface mapping.

**Why it's included**

Amass often discovers subdomains that simpler tools miss.

**Strengths**

- Extensive data sources
- Recursive discovery
- ASN awareness
- Mature project

**Limitations**

- Slower than other passive tools
- Higher resource usage

Project

https://github.com/owasp-amass/amass

---

## Findomain

**Purpose**

Passive subdomain enumeration using multiple certificate and intelligence sources.

**Why it's included**

Often discovers additional subdomains not found by other passive tools.

**Strengths**

- Fast
- Good coverage
- Easy to use

**Limitations**

- Binary installation varies by platform

Project

https://github.com/findomain/findomain

---

## Sublist3r

**Purpose**

Searches multiple search engines and OSINT sources.

**Why it's included**

Provides additional passive coverage from different data providers.

**Strengths**

- Simple
- Reliable
- Useful as an additional source

**Limitations**

- Development is relatively slow
- Fewer sources than newer tools

Project

https://github.com/aboul3la/Sublist3r

---

## crt.sh

**Purpose**

Retrieve subdomains from Certificate Transparency logs.

**Why it's included**

Certificate logs frequently reveal forgotten or legacy subdomains.

**Strengths**

- Excellent historical data
- Completely passive
- No authentication required

**Limitations**

- Can be slow
- Occasionally unavailable
- May return duplicates

Website

https://crt.sh

---

# Active Enumeration

Active enumeration interacts directly with the target.

Use only against authorised targets.

---

## Gobuster

**Purpose**

Brute-force DNS subdomains using a wordlist.

**Why it's included**

Finds subdomains that are not publicly indexed.

**Strengths**

- Fast
- Highly configurable
- Good for internal naming conventions

**Limitations**

- Requires a good wordlist
- Generates DNS requests

Project

https://github.com/OJ/gobuster

---

## PureDNS

**Purpose**

Mass DNS resolution and wildcard filtering.

**Why it's included**

Efficiently validates large numbers of candidate subdomains.

**Strengths**

- Extremely fast
- Wildcard detection
- Scalable

**Limitations**

- Requires MassDNS
- Depends on resolver quality

Project

https://github.com/d3mondev/puredns

---

# Subdomain Permutation

---

## AlterX

**Purpose**

Generate likely subdomain permutations.

**Why it's included**

Creates intelligent variations based on discovered names.

Example

```
api.example.com

↓

dev-api.example.com

↓

staging-api.example.com

↓

api-prod.example.com
```

**Strengths**

- Intelligent permutations
- High-value discoveries
- Fast

**Limitations**

- Generated names require validation

Project

https://github.com/projectdiscovery/alterx

---

# DNS Validation

---

## dnsx

**Purpose**

Validate candidate subdomains.

**Why it's included**

Removes invalid hosts before HTTP probing.

**Strengths**

- Very fast
- Reliable
- Low memory usage

**Limitations**

- DNS validation only

Project

https://github.com/projectdiscovery/dnsx

---

# HTTP Probing

---

## httpx (ProjectDiscovery)

**Purpose**

Identify live web services.

The tool collects information such as

- HTTP Status Code
- Page Title
- IP Address
- CNAME
- Technologies
- Redirects

**Why it's included**

Determining which hosts actually serve web content is essential before further testing.

**Strengths**

- Extremely fast
- Rich metadata
- JSON output
- Highly reliable

**Limitations**

- HTTP/HTTPS only

Project

https://github.com/projectdiscovery/httpx

---

# Virtual Host Discovery

---

## ffuf

**Purpose**

Discover hidden virtual hosts.

**Why it's included**

Some applications exist only as virtual hosts and cannot be found through normal DNS enumeration.

**Strengths**

- Very fast
- Flexible
- Industry standard

**Limitations**

- Requires a valid base domain
- Depends on wordlist quality

Project

https://github.com/ffuf/ffuf

---

# Supporting Tools

---

## jq

Processes JSON output from APIs such as crt.sh.

---

## curl

Retrieves data from online services.

---

## Git

Used for downloading dependencies.

---

## Go

Required for installing ProjectDiscovery tools.

---

## SecLists

Provides high-quality wordlists for active enumeration and virtual host discovery.

Project

https://github.com/danielmiessler/SecLists

---

## MassDNS

Required by PureDNS for high-speed DNS resolution.

Project

https://github.com/blechschmidt/massdns

---

# Why Multiple Enumeration Tools?

No single tool can discover every subdomain.

Each tool uses different techniques and data sources. Combining multiple tools significantly increases overall coverage and reduces the chance of missing valuable assets.

The workflow is designed to:

1. Collect as many candidate subdomains as possible.
2. Remove duplicate entries.
3. Generate intelligent permutations.
4. Validate DNS records.
5. Identify live web services.
6. Discover hidden virtual hosts.

This layered approach provides broader coverage than relying on a single enumeration tool.

---

# Legal Notice

This project is intended only for authorised security assessments, penetration testing, educational purposes, and bug bounty programmes where you have explicit permission to test the target systems.

Always comply with applicable laws and the target organisation's rules of engagement.
