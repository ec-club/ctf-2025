/* encrypt.c
 *
 * Reimplementation in C of the Python pipeline described earlier:
 *  - key derivation: sha256(password) repeated -> 32 bytes key
 *  - seed = (sha256(password) as big-int low32) XOR first4_of_key
 *  - RNG: LCG s = (1103515245*s + 12345) & 0xFFFFFFFF, byte = (s >> 24) & 0xFF
 *  - sbox: fisher-yates using RNG (separate RNG seeded with seed ^ 0xA5A5A5A5)
 *  - per-byte: t = (pb + rng.byte()) & 0xFF; t ^= kb; t = rol8(t, key[(i+1)%klen]);
 *             t = sbox[t]; out = (t + (i & 0xFF)) & 0xFF
 *  - output Base64
 *
 * Also provides decrypt to verify correctness.
 *
 * Public-domain SHA256 implementation (compact) included.
 */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

/* -------------------- Minimal SHA256 (public-domain style) --------------------
 * Source idea: compact implementations (kept inline for portability).
 * Produces 32-byte digest.
 */

typedef struct
{
  uint32_t state[8];
  uint64_t bitlen;
  uint8_t data[64];
  size_t datalen;
} SHA256_CTX;

static const uint32_t K256[64] = {
    0x428a2f98ul, 0x71374491ul, 0xb5c0fbcful, 0xe9b5dba5ul, 0x3956c25bul, 0x59f111f1ul, 0x923f82a4ul, 0xab1c5ed5ul,
    0xd807aa98ul, 0x12835b01ul, 0x243185beul, 0x550c7dc3ul, 0x72be5d74ul, 0x80deb1feul, 0x9bdc06a7ul, 0xc19bf174ul,
    0xe49b69c1ul, 0xefbe4786ul, 0x0fc19dc6ul, 0x240ca1ccul, 0x2de92c6ful, 0x4a7484aaul, 0x5cb0a9dcul, 0x76f988daul,
    0x983e5152ul, 0xa831c66dul, 0xb00327c8ul, 0xbf597fc7ul, 0xc6e00bf3ul, 0xd5a79147ul, 0x06ca6351ul, 0x14292967ul,
    0x27b70a85ul, 0x2e1b2138ul, 0x4d2c6dfcul, 0x53380d13ul, 0x650a7354ul, 0x766a0abbul, 0x81c2c92eul, 0x92722c85ul,
    0xa2bfe8a1ul, 0xa81a664bul, 0xc24b8b70ul, 0xc76c51a3ul, 0xd192e819ul, 0xd6990624ul, 0xf40e3585ul, 0x106aa070ul,
    0x19a4c116ul, 0x1e376c08ul, 0x2748774cul, 0x34b0bcb5ul, 0x391c0cb3ul, 0x4ed8aa4aul, 0x5b9cca4ful, 0x682e6ff3ul,
    0x748f82eeul, 0x78a5636ful, 0x84c87814ul, 0x8cc70208ul, 0x90befffaul, 0xa4506cebul, 0xbef9a3f7ul, 0xc67178f2ul};

static uint32_t rotr32(uint32_t x, unsigned n) { return (x >> n) | (x << (32 - n)); }
static uint32_t ch(uint32_t x, uint32_t y, uint32_t z) { return (x & y) ^ (~x & z); }
static uint32_t maj(uint32_t x, uint32_t y, uint32_t z) { return (x & y) ^ (x & z) ^ (y & z); }
static uint32_t bsig0(uint32_t x) { return rotr32(x, 2) ^ rotr32(x, 13) ^ rotr32(x, 22); }
static uint32_t bsig1(uint32_t x) { return rotr32(x, 6) ^ rotr32(x, 11) ^ rotr32(x, 25); }
static uint32_t ssig0(uint32_t x) { return rotr32(x, 7) ^ rotr32(x, 18) ^ (x >> 3); }
static uint32_t ssig1(uint32_t x) { return rotr32(x, 17) ^ rotr32(x, 19) ^ (x >> 10); }

void sha256_init(SHA256_CTX *ctx)
{
  ctx->state[0] = 0x6a09e667ul;
  ctx->state[1] = 0xbb67ae85ul;
  ctx->state[2] = 0x3c6ef372ul;
  ctx->state[3] = 0xa54ff53aul;
  ctx->state[4] = 0x510e527ful;
  ctx->state[5] = 0x9b05688cul;
  ctx->state[6] = 0x1f83d9abul;
  ctx->state[7] = 0x5be0cd19ul;
  ctx->datalen = 0;
  ctx->bitlen = 0;
}

