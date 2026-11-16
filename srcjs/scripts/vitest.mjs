// Launch Vitest from a working directory with an upper-case drive letter.
//
// On Windows, VS Code terminals start in `c:\...`. Vitest then loads two copies
// of itself (one per drive-letter spelling) and every test file fails with
// "Vitest failed to find the runner". Re-spawning from `C:\...` avoids that.
import { spawnSync } from "node:child_process";
import path from "node:path";

const cwd = process.cwd().replace(/^[a-z]:/, drive => drive.toUpperCase());
const vitest = path.join(cwd, "node_modules", "vitest", "vitest.mjs");

const result = spawnSync(
    process.execPath,
    [vitest, ...process.argv.slice(2)],
    { cwd, stdio: "inherit" }
);

process.exit(result.status ?? 1);
