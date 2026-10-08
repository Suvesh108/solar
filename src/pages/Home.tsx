import { Link } from "react-router-dom";
import { motion } from "motion/react";
import { SiteHeader, whatsappUrl } from "@/components/site-shell";

const projects = [
  ["The green home", "Pune · 3 kW", "project-image-1"],
  ["A cooler workplace", "Nashik · 10 kW", "project-image-2"],
  ["Room to grow", "Satara · 5 kW", "project-image-3"],
];

export default function Home() {
  return (
    <main>
      <SiteHeader overlay={true} />

      <section id="top" className="hero-image flex min-h-[100dvh] items-end bg-cover bg-center text-white">
        <div className="mx-auto grid w-full max-w-7xl gap-8 px-6 pb-16 pt-28 sm:gap-12 sm:pb-20 sm:pt-36 lg:grid-cols-[1.2fr_.8fr] lg:px-10 lg:pb-28">
          <motion.div
            initial={{ opacity: 0, y: 24 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, ease: "easeOut" }}
            className="max-w-3xl"
          >
            <p className="mb-6 text-xs font-bold uppercase tracking-[.22em] text-[var(--sun)]">
              Powering a brighter everyday · Aapki bijli, aapka control
            </p>
            <h1 className="display text-5xl leading-[.94] tracking-[-.03em] sm:text-8xl">
              Your roof has<br />
              <em className="font-normal text-[var(--sun)]">more to give.</em>
            </h1>
            <p className="mt-8 max-w-lg text-lg leading-8 text-white/80">
              Ghar aur business ke liye rooftop solar. Hum simple language mein samjhaate hain, sahi system suggest karte hain.
            </p>
            <div className="mt-9 flex flex-wrap gap-3">
              <motion.div whileHover={{ scale: 1.03 }} whileTap={{ scale: 0.97 }}>
                <Link to="/contact" className="inline-block bg-[var(--sun)] px-6 py-4 text-sm font-bold text-[var(--ink)] hover:bg-white transition">
                  Free assessment lein ↗
                </Link>
              </motion.div>
              <motion.div whileHover={{ scale: 1.03 }} whileTap={{ scale: 0.97 }}>
                <a href="tel:+919999999999" className="inline-block border border-white/50 px-6 py-4 text-sm font-bold hover:bg-white hover:text-[var(--ink)] transition">
                  Phone se baat karein
                </a>
              </motion.div>
            </div>
          </motion.div>
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.6, delay: 0.2, ease: "easeOut" }}
            className="self-end border-l border-white/30 pl-6 lg:mb-3"
          >
            <p className="text-4xl text-[var(--sun)]">01</p>
            <p className="mt-3 max-w-xs text-sm leading-6 text-white/75">
              Smartphone nahi hai? Koi problem nahi. Humein direct call karein, hum help karenge.
            </p>
          </motion.div>
        </div>
      </section>

      <section id="why" className="grain border-b border-[var(--ink)]/10 bg-[var(--cream)] px-6 py-16 sm:py-20 lg:px-10 lg:py-28">
        <div className="mx-auto max-w-7xl">
          <div className="grid gap-8 sm:gap-12 lg:grid-cols-[.8fr_1.2fr]">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5 }}
            >
              <p className="text-xs font-bold uppercase tracking-[.22em] text-[var(--coral)]">
                The sunward way
              </p>
              <h2 className="display mt-4 text-4xl leading-none sm:text-5xl lg:text-6xl">
                Good solar<br />
                <em className="font-normal">starts with trust.</em>
              </h2>
            </motion.div>
            <div className="grid gap-8 sm:grid-cols-3">
              {[
                ["◎", "Advice before equipment", "We understand your bill and your roof before we recommend a system."],
                ["↗", "Built for your place", "Every home and business gets a plan tuned to its actual energy rhythm."],
                ["✳", "People who stay close", "A local team for the survey, the paperwork, and questions after."],
              ].map(([icon, title, text], index) => (
                <motion.div
                  key={title}
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.5, delay: index * 0.1 }}
                >
                  <span className="text-3xl text-[var(--coral)]">{icon}</span>
                  <h3 className="mt-5 text-lg font-bold">{title}</h3>
                  <p className="mt-3 text-sm leading-6 text-[var(--muted)]">{text}</p>
                </motion.div>
              ))}
            </div>
          </div>
        </div>
      </section>

      <section id="projects" className="px-6 py-16 sm:py-20 lg:px-10 lg:py-28">
        <div className="mx-auto max-w-7xl">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5 }}
          >
            <p className="text-xs font-bold uppercase tracking-[.22em] text-[var(--coral)]">
              A few rooftops
            </p>
            <h2 className="display mt-4 text-4xl leading-none sm:text-5xl lg:text-6xl">
              Sunlight,<br />
              <em className="font-normal">put to work.</em>
            </h2>
          </motion.div>
          <div className="mt-12 grid gap-5 md:grid-cols-3">
            {projects.map(([title, place, className], index) => (
              <motion.div
                key={title}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: index * 0.1 }}
                whileHover={{ y: -4 }}
                className={`${className} flex aspect-[4/3] items-end bg-cover bg-center p-6 text-white sm:aspect-[.9] transition-shadow duration-300`}
              >
                <div>
                  <p className="text-lg font-bold">{title}</p>
                  <p className="mt-1 text-sm text-white/75">{place}</p>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      <div className="fixed bottom-4 right-4 z-20 flex gap-2 sm:bottom-5 sm:right-5">
        <motion.a
          whileHover={{ scale: 1.08 }}
          whileTap={{ scale: 0.92 }}
          aria-label="Call Sunward Solar"
          href="tel:+919999999999"
          className="grid h-12 w-12 place-items-center rounded-full bg-[var(--ink)] text-lg text-white shadow-xl sm:h-14 sm:w-14 sm:text-xl"
        >
          ☎
        </motion.a>
        <motion.a
          whileHover={{ scale: 1.08 }}
          whileTap={{ scale: 0.92 }}
          aria-label="Chat on WhatsApp"
          href={whatsappUrl()}
          target="_blank"
          rel="noreferrer"
          className="grid h-12 w-12 place-items-center rounded-full bg-[#25D366] text-xl text-white shadow-xl sm:h-14 sm:w-14 sm:text-2xl"
        >
          ◔
        </motion.a>
      </div>
    </main>
  );
}
