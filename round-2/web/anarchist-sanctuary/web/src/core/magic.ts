import { nanoid } from 'nanoid';

export function generateFlag(identifier: unknown): string {
	const flag =
		process.env.FLAG?.replace('$1', nanoid(16)).replace('$2', nanoid(8)) ??
		'Something went wrong. Please contact an admin.';
	console.log(
		`Releasing flag ${flag} to ${typeof identifier === 'string' ? identifier : 'unknown'}`
	);
	return flag;
}
