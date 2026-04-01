# 📊 Marketing Insights Dashboard

> Interactive marketing analytics dashboard built with R Shiny, inspired by Improvado's Executive Summary view.

---

## 🗂️ Table of Contents

- [Overview](#overview)
- [Key Metrics](#key-metrics)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [How It Works](#how-it-works)
- [Getting Started](#getting-started)
- [Data Model](#data-model)
- [Development Workflow](#development-workflow)

---

## Overview

This dashboard simulates a **cross-channel marketing performance tracker** covering 2 years of data (2022–2023) across 4 channels, 8 campaigns, and 7 data sources. It mirrors the layout and UX of enterprise tools like Improvado, built entirely in R.

**What you can do with it:**
- Filter by Data Source, Channel, Campaign, and Date Range
- Track 8 KPI cards with period-over-period deltas (▲/▼)
- Analyze monthly spend trends across all channels in an interactive line chart
- Drill down into Channel, Data Source, and Campaign performance tables

---

## Key Metrics

The dashboard tracks the core digital marketing funnel:

```
Impressions → Clicks → Conversions
```

| Metric | Definition | Formula |
|---|---|---|
| **Impressions** | Times the ad was displayed | — |
| **CTR** | % of viewers who clicked | `Clicks / Impressions × 100` |
| **CPC** | Cost per click | `Total Spend / Clicks` |
| **Spend** | Total ad investment | `Clicks × CPC` |
| **Conversions** | Valuable actions completed (purchase, signup, etc.) | — |
| **Conversion Rate** | % of clicks that converted | `Conversions / Clicks × 100` |
| **Video Views** | Estimated views (proxy: `Clicks × 3`) | — |

Each KPI card shows the **current period value** alongside a **▲/▼ delta vs. the prior equivalent period** (auto-calculated based on the selected date range).

---

## Tech Stack

| Layer | Package | Purpose |
|---|---|---|
| UI Framework | `shinydashboard` | Layout, sidebar, panels |
| Reactivity | `shiny` | Filters, inputs, outputs |
| Interactive Charts | `echarts4r` | Line chart with tooltip |
| Tables | `DT` | Channel/Source/Campaign tables |
| Data Wrangling | `dplyr`, `lubridate`, `tidyr` | Aggregations, date math |
| Static Prototyping | `ggplot2`, `scales` | Visual validation before Shiny |

---

## How It Works

### Channels & Data Sources

The dataset maps each **channel** to its real-world **data sources**:

| Channel | Data Sources |
|---|---|
| Programmatic | Amazon Ad Server, StackAdapt, Google Display & Video 360 |
| Paid Search | Google Search Ads 360, Bing Ads |
| Paid Social | Facebook, LinkedIn Ads |
| Organic | Google Analytics |

> **Channel** = the medium where the user was reached  
> **Data Source** = the platform that reported the data

### Reactive Chain

```
User filters (Source / Channel / Campaign / Dates)
         │
         ▼
    filtered()   ──── current period data
    prior()      ──── same date span, shifted back (for ▲▼ deltas)
         │
         ▼
      kpi()      ──── aggregated metrics: spend, CTR, CPC, CVR...
         │
    ┌────┴──────────────────────────────────────┐
    ▼                                           ▼
renderUI                               renderEcharts4r
(kpi_row1, kpi_row2)                   (spend_line chart)
                                       renderDT
                                       (channel / source / campaign tables)
```

### Prior Period Logic

The delta (▲/▼) is calculated automatically by shifting the selected date range backward by the same number of days:

```r
span <- as.numeric(end_date - start_date) + 1
prior_start <- start_date - span
prior_end   <- start_date - 1
```

**Example:** Select Jan–Mar 2023 (90 days) → delta compares against Oct–Dec 2022 (previous 90 days).

---

## Getting Started

### Prerequisites

```r
# Required packages (auto-installed on first run)
pkgs <- c("shiny", "shinydashboard", "dplyr", "lubridate",
          "tidyr", "echarts4r", "scales", "DT", "htmltools")
```

### Run the app

```r
# Option 1 — from RStudio
shiny::runApp("marketing_dashboard.R")

# Option 2 — from R console
source("marketing_dashboard.R")
```

### Use your own data

Replace the data generation block at the top of `marketing_dashboard.R` with your real data:

```r
# Replace this:
set.seed(42)
marketing_data <- expand.grid(...) |> mutate(...)

# With this:
marketing_data <- read.csv("your_data.csv")
```

**Required columns:**

| Column | Type | Description |
|---|---|---|
| `date` | Date | `YYYY-MM-DD` |
| `channel` | character | e.g. `"Paid Search"` |
| `data_source` | character | e.g. `"Google Ads"` |
| `campaign` | character | Campaign name |
| `impressions` | numeric | Ad impressions |
| `clicks` | numeric | Total clicks |
| `ctr` | numeric | Click-through rate (0–1) |
| `cpc` | numeric | Cost per click in USD |
| `spend` | numeric | Total spend in USD |
| `conversions` | numeric | Conversion count |

---

## Data Model

The dummy dataset is generated with realistic behavior per channel:

| Channel | Base Impressions | Avg CTR | CPC Range | Conv. Rate |
|---|---|---|---|---|
| Programmatic | 9K–14K/day | ~9% | $1.00–$2.00 | 2–6% |
| Paid Search | 8K–12K/day | ~11% | $2.50–$4.50 | 5–12% |
| Paid Social | 2.5K–4.5K/day | ~10% | $1.50–$3.00 | 3–8% |
| Organic | 2.5K–4.5K/day | ~12% | $0 | 6–15% |

**Seasonality multipliers:**

| Period | Multiplier | Reason |
|---|---|---|
| Nov / Dec | ×1.5 | Holiday season |
| Jun / Jul | ×1.2 | Summer peak |
| Jan / Feb | ×0.8 | Post-holiday drop |
| Rest | ×1.0 | Baseline |

---

## Development Workflow

This project was built **layer by layer**, validating each step before adding complexity:

```
Layer 1 → Dummy Data       Was the data realistic?
Layer 2 → ggplot2          Did the visualizations look right?
Layer 3 → echarts4r        Did the interactivity work correctly?
Layer 4 → Shiny UI         Did the layout match the design target?
Layer 5 → Shiny Server     Did filters propagate to all outputs?
```

See [`workflow_marketing_dashboard.Rmd`](workflow_marketing_dashboard.Rmd) for the full step-by-step documentation with code and explanations for each layer.

---

## Color Palette

```r
CHANNEL_COLORS <- c(
  "Programmatic" = "#6A0DAD",   # Purple
  "Paid Search"  = "#FF4DA6",   # Pink
  "Paid Social"  = "#4DB6E2",   # Light Blue
  "Organic"      = "#FF8C00"    # Orange
)
```

---

*Built with R · shinydashboard · echarts4r*
