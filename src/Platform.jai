#import "Basic";
#import "String";
#import "Algebra";
#load "Identity.jai";

#scope_export

Layout :: enum s32 {
	AZERTY :: 0;
	QWERTY :: 1;
	Unknown :: 2;
}

LOCAL_SERVER_PROCESS :: GAME_SERVER_EXE;

Process_Status :: enum s32 {
	Invalid;
	Running;
	Exited;
}

Data_State :: enum s32 {
	Invalid;
	Pending;
	Ready;
	Failed;
}

Data_Status :: struct {
	status: Data_State;
	// With a valid destination this is the number of bytes copied. With an
	// empty or null destination this is the number of bytes available.
	bytes_read: s64;
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

Keys :: struct {
	pressed: [Key_COUNT] bool;
	just_pressed: [Key_COUNT] bool;
	just_released: [Key_COUNT] bool;
}

advance_keys :: (previous: Keys, down: [Key_COUNT] bool) -> Keys {
	next: Keys;
	for i: 0..Key_COUNT - 1 {
		next.pressed[i] = down[i];
		next.just_pressed[i] = down[i] && !previous.pressed[i];
		next.just_released[i] = !down[i] && previous.pressed[i];
	}
	return next;
}

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

	keys: Keys;

	mouse_position: V2f;
	window_size: V2f;
	framebuffer_size: V2f;
	quit := false;

	window_focused := false;

	delta_time := 0.0;

	mouse_wheel := 0;

	capture_frame := false;
	capture_serial: u64;

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

Sql_Bind :: struct {
	type: *Type_Info;
	value: *void;
}

Sql :: struct {
	text: string;
	binds: [] Sql_Bind;
}

Sql_Load :: struct (T: Type) {
	platform: *Platform;
	db: DB_query.Handle;
	q: Sql;
}

Sql_Store :: struct (T: Type) {
	platform: *Platform;
	db: DB_query.Handle;
	text: string;
	max_iterations: int;
}

DB_query :: struct {
	Handle :: int;

	kind: enum {
		OPEN;
		EXEC;
		CLOSE;
		FLUSH;
		PREPARE;
		STEP_ROW;
		STORE_ROW;
		STEP_EXEC;
		FINALIZE;
	};

	handle: Handle;
	memory := false;

	query_string: string;
	binds: [] Sql_Bind;
	stmt: *void;
	row_ptr: *void;

	type: *Type_Info;

	success := false;
}

db_table_name :: ($T: Type) -> string {
	return T.table;
}

db_sql_type :: (member: Type_Info_Struct_Member) -> string {
	for note: member.notes {
		if note == "json_array"
			return "TEXT";
	}

	tag := member.type.type;
	if tag == .INTEGER || tag == .BOOL
		return "INTEGER";
	if tag == .FLOAT
		return "REAL";
	if tag == .STRING
		return "TEXT";
	if tag == .ARRAY {
		arr := member.type.(*Type_Info_Array);
		if arr.element_type.type == .INTEGER && arr.element_type.runtime_size == 1
			return "BLOB";
		return "TEXT";
	}

	assert(false, "No SQL mapping for database field '%'\n", member.name);
	return "TEXT";
}

sql_insert_text :: ($T: Type) -> string {
	info := type_info(T).(*Type_Info_Struct);
	table := db_table_name(T);

	pk_name: string;
	sb: String_Builder;
	sb.allocator = temp;
	print_to_builder(*sb, "INSERT INTO % (", table);
	sep := "";
	for member: info.members {
		if member.offset_into_constant_storage >= 0
			continue;

		column := to_lower_copy(member.name,, temp);
		print_to_builder(*sb, "%1%2", sep, column);
		sep = ", ";

		for note: member.notes {
			if note == "PK" {
				assert(pk_name.count == 0, "Type % has more than one @PK field\n", T);
				pk_name = column;
			}
		}
	}
	print_to_builder(*sb, ") VALUES (");
	sep = "";
	for member: info.members {
		if member.offset_into_constant_storage >= 0
			continue;
		print_to_builder(*sb, "%1?", sep);
		sep = ", ";
	}
	print_to_builder(*sb, ")");

	if pk_name.count > 0 {
		any_update := false;
		for member: info.members {
			if member.offset_into_constant_storage >= 0
				continue;
			column := to_lower_copy(member.name,, temp);
			if column == pk_name
				continue;
			if !any_update {
				print_to_builder(*sb, " ON CONFLICT(%) DO UPDATE SET ", pk_name);
				any_update = true;
				sep = "";
			}
			print_to_builder(*sb, "%1%2 = excluded.%2", sep, column);
			sep = ", ";
		}
		if !any_update
			print_to_builder(*sb, " ON CONFLICT(%) DO NOTHING", pk_name);
	}

	return builder_to_string(*sb,, temp);
}

sql_bind_count :: (text: string) -> int {
	n := 0;
	i := 0;
	while i < text.count {
		if text[i] == #char "?"
			n += 1;
		i += 1;
	}
	return n;
}

sql :: (text: string, args: .. Any) -> Sql {
	assert(sql_bind_count(text) == args.count, "sql() ? count does not match argument count\n");
	q: Sql;
	q.text = text;
	if args.count > 0 {
		q.binds = NewArray(args.count, Sql_Bind,, temp);
		for args {
			q.binds[it_index].type = it.type;
			q.binds[it_index].value = it.value_pointer;
		}
	}
	return q;
}

sql_exec :: (platform: *Platform, db: DB_query.Handle, q: Sql) {
	if q.binds.count == 0 {
		query: DB_query;
		query.kind = .EXEC;
		query.handle = db;
		query.query_string = q.text;
		platform.db_query(*query);
		return;
	}

	query: DB_query;
	query.kind = .PREPARE;
	query.handle = db;
	query.query_string = q.text;
	query.binds = q.binds;
	platform.db_query(*query);
	if !query.success
		return;
	query.kind = .STEP_EXEC;
	platform.db_query(*query);
	query.kind = .FINALIZE;
	platform.db_query(*query);
}

sql_loads :: (platform: *Platform, db: DB_query.Handle, q: Sql, $T: Type) -> Sql_Load(T) {
	return .{ platform, db, q };
}

sql_stores :: (
	platform: *Platform,
	db: DB_query.Handle,
	text: string,
	$T: Type,
	max_iterations := -1
) -> Sql_Store(T) {
	return .{ platform, db, text, max_iterations };
}

sql_stores :: (
	platform: *Platform,
	db: DB_query.Handle,
	$T: Type,
	max_iterations := -1
) -> Sql_Store(T) {
	return sql_stores(platform, db, sql_insert_text(T), T, max_iterations);
}

sql_tloads :: (platform: *Platform, db: DB_query.Handle, q: Sql, $T: Type) -> [] T {
	rows: [..] T;
	rows.allocator = temp;
	for sql_loads(platform, db, q, T) {
		array_add(*rows, it);
	}
	return rows;
}

sql_load :: (platform: *Platform, db: DB_query.Handle, q: Sql, $T: Type) -> T, bool {
	result: T;
	found := false;
	for sql_loads(platform, db, q, T) {
		result = it;
		found = true;
		break;
	}
	return result, found;
}

sql_store :: (platform: *Platform, db: DB_query.Handle, text: string, row: $T) {
	for sql_stores(platform, db, text, T, 1) {
		it = row;
	}
}

sql_store :: (platform: *Platform, db: DB_query.Handle, row: $T) {
	sql_store(platform, db, sql_insert_text(T), row);
}

for_expansion :: (load: $L/Sql_Load, body: Code, flags: For_Flags) #expand {
	#assert !(flags & .REVERSE) "sql_loads does not support reverse iteration";

	query: DB_query;
	query.kind = .PREPARE;
	query.handle = load.db;
	query.query_string = load.q.text;
	query.binds = load.q.binds;
	query.type = type_info(L.T);
	load.platform.db_query(*query);

	`it: L.T = .{};
	`it_index := 0;

	if query.success {
		for load_loop: 0..0x7FFF_FFFE {
			it = .{};
			query.kind = .STEP_ROW;
			query.row_ptr = *it;
			load.platform.db_query(*query);
			if !query.success
				break load_loop;

			#insert (break = break load_loop, continue = { it_index += 1; continue load_loop; }) body;

			it_index += 1;
		}
	}

	query.kind = .FINALIZE;
	load.platform.db_query(*query);
}

