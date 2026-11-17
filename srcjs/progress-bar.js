// update_carbon_progress_bar(): a progress bar isn't an input, so the
// server updates it with a custom message naming its element id. Shiny sends
// custom messages straight away, so the bar moves during a long computation.

const PROPERTIES = ["value", "max", "label", "helperText", "status"];

export function updateProgressBar(message) {
    const bar = document.getElementById(message?.id);
    if (!bar || !bar.matches("cds-progress-bar")) return false;

    PROPERTIES.forEach(name => {
        if (name in message) bar[name] = message[name];
    });
    // An indeterminate bar has no value at all (Carbon checks for null)
    if ("value" in message && message.value === null) bar.removeAttribute("value");
    return true;
}

window.Shiny?.addCustomMessageHandler?.("carbonite-progress-bar", updateProgressBar);
