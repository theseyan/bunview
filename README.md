<div align="center">
<br>
<h1>bunview</h1><br>
<i>
Feature-complete <a href="https://github.com/webview/webview">webview</a> bindings for <a href="https://bun.sh">Bun</a>
</i>
<br><br>
<!--<img alt="GitHub Workflow Status" src="https://img.shields.io/github/workflow/status/theseyan/bkg/CI">
<br><br>
-->
</div>

![Example Image](misc/bunview_intro.png)

Bunview is a cross-platform library to build web-based GUIs for desktop applications.

**Note:** Due to an [issue in the Zig compiler](https://github.com/ziglang/zig/issues/10478), macOS builds are not available at the moment.
Help in making macOS builds succeed would be appreciated!

## Installation

```
bun add bunview
```

## Usage

```js
import {Window, SizeHint} from "bunview";

let window = new Window(true);

window.on('ready', () => {
    window.setTitle('Bunview');
    window.navigate("https://bun.sh");
});
```

There is no documentation right now, hence the best place to start is [examples](https://github.com/theseyan/bunview/blob/main/examples).

## Limitations

- Due to a [design limitation in the underlying webview library](https://github.com/webview/webview/issues/647), only one window can be active at a time
- Once opened, a window cannot be closed without exiting the Bun process due to a bug in `webview_destroy` (tested on Linux)

# Building from source
Bunview is written in Zig and compilation is fairly straightforward. The prerequisites are:
- Zig version [0.11.0-dev.944+a193ec432](https://ziglang.org/builds/zig-0.11.0-dev.944+a193ec432.tar.xz)

```bash
# Clone the repository and update submodules
git clone https://github.com/theseyan/bunview && cd bunview
git submodule update --init --recursive

# Build
zig build -Drelease-fast

# Run example (must have Bun installed)
bun examples/main.js
```