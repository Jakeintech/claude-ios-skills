---
name: ios-release-playbook
description: Use when taking an iOS app from "features done" to "owner only has to press Submit" — App Store Connect as code, bundle ids, build numbers and TestFlight, screenshots and creative assets, the Icon Composer icon, review notes, paywall honesty, and the owner-only checklist. Also use at the START of a new app, to set up the demo-mode launch arguments, the project roadmap skill and the release scripts on day one so release week is mechanical. Holds battle-tested templates (Ruby ASC client, fastlane lanes, capture/compose scripts, icon generator) and the lessons from shipping a 1.0.0.
allowed-tools: Bash(*) Read Write Edit Glob Grep Agent
argument-hint: "[setup|release|checklist]"
---

# iOS release playbook

The order of work and the lessons that made a real 1.0.0 release mechanical. The scripts in
`templates/` are copies of the ones that shipped. Copy them into the new repo and change the constants
listed in `templates/README.md`. Where this overlaps the narrower skills (`appstore-iac`, `storekit-iac`,
`ios-screenshots`, `ios-app-icon`, `ios-testflight`, `ios-submit`, `ios-privacy`, `ios-site`,
`ios-store-listing`), use them for depth. **Where they disagree, this playbook wins: it records what
actually worked against the live API.**

Modes:
- `setup`: day-one work for a new app (§1).
- `release`: run §2–§8 in order.
- `checklist`: print §9 for the owner.

## Hard rules (every app)

