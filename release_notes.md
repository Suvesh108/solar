### Sunward Solar v0.1.4 Updates

- **Settlr-Grade In-App Update Engine**: Rebuilt update pipeline with dedicated `com.sunward.updater` native MethodChannel and live streaming progress reporting received vs total megabytes.
- **Interactive Update Popup Modal**: Integrated popup dialog displaying release notes and live progress tracking with direct "Update Now" and "Later" options.
- **Android 11+ Package Visibility**: Added explicit package archive intent filters to `<queries>` in AndroidManifest.xml for full compatibility with native system package installers.
- **Automated Tag-Based CI/CD Workflow**: Replaced hardcoded version release with dynamic tag-triggered GitHub release automation.
