import { Link } from "react-router-dom";
import { motion } from "motion/react";
import { PageLayout } from "@/components/site-shell";

const benefits = [
  ["01", "A calmer electricity bill", "Generate your own power and reduce your dependence on changing grid tariffs."],
  ["02", "A roof with a purpose", "Turn unused rooftop space into a productive, long-term asset for your property."],
  ["03", "A local team beside you", "We help with the survey, system design, paperwork, installation and questions after."],
  ["04", "A decision that fits", "We recommend the right size for your real usage, not the biggest system available."],
];

export default function WhySolar() {
  return (
    <PageLayout overlay>
      <section className="hero-image flex min-h-[100dvh] items-end bg-cover bg-center px-6 pt-28 pb-16 text-white sm:pt-36 sm:pb-20 lg:px-10 lg:pb-28">
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, ease: "easeOut" }}
          className="mx-auto w-full max-w-7xl"
        >
          <p className="text-xs font-bold uppercase tracking-[.22em] text-[var(--sun)]">
            Why solar · Solar kyun?
          </p>
          <h1 className="display mt-5 max-w-3xl text-5xl leading-[.95] sm:text-8xl">
            Make your roof<br />
            <em className="font-normal text-[var(--sun)]">part of the plan.</em>
          </h1>
          <p className="mt-8 max-w-xl text-lg leading-8 text-white/80">
            Solar is a practical upgrade for homes and businesses. Apni bijli par zyada control paaiye.
          </p>
        </motion.div>
      </section>

      <section className="px-6 py-20 lg:px-10 lg:py-28">
        <div className="mx-auto grid max-w-7xl gap-14 lg:grid-cols-[.7fr_1.3fr]">
          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5 }}
            className="display text-4xl sm:text-5xl"
          >
            The good<br />stuff, clearly.
          </motion.h2>
          <div className="grid gap-0 sm:grid-cols-2">
            {benefits.map(([number, title, text], index) => (
              <motion.article
                key={number}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: index * 0.1 }}
                className="border-t border-[var(--ink)]/15 py-7 sm:pr-10"
              >
                <p className="text-sm text-[var(--coral)] font-bold">{number}</p>
                <h3 className="mt-5 text-xl font-bold">{title}</h3>
                <p className="mt-3 text-sm leading-6 text-[var(--muted)]">{text}</p>
              </motion.article>
            ))}
          </div>
        </div>
      </section>

      <section className="hero-image min-h-[360px] bg-cover bg-center px-6 py-20 text-white lg:px-10">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="mx-auto max-w-7xl"
        >
          <p className="max-w-md text-4xl leading-tight sm:text-5xl">
            The best time to understand solar is before you need to.
          </p>
          <motion.div whileHover={{ scale: 1.03 }} whileTap={{ scale: 0.97 }} className="inline-block">
            <Link to="/contact" className="mt-8 inline-block bg-[var(--sun)] px-5 py-4 text-sm font-bold text-[var(--ink)] hover:bg-white transition">
              Talk to a solar advisor ↗
            </Link>
          </motion.div>
        </motion.div>
      </section>
    </PageLayout>
  );
}
