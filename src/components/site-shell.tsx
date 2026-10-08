import { useState } from "react";
import { Link } from "react-router-dom";
import { motion, AnimatePresence } from "motion/react";

const WHATSAPP_NUMBER = "919999999999";

export function whatsappUrl(message = "Hi, I'm interested in a free solar assessment for my property.") {
  return `https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(message)}`;
}

export function SiteHeader({ overlay = false }: { overlay?: boolean }) {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  return (
    <header className={overlay ? "absolute top-0 left-0 z-30 w-full bg-transparent text-white" : "relative z-30 bg-transparent text-[var(--ink)]"}>
      <div className="mx-auto flex max-w-7xl items-center justify-between px-6 py-5 lg:px-10">
        <Link to="/" className="flex items-center gap-2 text-lg font-bold tracking-tight">
          <span className="grid h-8 w-8 place-items-center rounded-full bg-[var(--sun)] text-[var(--ink)]">☼</span>
          sunward
        </Link>
        <nav className="hidden items-center gap-8 text-sm md:flex">
          <Link to="/why-solar">Why solar</Link>
          <Link to="/calculator">Calculator</Link>
          <Link to="/contact">Contact</Link>
        </nav>
        <div className="flex items-center gap-2">
          <a href="tel:+919999999999" className="hidden border border-current/40 px-3 py-2 text-sm font-bold sm:block">
            Call us
          </a>
          <Link
            to="/contact"
            className={
              overlay
                ? "border border-white/60 px-4 py-2 text-sm transition hover:bg-white hover:text-[var(--ink)]"
                : "bg-[var(--ink)] px-4 py-2 text-sm font-bold text-white transition hover:bg-[var(--teal)]"
            }
          >
            Free assessment ↗
          </Link>
          <button
            type="button"
            aria-label="Toggle navigation menu"
            aria-expanded={mobileMenuOpen}
            onClick={() => setMobileMenuOpen((prev) => !prev)}
            className={`grid h-10 w-10 place-items-center border text-base font-bold transition md:hidden cursor-pointer ${
              overlay ? "border-white/60 text-white bg-black/20" : "border-[var(--ink)]/30 text-[var(--ink)] bg-black/5"
            }`}
          >
            {mobileMenuOpen ? "✕" : "☰"}
          </button>
        </div>
      </div>

      <AnimatePresence>
        {mobileMenuOpen && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            transition={{ duration: 0.2 }}
            className="absolute top-full left-0 w-full border-b border-[var(--ink)]/15 bg-[var(--paper)] px-6 py-5 text-[var(--ink)] shadow-2xl md:hidden z-50"
          >
            <nav className="flex flex-col gap-3.5 text-base font-semibold">
              <Link
                to="/why-solar"
                onClick={() => setMobileMenuOpen(false)}
                className="flex items-center justify-between border-b border-[var(--ink)]/10 pb-3"
              >
                <span>Why solar</span>
                <span className="text-xs text-[var(--muted)]">→</span>
              </Link>
              <Link
                to="/calculator"
                onClick={() => setMobileMenuOpen(false)}
                className="flex items-center justify-between border-b border-[var(--ink)]/10 pb-3"
              >
                <span>Calculator</span>
                <span className="text-xs text-[var(--muted)]">→</span>
              </Link>
              <Link
                to="/contact"
                onClick={() => setMobileMenuOpen(false)}
                className="flex items-center justify-between border-b border-[var(--ink)]/10 pb-3"
              >
                <span>Contact</span>
                <span className="text-xs text-[var(--muted)]">→</span>
              </Link>
              <a
                href="tel:+919999999999"
                className="mt-2 flex items-center justify-center gap-2 bg-[var(--sun)] py-3 text-center text-sm font-bold text-[var(--ink)] transition hover:bg-white"
              >
                <span>☎ Call us: +91 99999 99999</span>
              </a>
            </nav>
          </motion.div>
        )}
      </AnimatePresence>
    </header>
  );
}

