import { packager } from "@electron/packager";
import { execFileSync } from "node:child_process";
import { cp, mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const pnpmPath = process.env.npm_execpath;
if (!pnpmPath) throw new Error("Run the desktop build with pnpm build:desktop.");
const pnpmIsScript = /\.[cm]?js$/i.test(pnpmPath);
const pnpmExecutable = pnpmIsScript ? process.execPath : pnpmPath;
const pnpmArgs = pnpmIsScript ? [pnpmPath] : [];

const workspace = fileURLToPath(new URL("../../", import.meta.url));
const runPnpm = (args, cwd) => execFileSync(pnpmExecutable, [...pnpmArgs, ...args], { cwd, stdio: "inherit" });

const pkg = JSON.parse(await readFile(new URL("package.json", import.meta.url), "utf8"));
const version = process.env.INFINITE_CANVAS_DESKTOP_VERSION ?? pkg.version;
const temporary = await mkdtemp(join(tmpdir(), "infinite-canvas-desktop-"));
try {
    await cp(new URL("main.mjs", import.meta.url), join(temporary, "main.mjs"));
    await writeFile(join(temporary, "package.json"), JSON.stringify({ name: "infinite-canvas", productName: pkg.productName, version, type: "module", main: "main.mjs" }));
    await packager({
        dir: temporary, out: fileURLToPath(new URL("dist/", import.meta.url)), name: pkg.productName,
        appBundleId: "com.infinitecanvas.desktop", appVersion: version, electronVersion: pkg.devDependencies.electron,
        win32metadata: { CompanyName: "Infinite Canvas contributors" },
        asar: false, prune: false, overwrite: true,
        afterCopy: [async ({ buildPath, platform }) => {
            const cli = join(buildPath, "cli");
            const deployed = platform === "win32" ? join(temporary, "cli-deploy") : cli;
            runPnpm(["--filter", "@basketikun/infinite-canvas", "deploy", "--legacy", "--prod", "--ignore-scripts", deployed], workspace);
            if (platform !== "win32") return;

            // The packager moves its staging directory. Windows junctions from deploy use absolute paths.
            const modules = join(deployed, "node_modules");
            const install = join(temporary, "cli-install");
            const manifest = JSON.parse(await readFile(join(deployed, "package.json"), "utf8"));
            delete manifest.devDependencies;
            delete manifest.packageManager;
            await mkdir(install);
            await writeFile(join(install, "package.json"), JSON.stringify(manifest));
            await cp(join(modules, ".pnpm", "lock.yaml"), join(install, "pnpm-lock.yaml"));
            await cp(join(workspace, "pnpm-workspace.yaml"), join(install, "pnpm-workspace.yaml"));
            runPnpm(["install", "--frozen-lockfile", "--prod", "--ignore-scripts", "--node-linker=hoisted"], install);
            await cp(deployed, cli, { recursive: true, filter: (path) => path !== modules });
            const installedModules = join(install, "node_modules");
            const installMetadata = new Set([".bin", ".pnpm", ".modules.yaml", ".pnpm-workspace-state-v1.json"].map((name) => join(installedModules, name)));
            await cp(installedModules, join(cli, "node_modules"), { recursive: true, filter: (path) => !installMetadata.has(path) });
        }],
    });
} finally {
    await rm(temporary, { recursive: true, force: true });
}
