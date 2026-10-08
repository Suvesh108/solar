# Sunward Solar — Flutter Android App

Dedicated Android mobile application for **Sunward Solar**, containing only the **Solar ROI Calculator** and **Admin Lead Inbox Dashboard**.

---

## 📱 Features

1. **Solar ROI & Capacity Calculator (Tab 1)**:
   - Monthly electricity bill & required kW inputs with live mutual recalculation.
   - Quick kW presets (1kW, 2kW, 3kW, 5kW, 10kW, 15kW).
   - Property selector (House, Shop, Office, Factory).
   - Custom rate overrides (Tariff ₹/kWh, Cost ₹/kW, Government Subsidy ₹).
   - Real-time Metrics:
     - Net Investment Cost (after subsidy)
     - Annual & Monthly electricity savings
     - 25-Year profit & lifetime ROI %
     - Payback period in years
     - Technical & Environmental specs: Required 540W solar panels count, rooftop area (sq. ft.), CO₂ saved (kg/year), and tree offsets.
   - Lead Capture: Book Free Site Survey button saves directly to the local Lead CRM and forwards to the Admin Box.

2. **Admin Lead Box & CRM (Tab 2)**:
   - Direct access to leads pipeline and CRM.
   - Summary statistics bar (Total inquiries, New pending, Won deals).
   - Instant search by customer name, phone, or location.
   - Status filter chips (All, New, Contacted, Qualified, Site Visit, Quotation, Won, Lost).
   - Pipeline status updater badge.
   - One-tap phone dialer (`tel:`) and direct WhatsApp chat launcher (`https://wa.me/`).
   - Manual lead entry floating action button.

---

## 📂 Project Structure

```
solar_app/
├── pubspec.yaml
├── README.md
├── lib/
│   ├── main.dart                      # Bottom navigation bar & app entry
│   ├── models/
│   │   └── lead.dart                  # Lead data model & JSON serialization
│   ├── services/
│   │   └── lead_service.dart          # Local persistent lead storage & state
│   ├── screens/
│   │   ├── calculator_screen.dart     # Solar calculator & site visit lead capture
│   │   └── admin_inbox_screen.dart    # Protected CRM lead inbox
│   └── theme/
│       └── app_theme.dart             # Sunward Solar brand styling & tokens
└── android/                           # Complete Android build configuration
    ├── build.gradle.kts
    ├── settings.gradle.kts
    ├── gradle.properties
    └── app/
        ├── build.gradle.kts
        └── src/main/
            ├── AndroidManifest.xml
            └── kotlin/com/sunward/solar/MainActivity.kt
```

---

## 🚀 How to Run & Build

### 1. Prerequisites
Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.2.0 or higher) and add `flutter` to your system `PATH`.

### 2. Install Dependencies
```bash
cd solar_app
flutter pub get
```

### 3. Run on Connected Android Device or Emulator
```bash
flutter run
```

### 4. Build Release APK
```bash
flutter build apk --release
```
The output APK will be generated at:
`solar_app/build/app/outputs/flutter-apk/app-release.apk`
