#import "Basic";
#import "String";
#import "Algebra";

#scope_export

Layout :: enum s32 {
	AZERTY :: 0;
	QWERTY :: 1;
	Unknown :: 2;
}

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
	Up;
	Down;
	Enter;
	Control;
	Minus;
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

	layout: Layout;

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
	volume: float;
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

DB_query :: struct {
	Handle :: int;
	
	kind: enum {
		OPEN;
		EXEC;
		CLOSE;
		STORE;
		LOAD;
		FLUSH;
	};

	handle: Handle;
	memory := false;

	query_string: string;

	input: [] *void;
	output: [] *void;
	output_allocator: Allocator;

	type: *Type_Info;

	success := false;
}
load_database_custom :: (
	platform: *Platform, db: DB_query.Handle, $T: Type, query_string: string
) -> [] *T {
	query := DB_query.{};
	query.kind = .LOAD;
	query.handle = db;
	query.type = type_info(T);
	info := query.type.(*Type_Info_Struct);
	assert(query.type.type == .STRUCT);

	query.query_string = query_string;
	query.output_allocator = temp;

	platform.db_query(*query);

	output: [] *T;
	output.data = query.output.data.(**T);
	output.count = query.output.count;
	return output;
}


load_database :: (
	platform: *Platform,
	db: DB_query.Handle,
	table: string,
	$T: Type,
	where: string = ""
) -> [] *T {
	query := DB_query.{};
	query.kind = .LOAD;
	query.handle = db;
	query.type = type_info(T);
	info := query.type.(*Type_Info_Struct);
	assert(query.type.type == .STRUCT);

	sb: String_Builder;
	sb.allocator = temp;
	print_to_builder(*sb, "SELECT ");
	sep := "";
	for info.members {
		print_to_builder(*sb, "%1%2", sep, to_lower_copy(it.name,, temp));
		sep = ", ";
	}
	print_to_builder(*sb, " FROM %", table);
	if where != "" {
		print_to_builder(*sb, " WHERE %", where);
	}
	print_to_builder(*sb, ";");

	query.query_string = builder_to_string(*sb);

	query.output_allocator = temp;

	platform.db_query(*query);

	output: [] *T;
	output.data = query.output.data.(**T);
	output.count = query.output.count;
	return output;
}

store_database :: (
	platform: *Platform,
	db: DB_query.Handle,
	table: string,
	inputs: [] $T,
	on_conflict_update: bool = true
) {
	query := DB_query.{};
	query.kind = .STORE;
	query.handle = db;
	query.input = NewArray(inputs.count, *void,, temp);
	for 0..inputs.count - 1 {
		query.input[it] = (inputs.data + it).(*void);
	}
	query.type = type_info(T);
	info := query.type.(*Type_Info_Struct);
	assert(query.type.type == .STRUCT);

	sb: String_Builder;
	sb.allocator = temp;
	print_to_builder(*sb, "INSERT INTO % (", table);
	sep := "";
	for info.members {
		print_to_builder(*sb, "%1%2", sep, to_lower_copy(it.name,, temp));
		sep = ", ";
	}
	print_to_builder(*sb, ") VALUES (");
	sep = "";
	for info.members {
		print_to_builder(*sb, "%1?", sep);
		sep = ", ";
	}
	print_to_builder(*sb, ")");

	if on_conflict_update {
		any_to_update := false;
		for info.members {
			if it.name != "id" {
				any_to_update = true;
				break;
			}
		}

		if any_to_update {
			print_to_builder(*sb, " ON CONFLICT(id) DO UPDATE SET ");
			sep = "";
			for info.members {
				if it.name == "id" {
					continue;
				}
				print_to_builder(*sb, "%1%2 = excluded.%2", sep, to_lower_copy(it.name,, temp));
				sep = ", ";
			}
		}
	}
	print_to_builder(*sb, ";");
	

	query.query_string = builder_to_string(*sb);

	platform.db_query(*query);
}

flush_database :: (platform: *Platform, db: DB_query.Handle) {
	query := DB_query.{};
	query.kind = .FLUSH;
	query.handle = db;
	platform.db_query(*query);
}

open_database :: (platform: *Platform, path: string) -> DB_query.Handle {
	query := DB_query.{};
	query.kind = .OPEN;
	query.query_string = path;
	platform.db_query(*query);
	return query.handle;
}

quit_database :: (platform: *Platform, handle: DB_query.Handle) {
	query := DB_query.{};
	query.kind = .CLOSE;
	query.handle = handle;
	platform.db_query(*query);
}

exec_database :: (platform: *Platform, handle: DB_query.Handle, query_string: string) {
	query := DB_query.{};
	query.kind = .EXEC;
	query.handle = handle;
	query.query_string = query_string;
	platform.db_query(*query);
}

Platform :: struct {
	extern_ref :: s32;
	wait: #type (promise: extern_ref) = null;

	gpu: GPU_proc;

	open_server: #type (port: int) -> bool = null;
	connect_server: #type (address: string, port: int, protocol: string) -> Connection, bool = null;
	is_server_connected: #type () -> bool = null;
	is_released: #type () -> bool = null;

	send_web_message   : #type (msg: [] u8, target: Connection) = null;
	send_web_messages  : #type (msg_pool: [] u8, msg_indices: [] int, target: Connection) = null;
	gather_web_messages: #type () -> [] Web_Message = null;
	gather_connection_changes: #type () -> [] Connection_Change = null;

	get_token:        #type () -> int        = null;
	set_token:        #type (token: int)     = null;
	get_frame_info:   #type (info: *Frame_Info) = null;
	end_frame:        #type ()               = null;

	get_current_time: #type () -> Apollo_Time = null;
	to_calendar: #type (time: Apollo_Time) -> Calendar_Time = null;

	sleep: #type (ms: int) =null;

	set_listener_info: #type (listener: Listener) = null;
	load_audio: #type (data: string, compressed: bool, out: *Audio) -> extern_ref = null;
	play_audio: #type (audio: Audio, position: V3f) -> Sound = null;
	set_sound: #type (sound: Sound) = null;

	list_files : #type (path: string, rec: bool) -> [] string = null;
	read_entire_file: #type (path: string, data: [] u8) -> int = null;
	load_image: #type (data: [] u8) -> Image = null;
	free_image: #type (image: *Image) = null;

	db_query: #type (query: *DB_query) = null;

	Thread_F :: #type (data: *void);
	spawn: #type (func: Thread_F, data: *void) -> int = null;
	join: #type (thread_id: int) = null;

	allocator: Allocator;
}

App :: struct {
	platform: *Platform;
	allocator: Allocator;
	user_data: *void;
}

#load "webgpu.jai";