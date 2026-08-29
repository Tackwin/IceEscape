#import "Platform";
#import "Basic";

#scope_export

DB_Profile_Id :: struct {
	id: int;
}

DB_Profile_Stats :: struct {
	id: int;
	win_count: int;
	death_count: int;
	revive_count: int;
}

DB_Profile_Passcode :: struct {
	id: int;
	passcode: u64;
}

DB_Profile_Username :: struct {
	id: int;
	username: string;
}

DB_Profile_Token :: struct {
	id: int;
	token: u64;
}

DB_Time_Entry :: struct {
	id: int;
	profile_id: int;
	terrain_id: int;
	time_ms: int;
	timestamp_ms: int;
}

DB_Terrain_Id :: struct {
	id: int;
}

DB_Terrain_Infos :: struct {
	id: int;
	name: string;
	author_profile_id: int;
	created_ms: int;
}

DB_Terrain_Ascii :: struct {
	ascii_id: int;
	id: int;
	ascii: string;
	created_ms: int;
}

DB_Terrain_Thumbnail :: struct {
	ascii_id: int;
	thumbnail: [] u8;
}

DB_Terrain_Roster :: struct {
	id: int;
	name: string;
	terrain_ids: [] int; @json_array
}

DB_Terrain_Bomberman_Entry :: struct {
	id: int;
	terrain_id: int;
	max_players: int;
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

