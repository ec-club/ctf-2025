import crypto from 'crypto';
import { eq } from 'drizzle-orm';

import { user } from './db/schema';
import { getDB } from './db';

export function hashPassword(password: string): string {
	return crypto.createHash('sha256').update(password).digest('hex');
}

export async function createUser(username: string, password: string, email: string) {
	const hashedPassword = hashPassword(password);

	try {
		const newUser = await getDB()
			.insert(user)
			.values({
				username,
				password: hashedPassword,
				email
			})
			.returning();

		return { success: true, user: newUser[0] };
	} catch {
		return { success: false, error: 'Username already exists' };
	}
}

export async function verifyUser(username: string, password: string) {
	const hashedPassword = hashPassword(password);

	const foundUser = await getDB().select().from(user).where(eq(user.username, username)).limit(1);
	if (foundUser.length === 0) {
		return { success: false, error: 'Invalid username or password' };
	}
	if (foundUser[0].password !== hashedPassword) {
		return { success: false, error: 'Invalid username or password' };
	}

	return { success: true, user: foundUser[0] };
}

export async function getUserByUsername(username: string) {
	const foundUser = await getDB().select().from(user).where(eq(user.username, username)).limit(1);
	if (foundUser.length === 0) {
		return null;
	}
	return foundUser[0];
}
