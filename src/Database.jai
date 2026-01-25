DB_Profile_Id :: struct {
	id: int;
}

DB_Profile_Status :: struct {
	id: int;
	win_count: int;
	death_count: int;
	revive_count: int;
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