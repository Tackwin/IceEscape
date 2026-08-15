#import "Basic";
#import "Platform";
#import "File_Watcher";
#import "File";
#import "File_Utilities";
#import "Hash_Table";
#import "sqlite";
#import "String";
#if OS == .WINDOWS
	Win32 :: #import "Windows";

receive_buffer: [] u8;

sqlite_array: [..] *sqlite3;

init_platform :: () -> Platform {
	platform: Platform;

	platform.open_server = win32_open_server;
	platform.send_web_message = win32_send_web_message;
	platform.gather_web_messages = win32_gather_web_messages;
	platform.db_query = win32_db_query;
	platform.read_entire_file = std_read_entire_file;
	platform.list_files = str_list_files;

	return platform;
}

print_sqliterror :: (db: *sqlite3, msg: string) {
	errstr: string;
	errstr.data = sqlite3_errmsg(db);
	errstr.count = c_style_strlen(errstr.data);
	print("SQLite Error: % - %\n", msg, errstr);
}

win32_db_query :: (query: *DB_query) {
	bind_type :: (
		stmt: *sqlite3_stmt, info: *Type_Info, value_ptr: *void, index: int) -> bool #expand {
		tag := info.type;
		if tag == .INTEGER {
			integer: int;
			if info.runtime_size == 1 {
				integer = value_ptr.(*s8).*;
			} else if info.runtime_size == 2 {
				integer = value_ptr.(*s16).*;
			} else if info.runtime_size == 4 {
				integer = value_ptr.(*s32).*;
			} else {
				integer = value_ptr.(*s64).*;
			}
			if info.runtime_size == 8 {
				return sqlite3_bind_int64(stmt, (index + 1).(s32), integer.(s64)) == SQLITE_OK;
			} else {
				return sqlite3_bind_int(stmt, (index + 1).(s32), integer.(s32)) == SQLITE_OK;
			}
		} else if tag == .FLOAT {
			double: float64;
			if info.runtime_size == 4 {
				double = value_ptr.(*float32).*;
			} else {
				double = value_ptr.(*float64).*;
			}
			return sqlite3_bind_double(stmt, (index + 1).(s32), double) == SQLITE_OK;
		} else if tag == .STRING {
			str_ptr := value_ptr.(*string);
			return sqlite3_bind_text(
				stmt, (index + 1).(s32), str_ptr.data, xx str_ptr.count, SQLITE_STATIC
			) == SQLITE_OK;
		} else if tag == .BOOL {
			return sqlite3_bind_int(
				stmt, (index + 1).(s32), (ifx value_ptr.(*bool).* then 1 else 0).(s32)
			) == SQLITE_OK;
		} else if tag == .ARRAY && info.(*Type_Info_Array).array_type == .VIEW {
			view := value_ptr.(*[] u8).*;
			view.count *= info.(*Type_Info_Array).element_type.runtime_size;
			return sqlite3_bind_blob(
				stmt, (index + 1).(s32), view.data, xx view.count, SQLITE_STATIC
			) == SQLITE_OK;
		} else {
			return false;
		}
		return true;
	}

	Field_Flag :: enum {
		NONE :: 0;
		JSON_ARRAY :: 1;
	}

	parse_json_int_array :: (json_text: string, output: *[] int) -> bool {
		if json_text.count < 2
			return false;
		if json_text.data[0] != #char "[" || json_text.data[json_text.count - 1] != #char "]"
			return false;

		csv := json_text;
		csv.data += 1;
		csv.count -= 2;

		splitted := split(csv, ",");
		output.* = NewArray(splitted.count, int,, temp);
		for splitted {
			trimmed := trim(it);
			if trimmed.count == 0
				continue;
			
			i: int;
			if !scan2(trimmed, "%", *i)
				continue;
			output.data[it_index] = i;
		}
		return true;
	}

	read_type :: (
		stmt: *sqlite3_stmt,
		info: *Type_Info,
		value_ptr: *void,
		index: int,
		flags := Field_Flag.NONE
	) #expand {
		parsed := false;
		tag := info.type;
		if tag == .INTEGER {
			if info.runtime_size == 1 {
				integer := sqlite3_column_int(stmt, index.(s32));
				value_ptr.(*s8).* = integer.(s8);
			} else if info.runtime_size == 2 {
				integer := sqlite3_column_int(stmt, index.(s32));
				value_ptr.(*s16).* = integer.(s16);
			} else if info.runtime_size == 4 {
				integer := sqlite3_column_int(stmt, index.(s32));
				value_ptr.(*s32).* = integer.(s32);
			} else {
				integer := sqlite3_column_int64(stmt, index.(s32));
				value_ptr.(*s64).* = integer.(s64);
			}
			parsed = true;
		} else if tag == .FLOAT {
			double := sqlite3_column_double(stmt, index.(s32));
			if info.runtime_size == 4 {
				value_ptr.(*float32).* = double.(float32);
			} else {
				value_ptr.(*float64).* = double.(float64);
			}
			parsed = true;
		} else if tag == .STRING {
			text := sqlite3_column_text(stmt, index.(s32));
			length := sqlite3_column_bytes(stmt, index.(s32));
			sqlite_text: string;
			sqlite_text.data = text;
			sqlite_text.count = length;

			value_ptr.(*string).* = tprint("%", sqlite_text);
			parsed = true;
		} else if tag == .BOOL {
			bool_value := sqlite3_column_int(stmt, index.(s32));
			value_ptr.(*bool).* = bool_value != 0;
			parsed = true;
		} else if tag == .ARRAY && info.(*Type_Info_Array).array_type == .VIEW {
			if flags & Field_Flag.JSON_ARRAY {
				text := sqlite3_column_text(stmt, index.(s32));
				length := sqlite3_column_bytes(stmt, index.(s32));
				sqlite_text: string;
				sqlite_text.data = text;
				sqlite_text.count = length;

				if parse_json_int_array(sqlite_text, value_ptr.(*[] int))
					parsed = true;
				else
					print("Failed to parse JSON array: %\n", sqlite_text);
			} else {
				blob := sqlite3_column_blob(stmt, index.(s32));
				length := sqlite3_column_bytes(stmt, index.(s32));
				value_ptr.(*[] u8).data = blob;
				value_ptr.(*[] u8).count = length;
				value_ptr.(*[] u8).count /= info.(*Type_Info_Array).element_type.runtime_size;
				parsed = true;
			}
		}

		if !parsed {
			print(
				"Unsupported type for reading from database\n"
			);
		}
	}

	if query.kind == {
		case .OPEN;
			db: *sqlite3;
			result := sqlite3_open(tprint("%\0", query.query_string).data, *db);
			if result != SQLITE_OK {
				print_sqliterror(db, "Failed to open database");
			} else {
				array_add(*sqlite_array, db);
				query.handle = sqlite_array.count - 1;
				query.success = true;
			}
		case .CLOSE;
			if query.handle < 0 || query.handle >= sqlite_array.count {
				print("Invalid database handle %\n", query.handle);
				return;
			}
			db := sqlite_array[query.handle];
			result := sqlite3_close(db);
			if result != SQLITE_OK {
				print_sqliterror(db, "Failed to close database");
			} else
				query.success = true;
		case .FLUSH;
			if query.handle < 0 || query.handle >= sqlite_array.count {
				print("Invalid database handle %\n", query.handle);
				return;
			}
			db := sqlite_array[query.handle];
			result := sqlite3_exec(db, "PRAGMA wal_checkpoint(FULL);", null, null, null);
			if result != SQLITE_OK {
				print_sqliterror(db, "Failed to flush database");
			} else
				query.success = true;
		case .EXEC;
			if query.handle < 0 || query.handle >= sqlite_array.count {
				print("Invalid database handle %\n", query.handle);
				return;
			}
			db := sqlite_array[query.handle];
			result := sqlite3_exec(db, tprint("%\0", query.query_string).data, null, null, null);
			if result != SQLITE_OK {
				print_sqliterror(db, "Failed to execute query");
			} else
				query.success = true;
		case .STORE;
			if query.handle < 0 || query.handle >= sqlite_array.count {
				print("Invalid database handle %\n", query.handle);
				return;
			}
			db := sqlite_array[query.handle];

			result := sqlite3_exec(db, "BEGIN TRANSACTION;", null, null, null);
			if result != SQLITE_OK {
				print_sqliterror(db, "Failed to begin transaction");
				return;
			}
			defer {
				result := sqlite3_exec(db, "COMMIT;", null, null, null);
				if result != SQLITE_OK {
					print_sqliterror(db, "Failed to commit transaction");
				} else
					query.success = true;
			}

			stmt: *sqlite3_stmt;
			result = sqlite3_prepare_v2(db, tprint("%\0", query.query_string).data, -1, *stmt, null);
			if result != SQLITE_OK {
				print_sqliterror(db, "Failed to prepare statement");
				return;
			}
			defer {
				sqlite3_finalize(stmt);
			}

			// Bind input parameters
			for input: query.input {
				sqlite3_reset(stmt);
				sqlite3_clear_bindings(stmt);

				if query.type.type == .STRUCT {
					struct_info := query.type.(*Type_Info_Struct);
					for field_idx: 0..struct_info.members.count - 1 {
						field := struct_info.members[field_idx];
						value_ptr := (input.(int) + field.offset_in_bytes).(*void);
						if !bind_type(stmt, field.type, value_ptr, field_idx) {
							print_sqliterror(
								db, tprint(
									"Unsupported field (%::%) type for binding\n",
									struct_info.name,
									field.name
								)
							);
						}
					}
				} else {
					if !bind_type(stmt, query.type, input, 0) {
						print_sqliterror(db, tprint("Unsupported type for binding %\n", query.type));
					}
				}

				result := sqlite3_step(stmt);
				if result != SQLITE_DONE {
					print_sqliterror(db, "Failed to execute statement");
					print("Failed query: %\n", query.query_string);
				}
			}
		case .LOAD;
			if query.handle < 0 || query.handle >= sqlite_array.count {
				print("Invalid database handle %\n", query.handle);
				return;
			}

			db := sqlite_array[query.handle];
			stmt: *sqlite3_stmt;
			result := sqlite3_prepare_v2(db, tprint("%\0", query.query_string).data, -1, *stmt, null);
			if result != SQLITE_OK {
				print_sqliterror(db, "Failed to prepare statement");
				return;
			}

			defer {
				sqlite3_finalize(stmt);
			}

			outputs: [..] *void;
			outputs.allocator = query.output_allocator;
			while true {
				result := sqlite3_step(stmt);
				if result == SQLITE_DONE {
					query.success = true;
					break;
				} else if result != SQLITE_ROW {
					print_sqliterror(db, "Failed to execute statement");
					print("Failed query: %\n", query.query_string);
					break;
				}

				output_ptr := alloc(query.type.runtime_size,, query.output_allocator);
				if query.type.type == .STRUCT {
					struct_info := query.type.(*Type_Info_Struct);
					for field_idx: 0..struct_info.members.count - 1 {
						field := struct_info.members[field_idx];

						flag: Field_Flag = Field_Flag.NONE;
						for field.notes
							if it == "json_array"
								flag = .JSON_ARRAY;

						value_ptr := (output_ptr.(int) + field.offset_in_bytes).(*void);
						read_type(stmt, field.type, value_ptr, field_idx, flag);
					}
				} else {
					read_type(stmt, query.type, output_ptr, 0);
				}

				array_add(*outputs, output_ptr);
			}
			query.output = outputs;
	}
}

