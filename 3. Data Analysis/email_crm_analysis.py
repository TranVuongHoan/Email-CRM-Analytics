# =============================================================================
# Email CRM Marketing — Python EDA Script
# Dataset : 02_Email_CRM_Marketing - 2_CLEANED_DATA.csv
# Date    : 2026-05-17
# =============================================================================

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import seaborn as sns
from pathlib import Path

# ── Paths ─────────────────────────────────────────────────────────────────────
BASE  = Path(__file__).parent.parent
DATA  = BASE / "uploads" / "02_Email_CRM_Marketing - 2_CLEANED_DATA.csv"
OUT   = Path(__file__).parent

# ── Load & clean ──────────────────────────────────────────────────────────────
df = pd.read_csv(DATA, thousands=",")
df["Send_Date"] = pd.to_datetime(df["Send_Date"], dayfirst=True, errors="coerce")

# Rename % columns for safe attribute access
df.rename(columns={
    "Delivery_Rate_%":  "Delivery_Rate_pct",
    "Bounce_Rate_%":    "Bounce_Rate_pct",
    "Open_Rate_%":      "Open_Rate_pct",
    "CTR_%":            "CTR_pct",
    "CTOR_%":           "CTOR_pct",
    "Unsub_Rate_%":     "Unsub_Rate_pct",
    "Spam_Rate_%":      "Spam_Rate_pct",
    "Conv_Rate_%":      "Conv_Rate_pct",
}, inplace=True)

print(f"Dataset: {df.shape[0]:,} rows × {df.shape[1]} columns")
print(f"Date range: {df['Send_Date'].min().date()} → {df['Send_Date'].max().date()}")
print(f"Brands: {df['Brand'].nunique()}  |  Campaign types: {df['Campaign_Type'].nunique()}")
print(f"Total revenue: {df['Revenue_VND'].sum()/1e9:.1f}B VND  |  Emails sent: {df['Emails_Sent'].sum()/1e6:.1f}M")

# ── Palette ───────────────────────────────────────────────────────────────────
COLORS = ["#2563eb","#10b981","#f59e0b","#ef4444","#8b5cf6",
          "#06b6d4","#ec4899","#f97316","#84cc16","#6366f1"]
sns.set_theme(style="whitegrid", palette=COLORS, font_scale=1.05)
plt.rcParams.update({"figure.dpi":130, "axes.spines.top":False, "axes.spines.right":False})

# ==============================================================================
# CHART 1 — Campaign Type: Revenue per Email vs Conv Rate (bubble)
# ==============================================================================
fig, axes = plt.subplots(1, 2, figsize=(14, 5))
fig.suptitle("BQ1 · Campaign Type Performance", fontsize=14, fontweight="bold", y=1.02)

ct = df.groupby("Campaign_Type").agg(
    revenue_B=("Revenue_VND", lambda x: x.sum()/1e9),
    conv_rate=("Conv_Rate_pct","mean"),
    rev_per_email=("Revenue_per_Email_VND","mean"),
    campaigns=("Email_ID","count"),
    unsub_rate=("Unsub_Rate_pct","mean")
).reset_index().sort_values("revenue_B", ascending=False)

# Bar: total revenue
ax = axes[0]
bars = ax.barh(ct["Campaign_Type"], ct["revenue_B"], color=COLORS[:len(ct)], edgecolor="white")
ax.set_xlabel("Revenue (Billion VND)")
ax.set_title("Total Revenue by Campaign Type", fontsize=12)
ax.bar_label(bars, fmt="%.0fB", padding=4, fontsize=9)
ax.invert_yaxis()

# Bar: Revenue per Email
ax = axes[1]
ct2 = ct.sort_values("rev_per_email", ascending=False)
bars2 = ax.barh(ct2["Campaign_Type"], ct2["rev_per_email"]/1000, color=COLORS[:len(ct2)], edgecolor="white")
ax.set_xlabel("Revenue per Email (K VND)")
ax.set_title("Revenue per Email by Campaign Type", fontsize=12)
ax.bar_label(bars2, fmt="%.0fK", padding=4, fontsize=9)
ax.invert_yaxis()

plt.tight_layout()
fig.savefig(OUT / "eq1_campaign_type.png", bbox_inches="tight")
plt.close()
print("✓ eq1_campaign_type.png")

