import { defineConfig } from "vite";

export default defineConfig({
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