void sha256_transform(SHA256_CTX *ctx, const uint8_t data[])
{
  uint32_t W[64];
  for (int t = 0; t < 16; t++)
  {
    W[t] = (uint32_t)data[t * 4] << 24 | (uint32_t)data[t * 4 + 1] << 16 | (uint32_t)data[t * 4 + 2] << 8 | (uint32_t)data[t * 4 + 3];
  }
  for (int t = 16; t < 64; t++)
  {
    W[t] = ssig1(W[t - 2]) + W[t - 7] + ssig0(W[t - 15]) + W[t - 16];
  }
  uint32_t a = ctx->state[0], b = ctx->state[1], c = ctx->state[2], d = ctx->state[3];
  uint32_t e = ctx->state[4], f = ctx->state[5], g = ctx->state[6], h = ctx->state[7];
  for (int t = 0; t < 64; t++)
  {
    uint32_t T1 = h + bsig1(e) + ch(e, f, g) + K256[t] + W[t];
    uint32_t T2 = bsig0(a) + maj(a, b, c);
    h = g;
    g = f;
    f = e;
    e = d + T1;
    d = c;
    c = b;
    b = a;
    a = T1 + T2;
  }
  ctx->state[0] += a;
  ctx->state[1] += b;
  ctx->state[2] += c;
  ctx->state[3] += d;
  ctx->state[4] += e;
  ctx->state[5] += f;
  ctx->state[6] += g;
  ctx->state[7] += h;
}

void sha256_update(SHA256_CTX *ctx, const uint8_t *data, size_t len)
{
  for (size_t i = 0; i < len; i++)
  {
    ctx->data[ctx->datalen++] = data[i];
    if (ctx->datalen == 64)
    {
      sha256_transform(ctx, ctx->data);
      ctx->bitlen += 512;
      ctx->datalen = 0;
    }
  }
}

void sha256_final(SHA256_CTX *ctx, uint8_t hash[32])
{
  size_t i = ctx->datalen;
  // Pad
  if (ctx->datalen < 56)
  {
    ctx->data[i++] = 0x80;
    while (i < 56)
      ctx->data[i++] = 0x00;
  }
  else
  {
    ctx->data[i++] = 0x80;
    while (i < 64)
      ctx->data[i++] = 0x00;
    sha256_transform(ctx, ctx->data);
    memset(ctx->data, 0, 56);
  }
  ctx->bitlen += ctx->datalen * 8;
  // append big-endian bitlen
  ctx->data[63] = ctx->bitlen & 0xFF;
  ctx->data[62] = (ctx->bitlen >> 8) & 0xFF;
  ctx->data[61] = (ctx->bitlen >> 16) & 0xFF;
  ctx->data[60] = (ctx->bitlen >> 24) & 0xFF;
  ctx->data[59] = (ctx->bitlen >> 32) & 0xFF;
  ctx->data[58] = (ctx->bitlen >> 40) & 0xFF;
  ctx->data[57] = (ctx->bitlen >> 48) & 0xFF;
  ctx->data[56] = (ctx->bitlen >> 56) & 0xFF;
  sha256_transform(ctx, ctx->data);
  for (int i = 0; i < 8; i++)
  {
    hash[i * 4] = (ctx->state[i] >> 24) & 0xFF;
    hash[i * 4 + 1] = (ctx->state[i] >> 16) & 0xFF;
    hash[i * 4 + 2] = (ctx->state[i] >> 8) & 0xFF;
    hash[i * 4 + 3] = (ctx->state[i]) & 0xFF;
  }
}

/* -------------------- Utility functions -------------------- */

static inline uint32_t be32(const uint8_t *p)
{
  return (uint32_t)p[0] << 24 | (uint32_t)p[1] << 16 | (uint32_t)p[2] << 8 | (uint32_t)p[3];
}

static inline uint8_t rol8(uint8_t x, uint8_t r)
{
  r &= 7;
  return (uint8_t)(((x << r) & 0xFF) | (x >> (8 - r)));
}
static inline uint8_t ror8(uint8_t x, uint8_t r)
{
  r &= 7;
  return (uint8_t)((x >> r) | ((x << (8 - r)) & 0xFF));
}

/* -------------------- RNG and S-box -------------------- */

typedef struct
{
  uint32_t s;
} WobbleRNG;

void wobble_init(WobbleRNG *r, uint32_t seed)
{
  r->s = seed;
}
uint8_t wobble_byte(WobbleRNG *r)
{
  r->s = (uint32_t)((1103515245u * (uint64_t)r->s + 12345u) & 0xFFFFFFFFu);
  return (uint8_t)((r->s >> 24) & 0xFFu);
}

