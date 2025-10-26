<script lang="ts">
	import logo from '$assets/anarchisttt.webp';
	import type { PageData } from './$types';

	interface Props {
		data: PageData;
		form?: any;
	}

	let { data, form }: Props = $props();

	let isEditingBio = $state(false);
	let bioText = $state(data.user?.bio || '');

	function formatDate(date: Date | null) {
		if (!date) return 'N/A';
		return new Date(date).toLocaleDateString('en-US', {
			year: 'numeric',
			month: 'long',
			day: 'numeric'
		});
	}

	function startEdit() {
		bioText = data.user?.bio || '';
		isEditingBio = true;
	}

	function cancelEdit() {
		isEditingBio = false;
		bioText = data.user?.bio || '';
	}
</script>

<svelte:head>
	<title>My Profile | Anarchist Sanctuary</title>
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

				<div class="flex items-center gap-3">
					<a
						href="/u/{data.user.username}"
						class="rounded-lg bg-purple-600 px-4 py-2 text-white transition hover:bg-purple-700"
					>
						View Public Profile
					</a>
					<form method="POST" action="/?/signout">
						<button
							type="submit"
							class="rounded-lg bg-zinc-800 px-4 py-2 text-white transition hover:bg-zinc-700"
						>
							Sign Out
						</button>
					</form>
				</div>
			</div>
		</div>
	</header>

	<!-- Profile Content -->
	<div class="container mx-auto px-4 py-12">
		<div class="mx-auto max-w-3xl">
			<!-- Profile Header -->
			<div class="mb-12 text-center">
				<div
					class="mb-4 inline-flex h-24 w-24 items-center justify-center rounded-full bg-gradient-to-r from-purple-600 to-pink-600"
				>
					<span class="text-4xl font-bold text-white">
						{data.user.username.charAt(0).toUpperCase()}
					</span>
				</div>
				<h1 class="mb-2 text-4xl font-bold text-white">{data.user.username}</h1>
				<p class="text-zinc-400">Anarchist Sanctuary {data.user.status}</p>
			</div>
			<!-- Profile Information -->
			<div class="overflow-hidden rounded-xl border border-zinc-800 bg-zinc-900/50">
				<div class="border-b border-zinc-800 px-8 py-6">
					<h2 class="text-2xl font-bold text-white">Profile Information</h2>
				</div>

				<div class="divide-y divide-zinc-800">
					<!-- User ID -->
					<div class="flex flex-col gap-2 px-8 py-6 sm:flex-row sm:items-center sm:justify-between">
						<div>
							<h3 class="mb-1 text-sm font-medium text-zinc-400">User ID</h3>
							<p class="font-mono text-sm break-all text-white">{data.user.id}</p>
						</div>
					</div>

					<!-- Username -->
					<div class="flex flex-col gap-2 px-8 py-6 sm:flex-row sm:items-center sm:justify-between">
						<div>
							<h3 class="mb-1 text-sm font-medium text-zinc-400">Username</h3>
							<p class="text-lg font-semibold text-white">{data.user.username}</p>
						</div>
						<span
							class="inline-flex items-center self-start rounded-full bg-purple-600/20 px-3 py-1 text-sm text-purple-400 sm:self-auto"
						>
							Active
						</span>
					</div>

					<!-- Email -->
					<div class="flex flex-col gap-2 px-8 py-6 sm:flex-row sm:items-center sm:justify-between">
						<div>
							<h3 class="mb-1 text-sm font-medium text-zinc-400">Email</h3>
							<p class="text-white">{data.user.email}</p>
						</div>
					</div>

					<!-- Status -->
					<div class="flex flex-col gap-2 px-8 py-6 sm:flex-row sm:items-center sm:justify-between">
						<div>
							<h3 class="mb-1 text-sm font-medium text-zinc-400">Status</h3>
							<p class="text-lg font-semibold text-white">{data.user.status}</p>
						</div>
						<span
							class="inline-flex items-center self-start rounded-full bg-pink-600/20 px-3 py-1 text-sm text-pink-400 sm:self-auto"
						>
							{data.user.status}
						</span>
					</div>

					<!-- Member Since -->
					<div class="flex flex-col gap-2 px-8 py-6 sm:flex-row sm:items-center sm:justify-between">
						<div>
							<h3 class="mb-1 text-sm font-medium text-zinc-400">Member Since</h3>
							<p class="text-white">{formatDate(data.user.createdAt)}</p>
						</div>
					</div>
				</div>
			</div>

			<!-- Stats Cards -->
			<div class="mt-8 grid gap-6 md:grid-cols-3">
				<div class="rounded-xl border border-zinc-800 bg-zinc-900/50 p-6 text-center">
					<div class="mb-2 text-3xl">🎵</div>
					<h3 class="mb-1 text-2xl font-bold text-white">{data.user.status}</h3>
					<p class="text-sm text-zinc-400">Status</p>
				</div>
				<div class="rounded-xl border border-zinc-800 bg-zinc-900/50 p-6 text-center">
					<div class="mb-2 text-3xl">🏴</div>
					<h3 class="mb-1 text-2xl font-bold text-white">Sanctuary</h3>
					<p class="text-sm text-zinc-400">Member</p>
				</div>

				<div class="rounded-xl border border-zinc-800 bg-zinc-900/50 p-6 text-center">
					<div class="mb-2 text-3xl">⭐</div>
					<h3 class="mb-1 text-2xl font-bold text-white">Active</h3>
					<p class="text-sm text-zinc-400">Community</p>
				</div>
			</div>

			<!-- About Section -->
			<div class="mt-8 rounded-xl border border-zinc-800 bg-zinc-900/30 p-8">
				<div class="mb-4 flex items-center justify-between">
					<h2 class="text-2xl font-bold text-white">About</h2>
					{#if !isEditingBio}
						<button
							onclick={startEdit}
							class="rounded-lg bg-purple-600 px-4 py-2 text-sm text-white transition hover:bg-purple-700"
						>
							Edit Bio
						</button>
					{/if}
				</div>

				{#if form?.error}
					<div class="mb-4 rounded border border-red-500/50 bg-red-500/10 p-3 text-sm text-red-400">
						{form.error}
					</div>
				{/if}

				{#if form?.success}
					<div
						class="mb-4 rounded border border-green-500/50 bg-green-500/10 p-3 text-sm text-green-400"
					>
						Bio updated successfully!
					</div>
				{/if}

				{#if isEditingBio}
					<form method="POST" action="?/updateBio" class="space-y-4">
						<div>
							<textarea
								name="bio"
								bind:value={bioText}
								rows="6"
								maxlength="500"
								placeholder="Tell us about yourself..."
								class="w-full resize-none rounded-lg border border-zinc-700 bg-zinc-800 px-4 py-3 text-white placeholder-zinc-500 focus:border-transparent focus:ring-2 focus:ring-purple-500"
							></textarea>
							<p class="mt-1 text-xs text-zinc-500">{bioText.length}/500 characters</p>
						</div>

						<div class="flex gap-3">
							<button
								type="submit"
								class="rounded-lg bg-purple-600 px-6 py-2 font-medium text-white transition hover:bg-purple-700"
							>
								Save Bio
							</button>
							<button
								type="button"
								onclick={cancelEdit}
								class="rounded-lg bg-zinc-800 px-6 py-2 text-white transition hover:bg-zinc-700"
							>
								Cancel
							</button>
						</div>
					</form>
				{:else}
					<p class="leading-relaxed text-zinc-300">
						{#if data.user?.bio && data.user.bio.trim()}
							{data.user.bio}
						{:else}
							<span class="text-zinc-500 italic"
								>No bio yet. Click "Edit Bio" to add information about yourself.</span
							>
						{/if}
					</p>
				{/if}
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
