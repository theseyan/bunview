/**
 * Events example
 * Demonstrates how to listen for events
*/

import {Window, SizeHint} from "../lib";

// Create a new window with developer tools enabled
let window = new Window(true);

// The 'ready' event is fired when the Window is ready to be modified
// This does *not* mean a webpage has been loaded
window.on('ready', () => {
    console.log('Window ready!');

    // Navigate to Bun's homepage
    window.navigate("https://bun.sh");
});

// The 'navigate' event is fired when the window navigation changes
// This does *not* mean the webpage has been loaded 
window.on('navigate', (evt) => {
    console.log('Navigation occurred: ', evt.url);
});

// The 'load' event is fired when a webpage has been loaded
window.on('load', (evt) => {
    console.log('Webpage loaded: ', evt.url);
});