/* builds sbox array[256] */
void make_sbox(uint8_t sbox[256], WobbleRNG *rng)
{
  for (int i = 0; i < 256; ++i)
    sbox[i] = (uint8_t)i;
  for (int i = 255; i > 0; --i)
  {
    uint8_t rb = wobble_byte(rng);
    uint32_t j = rb % (i + 1);
    uint8_t tmp = sbox[i];
    sbox[i] = sbox[j];
    sbox[j] = tmp;
  }
}

/* -------------------- Key derivation -------------------- */

/* derive_key_bytes(password) -> 32 bytes: sha256(pass) repeated *4 and truncated to 32
   Equivalent: digest = sha256(password); key = (digest * 4)[:32] -> same as digest itself, but we keep exact behavior. */
void derive_key(const char *password, uint8_t key_out[32])
{
  SHA256_CTX ctx;
  uint8_t digest[32];
  sha256_init(&ctx);
  sha256_update(&ctx, (const uint8_t *)password, strlen(password));
  sha256_final(&ctx, digest);
  /* Python code created digest and then (h * 4)[:32] -> effectively the same 32 bytes as digest. */
  memcpy(key_out, digest, 32);
}

/* sha256_int_low32 = low 32 bits of sha256(password) interpreted as big-endian big-int */
uint32_t sha256_low32(const char *password)
{
  SHA256_CTX ctx;
  uint8_t digest[32];
  sha256_init(&ctx);
  sha256_update(&ctx, (const uint8_t *)password, strlen(password));
  sha256_final(&ctx, digest);
  /* low 32 bits of the big-endian integer = last 4 bytes of digest */
  return be32(digest + 28);
}

/* -------------------- Base64 encode/decode (simple) -------------------- */
static const char b64_table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

char *base64_encode(const uint8_t *data, size_t inlen)
{
  size_t outlen = ((inlen + 2) / 3) * 4;
  char *out = (char *)malloc(outlen + 1);
  if (!out)
    return NULL;
  size_t i = 0, o = 0;
  while (i < inlen)
  {
    uint32_t a = i < inlen ? data[i++] : 0;
    uint32_t b = i < inlen ? data[i++] : 0;
    uint32_t c = i < inlen ? data[i++] : 0;
    uint32_t triple = (a << 16) | (b << 8) | c;
    out[o++] = b64_table[(triple >> 18) & 0x3F];
    out[o++] = b64_table[(triple >> 12) & 0x3F];
    out[o++] = (i - 1 > inlen) ? '=' : b64_table[(triple >> 6) & 0x3F];
    out[o++] = (i > inlen) ? '=' : b64_table[triple & 0x3F];
  }
  out[o] = '\0';
  return out;
}

/* for verification we need base64 decode: returns length in *outlen, malloc'ed buffer */
uint8_t *base64_decode(const char *b64, size_t *outlen)
{
  size_t len = strlen(b64);
  if (len % 4 != 0)
    return NULL;
  size_t padding = 0;
  if (len >= 2 && b64[len - 1] == '=')
    padding++;
  if (len >= 1 && b64[len - 2] == '=')
    padding++;
  size_t out_sz = (len / 4) * 3 - padding;
  uint8_t *out = (uint8_t *)malloc(out_sz);
  if (!out)
    return NULL;
  uint8_t dec[256];
  for (int i = 0; i < 256; i++)
    dec[i] = 0x80;
  for (int i = 0; i < 64; i++)
    dec[(uint8_t)b64_table[i]] = i;
  dec[(uint8_t)'+'] = 62;
  dec[(uint8_t)'/'] = 63;
  size_t inpos = 0, outpos = 0;
  while (inpos < len)
  {
    uint32_t vals[4];
    for (int k = 0; k < 4; k++)
    {
      char c = b64[inpos++];
      if (c == '=')
        vals[k] = 0;
      else
      {
        uint8_t v = dec[(uint8_t)c];
        if (v == 0x80)
        {
          free(out);
          return NULL;
        }
        vals[k] = v;
      }
    }
    uint32_t triple = (vals[0] << 18) | (vals[1] << 12) | (vals[2] << 6) | vals[3];
    if (outpos < out_sz)
      out[outpos++] = (triple >> 16) & 0xFF;
    if (outpos < out_sz)
      out[outpos++] = (triple >> 8) & 0xFF;
    if (outpos < out_sz)
      out[outpos++] = triple & 0xFF;
  }
  *outlen = out_sz;
  return out;
}

/* -------------------- Encrypt / Decrypt (core) -------------------- */

