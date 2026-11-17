import { defineConfig } from "vite";
import { copyFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

// carbonite.scss sets Carbon's `$font-path` to "fonts", so the CSS refers to
// the IBM Plex fonts as `url(fonts/IBM-Plex-Sans/...)`, relative to the CSS
// file. Copy exactly those files from @ibm/plex into the build. (Letting Vite
// resolve the fonts itself would inline all of them as base64: library mode
// always inlines assets.)
function copyPlexFonts() {
    const plexDir = fileURLToPath(new URL("node_modules/@ibm/plex/", import.meta.url));

    return {
        name: "copy-plex-fonts",
        // writeBundle, not generateBundle: Vite adds the CSS to the bundle
        // after user plugins' generateBundle runs.
        writeBundle(options, bundle) {
            const css = Object.values(bundle)
                .filter(file => file.fileName.endsWith(".css"))
                .map(file => String(file.source))
                .join("\n");
            const paths = new Set(
                [...css.matchAll(/url\(["']?fonts\/([^"')]+)["']?\)/g)].map(m => m[1])
            );

            if (paths.size === 0) {
                this.error("No IBM Plex font URLs found in the CSS; check $font-path in carbonite.scss.");
            }

            for (const path of paths) {
                const dest = join(options.dir, "fonts", path);
                mkdirSync(dirname(dest), { recursive: true });
                copyFileSync(plexDir + path, dest);
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
