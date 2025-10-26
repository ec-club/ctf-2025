<script lang="ts">
	import logo from '$assets/anarchisttt.webp';
	import type { PageData } from './$types';

	interface Props {
		data: PageData;
	}

	let { data }: Props = $props();

	function formatDate(date: Date | null) {
		if (!date) return 'N/A';
		return new Date(date).toLocaleDateString('en-US', {
			year: 'numeric',
			month: 'long',
			day: 'numeric'
		});
	}
</script>

<svelte:head>
	<title>{data.user.username} | Anarchist Sanctuary</title>
</svelte:head>

<div class="min-h-screen bg-gradient-to-br from-zinc-900 via-black to-zinc-900">
	<!-- Header -->
	<header class="border-b border-zinc-800 bg-black/50 backdrop-blur-sm">
		<div class="container mx-auto px-4 py-6">
			<div class="flex items-center justify-between">
				<header>
					<a href="/">
						<img class="h-24" src={logo} alt="Anarchist Sanctuary" />
					</a>
				</header>
			</div>
		</div>
	</header>

	<!-- Public Profile Content -->
	<div class="container mx-auto px-4 py-12">
		<div class="mx-auto max-w-3xl">
			<!-- Profile Header -->
			<div class="mb-12 text-center">
				<div
					class="mb-6 inline-flex h-32 w-32 items-center justify-center rounded-full bg-gradient-to-r from-purple-600 to-pink-600 shadow-lg shadow-purple-500/50"
				>
					<span class="text-5xl font-bold text-white">
						{data.user.username.charAt(0).toUpperCase()}
					</span>
				</div>
				<h1 class="mb-3 text-5xl font-bold text-white">{data.user.username}</h1>
				<div class="mb-2 flex items-center justify-center gap-3">
					<span
						class="inline-flex items-center rounded-full border border-pink-500/30 bg-pink-600/20 px-4 py-2 text-lg font-medium text-pink-400"
					>
						{data.user.status}
					</span>
				</div>
				<p class="text-lg text-zinc-400">Anarchist Sanctuary Community Member</p>
			</div>

			<!-- Membership Info Card -->
			<div class="mb-8 overflow-hidden rounded-xl border border-zinc-800 bg-zinc-900/50">
				<div class="border-b border-zinc-800 px-8 py-6">
					<h2 class="text-2xl font-bold text-white">Membership Details</h2>
				</div>

				<div class="divide-y divide-zinc-800">
					<!-- Username -->
					<div class="px-8 py-6">
						<h3 class="mb-2 text-sm font-medium text-zinc-400">Username</h3>
						<p class="text-xl font-semibold text-white">{data.user.username}</p>
					</div>

					<!-- Status -->
					<div class="px-8 py-6">
						<h3 class="mb-2 text-sm font-medium text-zinc-400">Status</h3>
						<div class="flex items-center gap-3">
							<p class="text-xl font-semibold text-white">{data.user.status}</p>
							<span class="text-2xl">🎵</span>
						</div>
					</div>

					<!-- Member Since -->
					<div class="px-8 py-6">
						<h3 class="mb-2 text-sm font-medium text-zinc-400">Member Since</h3>
						<p class="text-xl font-semibold text-white">{formatDate(data.user.createdAt)}</p>
					</div>
				</div>
			</div>

			<!-- About Section -->
			<div class="rounded-xl border border-zinc-800 bg-zinc-900/30 p-8">
				<h2 class="mb-4 flex items-center gap-2 text-2xl font-bold text-white">
					<span>🏴</span>
					About
				</h2>
				{#if data.user.bio && data.user.bio.trim()}
					<p class="leading-relaxed text-zinc-300">
						{@html data.user.bio}
					</p>
				{:else}
					<p class="leading-relaxed text-zinc-500 italic">
						{data.user.username} is a valued member of the Anarchist Sanctuary community, supporting
						underground music and artistic expression. As a {data.user.status}, they are part of the
						collective that celebrates the work of kets4eki, Asteria, and d3r.
					</p>
				{/if}
			</div>
			<!-- Stats Grid -->
			<div class="mt-8 grid gap-6 md:grid-cols-3">
				<div
					class="rounded-xl border border-zinc-800 bg-zinc-900/50 p-6 text-center transition hover:border-purple-500/50"
				>
					<div class="mb-3 text-4xl">🎵</div>
					<h3 class="mb-1 text-xl font-bold text-white">{data.user.status}</h3>
					<p class="text-sm text-zinc-400">Current Status</p>
				</div>

				<div
					class="rounded-xl border border-zinc-800 bg-zinc-900/50 p-6 text-center transition hover:border-purple-500/50"
				>
					<div class="mb-3 text-4xl">🏴</div>
					<h3 class="mb-1 text-xl font-bold text-white">Sanctuary</h3>
					<p class="text-sm text-zinc-400">Community</p>
				</div>

				<div
					class="rounded-xl border border-zinc-800 bg-zinc-900/50 p-6 text-center transition hover:border-purple-500/50"
				>
					<div class="mb-3 text-4xl">⭐</div>
					<h3 class="mb-1 text-xl font-bold text-white">Active</h3>
					<p class="text-sm text-zinc-400">Member</p>
				</div>
			</div>
		</div>
	</div>

	<!-- Footer -->
	<footer class="mt-12 border-t border-zinc-800 px-4 py-8">
		<div class="container mx-auto text-center text-zinc-500">
			<p>&copy; 2025 Anarchist Sanctuary. All rights reserved.</p>
		</div>
	</footer>
</div>
