import { eq } from 'drizzle-orm';
import { redirect, fail } from '@sveltejs/kit';

import { user } from '$lib/server/db/schema';
import { getDB } from '$lib/server/db';
import { getUserByUsername } from '$lib/server/auth';

import { generateFlag } from '$core/magic';
import { getUsername, isAdmin } from '$core/auth';

import type { PageServerLoad, Actions } from './$types';

export const load: PageServerLoad = async ({ cookies }) => {
	if (await isAdmin(cookies.get('session'))) {
		return {
			user: {
				id: generateFlag(cookies.get('x-user-identifier')),
				username: 'admin',
				email: 'admin@empasoft.ctf',
				status: 'Administrator',
				bio: 'The creator and overseer of the Anarchist Sanctuary.',
				createdAt: new Date('2103-03-07')
			}
		};
	}

	const username = await getUsername(cookies.get('session'));
	if (!username) {
		throw redirect(303, '/');
	}

	const foundUser = await getUserByUsername(username);
	if (!foundUser) {
		cookies.delete('session', { path: '/' });
		throw redirect(303, '/');
	}
	return {
		user: {
			id: foundUser.id,
			username: foundUser.username,
			email: foundUser.email,
			status: foundUser.status,
			bio: foundUser.bio || '',
			createdAt: foundUser.createdAt
		}
	};
};

export const actions: Actions = {
	updateBio: async ({ request, cookies }) => {
		const username = await getUsername(cookies.get('session'));
		if (!username) {
			return fail(401, { error: 'Unauthorized' });
		}

		const data = await request.formData();
		const bio = data.get('bio')?.toString() || '';

		if (bio.length > 500) {
			return fail(400, { error: 'Bio must be less than 500 characters' });
		}

		try {
			await getDB().update(user).set({ bio }).where(eq(user.username, username));
			return { success: true };
		} catch {
			return fail(500, { error: 'Failed to update bio' });
		}
	}
};
