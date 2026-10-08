# Sunward Solar

Solar rooftop lead generation platform & mobile application suite.

## 🌟 Overview

- **Web Application (`/src`)**: High-performance React 19 + Vite SPA built with Tailwind CSS v4, Motion, and local lead management.
- **Android App (`/solar_app`)**: Standalone Flutter application focused purely on the **Solar ROI Calculator** and **Admin Lead Box**.

---

## ⚡ Web Platform

### Getting Started

```bash
# Install dependencies
npm install

# Start local dev server
npm run dev

# Build for production
npm run build
```

### Pages & Routes

- `/` — Homepage with direct consultation CTA, WhatsApp & phone integration.
- `/why-solar` — Educational rooftop solar guide, net metering & subsidy overview.
- `/projects` — Real installations & project portfolio.
- `/calculator` — Interactive solar ROI, capacity, payback & subsidy calculator.
- `/contact` — Lead capture form with direct persistent lead routing.
- `/admin/inbox` — Direct administrative lead inbox & CRM pipeline.

---

## 📱 Mobile App (`solar_app/`)

Dedicated Flutter Android app featuring:
- **Tab 1: Calculator** — Interactive solar sizing, payback calculation, and direct customer site visit intake.
- **Tab 2: Admin Box** — Direct lead CRM with live pending badges, status switcher, one-tap phone dialer, and WhatsApp launcher.

To run:
```bash
cd solar_app
flutter pub get
flutter run
```