- **Never submit for review.** Claude prepares everything; the owner presses Submit.
- **Dry-run first.** Every write to App Store Connect runs with `--dry-run`, Claude reads the diff, then applies.
- **Credentials come from the environment only.** `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY_PATH`, or the `APP_STORE_CONNECT_API_KEY_*` trio. Never commit them or echo them.
- **The owner's identity stays private.** Their name, email and phone live only in the app's private repo (`appstore/listing.json` › reviewDetail), never in public repos, skills or outside requests.
- **Use the release toolchain.** Every build, archive or upload starts with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`. A beta-built binary is rejected.
- **Use Claude's own simulators.** Create them with names like `Claude <App> iPhone 18 Pro Max` and pass `id=<UDID>` destinations. The owner's simulators are theirs.
- **Before calling anything done, run it and read the output.** For screenshots that means opening the composed PNGs. For ASC it means re-reading live state (`ready_check.rb`).

## 1. Day one: set up what release week needs

These cost an hour at the start and save days at the end.

1. **Demo mode via launch arguments** (`templates/App/LaunchOptions.swift`):
   - Arguments: `-demo 1 -now <ISO8601> -tab <tab> -screen <route> -state loading|empty|error|offline|unavailable`, plus app-specific extras (`-redNight 1`, `-pro 1`, `-layers a,b`, `-minute <ISO>`).
   - `-pro` and other entitlement previews are honoured **only in demo**. Pin them so the StoreKit refresh can't undo them.
   - `UserDefaults` reads the **first** occurrence of a key. A capture script puts each shot's arguments **before** the shared demo arguments.
   - Why: simulator tapping (idb / SimulatorKit) is broken on Xcode 27.2, so every screen and state must be reachable without taps. This is also how screenshots, design comparisons and App Review's "how to test" work.
2. **Deterministic time and data.** The app takes `now` and fixtures from demo mode. Numbers on screen come from the real engine, never typed into views, so screenshots are true.
3. **A project roadmap skill** (`templates/project-skill/SKILL.md`), plus `STATUS.md` and `DECISIONS.md`. A new session (or a compacted one) resumes from them. Point the project `CLAUDE.md` at the skill. Keep its Roadmap current after every step.
4. **App Store as code** from the first ASC contact: `appstore/*.json` plus `products.yml` are the source of truth (§3).
5. **Versioning**: semver `MARKETING_VERSION` (1.0.0 → 1.0.1 → 1.1.0) in `project.yml`, equal to `listing.json` › version.versionString. `CURRENT_PROJECT_VERSION` is the one build number every target reads (`scripts/bump-build.sh`).
6. **Every target's bundle id** goes in the `register_ids` lane at the moment the target is added (widgets, watch app, watch widgets), not at upload time.

## 2. Truth pass: the app sells only what ships

App Review 2.1 / 3.1 and refunds hit apps whose paywall promises more than they deliver.

- **One list of paid features**, in code (`PaywallCopy.features`), pinned by a test (`testFeatures_onlyWhatShips`). The listing description, IAP review notes, review notes, website and TestFlight "What to test" all copy that list word for word. A feature that slips comes out of all of them in the same commit and moves to the next patch version.
- **Sweep for dead buttons**: grep for empty actions, `TODO`, placeholder `Button("…") {}`. Each one is either built or removed.
- **Remove unused usage descriptions.** `PhotosPicker` runs out of process, so `NSPhotoLibraryUsageDescription` isn't needed. Unused purpose strings draw questions.
- **Review notes are a script for the reviewer** (template in `appstore/listing.json`):
  - no login or backend;
  - HOW TO TEST in 5 numbered steps;
  - one paragraph per permission, naming where it is asked;
  - Live Activity and widgets: how to start them;
  - DATA SOURCES (every outside service and what is sent);
  - IN-APP PURCHASES: the same list as the paywall, where the paywall opens, where Restore is;
  - "AR / camera needs a real device".

  Correct every claim against the code: a first draft once said a Live Activity starts on its own, and it didn't.

## 3. App Store Connect as code (`templates/appstore/`)

| File | What it drives |
|---|---|
| `listing.json` | name, subtitle, keywords, promo, description, URLs, copyright, review detail and notes, age rating, subscription group, TestFlight info |
| `products.yml` | IAPs and subscriptions (`create_products.rb`, also patches review notes that differ) |
| `app-info.json` | ids, URLs, categories |
| `privacy-labels.json`, `export-compliance.json`, `age-rating.json` | as named |

Order:
1. `ruby asc/audit.rb` — dump live state, read-only.
2. `ruby asc/apply.rb --dry-run`, then apply. Then `ruby asc/settings.rb --dry-run`, then apply.
3. `ruby asc/create_products.rb --dry-run`, then apply.
4. Screenshots (§5).
5. `ruby asc/ready_check.rb` — every line must be green.

What the API sets (and apply.rb does):
- contentRights (`USES_THIRD_PARTY_CONTENT` when you show maps, weather or terrain);
- the version string;
- a 16-day billing grace period;
- accessibility declarations as **drafts**, which can only be **published after the app is live**;
- the IAP review note.

What the API **can't** do. These go on the owner checklist (§9):
- Ticking the IAPs on the version page for the **first** submission with IAPs.
- Unticking Mac (Apple silicon) and Apple Vision Pro availability.
- Enabling **WeatherKit** (and other App Services) for the bundle id in the developer portal. Without it the build shows "forecast didn't load" on TestFlight even though the entitlement is in place.
- The App Group itself is created by Xcode automatic signing on the first archive.

Age rating: after a full patch, `kidsAgeBand`, `socialMediaAgeRestricted`, `gracRatingClassificationNumber` and `developerAgeRatingInfoUrl` stay `nil`. They are optional follow-ups; don't chase them.

Name and keywords:
- Name and subtitle are 30 characters each. Keywords are 100 characters, comma-separated with no spaces.
- Never repeat a word that is already in the name or subtitle. Apple indexes those already.
- Keep the brand word plus a descriptive phrase ("Brand: What It Does").
- Don't rebrand late: a name change ripples into the icon, site, screenshots and copy, for little search gain.

## 4. Bundle ids, build numbers, TestFlight (`templates/fastlane/Fastfile`, `templates/scripts/bump-build.sh`)

1. `fastlane register_ids` registers every target, including `.watchkitapp` and `.watchkitapp.widgets`, and adds missing capabilities. `asc/caps.rb` compares those capabilities read-only.
2. **Build numbers only go up, per version, forever.** ASC remembers every upload, even failed or expired ones. Run `ruby asc/testflight.rb` (or check the builds list) and take the highest number plus 1.
3. `scripts/bump-build.sh`, commit, then push. `fastlane beta` archives the *committed* number and tags `v<version>-build<N>`.
4. Run beta:

   ```
   DEVELOPER_DIR=… FASTLANE_SKIP_UPDATE_CHECK=1 <APP>_SIM_DEST='platform=iOS Simulator,id=<Claude UDID>' fastlane beta
   ```

   - The lane runs the full test suite as a gate, then archives and uploads.
   - Run it in the background; it takes 10–20 minutes.
   - Don't commit during the run, so the tag lands on the build commit.
5. Read fastlane output with `grep -E "exists|registered|error|Error|uploaded|finished"`. It prints an update banner last, so `tail` hides the result.
6. After processing, `ruby asc/attach_build.rb <N> --dry-run`, then without (it picks the highest VALID build of the
   listing's version if N is omitted). Then `ruby asc/testflight.rb --dry-run`, then apply, so What to Test is filled for that build.
   Then `ruby asc/ready_check.rb`, which must end `READY: only Submit for Review remains`, and look at the `build-icon.png` it saves.
7. StoreKit purchase tests can stall on a brand-new simulator behind the "Sign in to Apple Account" sheet. Rerun them, or skip that one suite with a note in STATUS.

## 5. Screenshots and creative assets (`templates/scripts/`)

1. **Capture** with `capture-appstore-screens.sh`:
   - It builds once, then for each shot `simctl launch <udid> <bundle> <shot args> <DEMO args>` and `simctl io screenshot`.
   - Set `simctl status_bar override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3` first.
   - Devices: a Claude-owned **iPhone Pro Max** (6.9"/6.7" set, 1320×2868) and **iPad Pro 13"** (2048×2732).
   - A full run deletes the old raw PNGs so renamed shots don't linger.
2. **Watch** with `capture-watch-screens.sh`: 416×496 for `APP_WATCH_SERIES_10`. The watch status bar clock can't be overridden; accept the Mac's time.
3. **Compose** with `compose-appstore-screenshots.py`:
   - The caption is a headline plus a subline, written per screen, saying what *that* screen proves.
   - The **iPad status bar shows today's weekday whatever the override**, so the script crops the top 48 px.
4. **What sells, in order:**
   - Lead with the outcome screen (the result list, then the detail that answers the question), not the home screen.
   - Then the daily-use screen, the signature input, the "wow" view, the accessibility/night mode, the tools.
   - Drop any shot that shows "sample" or "demo" labels or an invisible state (an "offline" shot that looks online).
5. **Open the composed PNGs and look at them.** Check for clipped titles under the tab bar, guide lines crossing labels, and a wrong date.
6. Upload: `ruby asc/screenshots.rb appstore/screenshots/final --dry-run`, then for real. It replaces each display-type set whole and creates new sets (Watch). It must print `states COMPLETE` for every set.
7. **Creative assets**, optional but cheap:
   - `make-creative-assets.py` makes the product page header (3840×1646) and the search card (3840×2560) from the raw shots plus the icon.
   - Place them with `ruby asc/creative_assets.rb place PRODUCT_PAGE_HEADER_ASSET <png> --dry-run`, then for real; the same for `APP_STORE_SEARCH_RESULTS_ASSET`.
   - **Re-place them whenever the icon or screenshots change.** They embed both.

## 6. App icon (`templates/scripts/make-app-icon.py`)

- Generate the **Icon Composer bundle** in code, not by hand:
  - The script writes `Resources/AppIcon.icon/` with `icon.json` (one group; layers background / art / foreground; `image-name-specializations` for default / `dark` / `tinted`; `"supported-platforms": {"circles": ["watchOS"], "squares": "shared"}`) and the layer PNGs in `Assets/`.
  - xcodegen picks up a `.icon` in Resources automatically. Verify with `assetutil --info` on the built `Assets.car`: there should be IconImageStack renditions for Light, Dark and Tintable.
- Also write flat fallbacks (`AppIcon.appiconset` PNGs) and the Watch `AppIcon.png` from the same art.
- Draw at 4× and downsample. Write a **preview sheet** with the three looks at 520 px and at Home Screen sizes (180 / 120 / 58), then look at it. Detail that vanishes at 58 px goes.
- **Family style**: when the owner has other apps, open their icons first and match the weight: bold, few rounded shapes, one accent colour on a dark gradient. The owner asked for exactly this.
- Dark look: the foreground must never be lighter than the sky. Tinted: grayscale values only.

## 7. Website (privacy, support, terms)

Use `ios-site`. Keep the site's Pro list, data-sources rows (each outside service and what's sent) and footer credits in step with §2's single list. Rebuild and push the site repo in the same session as the copy change.

## 8. Working with agents

- Large features (a Watch app, a data source) go to background agents in **worktrees on their own branches**. They commit there and **never push or merge**.
- The main session reviews against the design source, runs the full tests, merges, resolves conflicts, pushes, then runs `git worktree remove`.
- Expect conflicts in `STATUS.md`, `DECISIONS.md` and shared launch-option code. When two agents both add the same flag, keep one.
- For a second opinion, use Codex read-only: `codex exec -s read-only -C <dir> -o <file> "<prompt>" < /dev/null`. Without `< /dev/null` it hangs. Verify each finding before acting on it.

## 9. Owner-only checklist (say it plainly at the end)

1. Version page → In-App Purchases and Subscriptions: **tick each IAP** (first submission only).
2. Developer portal → Identifiers → the app id → App Services: **enable WeatherKit** (and any other App Service the app uses).
3. Pricing and Availability: **untick Mac and Apple Vision Pro** unless wanted.
4. Check the attached build and the screenshots once in the web UI.
5. Press **Submit for Review**.
6. After release: **publish the accessibility declarations** (the drafts already exist), and tag the release commit.

## 10. Lessons that cost time (don't repeat)

- Simulator UI automation is unavailable on Xcode 27.2, so plan every state behind launch arguments (§1).
- `simctl status_bar override --time` accepts only `…T…:00.000Z` ISO or `9:41`, and the iPad ignores the date part. Crop instead.
- A bounding-box "erase the old icon" step on a marketing image wiped the headline. Restore with git and paint a fixed rectangle. Always look at generated images.
- Duplicate error banners appear when two layers fail for the same cause (terrain). Show the root banner only; one Retry resets every dependent layer.
- ASC accepts a screenshot set only when every image is `COMPLETE`. A failed upload leaves a half-set, so re-run the replace.
- Agents' worktrees can stay locked by a dead pid. Leave them and remove them later, rather than forcing a removal mid-session.
