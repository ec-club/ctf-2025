export async function register() {
  if (process.env.NEXT_RUNTIME === "nodejs") {
    if (!process.env.APP_SECRET) {
      process.env.APP_SECRET = Buffer.from(
        crypto.getRandomValues(new Uint8Array(32))
      ).toString("base64url");
    }
    await import("./models/db");
  }
}
