// Carbon bug in `cds-slider`'s two-handle mode (its `unstable_valueUpper`):
// dragging and track clicks compare a handle's position as a percentage
// (0-100) with the other handle's value, which only works for 0-100
// sliders. On a 0-1000 slider with the lower handle at 200, the upper handle
// can never be dragged (its percentage is never >= 200), the lower one can
// be dragged past it, and a track click can move the wrong handle.
//
// For range sliders, redo those two handlers in value units: keep each
// handle on its side of the other, and move the nearer handle on a track
// click. Single-handle sliders keep Carbon's own code.

const CHANGE_EVENT = "cds-slider-changed";

export function isRangeSlider(slider) {
    const upper = slider.unstable_valueUpper;
    return upper !== undefined && upper !== null && upper !== "";
}

// Where the pointer is along the track, from 0 to 1.
export function trackRate(slider, clientX) {
    const track = slider._trackNode;
    const { left, width } = track.getBoundingClientRect();
    const rtl = getComputedStyle(track).getPropertyValue("direction") === "rtl";
    const rate = (rtl ? left + width - clientX : clientX - left) / width;
    return Math.min(1, Math.max(0, rate));
}

export function rateOf(slider, value) {
    const min = Number(slider.min);
    const max = Number(slider.max);
    return (Number(value) - min) / (max - min);
}

function valueAt(slider, rate) {
    const min = Number(slider.min);
    return min + rate * (Number(slider.max) - min);
}

function changed(slider, value, intermediate) {
    slider.dispatchEvent(new CustomEvent(CHANGE_EVENT, {
        bubbles: true,
        composed: true,
        detail: intermediate === undefined ? { value } : { value, intermediate }
    }));
}

function thumbOf(event) {
    const target = event.target;
    return target?.id || target?.closest?.(".cds--slider__thumb")?.id || "";
}

// Move a handle of a range slider towards `rate`, without passing the other.
export function moveRangeHandle(slider, upper, rate) {
    if (upper) {
        slider._rateUpper = Math.max(rate, rateOf(slider, slider.value));
        return slider.unstable_valueUpper;
    }
    slider._rate = Math.min(rate, rateOf(slider, slider.unstable_valueUpper));
    return slider.value;
}

export function patchSlider(Slider) {
    if (Slider.prototype._carbonitePatched) return;

    const { _handlePointermoveImpl: pointermove, _handleClick: click } = Slider.prototype;

    Slider.prototype._handlePointermoveImpl = function (event) {
        if (!isRangeSlider(this) || this.disabled || !(this._dragging || this._draggingUpper)) {
            return pointermove.call(this, event);
        }

        const upper = !this._dragging;
        this._setThumbTooltipOpen?.(upper ? this._thumbNodeUpper : this._thumbNode, true);
        changed(this, moveRangeHandle(this, upper, trackRate(this, event.clientX)), true);
    };

    Slider.prototype._handleClick = function (event) {
        // Clicks on a handle itself, and single-handle sliders, are fine
        if (!isRangeSlider(this) || thumbOf(event) || this.disabled || this.readonly || this.dragCoolDown) {
            return click.call(this, event);
        }

        const rate = trackRate(this, event.clientX);
        const value = valueAt(this, rate);
        const toLower = Math.abs(value - Number(this.value));
        const toUpper = Math.abs(value - Number(this.unstable_valueUpper));
        // On a tie (handles together), go by which side was clicked
        const upper = toUpper < toLower || (toUpper === toLower && value > Number(this.unstable_valueUpper));

        changed(this, moveRangeHandle(this, upper, rate));
    };

    Slider.prototype._carbonitePatched = true;

    // A slider that connected before this patch (sliders already in the page
    // are upgraded the moment Carbon defines `cds-slider`, before this module
    // runs) has captured the unpatched pointermove handler in its throttled
    // copy; point it at the patched one.
    document.querySelectorAll("cds-slider").forEach(slider => {
        if (slider instanceof Slider && slider._throttledHandlePointermoveImpl) {
            slider._throttledHandlePointermoveImpl = event => slider._handlePointermoveImpl(event);
        }
    });
}

// Patch as soon as possible (see accordion.js for why synchronously). Sliders
// connecting later throttle the patched handler themselves.
const Slider = customElements.get("cds-slider");
if (Slider) {
    patchSlider(Slider);
} else {
    customElements.whenDefined("cds-slider")
        .then(() => patchSlider(customElements.get("cds-slider")));
}
