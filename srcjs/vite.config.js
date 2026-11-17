import { defineConfig } from "vite";
import { copyFileSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { basename, join } from "node:path";
import { fileURLToPath } from "node:url";

// carbonite.scss sets Carbon's `$font-path` to "fonts", so the CSS refers to
// the IBM Plex fonts as `url(fonts/IBM-Plex-Sans/fonts/split/woff2/...)`.
// Copy exactly those files from @ibm/plex into a flat `fonts/` folder and
// point the CSS at them: the nested paths are too long for an R package
// (R CMD check: "non-portable file paths", over 100 characters). (Letting
// Vite resolve the fonts itself would inline all of them as base64: library
// mode always inlines assets.)
const FONT_URL = /url\(["']?fonts\/([^"')]+)["']?\)/g;

function copyPlexFonts() {
    const plexDir = fileURLToPath(new URL("node_modules/@ibm/plex/", import.meta.url));

    return {
        name: "copy-plex-fonts",
        // writeBundle, not generateBundle: Vite adds the CSS to the bundle
        // after user plugins' generateBundle runs.
        writeBundle(options, bundle) {
            const cssFiles = Object.values(bundle)
                .filter(file => file.fileName.endsWith(".css"))
                .map(file => join(options.dir, file.fileName));
            const flatNames = new Map();

            for (const cssFile of cssFiles) {
                const css = readFileSync(cssFile, "utf8").replace(FONT_URL, (_, path) => {
                    const name = basename(path);
                    if (flatNames.has(name) && flatNames.get(name) !== path) {
                        this.error(`Two fonts would both be copied to fonts/${name}`);
                    }
                    flatNames.set(name, path);
                    return `url(fonts/${name})`;
                });
                writeFileSync(cssFile, css);
            }

            if (flatNames.size === 0) {
                this.error("No IBM Plex font URLs found in the CSS; check $font-path in carbonite.scss.");
            }

            mkdirSync(join(options.dir, "fonts"), { recursive: true });
            for (const [name, path] of flatNames) {
                copyFileSync(plexDir + path, join(options.dir, "fonts", name));
            }
        }
    };
}

export default defineConfig({
    plugins: [copyPlexFonts()],
    test: {
        environment: "happy-dom",
        include: ["test/**/*.test.js"],
        setupFiles: ["test/setup.js"]
    },
    build: {
        lib: {
            entry: "carbonite.js",
            formats: ["iife"],
            fileName: () => "carbonite.min.js",
            name: "Carbonite"
        },
        outDir: "../inst/www/carbon",
        emptyOutDir: true,
        rollupOptions: {
            output: {
                assetFileNames: (assetInfo) => {
                    if (assetInfo.name?.endsWith(".css")) {
                        return "carbonite.min.css";
                    }
                    return "[name][extname]";
                }
            }
        }
    }
});
