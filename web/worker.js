"use strict";

let started = false;

let controls_buffer;
let workerInstance;
let jai_exports; // contains procedures and globals from the loaded wasm module

const jai_imports = {};

self.onmessage = async e => {
	if (e.data.module && e.data.memory && e.data.controls_buffer) {
		jai_imports.memory = e.data.memory;
		const imports = {
			"env": new Proxy(jai_imports, {
				get(target, prop, receiver) {
					// if (prop === "memcpy") throw new Error("these");
					if (target.hasOwnProperty(prop)) return target[prop];
					return () => { throw new Error("Missing function: " + prop); };
				},
			}),
		};
		workerInstance = await WebAssembly.instantiate(e.data.module, imports);
		jai_exports = workerInstance.exports;
		controls_buffer = e.data.controls_buffer;

		postMessage({ ready: true });
	}
	if (e.data.start) {
		started = true;
		const worker_loop = WebAssembly.promising(workerInstance.exports.wasm_worker_loop);
		if (workerInstance)
			setInterval(async () => {
				await worker_loop();
				// await start();
			}, 1)
	}
}

// const start = async () => {
// 	while (true) {
// 	}
// }


let web_buffer = new Uint8Array(1024*1024*32);
let web_buffer_cursor = 0;
let websocket;
jai_imports.js_connect_server = (
	protocol_ptr, protocol_len, address_ptr, address_len, port, success_ptr
) => {
	const address = getStringX(address_ptr, address_len);
	const protocol = getStringX(protocol_ptr, protocol_len);

	const uri = `${protocol}://${address}:${port}/ws`;
	console.log(`Connecting to server at ${uri}...`);
	websocket = new WebSocket(uri);
	websocket.onopen = () => {
		console.log("Websocket server opened !");
	}
	websocket.onerror = (e) => {
		console.error("Websocket error:", e);
	}
	websocket.onclose = (e) => {
		console.log("Websocket close", e);
	}
	websocket.onmessage = async (event) => {
        // Append event.data to web_buffer at web_buffer_cursor
        const blob = event.data;
        const buffer = await blob.arrayBuffer();
        const data = new Uint8Array(buffer);
        // const data = new Uint8Array(await event.data.arrayBuffer());
        if (web_buffer_cursor + data.length > web_buffer.length) {
            console.error("Web buffer overflow, dropping message");
            return;
        }

        web_buffer.set(data, web_buffer_cursor);
        web_buffer_cursor += data.length;
	}
}

jai_imports.js_is_server_connected = (connected_ptr) => {
	let connected = 0;
	if (websocket && websocket.readyState === WebSocket.OPEN) {
		connected = 1;
	}
	setU32(connected_ptr, 0, connected);
}

const copy_array_to_js = (count, data) => {
    const u8 = new Uint8Array(jai_exports.memory.buffer)
    const bytes = u8.subarray(Number(data), Number(data) + Number(count));
    return bytes;
}
jai_imports.js_send_web_message = (data, length) => {
    if (websocket.readyState != WebSocket.OPEN)
        return;
	const span = new Uint8Array(jai_exports.memory.buffer, Number(data), Number(length));
	const copy = new ArrayBuffer(Number(length));
	new Uint8Array(copy).set(span);
    websocket.send(copy);
};

jai_imports.jsDontOptimize = (count_ptr) => {};

jai_imports.js_get_web_message_received_buffer_count = (count_ptr) => {
	setU64(count_ptr, 0, web_buffer_cursor);
};

jai_imports.js_get_web_message_received = (data, count, recv_ptr) => {
    const dest = new Uint8Array(jai_exports.memory.buffer, Number(data), Number(count));

    dest.set(web_buffer.subarray(0, Number(count)));

    // Interpret recv_ptr as a s64 pointer to jai_exports.memory
    const view = new DataView(jai_exports.memory.buffer);
    const recv_address = Number(recv_ptr);

    view.setBigInt64(recv_address, BigInt(web_buffer_cursor), true);

    web_buffer_cursor = 0;
};

