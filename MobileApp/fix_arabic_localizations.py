from pathlib import Path
import re

path = Path('lib/core/localization/app_localizations.dart')
text = path.read_text(encoding='utf-8')
start = text.find("'ar': {")
if start == -1:
    raise SystemExit('ar map not found')
idx = text.find('{', start)
brace = 1
end = idx + 1
while end < len(text) and brace > 0:
    c = text[end]
    if c == '{':
        brace += 1
    elif c == '}':
        brace -= 1
    end += 1

ar_text = text[idx:end]
lines = ar_text.splitlines()
new_lines = []
changes = []

for line in lines:
    m = re.match(r"(\s*'([^']+)':\s*')(.+?)(',?\s*)$", line)
    if m:
        prefix, key, val, suffix = m.group(1), m.group(2), m.group(3), m.group(4)
        try:
            encoded = val.encode('latin-1')
            decoded = encoded.decode('utf-8')
        except Exception:
            new_lines.append(line)
            continue
        if decoded != val:
            new_lines.append(f"{prefix}{decoded}{suffix}")
            changes.append((key, val, decoded))
        else:
            new_lines.append(line)
    else:
        new_lines.append(line)

if not changes:
    print('No mojibake entries found or fixed.')
else:
    print(f'Fixed {len(changes)} Arabic values:')
    for key, old, new in changes[:40]:
        print(key, '->', new)
    new_text = text[:idx] + '\n'.join(new_lines) + text[end:]
    path.write_text(new_text, encoding='utf-8')
    print('File updated.')
