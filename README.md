# Sub Domain Enumeration

**Created by Efti74**

A Bash-based subdomain reconnaissance workflow for **authorized bug-bounty and penetration-testing scopes**. It combines passive discovery, active DNS enumeration, permutation generation, DNS validation, HTTP/HTTPS probing, status-code collection, and optional VHost discovery.

> **Important:** Install and verify the required tools **before running `./sub_enum.sh`**. If dependencies are missing, some enumeration stages will be skipped or may not work correctly.

## 1. Clone the repository

```bash
git clone <YOUR-GITHUB-REPOSITORY-URL>
cd <YOUR-REPOSITORY-NAME>
```

Replace the placeholders above with the actual GitHub repository URL and directory name after publishing.

## 2. Make the scripts executable

```bash
chmod +x install.sh sub_enum.sh
```

## 3. Install required tools first

Run the included dependency installer **before the reconnaissance script**:

```bash
./install.sh
```

The installer attempts to install or detect the dependencies used by the workflow, including:

- Subfinder
- Amass
- Assetfinder
- Findomain
- Sublist3r
- curl
- jq
- Gobuster
- PureDNS
- MassDNS
- AlterX
- dnsx
- **ProjectDiscovery httpx**
- ffuf
- SecLists/wordlists

Package availability differs between Linux distributions. If a dependency cannot be installed automatically, `install.sh` prints a **warning**. Install every missing dependency manually from its official project/package source before starting a full reconnaissance run.

After installation, review the verification output. Do not ignore `[WARNING] ... missing` messages for tools you expect the workflow to use.

For detailed descriptions and troubleshooting, read [`TOOLS.md`](TOOLS.md).

## 4. Verify the main script

Before the first run:

```bash
bash -n ./sub_enum.sh
```

If the command prints nothing, the Bash syntax is valid.

You can also view the available options:

```bash
./sub_enum.sh --help
```

## 5. Run Sub Domain Enumeration

### Recommended for beginners: interactive mode

Simply run:

```bash
./sub_enum.sh
```

The script asks for the configuration interactively.

Example:

```text
============================================================
                 Sub Domain Enumeration
                    Created by Efti74
============================================================

Interactive setup (optional fields can be skipped by pressing Enter)
------------------------------------------------------------------
Target domain (required, e.g. example.com): example.com
Wordlist [optional - Enter = default]:
PureDNS resolver list [optional - Enter = skip]:
Base URL for ffuf [optional - Enter = skip]:
Output directory [optional - Enter = automatic]:
Threads [optional - Enter = 50]:
Run active enumeration? [Y/n - Enter = Yes]:
Enable ffuf VHost stage? [Y/n - Enter = Yes]:
```

Only the **target domain is required**. For optional questions, press **Enter** to use the default value or skip that feature.

Enter the root domain, for example:

```text
example.com
```

Do not enter an arbitrary URL path such as:

```text
https://example.com/login/page
```

The optional **Base URL** prompt is specifically for ffuf VHost discovery and can accept a value such as:

```text
https://example.com
```

### Command-line mode

You can bypass the interactive questions by supplying arguments.

Basic:

```bash
./sub_enum.sh -d example.com
```

Custom wordlist:

```bash
./sub_enum.sh \
  -d example.com \
  -w /path/to/subdomains-wordlist.txt
```

Custom PureDNS resolver list:

```bash
./sub_enum.sh \
  -d example.com \
  -r /path/to/resolvers.txt
```

Optional ffuf VHost discovery:

```bash
./sub_enum.sh \
  -d example.com \
  -u https://example.com
```

Custom output directory:

```bash
./sub_enum.sh \
  -d example.com \
  -o recon_example
```

Custom concurrency:

```bash
./sub_enum.sh \
  -d example.com \
  -t 100
```

Passive/lower-noise mode:

```bash
./sub_enum.sh \
  -d example.com \
  --no-active
```

Disable only ffuf:

