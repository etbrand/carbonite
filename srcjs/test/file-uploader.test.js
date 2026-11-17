import { describe, it, expect, vi, beforeAll } from "vitest";

let uploadFiles, setItemsState, handleInputChanged, watchProgress;

beforeAll(async () => {
    // happy-dom may not have DataTransfer; a minimal stand-in
    if (typeof globalThis.DataTransfer !== "function") {
        globalThis.DataTransfer = class {
            constructor() {
                const list = [];
                this.items = { add: file => list.push(file) };
                this.files = list;
            }
        };
    }
    ({ uploadFiles, setItemsState, handleInputChanged, watchProgress } = await import("../file-uploader.js"));
});

// Mirrors carbon_file_uploader()
function mount({ multiple = false } = {}) {
    document.body.innerHTML = `<div class="carbonite-file-uploader" data-size="sm"${multiple ? " data-multiple" : ""}>
        <cds-file-uploader><cds-file-uploader-button>Add file</cds-file-uploader-button></cds-file-uploader>
        <input type="file" id="data" class="carbonite-file-uploader__input" hidden>
        <div id="data_progress" class="shiny-file-input-progress" hidden><div class="progress-bar"></div></div>
    </div>`;
    const wrapper = document.querySelector(".carbonite-file-uploader");
    const input = wrapper.querySelector("input");
    // Let the test set `files` (happy-dom's may be read-only)
    Object.defineProperty(input, "files", { writable: true, value: [] });
    return { wrapper, input, button: wrapper.querySelector("cds-file-uploader-button") };
}

const file = name => new File(["x"], name, { type: "text/csv" });
const items = wrapper => [...wrapper.querySelectorAll("cds-file-uploader-item")];
const chosen = (el, type, files) => el.dispatchEvent(
    new CustomEvent(type, { bubbles: true, composed: true, detail: { addedFiles: files } })
);

describe("file uploader", () => {
    it("hands chosen files to the hidden input, triggers Shiny's upload, and lists them", () => {
        const { wrapper, input, button } = mount({ multiple: true });
        const changed = vi.fn();
        $(input).on("change", changed);

        chosen(button, "cds-file-uploader-button-changed", [file("a.csv"), file("b.csv")]);

        expect([...input.files].map(f => f.name)).toEqual(["a.csv", "b.csv"]);
        expect(changed).toHaveBeenCalledTimes(1);
        expect(items(wrapper).map(i => i.textContent)).toEqual(["a.csv", "b.csv"]);
        expect(items(wrapper).map(i => i.getAttribute("state"))).toEqual(["uploading", "uploading"]);
        expect(items(wrapper)[0].getAttribute("size")).toBe("sm");
    });

    it("keeps only the first of several dropped files when not multiple", () => {
        const { wrapper, input } = mount();
        const drop = document.createElement("cds-file-uploader-drop-container");
        wrapper.querySelector("cds-file-uploader").appendChild(drop);

        chosen(drop, "cds-file-uploader-drop-container-changed", [file("a.csv"), file("b.csv")]);

        expect([...input.files].map(f => f.name)).toEqual(["a.csv"]);
        expect(items(wrapper)).toHaveLength(1);
    });

    it("replaces the listed files when files are chosen again, and ignores no files", () => {
        const { wrapper, button } = mount();

        chosen(button, "cds-file-uploader-button-changed", [file("a.csv")]);
        chosen(button, "cds-file-uploader-button-changed", [file("b.csv")]);
        chosen(button, "cds-file-uploader-button-changed", []);

        expect(items(wrapper).map(i => i.textContent)).toEqual(["b.csv"]);
    });

    it("ignores the same events outside a carbon_file_uploader()", () => {
        document.body.innerHTML = `<cds-file-uploader-button></cds-file-uploader-button>`;
        expect(() => chosen(document.body.firstElementChild, "cds-file-uploader-button-changed", [file("a.csv")])).not.toThrow();
    });

    it("marks files complete once Shiny sets the input, not on its initial value", () => {
        const { wrapper, input } = mount();
        uploadFiles(wrapper, [file("a.csv")]);

        handleInputChanged({ el: input, value: null });
        expect(items(wrapper)[0].getAttribute("state")).toBe("uploading");

        handleInputChanged({ el: input, value: [{ name: "a.csv" }] });
        expect(items(wrapper)[0].getAttribute("state")).toBe("complete");
    });

    it("shows Shiny's upload error on the files", async () => {
        const { wrapper } = mount();
        uploadFiles(wrapper, [file("big.csv")]);
        watchProgress(wrapper);

        // As Shiny's uploader does on failure
        const bar = wrapper.querySelector(".progress-bar");
        bar.classList.add("progress-bar-danger");
        bar.textContent = "Maximum upload size exceeded";
        await new Promise(resolve => setTimeout(resolve));

        const [item] = items(wrapper);
        expect(item.getAttribute("state")).toBe("edit");
        expect(item.hasAttribute("invalid")).toBe(true);
        expect(item.errorBody).toBe("Maximum upload size exceeded");
    });

    it("removes a failed file from the list when it's closed", () => {
        const { wrapper } = mount();
        uploadFiles(wrapper, [file("big.csv")]);
        setItemsState(wrapper, "edit", "Too big");

        items(wrapper)[0].dispatchEvent(new CustomEvent("cds-file-uploader-item-deleted", { bubbles: true, composed: true }));

        expect(items(wrapper)).toHaveLength(0);
    });

    it("sets item state and clears errors", () => {
        const { wrapper } = mount();
        uploadFiles(wrapper, [file("a.csv")]);

        setItemsState(wrapper, "edit", "Oops");
        setItemsState(wrapper, "complete");

        const [item] = items(wrapper);
        expect(item.state).toBe("complete");
        expect(item.hasAttribute("invalid")).toBe(false);
    });
});