# ==============================================================================
# CHART 2 — Send Timing: Day × Hour heatmap
# ==============================================================================
fig, axes = plt.subplots(1, 2, figsize=(14, 5))
fig.suptitle("BQ2 · Send Timing Optimization", fontsize=14, fontweight="bold")

day_order = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
sd = df.groupby("Send_Day").agg(
    open_rate=("Open_Rate_pct","mean"),
    conv_rate=("Conv_Rate_pct","mean"),
    revenue_B=("Revenue_VND", lambda x: x.sum()/1e9)
).reindex(day_order).reset_index()

ax = axes[0]
x = range(len(sd))
width = 0.4
b1 = ax.bar([i - width/2 for i in x], sd["open_rate"], width, label="Open Rate %", color="#2563eb", alpha=0.85)
b2 = ax.bar([i + width/2 for i in x], sd["conv_rate"]*5, width, label="Conv Rate % (×5)", color="#10b981", alpha=0.85)
ax.set_xticks(list(x))
ax.set_xticklabels([d[:3] for d in sd["Send_Day"]], rotation=0)
ax.set_ylabel("Rate (%)")
ax.set_title("Open & Conv Rate by Send Day", fontsize=12)
ax.legend(fontsize=9)
ax.bar_label(b2, fmt="%.1f%%", padding=3, fontsize=8)

# Hour bucket
df["hour_bucket"] = pd.cut(df["Send_Hour"], bins=[0,6,9,12,15,18,21,24],
    labels=["0-6h","6-9h","9-12h","12-15h","15-18h","18-21h","21-24h"])
sh = df.groupby("hour_bucket", observed=True).agg(
    open_rate=("Open_Rate_pct","mean"),
    conv_rate=("Conv_Rate_pct","mean"),
    campaigns=("Email_ID","count")
).reset_index()

ax = axes[1]
c = ax.bar(sh["hour_bucket"].astype(str), sh["conv_rate"],
           color=["#2563eb" if v==sh["conv_rate"].max() else "#93c5fd" for v in sh["conv_rate"]],
           edgecolor="white")
ax.set_xlabel("Send Hour Window")
ax.set_ylabel("Avg Conv Rate (%)")
ax.set_title("Conversion Rate by Send Hour", fontsize=12)
ax.bar_label(c, fmt="%.2f%%", padding=3, fontsize=9)

plt.tight_layout()
fig.savefig(OUT / "eq2_send_timing.png", bbox_inches="tight")
plt.close()
print("✓ eq2_send_timing.png")

# ==============================================================================
# CHART 3 — Personalization, Emoji & A/B Testing Impact
# ==============================================================================
fig, axes = plt.subplots(1, 3, figsize=(15, 5))
fig.suptitle("BQ3 · Personalization & Testing Impact", fontsize=14, fontweight="bold")

metrics = ["open_rate","ctr","conv_rate"]
labels  = ["Open Rate %","CTR %","Conv Rate %"]

for ax, (grp_col, title, cols) in zip(axes, [
    ("Has_Personalization","Personalization Effect",["#2563eb","#10b981"]),
    ("Has_Emoji_Subject",  "Emoji in Subject",      ["#f59e0b","#8b5cf6"]),
    ("AB_Test",            "A/B Testing",           ["#ef4444","#06b6d4"])
]):
    g = df.groupby(grp_col)[["Open_Rate_pct","CTR_pct","Conv_Rate_pct"]].mean().reset_index()
    g.columns = [grp_col,"open_rate","ctr","conv_rate"]
    x = np.arange(len(metrics))
    w = 0.35
    for i, (_, row) in enumerate(g.iterrows()):
        vals = [row.open_rate, row.ctr, row.conv_rate]
        bars = ax.bar(x + (i-0.5)*w, vals, w, label=row[grp_col], color=cols[i], alpha=0.88)
        ax.bar_label(bars, fmt="%.1f", padding=2, fontsize=8)
    ax.set_xticks(x)
    ax.set_xticklabels(labels, fontsize=9)
    ax.set_title(title, fontsize=12)
    ax.legend(fontsize=9)
    ax.set_ylabel("Rate (%)")

plt.tight_layout()
fig.savefig(OUT / "eq3_personalization_testing.png", bbox_inches="tight")
plt.close()
print("✓ eq3_personalization_testing.png")

