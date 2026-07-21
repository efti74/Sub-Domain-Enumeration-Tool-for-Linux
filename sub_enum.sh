#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

banner(){ cat <<'EOF'
============================================================
                 Sub Domain Enumeration
                    Created by Efti74
============================================================
EOF
}
banner

# sub_enum.sh
# Authorized security testing / bug bounty reconnaissance only.
# Uses every tool requested:
#   subfinder, amass, assetfinder, findomain, sublist3r, crt.sh, gobuster, ffuf,
#   dnsx, puredns, alterx, httpx
#
# Pipeline:
# passive sources -> active DNS brute force -> permutations -> normalize/dedupe
# -> DNS resolution -> HTTP(S) probing -> status-code inventory
#
# Notes:
# - ffuf is used for VHost discovery, not DNS discovery. A reachable base URL/IP
#   is required, and results are candidates until separately DNS-resolved.
# - puredns is preferred for brute-force validation because it handles wildcard DNS.
# - Only names ending in the exact target domain are retained.

usage() {
  cat <<'EOF'
Usage:
  ./sub_enum.sh -d example.com [options]

Required:
  -d DOMAIN              Root domain in authorized scope

Options:
  -w WORDLIST            DNS/VHost wordlist
                         Default: /usr/share/seclists/Discovery/DNS/subdomains-top1million-20000.txt
  -r RESOLVERS           Resolver list for puredns (optional)
  -u BASE_URL            Base URL for ffuf VHost discovery, e.g. https://1.2.3.4
                         or https://example.com
  -o OUTPUT_DIR          Default: recon-DOMAIN-TIMESTAMP
  -t THREADS             HTTP/DNS concurrency hint (default: 50)
  --no-active            Skip Gobuster, puredns brute force, AlterX, and ffuf
  --no-ffuf              Skip ffuf VHost discovery
  -h, --help             Show help

Examples:
  ./sub_enum.sh -d example.com
  ./sub_enum.sh -d example.com -w /usr/share/seclists/Discovery/DNS/dns-Jhaddix.txt
  ./sub_enum.sh -d example.com -u https://example.com
EOF
}

DOMAIN=""
WORDLIST="/usr/share/SecLists-master/Discovery/DNS/subdomains-top1million-20000.txt"
RESOLVERS=""
BASE_URL=""
OUTDIR=""
THREADS=50
ACTIVE=1
RUN_FFUF=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d) DOMAIN="${2:-}"; shift 2 ;;
    -w) WORDLIST="${2:-}"; shift 2 ;;
    -r) RESOLVERS="${2:-}"; shift 2 ;;
    -u) BASE_URL="${2:-}"; shift 2 ;;
    -o) OUTDIR="${2:-}"; shift 2 ;;
    -t) THREADS="${2:-}"; shift 2 ;;
    --no-active) ACTIVE=0; shift ;;
    --no-ffuf) RUN_FFUF=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[!] Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

# Interactive mode when -d is not supplied.
if [[ -z "$DOMAIN" ]]; then
  echo
  echo "Interactive setup (optional fields can be skipped by pressing Enter)"
  echo "------------------------------------------------------------------"
  while [[ -z "$DOMAIN" ]]; do
    read -r -p "Target domain (required, e.g. example.com): " DOMAIN
    [[ -n "$DOMAIN" ]] || echo "[!] Target domain is required."
  done
  read -r -p "Wordlist [optional - Enter = default]: " v; [[ -n "$v" ]] && WORDLIST="$v"
  read -r -p "PureDNS resolver list [optional - Enter = skip]: " v; [[ -n "$v" ]] && RESOLVERS="$v"
  read -r -p "Base URL for ffuf [optional - Enter = skip]: " v; [[ -n "$v" ]] && BASE_URL="$v"
  read -r -p "Output directory [optional - Enter = automatic]: " v; [[ -n "$v" ]] && OUTDIR="$v"
  read -r -p "Threads [optional - Enter = 50]: " v; [[ -n "$v" ]] && THREADS="$v"
  read -r -p "Run active enumeration? [Y/n - Enter = Yes]: " v
  case "${v,,}" in n|no) ACTIVE=0;; esac
  if [[ "$ACTIVE" -eq 1 ]]; then
    read -r -p "Enable ffuf VHost stage? [Y/n - Enter = Yes]: " v
    case "${v,,}" in n|no) RUN_FFUF=0;; esac
  fi
  echo
