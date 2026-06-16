import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const EXT_ID = "git-info";

type GitInfo = {
	inside: boolean;
	root?: string;
	branch?: string;
	upstream?: string;
	ahead?: number;
	behind?: number;
	commit?: string;
	subject?: string;
	author?: string;
	date?: string;
	changes?: {
		modified: number;
		added: number;
		deleted: number;
		renamed: number;
		untracked: number;
		staged: number;
		conflicts: number;
	};
	stashCount?: number;
	remote?: string;
};

async function git(args: string[], cwd: string): Promise<string> {
	try {
		const { stdout } = await execFileAsync("git", args, {
			cwd,
			timeout: 3000,
			maxBuffer: 1024 * 1024,
		});
		return String(stdout).trim();
	} catch {
		return "";
	}
}

function parseStatus(porcelain: string) {
	const changes = {
		modified: 0,
		added: 0,
		deleted: 0,
		renamed: 0,
		untracked: 0,
		staged: 0,
		conflicts: 0,
	};

	for (const line of porcelain.split("\n")) {
		if (!line) continue;
		const x = line[0];
		const y = line[1];
		if (line.startsWith("??")) {
			changes.untracked++;
			continue;
		}
		if (["U", "A", "D"].includes(x) && ["U", "A", "D"].includes(y)) changes.conflicts++;
		if (x !== " " && x !== "?") changes.staged++;
		for (const c of [x, y]) {
			if (c === "M") changes.modified++;
			else if (c === "A") changes.added++;
			else if (c === "D") changes.deleted++;
			else if (c === "R") changes.renamed++;
		}
	}
	return changes;
}

async function collectGitInfo(cwd: string): Promise<GitInfo> {
	const inside = (await git(["rev-parse", "--is-inside-work-tree"], cwd)) === "true";
	if (!inside) return { inside: false };

	const [
		root,
		branch,
		upstream,
		aheadBehind,
		lastCommit,
		porcelain,
		stashList,
		remote,
	] = await Promise.all([
		git(["rev-parse", "--show-toplevel"], cwd),
		git(["branch", "--show-current"], cwd),
		git(["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"], cwd),
		git(["rev-list", "--left-right", "--count", "HEAD...@{u}"], cwd),
		git(["log", "-1", "--format=%h%x09%s%x09%an%x09%cr"], cwd),
		git(["status", "--porcelain=v1"], cwd),
		git(["stash", "list"], cwd),
		git(["remote", "get-url", "origin"], cwd),
	]);

	const [commit, subject, author, date] = lastCommit.split("\t");
	const [aheadRaw, behindRaw] = aheadBehind.split(/\s+/).map((v) => Number(v || 0));
	const stashCount = stashList ? stashList.split("\n").filter(Boolean).length : 0;

	return {
		inside: true,
		root,
		branch: branch || "DETACHED",
		upstream: upstream || undefined,
		behind: Number.isFinite(behindRaw) ? behindRaw : 0,
		ahead: Number.isFinite(aheadRaw) ? aheadRaw : 0,
		commit,
		subject,
		author,
		date,
		changes: parseStatus(porcelain),
		stashCount,
		remote: remote || undefined,
	};
}

function formatRemote(url?: string) {
	if (!url) return undefined;
	return url
		.replace(/^git@([^:]+):/, "$1/")
		.replace(/^https?:\/\//, "")
		.replace(/\.git$/, "");
}

function render(info: GitInfo, theme: ExtensionContext["ui"]["theme"]) {
	if (!info.inside) {
		return {
			status: theme.fg("dim", "git: not a repo"),
			widget: undefined as string[] | undefined,
		};
	}

	const c = info.changes!;
	const dirty = c.modified + c.added + c.deleted + c.renamed + c.untracked + c.conflicts;
	const sync = info.upstream
		? `${info.ahead ? `↑${info.ahead}` : ""}${info.behind ? `↓${info.behind}` : ""}` || "synced"
		: "no upstream";
	const dirtyText = dirty ? theme.fg(c.conflicts ? "error" : "warning", `±${dirty}`) : theme.fg("success", "clean");

	const status = [
		theme.fg("accent", ` ${info.branch}`),
		theme.fg("dim", sync),
		dirtyText,
		info.commit ? theme.fg("dim", info.commit) : undefined,
	].filter(Boolean).join(" ");

	const changeParts = [
		c.staged ? `staged ${c.staged}` : undefined,
		c.modified ? `M ${c.modified}` : undefined,
		c.added ? `A ${c.added}` : undefined,
		c.deleted ? `D ${c.deleted}` : undefined,
		c.renamed ? `R ${c.renamed}` : undefined,
		c.untracked ? `? ${c.untracked}` : undefined,
		c.conflicts ? `conflicts ${c.conflicts}` : undefined,
	].filter(Boolean).join(" · ") || "clean working tree";

	const widget = [
		`${theme.fg("accent", "Git")} ${info.branch} ${theme.fg("dim", sync)}`,
		`Commit: ${info.commit ?? "-"} ${info.subject ?? ""}`.trim(),
		`Author: ${info.author ?? "-"} · ${info.date ?? "-"}`,
		`Changes: ${changeParts}`,
		info.stashCount ? `Stash: ${info.stashCount}` : undefined,
		formatRemote(info.remote) ? `Remote: ${formatRemote(info.remote)}` : undefined,
	].filter(Boolean) as string[];

	return { status, widget };
}

export default function gitInfoExtension(pi: ExtensionAPI) {
	let showWidget = true;
	async function refresh(ctx: ExtensionContext) {
		if (!ctx.hasUI) return;
		const info = await collectGitInfo(ctx.cwd);
		const { status, widget } = render(info, ctx.ui.theme);
		ctx.ui.setStatus(EXT_ID, status);
		ctx.ui.setWidget(EXT_ID, showWidget ? widget : undefined, { placement: "aboveEditor" });
	}

	pi.on("session_start", async (_event, ctx) => refresh(ctx));
	pi.on("turn_start", async (_event, ctx) => refresh(ctx));
	pi.on("turn_end", async (_event, ctx) => refresh(ctx));
	pi.on("tool_result", async (event, ctx) => {
		if (["bash", "edit", "write"].includes(event.toolName)) await refresh(ctx);
	});

	pi.registerCommand("gitinfo", {
		description: "Refresh/toggle Git status widget. Usage: /gitinfo [on|off|toggle|refresh]",
		handler: async (args, ctx) => {
			const action = (args || "refresh").trim().toLowerCase();
			if (action === "on") showWidget = true;
			else if (action === "off") showWidget = false;
			else if (action === "toggle") showWidget = !showWidget;
			await refresh(ctx);
			ctx.ui.notify(`Git info ${showWidget ? "shown" : "hidden"}`, "info");
		},
	});

	pi.registerCommand("gitinfo-refresh", {
		description: "Refresh Git info widget/status",
		handler: async (_args, ctx) => refresh(ctx),
	});
}
