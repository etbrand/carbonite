import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import "../bindings/carbon-menu.js";
import { mount } from "./helpers.js";

const binding = getBinding("carbon.menu");

// Mirrors carbon_menu_button() with a divider, a disabled item, and a submenu.
function makeMenu(tag = "cds-menu-button") {
    return mount(`<${tag} id="actions" class="carbonite-menu" label="Actions">
        <cds-menu>
            <cds-menu-item label="Edit" data-value="edit"><svg slot="render-icon"></svg></cds-menu-item>
            <cds-menu-item label="Locked" data-value="locked" disabled></cds-menu-item>
            <cds-menu-item-divider></cds-menu-item-divider>
            <cds-menu-item label="Export as">
                <cds-menu-item-group slot="submenu">
                    <cds-menu-item label="CSV" data-value="csv"></cds-menu-item>
                </cds-menu-item-group>
            </cds-menu-item>
        </cds-menu>
    </${tag}>`);
}

const item = (el, value) => el.querySelector(`[data-value="${value}"]`);
const click = node => node.dispatchEvent(new MouseEvent("click", { bubbles: true, composed: true }));

describe("carbon.menu", () => {
    beforeEach(() => {
        Shiny.setInputValue = vi.fn();
    });

    afterEach(() => {
        delete Shiny.setInputValue;
    });

    it("finds menu buttons and overflow menus with an id", () => {
        document.body.innerHTML = `
            <cds-menu-button id="a" class="carbonite-menu"></cds-menu-button>
            <cds-overflow-menu id="b" class="carbonite-menu"></cds-overflow-menu>
            <cds-menu-button class="carbonite-menu"></cds-menu-button>
            <cds-menu-button id="plain"></cds-menu-button>`;

        expect(binding.find(document.body).toArray().map(el => el.id)).toEqual(["a", "b"]);
    });

    it("starts as NULL", () => {
        expect(binding.getValue(makeMenu())).toBeNull();
    });

    it.each(["cds-menu-button", "cds-overflow-menu"])("%s: sends the chosen item's value as an event", tag => {
        const el = makeMenu(tag);
        binding.subscribe(el, vi.fn());

        click(item(el, "edit"));

        expect(binding.getValue(el)).toBe("edit");
        expect(Shiny.setInputValue).toHaveBeenCalledWith("actions", "edit", { priority: "event" });
    });

    it("sends the same item again when chosen again", () => {
        const el = makeMenu();
        binding.subscribe(el, vi.fn());

        click(item(el, "edit"));
        click(item(el, "edit"));

        expect(Shiny.setInputValue).toHaveBeenCalledTimes(2);
    });

    it("treats a click inside an item (e.g. its icon) as choosing it", () => {
        const el = makeMenu();
        binding.subscribe(el, vi.fn());

        click(item(el, "edit").querySelector("svg"));

        expect(Shiny.setInputValue).toHaveBeenCalledWith("actions", "edit", { priority: "event" });
    });

    it("chooses items in a submenu, but not the item that opens it", () => {
        const el = makeMenu();
        binding.subscribe(el, vi.fn());

        click(el.querySelector('[label="Export as"]'));
        expect(Shiny.setInputValue).not.toHaveBeenCalled();

        click(item(el, "csv"));
        expect(Shiny.setInputValue).toHaveBeenCalledWith("actions", "csv", { priority: "event" });
    });

    it("ignores disabled items, dividers, and the trigger button", () => {
        const el = makeMenu();
        binding.subscribe(el, vi.fn());

        click(item(el, "locked"));
        click(el.querySelector("cds-menu-item-divider"));
        click(el);

        expect(Shiny.setInputValue).not.toHaveBeenCalled();
        expect(binding.getValue(el)).toBeNull();
    });

    it("prefers Carbon's `disabled` property over the attribute", () => {
        const el = makeMenu();
        binding.subscribe(el, vi.fn());
        item(el, "locked").disabled = false;
        item(el, "edit").disabled = true;

        click(item(el, "locked"));
        click(item(el, "edit"));

        expect(Shiny.setInputValue).toHaveBeenCalledTimes(1);
        expect(Shiny.setInputValue).toHaveBeenCalledWith("actions", "locked", { priority: "event" });
    });

    it("stops listening when unsubscribed", () => {
        const el = makeMenu();
        binding.subscribe(el, vi.fn());
        binding.unsubscribe(el);

        click(item(el, "edit"));

        expect(Shiny.setInputValue).not.toHaveBeenCalled();
    });

    it("updates label and disabled from update_carbon_menu()", () => {
        const el = makeMenu();

        binding.receiveMessage(el, { label: "More", disabled: true });

        expect(el.label).toBe("More");
        expect(el.disabled).toBe(true);
    });
});
