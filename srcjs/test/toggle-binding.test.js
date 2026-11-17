import { describe, it, expect, vi } from "vitest";
import "../bindings/carbon-toggle.js";
import { mount, fire } from "./helpers.js";

const binding = getBinding("carbon.toggle");
const make = () => mount(`<cds-toggle id="tg"></cds-toggle>`);

describe("carbon.toggle", () => {
    it("finds toggles with an id", () => {
        mount(`<div><cds-toggle id="a"></cds-toggle><cds-toggle></cds-toggle></div>`);

        const found = binding.find(document.body);
        expect(found.length).toBe(1);
        expect(found[0].id).toBe("a");
    });

    it("reads `toggled` as TRUE/FALSE", () => {
        const el = make();
        expect(binding.getValue(el)).toBe(false);

        el.toggled = true;
        expect(binding.getValue(el)).toBe(true);
    });

    it("notifies Shiny on cds-toggle-changed, not native change", () => {
        const el = make();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        fire(el, "change");
        expect(callback).not.toHaveBeenCalled();

        fire(el, "cds-toggle-changed");
        expect(callback).toHaveBeenCalledWith(false);

        binding.unsubscribe(el);
        fire(el, "cds-toggle-changed");
        expect(callback).toHaveBeenCalledTimes(1);
    });

    it("updates the state from update_carbon_toggle() and notifies Shiny", () => {
        const el = make();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        binding.receiveMessage(el, { toggled: true });

        expect(binding.getValue(el)).toBe(true);
        expect(callback).toHaveBeenCalledTimes(1);
    });

    it("doesn't notify Shiny when the state doesn't change", () => {
        const el = make();
        el.toggled = true;
        const callback = vi.fn();
        binding.subscribe(el, callback);

        binding.receiveMessage(el, { toggled: true, labelText: "Wi-Fi", labelA: "Yes", labelB: "No", disabled: true });

        expect(callback).not.toHaveBeenCalled();
        expect(el.labelText).toBe("Wi-Fi");
        expect(el.labelA).toBe("Yes");
        expect(el.labelB).toBe("No");
        expect(el.disabled).toBe(true);
    });
});
