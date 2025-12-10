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

let key_buffer = [];

let mouse_x = 0;
let mouse_y = 0;
let mouse_wheel_delta = 0;

const mapKeyNameToKeyIndex = (e) => {
	const lowered = e.toLowerCase();
	switch (lowered) {
		case "a": return Key_A;
		case "b": return Key_B;
		case "c": return Key_C;
		case "d": return Key_D;
		case "e": return Key_E;
		case "f": return Key_F;
		case "g": return Key_G;
		case "h": return Key_H;
		case "i": return Key_I;
		case "j": return Key_J;
		case "k": return Key_K;
		case "l": return Key_L;
		case "m": return Key_M;
		case "n": return Key_N;
		case "o": return Key_O;
		case "p": return Key_P;
		case "q": return Key_Q;
		case "r": return Key_R;
		case "s": return Key_S;
		case "t": return Key_T;
		case "u": return Key_U;
		case "v": return Key_V;
		case "w": return Key_W;
		case "x": return Key_X;
		case "y": return Key_Y;
		case "z": return Key_Z;
		case "0": return Key__0;
		case "1": return Key__1;
		case "2": return Key__2;
		case "3": return Key__3;
		case "4": return Key__4;
		case "5": return Key__5;
		case "6": return Key__6;
		case "7": return Key__7;
		case "8": return Key__8;
		case "9": return Key__9;
		case " ": return Key_Space;
		case "f1": return Key_F1;
		case "f2": return Key_F2;
		case "f3": return Key_F3;
		case "f4": return Key_F4;
		case "f5": return Key_F5;
		case "f6": return Key_F6;
		case "f7": return Key_F7;
		case "f8": return Key_F8;
		case "f9": return Key_F9;
		case "f10": return Key_F10;
		case "f11": return Key_F11;
		case "f12": return Key_F12;
		case "tab": return Key_Tab;
		case "escape": return Key_Escape;
		default: return -1;
	}

};

document.addEventListener("keydown", (e) => {
	const keyIndex = mapKeyNameToKeyIndex(e.key);
	if (keyIndex !== -1) {
		key_buffer[keyIndex] = true;
		if (e.preventDefault) {
			e.preventDefault();
		}
	}
});

document.addEventListener("keyup", (e) => {
	const keyIndex = mapKeyNameToKeyIndex(e.key);
	if (keyIndex !== -1) {
		key_buffer[keyIndex] = false;
		if (e.preventDefault) {
			e.preventDefault();
		}
	}
});

document.addEventListener("mousedown", (e) => {
	if (e.button === 0) {
		key_buffer[Key_MouseLeft] = true;
	} else if (e.button === 1) {
		key_buffer[Key_MouseMiddle] = true;
	} else if (e.button === 2) {
		key_buffer[Key_MouseRight] = true;
	}
});

document.addEventListener("mouseup", (e) => {
	if (e.button === 0) {
		key_buffer[Key_MouseLeft] = false;
	} else if (e.button === 1) {
		key_buffer[Key_MouseMiddle] = false;
	} else if (e.button === 2) {
		key_buffer[Key_MouseRight] = false;
	}
});

document.addEventListener("mousemove", (e) => {
	const canvas = document.getElementById("webgpu-canvas");
	if (!canvas) {
		return;
	}
	const rect = canvas.getBoundingClientRect();
	mouse_x = e.clientX - rect.left;
	mouse_y = e.clientY - rect.top;
});

document.addEventListener("wheel", (e) => {
	// Prevent scrolling the page
	e.preventDefault();

	mouse_wheel_delta -= e.deltaY;
});

jai_imports.jsGetKeyState = (key_map_ptr, key_map_count) => {
	for (let i = 0; i < key_map_count; i++) {
		const index = key_buffer[i] ? 1 : 0;
		setU8(key_map_ptr, i, index);
	}
}

jai_imports.jsGetMousePointer = (x_ptr, y_ptr) => {
	setU32(x_ptr, 0, mouse_x);
	setU32(y_ptr, 0, mouse_y);
}

jai_imports.jsGetMouseWheelDelta = (delta_ptr) => {
	setF32(delta_ptr, 0, mouse_wheel_delta);
	mouse_wheel_delta = 0;
}

jai_imports.jsGetDimensions = (dim_ptr) => {
	const canvas = document.getElementById("webgpu-canvas");
	if (!canvas) {
		setU32(dim_ptr, 0, 0);
		setU32(dim_ptr, 4, 0);
		setU32(dim_ptr, 8, 0);
		setU32(dim_ptr, 12, 0);
		return;
	}
	setU32(dim_ptr, 0, canvas.x);
	setU32(dim_ptr, 4, canvas.y);
	setU32(dim_ptr, 8, canvas.width);
	setU32(dim_ptr, 12, canvas.height);
}

let web_buffer = new Uint8Array(1024*1024*32);
let web_buffer_cursor = 0;
let websocket;
jai_imports.jsConnectServer = (address_ptr, address_len, port, success_ptr) => {
	const address = new TextDecoder().decode(
		new Uint8Array(jai_exports.memory.buffer, Number(address_ptr), Number(address_len))
	);

	console.log(`Connecting to server at ${address}:${port}...`);
	websocket = new WebSocket(`ws://${address}:${port}/ws`);
    websocket.addEventListener("message", async event => {
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
    });
}

jai_imports.jsIsServerConnected = (connected_ptr) => {
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
    const x = copy_array_to_js(length, data);
    websocket.send(x);
};

jai_imports.js_get_web_message_received = (data, count, recv_ptr) => {
    const dest = new Uint8Array(jai_exports.memory.buffer, Number(data), Number(count));

    dest.set(web_buffer);

    // Interpret recv_ptr as a s64 pointer to jai_exports.memory
    const view = new DataView(jai_exports.memory.buffer);
    const recv_address = Number(recv_ptr);

    view.setBigInt64(recv_address, BigInt(web_buffer_cursor), true);

    web_buffer_cursor = 0;
};

jai_imports.js_get_token = () => {
    if (sessionStorage.getItem("token")) {
        return parseInt(sessionStorage.getItem("token"), 10);
    }
    return Math.random() * 1024 * 1024;
}

jai_imports.js_set_token = (token) => {
    sessionStorage.setItem("token", token);
};
