/**
 * Main example
 * Demonstrates most API functions
*/

import {Window, SizeHint} from "../lib";

// Create a new window with developer tools enabled
let window = new Window(true);

// We must wait for 'ready' event before calling any window-modifying function
window.on('ready', () => {
    // Set title
    window.setTitle('Bunview');

    // We can use data: URLs
    window.navigate("data:text/html,<html><h1>webview!</h1></html>");

    // Set window size
    window.setSize(400, 400, SizeHint.MIN);

    // Bind function to webview's JS global namespace
    window.bind("helloworld", function() {
        console.log('helloworld called with arguments:', ...arguments);
    });

    // Call binded function from webview's JS context
    // We wait some time to let the window context initialize
    setTimeout(() => {
        window.eval("helloworld('hi!', true, 100)");
    }, 2000);

    // Inject initialization JS to be loaded before every page load
    window.init("alert('Before page load!')");

    // After 5 seconds, navigate to Bun's homepage and expand the window size
    setTimeout(() => {
        window.navigate("https://bun.sh");
        window.setSize(800, 600, SizeHint.NONE);
    }, 5000);

    // After 10 seconds, exit the app
    setTimeout(() => {
        window.destroy();
    }, 10000);
});