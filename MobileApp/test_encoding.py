samples = [
    'Ø±Ù‚Ù… Ø§Ù„Ù‡Ø§ØªÙ',
    'Ø§Ù„Ù…ÙˆØ¸ÙÙˆÙ†',
    'Ø§Ù„Ø¥Ø´Ø¹Ø§Ø±Ø§Øª Ø§Ù„ÙÙˆØ±ÙŠØ©',
    'ÙˆØ¸ÙŠÙØ© Ø¥ÙŠÙ‚Ø§Ù Ø§Ù„Ù…Ø¤Ù‚Øª'
]
encs = ['latin-1', 'cp1252', 'utf-8']
for s in samples:
    print('sample:', s)
    print('codepoints:', [hex(ord(c)) for c in s])
    for src in encs:
        try:
            b = s.encode(src)
        except Exception as e:
            print('  encode', src, 'failed', e)
            continue
        print('  encode', src, 'bytes', b)
        for dst in encs:
            try:
                dec = b.decode(dst)
                print('    decode', dst, '->', dec)
            except Exception as e:
                print('    decode', dst, 'failed', e)
    print()