# ==============================================================================
# CHART 4 — CRM Stage Funnel
# ==============================================================================
fig, axes = plt.subplots(1, 2, figsize=(13, 5))
fig.suptitle("BQ4 · CRM Stage Performance", fontsize=14, fontweight="bold")

crm = df.groupby("CRM_Stage").agg(
    open_rate=("Open_Rate_pct","mean"),
    conv_rate=("Conv_Rate_pct","mean"),
    revenue_B=("Revenue_VND", lambda x: x.sum()/1e9),
    unsub_rate=("Unsub_Rate_pct","mean")
).reset_index().sort_values("revenue_B", ascending=False)

ax = axes[0]
bars = ax.bar(crm["CRM_Stage"], crm["revenue_B"], color=COLORS[:len(crm)], edgecolor="white")
ax.set_ylabel("Revenue (B VND)")
ax.set_title("Revenue by CRM Stage", fontsize=12)
ax.bar_label(bars, fmt="%.0fB", padding=3, fontsize=9)
ax.tick_params(axis="x", rotation=20)

ax = axes[1]
ax2 = ax.twinx()
lns1 = ax.bar(crm["CRM_Stage"], crm["conv_rate"], color="#2563ebaa", label="Conv Rate %", edgecolor="white")
lns2 = ax2.plot(crm["CRM_Stage"], crm["unsub_rate"], "o--", color="#ef4444", linewidth=2, markersize=8, label="Unsub Rate %")
ax.set_ylabel("Conv Rate (%)", color="#2563eb")
ax2.set_ylabel("Unsub Rate (%)", color="#ef4444")
ax.set_title("Conv Rate vs Unsub Rate by CRM Stage", fontsize=12)
ax.tick_params(axis="x", rotation=20)
lines = [lns1] + lns2
ax.legend([lns1, lns2[0]], ["Conv Rate %","Unsub Rate %"], fontsize=9)

plt.tight_layout()
fig.savefig(OUT / "eq4_crm_stage.png", bbox_inches="tight")
plt.close()
print("✓ eq4_crm_stage.png")

# ==============================================================================
# CHART 5 — Brand Performance
# ==============================================================================
fig, axes = plt.subplots(1, 2, figsize=(14, 5))
fig.suptitle("BQ5 · Brand Performance", fontsize=14, fontweight="bold")

br = df.groupby("Brand").agg(
    revenue_B=("Revenue_VND", lambda x: x.sum()/1e9),
    conv_rate=("Conv_Rate_pct","mean"),
    open_rate=("Open_Rate_pct","mean"),
    rev_per_email=("Revenue_per_Email_VND","mean")
).reset_index().sort_values("revenue_B", ascending=False)

ax = axes[0]
bars = ax.barh(br["Brand"], br["revenue_B"], color=COLORS[:len(br)], edgecolor="white")
ax.set_xlabel("Revenue (B VND)")
ax.set_title("Total Revenue by Brand", fontsize=12)
ax.bar_label(bars, fmt="%.0fB", padding=4, fontsize=9)
ax.invert_yaxis()

ax = axes[1]
sc = ax.scatter(br["open_rate"], br["conv_rate"],
                s=br["rev_per_email"]/200, c=COLORS[:len(br)], alpha=0.8, edgecolors="white", linewidth=1.5)
for _, row in br.iterrows():
    ax.annotate(row.Brand, (row.open_rate, row.conv_rate), textcoords="offset points",
                xytext=(6,4), fontsize=8.5)
ax.set_xlabel("Open Rate (%)")
ax.set_ylabel("Conv Rate (%)")
ax.set_title("Open Rate vs Conv Rate\n(bubble = Rev/Email)", fontsize=12)

plt.tight_layout()
fig.savefig(OUT / "eq5_brand_performance.png", bbox_inches="tight")
plt.close()
print("✓ eq5_brand_performance.png")

# ==============================================================================
# CHART 6 — Target Segment Analysis
# ==============================================================================
fig, axes = plt.subplots(1, 2, figsize=(14, 5))
fig.suptitle("BQ6 · Target Segment Performance", fontsize=14, fontweight="bold")

seg = df.groupby("Target_Segment").agg(
    conv_rate=("Conv_Rate_pct","mean"),
    open_rate=("Open_Rate_pct","mean"),
    revenue_B=("Revenue_VND", lambda x: x.sum()/1e9),
    unsub_rate=("Unsub_Rate_pct","mean")
).reset_index().sort_values("conv_rate", ascending=False)

