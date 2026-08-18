# SSK Cargo

Flutter app for the SSK Cargo mobile experience.

## Layout

- `lib/` active application code
- `assets/` runtime images, icons, and bundled app media
- `docs/apis/` API notes and request/response references
- `docs/driver/` driver workflow, socket, and handoff notes
- `docs/reference/` product and feature reference docs
- `archive/legacy-web/` older React app snapshots kept for reference
- `archive/legacy-flutter/` older Flutter snapshot kept for reference
- `archive/artifacts/`, `archive/media/`, `archive/config-backups/` one-off files and backups

## Run

```bash
flutter pub get
flutter run
```

## Notes

- The archived folders are not part of the active app.
- Keep new product or API documentation in `docs/` instead of the root or `assets/`.
