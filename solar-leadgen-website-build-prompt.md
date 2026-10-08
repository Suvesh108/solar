# Solar Lead-Generation Website — Agent Build Prompt

> Paste this into your AI coding agent (Antigravity / Claude Code / Cursor). Build phase by phase — do not skip ahead. Confirm each phase works before moving to the next.

## Project Summary

Build a **solar lead-generation website** for a local solar dealership business. The business sits between the customer and the solar installation company: the website's only job is to **capture and qualify leads at low cost**, then hand them to an admin dashboard for follow-up.

Business flow:
```
Customer → Website/Google/WhatsApp → Lead Captured → Qualify → Site Survey
        → Solar Company → Quotation → Installation → Commission/Margin
```

This is V1. Keep it lean — a professional landing experience, a working lead-capture calculator, a WhatsApp funnel, and a basic admin dashboard. No CRM automation, no payments, no complex integrations yet.

---

## Tech Stack

- **Frontend:** Next.js (App Router) + Tailwind CSS — chosen for SEO (local search is the primary acquisition channel)
- **Backend:** Node.js + Express (or Next.js API routes if simpler for V1)
- **Database:** MongoDB (MongoDB Atlas for hosting)
- **Auth:** Simple admin login (JWT-based, single/few admin users — father + self)
- **Hosting:** Frontend → Vercel, Backend → Railway, DB → MongoDB Atlas
- **Deferred:** payments, SMS, multi-tenant support, complex CRM

---

## Site Structure

```
/
├── Home
├── Residential Solar
├── Commercial Solar
├── Solar Calculator
├── Solar Subsidy
├── Solar Solutions
│   ├── 2kW Solar
│   ├── 3kW Solar
│   ├── 5kW Solar
│   └── 10kW Solar
├── Our Projects
├── About
├── Contact
├── Get Free Site Survey
└── /admin (protected)
    ├── Login
    ├── Leads Dashboard
    └── Lead Detail View
```

---

## Phase 1 — Landing Page & Core Pages

**Goal:** A professional, fast, SEO-friendly landing page that clearly answers: what do you sell, where do you operate, why contact us.

Build:
1. **Homepage hero** with headline pattern:
   - "Switch to Solar. Reduce Your Electricity Bill."
   - Subtext: "Residential & Commercial Rooftop Solar Solutions — Free Site Survey & Consultation"
   - Two CTAs: **Get Free Assessment** (scrolls/links to lead form) and **WhatsApp Us** (opens `wa.me` link)
2. **Residential Solar** and **Commercial Solar** pages — benefits, use cases, imagery placeholders
3. **Solar Solutions** pages for 2kW / 3kW / 5kW / 10kW — each with typical use case (home size / business type), estimated output, placeholder pricing range
4. **Solar Subsidy** page — general explainer content (mark as informational, not guaranteed figures)
5. **Our Projects** — gallery/grid component, placeholder data for now
6. **About** and **Contact** pages
7. Shared **Header/Nav**, **Footer**, and persistent **WhatsApp floating button**
8. Responsive, mobile-first (majority of local search traffic will be mobile)
9. Basic on-page SEO: proper `<title>`, meta descriptions, semantic headings, structured data (LocalBusiness schema) per page

**Do not build the calculator or lead form logic yet — placeholder sections/buttons only.**

---

## Phase 2 — Solar Calculator (Lead Magnet)

**Goal:** The key differentiator vs. local dealers — an interactive estimator that converts visitors into leads.

### Inputs
```
Monthly Electricity Bill (₹)
Location
Property Type: House / Shop / Office / Factory
Roof Type: RCC / Metal / Other
```

### Output (estimate only — label clearly as such)
```
Estimated Solar Requirement       (kW)
Estimated Annual Generation       (units)
Estimated Annual Savings          (₹)
Estimated System Cost             (₹)
Estimated Payback                 (years)
```

### Calculation logic (placeholder formulas — make these easily configurable constants, not hardcoded magic numbers, since real formulas depend on tariff/location/subsidy policy and will need tuning):
- Estimate monthly units consumed from bill ÷ average tariff rate (configurable, default e.g. ₹7/unit)
- Estimate required kW from monthly units ÷ average generation per kW per month (configurable, e.g. ~120 units/kW/month depending on region)
- System cost = kW × cost-per-kW (configurable, e.g. ₹55,000/kW — adjust to real dealer pricing)
- Annual savings = annual units generated × tariff rate
- Payback = system cost ÷ annual savings

### After showing results
- CTA: "Want an accurate calculation for your property? **Get Free Site Survey**"
- This should feed directly into the Phase 3 lead form, pre-filled with calculator inputs