win32_open_server :: (port: int) -> bool {
	ws_listen :: (url: *u8, buffer: *void, buffer_capacity: u64) #foreign;

	receive_buffer = NewArray(1024 * 1024 * 64, u8, false);

	url := tprint("ws://localhost:%\0", port);
	ws_listen(url.data, receive_buffer.data, xx receive_buffer.count);
	return true;
}

win32_send_web_message :: (msg: [] u8, target: Connection) {
	ws_send :: (uid: u64, data: *u8, count: u64) #foreign;

	if target >= 0 {
		ws_send(target.(u64), msg.data, xx msg.count);
	}
	
}

win32_gather_web_messages :: () -> [] Web_Message {
	ws_poll :: () #foreign;
	ws_poll();

	received := receive_buffer.data.(*u64)[0];
	dropped  := receive_buffer.data.(*u64)[1];

	if dropped > 0 {
		print("[WARNING] The server dropped % messages\n", dropped);
	}

	cursor   := 16;

	msgs := NewArray(xx received, Web_Message, false,, temp);
	for * msgs {
		it.sender = cast,no_check(int) (receive_buffer.data + cursor).(*u64).*;
		it.data.count = cast,no_check(int) (receive_buffer.data + cursor + 8).(*u64).*;
		it.data.data  = receive_buffer.data + cursor + 16;
		cursor += 16;
		cursor += it.data.count;
	}
	
	return msgs;
}