```bash
./sub_enum.sh \
  -d example.com \
  --no-ffuf
```

## 6. Recommended first-run sequence

For a new Linux installation, follow this exact order:

```bash
# 1. Enter the cloned repository
cd <YOUR-REPOSITORY-NAME>

# 2. Make scripts executable
chmod +x install.sh sub_enum.sh

# 3. Install/check dependencies
./install.sh

# 4. Resolve every important MISSING/WARNING dependency
#    shown by install.sh before continuing.

# 5. Validate Bash syntax
bash -n ./sub_enum.sh

# 6. Start interactive reconnaissance
./sub_enum.sh
```

Or, after dependencies are ready:

```bash
./sub_enum.sh -d example.com
```

## 7. Critical ProjectDiscovery httpx check

There are multiple programs named `httpx`. This project requires **ProjectDiscovery httpx**, not the Python HTTPX CLI.

Before your first full run, verify:

```bash
type -a httpx
httpx -h 2>&1 | grep -E -- '-l|-status-code|-json'
```

The correct tool supports options such as:

```text
-l
-status-code
-json
```

If you get:

```text
Error: No such option: -l
```

the wrong `httpx` is being executed.

If ProjectDiscovery httpx was installed using Go, try:

```bash
export PATH="$HOME/go/bin:$PATH"
hash -r
```

Then verify again:

```bash
httpx -version
httpx -h 2>&1 | grep -E -- '-l|-status-code|-json'
```

See `TOOLS.md` for more troubleshooting.

## 8. Wordlist note

SecLists paths vary between Linux distributions.

If the default wordlist configured in the script does not exist, locate your installed DNS wordlist and provide it explicitly:

```bash
./sub_enum.sh \
  -d example.com \
  -w /path/to/subdomains-top1million-20000.txt
```

Before using a custom wordlist:

```bash
test -f /path/to/wordlist.txt && wc -l /path/to/wordlist.txt
```

## 9. Understanding the results

The result directory contains files such as:

```text
passive_unique.txt
all_candidates_unique.txt
resolved_subdomains.txt
dns_records.txt
httpx.jsonl
live_urls.txt
live_with_status.txt
dns_alive_but_no_http.txt
vhost_candidates_ffuf.txt
raw/
```

Important files:

- **`resolved_subdomains.txt`** — main DNS-validated subdomain inventory when DNS validation tools are available.
- **`live_urls.txt`** — HTTP/HTTPS-responsive URLs.
- **`live_with_status.txt`** — live URL information including HTTP status and other collected metadata.
- **`httpx.jsonl`** — structured ProjectDiscovery httpx output.
- **`dns_alive_but_no_http.txt`** — DNS-resolving hosts that did not respond to HTTP/HTTPS probing.
- **`vhost_candidates_ffuf.txt`** — VHost candidates; these are kept separate from DNS subdomains.
- **`raw/`** — per-tool and intermediate results useful for troubleshooting.

An empty file does **not always mean zero findings**. A tool may have been missing, skipped, timed out, or failed. Check terminal warnings and `TOOLS.md` before interpreting empty results.

## Dependency manifest

`requirements.txt` lists the project dependencies, but it is **not a Python pip requirements file**.

Do not use:

```bash
pip install -r requirements.txt
```

Most dependencies are Linux/Go security tools. Use:

```bash
./install.sh
```

and manually install anything the installer reports as unavailable.

## Documentation

- `README.md` — installation and usage instructions.
- `TOOLS.md` — tool-by-tool explanations and troubleshooting.
- `requirements.txt` — dependency manifest.
- `install.sh` — best-effort dependency installer/checker.
- `SKILL.md` — instructions for compatible CLI-based AI agents.
- `sub_enum.sh` — main reconnaissance script.

## Legal and authorization notice

Use this project only on domains and systems you are explicitly authorized to test. Follow the target's bug-bounty or penetration-testing scope, automation restrictions, and rate limits. You are responsible for complying with applicable laws and program rules.
