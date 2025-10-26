<script lang="ts">
	import logo from '$assets/anarchisttt.webp';

	interface Props {
		form?: any;
	}

	let { form }: Props = $props();
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
			</div>
		</div>
	</header>

	<!-- Registration Content -->
	<div class="flex items-center justify-center px-4 py-12">
		<div class="w-full max-w-md">
			<div class="rounded-xl border border-zinc-800 bg-zinc-900/50 p-8 shadow-2xl">
				<div class="mb-8 text-center">
					<div class="mb-4 text-6xl">🏴</div>
					<h1
						class="mb-2 bg-gradient-to-r from-purple-400 to-pink-600 bg-clip-text text-3xl font-bold text-transparent"
					>
						Join the Sanctuary
					</h1>
					<p class="text-zinc-400">Create your account and become part of the collective</p>
				</div>

				{#if form?.error}
					<div class="mb-6 rounded-lg border border-red-500/50 bg-red-500/10 p-4 text-red-400">
						{form.error}
					</div>
				{/if}

				<form method="POST" class="space-y-5">
					<div>
						<label for="username" class="mb-2 block text-sm font-medium text-zinc-300">
							Username
						</label>
						<input
							type="text"
							id="username"
							name="username"
							required
							minlength="3"
							maxlength="20"
							class="w-full rounded-lg border border-zinc-700 bg-zinc-800 px-4 py-3 text-white placeholder-zinc-500 transition focus:border-transparent focus:ring-2 focus:ring-purple-500"
							placeholder="Choose a username"
						/>
					</div>

					<div>
						<label for="email" class="mb-2 block text-sm font-medium text-zinc-300"> Email </label>
						<input
							type="email"
							id="email"
							name="email"
							required
							class="w-full rounded-lg border border-zinc-700 bg-zinc-800 px-4 py-3 text-white placeholder-zinc-500 transition focus:border-transparent focus:ring-2 focus:ring-purple-500"
							placeholder="your@email.com"
						/>
					</div>

					<div>
						<label for="password" class="mb-2 block text-sm font-medium text-zinc-300">
							Password
						</label>
						<input
							type="password"
							id="password"
							name="password"
							required
							minlength="6"
							class="w-full rounded-lg border border-zinc-700 bg-zinc-800 px-4 py-3 text-white placeholder-zinc-500 transition focus:border-transparent focus:ring-2 focus:ring-purple-500"
							placeholder="Create a password"
						/>
						<p class="mt-1 text-xs text-zinc-500">Must be at least 6 characters</p>
					</div>

					<div>
						<label for="confirmPassword" class="mb-2 block text-sm font-medium text-zinc-300">
							Confirm Password
						</label>
						<input
							type="password"
							id="confirmPassword"
							name="confirmPassword"
							required
							minlength="6"
							class="w-full rounded-lg border border-zinc-700 bg-zinc-800 px-4 py-3 text-white placeholder-zinc-500 transition focus:border-transparent focus:ring-2 focus:ring-purple-500"
							placeholder="Confirm your password"
						/>
					</div>

					<button
						type="submit"
						class="w-full rounded-lg bg-gradient-to-r from-purple-600 to-pink-600 px-4 py-3 font-semibold text-white transition hover:from-purple-700 hover:to-pink-700"
					>
						Create Account
					</button>
				</form>

				<div class="mt-6 text-center">
					<p class="text-sm text-zinc-400">
						Already have an account?
						<a href="/" class="font-medium text-purple-400 hover:text-purple-300">Sign in</a>
					</p>
				</div>
			</div>

			<!-- Info Box -->
			<div class="mt-6 rounded-lg border border-zinc-800 bg-zinc-900/30 p-4">
				<p class="text-center text-sm text-zinc-400">
					🎵 Get exclusive access to unreleased tracks and community content
				</p>
			</div>
		</div>
	</div>
</div>
