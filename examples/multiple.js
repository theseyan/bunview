import {Window, SizeHint} from "../lib";

let window1 = new Window(true);
let window2 = new Window(true);

window1.on('ready', () => {
    window1.setTitle('Window 1');
    window1.navigate(`data:text/html,<html><h1>Window 1</h1><button onclick='increase()'>Increase counter</button></html>`);

    var count = 0;
    window1.bind("increase", () => {
        count++;
        window2.eval(`document.getElementById('counter').innerHTML = 'Counter: ${count}';`);
    });
});

window2.on('ready', () => {
    window2.setTitle('Window 2');
    window2.navigate(`data:text/html,<html><h1 id="counter">Counter: 0</h1></html>`);
});