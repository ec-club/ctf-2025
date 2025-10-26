export function GET() {
	return new Response(
		`<html><body>HAHAHAH GET RICKROLLED! <!-- tg: ectf_wujek_bot --></body></html>`,
		{
			status: 302,
			headers: {
				Location: 'https://youtu.be/dQw4w9WgXcQ',
				'Content-Type': 'text/html; charset=utf-8',
				'My-Telega': 'ectf_wujek_bot'
			}
		}
	);
}
