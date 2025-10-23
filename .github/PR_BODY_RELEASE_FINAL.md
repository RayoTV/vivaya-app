# PR Validation Summary

Arabic:
✅ تم التحقق من جميع ملفات البيانات (الوجبات/التمارين/الإشعارات/الترجمات/القواعد)
✅ جميع الملفات < 300 KB وبتنسيق UTF-8
✅ لا يوجد تكرار للمعرّفات
✅ الوجبات لكل هدف ≥ 10/10/10/8/8
✅ التمارين ≥ 24
✅ الإشعارات 5 لكل فئة باللغتين
✅ يحتوي program_rules.json على filters و unit_settings
✅ `dart run test/data_integrity_test.dart` → All JSON assets valid and ready.
ملاحظة: تم تطبيق تنسيقات طفيفة فقط، بدون كسر للسكيمات.

English:
✅ All data JSONs validated (meals/workouts/notifications/translations/rules)
✅ All < 300 KB, UTF-8, schema-safe
✅ IDs unique across meals
✅ Meals ≥ 10/10/10/8/8 (B/L/D/S/Drink)
✅ Exercises ≥ 24
✅ Notifications ≥ 5 per category (AR/EN)
✅ program_rules.json includes filters & unit_settings
✅ `dart run test/data_integrity_test.dart` → All JSON assets valid and ready.
Note: Minor non-schema fixes (format/value) already applied.
