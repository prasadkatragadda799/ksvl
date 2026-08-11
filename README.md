# KSVL Naturals

Monorepo with **separate** Flutter apps so admin (mobile) and customer (web/PWA) builds never mix.

```
ksvl/
├── apps/
│   ├── admin_app/       # Store Manager — Android / iOS
│   └── customer_app/    # Customer storefront — Web / PWA
└── packages/
    └── ksvl_shared/     # Shared models, mock catalog, price helpers
```

## Run

**Admin (Mom’s Android app)**
```bash
cd apps/admin_app
flutter pub get
flutter run
# Release APK:
flutter build apk --release
```

**Customer (Web / PWA)**
```bash
cd apps/customer_app
flutter pub get
flutter run -d chrome
# Release web:
flutter build web --release
```

## Notes

- Always `cd` into the app you are building — each has its own `pubspec.yaml`, platforms, and build outputs.
- Shared product/order models live in `packages/ksvl_shared` and are linked via path dependency.