export function SiteFooter() {
  return (
    <footer className="bg-[var(--ink)] px-6 pt-12 pb-28 text-white sm:pb-14 lg:px-10">
      <div className="mx-auto flex max-w-7xl flex-col justify-between gap-10 md:flex-row md:items-end">
        <div>
          <Link to="/" className="flex items-center gap-2 text-lg font-bold">
            <span className="grid h-8 w-8 place-items-center rounded-full bg-[var(--sun)] text-[var(--ink)]">☼</span>
            sunward
          </Link>
          <p className="mt-5 max-w-xs text-sm leading-6 text-white/55">
            Rooftop solar, made clear. Ghar ho ya business, hum help karte hain.
          </p>
        </div>
        <div className="flex flex-col gap-3 text-sm">
          <a href="tel:+919999999999" className="text-[var(--sun)] font-medium">
            Call us: +91 99999 99999
          </a>
          <a href={whatsappUrl()} target="_blank" rel="noreferrer" className="text-white/70 hover:text-white transition">
            WhatsApp us ↗
          </a>
          <a href="mailto:hello@sunwardsolar.in" className="text-white/70 hover:text-white transition">
            hello@sunwardsolar.in
          </a>
          <p className="text-white/40">Mon–Sat · 9:00–18:00</p>
        </div>
      </div>
      <div className="mx-auto mt-12 max-w-7xl border-t border-white/10 pt-5 text-xs text-white/35">
        © 2026 Sunward Solar · Estimate sirf idea ke liye hai; final result site survey ke baad.
      </div>
    </footer>
  );
}

function WhatsAppIcon({ className = "w-6 h-6" }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="currentColor"
      className={className}
      aria-hidden="true"
    >
      <path d="M17.472 14.382c-.301-.15-1.781-.879-2.057-.979-.276-.1-.476-.15-.676.15-.2.301-.776.979-.951 1.179-.176.2-.351.226-.652.076-.301-.15-1.27-.468-2.42-1.493-.894-.798-1.497-1.783-1.672-2.084-.176-.3-.019-.462.132-.612.136-.135.301-.35.451-.525.15-.175.2-.3.301-.5.1-.2.05-.375-.025-.525-.075-.15-.676-1.63-.926-2.233-.243-.588-.49-.508-.676-.518-.175-.008-.376-.01-.577-.01-.2 0-.527.075-.802.375-.276.301-1.053 1.029-1.053 2.51s1.078 2.912 1.228 3.113c.15.2 2.122 3.24 5.14 4.544.718.31 1.278.496 1.716.635.722.23 1.379.197 1.9.12.58-.087 1.781-.728 2.032-1.43.25-.702.25-1.303.175-1.43-.075-.126-.276-.201-.577-.351zM12.04 2C6.51 2 2.015 6.495 2.015 12.025c0 1.91.536 3.693 1.468 5.215L2 22l4.908-1.433c1.472.85 3.177 1.34 5.132 1.34 5.53 0 10.025-4.495 10.025-10.025S17.57 2 12.04 2zm0 18.232c-1.67 0-3.22-.505-4.516-1.37l-.324-.216-2.914.85.87-2.842-.236-.346a8.167 8.167 0 0 1-1.258-4.283c0-4.526 3.682-8.208 8.378-8.208 4.695 0 8.378 3.682 8.378 8.208 0 4.526-3.683 8.207-8.378 8.207z" />
    </svg>
  );
}

function PhoneIcon({ className = "w-5 h-5" }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="currentColor"
      className={className}
      aria-hidden="true"
    >
      <path d="M6.62 10.79a15.053 15.053 0 006.59 6.59l2.2-2.2c.27-.27.67-.36 1.02-.24 1.12.37 2.33.57 3.57.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1-9.39 0-17-7.61-17-17 0-.55.45-1 1-1h3.5c.55 0 1 .45 1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z" />
    </svg>
  );
}

export function PageLayout({
  children,
  compact = false,
  overlay = false,
}: {
  children: React.ReactNode;
  compact?: boolean;
  overlay?: boolean;
}) {
  return (
    <div className={`min-h-screen w-full flex flex-col ${compact ? "" : "justify-between"}`}>
      <SiteHeader overlay={overlay || compact} />
      <main className="flex-1 w-full flex flex-col">{children}</main>
      {!compact && <SiteFooter />}
      <div className="fixed bottom-4 right-4 z-20 flex gap-2 sm:bottom-5 sm:right-5">
        <motion.a
          whileHover={{ scale: 1.08 }}
          whileTap={{ scale: 0.92 }}
          aria-label="Call Sunward Solar"
          href="tel:+919999999999"
          className="grid h-12 w-12 place-items-center rounded-full bg-[var(--ink)] text-white shadow-xl sm:h-14 sm:w-14"
        >
          <PhoneIcon className="w-5 h-5 sm:w-6 sm:h-6" />
        </motion.a>
        <motion.a
          whileHover={{ scale: 1.08 }}
          whileTap={{ scale: 0.92 }}
          aria-label="Chat on WhatsApp"
          href={whatsappUrl()}
          target="_blank"
          rel="noreferrer"
          className="grid h-12 w-12 place-items-center rounded-full bg-[#25D366] text-white shadow-xl sm:h-14 sm:w-14"
        >
          <WhatsAppIcon className="w-6 h-6 sm:w-7 sm:h-7" />
        </motion.a>
      </div>
    </div>
  );
}
