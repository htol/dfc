import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { spawn } from "node:child_process";

/**
 * webfetch: local anti-ban web fetching for agents.
 *
 * Talks to the local `webfetch` daemon (https://github.com/tol/webfetch,
 * sources at ~/repos/webfetch) which impersonates a real Chrome at the TLS
 * layer and falls back to a real headless Chromium for JS/challenge pages.
 * Falls back to the `webfetch` CLI (one-shot mode) when the daemon is down.
 */

const DAEMON_ADDR = process.env.WEBFETCH_ADDR ?? "127.0.0.1:8765";

interface FetchOptions {
	format?: string;
	raw?: boolean;
	force?: boolean;
	engine?: string;
	maxBytes?: number;
	allowPrivate?: boolean;
}

interface FetchResponse {
	url: string;
	finalUrl: string;
	status: number;
	contentType: string;
	engine: string;
	cached: boolean;
	truncated: boolean;
	content: string;
	error?: string;
}

async function fetchViaDaemon(url: string, opts: FetchOptions, signal: AbortSignal): Promise<FetchResponse> {
	const resp = await fetch(`http://${DAEMON_ADDR}/fetch`, {
		method: "POST",
		headers: { "content-type": "application/json" },
		body: JSON.stringify({ url, timeoutSec: 60, ...opts }),
		signal,
	});
	return (await resp.json()) as FetchResponse;
}

function fetchViaCLI(url: string, opts: FetchOptions, signal: AbortSignal): Promise<FetchResponse> {
	return new Promise((resolve, reject) => {
		const args = ["get", url, "--json"];
		if (opts.format && opts.format !== "markdown") args.push("-f", opts.format);
		if (opts.raw) args.push("-raw");
		if (opts.force) args.push("-force");
		if (opts.engine && opts.engine !== "auto") args.push("-engine", opts.engine);
		if (opts.maxBytes) args.push("-max-bytes", String(opts.maxBytes));
		if (opts.allowPrivate) args.push("-allow-private");
		const proc = spawn("webfetch", args, { stdio: ["ignore", "pipe", "pipe"] });
		let out = "";
		let err = "";
		proc.stdout.on("data", (d: Buffer) => (out += d));
		proc.stderr.on("data", (d: Buffer) => (err += d));
		proc.on("error", reject);
		proc.on("close", (code) => {
			if (code !== 0) {
				reject(new Error(err.trim() || `webfetch CLI exited with code ${code}`));
				return;
			}
			try {
				resolve(JSON.parse(out) as FetchResponse);
			} catch (e) {
				reject(new Error(`bad CLI output: ${out.slice(0, 200)}`));
			}
		});
		signal.addEventListener("abort", () => proc.kill("SIGTERM"), { once: true });
	});
}

async function fetchPage(url: string, opts: FetchOptions, signal: AbortSignal): Promise<FetchResponse> {
	try {
		return await fetchViaDaemon(url, opts, signal);
	} catch (e) {
		// Daemon down or unreachable: one-shot CLI mode.
		return await fetchViaCLI(url, opts, signal);
	}
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "webfetch",
		label: "WebFetch",
		description:
			"Fetch a web page over HTTP(S) and return its main content as clean markdown. " +
			"Uses a local daemon that impersonates a real Chrome browser (real TLS fingerprint, " +
			"browser fallback for JavaScript and anti-bot pages) with caching, so it works on " +
			"sites that block plain HTTP clients. Prefer this tool over `curl`/`wget` in bash " +
			"whenever you need to read content from the web.",
		parameters: Type.Object({
			url: Type.String({ description: "Absolute URL to fetch (https:// or http://)" }),
			format: Type.Optional(
				Type.String({
					description: "Output format: markdown (default), html, or text",
				}),
			),
			maxBytes: Type.Optional(
				Type.Number({ description: "Truncate content to at most this many bytes (default 200000)" }),
			),
			raw: Type.Optional(
				Type.Boolean({
					description: "Skip main-content extraction and return the whole document (for non-article pages like docs indexes)",
				}),
			),
			force: Type.Optional(
				Type.Boolean({ description: "Bypass the local cache and refetch" }),
			),
			engine: Type.Optional(
				Type.String({ description: "auto (default), fast (HTTP client only), or browser (real Chromium)" }),
			),
			allowPrivate: Type.Optional(
				Type.Boolean({ description: "Allow fetching private/localhost addresses" }),
			),
		}),
		async execute(_toolCallId, params, signal) {
			const res = await fetchPage(
				params.url,
				{
					format: params.format ?? "markdown",
					raw: params.raw,
					force: params.force,
					engine: params.engine,
					maxBytes: params.maxBytes,
					allowPrivate: params.allowPrivate,
				},
				signal,
			);
			if (res.error) {
				return {
					content: [{ type: "text", text: `webfetch error: ${res.error}` }],
					details: { error: res.error },
				};
			}
			let text = res.content;
			if (!text) {
				text = `(empty response from ${res.finalUrl})`;
			}
			const meta = `[webfetch ${res.status} ${res.engine}${res.cached ? " cached" : ""}${res.truncated ? " truncated" : ""} ${res.finalUrl}]`;
			return {
				content: [{ type: "text", text: `${meta}\n\n${text}` }],
				details: {
					status: res.status,
					engine: res.engine,
					cached: res.cached,
					truncated: res.truncated,
					finalUrl: res.finalUrl,
					contentType: res.contentType,
				},
			};
		},
	});
}
