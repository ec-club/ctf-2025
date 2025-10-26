const express = require('express');
const puppeteer = require('puppeteer');

const app = express();
const PORT = 3000;

const appBaseUrl = new URL(process.env.APP_ORIGIN);

const cookieBaseOptions = {
	domain: appBaseUrl.hostname,
	path: '/',
	httpOnly: true,
	sameSite: 'strict',
}
app.get('/visit/:username', async (req, res) => {
	const requester = req.query['x-requester'];
	if (!requester) {
		return res.status(400).send('Unknown requester');
	}

	const username = req.params.username;
	const browser = await puppeteer.launch({
		acceptInsecureCerts: !!process.env.BASIC_AUTH,
	});

	browser.setCookie({
		name: "session",
		value: process.env.APP_SECRET,
		...cookieBaseOptions
	}, {
		name: "x-user-identifier",
		value: requester,
		...cookieBaseOptions
	});

	const page = await browser.newPage();
	if (process.env.BASIC_AUTH) {
		const [username, password] = process.env.BASIC_AUTH.split(':');
		await page.authenticate({ username, password });
	}

	page.on('request', (request) => console.log(`Request: ${request.url()}`));
	page.on('response', (response) => console.log(`Response: ${response.url()}`));
	page.on('requestfailed', (request) => console.log(`Request failed: ${request.url()}`));
	page.on('requestfinished', (request) => console.log(`Request finished: ${request.url()}`));
	page.on('console', (message) => {
		console.log(`PAGE LOG: ${message.text()}`);
	});

	const path = `/u/${encodeURIComponent(username)}`;
	console.log(`Visiting ${path}`);
	await page.goto(`${process.env.APP_ORIGIN}${path}`, { waitUntil: 'networkidle0' });
	await browser.close();
	res.send('OK');
});

app.listen(PORT, () => {
	console.log(`🚀 Server is running on http://localhost:${PORT}`);
});
