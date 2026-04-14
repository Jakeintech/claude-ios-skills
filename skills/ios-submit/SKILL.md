---
name: ios-submit
description: Submit app for App Store review. Runs comprehensive pre-submission checklist, attaches build, uploads screenshots and metadata, submits, and monitors review status. Triggers ios-review-response on rejection.
disable-model-invocation: true
allowed-tools: Bash(*) Read Write Edit Glob Grep
---

# App Store Submission

Submit your app for App Store review with full pre-flight verification.

## Reference

Load the full checklist from [checklist.md](checklist.md) before starting.

## Process

### 1. Pre-Submission Verification

Run every check in checklist.md. For each:

**Build:**
```bash
# Verify build is uploaded and processed
asc builds list --app-id $APP_ID --limit 1
# Status must be "readyForSale" or "readyForBetaSubmission"
```

**Screenshots:**
```bash
# Verify screenshots directory has required device classes
ls screenshots/appstore/iphone-6.7/ | wc -l  # Must be 1-10
ls screenshots/appstore/ipad-13/ | wc -l      # If iPad supported
ls screenshots/appstore/watch-ultra/ | wc -l   # If watchOS supported
```

**Metadata:**
```bash
# Verify listing.json is complete
cat appstore/listing.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
required = ['name', 'subtitle', 'description', 'keywords', 'supportUrl', 'copyright', 'primaryCategory']
missing = [f for f in required if not data.get(f)]
if missing: print(f'FAIL: Missing fields: {missing}'); sys.exit(1)
print('PASS: All required fields present')
"
```

**Privacy:**
```bash
# Privacy manifest exists
find . -name "PrivacyInfo.xcprivacy" -not -path "./.git/*"

# Privacy labels submitted
test -f appstore/privacy-labels.json && echo "PASS" || echo "FAIL: Run /ios-privacy"
```

**URLs:**
```bash
# Support URL is reachable
curl -sI "$(cat appstore/listing.json | python3 -c 'import json,sys; print(json.load(sys.stdin).get("supportUrl",""))')" | head -1
```

### 2. Block on Failures

If ANY check fails:
1. List all failures with the specific fix needed
2. Suggest which skill to run (e.g., "Run /ios-screenshots for missing screenshots")
3. Do NOT proceed to submission
4. Re-run checks after fixes

### 3. Upload Media and Metadata

```bash
# Upload screenshots
asc screenshots upload --app-id $APP_ID --device "iphone-6.7" --dir screenshots/appstore/iphone-6.7/

# Upload metadata
asc versions update --app-id $APP_ID \
  --description "$(cat appstore/listing.json | python3 -c 'import json,sys; print(json.load(sys.stdin)["description"])')" \
  --keywords "$(cat appstore/listing.json | python3 -c 'import json,sys; print(json.load(sys.stdin)["keywords"])')"
```

For any upload that fails via `asc`, fall back to computer-use MCP to navigate App Store Connect in the browser and upload manually.

### 4. Submit for Review

```bash
asc versions submit --app-id $APP_ID
```

### 5. Monitor Review Status

```bash
# Check status
asc versions list --app-id $APP_ID --limit 1
```

Poll periodically or instruct user to check. Report status changes:
- **Waiting for Review** — submitted, in queue
- **In Review** — Apple is reviewing
- **Approved** — ready for release (manual or auto-release based on settings)
- **Rejected** — auto-invoke `ios-review-response`

### 6. Handle Rejection

If the app is rejected, automatically invoke the `ios-review-response` skill with the rejection details.
