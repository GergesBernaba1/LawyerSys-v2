import re
from pathlib import Path
root = Path('.')
all_src = list(root.rglob('*.dart'))
keys = set()
used = set()
for p in all_src:
    txt = p.read_text(encoding='utf-8', errors='ignore')
    used.update(m.group(1) for m in re.finditer(r'AppLocalizations\.of\(context\)\.([A-Za-z0-9_]+)', txt))
    used.update(m.group(1) for m in re.finditer(r"\.translate\('([A-Za-z0-9_]+)'\)", txt))
    if p.name == 'app_localizations.dart':
        keys.update(m.group(1) for m in re.finditer(r"'([A-Za-z0-9_]+)':\s*'", txt))
print('Used keys total:', len(used))
print('Defined keys total:', len(keys))
missing = sorted(k for k in used if k not in keys)
print('Missing keys:', missing)
extra = sorted(k for k in keys if k not in used)
print('Unused defined keys count:', len(extra))
if len(extra) < 100:
    print('Unused defined keys:', extra)
