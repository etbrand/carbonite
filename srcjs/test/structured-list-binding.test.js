import { describe, it, expect, vi } from "vitest";
import "../bindings/carbon-structured-list.js";
import { mount, fire } from "./helpers.js";

const binding = getBinding("carbon.structuredList");

// Mirrors carbon_structured_list(selection = "single").
function makeList({ keyType = "key", values = ["lite", "standard", "enterprise"], selected } = {}) {
    const rows = values.map(v =>
        `<cds-structured-list-row selection-name="plan" selection-value="${v}"${v === selected ? " selected" : ""}>` +
        `<cds-structured-list-cell>${v}</cds-structured-list-cell></cds-structured-list-row>`
    ).join("");

    return mount(`<cds-structured-list id="plan" class="carbonite-structured-list-input" selection-name="plan" data-row-key-type="${keyType}">
        <cds-structured-list-head><cds-structured-list-header-row></cds-structured-list-header-row></cds-structured-list-head>
        <cds-structured-list-body>${rows}</cds-structured-list-body>
    </cds-structured-list>`);
}

const rowFor = (el, value) => el.querySelector(`[selection-value="${value}"]`);
const flush = () => new Promise(resolve => setTimeout(resolve));

describe("carbon.structuredList", () => {
    it("finds only selectable lists with an id", () => {
        document.body.innerHTML = `
            <cds-structured-list id="plain"></cds-structured-list>
            <cds-structured-list id="pick" class="carbonite-structured-list-input"></cds-structured-list>`;

        const found = binding.find(document.body);
        expect(found.length).toBe(1);
        expect(found[0].id).toBe("pick");
    });

    it("reads the selected row's key, or null", () => {
        const el = makeList({ selected: "standard" });
        expect(binding.getValue(el)).toBe("standard");

        rowFor(el, "standard").removeAttribute("selected");
        expect(binding.getValue(el)).toBeNull();
    });

    it("prefers Carbon's `selected` property over the attribute", () => {
        const el = makeList({ selected: "standard" });
        rowFor(el, "standard").selected = false;
        rowFor(el, "lite").selected = true;

        expect(binding.getValue(el)).toBe("lite");
    });

    it("reports row numbers as numbers without a row_key", () => {
        const el = makeList({ keyType: "index", values: ["1", "2", "3"], selected: "2" });

        expect(binding.getValue(el)).toBe(2);
    });

    // Carbon fires no change event; the row selects itself on click/keydown.
    it.each(["click", "keydown"])("notifies Shiny after a row handles %s", async type => {
        const el = makeList();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        fire(rowFor(el, "lite"), type);
        expect(callback).not.toHaveBeenCalled(); // waits for the row's own handler
        await flush();
        expect(callback).toHaveBeenCalledWith(false);

        binding.unsubscribe(el);
        fire(rowFor(el, "lite"), type);
        await flush();
        expect(callback).toHaveBeenCalledTimes(1);
    });

    it("selects a row from update_carbon_structured_list() and notifies Shiny", async () => {
        const el = makeList({ selected: "lite" });
        const callback = vi.fn();
        binding.subscribe(el, callback);

        binding.receiveMessage(el, { selected: "enterprise" });

        expect(binding.getValue(el)).toBe("enterprise");
        expect(rowFor(el, "lite").selected).toBe(false);
        expect(rowFor(el, "lite").hasAttribute("selected")).toBe(false);
        expect(rowFor(el, "enterprise").tabIndex).toBe(0);
        expect(rowFor(el, "lite").tabIndex).toBe(-1);
        await flush();
        expect(callback).toHaveBeenCalledTimes(1);
    });

    it("accepts the value as a one-element array and matches exactly", () => {
        const el = makeList({ values: ["a", "ab"] });

        binding.receiveMessage(el, { selected: ["a"] });

        expect(binding.getValue(el)).toBe("a");
    });

    it.each([[null], ["unknown"]])("clears the selection when sent %j", value => {
        const el = makeList({ selected: "lite" });

        binding.receiveMessage(el, { selected: value });

        expect(binding.getValue(el)).toBeNull();
    });

    it("ignores messages without `selected`", () => {
        const el = makeList({ selected: "lite" });

        binding.receiveMessage(el, {});

        expect(binding.getValue(el)).toBe("lite");
    });
});
