# __APP_NAME__ SDLC Workflow

## Branch Strategy

```
main (production)
 └── dev (integration)
      ├── epic/01-name
      ├── epic/02-name
      └── ...
```

## Rules

1. **Epic branches** created off `dev`, merge back via reviewed PR
2. **Each epic** must pass full test suite before merge to `dev`
3. **Code review** required before every epic→dev merge
4. **dev→main** merge only after full regression passes

## Quality Gates

- No merge without green build (`xcodebuild build`)
- No merge without passing tests (`xcodebuild test`)
- No merge without code review
- No merge without accessibility check on new UI
- Every new feature has unit tests
- Every UI change verified in simulator

## Per-Epic Pipeline

```
[Implementation]
    ↓ writes code on epic/XX branch
[Build Verification]
    ↓ xcodebuild build + test
[Code Review]
    ↓ ios-code-review skill
[Design Review]
    ↓ ios-design-review skill
[Fix Findings]
    ↓ address all issues
[Final Build + Test]
    ↓ clean build, full test suite
[Merge to dev]
```