for_expansion :: (store: $S/Sql_Store, body: Code, flags: For_Flags) #expand {
	#assert !(flags & .REVERSE) "sql_stores does not support reverse iteration";
	#assert !(flags & .POINTER) "sql_stores it is already a write slot";

	query: DB_query;
	query.kind = .PREPARE;
	query.handle = store.db;
	query.query_string = store.text;
	query.type = type_info(S.T);
	store.platform.db_query(*query);

	sql_exec(store.platform, store.db, sql("BEGIN TRANSACTION;"));

	`it: S.T = .{};
	`it_index := 0;

	if query.success {
		for store_loop: 0..0x7FFF_FFFE {
			if store.max_iterations >= 0 && it_index >= store.max_iterations
				break store_loop;

			it = .{};
			#insert (
				break = break store_loop,
				continue = { it_index += 1; continue store_loop; }
			) body;
			query.kind = .STORE_ROW;
			query.row_ptr = *it;
			store.platform.db_query(*query);
			it_index += 1;
		}
	}

	sql_exec(store.platform, store.db, sql("COMMIT;"));
	query.kind = .FINALIZE;
	store.platform.db_query(*query);
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


Platform :: struct {
	extern_ref :: s32;
	wait: #type (promise: extern_ref) = null;
	poll: #type (promise: extern_ref, data: [] u8) -> Data_Status = null;

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
	fetch_data: #type (path: string) -> extern_ref = null;
	load_audio: #type (data: [] u8, compressed: bool, out: *Audio) -> extern_ref = null;
	play_audio: #type (audio: Audio, position: V3f) -> Sound = null;
	set_sound: #type (sound: Sound) = null;

	list_files : #type (path: string, rec: bool) -> [] string = null;
	read_entire_file: #type (path: string, data: [] u8) -> int = null;
	write_file: #type (path: string, data: [] u8) -> bool = null;
	load_image: #type (data: [] u8) -> Image = null;
	free_image: #type (image: *Image) = null;

	db_query: #type (query: *DB_query) = null;

	create_process: #type (path: string) -> extern_ref = null;
	query_process_status: #type (ref: extern_ref) -> Process_Status = null;
	close_process: #type (ref: extern_ref) = null;

	Thread_F :: #type (data: *void);
	spawn: #type (func: Thread_F, data: *void) -> int = null;
	join: #type (thread_id: int) = null;

	allocator: Allocator;
}

fetch_data :: (platform: *Platform, path: string) -> Platform.extern_ref {
	if platform.fetch_data == null return 0;
	return platform.fetch_data(path);
}

poll :: (platform: *Platform, promise: Platform.extern_ref, data: [] u8) -> Data_Status {
	if platform.poll == null return .{ status = .Invalid };
	return platform.poll(promise, data);
}

create_process :: (platform: *Platform, path: string) -> Platform.extern_ref {
	if platform.create_process == null return 0;
	return platform.create_process(path);
}

query_process_status :: (platform: *Platform, ref: Platform.extern_ref) -> Process_Status {
	if platform.query_process_status == null return .Invalid;
	return platform.query_process_status(ref);
}

close_process :: (platform: *Platform, ref: Platform.extern_ref) {
	if platform.close_process == null return;
	platform.close_process(ref);
}

App :: struct {
	platform: *Platform;
	allocator: Allocator;
	user_data: *void;
}

#load "webgpu.jai";
