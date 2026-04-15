from pathlib import Path
import re
path = Path('lib/core/localization/app_localizations.dart')
text = path.read_text(encoding='utf-8')
start = text.find("'ar': {")
if start == -1:
    raise SystemExit("'ar' section not found")
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
segment = text[idx:end]
lines = segment.splitlines()
pattern = re.compile(r"^(\s*'([^']+)':\s*'.*',?\s*)$")
seen = set()
new_lines = []
for line in lines:
    m = pattern.match(line)
    if not m:
        new_lines.append(line)
        continue
    key = m.group(2)
    if key in seen:
        continue
    seen.add(key)
    new_lines.append(line)
new_text = text[:idx] + '\n'.join(new_lines) + text[end:]
path.write_text(new_text, encoding='utf-8')
print('cleaned duplicate keys, total unique keys in ar:', len(seen))