jai_imports.js_get_current_time_monotonic = (low_ptr, high_ptr) => {
	const epoch = new Date("1969-07-20T20:17:40Z").getTime();
	const now = performance.now() + performance.timeOrigin - epoch;
	const fs = BigInt(Math.round(now)) * 1000n * 1000n * 1000n * 1000n;
	const high = fs >> 64n;
	const low = fs & ((1n << 64n) - 1n)

	setU64(low_ptr, 0, low);
	setU64(high_ptr, 0, high);
}
const Key_A = 0;
const Key_B = 1;
const Key_C = 2;
const Key_D = 3;
const Key_E = 4;
const Key_F = 5;
const Key_G = 6;
const Key_H = 7;
const Key_I = 8;
const Key_J = 9;
const Key_K = 10;
const Key_L = 11;
const Key_M = 12;
const Key_N = 13;
const Key_O = 14;
const Key_P = 15;
const Key_Q = 16;
const Key_R = 17;
const Key_S = 18;
const Key_T = 19;
const Key_U = 20;
const Key_V = 21;
const Key_W = 22;
const Key_X = 23;
const Key_Y = 24;
const Key_Z = 25;
const Key__0 = 26;
const Key__1 = 27;
const Key__2 = 28;
const Key__3 = 29;
const Key__4 = 30;
const Key__5 = 31;
const Key__6 = 32;
const Key__7 = 33;
const Key__8 = 34;
const Key__9 = 35;
const Key_Space = 36;
const Key_F1 = 37;
const Key_F2 = 38;
const Key_F3 = 39;
const Key_F4 = 40;
const Key_F5 = 41;
const Key_F6 = 42;
const Key_F7 = 43;
const Key_F8 = 44;
const Key_F9 = 45;
const Key_F10 = 46;
const Key_F11 = 47;
const Key_F12 = 48;
const Key_MouseLeft = 49;
const Key_MouseRight = 50;
const Key_MouseMiddle = 51;
const Key_Tab = 52;
const Key_Escape = 53;
const Key_LShift = 54;
const Key_RShift = 55;
const Key_Period = 56;
const Key_Backspace = 57;
const Key_Left = 58;
const Key_Right = 59;
const Key_Count = 60;
const Mouse_X = 128;
const Mouse_Y = 132;
const Mouse_Wheel = 136;
const Window_W = 140;
const Window_H = 144;
const Control_Token = 148;

jai_imports.js_get_token = () => {
	return new DataView(controls_buffer).getUint32(Control_Token);
}
jai_imports.js_set_token = (token) => {
	new DataView(controls_buffer).setUint32(Control_Token, token);
	postMessage({ set_token: token });
}

jai_imports.js_get_key_state = (key_map_ptr, key_map_count) => {
	for (let i = 0; i < key_map_count; i++) {
		setU8(key_map_ptr, i, new DataView(controls_buffer).getUint8(i));
	}
}

jai_imports.js_get_mouse_pointer = (x_ptr, y_ptr) => {
	setU32(x_ptr, 0, new DataView(controls_buffer).getUint32(Mouse_X));
	setU32(y_ptr, 0, new DataView(controls_buffer).getUint32(Mouse_Y));
}

jai_imports.js_get_mouse_wheel_delta = (delta_ptr) => {
	setF32(delta_ptr, 0, new DataView(controls_buffer).getFloat32(Mouse_Wheel));
	new DataView(controls_buffer).setFloat32(Mouse_Wheel, 0)
}

jai_imports.js_get_dimemsions = (dim_ptr) => {
	setU32(dim_ptr, 0, 0);
	setU32(dim_ptr, 4, 0);
	setU32(dim_ptr, 8, new DataView(controls_buffer).getUint32(Window_W));
	setU32(dim_ptr, 12, new DataView(controls_buffer).getUint32(Window_H));
}

jai_imports.js_load_audio = async (params_ptr) => {
}

jai_imports.js_play_audio = (params_ptr) => {
}

jai_imports.js_volume_audio = (params_ptr) => {
}

jai_imports.js_query_sound = (params_ptr) => {
}

jai_imports.js_set_sound = (params_ptr) => {

}

jai_imports.js_set_listener_info = (params_ptr) => {
}

jai_imports.memcmp = (a, b, count) => {
	const [na, nb, nc] = [Number(a), Number(b), Number(count)];
	const u8    = new Uint8Array(jai_exports.memory.buffer);
	const buf_a = u8.subarray(na, na + nc);
	const buf_b = u8.subarray(nb, nb + nc);
	for (let i = 0; i < count; i++) {
		const delta = Number(buf_a[i]) - Number(buf_b[i]);
		if (delta !== 0) return delta;
	}
	return 0;
};

