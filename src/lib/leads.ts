export type LeadStatus = "New" | "Contacted" | "Qualified" | "Site Visit" | "Quotation" | "Won" | "Lost";

export type Lead = {
  id: string;
  name: string;
  phone: string;
  location: string;
  monthlyBill: string;
  propertyType: string;
  status: LeadStatus;
  createdAt: string;
};

const STORAGE_KEY = "sunward-leads";

export function saveLead(lead: Omit<Lead, "id" | "status" | "createdAt">) {
  const existing = readLeads();
  const next: Lead = { ...lead, id: crypto.randomUUID(), status: "New", createdAt: new Date().toISOString() };
  localStorage.setItem(STORAGE_KEY, JSON.stringify([next, ...existing]));
  return next;
}

export function readLeads(): Lead[] {
  if (typeof window === "undefined") return [];
  try {
    return JSON.parse(localStorage.getItem(STORAGE_KEY) || "[]") as Lead[];
  } catch {
    return [];
  }
}

export function updateLead(id: string, changes: Partial<Lead>) {
  const leads = readLeads().map((lead) => lead.id === id ? { ...lead, ...changes } : lead);
  localStorage.setItem(STORAGE_KEY, JSON.stringify(leads));
}
