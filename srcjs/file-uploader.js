// carbon_file_uploader(): Carbon's file chooser in front of Shiny's own file
// upload.
//
// carbon_file_uploader() renders Carbon's button (or drop area) next to a
// hidden <input type="file"> carrying the input id, which Shiny's file input
// binding binds like any fileInput(). When the user chooses files in
// Carbon's UI, they're handed to that input, which uploads them; the
// server's input is then the usual data frame of name/size/type/datapath.
//
// Carbon's file list shows each file's state. Shiny reports on an upload
// through:
// * a "shiny:inputchanged" event on the input once the files are uploaded;
// * its progress bar (the hidden `#<id>_progress .progress-bar`), which gets
//   the `progress-bar-danger` class and the error message if it fails.

const WRAPPER = ".carbonite-file-uploader";
const CHANGE_EVENTS = ["cds-file-uploader-button-changed", "cds-file-uploader-drop-container-changed"];

function partsOf(wrapper) {
    return {
        uploader: wrapper.querySelector(":scope > cds-file-uploader"),
        input: wrapper.querySelector(":scope > input[type=file]"),
        bar: wrapper.querySelector(":scope > .shiny-file-input-progress > .progress-bar")
    };
}

function items(uploader) {
    return [...uploader.querySelectorAll(":scope > cds-file-uploader-item")];
}

// Show these files in Carbon's list, replacing the previous ones.
export function listFiles(wrapper, files) {
    const { uploader } = partsOf(wrapper);
    items(uploader).forEach(item => item.remove());

    files.forEach(file => {
        const item = document.createElement("cds-file-uploader-item");
        item.setAttribute("state", "uploading");
        item.setAttribute("size", wrapper.dataset.size || "md");
        item.textContent = file.name;
        uploader.appendChild(item);
    });
}

export function setItemsState(wrapper, state, error = null) {
    items(partsOf(wrapper).uploader).forEach(item => {
        item.state = state;
        item.setAttribute("state", state);
        item.invalid = error !== null;
        item.toggleAttribute("invalid", error !== null);
        if (error !== null) {
            item.errorSubject = "Upload failed";
            item.errorBody = error;
        }
    });
}

// Hand the files to the hidden input, whose "change" starts Shiny's upload.
export function uploadFiles(wrapper, files) {
    const { input } = partsOf(wrapper);
    if (!files.length || !input) return;

    const transfer = new DataTransfer();
    files.forEach(file => transfer.items.add(file));
    input.files = transfer.files;

    listFiles(wrapper, files);
    $(input).trigger("change");
}

CHANGE_EVENTS.forEach(type => {
    document.addEventListener(type, event => {
        const wrapper = event.target.closest?.(WRAPPER);
        if (!wrapper) return;

        let files = Array.from(event.detail?.addedFiles ?? []);
        // A drop can hold several files even when only one is wanted
        if (!wrapper.hasAttribute("data-multiple")) files = files.slice(0, 1);

        uploadFiles(wrapper, files);
    });
});

// A failed file shows a close button (Carbon's "edit" state); closing it
// just clears it from the list, since it never reached the server.
document.addEventListener("cds-file-uploader-item-deleted", event => {
    const item = event.target;
    if (item?.closest?.(WRAPPER) && item.matches("cds-file-uploader-item")) item.remove();
});

// Uploaded: Shiny has set the input. For file uploads Shiny triggers this on
// the document, with the input as `event.el`. Only files still uploading are
// marked: the event also fires for the input's initial (empty) value.
export function handleInputChanged(event) {
    const el = event.el ?? event.target;
    const wrapper = el?.closest?.(WRAPPER);
    if (!wrapper || !el.matches("input[type=file]") || event.value == null) return;

    const uploading = items(partsOf(wrapper).uploader).some(item => item.getAttribute("state") === "uploading");
    if (uploading) setItemsState(wrapper, "complete");
}

$(document).on("shiny:inputchanged", handleInputChanged);

// Failed: Shiny marks its progress bar as an error, with the message.
export function watchProgress(wrapper) {
    const { bar } = partsOf(wrapper);
    if (!bar || bar._carboniteWatched) return;
    bar._carboniteWatched = true;

    new MutationObserver(() => {
        if (bar.classList.contains("progress-bar-danger")) {
            setItemsState(wrapper, "edit", bar.textContent.trim() || "The file could not be uploaded.");
        }
    }).observe(bar, { attributes: true, attributeFilter: ["class"], childList: true, characterData: true, subtree: true });
}

// Watch uploaders already in the page and any added later (renderUI, modals)
function watchAll(root = document) {
    root.querySelectorAll?.(WRAPPER).forEach(watchProgress);
}

$(document).on("shiny:bound", event => watchAll(event.target?.parentElement ?? document));
if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", () => watchAll());
} else {
    watchAll();
}
