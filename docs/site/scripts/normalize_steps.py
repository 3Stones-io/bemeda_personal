#!/usr/bin/env python3
import os
import re
import glob
from typing import Dict

BASE = "/Users/spitexbemeda/Documents/Bemeda Personal Page/docs/site/sitemap"

# Participant mappings per section
PARTICIPANT_BY_GROUP: Dict[str, Dict[str, str]] = {
    "job": {"p1": "Organisation", "p2": "JobSeeker", "p3": "Sales Team"},
    "tmp-temp": {"p1": "Hospital", "p2": "Specialist", "p3": "Project Manager"},
    "tmp-try": {"p1": "Hospital", "p2": "Nurse", "p3": "Evaluator"},
    "tmp-pool": {"p1": "Pool Worker", "p2": "Organisation", "p3": "Scheduler"},
}

# Top navigation markup per section
NAV_BY_GROUP: Dict[str, str] = {
    "job": (
        '<nav class="top-nav">\n'
        '            <ul class="nav-list">\n'
        '                <li class="nav-item">\n'
        '                    <a href="/index.html" class="nav-link" data-i18n="nav.index">Index</a>\n'
        '                </li>\n'
        '                <li class="nav-item">\n'
        '                    <a href="../../index.html" class="nav-link active" data-i18n="nav.job">JOB</a>\n'
        '                </li>\n'
        '                <li class="nav-item dropdown">\n'
        '                    <a href="../../../tmp/index.html" class="nav-link" data-i18n="nav.tmp">TMP</a>\n'
        '                    <div class="dropdown-content">\n'
        '                        <a href="../../../tmp/temporary/index.html" data-i18n="nav.tmp-temporary">TMP-Temporary</a>\n'
        '                        <a href="../../../tmp/tryhire/index.html" data-i18n="nav.tmp-tryhire">TMP & Hire</a>\n'
        '                        <a href="../../../tmp/pool/index.html" data-i18n="nav.tmp-pool">TMP-Pool</a>\n'
        '                    </div>\n'
        '                </li>\n'
        '                <li class="nav-item">\n'
        '                    <a href="../../../table/index.html" class="nav-link" data-i18n="nav.table-view">Table View</a>\n'
        '                </li>\n'
        '            </ul>\n'
        '        </nav>'
    ),
    "tmp-temp": (
        '<nav class="top-nav">\n'
        '            <ul class="nav-list">\n'
        '                <li class="nav-item"><a href="/index.html" class="nav-link" data-i18n="nav.index">Index</a></li>\n'
        '                <li class="nav-item"><a href="../../../job/index.html" class="nav-link" data-i18n="nav.job">JOB</a></li>\n'
        '                <li class="nav-item dropdown">\n'
        '                    <a href="../../index.html" class="nav-link active" data-i18n="nav.tmp">TMP</a>\n'
        '                    <div class="dropdown-content">\n'
        '                        <a href="../../temporary/index.html" data-i18n="nav.tmp-temporary">TMP-Temporary</a>\n'
        '                        <a href="../../tryhire/index.html" data-i18n="nav.tmp-tryhire">TMP & Hire</a>\n'
        '                        <a href="../../pool/index.html" data-i18n="nav.tmp-pool">TMP-Pool</a>\n'
        '                    </div>\n'
        '                </li>\n'
        '                <li class="nav-item"><a href="../../../table/index.html" class="nav-link" data-i18n="nav.table-view">Table</a></li>\n'
        '            </ul>\n'
        '        </nav>'
    ),
    "tmp-try": (
        '<nav class="top-nav">\n'
        '            <ul class="nav-list">\n'
        '                <li class="nav-item"><a href="/index.html" class="nav-link" data-i18n="nav.index">Index</a></li>\n'
        '                <li class="nav-item"><a href="../../../job/index.html" class="nav-link" data-i18n="nav.job">JOB</a></li>\n'
        '                <li class="nav-item dropdown">\n'
        '                    <a href="../../index.html" class="nav-link active" data-i18n="nav.tmp">TMP</a>\n'
        '                    <div class="dropdown-content">\n'
        '                        <a href="../../temporary/index.html" data-i18n="nav.tmp-temporary">TMP-Temporary</a>\n'
        '                        <a href="../index.html" data-i18n="nav.tmp-tryhire">TMP & Hire</a>\n'
        '                        <a href="../../pool/index.html" data-i18n="nav.tmp-pool">TMP-Pool</a>\n'
        '                    </div>\n'
        '                </li>\n'
        '                <li class="nav-item"><a href="../../../table/index.html" class="nav-link" data-i18n="nav.table-view">Table</a></li>\n'
        '            </ul>\n'
        '        </nav>'
    ),
    "tmp-pool": (
        '<nav class="top-nav">\n'
        '            <ul class="nav-list">\n'
        '                <li class="nav-item"><a href="/index.html" class="nav-link" data-i18n="nav.index">Index</a></li>\n'
        '                <li class="nav-item"><a href="../../../job/index.html" class="nav-link" data-i18n="nav.job">JOB</a></li>\n'
        '                <li class="nav-item dropdown">\n'
        '                    <a href="../../index.html" class="nav-link active" data-i18n="nav.tmp">TMP</a>\n'
        '                    <div class="dropdown-content">\n'
        '                        <a href="../../temporary/index.html" data-i18n="nav.tmp-temporary">TMP-Temporary</a>\n'
        '                        <a href="../../tryhire/index.html" data-i18n="nav.tmp-tryhire">TMP & Hire</a>\n'
        '                        <a href="../index.html" data-i18n="nav.tmp-pool">TMP-Pool</a>\n'
        '                    </div>\n'
        '                </li>\n'
        '                <li class="nav-item"><a href="../../../table/index.html" class="nav-link" data-i18n="nav.table-view">Table</a></li>\n'
        '            </ul>\n'
        '        </nav>'
    ),
}

