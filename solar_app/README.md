# Sunward Solar — Flutter Android App (v0.0.2)

Dedicated Android mobile application for **Sunward Solar**, featuring the **Solar Calculator**, **Customer Leads CRM**, and **Profile with In-App Updater**.

---

## 📱 Features

1. **Solar Calculator (Tab 1)**:
   - Permanently visible Custom Rates (Hardware rate, Fitting & Labour, Inverter/Wiring charges, and Govt Subsidy).
   - Everyday simple terminology with clear cost and savings breakdowns.
   - Live mutual recalculation of Monthly Bill (₹) and Solar Capacity (kW).
   - Real-time return metrics: Aapka Final Kharcha, Saal Ki Bachat, and Paisa Vasool Time.
   - Free Site Survey & Quotation customer lead capture.

2. **Customer Leads (Tab 2)**:
   - Direct CRM pipeline to track and manage incoming customer inquiries.
   - Status tracking (`New`, `Contacted`, `Qualified`, `Site Visit`, `Quotation`, `Won`, `Lost`).
   - 1-tap Phone dialing (`tel:`) and direct WhatsApp chat launcher (`https://wa.me/`).
   - Manual lead entry for on-field customer intake.

3. **Profile & In-App Updater (Tab 3)**:
   - First-time user onboarding with name personalization.
   - In-app 1-click update checker that queries GitHub Releases directly.
   - Direct in-app APK download with live progress bar and automatic installation without opening external browsers.
   - Cryptographically signed with a consistent release keystore to eliminate update conflict issues.

---

## 📂 Project Structure

```
solar_app/
├── pubspec.yaml
├── sunward-release.jks                # Permanent release signing keystore
├── key.properties                     # Keystore signing properties
├── assets/
│   ├── logo.png                       # Official 3D solar app logo
│   └── icons/                         # Standard mipmap launcher icons
├── lib/
│   ├── main.dart                      # 3-tab navigation & onboarding gate
│   ├── models/
│   │   └── lead.dart                  # Lead data model
│   ├── services/
│   │   ├── lead_service.dart          # Local persistent lead CRM
│   │   └── update_service.dart        # GitHub release in-app downloader
│   ├── screens/
│   │   ├── calculator_screen.dart     # Solar ROI calculator & custom rates
│   │   ├── leads_screen.dart          # Customer inquiries & leads manager
│   │   └── profile_screen.dart        # User profile & in-app update check
│   └── theme/
│       └── app_theme.dart             # Sunward brand theme tokens
└── scripts/
    └── setup_android.py               # CI automation for icons, manifest & signing
```
