// Toast notifications from show_carbon_notification().
//
// The server inserts each toast at the end of <body> with insertUI(): that
// works on any page, even before this bundle has loaded (insertUI loads it
// with the toast). Here each toast is moved into a fixed stack in the
// top-right corner, and removed once it closes, whether the user closed it
// or its `timeout` ran out (Carbon only hides a closed notification).

export const STACK_CLASS = "carbonite-toast-stack";
const TOAST = "cds-toast-notification.carbonite-toast";

export function toastStack() {
    let stack = document.querySelector(`body > .${STACK_CLASS}`);

    if (!stack) {
        stack = document.createElement("div");
        stack.className = STACK_CLASS;
        document.body.appendChild(stack);
    }

    return stack;
}

// Move toasts that were inserted directly into <body> into the stack.
export function collectToasts() {
    const toasts = document.querySelectorAll(`body > ${TOAST}`);
    if (toasts.length) toastStack().append(...toasts);
}

export function removeToast(toast) {
    window.Shiny?.unbindAll?.(toast);
    toast.remove();
}

document.addEventListener("cds-notification-closed", event => {
    if (event.target?.matches?.(TOAST)) removeToast(event.target);
});

function watchBody() {
    collectToasts();
    new MutationObserver(collectToasts).observe(document.body, { childList: true });
}

if (document.body) {
    watchBody();
} else {
    document.addEventListener("DOMContentLoaded", watchBody);
}
