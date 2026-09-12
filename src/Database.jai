#import "Platform";
#import "Basic";
#import "String";

#scope_export

DB_Profile_Id :: struct {
	table :: "profile_ids";
	id: int; @PK
}

DB_Profile_Stats :: struct {
	table :: "profile_stats";
	id: int; @PK
	win_count: int;
	death_count: int;
	revive_count: int;
}

DB_Profile_Passcode :: struct {
	table :: "profile_passcodes";
	id: int; @PK
	passcode: u64;
}

DB_Profile_Username :: struct {
	table :: "profile_usernames";
	id: int; @PK
	username: string;
}

DB_Profile_Token :: struct {
	table :: "profile_tokens";
	id: int; @PK
	token: u64;
}

DB_Time_Entry :: struct {
	table :: "time_entries";
	id: int;
	profile_id: int;
	terrain_id: int;
	time_ms: int;
	timestamp_ms: int;
}

DB_Terrain_Id :: struct {
	table :: "terrain_ids";
	id: int; @PK
}

DB_Terrain_Infos :: struct {
	table :: "terrain_infos";
	id: int; @PK
	name: string;
	author_profile_id: int;
	created_ms: int;
}

DB_Terrain_Ascii :: struct {
	table :: "terrain_asciis";
	ascii_id: int; @PK
	id: int;
	ascii: string;
	created_ms: int;
}

DB_Terrain_Thumbnail :: struct {
	table :: "terrain_thumbnails";
	ascii_id: int; @PK
	thumbnail: [] u8;
}

DB_Terrain_Roster :: struct {
	table :: "terrain_rosters";
	id: int; @PK
	name: string;
	terrain_ids: [] int; @json_array
}

DB_Terrain_Bomberman_Entry :: struct {
	table :: "terrain_bomberman_entry";
	id: int; @PK
	terrain_id: int;
	max_players: int;
}

All_DB_Types :: Type.[
	DB_Profile_Id,
	DB_Profile_Stats,
	DB_Profile_Passcode,
	DB_Profile_Username,
	DB_Profile_Token,
	DB_Time_Entry,
	DB_Terrain_Id,
	DB_Terrain_Infos,
	DB_Terrain_Ascii,
	DB_Terrain_Thumbnail,
	DB_Terrain_Roster,
	DB_Terrain_Bomberman_Entry,
];

DB_Pragma_Table_Info :: struct {
	cid: int;
	name: string;
	type: string;
	notnull: int;
	dflt_value: string;
	pk: int;
}

ensure_table :: (platform: *Platform, db: DB_query.Handle, $T: Type) {
	info := type_info(T).(*Type_Info_Struct);
	table := db_table_name(T);

	sb: String_Builder;
	sb.allocator = temp;
	print_to_builder(*sb, "CREATE TABLE IF NOT EXISTS % (\n", table);
	sep := "";
	for info.members {
		if it.offset_into_constant_storage >= 0
			continue;

		column := to_lower_copy(it.name,, temp);
		print_to_builder(*sb, "%\t% %", sep, column, db_sql_type(it));
		sep = ",\n";
		is_pk := false;
		json_array := false;
		for note: it.notes {
			if note == "PK"
				is_pk = true;
			if note == "json_array"
				json_array = true;
		}
		if is_pk
			print_to_builder(*sb, " PRIMARY KEY");
		if json_array {
			print_to_builder(
				*sb,
				" CHECK (json_valid(%1) AND json_type(%1) = 'array')",
				column
			);
		}
	}
	print_to_builder(*sb, "\n);");

	sql_exec(platform, db, sql(builder_to_string(*sb)));

	existing_names: [..] string;
	existing_names.allocator = temp;
	for sql_loads(
		platform, db, sql(tprint("PRAGMA table_info(%);", table)), DB_Pragma_Table_Info
	) {
		array_add(*existing_names, to_lower_copy(it.name,, temp));
	}
	for info.members {
		if it.offset_into_constant_storage >= 0
			continue;
		column := to_lower_copy(it.name,, temp);
		found := false;
		for existing_names {
			if it == column {
				found = true;
				break;
			}
		}
		if !found {
			sql_exec(
				platform,
				db,
				sql(tprint("ALTER TABLE % ADD COLUMN % %;", table, column, db_sql_type(it)))
			);
		}
	}

	sql_exec(platform, db, sql(tprint("SELECT 1 FROM % LIMIT 0;", table)));
}

ensure_database_schema :: (platform: *Platform, db: DB_query.Handle) {
	#insert #run -> string {
		sb: String_Builder;
		for All_DB_Types {
			print(*sb, "ensure_table(platform, db, %);\n", it);
		}
		return builder_to_string(*sb);
	};
}

get_wr_info :: (platform: *Platform, db: DB_query.Handle, terrain_id: int) -> DB_Time_Entry {
	row, found := sql_load(
		platform,
		db,
		sql(
			"SELECT * FROM time_entries WHERE terrain_id = ? ORDER BY time_ms ASC LIMIT 1",
			terrain_id
		),
		DB_Time_Entry
	);
	if found
		return row;
	return .{};
}

get_profile_name :: (platform: *Platform, db: DB_query.Handle, profile_id: int) -> string {
	row, found := sql_load(
		platform,
		db,
		sql("SELECT username FROM profile_usernames WHERE id = ? LIMIT 1", profile_id),
		DB_Profile_Username
	);
	if found
		return row.username;
	return "";
}

get_terrain_info :: (platform: *Platform, db: DB_query.Handle, terrain_id: int) -> DB_Terrain_Infos {
	row, found := sql_load(
		platform,
		db,
		sql("SELECT * FROM terrain_infos WHERE id = ? LIMIT 1", terrain_id),
		DB_Terrain_Infos
	);
	if found
		return row;
	return .{};
}
