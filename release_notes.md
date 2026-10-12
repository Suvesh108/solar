### Sunward Solar v0.1.2 Updates

- **Smooth In-App APK Installation**: Upgraded native package installation pipeline with modern Android PackageInstaller flags (`EXTRA_NOT_UNKNOWN_SOURCE = true`, `EXTRA_INSTALLER_PACKAGE_NAME`).
- **One-Tap Permission Flow**: Added native Unknown Apps permission verification (`canRequestPackageInstalls`) with automatic redirection to system settings.
- **Enhanced APK Signing**: Enforced full V1 (JAR), V2 (APK signature scheme), V3, and V4 multi-scheme signing with standard PKCS12 release keystore for maximum Android OS security trust.
- **Removed High-Risk Permissions**: Stripped obsolete direct phone call and storage permissions, removing Play Protect and OEM security scanner flags.
- **Streamlined 4-Stage Lead Pipeline & Pure English UI**: High-speed lead tracker with 4 active stages (`New`, `Contacted`, `Quotation`, `Interested`) and dedicated "Not Interested" outcome disposition.
