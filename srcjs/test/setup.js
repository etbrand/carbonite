// Global stand-ins for what the bindings expect from a Shiny page.
// Runs before every test file (see `test.setupFiles` in vite.config.js).
import jQuery from "jquery";

globalThis.$ = globalThis.jQuery = jQuery;

// Bindings register themselves on import; keep them so tests can look them up.
const registered = new Map();

globalThis.Shiny = {
    InputBinding: class InputBinding {},
    inputBindings: {
        register(binding, name) {
            registered.set(name, binding);
        }
    }
};

globalThis.getBinding = name => {
    const binding = registered.get(name);

    if (!binding) {
        throw new Error(`No binding registered as "${name}"`);
    }

    return binding;
};
