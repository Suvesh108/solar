### Sunward Solar v0.1.4 Updates

- **Native Kotlin Update Engine**: Built a pure Kotlin update engine (`AppUpdater.kt`) handling GitHub release querying, dynamic installed package version inspection, background downloading with HTTP redirect handling, live stream progress reporting, and native system package installer triggering.
- **Interactive Update Popup Modal**: Integrated popup dialog displaying release notes and live progress tracking with direct "Update Now" and "Later" options.
- **Android 11+ & 14+ Compatibility**: Added explicit package archive intent filters to `<queries>` and FileProvider URI grant permissions for all resolving package installer activities.
- **Automated CI/CD Workflow**: Replaced hardcoded version release with dynamic tag-triggered GitHub release automation.
