// Carbon components aren't registered in tests, so `cds-*` tags are plain
// elements. Properties Carbon would normally manage (`checked`, `value`, ...)
// are set directly, mirroring what the real components expose.

export function mount(markup) {
    document.body.innerHTML = markup;
    return document.body.firstElementChild;
}

export function makeGroup(groupTag, itemTag, items, id = "grp") {
    const el = mount(`<${groupTag} id="${id}"></${groupTag}>`);

    items.forEach(({ value, checked = false }) => {
        const item = document.createElement(itemTag);
        item.value = value;
        item.checked = checked;
        el.appendChild(item);
    });

    return el;
}

export function fire(el, type) {
    el.dispatchEvent(new CustomEvent(type, { bubbles: true, composed: true }));
}

export function childValues(el, selector) {
    return Array.from(el.querySelectorAll(selector)).map(item => item.value);
}

export function checkedValues(el, selector) {
    return Array.from(el.querySelectorAll(selector))
        .filter(item => item.checked)
        .map(item => item.value);
}
