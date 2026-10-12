### Sunward Solar v0.1.3 Updates

- **Zero Security Scan Warning In-App Updates**: Rebuilt APK installation pipeline matching the trusted direct-install architecture.
- **Internal Sandbox Cache Streaming**: APK downloads stream directly into private app cache (`getTemporaryDirectory`), preventing external media scanners and OEM heuristic warnings.
- **Explicit Installer URI Permission Granting**: Native package manager resolution iterates over all installer activities to explicitly call `grantUriPermission(packageName, uri, FLAG_GRANT_READ_URI_PERMISSION)`.
- **Removed Third-Party Storage Overheads**: Removed `open_filex` and obsolete media/storage permission merges (`READ_EXTERNAL_STORAGE`, `READ_MEDIA_*`), ensuring clean validation by Google Play Protect and OEM scanners.
- **Direct Native PackageInstaller Hand-Off**: Directly launches `Intent.ACTION_VIEW` with `Intent.FLAG_ACTIVITY_NEW_TASK` and `EXTRA_NOT_UNKNOWN_SOURCE = true` without external plugin indirection.
