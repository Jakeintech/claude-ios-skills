---
name: ios-site
description: Scaffold and deploy a GitHub Pages site for an iOS app — branded landing page plus neutral privacy, terms, and support pages. Derives content from brand book, privacy labels, and product config; pushes to a public GitHub repo with Pages enabled.
disable-model-invocation: true
allowed-tools: Bash(*) Read Write Edit Glob Grep Agent
argument-hint: "[init|update|plan] [--in-repo] [--domain DOMAIN]"
---

# iOS Marketing/Legal Site

Scaffolds a GitHub Pages site with four pages:

- `index.html` — branded landing (dark background, brand accent color)
- `privacy-policy.html` — neutral light styling, derived from `appstore/privacy-labels.json`
- `terms-of-service.html` — neutral, derived from `products.yml` + brand book
- `support.html` — neutral FAQ derived from brand book + key features

## Reference

Load `reference.md` before starting for `gh` CLI commands, Pages API, CNAME/DNS notes, and troubleshooting.

## Modes

- `init` — First-time scaffold: create local repo dir, generate content, create GitHub repo, push, enable Pages, write URLs back to `appstore/app-info.json`.
- `update` — Regenerate content in existing repo, commit + push only if changed.
- `plan` (default) — Show what would change, no writes or network mutations.

## Flags

- `--in-repo` — scaffold into `<project>/site/` instead of a sibling repo. Skips GitHub repo creation and Pages enablement; user manages deployment themselves.
- `--domain DOMAIN` — write a `CNAME` file and print DNS records to add at the user's registrar.

## Config Files

| File | Required | Source |
|---|---|---|
| `docs/product-vision/00-product-bounds.md` | Yes | `ios-prd` |
| `appstore/app-info.json` | Yes | manual |
| `appstore/privacy-labels.json` | Yes | `ios-privacy` |
| `appstore/age-rating.json` | Yes | `ios-privacy` |
| `appstore/products.yml` | Optional | `storekit-iac` (for ToS pricing) |
| `appstore/listing.json` | Optional | `ios-store-listing` (for landing hero reuse) |
| `appstore/review-notes.json` | Optional | `ios-privacy` (for support_email fallback) |
| `CLAUDE.md` | Yes | project |
| `site/site.config.json` | Optional | manual — see below |

### `site/site.config.json` (optional overrides)

```json
{
  "repo_name": "udana-site",
  "github_user": "jakeintech",
  "developer_name": "Jake Williams",
  "support_email": "info@jakeawilliams.com",
  "app_store_url": "https://apps.apple.com/app/id6762299975",
  "custom_domain": null,
  "faq_overrides": []
}
```

All fields optional. Missing fields are derived:
- `repo_name` default: `<slug(app-name)>-site`
- `github_user` default: `gh api user -q .login`
- `support_email` default: `review-notes.json.contactEmail`
- `app_store_url` default: `https://apps.apple.com/app/id{app_id}` from app-info.json

## Process

### 1. Validate

```bash
for f in "docs/product-vision/00-product-bounds.md" "appstore/app-info.json" "appstore/privacy-labels.json" "appstore/age-rating.json" "CLAUDE.md"; do
  test -f "$f" || { echo "MISSING: $f"; exit 1; }
done

# Check gh CLI for init mode
if [ "$MODE" = "init" ]; then
  gh auth status 2>&1 || { echo "gh CLI not authenticated. Run: gh auth login"; exit 1; }
fi
```

### 2. Resolve config

```python
import json, os, subprocess
from datetime import date

app_info = json.load(open("appstore/app-info.json"))
site_config = {}
if os.path.exists("site/site.config.json"):
    site_config = json.load(open("site/site.config.json"))

def slug(s):
    return "".join(c.lower() if c.isalnum() else "-" for c in s).strip("-")

repo_name = site_config.get("repo_name") or f"{slug(app_info['name'])}-site"

# GitHub user
gh_user = site_config.get("github_user")
if not gh_user:
    gh_user = subprocess.check_output(["gh", "api", "user", "-q", ".login"]).decode().strip()

# Support email
support_email = site_config.get("support_email")
if not support_email:
    try:
        rn = json.load(open("appstore/review-notes.json"))
        support_email = rn.get("contactEmail", "")
    except FileNotFoundError:
        support_email = ""
assert support_email, "support_email required — set in site.config.json or review-notes.json"

# App Store URL
app_store_url = site_config.get("app_store_url") or f"https://apps.apple.com/app/id{app_info['app_id']}"

# Developer name
developer = site_config.get("developer_name", "")

# Site URL
custom_domain = site_config.get("custom_domain")
site_url = f"https://{custom_domain}" if custom_domain else f"https://{gh_user}.github.io/{repo_name}"
```

### 3. Dispatch subagents in parallel

One message, two `Agent` calls:

- **brand-designer** per `agents/brand-designer.md` — pass brand_book, claude_md, listing (if exists), app_name, app_store_url. Returns `landing_content` JSON.
- **legal-writer** per `agents/legal-writer.md` — pass app_name, developer_name, support_email, privacy_labels, age_rating, products (if exists), claude_md, brand_book, last_updated. Returns `legal_content` JSON.

Retry any failed agent ONCE with stricter JSON-only prompt. Second failure → abort.

### 4. Render templates

For each template in `templates/`:

```python
import re
from datetime import date

def render(template_path, context):
    with open(template_path) as f:
        html = f.read()
    for key, value in context.items():
        html = html.replace("{{" + key + "}}", str(value))
    # Validate no leftover placeholders
    leftovers = re.findall(r"\{\{[^}]+\}\}", html)
    if leftovers:
        raise RuntimeError(f"Unresolved placeholders in {template_path}: {leftovers}")
    return html

# Build stats HTML
stats_html = "\n".join(
    f'<div class="stat"><div class="stat-number">{s["number"]}</div><div class="stat-label">{s["label"]}</div></div>'
    for s in landing["stats"]
)

# Build features HTML
features_html = "\n".join(
    f'<div class="feature"><h3>{f["title"]}</h3><p>{f["body"]}</p></div>'
    for f in landing["features"]
)

index_ctx = {
    "app_name": app_info["name"],
    "tagline": landing["tagline"],
    "meta_description": landing["meta_description"],
    "palette_bg": landing["palette"]["bg"],
    "palette_accent": landing["palette"]["accent"],
    "palette_muted": landing["palette"]["muted"],
    "palette_ink": landing["palette"]["ink"],
    "hero": landing["hero"],
    "stats_html": stats_html,
    "features_html": features_html,
    "cta_url": landing["cta"]["url"],
    "cta_text": landing["cta"]["text"],
    "year": date.today().year,
    "developer": developer,
}

today_str = date.today().strftime("%B %-d, %Y")

privacy_ctx = {
    "app_name": app_info["name"],
    "last_updated": today_str,
    "privacy_body_html": legal["privacy_body_html"],
}

terms_ctx = {
    "app_name": app_info["name"],
    "last_updated": today_str,
    "terms_body_html": legal["terms_body_html"],
}

support_ctx = {
    "app_name": app_info["name"],
    "faq_html": legal["faq_html"],
    "support_email": support_email,
}
```

Call `render()` for each template with its context.

### 5. Decide target directory

```python
if "--in-repo" in args:
    site_dir = "site"
else:
    site_dir = os.path.expanduser(f"~/Documents/GitHub/{repo_name}")
```

### 6. init mode

```bash
# Create dir
mkdir -p "$SITE_DIR"

# In non-empty existing dir: stop
if [ -n "$(ls -A "$SITE_DIR" 2>/dev/null)" ]; then
  echo "ERROR: $SITE_DIR exists and is non-empty"
  exit 1
fi

# Write rendered files (each HTML file from step 4)

# Write CNAME if custom_domain
if [ -n "$CUSTOM_DOMAIN" ]; then
  echo "$CUSTOM_DOMAIN" > "$SITE_DIR/CNAME"
fi

# Git init + first commit
cd "$SITE_DIR"
git init -b main
git add .
git commit -m "chore: initial site scaffold"

# Create GitHub repo (skip with --in-repo)
if [ "$IN_REPO" = "false" ]; then
  gh repo create "$REPO_NAME" --public --source=. --push

  # Enable Pages
  gh api -X POST "/repos/$GH_USER/$REPO_NAME/pages" \
    -f "source[branch]=main" \
    -f "source[path]=/" || true  # 422 means already enabled

  # Poll until built (5 min timeout)
  DEADLINE=$(($(date +%s) + 300))
  STATUS="null"
  while [ "$(date +%s)" -lt "$DEADLINE" ]; do
    STATUS=$(gh api "/repos/$GH_USER/$REPO_NAME/pages" -q .status 2>/dev/null || echo "null")
    if [ "$STATUS" = "built" ]; then break; fi
    sleep 10
  done

  if [ "$STATUS" != "built" ]; then
    echo "⚠ Pages build did not complete within 5min — check https://github.com/$GH_USER/$REPO_NAME/settings/pages"
    SKIP_URL_WRITEBACK=true
  fi
fi
```

### 7. Write URLs back to app-info.json (init mode only)

```python
if mode == "init" and not skip_url_writeback and not in_repo:
    app_info_path = "appstore/app-info.json"
    info = json.load(open(app_info_path))

    new_marketing = site_url + "/"
    new_support = site_url + "/support.html"

    # Confirm on conflict
    if info.get("marketing_url") and info["marketing_url"] != new_marketing:
        print(f"marketing_url exists: {info['marketing_url']}")
        print(f"would overwrite with: {new_marketing}")
        confirm = input("Overwrite? [y/N] ").strip().lower()
        if confirm != "y":
            return

    info["marketing_url"] = new_marketing
    info["support_url"] = new_support
    with open(app_info_path, "w") as f:
        json.dump(info, f, indent=2)
```

### 8. update mode

Run steps 1-4 with existing site dir. Then:

```bash
cd "$SITE_DIR"
git pull --rebase origin main || true

# Write rendered files

# Commit only if changed
if git diff --quiet && git diff --cached --quiet; then
  echo "No changes."
  exit 0
fi

git add .
git commit -m "chore(site): regenerate from brand book"
git push
```

### 9. plan mode

Run steps 1-4. Don't write anything. Print a diff-style summary of what would change:
- Which files would be created/modified in the site dir
- Whether `app-info.json` would be updated
- Whether the repo would be created

### 10. Report

```
ios-site — init complete
────────────────────────
Repo:    https://github.com/{gh_user}/{repo_name}
Pages:   {site_url}/
Support: {site_url}/support.html

Written to appstore/app-info.json:
  marketing_url = {site_url}/
  support_url   = {site_url}/support.html

Next:
  /ios-store-listing  — generate listing.json using the new URLs
  /appstore-iac plan  — preview the full App Store sync
```

## Safety

1. **Default is plan mode** (unless explicit `init` or `update`).
2. **Never force-push.** Repo name conflicts stop and ask.
3. **Validate templates after render** — no leftover `{{...}}` tokens.
4. **`--in-repo` target must be empty** if creating fresh.
5. **No secrets in site.config.json** — documented in reference.md.
6. **Self-healing.** On any gh API failure, fix and update `reference.md` in the same run.
