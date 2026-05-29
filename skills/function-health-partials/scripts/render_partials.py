#!/usr/bin/env python3
"""function-health-partials :: render_partials.py

Turn a Function Health `requisitions?pending=false` payload into an interim
partial-results markdown record (+ raw JSON for the archive).

Usage:
    render_partials.py REQS.json --which latest \
        --out  labs/.../2026-05-28_partial_results.md \
        --raw  labs/.../2026-05-28_partial_results_raw.json

    --which latest        most recent visit by visitDate (default)
    --which 2026-05-28    the visit collected on that date
    --which all           every visit (writes one section each)

The input may be either the raw `status=200|[...]` string this skill captures
or already-parsed JSON (an array of requisitions).
"""
import argparse, json, sys, datetime


def load_requisitions(path):
    raw = open(path).read().strip()
    if raw.startswith('status='):
        raw = raw.split('|', 1)[1]
    data = json.loads(raw)
    return data if isinstance(data, list) else [data]


def collect_visits(reqs):
    visits = []
    for rq in reqs:
        for v in rq.get('visits', []) or []:
            visits.append({'req': rq, 'visit': v, 'date': v.get('visitDate', '')})
    visits.sort(key=lambda x: x['date'], reverse=True)
    return visits


def pick(visits, which):
    if which in ('latest', None):
        return visits[:1]
    if which == 'all':
        return visits
    return [v for v in visits if (v['date'] or '')[:10] == which] or visits[:1]


def categorize(name):
    n = name.lower()
    if 'urine' in n: return 'Urinalysis'
    if any(k in n for k in ['cholesterol', 'triglyc', 'hdl', 'ldl', 'non-hdl']): return 'Lipids'
    if any(k in n for k in ['glucose', 'hba1c', 'a1c', 'insulin', 'uric']): return 'Metabolic'
    if any(k in n for k in ['sodium', 'potassium', 'chloride', 'carbon dioxide', 'calcium',
                            'bun', 'urea', 'creatinine', 'egfr']): return 'Metabolic panel (chem/kidney)'
    if any(k in n for k in ['protein', 'albumin', 'globulin', 'bilirubin', 'alkaline',
                            'aspartate', 'alanine', 'ggt', 'transaminase']): return 'Liver / protein'
    if any(k in n for k in ['amylase', 'lipase']): return 'Pancreas'
    if any(k in n for k in ['wbc', 'rbc', 'hemoglobin', 'hematocrit', 'corpuscular', 'platelet',
                            'rdw', 'mpv', 'neutro', 'lympho', 'mono', 'eosino', 'baso',
                            'white blood', 'red blood']): return 'CBC w/ differential'
    if any(k in n for k in ['ferritin', 'iron', 'vitamin d']): return 'Iron / Vitamin D'
    if any(k in n for k in ['tsh', 'thyrox', 't4', 't3', 'triiodo']): return 'Thyroid'
    if any(k in n for k in ['fsh', 'lh', 'luteinizing', 'follicle', 'prolactin', 'estradiol',
                            'dhea', 'shbg', 'sex hormone', 'cortisol', 'testosterone']): return 'Hormones'
    return 'Other'


ORDER = ['Lipids', 'Metabolic', 'Metabolic panel (chem/kidney)', 'Liver / protein', 'Pancreas',
         'CBC w/ differential', 'Urinalysis', 'Iron / Vitamin D', 'Thyroid', 'Hormones', 'Other']