fi

[[ -n "$DOMAIN" ]] || { echo "[!] -d DOMAIN is required." >&2; usage; exit 1; }

# Normalize user input to a hostname.
DOMAIN="$(printf '%s' "$DOMAIN" | tr '[:upper:]' '[:lower:]' | sed -E 's#^[a-z]+://##; s#/.*$##; s/:\d+$//; s/\.$//')"
if ! [[ "$DOMAIN" =~ ^([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,63}$ ]]; then
  echo "[!] Invalid root domain: $DOMAIN" >&2
  exit 1
fi
[[ "$THREADS" =~ ^[0-9]+$ ]] || { echo "[!] Threads must be numeric." >&2; exit 1; }

STAMP="$(date +%Y%m%d)"
OUTDIR="${OUTDIR:-recon-${DOMAIN}-${STAMP}}"
RAW="$OUTDIR/raw"
mkdir -p "$RAW"

log(){ printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }
have(){ command -v "$1" >/dev/null 2>&1; }
run_timeout(){
  local duration="$1"; shift
  if have timeout; then timeout "$duration" "$@"; else "$@"; fi
}
safe_run(){
  local label="$1"; shift
  log "$label"
  if ! "$@"; then
    log "WARNING: $label failed; continuing."
    return 0
  fi
}

# Keep only the root domain itself or true children of it.
normalize_scope() {
  awk -v d="$DOMAIN" '
    {
      gsub(/\r/,"");
      x=tolower($0);
      sub(/^[[:space:]]+/,"",x); sub(/[[:space:]]+$/,"",x);
      sub(/^\*\./,"",x); sub(/\.$/,"",x);
      if (x==d || (length(x)>length(d) && substr(x,length(x)-length(d),length(d)+1)=="." d))
        print x
    }' | sort -u
}

: > "$RAW/subfinder.txt"
: > "$RAW/amass.txt"
: > "$RAW/assetfinder.txt"
: > "$RAW/findomain.txt"
: > "$RAW/sublist3r.txt"
: > "$RAW/crtsh.txt"
: > "$RAW/gobuster.txt"
: > "$RAW/puredns.txt"
: > "$RAW/alterx_candidates.txt"
: > "$RAW/alterx_resolved.txt"
: > "$RAW/ffuf_vhosts.txt"

log "Output directory: $OUTDIR"
log "Target scope: *.$DOMAIN and $DOMAIN"

# ---------------- PASSIVE ENUMERATION ----------------

if have subfinder; then
  safe_run "Subfinder passive enumeration..." \
    bash -c 'subfinder -d "$1" -all -recursive -silent -o "$2"' _ "$DOMAIN" "$RAW/subfinder.txt"
else log "SKIP: subfinder not installed."; fi

if have amass; then
  log "Amass passive enumeration..."

  : > "$RAW/amass.unfiltered.txt"
  : > "$RAW/amass.stderr.log"

  if ! run_timeout 30m amass enum -passive -d "$DOMAIN" \
      > "$RAW/amass.unfiltered.txt" \
      2> "$RAW/amass.stderr.log"; then
    log "WARNING: Amass failed/timed out; keeping any partial output."
  fi

  if [[ -s "$RAW/amass.unfiltered.txt" ]]; then
    normalize_scope < "$RAW/amass.unfiltered.txt" > "$RAW/amass.txt"
  else
    : > "$RAW/amass.txt"
  fi

else
  log "SKIP: amass not installed."
fi

if have assetfinder; then
  log "Assetfinder passive enumeration..."
  assetfinder --subs-only "$DOMAIN" 2>/dev/null | normalize_scope > "$RAW/assetfinder.txt" || true
else log "SKIP: assetfinder not installed."; fi

if have findomain; then
  log "Findomain enumeration..."
  # stdout capture avoids relying on version-specific output-file behavior.
  findomain -t "$DOMAIN" -q 2>/dev/null | normalize_scope > "$RAW/findomain.txt" || true
else log "SKIP: findomain not installed."; fi

if have sublist3r; then
  log "Sublist3r passive enumeration..."
  SUBLIST3R_TMP="$RAW/sublist3r.unfiltered.txt"
  : > "$SUBLIST3R_TMP"
  if ! run_timeout 20m sublist3r -d "$DOMAIN" -o "$SUBLIST3R_TMP" >/dev/null 2>"$RAW/sublist3r.stderr.log"; then
    log "WARNING: Sublist3r failed/timed out; keeping any partial output."
  fi
  [[ -f "$SUBLIST3R_TMP" ]] && normalize_scope < "$SUBLIST3R_TMP" > "$RAW/sublist3r.txt"
else
  log "SKIP: sublist3r not installed."
fi

# crt.sh Certificate Transparency source
if have curl; then
  log "crt.sh Certificate Transparency enumeration..."
  if have jq; then
    curl -fsS --retry 2 --connect-timeout 15 --max-time 90 \
      "https://crt.sh/?q=%25.${DOMAIN}&output=json" \
      | jq -r '.[].name_value? // empty' 2>/dev/null \
      | tr '\r' '\n' | sed 's/\\n/\n/g' | normalize_scope > "$RAW/crtsh.txt" || true
  else
    log "SKIP: crt.sh JSON parsing requires jq."
  fi
else log "SKIP: curl not installed; cannot query crt.sh."; fi

cat "$RAW/subfinder.txt" "$RAW/amass.txt" "$RAW/assetfinder.txt" \
    "$RAW/findomain.txt" "$RAW/sublist3r.txt" "$RAW/crtsh.txt" 2>/dev/null \
  | normalize_scope > "$OUTDIR/passive_unique.txt"

log "Passive unique names: $(wc -l < "$OUTDIR/passive_unique.txt")"

# ---------------- ACTIVE ENUMERATION ----------------

if [[ "$ACTIVE" -eq 1 ]]; then
  if [[ -f "$WORDLIST" ]]; then
    if have gobuster; then
      log "Gobuster DNS brute force..."
      # --no-error reduces noise. Parse "Found:" output defensively.
      gobuster dns -d "$DOMAIN" -w "$WORDLIST" -t "$THREADS" --no-error 2>/dev/null \
        | tee "$RAW/gobuster_full.log" \
        | sed -nE 's/.*Found:[[:space:]]+([^[:space:]]+).*/\1/p' \
        | normalize_scope > "$RAW/gobuster.txt" || true
    else log "SKIP: gobuster not installed."; fi

    if have puredns; then
      log "PureDNS brute force with wildcard filtering..."
      PURE_ARGS=(bruteforce "$WORDLIST" "$DOMAIN" --write "$RAW/puredns.txt")
      [[ -n "$RESOLVERS" && -f "$RESOLVERS" ]] && PURE_ARGS+=(--resolvers "$RESOLVERS")
      puredns "${PURE_ARGS[@]}" >/dev/null 2>&1 || true
      [[ -f "$RAW/puredns.txt" ]] || : > "$RAW/puredns.txt"
    else log "SKIP: puredns not installed."; fi
  else
    log "SKIP: wordlist not found: $WORDLIST"
  fi

  # Seed permutations with all discoveries so far.
  cat "$OUTDIR/passive_unique.txt" "$RAW/gobuster.txt" "$RAW/puredns.txt" 2>/dev/null \
    | normalize_scope > "$OUTDIR/pre_permutation_unique.txt"

  if have alterx; then
    log "AlterX permutation generation..."
    # AlterX generates candidates; candidates are NOT trusted as existing until resolved.
    alterx -l "$OUTDIR/pre_permutation_unique.txt" -silent 2>/dev/null \
      | normalize_scope > "$RAW/alterx_candidates.txt" || true

    if have puredns && [[ -s "$RAW/alterx_candidates.txt" ]]; then
      log "Resolving AlterX candidates with PureDNS..."
      PURE_RESOLVE=(resolve "$RAW/alterx_candidates.txt" --write "$RAW/alterx_resolved.txt")
      [[ -n "$RESOLVERS" && -f "$RESOLVERS" ]] && PURE_RESOLVE+=(--resolvers "$RESOLVERS")
      puredns "${PURE_RESOLVE[@]}" >/dev/null 2>&1 || true
    elif have dnsx && [[ -s "$RAW/alterx_candidates.txt" ]]; then
      log "Resolving AlterX candidates with dnsx..."
      dnsx -l "$RAW/alterx_candidates.txt" -silent -o "$RAW/alterx_resolved.txt" 2>/dev/null || true
    fi
  else log "SKIP: alterx not installed."; fi

  # ffuf VHost discovery: useful where Host-header routing exposes names not in DNS.
  # We do not mix unverified ffuf names into DNS-existing inventory.
  if [[ "$RUN_FFUF" -eq 1 && -n "$BASE_URL" && -f "$WORDLIST" ]]; then
    if have ffuf && have jq; then
      log "ffuf VHost discovery against $BASE_URL ..."
      ffuf -w "$WORDLIST" -u "$BASE_URL" -H "Host: FUZZ.${DOMAIN}" \
        -ac -s -of json -o "$RAW/ffuf.json" 2>/dev/null || true
      if [[ -s "$RAW/ffuf.json" ]]; then
        jq -r '.results[]?.input.FUZZ // empty' "$RAW/ffuf.json" 2>/dev/null \
          | sed "s/$/.${DOMAIN}/" | normalize_scope > "$RAW/ffuf_vhosts.txt" || true
      fi
    else log "SKIP: ffuf VHost stage requires ffuf + jq."; fi
  elif [[ "$RUN_FFUF" -eq 1 ]]; then
    log "SKIP: ffuf VHost stage needs -u BASE_URL."
  fi
fi

# ---------------- DEDUPE + DNS VALIDATION ----------------

cat "$OUTDIR/passive_unique.txt" "$RAW/gobuster.txt" "$RAW/puredns.txt" \
    "$RAW/alterx_resolved.txt" 2>/dev/null \
  | normalize_scope > "$OUTDIR/all_candidates_unique.txt"

log "Unique candidates before final DNS validation: $(wc -l < "$OUTDIR/all_candidates_unique.txt")"

if have dnsx; then
  log "Final DNS validation with dnsx..."
  dnsx -l "$OUTDIR/all_candidates_unique.txt" -silent \
    -o "$OUTDIR/resolved_subdomains.txt" 2>/dev/null || true
  # dnsx plain output can include only hostnames in this mode; normalize again.
  normalize_scope < "$OUTDIR/resolved_subdomains.txt" > "$OUTDIR/.resolved.tmp"
  mv "$OUTDIR/.resolved.tmp" "$OUTDIR/resolved_subdomains.txt"

  log "Collecting DNS records..."
  dnsx -l "$OUTDIR/resolved_subdomains.txt" -silent -a -aaaa -cname -resp \
    > "$OUTDIR/dns_records.txt" 2>/dev/null || true
elif have puredns; then
  log "dnsx missing; using PureDNS for final validation..."
  PURE_FINAL=(resolve "$OUTDIR/all_candidates_unique.txt" --write "$OUTDIR/resolved_subdomains.txt")
  [[ -n "$RESOLVERS" && -f "$RESOLVERS" ]] && PURE_FINAL+=(--resolvers "$RESOLVERS")
  puredns "${PURE_FINAL[@]}" >/dev/null 2>&1 || true
  touch "$OUTDIR/dns_records.txt"
else
  log "WARNING: neither dnsx nor puredns installed; DNS existence cannot be reliably verified."
  cp "$OUTDIR/all_candidates_unique.txt" "$OUTDIR/resolved_subdomains.txt"
  touch "$OUTDIR/dns_records.txt"
fi

sort -u -o "$OUTDIR/resolved_subdomains.txt" "$OUTDIR/resolved_subdomains.txt"
log "DNS-existing unique subdomains: $(wc -l < "$OUTDIR/resolved_subdomains.txt")"

# ---------------- HTTP(S) LIVE CHECK + STATUS CODES ----------------

: > "$OUTDIR/live_urls.txt"
: > "$OUTDIR/live_with_status.txt"
: > "$OUTDIR/httpx.jsonl"

if have httpx; then
  log "Probing HTTP/HTTPS with httpx..."
  # JSONL is the canonical machine-readable output.
  httpx -l "$OUTDIR/resolved_subdomains.txt" -silent -status-code -title \
    -tech-detect -ip -cname -follow-redirects -json -o "$OUTDIR/httpx.jsonl" \
    2>/dev/null || true

  if have jq && [[ -s "$OUTDIR/httpx.jsonl" ]]; then
    jq -r 'select(.url != null) | .url' "$OUTDIR/httpx.jsonl" \
      | sort -u > "$OUTDIR/live_urls.txt"

    # TSV: URL, status code, title, IP, CNAME.
    jq -r '[
      (.url // ""),
      ((.status_code // "")|tostring),
      ((.title // "")|gsub("[\t\r\n]";" ")),
      ((.host_ip // .ip // "")|tostring),
      (if (.cname|type)=="array" then (.cname|join(",")) else ((.cname // "")|tostring) end)
    ] | @tsv' "$OUTDIR/httpx.jsonl" \
      | sort -u > "$OUTDIR/live_with_status.txt"
  else
    # Fallback if jq is absent: produce a human-readable status inventory.
    httpx -l "$OUTDIR/resolved_subdomains.txt" -silent -status-code \
      > "$OUTDIR/live_with_status.txt" 2>/dev/null || true
    awk '{print $1}' "$OUTDIR/live_with_status.txt" | sort -u > "$OUTDIR/live_urls.txt"
  fi
else
  log "SKIP: httpx not installed; no HTTP status/live-web inventory generated."
fi

# DNS-existing hosts that did not return an HTTP(S) response.
if [[ -s "$OUTDIR/live_urls.txt" ]]; then
  sed -E 's#^[a-zA-Z]+://##; s#/.*$##; s/:\d+$//' "$OUTDIR/live_urls.txt" \
    | sort -u > "$OUTDIR/.live_hosts.tmp"
  comm -23 "$OUTDIR/resolved_subdomains.txt" "$OUTDIR/.live_hosts.tmp" \
    > "$OUTDIR/dns_alive_but_no_http.txt" || true
  rm -f "$OUTDIR/.live_hosts.tmp"
else
  cp "$OUTDIR/resolved_subdomains.txt" "$OUTDIR/dns_alive_but_no_http.txt"
fi

# Keep ffuf findings separate because a VHost can exist without public DNS.
sort -u "$RAW/ffuf_vhosts.txt" -o "$RAW/ffuf_vhosts.txt" 2>/dev/null || true
cp "$RAW/ffuf_vhosts.txt" "$OUTDIR/vhost_candidates_ffuf.txt"

cat > "$OUTDIR/README-results.txt" <<EOF
Target: $DOMAIN

Key outputs:
  passive_unique.txt             Deduplicated passive discoveries
  all_candidates_unique.txt      Deduplicated candidates from all DNS-oriented stages
  resolved_subdomains.txt        DNS-existing/validated subdomains (main inventory)
  dns_records.txt                DNS record details when dnsx is available
  live_urls.txt                  HTTP/HTTPS-responsive URLs
  live_with_status.txt           URL + status code + title + IP + CNAME (TSV when jq exists)
  httpx.jsonl                    Full machine-readable HTTP probe results
  dns_alive_but_no_http.txt      DNS-existing names with no HTTP(S) response
  vhost_candidates_ffuf.txt      ffuf Host-header discoveries kept separate from DNS inventory
  raw/                           Per-tool raw/intermediate results

Important:
- "Existing subdomain" means DNS-resolvable after final validation.
- "Live domain" here means it responded over HTTP or HTTPS.
- A DNS-existing host may expose SSH, SMTP, VPN, or another non-web service and therefore
  legitimately appear in dns_alive_but_no_http.txt.
- VHost findings are separate because virtual hosts can exist without public DNS records.
EOF

log "Done."
printf '\nSummary\n'
printf '  DNS-existing subdomains : %s\n' "$(wc -l < "$OUTDIR/resolved_subdomains.txt")"
printf '  Live HTTP(S) URLs       : %s\n' "$(wc -l < "$OUTDIR/live_urls.txt")"
printf '  DNS alive / no HTTP     : %s\n' "$(wc -l < "$OUTDIR/dns_alive_but_no_http.txt")"
printf '  ffuf VHost candidates   : %s\n' "$(wc -l < "$OUTDIR/vhost_candidates_ffuf.txt")"
printf '  Results                 : %s\n' "$OUTDIR"
