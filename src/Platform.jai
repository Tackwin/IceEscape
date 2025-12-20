#import "Basic";
#import "Algebra";

#scope_export

Key :: enum s32 {
	A :: 0;
	B;
	C;
	D;
	E;
	F;
	G;
	H;
	I;
	J;
	K;
	L;
	M;
	N;
	O;
	P;
	Q;
	R;
	S;
	T;
	U;
	V;
	W;
	X;
	Y;
	Z;
	_0;
	_1;
	_2;
	_3;
	_4;
	_5;
	_6;
	_7;
	_8;
	_9;
	Space;
	F1;
	F2;
	F3;
	F4;
	F5;
	F6;
	F7;
	F8;
	F9;
	F10;
	F11;
	F12;
	MouseLeft;
	MouseRight;
	MouseMiddle;
	Tab;
	Escape;
	Shift;
	Period;
	Backspace;
	Left;
	Right;
}
Key_COUNT :: #run enum_values_as_s64(Key).count;

Connection :: int;
Connection_Broadcast: Connection : -1;

Connection_Change :: struct {
	connection: Connection;
	entered: bool;
}

Web_Message :: struct {
	data: [] u8;
	sender: Connection;
}

Frame_Info :: struct {
	time: Apollo_Time;

	key_pressed: [Key_COUNT] bool;

	mouse_position: V2f;
	window_size: V2f;
	framebuffer_size: V2f;
	quit := false;

	window_focused := false;

	delta_time := 0.0;

	mouse_wheel := 0;

	message_received: [1024] Web_Message;
	message_received_count := 0;

	file_change: [1024] string;
	file_change_count := 0;
}

Audio :: struct {
	id: int;

	kind: enum {
		Sound;
		Music;
	} = .Sound;

	exponent: float = 3.0;
	volume := 1.0;
	pitch := 1.0;
	delay := 0; // ms

	fade_in := 100; // ms

	repeating: bool;

	loaded: bool;
	playing: bool;
}

Sound :: struct {
	id: int;
	audio_id: int;

	position: V3f;
	playing: bool;
	loop: bool;
	volume: float;
	pitch: float;
}

Listener :: struct {
	position: V3f;
	direction: V3f;
}

Image :: struct {
	width: u32;
	height: u32;
	data: [] u8;
	channels: int = 3;
}

// Atlas sprite properties
Font_Sprite :: struct {
	cnameId: string;
	ctag: string;
	originX: int;
	originY: int;
	positionX: int;
	positionY: int;
	sourceWidth: int;
	sourceHeight: int;
	padding: int;
	trimmed: bool;
	trimRecX: int;
	trimRecY: int;
	trimRecWidth: int;
	trimRecHeight: int;
	colliderType: int;
	colliderPosX: int;
	colliderPosY: int;
	colliderSizeX: int;
	colliderSizeY: int;

	// Atlas contains font data
	charValue: int;
	charOffsetX: int;
	charOffsetY: int;
	charAdvanceX: int;
}

Glyph :: struct {
	unicode: int;
	advance: float;
	planex: float;
	planey: float;
	planew: float;
	planeh: float;
	atlasx: float;
	atlasy: float;
	atlasw: float;
	atlash: float;
}

Font :: struct {
	atlas_width: int;
	atlas_height: int;
	glyphs: [256] Glyph;
}

Platform :: struct {
	gpu: GPU_proc;

	open_server: #type (port: int) -> bool = null;
	connect_server: #type (address: string, port: int, protocol: string) -> Connection, bool = null;
	is_server_connected: #type () -> bool = null;

	send_web_message   : #type (msg: [] u8, target: Connection) = null;
	gather_web_messages: #type () -> [] Web_Message = null;
	gather_connection_changes: #type () -> [] Connection_Change = null;

	get_token:        #type () -> int        = null;
	set_token:        #type (token: int)     = null;
	get_frame_info:   #type (info: *Frame_Info) = null;
	end_frame:        #type ()               = null;

	set_listener_info: #type (listener: Listener) = null;
	load_audio: #type (data: string, compressed: bool) -> Audio = null;
	play_audio: #type (audio: Audio, position: V3f) -> Sound = null;
	query_sound: #type (sound_id: int) -> Sound = null;
	set_sound: #type (sound: Sound) = null;
	volume_audio: #type (x: float) -> float = null;

	read_entire_file: #type (path: string, data: [] u8) -> int = null;
	load_image: #type (data: [] u8) -> Image = null;
	free_image: #type (image: *Image) = null;

	allocator: Allocator;
}

App :: struct {
	platform: *Platform;
	allocator: Allocator;
	user_data: *void;
}

#load "webgpu.jai";
