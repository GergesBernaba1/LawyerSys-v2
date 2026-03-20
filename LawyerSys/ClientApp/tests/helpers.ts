export function fakeToken(payload: Record<string, any>): string {
  const header = { alg: 'HS256', typ: 'JWT' };
  const b64 = (obj: any) => Buffer.from(JSON.stringify(obj)).toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  return `${b64(header)}.${b64(payload)}.signature`;
}
