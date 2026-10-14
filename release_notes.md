### Sunward Solar v0.1.5 Updates

- **Fixed Missing Internet Permission Bug**: Resolved root cause in CI build generator (`setup_android.py`) ensuring `android.permission.INTERNET`, `ACCESS_NETWORK_STATE`, and `REQUEST_INSTALL_PACKAGES` are always properly injected into `AndroidManifest.xml` during automated build steps.
- **Native Kotlin Update Engine**: Pure Kotlin update engine (`AppUpdater.kt`) querying GitHub releases, dynamically checking installed package versions, background downloading with stream progress, and native package installer launching.
- **Polished Profile UI & Error Handling**: Replaced raw platform exception dumps with human-friendly network error notifications and clean version tracking.