CSS_RE = re.compile(r'href="[^\"]*language-switcher\.css"')
JS_RE = re.compile(r'src="[^\"]*language-switcher\.js"')
NAV_RE = re.compile(r'<nav class="top-nav">[\s\S]*?</nav>')
CRUMB_RE = re.compile(r'<div class="breadcrumb">[\s\S]*?</div>')
STEPTITLE_RE = re.compile(r'<div class="step-title-section">[\s\S]*?</div>')
TITLE_RE = re.compile(r'<title>[\s\S]*?</title>')

patterns = [
    os.path.join(BASE, 'job', 's1', 'p[123]', 's[1-6].html'),
    os.path.join(BASE, 'tmp', 'temporary', 's1', 'p[123]', 's[1-6].html'),
    os.path.join(BASE, 'tmp', 'tryhire', 's1', 'p[123]', 's[1-6].html'),
    os.path.join(BASE, 'tmp', 'pool', 's1', 'p[123]', 's[1-6].html'),
]

files = []
for pat in patterns:
    files.extend(glob.glob(pat))

updated = 0

for path in files:
    # Determine group and indices
    rel = path.replace(BASE + os.sep, '')
    parts = rel.split(os.sep)
    if not parts or parts[0] not in ("job", "tmp"):
        continue

    if parts[0] == "job":
        group = "job"
        # job/s1/pX/sY.html
        if len(parts) < 4:
            continue
        pdir = parts[2]
        stepname = parts[3]
    else:
        # tmp/<subtype>/s1/pX/sY.html
        if len(parts) < 5:
            continue
        subtype = parts[1]
        group = {"temporary": "tmp-temp", "tryhire": "tmp-try", "pool": "tmp-pool"}.get(subtype)
        if not group:
            continue
        pdir = parts[3]
        stepname = parts[4]

    if not stepname.startswith('s') or not stepname.endswith('.html'):
        continue
    stepnum = stepname[1:-5]

    participant = PARTICIPANT_BY_GROUP[group][pdir]

    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    # Normalize asset paths (4 levels up to site/assets)
    content = CSS_RE.sub('href="../../../../assets/global/css/language-switcher.css"', content)
    content = JS_RE.sub('src="../../../../assets/global/js/language-switcher.js"', content)

    # Replace nav
    content = NAV_RE.sub(NAV_BY_GROUP[group], content)

    # Replace breadcrumb
    crumb = (
        '<div class="breadcrumb">\n'
        '                <a href="../index.html">Scenario 1</a>\n'
        '                <span>→</span>\n'
        f'                <span>{participant} Process</span>\n'
        '            </div>'
    )
    content = CRUMB_RE.sub(crumb, content)

    # Replace step title section
    step_title = (
        '<div class="step-title-section">\n'
        f'                <span class="step-badge">Step {stepnum}</span>\n'
        f'                <h1 class="step-name">{participant} - Step {stepnum}</h1>\n'
        '            </div>'
    )
    content = STEPTITLE_RE.sub(step_title, content)

    # Replace <title>
    content = TITLE_RE.sub(f'<title>Step {stepnum} - {participant} - Scenario 1 - Bemeda Platform</title>', content)

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    updated += 1

print(f"Updated {updated} files") 