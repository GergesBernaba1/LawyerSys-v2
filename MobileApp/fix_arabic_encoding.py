from pathlib import Path
import re

path = Path('lib/core/localization/app_localizations.dart')
raw = path.read_bytes()
start = raw.find(b"'ar': {")
if start == -1:
    raise SystemExit("'ar' section not found")
idx = raw.find(b'{', start)
brace = 1
end = idx + 1
while end < len(raw) and brace > 0:
    if raw[end] == 123:  # '{'
        brace += 1
    elif raw[end] == 125:  # '}'
        brace -= 1
    end += 1
segment = raw[idx:end]
text = segment.decode('utf-8', errors='replace')
lines = text.splitlines()
pattern = re.compile(r"^(\s*'([^']+)':\s*')(.*)(',?\s*)$")

fixed = []
new_lines = []
seen_keys = set()
for line in lines:
    match = pattern.match(line)
    if not match:
        new_lines.append(line)
        continue
    prefix, key, value, suffix = match.groups()
    if key in seen_keys:
        # skip duplicate keys, keep only first occurrence
        continue
    seen_keys.add(key)
    fixed_line = None
    # value is currently UTF-8 decoded string containing mojibake
    for src_enc in ['latin-1', 'cp1252', 'utf-8']:
        for mid_enc in ['latin-1', 'cp1252', 'utf-8']:
            try:
                b = value.encode(src_enc, errors='strict')
                s = b.decode(mid_enc, errors='strict')
                if s != value and any(0x0600 <= ord(c) <= 0x06FF for c in s):
                    fixed_line = prefix + s + suffix
                    fixed.append((key, value, s, src_enc, mid_enc))
                    break
            except Exception:
                continue
        if fixed_line:
            break
    if fixed_line:
        new_lines.append(fixed_line)
    else:
        new_lines.append(line)

if not fixed:
    print('No fixes applied. Maybe manual conversion is needed.')
else:
    print(f'Applied {len(fixed)} fixes:')
    for key, old, new, src_enc, mid_enc in fixed[:50]:
        print(key, src_enc, mid_enc, repr(new))

updated_segment = '\n'.join(new_lines)
out = raw[:idx] + updated_segment.encode('utf-8') + raw[end:]
path.write_bytes(out)
print('done')