def render_visit(entry, today):
    rq, v = entry['req'], entry['visit']
    res = v.get('biomarkerResults', []) or []
    partial = not rq.get('allResultsAvailable', False)
    date = (v.get('visitDate') or '')[:10] or 'unknown'
    out, oo = [], sum(1 for b in res if b.get('testResultOutOfRange'))

    out.append(f"# Function Health — {'Partial' if partial else 'Complete'} Results (Draw {date})")
    out.append("")
    status = "PARTIAL" if partial else "COMPLETE"
    out.append(f"> **Status: {status}.** Pulled from the Function Health member portal on {today}"
               + ("" if not partial else " while the official results PDF was not yet posted")
               + f". `allResultsAvailable = {rq.get('allResultsAvailable')}` — {len(res)} biomarkers resulted."
               + (" Supersede with the official Lab Results of Record PDF when posted." if partial else ""))
    out.append("")
    out.append("## Draw / requisition metadata")
    out.append("")
    out.append("| Field | Value |")
    out.append("|-------|-------|")
    out.append(f"| Collection / visit date | {date} |")
    addr = ", ".join(x for x in [v.get('streetAddress'), v.get('city'), v.get('state'), v.get('zip')] if x)
    out.append(f"| Collection site | {addr} |")
    out.append(f"| Confirmation code | {v.get('confirmationCode', '—')} |")
    pkgs = v.get('packages') or []
    pkg_names = ", ".join(p.get('name') or p.get('packageName') or str(p) for p in pkgs) if pkgs else "—"
    out.append(f"| Packages | {pkg_names} |")
    out.append(f"| Requisition status | {rq.get('status', '—')} (reviewed: {rq.get('reviewed')}) |")
    out.append(f"| All results available | {rq.get('allResultsAvailable')} |")
    out.append(f"| Requisition ID | `{rq.get('id', '—')}` |")
    out.append("| Source | Function Health member API (`/api/v1/requisitions`) |")
    out.append("")

    groups = {}
    for b in res:
        groups.setdefault(categorize(b.get('biomarkerName', '')), []).append(b)
    out.append(f"## Resulted biomarkers ({len(res)}) — {oo} out of range")
    out.append("")
    for g in ORDER:
        if g not in groups:
            continue
        out.append(f"### {g}")
        out.append("")
        out.append("| Biomarker | Result | Units | Reference range | Flag |")
        out.append("|-----------|--------|-------|-----------------|------|")
        for b in sorted(groups[g], key=lambda x: x.get('biomarkerName', '')):
            flag = "**OUT**" if b.get('testResultOutOfRange') else "in range"
            rng = (b.get('questReferenceRange') or '—').replace('|', '/')
            out.append(f"| {b.get('biomarkerName', '').strip()} | {b.get('testResult', '')} | "
                       f"{b.get('measurementUnits') or ''} | {rng} | {flag} |")
        out.append("")
    if oo:
        out.append("## Out-of-range summary")
        out.append("")
        out.append("| Biomarker | Result | Units | Reference range |")
        out.append("|-----------|--------|-------|-----------------|")
        for b in res:
            if b.get('testResultOutOfRange'):
                out.append(f"| {b.get('biomarkerName', '').strip()} | {b.get('testResult', '')} | "
                           f"{b.get('measurementUnits') or ''} | {b.get('questReferenceRange') or '—'} |")
        out.append("")
    out.append("> **Still pending:** the API only returns *resulted* markers. To list what is still "
               "pending, diff this set against the order-request PDF in this lab folder "
               "(`pdftotext -layout 'Lab Order Request-*.pdf' - | grep -E '^[[:space:]]*[0-9]{3,}'`).")
    out.append("")
    return "\n".join(out), {"requisition": {k: rq.get(k) for k in
                            ('id', 'status', 'reviewed', 'allResultsAvailable',
                             'reviewingPhysician', 'createdAt')}, "visit": v}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('reqs')
    ap.add_argument('--which', default='latest')
    ap.add_argument('--out', required=True)
    ap.add_argument('--raw')
    ap.add_argument('--today', default=None)
    a = ap.parse_args()
    today = a.today or datetime.date.today().isoformat()

    visits = collect_visits(load_requisitions(a.reqs))
    if not visits:
        sys.exit("no visits found in payload")
    chosen = pick(visits, a.which)

    md_parts, raw_parts = [], []
    for entry in chosen:
        md, raw = render_visit(entry, today)
        md_parts.append(md)
        raw_parts.append(raw)
    open(a.out, 'w').write(("\n\n---\n\n".join(md_parts)) + "\n")
    if a.raw:
        json.dump(raw_parts if a.which == 'all' else raw_parts[0],
                  open(a.raw, 'w'), indent=2)
    n = len(chosen[0]['visit'].get('biomarkerResults', []))
    print(f"wrote {a.out} ({len(chosen)} visit(s); latest = "
          f"{(chosen[0]['date'] or '')[:10]}, {n} results)")


if __name__ == '__main__':
    main()
