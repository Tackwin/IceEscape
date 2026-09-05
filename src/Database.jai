#import "Platform";
#import "Basic";
#import "String";

#scope_export

DB_Profile_Id :: struct {
	id: int; @table("profile_ids")
} @table("profile_ids");

DB_Profile_Stats :: struct {
	id: int; @table("profile_stats")
	win_count: int;
	death_count: int;
	revive_count: int;
} @table("profile_stats");

DB_Profile_Passcode :: struct {
	id: int; @table("profile_passcodes")
	passcode: u64;
} @table("profile_passcodes");

DB_Profile_Username :: struct {
	id: int; @table("profile_usernames")
	username: string;
} @table("profile_usernames");

DB_Profile_Token :: struct {
	id: int; @table("profile_tokens")
	token: u64;
} @table("profile_tokens");

DB_Time_Entry :: struct {
	id: int; @table("time_entries")
	profile_id: int;
	terrain_id: int;
	time_ms: int;
	timestamp_ms: int;
} @table("time_entries");

DB_Terrain_Id :: struct {
	id: int; @table("terrain_ids")
} @table("terrain_ids");

DB_Terrain_Infos :: struct {
	id: int; @table("terrain_infos")
	name: string;
	author_profile_id: int;
	created_ms: int;
} @table("terrain_infos");

DB_Terrain_Ascii :: struct {
	ascii_id: int; @table("terrain_asciis")
	id: int;
	ascii: string;
	created_ms: int;
} @table("terrain_asciis");

DB_Terrain_Thumbnail :: struct {
	ascii_id: int; @table("terrain_thumbnails")
	thumbnail: [] u8;
} @table("terrain_thumbnails");

DB_Terrain_Roster :: struct {
	id: int; @table("terrain_rosters")
	name: string;
	terrain_ids: [] int; @json_array
} @table("terrain_rosters");

DB_Terrain_Bomberman_Entry :: struct {
	id: int; @table("terrain_bomberman_entry")
	terrain_id: int;
	max_players: int;
} @table("terrain_bomberman_entry");

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
	for info.members {
		column := to_lower_copy(it.name,, temp);
		print_to_builder(*sb, "\t% %", column, db_sql_type(it));
		if it_index == 0 {
			print_to_builder(*sb, " PRIMARY KEY");
		} else {
			json_array := false;
			for note: it.notes {
				if note == "json_array"
					json_array = true;
			}
			if json_array {
				print_to_builder(
					*sb,
					" CHECK (json_valid(%1) AND json_type(%1) = 'array')",
					column
				);
			}
		}
		if it_index + 1 < info.members.count {
			print_to_builder(*sb, ",\n");
		} else {
			print_to_builder(*sb, "\n");
		}
	}
	print_to_builder(*sb, ");");

	exec_database(platform, db, builder_to_string(*sb));

	existing := load_database_custom(
		platform, db, DB_Pragma_Table_Info, tprint("PRAGMA table_info(%);", table)
	);
	for info.members {
		column := to_lower_copy(it.name,, temp);
		found := false;
		for row: existing {
			if row.name == column {
				found = true;
				break;
			}
		}
		if !found {
			exec_database(
				platform,
				db,
				tprint("ALTER TABLE % ADD COLUMN % %;", table, column, db_sql_type(it))
			);
		}
	}

	exec_database(platform, db, tprint("SELECT 1 FROM % LIMIT 0;", table));
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
	query := tprint(
		"SELECT * FROM time_entries WHERE terrain_id = %1 ORDER BY time_ms ASC LIMIT 1", terrain_id
	);
	time_entries := load_database_custom(platform, db, DB_Time_Entry, query);
	if time_entries.count > 0 {
		return time_entries[0];
	} else {
		return .{};
	}
}

get_profile_name :: (platform: *Platform, db: DB_query.Handle, profile_id: int) -> string {
	query := tprint("SELECT username FROM profile_usernames WHERE id = %1 LIMIT 1", profile_id);
	profile_usernames := load_database_custom(platform, db, struct {
		username: string;
	}, query);
	if profile_usernames.count > 0 {
		return profile_usernames[0].username;
	} else {
		return "";
	}
}

get_terrain_info :: (platform: *Platform, db: DB_query.Handle, terrain_id: int) -> DB_Terrain_Infos {
	query := tprint("SELECT * FROM terrain_infos WHERE id = %1 LIMIT 1", terrain_id);
	terrain_infos := load_database_custom(platform, db, DB_Terrain_Infos, query);
	if terrain_infos.count > 0 {
		return terrain_infos[0];
	} else {
		return .{};
	}
}
