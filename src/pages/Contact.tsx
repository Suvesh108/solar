import { FormEvent, useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { PageLayout, whatsappUrl } from "@/components/site-shell";
import { saveLead } from "@/lib/leads";

export default function Contact() {
  const [sent, setSent] = useState(false);

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const fields = event.currentTarget.querySelectorAll("input");
    const name = fields[0]?.value || "";
    const phone = fields[1]?.value || "";
    const location = fields[2]?.value || "";
    const bill = fields[3]?.value || "";
    saveLead({ name, phone, location, monthlyBill: bill, propertyType: "House" });
    setSent(true);

    // Also trigger instant WhatsApp notification to father's phone so the lead is never lost
    const text = encodeURIComponent(
      `*New Solar Website Lead!*\n👤 Name: ${name}\n📞 Phone: ${phone}\n📍 Location: ${location}\n⚡ Monthly Bill: ₹${bill}\n\nClient has requested a free rooftop solar site assessment.`
    );
    window.open(`https://wa.me/919731001477?text=${text}`, "_blank");
  }

  return (
    <PageLayout compact>
      <section className="flex flex-1 min-h-screen w-full items-center bg-[var(--coral)] px-6 pt-24 pb-20 text-white sm:pt-28 sm:pb-20 lg:py-12 lg:px-10">
        <div className="mx-auto grid w-full max-w-7xl gap-10 lg:grid-cols-[.9fr_1.1fr] lg:items-center">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
          >
            <p className="text-xs font-bold uppercase tracking-[.2em] text-[var(--sun)]">
              Get in touch · Seedhi baat
            </p>
            <h1 className="display mt-3 text-4xl leading-tight sm:text-7xl sm:leading-[.95]">
              Let&apos;s look<br />
              <em className="font-normal text-[var(--sun)]">at your roof.</em>
            </h1>
            <p className="mt-5 max-w-md text-base leading-7 text-white/80 sm:text-lg">
              Apni details share karein. Hamara solar consultant aapko call karke next steps simple way mein samjhayega.
            </p>
            <div className="mt-6 flex flex-wrap gap-4 text-sm font-bold">
              <a href="tel:+919731001477" className="hover:opacity-90 transition">Keypad phone? Call karein ☎</a>
              <a href={whatsappUrl()} target="_blank" rel="noreferrer" className="hover:opacity-90 transition">
                WhatsApp ↗
              </a>
            </div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, scale: 0.98 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.5, delay: 0.1 }}
            className="bg-[var(--paper)] p-6 text-[var(--ink)] sm:p-8 shadow-xl"
          >
            <AnimatePresence mode="wait">
              {sent ? (
                <motion.div
                  key="success"
                  initial={{ opacity: 0, y: 15 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -15 }}
                  transition={{ duration: 0.4 }}
                  className="flex min-h-[330px] flex-col justify-center"
                >
                  <span className="text-5xl text-[var(--coral)]">✳</span>
                  <h2 className="display mt-4 text-4xl">You&apos;re on your way.</h2>
                  <p className="mt-3 text-sm leading-6 text-[var(--muted)]">
                    Dhanyavaad! Hamara consultant aapko jaldi call karega.
                  </p>
                  <motion.a
                    whileHover={{ scale: 1.02 }}
                    whileTap={{ scale: 0.98 }}
                    href="tel:+919731001477"
                    className="mt-5 inline-block bg-[var(--ink)] px-5 py-3 text-sm font-bold text-white text-center"
                  >
                    Call us directly ☎
                  </motion.a>
                </motion.div>
              ) : (
                <motion.form
                  key="form"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  onSubmit={submit}
                  className="grid gap-4"
                >
                  <label className="block text-xs font-bold uppercase tracking-[.12em]">
                    Name / Naam
                    <input required className="input-field mt-1.5 py-3" placeholder="Apna naam" />
                  </label>
                  <label className="block text-xs font-bold uppercase tracking-[.12em]">
                    Mobile number
                    <input required type="tel" className="input-field mt-1.5 py-3" placeholder="+91" />
                  </label>
                  <div className="grid gap-4 sm:grid-cols-2">
                    <label className="block text-xs font-bold uppercase tracking-[.12em]">
                      Location / Jagah
                      <input required className="input-field mt-1.5 py-3" placeholder="City ya gaon" />
                    </label>
                    <label className="block text-xs font-bold uppercase tracking-[.12em]">
                      Monthly bill
                      <input required type="number" className="input-field mt-1.5 py-3" placeholder="₹ 5,000" />
                    </label>
                  </div>
                  <motion.button
                    whileHover={{ scale: 1.01 }}
                    whileTap={{ scale: 0.98 }}
                    type="submit"
                    className="mt-2 bg-[var(--ink)] px-5 py-3.5 text-left text-sm font-bold text-white hover:bg-[var(--teal)] transition cursor-pointer"
                  >
                    Free assessment request karein <span className="float-right">↗</span>
                  </motion.button>
                  <p className="text-xs text-[var(--muted)]">Smartphone nahi hai? Direct call karein: +91 9731001477</p>
                </motion.form>
              )}
            </AnimatePresence>
          </motion.div>
        </div>
      </section>
    </PageLayout>
  );
}
