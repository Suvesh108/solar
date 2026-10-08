import { FormEvent, useEffect, useState } from "react";
import { Lead, LeadStatus, readLeads, updateLead } from "@/lib/leads";

const ADMIN_PASSWORD = "sunward123";
const statuses: LeadStatus[] = ["New", "Contacted", "Qualified", "Site Visit", "Quotation", "Won", "Lost"];

export default function AdminInbox() {
  const [authenticated, setAuthenticated] = useState(false);
  const [password, setPassword] = useState("");
  const [leads, setLeads] = useState<Lead[]>([]);
  const [filter, setFilter] = useState("All");
  const [search, setSearch] = useState("");

  useEffect(() => {
    setAuthenticated(sessionStorage.getItem("sunward-admin") === "true");
    setLeads(readLeads());
  }, []);

  function login(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (password === ADMIN_PASSWORD) {
      sessionStorage.setItem("sunward-admin", "true");
      setAuthenticated(true);
    }
  }

  function changeStatus(id: string, status: LeadStatus) {
    updateLead(id, { status });
    setLeads(readLeads());
  }

  if (!authenticated) {
    return (
      <main className="grid min-h-screen place-items-center bg-[var(--ink)] px-6">
        <form onSubmit={login} className="w-full max-w-sm bg-[var(--paper)] p-8">
          <p className="text-xs font-bold uppercase tracking-[.2em] text-[var(--coral)]">Sunward admin</p>
          <h1 className="display mt-4 text-4xl">Lead inbox</h1>
          <p className="mt-3 text-sm leading-6 text-[var(--muted)]">Admin login karein aur customer queries dekhein.</p>
          <label className="mt-8 block text-xs font-bold uppercase tracking-[.12em]">
            Password
            <input
              autoFocus
              required
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              className="input-field mt-2"
            />
          </label>
          <button type="submit" className="mt-5 w-full bg-[var(--ink)] px-5 py-3 text-sm font-bold text-white">
            Open inbox ↗
          </button>
          <p className="mt-4 text-xs text-[var(--muted)]">Default password: sunward123</p>
        </form>
      </main>
    );
  }

  const visibleLeads = leads.filter(
    (lead) =>
      (filter === "All" || lead.status === filter) &&
      `${lead.name} ${lead.phone} ${lead.location}`.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <main className="min-h-screen bg-[var(--paper)]">
      <header className="bg-[var(--ink)] px-6 py-5 text-white">
        <div className="mx-auto flex max-w-7xl items-center justify-between">
          <div>
            <p className="text-lg font-bold">
              ☼ sunward <span className="ml-2 text-sm font-normal text-white/50">admin inbox</span>
            </p>
          </div>
          <button
            type="button"
            onClick={() => {
              sessionStorage.removeItem("sunward-admin");
              setAuthenticated(false);
            }}
            className="text-sm text-white/70 hover:text-white"
          >
            Log out
          </button>
        </div>
      </header>

      <section className="mx-auto max-w-7xl px-6 py-10 lg:px-10">
        <div className="flex flex-col justify-between gap-5 sm:flex-row sm:items-end">
          <div>
            <p className="text-xs font-bold uppercase tracking-[.2em] text-[var(--coral)]">Customer queries</p>
            <h1 className="display mt-3 text-5xl">Lead inbox</h1>
            <p className="mt-3 text-sm text-[var(--muted)]">Sabhi website enquiries yahan dikhenge.</p>
          </div>
          <div className="text-right">
            <p className="text-4xl font-bold">{leads.length}</p>
            <p className="text-xs uppercase tracking-[.15em] text-[var(--muted)]">total leads</p>
          </div>
        </div>

        <div className="mt-10 flex flex-col gap-3 sm:flex-row">
          <input
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder="Search name, phone or location"
            className="input-field max-w-md"
          />
          <select
            value={filter}
            onChange={(event) => setFilter(event.target.value)}
            className="input-field max-w-xs"
          >
            <option>All</option>
            {statuses.map((status) => (
              <option key={status}>{status}</option>
            ))}
          </select>
        </div>

        <div className="mt-8 overflow-hidden border border-[var(--ink)]/10 bg-white">
          <div className="hidden grid-cols-[1.3fr_1fr_1fr_1fr] gap-4 border-b border-[var(--ink)]/10 bg-[var(--cream)] px-5 py-3 text-xs font-bold uppercase tracking-[.12em] text-[var(--muted)] md:grid">
            <span>Customer</span>
            <span>Contact</span>
            <span>Requirement</span>
            <span>Status</span>
          </div>

          {visibleLeads.length === 0 ? (
            <div className="px-5 py-14 text-center text-sm text-[var(--muted)]">
              No queries yet. Website form submissions will appear here.
            </div>
          ) : (
            visibleLeads.map((lead) => (
              <article
                key={lead.id}
                className="grid gap-3 border-b border-[var(--ink)]/10 px-5 py-5 last:border-0 md:grid-cols-[1.3fr_1fr_1fr_1fr] md:items-center md:gap-4"
              >
                <div>
                  <h2 className="font-bold">{lead.name}</h2>
                  <p className="mt-1 text-sm text-[var(--muted)]">{lead.location}</p>
                  <p className="mt-1 text-xs text-[var(--muted)]">
                    {new Date(lead.createdAt).toLocaleString("en-IN")}
                  </p>
                </div>
                <div>
                  <a href={`tel:${lead.phone}`} className="text-sm font-bold text-[var(--teal)]">
                    {lead.phone}
                  </a>
                </div>
                <div>
                  <p className="text-sm">₹{Number(lead.monthlyBill).toLocaleString("en-IN")} / month</p>
                  <p className="mt-1 text-xs text-[var(--muted)]">{lead.propertyType}</p>
                </div>
                <select
                  aria-label={`Status for ${lead.name}`}
                  value={lead.status}
                  onChange={(event) => changeStatus(lead.id, event.target.value as LeadStatus)}
                  className="input-field py-2 text-sm"
                >
                  {statuses.map((status) => (
                    <option key={status}>{status}</option>
                  ))}
                </select>
              </article>
            ))
          )}
        </div>
      </section>
    </main>
  );
}
