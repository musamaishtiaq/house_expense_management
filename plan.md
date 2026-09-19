# Expense Manager — Version Plan

## v1.0.0 — Current functionality

Local, offline household finance tracker (SQLite). No login / cloud sync.

| Area | What it does |
|------|----------------|
| **Home** | Total savings (all-time income − expenses), last 12 months income/expense/savings table, amount privacy (double-tap) |
| **Expense** | Add / edit expenses (category → subcategory, amount, date, description); last 3 months list; monthly aggregate toggle |
| **Income** | Add / edit income tied to a salaried person; last 3 months; monthly aggregate toggle |
| **Category** | CRUD categories; current-month spend per category; open subcategories |
| **Subcategory** | CRUD subcategories under a category; current-month spend |
| **Person** | CRUD salaried persons; current-month income per person |
| **Storage** | Local DB `house_expense.db` (version 1 originally) |

**App version:** `1.0.0+1` (before 1.1 work)

---

## v1.1.0 — New functionality

| Feature | Summary |
|---------|---------|
| **Expense Insight** (merged Hint + Save More) | One screen: **basic need** (avg of last N completed months per category & subcategory) vs **actual this month**; summary totals; tag when category/subcategory exceeds basic need; savings target progress |
| **Hint months** | User selects **3 / 6 / 9 / 12**; current month excluded from averages |
| **Savings target** | Fixed monthly amount only (v1.1) |
| **Settings** | Persist basic prefs in DB (`hint_months`, `monthly_savings_target`) |
| **More** | Bottom nav item → list hub (Expense Insight, Settings; extensible later) |
| **Versions** | App `1.1.0+2`, DB version `2` |

### How Expense Insight works

```
Past expenses (N completed months)
        → average per category / subcategory = Basic need
Current month expenses
        → Actual
Compare → tag if Actual > Basic need
Summary → total basic need vs total actual + savings target progress
```

### Navigation (v1.1)

```
Bottom nav:  Home | Category | Person | More
                                    └── MoreScreen
                                         ├── Expense Insight
                                         └── Settings
```

---

## Implementation plan & progress

### Complete flow (target)

1. Upgrade app + DB; store settings in `app_settings`.
2. Add **More** entry point and menu list.
3. Build **Expense Insight** (basic need vs actual, tags, summary, months control).
4. Build **Settings** (hint months + savings target saved to DB; shared with Insight).

### Steps checklist

| Step | Description | Status |
|------|-------------|--------|
| **1** | Bump app to `1.1.0+2` and DB to version `2`; add `app_settings` table + `AppSettings` model; `getAppSettings` / `updateAppSettings`; seed defaults (`hint_months=3`, `monthly_savings_target=0`) | ✅ Done |
| **2** | Add **More** to bottom navigation (right side); create `MoreScreen` list with entries for **Expense Insight** and **Settings** (placeholders OK) | ✅ Done |
| **3** | Implement **Expense Insight** screen: load settings; months dropdown (3/6/9/12); compute basic need (avg, exclude current month) by category & subcategory; show actual this month; summary totals; overspend tags; savings progress vs target | ✅ Done |
| **4** | Implement **Settings** screen: edit hint months + monthly savings target; save to DB; keep in sync with Insight when months/target change | ✅ Done |

### Progress summary

- **Done:** 4 / 4 steps  
- **Remaining:** None — v1.1.0 planned work complete  

Update this checklist as each step is completed.
