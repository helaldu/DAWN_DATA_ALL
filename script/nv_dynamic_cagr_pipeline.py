"""
================================================================================
NEVADA MINOR REVENUE PIPELINE - QUARTERLY TRACKING & STATE COLOR SCHEME (v13)
================================================================================
Description:
    Reads transaction history from 'data/dawn_revenue_accounts_combined_history.csv'
    
    1. Parses the 'Date' column into sequential Year-Quarter segments (e.g., 2024Q1).
    2. Groups and summarizes granular transaction volumes into quarterly buckets.
    3. Extracts trailing quarterly growth trend variations.
    4. Projects 12 sequential future quarters (3-year horizon: 2027Q1 - 2029Q4).
    5. Applies the Nevada State Department Palette across all visualization engines.
    6. Outputs quarterly risk ribbon charts and detailed matrix sheets.
================================================================================
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os

# ==============================================================================
# 1. ARCHITECTURE SETUP & ENHANCED COLOR DEFINITIONS
# ==============================================================================
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, "data")
RESULTS_DIR = os.path.join(BASE_DIR, "results")
PLOTS_DIR = os.path.join(RESULTS_DIR, "plots")

os.makedirs(PLOTS_DIR, exist_ok=True)

# NEVADA STATE DEPARTMENT PALETTE MATRICES
COLOR_HIST = "#0A2540"      # Deep Nevada Navy
COLOR_BASE = "#2E5A44"      # Sagebrush Green
COLOR_STRESS = "#991B1B"    # Stagflation Crimson
COLOR_GRID = "#CBD5E1"      # Silver State Accent
COLOR_RIBBON = "#FEE2E2"    # Soft Exposure Shading

raw_ledger_csv = os.path.join(DATA_DIR, "dawn_revenue_accounts_combined_history.csv")

if not os.path.exists(raw_ledger_csv):
    raise FileNotFoundError(f"[ERROR] Target ledger asset missing! Path check failed: '{raw_ledger_csv}'")

print(f"[START] Processing dynamic multi-period quarterly data pipeline: '{raw_ledger_csv}'")
ledger_df = pd.read_csv(raw_ledger_csv)
ledger_df.columns = ledger_df.columns.str.strip()

# Isolate Minor portfolios
minor_df = ledger_df[ledger_df['Type'].str.strip() == 'Minor'].copy()

# ==============================================================================
# 2. CHRONOLOGICAL PARSING & QUARTERLY AGGREGATION
# ==============================================================================
print("[ENGINE] Transforming transaction date indices into sequential quarters...")
# Convert strings to robust timestamps and isolate Year-Quarter periods
minor_df['ParsedDate'] = pd.to_datetime(minor_df['Date'], errors='coerce')
minor_df['Quarter'] = minor_df['ParsedDate'].dt.to_period('Q')

minor_df['Amount'] = pd.to_numeric(minor_df['Amount'], errors='coerce').fillna(0.0)
minor_df['GL Number'] = minor_df['GL Number'].astype(str).str.strip()

# Aggregate transaction details directly into chronological quarters
quarterly_pivot = minor_df.groupby(['GL Number', 'Quarter'])['Amount'].sum().unstack(fill_value=0.0)

available_quarters = sorted(list(quarterly_pivot.columns))
if len(available_quarters) < 4:
    raise ValueError("[ERROR] Ingested history must span at least 4 quarters to extract seasonal trajectories.")

start_q = available_quarters[0]
end_q = available_quarters[-1]
total_quarters_delta = (end_q.year - start_q.year) * 4 + (end_q.quarter - start_q.quarter)

print(f"[INFO] Timeline identified from {start_q} to {end_q} ({total_quarters_delta} historical intervals).")

# Calculate compounded trailing quarterly growth limits
calculated_trends = {}
for gl_code, rows in quarterly_pivot.iterrows():
    start_val = rows[start_q]
    end_val = rows[end_q]
    
    if start_val > 0 and end_val > 0 and total_quarters_delta > 0:
        quarterly_cagr = (end_val / start_val) ** (1.0 / total_quarters_delta) - 1.0
        # Cap high frequency growth swings to protect long-term tracking simulations
        quarterly_cagr = max(min(quarterly_cagr, 0.04), -0.04)
    else:
        quarterly_cagr = 0.0035  # Standard fractional trend adjuster placeholder
        
    calculated_trends[gl_code] = {
        "baseline_stock": end_val,
        "quarterly_growth_rate": quarterly_cagr,
        "history_quarters": [str(q) for q in available_quarters],
        "history_values": [rows[q] for q in available_quarters]
    }

sector_labels = {
    "3113": "Business license fees", "3052": "Cigarette tax", "3130": "Corporate license fees",
    "3066": "Short term auto lease", "3050": "Liquor tax", "3073": "Transportation loan excise tax",
    "3053": "Other tobacco tax", "3152": "Securities fees", "3101": "Insurance license fees",
    "3002": "State share LSST", "3003": "State share BCCRT", "3004": "State share SCCRT",
    "3005": "Public transport tax (uber/lyft)", "3113-C": "Court administration assessment fees",
    "3047": "Expired slot machine voucher", "3044": "Non-residential slot", 
    "3043": "Flat fee restricted slot", "3042": "Gaming penalties", "3075": "Lodging tax", 
    "3276": "Cost recovery plan charge"
}

# ==============================================================================
# 3. 12-QUARTER HORIZON PROJECTIONS (3 YEARS OUT)
# ==============================================================================
print("[ENGINE] Generating 12-quarter outlook grids and corporate style plots...")
forecast_rows = []

# Generate full list of next 12 sequential future quarters starting from 2027Q1
future_quarters = []
start_year = 2027
for yr in range(start_year, start_year + 3):
    for qtr in range(1, 5):
        future_quarters.append(f"{yr}Q{qtr}")

for gl_code, data in calculated_trends.items():
    name = sector_labels.get(gl_code, f"GL Sector {gl_code} (Unclassified)")
    base = data["baseline_stock"]
    q_growth = data["quarterly_growth_rate"]
    
    # --- Quarterly Baseline Trajectory Engine ---
    v_base = base
    p_base = []
    for qtr in future_quarters:
        v_base *= (1 + q_growth)
        p_base.append(v_base)
        
    # --- Quarterly Stress Scenario Engine ---
    v_stress = base
    p_stress = []
    stress_modifier = -0.015 if q_growth < 0 else -0.008  # Micro quarterly downward adjustment factor
    for qtr in future_quarters:
        v_stress *= (1 + q_growth + stress_modifier)
        p_stress.append(v_stress)
        
    # --------------------------------------------------------------------------
    # CORPORATE PLOTTER ENGAGEMENT LAYER (STATE BALANCES)
    # --------------------------------------------------------------------------
    fig, ax = plt.subplots(figsize=(9, 5))
    
    h_qtrs = data["history_quarters"]
    h_vals = [v / 1e6 for v in data["history_values"]]
    
    # Plot historical actual markers using Deep Nevada Navy
    ax.plot(h_qtrs, h_vals, marker='o', color=COLOR_HIST, linewidth=2.5, label='Historical Actuals (Ledger)')
    
    # Append the last actual element onto the front of forecast streams to tie line graphs together
    f_qtrs = [h_qtrs[-1]] + future_quarters
    f_vals_base = [h_vals[-1]] + [v / 1e6 for v in p_base]
    f_vals_stress = [h_vals[-1]] + [v / 1e6 for v in p_stress]
    
    # Map scenarios using corporate color specifications
    ax.plot(f_qtrs, f_vals_base, linestyle='-', marker='^', color=COLOR_BASE, linewidth=1.8, label='Sagebrush Baseline Trend')
    ax.plot(f_qtrs, f_vals_stress, linestyle='-', marker='v', color=COLOR_STRESS, linewidth=1.8, label='Stagflation Stress Bound')
    
    # Ribbon Corridor Fill
    ax.fill_between(f_qtrs, f_vals_base, f_vals_stress, color=COLOR_RIBBON, alpha=0.7, label='Budgetary Exposure Ribbon')
    
    # Apply official formatting
    ax.set_title(f"State of Nevada | Revenue Horizon Exposure Profile\nGL Account: {gl_code} ({name})", fontsize=11, fontweight='bold', pad=12, color=COLOR_HIST)
    ax.set_ylabel("Quarterly Net Collections ($ Millions)", fontsize=9, fontweight='bold', color=COLOR_HIST)
    ax.set_xlabel("Sequential Financial Reporting Interval (Year-Quarter)", fontsize=9, fontweight='bold', color=COLOR_HIST)
    
    # Clean x-axis markers layout clutter by skipping labels dynamically if history is deep
    ax.set_xticks(h_qtrs + future_quarters)
    ticks_labels = h_qtrs + future_quarters
    visible_labels = [label if idx % 2 == 0 else "" for idx, label in enumerate(ticks_labels)]
    ax.set_xticklabels(visible_labels, rotation=45, fontsize=8)
    
    ax.grid(True, linestyle='--', color=COLOR_GRID, alpha=0.7)
    ax.legend(loc='best', fontsize=8.5, frameon=True, facecolor='#ffffff', edgecolor=COLOR_GRID)
    
    plt.tight_layout()
    plt.savefig(os.path.join(PLOTS_DIR, f"gl_{gl_code}_quarterly_risk.png"), dpi=200)
    plt.close()
    
    # Store calculated quarterly intervals for database matrices (Summarize to annual columns for table scanning efficiency)
    forecast_rows.append({
        "GL Code": gl_code, "Sector Description": name, "Quarterly Trend": f"{q_growth*100:+.2f}%",
        "2027 Q1 Base ($)": p_base[0], "2027 Q1 Stress ($)": p_stress[0],
        "2028 Q1 Base ($)": p_base[4], "2028 Q1 Stress ($)": p_stress[4],
        "2029 Q1 Base ($)": p_base[8], "2029 Q1 Stress ($)": p_stress[8],
        # Keep full dataset lists to pass cleanly into our text summary tables
        "_full_base": p_base, "_full_stress": p_stress
    })

# Export high-frequency records matrix out to disk path
output_df = pd.DataFrame(forecast_rows)
# Clean internal reference tracking columns from the final exported file
export_df = output_df.drop(columns=["_full_base", "_full_stress"])
output_csv = os.path.join(RESULTS_DIR, "nv_minor_revenue_quarterly_forecast.csv")
export_df.to_csv(output_csv, index=False)
print(f"[SUCCESS] High-frequency quarterly dataset matrix written to: '{output_csv}'")

# ==============================================================================
# 4. INDUSTRIAL REPORTING INTERFACE - HIGH REFRESH TEXT TABLES

Print(--- TABLE 1: HIGHLIGHTING FISCAL YEAR BASELINE TARGET BY FIRST QUARTER MARKERS ---)

print("\n" + "="*100)
print(f" {'GL CODE':<9} | {'SECTOR DESCRIPTION':<34} | {'2027 Q1 BASE':<14} | {'2028 Q1 BASE':<14} | {'2029 Q1 BASE':<14} ")
print("="*100)
for r in forecast_rows:
    print(f" {r['GL Code']:<9} | {r['Sector Description'][:34]:<34} | ${r['2027 Q1 Base ($)']/1e6:12,.2f}M | ${r['2028 Q1 Base ($)']/1e6:12,.2f}M | ${r['2029 Q1 Base ($)']/1e6:12,.2f}M")
print("="*100)

print(--- TABLE 2: ENHANCED GRID COMPARING TOTAL CUMULATIVE SIMULATED HORIZON VOLUMES ---)

print("\n" + "="*112)
print(f" {'GL CODE':<8} | {'SECTOR DESCRIPTION':<30} | {'3-YR CUM BASE':<16} | {'3-YR CUM STRESS':<16} | {'NET REVENUE GAP':<16} ")
print("="*112)
for r in forecast_rows:
    cum_base = sum(r["_full_base"])
    cum_stress = sum(r["_full_stress"])
    gap = cum_base - cum_stress
    print(f" {r['GL Code']:<8} | {r['Sector Description'][:30]:<30} | ${cum_base/1e6:13,.2f}M | ${cum_stress/1e6:13,.2f}M | -${gap/1e6:12,.2f}M")
print("="*112)
print("[INFO] Nevada corporate-styled risk ribbon charts updated in 'results/plots/'.\n")