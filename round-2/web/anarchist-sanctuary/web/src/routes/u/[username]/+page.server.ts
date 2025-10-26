import { error } from '@sveltejs/kit';

import { getUserByUsername } from '$lib/server/auth';

import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params }) => {
	if (params.username === 'admin') {
		return {
			user: {
				username: 'admin',
				status: 'Administrator',
				bio: 'The creator and overseer of the <i>Anarchist Sanctuary</i>.',
				createdAt: new Date('2103-03-07')
			}
		};
	}

	const user = await getUserByUsername(params.username);
	if (!user) {
		throw error(404, 'User not found');
	}
	console.log(`Send the payload of user ${user.username}: ${user.bio}`);
	return {
		user: {
			username: user.username,
			status: user.status,
			bio: user.bio ?? '',
			createdAt: user.createdAt
		}
	};
};
