samples = [
    "Ø±Ù‚Ù… Ø§Ù„Ù‡Ø§ØªÙ",
]
encs = ['latin-1', 'cp1252', 'utf-8']
for s in samples:
    print('sample:', s)
    raw = s.encode('utf-8')
    print('raw bytes:', raw)
    for enc in encs:
        try:
            t = raw.decode(enc)
            print('raw decode', enc, repr(t))
            try:
                print('  encode back to', enc, t.encode(enc))
            except Exception as e:
                print('  encode back failed', e)
        except Exception as e:
            print('raw decode', enc, 'failed', e)
    print('---')
