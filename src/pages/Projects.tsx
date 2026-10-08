import { motion } from "motion/react";
import { PageLayout } from "@/components/site-shell";

const projects = [
  ["The green home", "Pune · 3 kW", "project-image-1"],
  ["A cooler workplace", "Nashik · 10 kW", "project-image-2"],
  ["Room to grow", "Satara · 5 kW", "project-image-3"],
  ["Quiet power", "Kolhapur · 5 kW", "project-image-1"],
  ["The daily shop", "Sangli · 3 kW", "project-image-2"],
  ["A brighter office", "Pune · 10 kW", "project-image-3"],
];

export default function Projects() {
  return (
    <PageLayout>
      <section className="bg-[var(--cream)] px-6 py-20 lg:px-10 lg:py-32">
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, ease: "easeOut" }}
          className="mx-auto max-w-7xl"
        >
          <p className="text-xs font-bold uppercase tracking-[.22em] text-[var(--coral)]">
            Our projects
          </p>
          <h1 className="display mt-5 max-w-3xl text-6xl leading-[.95] sm:text-8xl">
            Sunlight,<br />
            <em className="font-normal">put to work.</em>
          </h1>
          <p className="mt-8 max-w-xl text-lg leading-8 text-[var(--muted)]">
            A growing collection of rooftops designed around the people and businesses beneath them.
          </p>
        </motion.div>
      </section>

      <section className="px-6 py-20 lg:px-10 lg:py-28">
        <div className="mx-auto grid max-w-7xl gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {projects.map(([title, place, image], index) => (
            <motion.article
              key={`${title}-${place}`}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: (index % 3) * 0.1 }}
              whileHover={{ y: -5 }}
              className={`${image} flex aspect-[4/3] items-end bg-cover bg-center p-6 text-white sm:aspect-[.9] transition-shadow duration-300`}
            >
              <div>
                <h2 className="text-lg font-bold">{title}</h2>
                <p className="mt-1 text-sm text-white/75">{place}</p>
              </div>
            </motion.article>
          ))}
        </div>
      </section>
    </PageLayout>
  );
}