jai_imports.js_debug_break = () => { debugger; };

// console.log and console.error always add newlines so we need to buffer the output from write_string
// to simulate a more basic I/O behavior. We’ll flush it after a certain time so that you still
// see the last line if you forget to terminate it with a newline for some reason.
let console_buffer = "";
let console_buffer_is_standard_error;
let console_timeout;
const FLUSH_CONSOLE_AFTER_MS = 3;
const flush_console_buffer = () => {
	if (!console_buffer) return;

	if (console_buffer_is_standard_error) {
		console.error(console_buffer);
	} else {
		console.log(console_buffer);
	}

	console_buffer = "";
};

const write_to_console_log = (str, to_standard_error) => {
	if (console_buffer && console_buffer_is_standard_error != to_standard_error) {
		flush_console_buffer();
	}

	console_buffer_is_standard_error = to_standard_error;
	const lines = str.split("\n");
	for (let i = 0; i < lines.length - 1; i++) {
		console_buffer += lines[i];
		flush_console_buffer();
	}

	console_buffer += lines[lines.length - 1];
	flush_console_buffer();
}

jai_imports.wasm_write_string = (s_count, s_data, to_standard_error) => {
	try {
		data_view.byteLength;
	} catch {
		data_view = new DataView(jai_exports.memory.buffer);
	}

	
	const string = getStringX(s_data, s_count);
	write_to_console_log(string, to_standard_error);
};
jai_imports.wasm_debug_break = () => {
	debugger;
};

let data_view = null;

const getU64 = (ptr, offset) => {
	try {
		data_view.byteLength;
	} catch {
		data_view = new DataView(jai_exports.memory.buffer);
	}
	
	return data_view.getBigUint64(Number(ptr) + Number(offset), true);
}
const getU32 = (ptr, offset) => {
	try {
		data_view.byteLength;
	} catch {
		data_view = new DataView(jai_exports.memory.buffer);
	}


	return data_view.getUint32(Number(ptr) + Number(offset), true);
}
const getS32 = (ptr, offset) => {
	try {
		data_view.byteLength;
	} catch {
		data_view = new DataView(jai_exports.memory.buffer);
	}

	return data_view.getInt32(Number(ptr) + Number(offset), true);
}
const getF64 = (ptr, offset) => {
	try {
		data_view.byteLength;
	} catch {
		data_view = new DataView(jai_exports.memory.buffer);
	}
	return data_view.getFloat64(Number(ptr) + Number(offset), true);
}
const getF32 = (ptr, offset) => {
	try {
		data_view.byteLength;
	} catch {
		data_view = new DataView(jai_exports.memory.buffer);
	}
	return data_view.getFloat32(Number(ptr) + Number(offset), true);
}
const setF32 = (ptr, offset, value) => {
	try {
		data_view.byteLength;
	} catch {
		data_view = new DataView(jai_exports.memory.buffer);
	}
	data_view.setFloat32(Number(ptr) + Number(offset), Number(value), true);
}

const setU8 = (ptr, offset, value) => {
	try {
		data_view.byteLength;
	} catch {
		data_view = new DataView(jai_exports.memory.buffer);
	}
	data_view.setUint8(Number(ptr) + Number(offset), Number(value));
}

const setU32 = (ptr, offset, value) => {
	try {
		data_view.byteLength;
	} catch {
		data_view = new DataView(jai_exports.memory.buffer);
	}
	data_view.setUint32(Number(ptr) + Number(offset), Number(value), true);
}
const setU64 = (ptr, offset, value) => {
	try {
		data_view.byteLength;
	} catch {
		data_view = new DataView(jai_exports.memory.buffer);
	}
	data_view.setBigUint64(Number(ptr) + Number(offset), BigInt(value), true);
}

const getStringX = (data, length) => {
	const span = new Uint8Array(jai_exports.memory.buffer, Number(data), Number(length));
	const copy = new ArrayBuffer(Number(length));
	new Uint8Array(copy).set(span);
	return new TextDecoder().decode(copy);
}

const getString = (stringview_ptr) => {
	const data = getU64(stringview_ptr, 0);
	const length = getU64(stringview_ptr, 8);
	return getStringX(data, length);
}

