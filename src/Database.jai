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

DB_Time_Entry :: struct {
	id: int;
	profile_id: int;
	terrain_id: int;
	time_ms: int;
	timestamp: float64;
}

DB_Terrain_Id :: struct {
	id: int;
}

DB_Terrain_Infos :: struct {
	id: int;
	name: string;
	author_profile_id: int;
}

DB_Terrain_Ascii :: struct {
	id: int;
	ascii: string;
}