import { fail, redirect } from '@sveltejs/kit';

import { verifyUser } from '$lib/server/auth';
import { getUsername, issueSession } from '$core/auth';

import type { PageServerLoad, Actions } from './$types';

export const load: PageServerLoad = async ({ cookies }) => {
	const session = await getUsername(cookies.get('session'));
	if (session) {
		return {
			loggedIn: true,
			username: session
		};
	}
	return {
		loggedIn: false
	};
};

export const actions: Actions = {
	signin: async ({ request, cookies, ...event }) => {
		const data = await request.formData();
		const username = data.get('username')?.toString();
		const password = data.get('password')?.toString();

		if (!username || !password) {
			return fail(400, { error: 'Username and password are required' });
		}

		const result = await verifyUser(username, password);
		if (!result.success) {
			return fail(400, { error: result.error });
		}

		console.log(`Signing in as ${username} from ${event.getClientAddress()}`);
		cookies.set('session', await issueSession(username), {
			path: '/',
			httpOnly: true,
			sameSite: 'strict',
			maxAge: 60 * 60 * 24 * 7 // 1 week
		});

		return { success: true };
	},

	signout: async ({ cookies }) => {
		cookies.delete('session', { path: '/' });
		throw redirect(303, '/');
	}
};
