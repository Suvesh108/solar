import { useState } from "react";
import { Link } from "react-router-dom";
import { motion } from "motion/react";
import { PageLayout } from "@/components/site-shell";

export default function Calculator() {
  const [bill, setBill] = useState<string | number>(5000);
  const [userKw, setUserKw] = useState<string | number>(3);
  const [property, setProperty] = useState("House");
  const [tariff, setTariff] = useState<string | number>(7);
  const [costPerKw, setCostPerKw] = useState<string | number>(55000);
  const [subsidy, setSubsidy] = useState<string | number>(78000);

  const numericBill = typeof bill === "number" ? bill : (Number(bill) || 0);
  const numericTariff = typeof tariff === "number" ? tariff : (Number(tariff) || 7);
  const numericCostPerKw = typeof costPerKw === "number" ? costPerKw : (Number(costPerKw) || 55000);
  const numericSubsidy = typeof subsidy === "number" ? subsidy : (Number(subsidy) || 0);
  const safeTariff = numericTariff > 0 ? numericTariff : 7;
  
  // Approx 4 units per kW per day = 120 units/kW/month
  const GENERATION_PER_KW_MONTH = 120;
  const kw = typeof userKw === "number" ? userKw : (Number(userKw) || 0);
  const hasKw = kw > 0;
  
  const dailyGeneration = kw * 4;
  const monthlyGeneration = kw * GENERATION_PER_KW_MONTH;
  const annualGeneration = monthlyGeneration * 12;
  const monthlySavings = monthlyGeneration * safeTariff;
  const annualSavings = annualGeneration * safeTariff;
  const grossCost = kw * numericCostPerKw;
  
  const effectiveSubsidy = hasKw ? numericSubsidy : 0;
  const netCost = Math.max(0, grossCost - effectiveSubsidy);
  const payback = (hasKw && annualSavings > 0) ? (netCost / annualSavings).toFixed(1) : "0";
  const lifetimeSavings = hasKw ? Math.max(0, (annualSavings * 25) - netCost) : 0;
  const roiPercent = (hasKw && netCost > 0) ? Math.round((lifetimeSavings / netCost) * 100) : 0;
  
  const roofAreaSqFt = kw * 100; // ~100 sq ft per kW
  const panelCount = Math.max(1, Math.ceil((kw * 1000) / 540)); // ~540W Mono PERC / TopCon panels
  const co2Kg = Math.round(annualGeneration * 0.82); // 820g CO2 per kWh
  const treesCount = Math.max(1, Math.round(co2Kg / 20)); // ~20kg CO2 per tree/yr

  const format = (value: number) => {
    if (isNaN(value) || !isFinite(value)) return "0";
    return Math.round(value).toLocaleString("en-IN");
  };

  const handleBillChange = (val: string) => {
    const clean = val === "" ? "" : val.replace(/^0+(?=\d)/, "");
    setBill(clean);
    const nBill = Number(clean) || 0;
    if (nBill > 0) {
      const recKw = Math.max(1, Math.ceil((nBill / safeTariff) / GENERATION_PER_KW_MONTH));
      setUserKw(recKw);
    } else {
      setUserKw(0);
    }
  };

  const handleKwChange = (val: string) => {
    const clean = val === "" ? "" : val.replace(/^0+(?=\d)/, "");
    setUserKw(clean);
    const nKw = Number(clean) || 0;
    if (nKw > 0) {
      const estimatedBill = Math.round(nKw * GENERATION_PER_KW_MONTH * safeTariff);
      setBill(estimatedBill);
    } else {
      setBill(0);
    }
  };

  return (
    <PageLayout compact>
      <section className="flex flex-1 min-h-[calc(100vh-70px)] lg:h-[calc(100vh-70px)] w-full items-center justify-center bg-[var(--ink)] px-6 pt-20 pb-16 text-white sm:pt-20 sm:pb-12 lg:py-4 lg:px-10">
        <motion.div
          initial={{ opacity: 0, y: 15 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4 }}
          className="mx-auto w-full max-w-7xl my-auto"
        >
          <div className="flex flex-col justify-between gap-1 sm:flex-row sm:items-end">
            <div>
              <p className="text-[11px] font-bold uppercase tracking-[.2em] text-[var(--sun)]">
                Solar calculator · Detailed custom hisaab
              </p>
              <h1 className="display text-2xl leading-tight sm:text-4xl lg:text-4xl">
                A useful first <em className="font-normal text-[var(--sun)]">look at the numbers.</em>
              </h1>
            </div>
            <p className="max-w-sm text-xs leading-5 text-white/60 hidden sm:block">
              Monthly bill, required kW, unit tariff aur plate cost ke detailed financial aur technical stats.
            </p>
          </div>

          <div className="mt-4 grid gap-4 lg:grid-cols-[.92fr_1.08fr]">
            {/* Input Configuration Card */}
            <div className="border border-white/15 bg-white/5 p-4 sm:p-5">
              <div className="grid gap-3 sm:grid-cols-2">
                {/* Monthly Bill Input */}
                <label className="block text-[11px] font-bold uppercase tracking-[.14em] text-white/60">
                  Monthly electricity bill
                  <div className="mt-1.5 flex items-center border-b border-white/40 pb-1">
                    <span className="text-xl text-[var(--sun)] font-bold">₹</span>
                    <input
                      aria-label="Monthly electricity bill"
                      type="number"
                      min="0"
                      placeholder="0"
                      value={bill}
                      onChange={(e) => handleBillChange(e.target.value)}
                      className="w-full bg-transparent px-2 text-xl font-bold outline-none [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
                    />
                  </div>
                </label>

                {/* Direct User Required kW Input */}
                <label className="block text-[11px] font-bold uppercase tracking-[.14em] text-white/60">
                  Required Solar Size (kW)
                  <div className="mt-1.5 flex items-center border-b border-white/40 pb-1">
                    <input
                      aria-label="Required solar system size in kW"
                      type="number"
                      min="0"
                      placeholder="0"
                      value={userKw}
                      onChange={(e) => handleKwChange(e.target.value)}
                      className="w-full bg-transparent px-1 text-xl font-bold text-[var(--sun)] outline-none [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
                    />
                    <span className="text-sm font-bold text-white/60">kW</span>
                  </div>
                </label>
              </div>

              {/* Quick kW Preset Buttons */}
              <div className="mt-2.5 flex items-center gap-1.5 overflow-x-auto pb-1">
                <span className="text-[10px] text-white/40 mr-1">Quick:</span>
                {[1, 2, 3, 5, 10, 15].map((preset) => (
                  <button
                    key={preset}
                    type="button"
                    onClick={() => handleKwChange(String(preset))}
                    className={`px-2 py-0.5 text-[11px] font-bold rounded-xs transition cursor-pointer ${
                      Number(userKw) === preset
                        ? "bg-[var(--sun)] text-[var(--ink)]"
                        : "bg-white/10 text-white/80 hover:bg-white/20"
                    }`}
                  >
                    {preset}kW
                  </button>
                ))}
              </div>

              <div className="mt-3">
                <label className="block text-[11px] font-bold uppercase tracking-[.14em] text-white/60">
                  Property type / Jagah
                  <select
                    value={property}
                    onChange={(event) => setProperty(event.target.value)}
                    className="mt-1.5 w-full border border-white/20 bg-[var(--ink)] p-2 text-xs sm:text-sm text-white outline-none"
                  >
                    <option className="text-white bg-[var(--ink)]">House / Ghar</option>
                    <option className="text-white bg-[var(--ink)]">Shop / Commercial Dukaan</option>
                    <option className="text-white bg-[var(--ink)]">Office</option>
                    <option className="text-white bg-[var(--ink)]">Factory / Industrial</option>
                  </select>
                </label>
              </div>

              {/* Custom Rates: 1 Unit Cost, Plate Price, and Manual Govt Subsidy */}
              <div className="mt-3.5 border-t border-white/15 pt-3">
                <p className="text-[10px] font-bold uppercase tracking-[.14em] text-[var(--sun)] mb-2">
                  Custom rates & subsidy / Manually enter karein
                </p>
                <div className="grid gap-3 sm:grid-cols-2">
                  <label className="block text-[11px] font-semibold text-white/70">
                    1 Unit Cost (Tariff ₹/kWh)
                    <div className="mt-1 flex items-center border border-white/25 bg-black/20 px-2.5 py-1.5">
                      <span className="text-xs text-[var(--sun)] font-bold">₹</span>
                      <input
                        aria-label="Electricity cost per unit"
                        type="number"
                        min="1"
                        max="50"
                        step="0.5"
                        value={tariff}
                        onChange={(event) => {
                          const val = event.target.value;
                          setTariff(val === "" ? "" : val.replace(/^0+(?=\d)/, ""));
                        }}
                        className="w-full bg-transparent px-1.5 text-sm font-bold outline-none [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
                      />
                      <span className="text-[10px] text-white/40">/unit</span>
                    </div>
                  </label>

                  <label className="block text-[11px] font-semibold text-white/70">
                    Solar Plate / System Price (₹/kW)
                    <div className="mt-1 flex items-center border border-white/25 bg-black/20 px-2.5 py-1.5">
                      <span className="text-xs text-[var(--sun)] font-bold">₹</span>
                      <input
                        aria-label="Solar plate price per kW"
                        type="number"
                        min="0"
                        step="1000"
                        value={costPerKw}
                        onChange={(event) => {
                          const val = event.target.value;
                          setCostPerKw(val === "" ? "" : val.replace(/^0+(?=\d)/, ""));
                        }}
                        className="w-full bg-transparent px-1.5 text-sm font-bold outline-none [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
                      />
                      <span className="text-[10px] text-white/40">/kW</span>
                    </div>
                  </label>
                </div>

                {/* Manual Govt Subsidy Input */}
                <div className="mt-2.5">
                  <label className="block text-[11px] font-semibold text-white/70">
                    Government Subsidy Amount (₹) — Write manually
                    <div className="mt-1 flex items-center border border-white/25 bg-black/20 px-2.5 py-1.5">
                      <span className="text-xs text-[var(--sun)] font-bold">₹</span>
                      <input
                        aria-label="Government subsidy amount"
                        type="number"
                        min="0"
                        placeholder="0"
                        value={subsidy}
                        onChange={(event) => {
                          const val = event.target.value;
                          setSubsidy(val === "" ? "" : val.replace(/^0+(?=\d)/, ""));
                        }}
                        className="w-full bg-transparent px-1.5 text-sm font-bold outline-none [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
                      />
                      <span className="text-[10px] text-white/40">subsidy</span>
                    </div>
                  </label>
                </div>
              </div>

              <div className="mt-3 flex items-center justify-between text-[11px] text-white/60 border-t border-white/10 pt-2">
                <span>Rooftop space needed:</span>
                <span className="font-bold text-white">{hasKw ? `~${roofAreaSqFt} sq. ft.` : "-"}</span>
              </div>
            </div>

            {/* Output Card with Enhanced Detailed Breakdown */}
            <div className="bg-[var(--sun)] p-5 text-[var(--ink)] flex flex-col justify-between rounded-none shadow-lg">
              {!hasKw ? (
                <div className="my-auto flex flex-col items-center justify-center py-12 text-center">
                  <span className="text-5xl">☼</span>
                  <h3 className="display mt-3 text-2xl font-bold">kW ya Bill enter karein</h3>
                  <p className="mt-2 max-w-xs text-xs leading-5 opacity-75">
                    Apna required system size (kW) ya monthly electricity bill enter karein aur full detailed estimate dekhein.
                  </p>
                </div>
              ) : (
                <div className="flex flex-col h-full justify-between gap-3">
                  {/* Top Bar: Title & Primary Highlight */}
                  <div>
                    <div className="flex items-center justify-between border-b border-[var(--ink)]/15 pb-2">
                      <div>
                        <p className="text-[10px] font-bold uppercase tracking-[.18em] opacity-75">
                          Detailed Solar Estimate
                        </p>
                        <h3 className="text-lg font-bold leading-tight">
                          {kw} kW Solar System Hisaab
                        </h3>
                      </div>
                      <span className="text-xs font-bold bg-[var(--ink)] text-white px-2.5 py-1">
                        {payback} yrs Payback
                      </span>
                    </div>

                    {/* Hero Investment & Savings Banner */}
                    <div className="mt-3 grid grid-cols-3 gap-2 bg-black/10 p-3 text-center">
                      <div>
                        <p className="text-[10px] font-semibold opacity-65 uppercase tracking-wider">Net Cost</p>
                        <p className="text-base sm:text-lg font-black text-[var(--ink)]">₹{format(netCost)}</p>
                        <p className="text-[9px] opacity-60">after subsidy</p>
                      </div>
                      <div className="border-x border-[var(--ink)]/15">
                        <p className="text-[10px] font-semibold opacity-65 uppercase tracking-wider">Yearly Savings</p>
                        <p className="text-base sm:text-lg font-black text-[var(--teal)]">₹{format(annualSavings)}</p>
                        <p className="text-[9px] opacity-60">₹{format(monthlySavings)}/mo</p>
                      </div>
                      <div>
                        <p className="text-[10px] font-semibold opacity-65 uppercase tracking-wider">25-Yr Profit</p>
                        <p className="text-base sm:text-lg font-black text-[var(--ink)]">₹{format(lifetimeSavings)}</p>
                        <p className="text-[9px] opacity-60">{roiPercent}% ROI</p>
                      </div>
                    </div>

                    {/* Detailed Financial & System Grid */}
                    <div className="mt-3 grid grid-cols-2 sm:grid-cols-4 gap-2 text-xs">
                      <div className="border border-[var(--ink)]/15 bg-white/10 p-2">
                        <p className="text-[10px] opacity-60 font-medium">Gross Cost</p>
                        <p className="font-bold text-sm">₹{format(grossCost)}</p>
                      </div>
                      <div className="border border-[var(--ink)]/15 bg-white/10 p-2">
                        <p className="text-[10px] opacity-60 font-medium">Govt Subsidy</p>
                        <p className="font-bold text-sm text-[#1e6f5c]">
                          {effectiveSubsidy > 0 ? `-₹${format(effectiveSubsidy)}` : "₹0"}
                        </p>
                      </div>
                      <div className="border border-[var(--ink)]/15 bg-white/10 p-2">
                        <p className="text-[10px] opacity-60 font-medium">Daily Power</p>
                        <p className="font-bold text-sm">~{format(dailyGeneration)} Units</p>
                      </div>
                      <div className="border border-[var(--ink)]/15 bg-white/10 p-2">
                        <p className="text-[10px] opacity-60 font-medium">Annual Power</p>
                        <p className="font-bold text-sm">~{format(annualGeneration)} Units</p>
                      </div>
                    </div>

                    {/* Hardware & Engineering Specs Box */}
                    <div className="mt-3 border border-[var(--ink)]/20 bg-white/15 p-2.5">
                      <p className="text-[10px] font-bold uppercase tracking-wider opacity-75 mb-1.5">
                        Technical & Environmental Specifications
                      </p>
                      <div className="grid grid-cols-3 gap-2 text-[11px]">
                        <div>
                          <span className="opacity-60 block text-[10px]">Panels Required:</span>
                          <span className="font-bold">~{panelCount} Panels (540W)</span>
                        </div>
                        <div>
                          <span className="opacity-60 block text-[10px]">Rooftop Space:</span>
                          <span className="font-bold">~{roofAreaSqFt} sq. ft.</span>
                        </div>
                        <div>
                          <span className="opacity-60 block text-[10px]">CO₂ Saved / yr:</span>
                          <span className="font-bold">{format(co2Kg)} kg ({treesCount} 🌲)</span>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Bottom Footer & CTA */}
                  <div className="border-t border-[var(--ink)]/20 pt-2 flex flex-col sm:flex-row items-center justify-between gap-2">
                    <p className="text-[10px] leading-4 opacity-75 text-center sm:text-left">
                      Rate: ₹{safeTariff}/u · ₹{format(numericCostPerKw)}/kW · Subsidy: ₹{format(effectiveSubsidy)}
                    </p>
                    <Link
                      to="/contact"
                      className="inline-flex items-center gap-1.5 bg-[var(--ink)] text-white px-3.5 py-1.5 text-xs font-bold hover:bg-black transition shrink-0"
                    >
                      Book Free Survey & Quote →
                    </Link>
                  </div>
                </div>
              )}
            </div>
          </div>
        </motion.div>
      </section>
    </PageLayout>
  );
}