std_read_entire_file :: (file: string, data: [] u8) -> int {
	if data.count == 0 {
		file, ok := file_open(file, for_writing=false);
		if !ok {
			print("Failed to open file: %\n", file);
			return 0;
		}
		defer file_close(*file);
		length:, ok = file_length(file);
		if !ok {
			print("Failed to get file length: %\n", file);
			return 0;
		}

		return length;
	}
	str, ok := read_entire_file(file,, temp);
	if !ok {
		print("Failed to read file: %\n", file);
		return 0;
	}
	memcpy(data.data, str.data, xx min(data.count, str.count));
	return min(data.count, str.count);
}

str_list_files :: (path: string, rec: bool) -> [] string {
	list: [..] string;
	list.allocator = temp;
	visit_files(path, rec, *list, (info: *File_Visit_Info, list: *[..] string) {
		array_add(list, tprint("%", info.full_name));
	});
	return list;
}

app: App;

#if OS == .WINDOWS {
	dll: Win32.HMODULE;
	dll_last_write: u64 = 0;

	load_dll :: () {
		Win32.FreeLibrary(dll);

		Win32.DeleteFileA("IceEscapeServer_temp.dll");
		Win32.CopyFileA("IceEscapeServer.dll", "IceEscapeServer_temp.dll", 0);

		dll = Win32.LoadLibraryA("IceEscapeServer_temp.dll");
		if dll == null {
			print("Failed to load IceEscape.dll\n");
			return;
		}

		// Get the function pointer of app_init
		app_init := Win32.GetProcAddress(dll, "app_init").(#type (app: *App) -> ());
		if app_init {
			app_init(*app);
		}
	}

	reload_dll :: () {
		Win32.FreeLibrary(dll);

		Win32.DeleteFileA("IceEscapeServer_temp.dll");
		Win32.CopyFileA("IceEscapeServer.dll", "IceEscapeServer_temp.dll", 0);

		dll_reloaded := Win32.LoadLibraryA("IceEscapeServer_temp.dll");
		if dll_reloaded == null {
			print("Failed to reload IceEscapeServer.dll\n");
			return;
		}
		dll = dll_reloaded;

		// Get the function pointer of app_init
		app_reload := Win32.GetProcAddress(dll, "app_reload").(#type (app: *App) -> ());
		if app_reload {
			app_reload(*app);
		}
	}
} else {
	#import "main_server";
}

main :: () {
	print("Context size in client is % bytes\n", size_of(#Context));

	args := get_command_line_arguments();
	defer array_free(args);

	platform := init_platform();
	app.platform = *platform;
	app.allocator = context.allocator;
	app.user_data = null;

	#if OS == .WINDOWS
		load_dll();
	else
		app_init(*app);

	loop := true;
	while (loop) {
		#if OS == .WINDOWS {
			if dll {
				file := Win32.CreateFileA("IceEscapeServer.dll", Win32.FILE_GENERIC_READ);
				defer Win32.CloseHandle(file);

				time_struct: Win32.FILETIME;
				Win32.GetFileTime(file, null, null, *time_struct);

				if time_struct.QuadPart != dll_last_write {
					print("Reloading DLL...\n");
					reload_dll();
					dll_last_write = time_struct.QuadPart;
				}
			}

			if dll {
				// Get the function pointer of app_loop
				app_loop := Win32.GetProcAddress(dll, "app_loop").(#type (app: *App) -> bool);
				if app_loop {
					loop = app_loop(*app);
				} else {
					print("App loop not found \n");
				}
			}
		} else {
			loop := app_loop(*app);
		}
	}

	#if OS == .WINDOWS {
		app_quit := Win32.GetProcAddress(dll, "app_quit").(#type (app: *App) -> ());
		if app_quit {
			app_quit(*app);
		}
	} else {
		app_quit(*app);
	}
}
