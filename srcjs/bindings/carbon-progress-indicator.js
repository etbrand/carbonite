// carbon_progress_indicator(inputId = ): the value is the current step's
// number, from 1 (Carbon's `currentIndex` counts from 0).
//
// Carbon only makes steps clickable when the indicator's `onChange`
// property is a function, which R can't set; with `data-clickable`, the
// binding sets it. A click then makes the clicked step current (Carbon only
// reports it) and tells Shiny. update_carbon_progress_indicator() moves the
// current step from the server.

function currentIndex(el) {
    const value = Number(el.currentIndex ?? el.getAttribute("current-index") ?? 0);
    return Number.isFinite(value) ? value : 0;
}

function stepCount(el) {
    return el.querySelectorAll(":scope > cds-progress-step").length;
}

// Make step `index` (from 0) current. Returns whether it changed.
export function goToStep(el, index) {
    const last = Math.max(0, stepCount(el) - 1);
    const target = Math.min(Math.max(0, Math.round(index)), last);
    if (target === currentIndex(el)) return false;

    el.currentIndex = target;
    el.setAttribute("current-index", target);
    return true;
}

const carbonProgressIndicatorBinding = new Shiny.InputBinding();

$.extend(carbonProgressIndicatorBinding, {
    find(scope) {
        return $(scope).find("cds-progress-indicator[id]");
    },

    getValue(el) {
        return currentIndex(el) + 1;
    },

    subscribe(el, callback) {
        el._carbonInputHandler = () => callback(false);

        if (el.hasAttribute("data-clickable")) {
            // Carbon calls this with its `change` event when a step is clicked
            el.onChange = event => {
                if (goToStep(el, event.detail.index)) callback(false);
            };
        }
    },

    unsubscribe(el) {
        el.onChange = undefined;
        delete el._carbonInputHandler;
    },

    receiveMessage(el, data) {
        if (data.current !== undefined && goToStep(el, Number(data.current) - 1)) {
            el._carbonInputHandler?.();
        }
    }
});

Shiny.inputBindings.register(carbonProgressIndicatorBinding, "carbon.progressIndicator");
