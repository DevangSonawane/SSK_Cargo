#!/usr/bin/env python3
"""Functional-regression audit for the l10n sweep."""
import json, os, re, sys

ROOT = "/Users/devangsonawane/ssk"
os.chdir(ROOT)
fails, warns, oks = [], [], []

def dart_files():
    for r, d, fs in os.walk("lib"):
        if "l10n" in r:
            continue
        for f in fs:
            if f.endswith(".dart"):
                yield os.path.join(r, f)

# 1. localized value leaking into logic
LOGIC = [
    (re.compile(r"==\s*l10n\.\w+"), "l10n on right of =="),
    (re.compile(r"l10n\.\w+\s*=="), "l10n on left of =="),
    (re.compile(r"!=\s*l10n\.\w+"), "l10n on right of !="),
    (re.compile(r"l10n\.\w+\s*!="), "l10n on left of !="),
    (re.compile(r"case\s+l10n\.\w+"), "l10n as switch case"),
    (re.compile(r"\.contains\(\s*l10n\.\w+"), "l10n inside .contains("),
    (re.compile(r"\.startsWith\(\s*l10n\.\w+"), "l10n inside .startsWith("),
    (re.compile(r"\[\s*l10n\.\w+\s*\]"), "l10n used as index"),
    (re.compile(r"\.containsKey\(\s*l10n\.\w+"), "l10n as map key"),
    (re.compile(r"putIfAbsent\(\s*l10n\."), "l10n as map key (putIfAbsent)"),
    (re.compile(r"(where|indexWhere|firstWhere|singleWhere|any)\([^)]*l10n\.\w+\s*(==|!=)"),
     "l10n in iterator predicate"),
]
for p in dart_files():
    for i, line in enumerate(open(p, encoding="utf-8", errors="ignore"), 1):
        for rx, desc in LOGIC:
            if rx.search(line):
                fails.append(f"{os.path.relpath(p, ROOT)}:{i}  {desc}\n      {line.strip()[:110]}")

# 2. backend/domain tokens must remain literal strings
TOKENS = ["assigned", "accepted", "picked_up", "in_transit", "en_route",
          "en_route_pickup", "route_to_pickup", "to_pickup", "confirmed",
          "cancelled", "canceled", "rejected", "declined", "completed", "done",
          "loading", "dropoff", "pickup", "pan_photo_url", "license_photo_url",
          "aadhaar_photo_url", "Authorization", "Bearer", "online", "offline"]
blobs = {p: open(p, encoding="utf-8", errors="ignore").read() for p in dart_files()}
for t in TOKENS:
    if not any(re.search(r"['\"]%s['\"]" % re.escape(t), b) for b in blobs.values()):
        warns.append(f"token '{t}' no longer a string literal anywhere")

# 3. every referenced l10n.* getter exists
en = json.load(open("lib/l10n/app_en.arb", encoding="utf-8"))
hi = json.load(open("lib/l10n/app_hi.arb", encoding="utf-8"))
ek = {k for k in en if not k.startswith("@")}
hk = {k for k in hi if not k.startswith("@")}
if ek == hk:
    oks.append(f"ARB parity OK: {len(ek)} keys each locale")
else:
    fails.append(f"ARB parity BROKEN: EN-only={sorted(ek-hk)[:8]} HI-only={sorted(hk-ek)[:8]}")

missing = {}
for p, txt in blobs.items():
    for m in re.finditer(r"\bl10n\.(\w+)", txt):
        if m.group(1) not in ek:
            missing.setdefault(m.group(1), []).append(os.path.relpath(p, ROOT))
if missing:
    fails.append("referenced l10n getters NOT in ARB: " + ", ".join(sorted(missing)[:15]))
else:
    oks.append("all referenced l10n.* getters exist in ARB")

# 4. placeholder parity
ph = lambda s: sorted(re.findall(r"\{(\w+)\}", s)) if isinstance(s, str) else []
bad = [k for k in ek if isinstance(en[k], str) and ph(en[k]) != ph(hi[k])]
if bad:
    fails.append(f"placeholder mismatch EN vs HI: {bad[:10]}")
else:
    oks.append("placeholder parity OK across all keys")

# 5. l10n inside const expressions
for p, txt in blobs.items():
    for i, line in enumerate(txt.split("\n"), 1):
        if re.search(r"\bconst\b.*[A-Z]\w*\(", line) and "l10n." in line:
            fails.append(f"{os.path.relpath(p, ROOT)}:{i}  l10n inside const expression")

print("=" * 60)
print("FUNCTIONAL REGRESSION AUDIT")
print("=" * 60)
for o in oks:
    print("  PASS  " + o)
for w in warns:
    print("  WARN  " + w)
for f in fails:
    print("  FAIL  " + f)
print("-" * 60)
print(f"pass={len(oks)}  warn={len(warns)}  FAIL={len(fails)}")
sys.exit(1 if fails else 0)