ax = axes[0]
bars = ax.barh(seg["Target_Segment"], seg["conv_rate"],
               color=["#10b981" if v >= 4.0 else "#2563eb" if v >= 3.5 else "#ef4444" for v in seg["conv_rate"]],
               edgecolor="white")
ax.set_xlabel("Avg Conv Rate (%)")
ax.set_title("Conv Rate by Segment\n(green=high, red=low)", fontsize=12)
ax.bar_label(bars, fmt="%.2f%%", padding=4, fontsize=9)
ax.invert_yaxis()

ax = axes[1]
bars2 = ax.barh(seg.sort_values("revenue_B",ascending=False)["Target_Segment"],
                seg.sort_values("revenue_B",ascending=False)["revenue_B"],
                color=COLORS[:len(seg)], edgecolor="white")
ax.set_xlabel("Revenue (B VND)")
ax.set_title("Total Revenue by Segment", fontsize=12)
ax.bar_label(bars2, fmt="%.0fB", padding=4, fontsize=9)
ax.invert_yaxis()

plt.tight_layout()
fig.savefig(OUT / "eq6_segment.png", bbox_inches="tight")
plt.close()
print("✓ eq6_segment.png")

# ==============================================================================
# CHART 7 — Monthly Trend
# ==============================================================================
fig, ax1 = plt.subplots(figsize=(13, 5))
fig.suptitle("BQ7 · Monthly Email Performance Trend", fontsize=14, fontweight="bold")

mo = df.groupby("Month").agg(
    revenue_B=("Revenue_VND", lambda x: x.sum()/1e9),
    open_rate=("Open_Rate_pct","mean"),
    conv_rate=("Conv_Rate_pct","mean")
).reset_index()
months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]

ax2 = ax1.twinx()
bars = ax1.bar(months, mo["revenue_B"], color="#2563ebaa", label="Revenue (B VND)", edgecolor="white")
ax1.set_ylabel("Revenue (B VND)", color="#2563eb")
ax1.tick_params(axis="y", colors="#2563eb")

l1, = ax2.plot(months, mo["open_rate"], "o-", color="#f59e0b", linewidth=2.5, markersize=7, label="Open Rate %")
l2, = ax2.plot(months, mo["conv_rate"]*5, "s--", color="#10b981", linewidth=2.5, markersize=7, label="Conv Rate % (×5)")
ax2.set_ylabel("Rate (%)", color="#374151")
ax2.tick_params(axis="y")

handles = [plt.Rectangle((0,0),1,1,color="#2563ebaa"), l1, l2]
ax1.legend(handles, ["Revenue (B VND)","Open Rate %","Conv Rate % (×5)"], loc="upper right", fontsize=9)

plt.tight_layout()
fig.savefig(OUT / "eq7_monthly_trend.png", bbox_inches="tight")
plt.close()
print("✓ eq7_monthly_trend.png")

# ==============================================================================
# CHART 8 — Deliverability Health (Bounce, Unsub, Spam)
# ==============================================================================
fig, axes = plt.subplots(1, 3, figsize=(15, 5))
fig.suptitle("BQ8 · Deliverability Health Metrics", fontsize=14, fontweight="bold")

for ax, col, title, color in zip(axes,
    ["Bounce_Rate_pct","Unsub_Rate_pct","Spam_Rate_pct"],
    ["Bounce Rate by Campaign Type","Unsub Rate by Campaign Type","Spam Rate by Campaign Type"],
    ["#ef4444","#f59e0b","#8b5cf6"]
):
    g = df.groupby("Campaign_Type")[col].mean().sort_values(ascending=False)
    bars = ax.barh(g.index, g.values, color=color, alpha=0.8, edgecolor="white")
    ax.bar_label(bars, fmt="%.2f%%", padding=3, fontsize=8)
    ax.set_title(title, fontsize=11)
    ax.set_xlabel("Rate (%)")
    ax.invert_yaxis()

plt.tight_layout()
fig.savefig(OUT / "eq8_deliverability.png", bbox_inches="tight")
plt.close()
print("✓ eq8_deliverability.png")

print("\n✅ All 8 charts saved to Output/")
