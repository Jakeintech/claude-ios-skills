# ios-site Reference

GitHub CLI, Pages API, DNS, and troubleshooting notes. Self-heal by adding to this file when something goes wrong.

## `gh` CLI basics

```bash
# Verify auth
gh auth status

# Login (user must run this themselves, not Claude)
gh auth login

# Current user
gh api user -q .login
```

If `gh` is not installed: `brew install gh`.

## Creating the repo

```bash
# Create and push in one step
gh repo create <name> --public --source=. --push

# If repo already exists on GitHub:
#   - Pull it first: git clone <url>
#   - Or pick a different name
# Never force-push to an existing repo.
```

## Enabling GitHub Pages

```bash
# Pages API — enable Pages with main branch source
gh api -X POST "/repos/<owner>/<repo>/pages" \
  -f "source[branch]=main" \
  -f "source[path]=/"

# Check Pages status
gh api "/repos/<owner>/<repo>/pages"
# Fields of interest:
#   .status        — "building" | "built" | "errored"
#   .html_url      — the live Pages URL
#   .cname         — custom domain if set
```

### Known quirks

- The `POST /pages` endpoint returns `422` if Pages is already enabled. Treat 422 as success; fetch status with a subsequent GET.
- The `status` field is `null` for the first ~10-30 seconds after enablement. Keep polling.
- Private repos require GitHub Pro for Pages; always create `--public`.

## Custom domain (CNAME)

```bash
# Set custom domain via API
gh api -X PUT "/repos/<owner>/<repo>/pages" \
  -f "cname=udana.app"

# Also commit a CNAME file to the repo root containing just the domain:
echo "udana.app" > CNAME
git add CNAME && git commit -m "chore: add CNAME" && git push
```

### DNS records to add at registrar

For apex domain (`udana.app`):
```
A    @   185.199.108.153
A    @   185.199.109.153
A    @   185.199.110.153
A    @   185.199.111.153
```

For subdomain (`www.udana.app`):
```
CNAME   www   <owner>.github.io
```

HTTPS certificate provisioning takes 15-60 minutes after DNS propagates.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `gh: command not found` | `brew install gh` |
| `gh auth status` fails | Tell user to run `gh auth login` — don't attempt yourself |
| `POST /pages` returns 404 | The repo was created but not yet visible to the API; retry after 2 sec |
| `POST /pages` returns 422 | Pages already enabled; proceed |
| `status` stuck on `building` > 5 min | Check repo Actions tab for build errors; skip write-back and tell user |
| Pages returns 404 at live URL | First build can take 10 min; user should refresh |
| CNAME set but HTTPS fails | DNS not propagated yet; wait up to 1 hour |
| `git push` rejected | Someone else pushed; `git pull --rebase` then retry |

## Self-healing additions

When the skill hits an unexpected `gh` error during a real run, add the error and fix here.
