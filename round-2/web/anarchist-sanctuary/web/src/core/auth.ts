import { env } from '$env/dynamic/private';

import { decryptJWT, generateJWT } from './crypto/jwt';

export async function isAdmin(session: unknown): Promise<boolean> {
	if (typeof session !== 'string') {
		return false;
	}
	return session === env.APP_SECRET;
}

export async function getUsername(session: unknown): Promise<string | null> {
	if (typeof session !== 'string') {
		return null;
	}
	try {
		const claims = await decryptJWT(session);
		return claims.userId;
	} catch {
		return null;
	}
}

export async function issueSession(username: string): Promise<string> {
	return await generateJWT(username);
}
