/**
 * This code is loaded before loading *any* webpage
*/

// Fire "navigate" event handlers
__bv_internal_callback(JSON.stringify({
    type: "internalEvent",
    data: {
        event: "navigate",
        data: { url: window.location.href }
    }
}));

// Fire "load" event handlers
addEventListener("load", () => {
    __bv_internal_callback(JSON.stringify({
        type: "internalEvent",
        data: {
            event: "load",
            data: { url: window.location.href }
        }
    }));
}, {once: true});