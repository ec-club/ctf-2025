import { migrate } from 'drizzle-orm/better-sqlite3/migrator';
import type { ServerInit } from '@sveltejs/kit';

import { getDB } from '$lib/server/db';

export const init: ServerInit = async () => {
	if (!('APP_SECRET' in process.env)) {
		throw new Error('APP_SECRET is not set in environment variables');
	}
	migrate(getDB(), { migrationsFolder: './drizzle' });
};
