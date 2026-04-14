---
name: ios-review-response
description: Handle App Store review rejections. Pulls rejection details, categorizes the issue, drafts Resolution Center responses or appeals, and prepares resubmission. Auto-invoked on rejection or manual.
allowed-tools: Bash(*) Read Write Edit Glob Grep
---

# App Review Response

Handle App Store review rejections and prepare resubmission.

## Trigger

- **Auto:** Invoked by `ios-submit` when a rejection is detected
- **Manual:** `/ios-review-response` to handle a rejection you discovered

## Process

### 1. Get Rejection Details

```bash
# Pull rejection info from App Store Connect
asc versions list --app-id $APP_ID --limit 1
asc reviews list --app-id $APP_ID
```

If `asc` can't retrieve rejection details, use computer-use MCP to:
1. Open App Store Connect in browser
2. Navigate to the app > App Review
3. Screenshot the rejection message
4. Extract the rejection reason and guideline references

### 2. Categorize the Rejection

**Metadata Rejection** (no new build needed):
- Screenshot issues (misleading, wrong device, missing)
- Description issues (inaccurate claims, keyword stuffing)
- Missing privacy information
- Incorrect age rating

→ Fix metadata, re-run relevant skill (`/ios-screenshots`, `/ios-store-listing`, `/ios-privacy`), resubmit

**Guideline Violation** (code changes needed):
- Design guideline violation (e.g., non-standard UI patterns)
- Privacy violation (data collection without consent)
- Performance issue (crashes, slow loading)
- Content policy violation

→ Identify specific code changes needed, link to dev cycle (`/ios-code-review`, `/ios-iterate`), rebuild and resubmit

**Bug / Crash** (code fix needed):
- Crash during review
- Feature not working as described
- Login issues with demo account

→ Pull crash logs if available, identify the bug, fix, test, rebuild, resubmit

### 3. Draft Resolution Center Response

Write a professional, factual response that:
- Acknowledges the reviewer's feedback
- Explains what was changed (if anything)
- Provides additional context if the rejection was a misunderstanding
- References specific Apple guidelines to support your case

**Tone guidelines:**
- Professional and respectful — never argumentative
- Factual — reference specific guideline numbers
- Concise — reviewers process many apps
- Helpful — make it easy for them to approve

### 4. Draft Appeal (if warranted)

If you believe the rejection is incorrect:
- Reference the specific guideline cited
- Explain how the app complies
- Provide screenshots or documentation as evidence
- Request re-review

**Only appeal if:**
- The rejection cites a guideline the app genuinely complies with
- There's a clear misunderstanding about app functionality
- The reviewer may not have tested with the demo account

**Do NOT appeal if:**
- The rejection is valid (fix the issue instead)
- The guideline is ambiguous (fix to be safe)

### 5. Prepare Resubmission

Create a resubmission checklist covering only what changed:

1. List specific changes made to address the rejection
2. Re-run only the relevant pre-submission checks
3. Update App Review notes to explain the changes
4. Reference the rejection in review notes so the new reviewer has context

### 6. Submit Response

Upload the Resolution Center response via `asc` or browser:

```bash
asc reviews respond --app-id $APP_ID --message "Response text..."
```

If resubmitting, hand off to `/ios-submit` with the updated build or metadata.
