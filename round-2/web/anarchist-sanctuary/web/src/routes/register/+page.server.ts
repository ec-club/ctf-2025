import { fail, redirect } from '@sveltejs/kit';

import { createUser } from '$lib/server/auth';
import { issueSession } from '$core/auth';

import type { Actions } from './$types';

export const actions: Actions = {
	default: async ({ request, cookies }) => {
		const data = await request.formData();
		const username = data.get('username')?.toString();
		const password = data.get('password')?.toString();
		const email = data.get('email')?.toString();
		const confirmPassword = data.get('confirmPassword')?.toString();

		if (!username || !password || !email || !confirmPassword) {
			return fail(400, { error: 'All fields are required' });
		}

		if (password !== confirmPassword) {
			return fail(400, { error: 'Passwords do not match' });
		}

		if (password.length < 6) {
			return fail(400, { error: 'Password must be at least 6 characters' });
		}

		if (username === 'admin') {
			return fail(403, 'Forbidden');
		}
		const result = await createUser(username, password, email);
		if (!result.success) {
			return fail(400, { error: result.error });
		}

		cookies.set('session', await issueSession(username), {
			path: '/',
			httpOnly: true,
			sameSite: 'strict',
			maxAge: 60 * 60 * 24 * 7 // 1 week
		});
		throw redirect(303, '/');
	}
};
