/**
 * Bunview - Feature-complete webview bindings for Bun
*/

import EventEmitter from 'events';
import { spawn } from "bun";

// Toggle debug logging
const DEBUG = false;

export const SizeHint = {
    // Width and height are default size
    NONE: 0,
    // Width and height are minimum bounds
    MIN: 1,
    // Width and height are maximum bounds
    MAX: 2,
    // Window size can not be changed by a user
    FIXED: 3,
};

var TARGET_TRIPLE;
switch(process.arch + "-" + process.platform) {
    case 'x64-linux': { TARGET_TRIPLE = "x86_64-linux"; break; }
    case 'arm64-linux': { TARGET_TRIPLE = "aarch64-linux"; break; }
    case 'x64-darwin': { TARGET_TRIPLE = "x86_64-macos"; break; }
    case 'arm64-darwin': { TARGET_TRIPLE = "aarch64-macos"; break; }
    default: throw new Error("Unsupported CPU/OS");
}

// Path to bunview server
const EXE_PATH = __dirname + `/../build/bunview-${TARGET_TRIPLE}`;

/**
 * Window Class
 * Corresponds to a single Window
*/
export class Window extends EventEmitter {

    /**
     * The child process running the native window
    */
    process = null;
 
    /**
     * Stores binded function callbacks
    */
    #callbacks = [];
    #bindIndex = 0;

    /**
     * Creates a Window object
     * @param {object} config - Configuration for the window
    */
    constructor(config) {
        
        super();

        // Display the window
        this.display();

    }

    /**
     * Writes a Message to the subprocess
     * @param {String} type - Type of this Message
     * @param {String} data - Data to be passed to the subprocess 
    */
    write(type, data) {
        this.process.stdin.write(JSON.stringify({
            type: type,
            data: data
        }) + "\n");
    }

    /**
     * Binds a Bun function to the global namespace in webview
     * @param {String} name - Function name to be exposed to window object
     * @param {Function} callback - Callback function to be executed when binding is called
    */
    bind(name, callback) {
        // Store callback
        this.#callbacks[this.#bindIndex] = callback;

        this.write('bind', this.#bindIndex + ":" + name);

        // Bump bind index
        this.#bindIndex++;
    }

    /**
     * Sets the title of the Window
     * @param {String} title - Title of the window
    */
    setTitle(title) {
        this.write('setTitle', title);
    }

    /**
     * Sets the size of the Window
     * @param {number} width - Width of the window
     * @param {number} height - Height of the window
     * @param {number} hint - Size Hint
    */
    setSize(width, height, hint = SizeHint.NONE) {

        // MAX and MIN size hints don't work on macOS due to an underling webview issue
        if(process.platform == "darwin" && (hint == SizeHint.MAX || hint == SizeHint.MIN)) {
            throw new Error("MacOS only supports SizeHint.NONE & SizeHint.FIXED in setSize()");
        }

        this.write('setSize', width + ':' + height + ':' + hint);
    }

    /**
     * Navigates to a given URL
     * @param {String} url
    */
    navigate(url) {
        this.write('navigate', url);
    }

    /**
     * Evaluates arbitrary Javascript in the Webview context
     * @param {String} code
    */
    eval(code) {
        this.write('eval', code);
    }

    /**
     * Injects Javascript code to be executed before loading any webpage
     * @param {String} code
    */
    init(code) {
        this.write('init', code);
    }
    
    /**
     * Destroys the Window
     * This cannot be undoed
    */
    destroy() {
        this.process.kill();
        this.emit('close');
    }

    /**
     * Displays the Window
     * There is no way to hide the window afterwards without destroying it
    */
    async display() {

        // Spawn child process
        this.process = spawn({
            cmd: [EXE_PATH],
            stdio: ['pipe', 'pipe', 'pipe']
        });

        // Handle standard IO
        (async () => {
            for await (const chunk of this.process.stdout) {
                this.ioHandlers.stdout(new TextDecoder().decode(chunk));
            }
        })();
        (async () => {
            for await (const chunk of this.process.stderr) {
                this.ioHandlers.stderr(new TextDecoder().decode(chunk));
            }
        })();

    }

    /**
     * Internal handlers for standard IO
    */
    ioHandlers = {
        stdout: (msg) => {

            msg = JSON.parse(msg);

            // Handle events from native code
            if(msg.type == 'event') {
                const evt = JSON.parse(msg.data);

                // Window close event
                if(evt.event == 'close') {
                    // Kill the subprocess
                    this.process.kill();
                    this.emit(evt.event);
                }
                else {
                    if(evt.data) this.emit(evt.event, evt.data);
                    else this.emit(evt.event);
                }
            }

            // Handle events from window
            else if(msg.type == 'internalEvent') {
                const evt = msg.data;
                this.emit(evt.event, evt.data);
            }

            // Handle binding callbacks
            else if(msg.type == 'bindCallback') {
                const id = msg.id;
                const args = msg.data;

                // Execute callback
                this.#callbacks[id](...args);
            }

        },

        stderr: (msg) => {         
            if(DEBUG) console.log("(debug) " + msg)
        }
    }

}