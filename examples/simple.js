import {Window, SizeHint} from "../lib";

let window = new Window(true);

window.on('ready', () => {
    window.setTitle('Bunview');
    window.setSize(1000, 800);
    window.navigate("https://bun.sh");
});