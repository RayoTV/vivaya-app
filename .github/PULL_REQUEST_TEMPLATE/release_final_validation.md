<!-- PR Title -->

# ✨ Final Global Validation — Smart Fix + Test Ready for VIVAYA ✨

## Arabic

تم التحقق من جميع ملفات البيانات (الوجبات – التمارين – الإشعارات – الترجمات – القواعد)

- ✅ جميع الملفات صالحة ومضغوطة (<300KB)
- ✅ لا تكرار في المعرّفات
- ✅ تمت إضافة اختبارات سلامة ذكية
- ✅ التطبيق جاهز للإطلاق العالمي

## English

All data JSONs (meals, workouts, notifications, translations, rules) validated successfully.

- ✅ All <300 KB and schema-safe
- ✅ IDs unique, tags/allergens normalized
- ✅ Added smart validation tests
- ✅ Ready for global release

### Notes

- This PR contains only additive changes and small type/value fixes to ensure data integrity. No existing JSON keys were removed or renamed.
- CI requires repository secrets for native Firebase config: `ANDROID_GOOGLE_SERVICES_JSON` (base64) and optionally `IOS_GOOGLE_SERVICE_INFO_PLIST`.

Please run CI and review before merging.
