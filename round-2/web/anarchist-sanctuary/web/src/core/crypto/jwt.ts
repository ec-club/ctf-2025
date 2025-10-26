import { nanoid } from 'nanoid';
import { EncryptJWT, jwtDecrypt } from 'jose';

import { getSecretKeyWithPurpose } from './keys';

export async function getTokenKey() {
	const rawKey = new Uint8Array(await getSecretKeyWithPurpose('session-token'));
	return await crypto.subtle.importKey('raw', rawKey, { name: 'AES-GCM' }, false, [
		'encrypt',
		'decrypt'
	]);
}

export async function generateJWT(userId: string) {
	return await new EncryptJWT({ sub: userId })
		.setProtectedHeader({ alg: 'dir', enc: 'A256GCM' })
		.setExpirationTime('24h')
		.setJti(nanoid())
		.encrypt(await getTokenKey());
}
export async function decryptJWT(token: string) {
	const { payload } = await jwtDecrypt(token, await getTokenKey(), {
		requiredClaims: ['exp', 'jti', 'sub'],
		keyManagementAlgorithms: ['dir'],
		contentEncryptionAlgorithms: ['A256GCM']
	});
	return { userId: payload.sub as string };
}
