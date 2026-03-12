---
name: health-analysis
description: Analyze DNA/genetic data and lab results to produce personalized health recommendations.
type: command
---

Analyze DNA/genetic data and lab results to produce personalized health recommendations.

## Arguments

- No arguments or `full`: Run the full pipeline (discover → ingest → correlate → recommend)
- `update`: Re-run with new/updated data sources (skip unchanged files)
- `labs`: Focus on new lab results only (cross-reference against existing genetic findings)
- `genetics`: Focus on new genetic data only
- `supplements`: Update supplement protocol and shopping list based on latest findings

## Pipeline

### Step 1: Data Discovery

Scan the working directory for all available data sources. Supported formats include (but are not limited to):

**Genetic data:**
- Promethease JSON exports (`*.json` with rsnum/geno/magnitude fields)
- Promethease HTML reports (`promethease.html`)
- 23andMe raw data (tab-delimited: rsid, chromosome, position, genotype)
- AncestryDNA raw data (tab-delimited with header, or zipped)
- SelfDecode exports
- Generic VCF files

**Lab results:**
- Function Health PDFs (lab results + clinician notes)
- Standard lab PDFs (Quest, LabCorp, etc.)
- Screenshots of lab portals (read as images)
- CSV/spreadsheet exports of biomarker values
- Any structured or semi-structured medical records

**Existing analysis:**
- Previously generated markdown files in `analysis/`
- These contain prior findings — read them to avoid contradicting or duplicating work

Do NOT assume a fixed format. Inspect file contents to determine structure. Ask the user if a file's format is ambiguous.

### Step 2: Data Ingestion

For each data source:

1. **Genetic data**: Extract variants with clinical significance. Focus on:
   - High magnitude (≥2) Promethease entries
   - ClinVar pathogenic/likely-pathogenic variants
   - Pharmacogenomic variants (drug metabolism: CYP2C19, CYP2D6, CYP3A4, DPYD, VKORC1, etc.)
   - MTHFR, APOE, COMT, FTO, and other commonly actionable SNPs
   - Cancer risk variants (BRCA, Lynch syndrome genes, CHEK2, etc.)
   - Cardiovascular risk (PCSK9, LDLR, 9p21, NOS3, etc.)

2. **Lab results**: Extract all biomarker values with reference ranges. Flag:
   - Out-of-range values (both conventional and functional/optimal ranges)
   - Trends if multiple time points available
   - Ratios that matter (TG/HDL, omega-6/omega-3, free T3/reverse T3, etc.)

3. **Read existing analysis files** to understand what has already been analyzed and recommended.

### Step 3: Genetics ↔ Labs Correlation

This is the highest-value step. Cross-reference genetic risk variants against actual lab values:

- Which genetic predictions are CONFIRMED by labs? (e.g., CAD risk genes + abnormal lipid panel)
- Which genetic risks are NOT yet manifesting? (monitor these)
- Which lab abnormalities have NO genetic basis? (environmental/lifestyle causes)
- Nutrient-gene interactions (MTHFR → folate, VDR → vitamin D, BCMO1 → beta-carotene conversion, etc.)
- Pharmacogenomic implications for current/planned medications

Present correlations in a table:
```
| Genetic Risk | Relevant Lab Values | Status | Priority |
```

### Step 4: Generate Recommendations

Produce a comprehensive, prioritized health program as a markdown file in `analysis/`. Structure:

1. **Top 5 Urgent Priorities** — things that need action now, ranked by severity
2. **Diet recommendations** — foods to emphasize and avoid, tied to specific genetic/lab findings
3. **Supplement protocol** — specific products, doses, timing, with rationale for each
   - Flag interactions (supplement-supplement, supplement-drug, supplement-gene)
   - Note absorption considerations (fat-soluble timing, PPI interactions, etc.)
4. **Lifestyle modifications** — exercise, sleep, stress (tied to genetic predispositions)
5. **Monitoring plan** — which labs to retest and when, what to watch for
6. **Medications to discuss with doctor** — pharmacogenomic considerations
7. **Things to AVOID** — contraindicated supplements/foods given genetic profile

### Step 5: Update Related Documents

If any of these exist in `analysis/`, update them to reflect new findings:
- `daily-cheatsheet.md` — timing and dosing summary
- `current-supplements.md` — full supplement regimen
- `amazon-shopping-list.md` — products to order

## Important Guidelines

- **Always include disclaimer**: "This is not medical advice. Discuss all changes with your doctor."
- **Cite your reasoning**: For each recommendation, note which SNP or lab value drives it.
- **Promethease magnitude is not clinical severity** — it's unusualness/importance in SNPedia.
- **GWAS associations are probabilistic** — "1.3x risk" means population-level, not individual certainty.
- **Functional/optimal ranges differ from conventional** — note when using functional ranges (e.g., fasting insulin optimal <7 vs conventional <25).
- **Check for drug interactions** when recommending supplements alongside medications.
- **Do NOT remove or contradict existing recommendations** without explaining why the change is warranted.
- **When data format is unfamiliar**, show a sample to the user and ask for clarification rather than guessing.
- **Multiple time-point labs**: Always note trends, not just latest values. Improving trends may reduce urgency.

## Output

All generated files go in `analysis/` as markdown. After generating, offer to run `rake pdf:all` or `md2pdf.sh` to produce PDFs.
