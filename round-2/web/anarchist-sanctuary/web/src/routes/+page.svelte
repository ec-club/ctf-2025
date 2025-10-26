<script lang="ts">
	import logo from '$assets/anarchisttt.webp';

	import type { PageData } from './$types';

	interface Props {
		data: PageData;
		form?: any;
	}

	let { data, form }: Props = $props();

	let showSignIn = $state(false);

	const members = [
		{
			name: 'kets4eki',
			role: 'Artist',
			description: 'Underground artist known for dark and atmospheric soundscapes',
			image: '🎤'
		},
		{
			name: 'Asteria',
			role: 'Producer',
			description: 'Master producer crafting unique beats and experimental sounds',
			image: '🎹'
		},
		{
			name: 'd3r',
			role: 'Creative Director',
			description: 'Visionary behind the aesthetic and artistic direction',
			image: '🎨'
		}
	];
</script>

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

				{#if data.loggedIn}
					<div class="flex items-center gap-4">
						<span class="text-zinc-300"
							>Welcome, <span class="text-purple-400">{data.username}</span></span
						>
						<a
							href="/profile"
							class="rounded-lg bg-purple-600 px-4 py-2 text-white transition hover:bg-purple-700"
						>
							Profile
						</a>
						<form method="POST" action="?/signout">
							<button
								type="submit"
								class="rounded-lg bg-zinc-800 px-4 py-2 text-white transition hover:bg-zinc-700"
							>
								Sign Out
							</button>
						</form>
					</div>
				{:else}
					<div class="flex gap-3">
						<a
							href="/register"
							class="rounded-lg bg-purple-600 px-4 py-2 text-white transition hover:bg-purple-700"
						>
							Register
						</a>
						<button
							onclick={() => (showSignIn = !showSignIn)}
							class="rounded-lg bg-zinc-800 px-4 py-2 text-white transition hover:bg-zinc-700"
						>
							Sign In
						</button>
					</div>
				{/if}
			</div>

			<!-- Sign In Form -->
			{#if showSignIn && !data.loggedIn}
				<div class="mt-6 max-w-md rounded-lg border border-zinc-800 bg-zinc-900/80 p-6">
					<h3 class="mb-4 text-xl font-semibold text-white">Sign In</h3>

					{#if form?.error}
						<div
							class="mb-4 rounded border border-red-500/50 bg-red-500/10 p-3 text-sm text-red-400"
						>
							{form.error}
						</div>
					{/if}

					<form method="POST" action="?/signin" class="space-y-4">
						<div>
							<label for="username" class="mb-2 block text-sm font-medium text-zinc-300"
								>Username</label
							>
							<input
								type="text"
								id="username"
								name="username"
								required
								class="w-full rounded-lg border border-zinc-700 bg-zinc-800 px-4 py-2 text-white focus:border-transparent focus:ring-2 focus:ring-purple-500"
							/>
						</div>

						<div>
							<label for="password" class="mb-2 block text-sm font-medium text-zinc-300"
								>Password</label
							>
							<input
								type="password"
								id="password"
								name="password"
								required
								class="w-full rounded-lg border border-zinc-700 bg-zinc-800 px-4 py-2 text-white focus:border-transparent focus:ring-2 focus:ring-purple-500"
							/>
						</div>

						<button
							type="submit"
							class="w-full rounded-lg bg-purple-600 px-4 py-2 font-medium text-white transition hover:bg-purple-700"
						>
							Sign In
						</button>
					</form>
				</div>
			{/if}
		</div>
	</header>

	<!-- Hero Section -->
	<section class="px-4 py-20">
		<div class="container mx-auto text-center">
			<div class="mb-6 text-8xl">🏴</div>
			<h2 class="mb-4 text-5xl font-bold text-white md:text-6xl">Welcome to the Sanctuary</h2>
			<p class="mx-auto max-w-2xl text-xl text-zinc-400">
				An underground collective pushing the boundaries of experimental music and artistic
				expression
			</p>
		</div>
	</section>

	<!-- Members Section -->
	<section class="bg-black/30 px-4 py-16">
		<div class="container mx-auto">
			<h2 class="mb-12 text-center text-4xl font-bold text-white">
				The <span class="bg-gradient-to-r from-purple-400 to-pink-600 bg-clip-text text-transparent"
					>Collective</span
				>
			</h2>

			<div class="mx-auto grid max-w-5xl gap-8 md:grid-cols-3">
				{#each members as member}
					<div
						class="group rounded-xl border border-zinc-800 bg-zinc-900/50 p-8 transition hover:border-purple-500/50"
					>
						<div class="mb-4 text-center text-6xl transition group-hover:scale-110">
							{member.image}
						</div>
						<h3 class="mb-2 text-2xl font-bold text-white">{member.name}</h3>
						<p class="mb-3 text-sm font-medium text-purple-400">{member.role}</p>
						<p class="text-zinc-400">{member.description}</p>
					</div>
				{/each}
			</div>
		</div>
	</section>

	<!-- About Section -->
	<section class="px-4 py-16">
		<div class="container mx-auto max-w-4xl">
			<div class="rounded-xl border border-zinc-800 bg-zinc-900/30 p-8 md:p-12">
				<h2 class="mb-6 text-3xl font-bold text-white">About the Sanctuary</h2>
				<div class="prose max-w-none prose-invert">
					<p class="mb-4 leading-relaxed text-zinc-300">
						Anarchist Sanctuary is more than just a music collective—it's a movement. Born from the
						underground scene, we represent the raw, unfiltered expression of artistic freedom.
					</p>
					<p class="mb-4 leading-relaxed text-zinc-300">
						Our members—kets4eki, Asteria, and d3r—each bring their unique vision to create
						something truly extraordinary. Together, we craft soundscapes that defy convention and
						challenge the status quo.
					</p>
					<p class="leading-relaxed text-zinc-300">
						Join our community to get exclusive access to unreleased tracks, behind-the-scenes
						content, and connect with fellow fans who share your passion for experimental music.
					</p>
				</div>
			</div>
		</div>
	</section>

	<!-- Call to Action -->
	{#if !data.loggedIn}
		<section class="px-4 py-20">
			<div class="container mx-auto text-center">
				<h2 class="mb-4 text-4xl font-bold text-white">Join the Movement</h2>
				<p class="mb-8 text-lg text-zinc-400">
					Become part of the Anarchist Sanctuary community today
				</p>
				<a
					href="/register"
					class="inline-block rounded-lg bg-gradient-to-r from-purple-600 to-pink-600 px-8 py-4 text-lg font-semibold text-white transition hover:from-purple-700 hover:to-pink-700"
				>
					Register Now
				</a>
			</div>
		</section>
	{:else}
		<section class="px-4 py-20">
			<div class="container mx-auto text-center">
				<h2 class="mb-4 text-4xl font-bold text-white">Welcome Back, Fan! 🎵</h2>
				<p class="text-lg text-zinc-400">You're now part of the Anarchist Sanctuary community</p>
			</div>
		</section>
	{/if}

	<!-- Footer -->
	<footer class="border-t border-zinc-800 px-4 py-8">
		<div class="container mx-auto text-center text-zinc-500">
			<p>&copy; 2025 Anarchist Sanctuary. All rights reserved.</p>
			<p class="mt-2 text-sm">Underground. Unfiltered. Unstoppable.</p>
		</div>
	</footer>
</div>
