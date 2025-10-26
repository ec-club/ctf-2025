const secretRegistry = new Map<string, Uint8Array>();

const textEncoder = new TextEncoder();
export async function getSecretKeyWithPurpose(
  purpose: string
): Promise<Uint8Array> {
  if (secretRegistry.has(purpose)) {
    return secretRegistry.get(purpose)!;
  }

  const ikm = await crypto.subtle.importKey(
    "raw",
    textEncoder.encode(process.env.APP_SECRET),
    "HKDF",
    false,
    ["deriveBits"]
  );
  const key = await crypto.subtle.deriveBits(
    {
      name: "HKDF",
      hash: "SHA-256",
      salt: textEncoder.encode(`${purpose}-salt`),
      info: textEncoder.encode(purpose),
    },
    ikm,
    256
  );
  return new Uint8Array(key);
}
