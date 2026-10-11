# Dairy Farm Management System - UI Design System Specification

## 1. Design Philosophy & Aesthetic Foundation

The UI design system embodies a **clean, premium, light-themed agrarian aesthetic**, faithfully replicating the reference implementation demonstrated in the verification recordings (*Kaivalya Dairy*):
* **Crisp & Trustworthy:** High readability with distinct hierarchy, restrained shadows, and subtle micro-borders.
* **Functional Efficiency:** Fast data entry for field operators, single-hand reachability on mobile devices, and high contrast under daylight conditions.
* **Responsive & Adaptive:** Gracefully scales across compact Android smartphones (320dp width), standard modern phones (360–430dp), phablets, and tablets (7" and 10"+).

---

## 2. Design Tokens

### 2.1 Color Palette

| Token Name | Hex Code | Purpose / Usage |
| :--- | :--- | :--- |
| `color-primary-900` | `#0f3923` | Active sidebar backgrounds, primary brand anchors |
| `color-primary-800` | `#165a36` | Sidebar navigation, drawer headers |
| `color-primary-700` | `#1b6e42` | Primary buttons (`+ Record milking`, `+ Add ...`), active tabs |
| `color-primary-600` | `#238652` | Button hover/pressed states, interactive chips |
| `color-primary-50` | `#f0fdf4` | Selected item highlights, active chip backgrounds |
| `color-surface-bg` | `#f8fafc` | Screen background canvas (slate-50) |
| `color-surface-card` | `#ffffff` | Elevated cards, dialog sheets, tables |
| `color-surface-border` | `#e2e8f0` | Dividers, card borders, inactive input outlines |
| `color-text-main` | `#0f172a` | Primary headings, metrics numbers, body text |
| `color-text-muted` | `#64748b` | Field labels, secondary descriptions, timestamps |
| `color-status-success` | `#15803d` | `Accepted`, `Active`, `Eligible`, positive yield |
| `color-status-warning` | `#b45309` | `Hold`, `Pending`, `Withheld`, gestation check alerts |
| `color-status-danger` | `#b91c1c` | `Rejected`, `Out of Stock`, `Expired`, active withdrawal alert |

### 2.2 Typography (Font Family: Inter / Roboto)

| Style | Size | Weight | Line Height | Usage |
| :--- | :--- | :--- | :--- | :--- |
| **Headline 1** | 22sp | 700 (Bold) | 28sp | Screen titles (e.g. "BMC & milk intake", "Herd & calves") |
| **Headline 2** | 18sp | 600 (Semi-bold) | 24sp | Card section headers, modal headers |
| **Headline 3** | 16sp | 600 (Semi-bold) | 22sp | Group headers, item names |
| **Metric Large** | 26sp | 700 (Bold) | 32sp | Hero KPI numbers (e.g. `₹1,616.67`, `25 L`) |
| **Metric Medium** | 18sp | 700 (Bold) | 24sp | Secondary card counters (e.g. `1 Lactating`, `0 kg`) |
| **Body Large** | 15sp | 400 (Regular) | 20sp | Form inputs, table cells |
| **Body Medium** | 13sp | 400 (Regular) | 18sp | Helper text, secondary table column |
| **Caption** | 11sp | 500 (Medium) | 14sp | Tags, badges, footnotes ("India time", revision) |

### 2.3 Radii & Elevation

* **Border Radii:**
  * Chips & Pills: `24dp` (Fully rounded)
  * Action Buttons: `8dp`
  * Cards & Containers: `12dp`
  * Bottom Sheets & Modal Dialogs: `16dp` (top corners)
* **Shadows & Elevation:**
  * Card Elevation: `0 1px 3px rgba(0, 0, 0, 0.05), 0 1px 2px rgba(0, 0, 0, 0.03)`
  * Modal Elevation: `0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.05)`

---

## 3. Core Component Patterns

### 3.1 Branded App Bar & Navigation Drawer
* **Sidebar Drawer:**
  * Background: Deep Emerald Green (`#0f3923` to `#165a36`).
  * Header: Circular/Shield brand logo, company name ("Kaivalya Dairy"), location ("Dandiri · Odisha").
  * Section Headers: Subtle uppercase label with muted opacity (`YOUR DAIRY`, `MILK TO MARKET`, `BUSINESS`).
  * Navigation Tiles: Left icon + title; active tile highlighted with lighter emerald pill (`#1b6e42`) and active dot.
* **Top App Bar:**
  * Hamburger menu trigger (left).
  * Current Module title.
  * Right action: User profile avatar / Sign out button.

### 3.2 Metric & KPI Cards
* Card layout: Surface white with 1dp border (`#e2e8f0`).
* Label: 12sp muted uppercase text.
* Value: Bold high-contrast metric.
* Subtitle: Micro-badge or comparative footnote (e.g. `0% vs previous period`).

### 3.3 Form Inputs & Modals
* **Dialog / Sheet Presentation:**
  * Header with title, brief subtext, and close icon (`✕`).
  * Mandatory indicator: Red asterisk (`*`).
  * Notice banner: *"Saved records update the connected stock ledger. Required fields are marked \*."*
  * Input fields: Outlined style with 1dp border, subtle focus ring (`#1b6e42`).
  * Footer: Secondary `Cancel` button + Primary `Save record` button (Green fill).
* **Date Pickers:**
  * Standard calendar modal with selected day highlighted in primary brand green.

### 3.4 Responsive Adaptation Rules

1. **Small Phones (Width < 360dp):**
   * KPI stat grids collapse into a single column or 2-column compact grid.
   * Modals take 100% full screen width.
2. **Standard Phones (Width 360dp – 600dp):**
   * KPI stat cards in 2-column grid.
   * Tables enable horizontal scrolling with fixed leftmost identifier column.
3. **Tablets (Width $\ge$ 600dp):**
   * Persistent left navigation sidebar replaces collapsible drawer.
   * Dashboard renders in 4-column KPI cards and split-pane view (Master-Detail).
