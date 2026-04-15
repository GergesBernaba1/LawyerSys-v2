from pathlib import Path
import re
root = Path('.')
# gather all used keys in translate() calls and AppLocalizations property usages
used = set()
for p in root.rglob('*.dart'):
    text = p.read_text(encoding='utf-8', errors='ignore')
    used.update(m.group(1) for m in re.finditer(r"AppLocalizations\.of\(context\)\.([A-Za-z0-9_]+)", text))
    used.update(m.group(1) for m in re.finditer(r"\.translate\('([A-Za-z0-9_]+)'\)", text))
# gather all defined map keys
path = Path('lib/core/localization/app_localizations.dart')
text = path.read_text(encoding='utf-8')
keys = set(m.group(1) for m in re.finditer(r"'([A-Za-z0-9_]+)':\s*'", text))
print('Used keys:', len(used))
print('Defined keys:', len(keys))
missing = sorted(k for k in used if k not in keys)
extra = sorted(k for k in keys if k not in used)
print('Missing keys (used but not defined):', len(missing))
for k in missing[:100]:
    print(k)
print('Extra keys (defined but not used):', len(extra))
for k in extra[:100]:
    print(k)