char *encrypt_bytes_base64(const uint8_t *plaintext, size_t plen, const char *password)
{
  uint8_t key[32];
  derive_key(password, key);
  uint32_t first4 = be32(key); /* int.from_bytes(key[:4], "big") */
  uint32_t sha_low = sha256_low32(password);
  uint32_t seed32 = (sha_low ^ first4) & 0xFFFFFFFFu;
  WobbleRNG rng;
  wobble_init(&rng, seed32);

  WobbleRNG sbox_rng;
  wobble_init(&sbox_rng, seed32 ^ 0xA5A5A5A5u);
  uint8_t sbox[256];
  make_sbox(sbox, &sbox_rng);

  uint8_t *out = (uint8_t *)malloc(plen);
  if (!out)
    return NULL;

  size_t klen = 32;
  for (size_t i = 0; i < plen; ++i)
  {
    uint8_t pb = plaintext[i];
    uint8_t r = wobble_byte(&rng);
    uint8_t t = (uint8_t)((pb + r) & 0xFF);
    uint8_t kb = key[i % klen];
    t = t ^ kb;
    t = rol8(t, key[(i + 1) % klen]);
    t = sbox[t];
    out[i] = (uint8_t)((t + (i & 0xFF)) & 0xFF);
  }

  char *b64 = base64_encode(out, plen);
  free(out);
  return b64;
}

/* decrypt base64 to plaintext; returns malloc'ed buffer and sets *outlen; NULL on failure */
uint8_t *decrypt_bytes_from_base64(const char *b64cipher, size_t *outlen, const char *password)
{
  size_t clen;
  uint8_t *cdata = base64_decode(b64cipher, &clen);
  if (!cdata)
    return NULL;

  uint8_t key[32];
  derive_key(password, key);
  uint32_t first4 = be32(key);
  uint32_t sha_low = sha256_low32(password);
  uint32_t seed32 = (sha_low ^ first4) & 0xFFFFFFFFu;
  WobbleRNG rng;
  wobble_init(&rng, seed32);

  WobbleRNG sbox_rng;
  wobble_init(&sbox_rng, seed32 ^ 0xA5A5A5A5u);
  uint8_t sbox[256];
  make_sbox(sbox, &sbox_rng);

  uint8_t inv[256];
  for (int i = 0; i < 256; i++)
    inv[(int)sbox[i]] = (uint8_t)i;

  uint8_t *out = (uint8_t *)malloc(clen);
  if (!out)
  {
    free(cdata);
    return NULL;
  }

  size_t klen = 32;
  for (size_t i = 0; i < clen; i++)
  {
    uint8_t cb = cdata[i];
    uint8_t t = (uint8_t)((cb - (i & 0xFF)) & 0xFF); /* undo finishing tweak */
    t = inv[t];                                      /* undo sbox */
    t = ror8(t, key[(i + 1) % klen]);                /* undo rotate */
    uint8_t kb = key[i % klen];
    t = t ^ kb;                    /* undo xor with key */
    uint8_t r = wobble_byte(&rng); /* get same rng byte sequence */
    t = (uint8_t)((t - r) & 0xFF); /* undo add of rng byte */
    out[i] = t;
  }

  free(cdata);
  *outlen = clen;
  return out;
}

const char *check_input(const char *input)
{
  const char *stored_b64 = "5hGk4q3PoEOieDbkMvvblBwc3Z0iPYMrf09vr7XzPY/peGQyrrnLgJxd";
  if (!input)
    return "Looks like you're not hecker";

  size_t dlen = 0;
  uint8_t *dec = decrypt_bytes_from_base64(stored_b64, &dlen, "whatsthat");
  if (!dec)
  {
    return "Challenge issue contact #byamb4";
  }

  size_t in_len = strlen(input);
  int ok = 1;

  if (in_len != dlen)
  {
    ok = 0;
  }
  else
  {
    volatile uint8_t *vdec = dec;
    size_t i;
    for (i = 0; i < dlen; ++i)
    {
      uint8_t pbyte = (uint8_t)vdec[i];
      if ((uint8_t)input[i] != pbyte)
      {
        ok = 0;
        vdec[i] = (uint8_t)((i ^ 0xA5) & 0xFF);
        break;
      }
      vdec[i] = (uint8_t)((i ^ 0xA5) & 0xFF);
    }
    if (!ok && i < dlen)
    {
      for (size_t j = i + 1; j < dlen; ++j)
        vdec[j] = (uint8_t)((j ^ 0xA5) & 0xFF);
    }
  }

  free(dec);

  return ok ? "GO GET PRIZE!!!" : "Looks like you're not hecker";
}
