
# PR creation and release helper (run locally)

Prerequisite: set an environment variable GITHUB_TOKEN with a personal access token that has repo permissions.

## Create the PR (replace OWNER/REPO if needed)

```bash
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/RayoTV/vivaya-app/pulls" \
  -d '{
    "title":"✨ Final Global Validation — fixes & self-tests for VIVAYA ✨",
    "head":"release/final-validation",
    "base":"main",
    "body":"Arabic:\n✅ تم التحقق من جميع ملفات البيانات (الوجبات/التمارين/الإشعارات/الترجمات/القواعد)\n✅ جميع الملفات < 300 KB وبتنسيق UTF-8\n✅ لا يوجد تكرار للمعرّفات\n✅ الوجبات لكل هدف ≥ 10/10/10/8/8\n✅ التمارين ≥ 24\n✅ الإشعارات 5 لكل فئة باللغتين\n✅ يحتوي program_rules.json على filters و unit_settings\n✅ `dart run test/data_integrity_test.dart` → All JSON assets valid and ready.\nملاحظة: تم تطبيق تنسيقات طفيفة فقط، بدون كسر للسكيمات.\n\nEnglish:\n✅ All data JSONs validated (meals/workouts/notifications/translations/rules)\n✅ All < 300 KB, UTF-8, schema-safe\n✅ IDs unique across meals\n✅ Meals ≥ 10/10/10/8/8 (B/L/D/S/Drink)\n✅ Exercises ≥ 24\n✅ Notifications ≥ 5 per category (AR/EN)\n✅ program_rules.json includes filters & unit_settings\n✅ `dart run test/data_integrity_test.dart` → All JSON assets valid and ready.\nNote: Minor non-schema fixes (format/value) already applied."
  }'
```

## Add the short CI comment to the PR (replace PR_NUMBER)

```bash
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/RayoTV/vivaya-app/issues/PR_NUMBER/comments" \
  -d '{"body":"CI note: data-only branch, safe to merge after checks ✅"}'
```

## Merge the PR after CI passes (replace PR_NUMBER)

```bash
curl -s -X PUT \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/RayoTV/vivaya-app/pulls/PR_NUMBER/merge" \
  -d '{"merge_method":"squash","commit_title":"chore: merge release/final-validation","commit_message":"Validated data assets and tests"}'
```

## Create a release and tag (after merge)

```bash
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/RayoTV/vivaya-app/releases" \
  -d '{"tag_name":"v1.0.0-data-ready","name":"VIVAYA Data & Validation","body":"All JSON assets validated, UTF-8 safe, global-ready, offline capable.","draft":false,"prerelease":false}'
```

Notes:

- Replace PR_NUMBER with the PR id returned when creating the PR.
- You can run these commands from a local machine with the repo cloned and GITHUB_TOKEN exported.