**Important:** Display a visible disclaimer that results are estimates — actual generation, cost, subsidy, and savings depend on site inspection, current tariffs, equipment, and approvals.

---

## Phase 3 — Lead Capture Form + Backend

**Goal:** Simple, low-friction lead form wired to a real backend and database.

### Form fields (keep minimal for first submission)
```
Name
Mobile Number
Location
Monthly Electricity Bill
Property Type
```
(Optional hidden fields, auto-filled if coming from calculator: estimated kW, estimated cost, estimated savings)

### Backend
- `POST /api/leads` — validates and stores lead in MongoDB
- Lead schema:
```
{
  name: String,
  phone: String,
  location: String,
  monthlyBill: Number,
  propertyType: String, // House | Shop | Office | Factory
  estimatedKW: Number,          // optional, from calculator
  estimatedCost: Number,        // optional
  estimatedSavings: Number,     // optional
  source: String,               // Google, Instagram, Facebook, WhatsApp, Referral, Electrician, Builder, Website, Advertisement
  status: String,                // New | Contacted | Qualified | Site Visit | Quotation | Won | Lost
  followUpDate: Date,
  notes: String,
  createdAt: Date,
  updatedAt: Date
}
```
- `source` should default to `Website` but be overridable via URL query param (e.g. `?src=instagram`) so campaigns can be tracked
- On successful submit: show "Thank you! Our solar consultant will contact you shortly." + WhatsApp CTA
- Basic rate limiting / spam protection on the endpoint (honeypot field is sufficient for V1)

---

## Phase 4 — WhatsApp Funnel

**Goal:** Make WhatsApp a first-class lead channel, not just a link.

- Floating WhatsApp button on every page, prefilled message: "Hi, I'm interested in a free solar assessment for my property."
- Dedicated `/contact` WhatsApp CTA block with copy:
  > ☀️ Thinking about installing rooftop solar? Find out how much you could save on your electricity bill. Free Solar Assessment — WhatsApp us today.
- No deep API integration needed for V1 (just `wa.me` links) — log a `source: WhatsApp` lead only if/when they also fill the form; don't try to auto-capture WhatsApp conversations yet

---

## Phase 5 — Admin Login + Lead Dashboard

**Goal:** A basic internal tool for the father/admin to manage leads without needing developer help.

### Auth
- Simple `/admin/login` — email/username + password, JWT stored in httpOnly cookie
- Seed one or two admin accounts manually (no public signup)

### Dashboard (`/admin/leads`)
- Summary counts at top:
```
New | Contacted | Qualified | Site Visit | Quotation | Won | Lost
```
- Table/list of leads, filterable by status and source, sortable by date
- Click into a lead → detail view:
```
Name / Phone / Location / Monthly Bill / Estimated Solar (kW)
Status: [dropdown: New/Contacted/Qualified/Site Visit/Quotation/Won/Lost]
Follow-up date: [date picker]
Notes: [free text, appendable]
```
- Update status/notes/follow-up via `PATCH /api/leads/:id`
- No need for email/SMS notifications in V1 — admin checks dashboard manually

---

## Phase 6 — Analytics Foundations (lightweight)

**Goal:** Make sure the data needed for later decisions is being captured from day one, even if the analysis UI comes later.

- Every lead has a `source` field (already in schema) — this alone unlocks:
  > "Google generated 40 leads, 5 sales. Instagram generated 20 leads, 1 sale. Electrician referrals generated 10 leads, 4 sales."
- Add basic conversion funnel counts to the dashboard summary (leads → site visits → won) computed from `status`
- Track cost fields are NOT needed in-app yet (ad spend can be tracked manually in a spreadsheet initially) — don't over-build this

---

## Explicitly Out of Scope for V1

- Payments/invoicing
- Automated SMS/email drip campaigns
- Multi-language support
- "Solar Savings Report" PDF generator (nice V2 feature — downloadable report from calculator inputs)
- Full CRM automation / lead scoring
- Local SEO landing pages per city/neighborhood (do this manually with real content later — don't auto-generate thin pages)

---

## Build Order Recap

1. Landing + core content pages (SEO-first, mobile-first)
2. Solar calculator (frontend logic, configurable constants)
3. Lead form + backend + MongoDB + `/api/leads`
4. WhatsApp funnel (buttons + prefilled messages)
5. Admin auth + lead dashboard (CRUD on lead status/notes)
6. Source tracking + basic funnel counts

Confirm each phase renders/functions correctly before proceeding to the next. Keep calculator formulas and pricing as named constants in one config file so they're easy to update once real dealer pricing/subsidy data is available.
