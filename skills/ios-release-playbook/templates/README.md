# Templates

These are the release scripts from a shipped 1.0.0 app, made generic (app name `MyApp`, bundle id `com.example.myapp`). They have no secrets and no personal data: ids are
`<ASC_APP_ID>` / `<TEAM_ID>`, and contacts are `<…>` placeholders. Copy each file to the same path in the new repo,
then change what's listed here. Ruby scripts need only the standard library. Python scripts need Pillow and numpy.

| File | Change |
|---|---|
| `appstore/asc/asc_client.rb` | Nothing. It reads the credentials from the environment. It takes the app id from `ASC_APP_ID`, else from `app-info.json` › `app_id`, else looks it up by bundle id. |
| `appstore/asc/apply.rb`, `settings.rb`, `ready_check.rb`, `audit.rb`, `screenshots.rb`, `creative_assets.rb`, `previews.rb`, `testflight.rb`, `attach_build.rb` | Generic. Read each header comment. Change `ready_check.rb`'s list of expected display types (it requires the Watch set when there is a Watch app). |
| `appstore/asc/create_products.rb` | The lifetime/non-consumable review note text. |
| `appstore/asc/caps.rb` | The bundle ids and the capabilities each one needs. |
| `appstore/*.json`, `products.yml` | Everything. `listing.json` is a full worked example: copy its structure and its review-notes outline, and rewrite the words. |
| `fastlane/Fastfile` | `PROJECT`, `SCHEME_APP`, `APP_IDENTIFIER`, `TEAM_ID`, the `register_ids` specs, and the `MYAPP_SIM_DEST` env var name. |
| `scripts/bump-build.sh` | Nothing. It edits `CURRENT_PROJECT_VERSION` in `project.yml` and runs `xcodegen generate`. |
| `scripts/capture-appstore-screens.sh`, `capture-watch-screens.sh` | `BUNDLE_ID`, project and scheme, the `SHOTS` list (`slug|args`) and the `DEMO` arguments. |
| `scripts/compose-appstore-screenshots.py` | `CAPTIONS`, `ORDER`, colours and fonts. |
| `scripts/make-creative-assets.py` | The tagline, the shots used, colours. |
| `scripts/make-app-icon.py` | The art (`subject()`, `disc()`), `LOOKS` colours, output paths. Keep the `.icon` manifest writer and the preview sheet. |
| `scripts/sim-setup.sh` | Simulator names: keep the `Claude <App> …` prefix. |
| `App/LaunchOptions.swift` | The keys your app needs. Keep demo-only gating for entitlement previews. |
| `project-skill/SKILL.md` | Becomes `.claude/skills/<app>-roadmap/SKILL.md` in the app repo. |
