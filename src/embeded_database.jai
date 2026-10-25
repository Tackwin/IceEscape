#import "String";
#import "Hash";
#import "Terrain";

embed_database_default_terrain_bomberman_entry :: (app: *App) {
	app_user := app.user_data.(*App_User);
	sql_store(
		app.platform,
		app_user.server.db,
		DB_Terrain_Bomberman_Entry.{
			id = 1,
			terrain_id = 107,
			max_players = 64,
		}
	);
}

embed_database_default_rosters :: (app: *App) {
	app_user := app.user_data.(*App_User);

	sql_store(
		app.platform,
		app_user.server.db,
		DB_Terrain_Roster.{
			id = 1,
			name = "Base",
			terrain_ids = .[100, 101, 102, 103, 104, 105, 106],
		}
	);

	roster: [] string = .[
		"Welcome",
		"Good Intro",
		"Good Ice",
		"Good Too",
		"Good Night",
		"Good Three",
		"Good Pounding",
		"Good Light",
		"Good Bomb",
		"Good Steady",
		"Good Turn",
		"Big Round",
		"Roundabout",
		"Funny",
		"Chamber",
		"Buzzzzz",
		"Right Angle",
		"Frogger",
		"Don't give up",
		"Volcano",
		"Tetris"
	];

	ids: [..] int;
	ids.allocator = temp;
	for roster {
		info, found := sql_load(
			app.platform,
			app_user.server.db,
			sql("SELECT * FROM terrain_infos WHERE name = ? AND COALESCE(deleted, 0) = 0", it),
			DB_Terrain_Infos
		);
		if !found
			continue;
		array_add(*ids, info.id);
	}
	sql_store(
		app.platform,
		app_user.server.db,
		DB_Terrain_Roster.{
			id = 2,
			name = "File",
			terrain_ids = ids,
		}
	);
}

embed_database_default_terrains :: (app: *App) {
	app_user := app.user_data.(*App_User);
	server := *app_user.server;
	platform := app.platform;
	save :: (new_id: int, ascii: string, name: string) #expand {
		sql_store(platform, server.db, DB_Terrain_Id.{ id = new_id });

		sql_store(
			platform,
			server.db,
			DB_Terrain_Infos.{
				id = new_id,
				author_profile_id = -1,
				name = parse_terrain_name(ascii),
				created_ms = 0,
			}
		);

		sql_store(
			platform,
			server.db,
			DB_Terrain_Ascii.{
				id = new_id,
				ascii_id = new_id,
				ascii = ascii,
				created_ms = 0,
			}
		);
	}

	sql_store(
		app.platform,
		app_user.server.db,
		DB_Terrain_Roster.{
			id = 200,
			name = "Season 2",
			terrain_ids = .[100, 201, 202, 203, 204, 205, 206, 207, 208, 209],
		}
	);

	terrains := platform.list_files("../assets/terrain", false);
	save(100, PIKC_TERRAIN, "Built Pick");
	save(101, BIG_SHIP, "Built Big Ship");
	save(102, BIG_INTRO, "Built Big Intro");
	save(103, BIG_TURN, "Built Big Turn");
	save(104, BIG_BOMBS, "Built Big Bombs");
	save(105, BIG_POUNDING, "Built Big Pounding");
	save(106, BIG_ROUND, "Built Big Round");
	save(107, BOMBERMAN_NORMAL, "Built Bomberman Normal");

	save(201, S2E1, "S2E1");
	save(202, S2E2, "S2E2");
	save(203, S2E3, "S2E3");
	save(204, S2E4, "S2E4");
	save(205, S2E5, "S2E5");
	save(206, S2E6, "S2E6");
	save(207, S2E7, "S2E7");
	save(208, S2E8, "S2E8");
	save(209, S2E9, "S2E9");
	for terrains {
		if !ends_with(it, ".terrain")
			continue;

		name: string;
		name.data = it.data + find_index_from_right(it, #char "/") + 1;
		name.count = it.count - xx (name.data - it.data);
		name.count = find_index_from_right(name, #char ".");

		length := platform.read_entire_file(it, .[]);
		data := NewArray(length, u8,, temp);
		success := platform.read_entire_file(it, data);
		if success {
			ascii: string;
			ascii.data = data.data;
			ascii.count = data.count;

			id := fnv1a_hash(name.data, name.count, 2356);
			id &= 0x7FFFFFFFFFFFFFFF; // Ensure positive.

			save(cast,no_check(s64) ((id / 100000) * 100000), ascii, name);
		}
	}
}

PIKC_TERRAIN :: #string PICK
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXIGIIGIGIIGIXXXXXXXXXXXXXXXXX
XXXXXXXXXXGGIGIIGIGIIGIGGXXXXXXXXXXXXXXX
XXXXXXXXXIIIIIIIIIIIIIIIIIXXXXXXXXXXXXXX
XXXXXXXXGGIIRIIIIIIIIIRIIGGXXXXXXXXXXXXX
XXXXXXXXIIIIRIIiiiiiIIRIIIIXXXXXXXXXXXXX
XXXXXXXXGGIIRIIiiiiiIIRIIGGXXXXXXXXXXXXX
XXXXXXXXIIIIRIIIIIIIIIRIIIIXXXXXXXXXXXXX
XXXXXXXXXIGIIIIIXGXIIIIIGIXXXXXXXXXXXXXX
XXXXXXXXXIGIGIGIXGXIGIGIGIXXXXXXXXXXXXXX
XXXXXXXXXXXXGIGIXGXIGIGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXSXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

- autorevive
- name: Welcome

frame
- position: 9.25 5.0
- size: 4.5 5.75
- origin: 6 4

standin
- model_id: 1
- position: 10.5 10.5 0.0
- orientation_dir: 0 -1 0

trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 10.5 10.5 0.0
- radius: 1.0
- model_id: 1

standin
- model_id: 2
- position: 7.5 10.5 0.0
- orientation_dir: 0 -1 0

trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 7.5 10.5 0.0
- radius: 1.0
- model_id: 2

trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 8.5 12.5 0.0
- radius: 1.0
- model_id: 2

standin
- model_id: 3
- position: 15.5 10.5 0.0
- orientation_dir: 0 -1 0

trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 15.5 10.5 0.0
- radius: 1.0
- model_id: 3

trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 15.5 12.5 0.0
- radius: 1.0
- model_id: 3


standin
- model_id: 4
- position: 20.5 7.5 0.0
- orientation_dir: -1 -1 0

trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 20.5 7.5 0.0
- radius: 1.0
- model_id: 4


standin
- model_id: 5
- position: 2.5 7.5 0.0
- orientation_dir: 1 0 0

trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 2.5 7.5 0.0
- radius: 1.0
- model_id: 5


standin
- model_id: 7
- position: 2.5 5.5 0.0
- orientation_dir: 1 0 0

trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 2.5 5.5 0.0
- radius: 1.0
- model_id: 7


standin
- model_id: 8
- position: 4.5 2.5 0.0
- orientation_dir: 0 1 0

trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 4.5 2.5 0.0
- radius: 1.0
- model_id: 8

standin
- model_id: 9
- position: 8.5 1.5 0.0
- orientation_dir: 0 1 0


trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 8.5 1.5 0.0
- radius: 1.0
- model_id: 9

standin
- model_id: 10
- position: 14.5 1.5 0.0
- orientation_dir: 0 1 0


trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 14.5 1.5 0.0
- radius: 1.0
- model_id: 10

standin
- model_id: 11
- position: 18.5 2.5 0.0
- orientation_dir: 0 1 0

trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 18.5 2.5 0.0
- radius: 1.0
- model_id: 11

standin
- model_id: 12
- position: 20.5 5.5 0.0
- orientation_dir: -1 1.0 0

trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 20.5 5.5 0.0
- radius: 1.0
- model_id: 12

standin
- model_id: 23
- position: 5.5 9.5 0.0
- orientation_dir: +1 -1 0

trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 5.5 9.5 0.0
- radius: 1.0
- model_id: 23


trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 4.5 13.5 0.0
- radius: 1.0
- model_id: 23

standin
- model_id: 24
- position: 17.5 9.5 0.0
- orientation_dir: -0.49 -0.99 0

trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 17.5 9.5 0.0
- radius: 1.0
- model_id: 24

standin
- model_id: 25
- position: 16.5 1.5 0.0
- orientation_dir: -0.0 +0.99 0

trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 16.5 1.5 0.0
- radius: 1.0
- model_id: 25

standin
- model_id: 26
- position: 6.5 1.5 0.0
- orientation_dir: -0.00 +0.99 0

trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 6.5 1.5 0.0
- radius: 1.0
- model_id: 26


standin
- model_id: 27
- position: 12.5 10.5 0.0
- orientation_dir: -0.0 -0.99 0

trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 12.5 10.5 0.0
- radius: 1.0
- model_id: 27

trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 18.5 13.5 0.0
- radius: 1.0
- model_id: 24

trophy
- position: 11.5 13.5 0.0

trap
- position: 11.5 7.5 0.0
- radius_hitbox: 0.5
PICK;

BIG_SHIP :: #string BIG_SHIP
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXIIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXIIIIIXIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXIIIIIXIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXIIIIIXIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXIIIIXIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXGGGGXXIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXGGGGXXGGiXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXGGGGXXGGiIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXGGiIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXIIIIIXXXXXXXIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXIIIIIIIIIIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXiiiiiiiiiiiiiiiiiXXXXXXIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXiiiiiiiiiiiiiiiiiXXXGGGGIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXIIIIIIIIIIIIIIIIIXXXXGGGGIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXGGGGXXXXXXIIIIIXXXXXXGGGGIIXIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXGGGGXXXXXXXXXXXXXXXXXGGGGIIXIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXIIIIIIIIIIIIIIIIIIIIIIIIIXXIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXIIIIIIIIIIIIIIIIIIIIIIIXXIIIIIIIIIIGGXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXIIIIIIIIIIIIIIIIIIIIIXXXIIIIIIIIIIGGXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXIIIIIIIIIIIIIIIIIIIXXXXIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXGGGGGGIIIIXIIIIIIIIIIIIIXIIGGGGGGXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXGGGGGGIIIIIIIIIIIIIIIIIIIIIGGGGGGXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXGGSGGGIIIIIIIIIIIIIIIIIIIIIGGGGGGXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXGGGGGGIIIIIIIIIIIIIIIIIIIIIGGGGGGXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXGGGGGGIIIIXIIIIIIIIIIIIIXIIGGGGGGXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

- name: Big Ship

frame
- origin: 7.0 3.0
- size: 45.0 28.0

trophy
- position: 17 23.5 0

flag
- position: 27 17 0
flag
- position: 22.5 22.5 0

path
- checkpoint: 16 5 0.0
- checkpoint: 16 8 0.0

skull
- path_id: 0
- speed: 1

path
- checkpoint: 26 4 0.0
- checkpoint: 26 9 0.0
- checkpoint: 22 6.5 0.0
- checkpoint: 26 4 0.0

skull
- path_id: 1
- speed: 2

skull
- path_id: 1
- speed: 2
- offset: 0.5

path
- checkpoint: 31.5 14.5 0.0
- checkpoint: 36.5 14.5 0.0
- checkpoint: 36.5 18.51 0.0
- checkpoint: 31.5 18.5 0.0
- checkpoint: 31.5 14.5 0.0

skull
- path_id: 2
- speed: 2

skull
- path_id: 2
- speed: 2
- offset: 0.25

skull
- path_id: 2
- speed: 2
- offset: 0.5

skull
- path_id: 2
- speed: 2
- offset: 0.75

path
- checkpoint: 7.5 10.5 0.0
- checkpoint: 10.5 13.5 0.0
- checkpoint: 13.5 10.5 0.0
- checkpoint: 16.5 13.5 0.0
- checkpoint: 19.5 10.5 0.0
- checkpoint: 22.5 13.5 0.0
- checkpoint: 25.5 10.5 0.0
- checkpoint: 28.5 13.5 0.0

skull
- path_id: 3
- speed: 2.0
- offset: 0.0
skull
- path_id: 3
- speed: 2.0
- offset: 0.02
skull
- path_id: 3
- speed: 2.0
- offset: 0.2
skull
- path_id: 3
- speed: 2.0
- offset: 0.22
skull
- path_id: 3
- speed: 2.0
- offset: 0.4
skull
- path_id: 3
- speed: 2.0
- offset: 0.42
skull
- path_id: 3
- speed: 2.0
- offset: 0.6
skull
- path_id: 3
- speed: 2.0
- offset: 0.62
skull
- path_id: 3
- speed: 2.0
- offset: 0.8
skull
- path_id: 3
- speed: 2.0
- offset: 0.82

path
- checkpoint: 21 16.5 0
- checkpoint: 5 16.51 0

path
- checkpoint: 24 19.5 0
- checkpoint: 8 19.51 0

skull
- path_id: 4
- speed: 2.5
- offset: 0.0
skull
- path_id: 4
- speed: 2.5
- offset: 0.5

skull
- path_id: 5
- speed: 2.5
- offset: 0.5
skull
- path_id: 5
- speed: 2.5
- offset: 0

path
- checkpoint: 24.5 33 0
- checkpoint: 24.5 24 0
- checkpoint: 24.5 33 0

path
- checkpoint: 20 28.5 0
- checkpoint: 29 28.51 0
- checkpoint: 20 28.5 0

skull
- path_id: 6
- speed: 1.5
- offset: 0.5
skull
- path_id: 6
- speed: 1.5
- offset: 0
skull
- path_id: 6
- speed: 1.5
- offset: 0.25
skull
- path_id: 6
- speed: 1.5
- offset: 0.75


skull
- path_id: 7
- speed: 1.5
- offset: 0.5
skull
- path_id: 7
- speed: 1.5
- offset: 0
skull
- path_id: 7
- speed: 1.5
- offset: 0.25
skull
- path_id: 7
- speed: 1.5
- offset: 0.75


jukebox
- position: 42 12 0
BIG_SHIP;

BIG_INTRO :: #string BIG_INTRO
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXGXXXXXXXXXXXXXXXXXXXXXXXXXXXGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXGGGXIiiiiXIIIIIIIIXXIIIIIIiiiiXIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXGXIIiiiiIIIIIIIIIXXIIIIIIiiiiXIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXIIIiiiiIIIIXXIIIIIIIIIXXiiiiIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXIIIIiiiiIIIIXXIIIIIIIIIXXiiiiIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXiiiiXXXXXXXXXXXXXXGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXiiiiXXXXXXXXXXXXXGGGXXXIIIGGGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXiiiiXXXXIIIXIIIIXGGGXIIIIIGGGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXiiiiXXXIIIIIIIIIIXGXIIIIIIGGGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXGGGGXXXIIIIIIIIIIXXXIIIIIIGGGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXGGGGIIXIIIIXIIIIIIXIIIIIIIGGGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXGGGGIIIIIIIXXIIIIIIIIIIIIXiiiiiiXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXGGGGIIIIIIIXXXIIIIIIIIIXXXiiiiiiIIIIGGXXXXXXXXXXX
XXXXXXXXXXXXXXXXIIIIIIXXXXXXIIIIIXXXXXiiiiiiIIIIGGXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXiiiiiiXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXIIIIIIIIIIIIIIIIIIIIIiiiiiiXXXXXXXXXXXXXXXXX
XXXXXXXXXXXGGGGGGIIIIIIIIIIIIIIIIIIXIIGGGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXGGGGGGIIIIIIIIIIIIIIIIIIIIIGGGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXGGSGGGIIIIIIIIIIIIIIIXIIIIIGGGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXGGGGGGIIIIIIIIIIIIIIIIIIIIIGGGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXGGGGGGIIIIIIIIIIIIIIIIIIXIIGGGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXIIIIIIIIIIIIIIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIXXXXXXXXXXXXXXXXXXXXX

- name: Big Intro

frame
- origin: 7.0 3.0
- size: 35.0 26.0

trophy
- position: 5.5 22.5 0

flag
- position: 35 17 0

flag
- position: 36 27 0

trap
- position: 9 26.15 0
trap
- position: 9 26.85 0

trap
- position: 15 25.65 0
trap
- position: 15 27.35 0

jukebox
- position: 42 12 0

gate
- position: 5.5 24.5 0
- direction: 0 1 0
- wait_for_pressbutton_id: 1
- wait_for_pressbutton_id: 2

pressbutton
- position: 4.0 26.5 0

pressbutton
- position: 7.0 26.5 0
BIG_INTRO;

BIG_TURN :: #string BIG_TURN
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIIIXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIIIIXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXGGGIIIIIIIIIIIIIIIIIIIGGGiiiiiiiXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXGGGIIIIIIIIIIIIIIIIIIIGGGiiiiiiiXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXGGGIIIIIIIIIIIIIIIIIIIGGGiiiiiiiXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXIXXXXXXXXXXXXXXXXXXGGGXiiiiiiiIIIXXXXXXXXXXXXXX
XXXXXXXXXXXIIIIIIIIIXXXXXXGGGXXXXXXXXXXiiiiiiIIIXXXXXXXXXXXXXX
XXXXXXXXXXXiXXXiXXXiXXXXXXXGXXXXXXIIIIiiiiiiXXXXXXXXXXXXXXXXXX
XXXXXXXXXXiiiiiiiiiiiiXXXGGGGGXXXXIIIIiiiiiiXXXXXXXXXXXXXXXXXX
XXXXXXXXXXiiiiiiiiiiiiXXXXXiXXXXXXIIIIiiiiiiXXXXXXXXXXXXXXXXXX
XXXXXXXXXXiiiiiiiiiiiXGXXXiiiXXXGXXXXXiiiiiiiiIIXXXXXXXXXXXXXX
XXXXXXXXXXiiiiiiiiiiiXGGIiiiiiIGGXXXXXXiiiiiiiIIXXXXXXXXXXXXXX
XXXXXXXXXXiiiiiiiiiiiXGXXXiiiXXXGXIIIIiiiiiiiiXXXXXXXXXXXXXXXX
XXXXXXXXXXiiiiiiiiiiiXXXXXIiIXXXXXIIIIiiiiiiXXXXXXXXXXXXXXXXXX
XXXXXXXXXXiiiiiiiiiiiXXXXXIIIXXXXXIIIIiiiiiiXXXXXXXXXXXXXXXXXX
XXXXXXXXXXiiiiiiiiiiiXXXXXIIIXXXXXXXXXiiiiiiXXXXXXXXXXXXXXXXXX
XXXXXXXXXXiiiiiiiiiiiXXXXXIIIXXXXXXXXXXiiiiiiiIIXXXXXXXXXXXXXX
XXXXXXXXXXiiiiiiiiiiiXXXXXGGGXXXXXIIIiiiiiiiiiIIXXXXXXXXXXXXXX
XXXXXXXXXXiiiiiiiiiiiXXXXiGGGXXXXXIIIiiiiiiiiiIIXXXXXXXXXXXXXX
XXXXXXXXXXIIIXIIIXIIIXXXiiGGGXXXXXIIIiiiiiiiXXXXXXXXXXXXXXXXXX
XXXXXXXXXXIIIXIIIXIIIXXiiXXXXXXXXXXXXXiiiiiiXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXIXXXIXXXIXXiiXXXXXXXXXXXXXXXiiiiiXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXIXXXXXXXXXiiXXXXXXXXXXXXXXXXXXiiiiiIIXXXXXXXXXXXXXX
XXXXXXXXXXXIIIIIIIIIIIXIIIXXIIIXXIIIXXXXXiiiiiIIXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXIIIXXIIIXXIIIXXGGGiiiXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXGGGXXIIIXXIIIXXIIIXXGGGiiiXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXGSGIIIIIIIIIIIIIIIIIGGGiiiXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXGGGXXXXXXIIXXXIIXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIXXXXXXXXXXXXXXXXX

- name: Big Turn

frame
- origin: 7.0 3.0
- size: 35.0 28.0

trophy
- position: 20.5 24.5 0

flag
- position: 29 27 0
flag
- position: 21 12 0

present
- position: 27.5 25.5 0.0

present
- position: 29.5 25.5 0.0
- kind: B

present
- position: 18.5 22.5 0.0

present
- position: 22.5 22.5 0.0
- kind: B

turn_table
- position: 20 4.5 0
- turning_period: 5
- turning_offset: 0.7
turn_table
- position: 25 4.5 0
- turning_period: 5
- turning_offset: 0.45
turn_table
- position: 30 4.5 0
- turning_period: 5
- turning_offset: 0.2
trap
- position: 17.5 4.2 0
trap
- position: 22.5 4.2 0
trap
- position: 27.5 4.2 0


turn_table
- position: 36 8.5 0
- turning_period: 5
turn_table
- position: 36 14.5 0
- turning_period: 5
turn_table
- position: 36 20.5 0
- turning_period: 5
turn_table
- position: 36 25.5 0
- turning_period: 5

trap
- position: 24 28.5 0
trap
- position: 24 26.5 0
turn_table
- position: 24 27.5 0
- turning_period: 5

trap
- position: 12 28.5 0
trap
- position: 12 26.5 0
turn_table
- position: 12.5 27.5 0
- turning_period: 5

trap
- position: 18 27.5 0
turn_table
- position: 18.25 26.5 0
- turning_period: 5
turn_table
- position: 18.25 28.5 0
- turning_period: 5

turn_table
- position: 20.5 19.5 0
- turning_period: 5

// maze
turn_table
- position: 4.5 23.5 0
- turning_speed: 0
- turning_offset: 0.75
turn_table
- position: 8.5 23.5 0
- turning_speed: 0
- turning_offset: 0.75
turn_table
- position: 12.5 23.5 0
- turning_speed: 0
- turning_offset: 0.75
turn_table
- position: 10 22.5 0
- turning_speed: 0
- turning_offset: 0.88
turn_table
- position: 13.5 19.5 0
- turning_speed: 0
- turning_offset: 0.25
turn_table
- position: 13.5 20.5 0
- turning_speed: 0
- turning_offset: 0.38
turn_table
- position: 11.7 22.3 0
- turning_speed: 0
- turning_offset: 0.00
turn_table
- position: 13.75 22.5 0
- turning_speed: 0
- turning_offset: 0.63
turn_table
- position: 5.5 21.5 0
- turning_speed: 0
- turning_offset: 0.75
turn_table
- position: 4.5 19.5 0
- turning_speed: 0
- turning_offset: 0.00
turn_table
- position: 5.5 16.5 0
- turning_speed: 0
- turning_offset: 0.00
turn_table
- position: 5.75 14 0
- turning_speed: 0
- turning_offset: 0.00
turn_table
- position: 4.5 15.5 0
- turning_speed: 0
- turning_offset: 0.75
turn_table
- position: 6.5 12.5 0
- turning_speed: 0
- turning_offset: 0.00
turn_table
- position: 7 13.5 0
- turning_speed: 0
- turning_offset: 0.87
turn_table
- position: 7.5 14.5 0
- turning_speed: 0
- turning_offset: 0.25
turn_table
- position: 6.5 20.5 0
- turning_speed: 0
- turning_offset: 0.75
turn_table
- position: 7.5 17.5 0
- turning_speed: 0
- turning_offset: 0.00
turn_table
- position: 3.5 18.5 0
- turning_speed: 0
- turning_offset: 0.25
turn_table
- position: 3.5 22.5 0
- turning_speed: 0
- turning_offset: 0.00
turn_table
- position: 8.5 21.5 0
- turning_speed: 0
- turning_offset: 0.50
turn_table
- position: 9.5 20.5 0
- turning_speed: 0
- turning_offset: 0.50
turn_table
- position: 10.5 19.5 0
- turning_speed: 0
- turning_offset: 0.75
turn_table
- position: 9.5 13.5 0
- turning_speed: 0
- turning_offset: 0.25
turn_table
- position: 10.5 14.5 0
- turning_speed: 0
- turning_offset: 0.50
turn_table
- position: 12.5 12.5 0
- turning_speed: 0
- turning_offset: 0.75
turn_table
- position: 13.5 13.5 0
- turning_speed: 0
- turning_offset: 0.50
turn_table
- position: 12.5 15.5 0
- turning_speed: 0
- turning_offset: 0.50
turn_table
- position: 13.5 16.5 0
- turning_speed: 0
- turning_offset: 0.75
turn_table
- position: 12.5 17.5 0
- turning_speed: 0
- turning_offset: 0.75
turn_table
- position: 12.5 18.5 0
- turning_speed: 0
- turning_offset: 0.50
turn_table
- position: 4.5 16.5 0
- turning_speed: 0
- turning_offset: 0.13

key
- position: 15.5 19.5 0

key
- position: 25.5 19.5 0

gate
- position: 20.5 23 0
- direction: 0 -1 0
- wait_for_key_id: 1

gate
- position: 20.5 24 0
- direction: 0 -1 0
- wait_for_key_id: 2


camera_rail
- waypoint: 11.5 4.5 0
- waypoint: 35.5 4.5 0
- waypoint: 35.5 27.5 0

BIG_TURN;

BIG_BOMBS :: #string BIG_BOMBS
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXIIIIIIIXXXXXXXXXXXXIIIIIIIXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXIIIIIIIXXXXXXXXXXXXIIIIIIIXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXGGGIIIIIIIIIIIiiiiiiiiIIIIIIIIIIIGGGXGGGXXXXXXXXXXXX
XXXXXXXXXXXXGGGIIIIIXIIIIIiiiiiiiiIIIIIXIIIIIGGGGGGGXXXXXXXXXXXX
XXXXXXXXXXXXGGGIIIIIIIIIIIiiiiiiiiIIIIIIIIIIIGGGXGGGXXXXXXXXXXXX
XXXXXXXXXXXXXGXXXIIIIIIIXXXXXXXXXXXXIIIIIIIXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXGXXXIIIIIIIXXXXXXXXXXXXIIIIIIIXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXGGGIIIXXIIIIIIIIXXIIIIIIIIXXIIIIIIIIXXXXXXXXXXXXXXXX
XXXXXXXXXXXXGGGIIIXXIIIIIIIIXXIIIIIIIIXXIIIIIIIIXXXXXXXXXXXXXXXX
XXXXXXXXXXXXGGGIIIXXIIIIIIIIXXIIIIIIIIXXIIIIIIIIXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXIIIXXIIIXXIIIXXIIIXXIIIXXIIIXXGGGXXXXXXXXXXXXXXXX
XXXXXXXXXXXXGXXIIIIIIIIXXIIIIIIIIXXIIIIIIIIXXGGGXXXXXXXXXXXXXXXX
XXXXXXXXXXXXGXXIIIIIIIIXXIIIIIIIIXXIIIIIIIIXXGGGXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXIIIIIIIIXXIIIIIIIIXXIIIIIIIIXXXGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXGGGXIIIIIIIIIIIIIIIIIIIIIIIIIIIIXGGGXXXXXXXXXXXXXXXX
XXXXXXXXXXXXGSGIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIGGGXXXXXXXXXXXXXXXX
XXXXXXXXXXXXGGGXIIIIIIIIIIIIIIIIIIIIIIIIIIIIXGGGXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

- name: Big Bomb

frame
- origin: 7.0 3.0
- size: 37.0 20.0

jukebox
- position: 5.5 9 0

robot
- position: 14 1 0
- start_target_aabb: 8.5 3
- size_target_aabb: 15 3
- shooting_cd: 1.5
- max_rotation_speed: 2.0
- predict: 1.0
- max_rotation_speed: 0.5
- charging_time: 0.2
- shooting_time: 0.3
- effectshoot_time: 0.2

robot
- position: 20 1 0
- start_target_aabb: 11.5 3
- size_target_aabb: 17 3
- shooting_cd: 1.5
- max_rotation_speed: 2.0
- predict: 1.0
- max_rotation_speed: 0.5
- charging_time: 0.2
- shooting_time: 0.3
- effectshoot_time: 0.2


robot
- position: 26 1 0
- start_target_aabb: 17.5 3
- size_target_aabb: 17 3
- shooting_cd: 1.5
- max_rotation_speed: 2.0
- predict: 1.0
- max_rotation_speed: 0.5
- charging_time: 0.2
- shooting_time: 0.3
- effectshoot_time: 0.2
robot
- position: 32 1 0
- start_target_aabb: 23.5 3
- size_target_aabb: 14 3
- shooting_cd: 1.5
- max_rotation_speed: 2.0
- predict: 1.0
- max_rotation_speed: 0.5
- charging_time: 0.2
- shooting_time: 0.3
- effectshoot_time: 0.2


bomb_spawner
- position: 5.5 5.5 0


block_rock
- position: 39.5 7 0
block_rock
- position: 6.5 15 0

flag
- position: 5.5 18.5 0

path
- checkpoint: 35 13.5 0
- checkpoint: 13 13.51 0
path
- checkpoint: 35 12.0 0
- checkpoint: 13 12.01 0
path
- checkpoint: 35 10.5 0
- checkpoint: 13 10.51 0
path
- checkpoint: 35 9.0 0
- checkpoint: 13 9.01 0
path
- checkpoint: 35 7.5 0
- checkpoint: 13 7.51 0

skull
- path_id: 0
- speed: 1.5
skull
- path_id: 1
- speed: 1.5
skull
- path_id: 2
- speed: 1.5
skull
- path_id: 3
- speed: 1.5
skull
- path_id: 4
- speed: 1.5

skull
- path_id: 0
- speed: 1.5
- offset: 0.5
skull
- path_id: 1
- speed: 1.5
- offset: 0.5
skull
- path_id: 2
- speed: 1.5
- offset: 0.5
skull
- path_id: 3
- speed: 1.5
- offset: 0.5
skull
- path_id: 4
- speed: 1.5
- offset: 0.5

robot
- position: 12 11 0
- start_target_aabb: 8.25 7.25
- size_target_aabb: 7.5 6.5
- shooting_cd: 1.25
- max_rotation_speed: 2.0
- predict: 0.5
- max_rotation_speed: 0.5
- charging_time: 0.2
- shooting_time: 0.3
- effectshoot_time: 0.2

robot
- position: 17 10 0
- start_target_aabb: 13.25 7.25
- size_target_aabb: 7.5 6.5
- shooting_cd: 1.5
- max_rotation_speed: 2.0
- predict: 0.5
- max_rotation_speed: 0.5
- charging_time: 0.2
- shooting_time: 0.3
- effectshoot_time: 0.2

robot
- position: 22 11 0
- start_target_aabb: 18.25 7.25
- size_target_aabb: 7.5 6.5
- shooting_cd: 1.5
- max_rotation_speed: 2.0
- predict: 0.5
- max_rotation_speed: 0.5
- charging_time: 0.2
- shooting_time: 0.3
- effectshoot_time: 0.2

robot
- position: 27 10 0
- start_target_aabb: 23.25 7.25
- size_target_aabb: 7.5 6.5
- shooting_cd: 1.5
- max_rotation_speed: 2.0
- predict: 0.5
- max_rotation_speed: 0.5
- charging_time: 0.2
- shooting_time: 0.3
- effectshoot_time: 0.2
robot
- position: 32 11 0
- start_target_aabb: 28.25 7.25
- size_target_aabb: 7.5 6.5
- shooting_cd: 1.5
- max_rotation_speed: 2.0
- predict: 0.5
- max_rotation_speed: 0.5
- charging_time: 0.2
- shooting_time: 0.3
- effectshoot_time: 0.2


bomb_spawner
- position: 5.5 17.5 0

path
- checkpoint: 10 15 0
- checkpoint: 17 15 0
- checkpoint: 17 22 0
- checkpoint: 10 22.01 0
- checkpoint: 10 15 0

skull
- path_id: 5
- speed: 1.5
skull
- path_id: 5
- speed: 1.5
- offset: 0.04
skull
- path_id: 5
- speed: 1.5
- offset: 0.08
skull
- path_id: 5
- speed: 1.5
- offset: 0.12
skull
- path_id: 5
- speed: 1.5
- offset: 0.16
skull
- path_id: 5
- speed: 1.5
- offset: 0.20
skull
- path_id: 5
- speed: 1.5
- offset: 0.24
skull
- path_id: 5
- speed: 1.5
- offset: 0.28
skull
- path_id: 5
- speed: 1.5
- offset: 0.32
skull
- path_id: 5
- speed: 1.5
- offset: 0.36
skull
- path_id: 5
- speed: 1.5
- offset: 0.40
skull
- path_id: 5
- speed: 1.5
- offset: 0.44
skull
- path_id: 5
- speed: 1.5
- offset: 0.48
skull
- path_id: 5
- speed: 1.5
- offset: 0.52
skull
- path_id: 5
- speed: 1.5
- offset: 0.56
skull
- path_id: 5
- speed: 1.5
- offset: 0.60
skull
- path_id: 5
- speed: 1.5
- offset: 0.64
skull
- path_id: 5
- speed: 1.5
- offset: 0.68
skull
- path_id: 5
- speed: 1.5
- offset: 0.72
skull
- path_id: 5
- speed: 1.5
- offset: 0.76
skull
- path_id: 5
- speed: 1.5
- offset: 0.80
skull
- path_id: 5
- speed: 1.5
- offset: 0.84
skull
- path_id: 5
- speed: 1.5
- offset: 0.88
skull
- path_id: 5
- speed: 1.5
- offset: 0.92


path
- checkpoint: 29 15 0
- checkpoint: 36 15 0
- checkpoint: 36 22 0
- checkpoint: 29 22.01 0
- checkpoint: 29 15 0

skull
- path_id: 6
- speed: 1.5
skull
- path_id: 6
- speed: 1.5
- offset: 0.04
skull
- path_id: 6
- speed: 1.5
- offset: 0.08
skull
- path_id: 6
- speed: 1.5
- offset: 0.12
skull
- path_id: 6
- speed: 1.5
- offset: 0.16
skull
- path_id: 6
- speed: 1.5
- offset: 0.20
skull
- path_id: 6
- speed: 1.5
- offset: 0.24
skull
- path_id: 6
- speed: 1.5
- offset: 0.32
skull
- path_id: 6
- speed: 1.5
- offset: 0.36
skull
- path_id: 6
- speed: 1.5
- offset: 0.40
skull
- path_id: 6
- speed: 1.5
- offset: 0.44
skull
- path_id: 6
- speed: 1.5
- offset: 0.48
skull
- path_id: 6
- speed: 1.5
- offset: 0.52
skull
- path_id: 6
- speed: 1.5
- offset: 0.56
skull
- path_id: 6
- speed: 1.5
- offset: 0.60
skull
- path_id: 6
- speed: 1.5
- offset: 0.64
skull
- path_id: 6
- speed: 1.5
- offset: 0.68
skull
- path_id: 6
- speed: 1.5
- offset: 0.72
skull
- path_id: 6
- speed: 1.5
- offset: 0.76
skull
- path_id: 6
- speed: 1.5
- offset: 0.80
skull
- path_id: 6
- speed: 1.5
- offset: 0.84
skull
- path_id: 6
- speed: 1.5
- offset: 0.88
skull
- path_id: 6
- speed: 1.5
- offset: 0.92
skull
- path_id: 6
- speed: 1.5
- offset: 0.96

robot
- position: 13.5 18.5 0
- start_target_aabb: 10 15
- size_target_aabb: 7 7
- shooting_cd: 1.5
- max_rotation_speed: 2.0
- predict: 0.5
- max_rotation_speed: 0.5
- charging_time: 0.2
- shooting_time: 0.3
- effectshoot_time: 0.2

robot
- position: 13.5 18.5 0
- start_target_aabb: 10 15
- size_target_aabb: 7 7
- shooting_cd: 1.4
- max_rotation_speed: 2.0
- predict: 0.5
- max_rotation_speed: 0.5
- charging_time: 0.2
- shooting_time: 0.3
- effectshoot_time: 0.2

robot
- position: 32.5 18.5 0
- start_target_aabb: 29 15
- size_target_aabb: 7 7
- shooting_cd: 1.5
- max_rotation_speed: 2.0
- predict: 0.5
- max_rotation_speed: 0.5
- charging_time: 0.2
- shooting_time: 0.3
- effectshoot_time: 0.2

robot
- position: 32.5 18.5 0
- start_target_aabb: 29 15
- size_target_aabb: 7 7
- shooting_cd: 1.4
- max_rotation_speed: 2.0
- predict: 0.5
- max_rotation_speed: 0.5
- charging_time: 0.2
- shooting_time: 0.3
- effectshoot_time: 0.2

trophy
- position: 43.5 18.5 0

block_rock
- position: 41.5 18.5 0
BIG_BOMBS;

BIG_POUNDING :: #string BIG_POUNDING
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXIXXXIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXIIXIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGiiGXIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXIXXXXXIIIIIIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXGIIIGIIIGIIIXGGGIIIIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXGIIIGIIIGIIIIGGGXXXXXXXXIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXGIIIGIIIGIIIXGGGXXXXXIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXiXXXXXXIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXIIIIIIIIIGIIIIIIIIIXXIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXIIIIIIIIIGIIIIIIIIIXXIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXIIIIIIIIIGIIIIIIIIIXXIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXIIIIIIIIIGIIIIIIIIIXXXXXIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXIIIIIIIIIGIIIIIIIIIXXIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXIIIIIIIIIGIIIIIIIIIXXIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXiXXXXXXXXXXXXXXXXIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXiXXXXXXXXXGGGXXXXIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXIIIIIIIIIIGGGXXXXIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXIIXXXXXXXXGGGXXXXXXXIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXIIIIIIIIIIIIIIIIIXXXXXIXXXXXXXGXXXGXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXIIIIIIIIIIIIIIIIIIIIIIIIXGGGIIIIXIGIXIGXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXIIIIIIIIIIIIIIIIIIIIIIIIIGGGIIXIXIXIXIXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXIIIIIIIIIIIIIIIIIIIIIIIIXGGGIIXIIIXIIIXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXIXXIIIIIIIIIIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXGXGGGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXGGGGGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXGXGGGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXIXXIIIIIIIIIIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXIIIIIIIIIIIIIIIIIIIIIIIXGGGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXIIIIIIIIIIIIIIIIIIIIIIIIGSGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXIIIIIIIIIIIIIIIIIIIIIIIXGGGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXIIIIIIIIIIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

- name: Pounding

trophy
- position: 23.0 20.5 0.0

frame
- origin: 7.0 3.0
- size: 38.0 28.0

present
- position: 1.5 10.5 0.0

present
- position: 1.5 8.5 0.0
- kind: B

present
- position: 37.5 16.5 0.0
- depends_on_flag_id: 1

present
- position: 41.5 16.5 0.0
- kind: B
- depends_on_flag_id: 1

present
- position: 13.5 34.5 0.0
- depends_on_flag_id: 2

present
- position: 10.5 34.5 0.0
- kind: B
- depends_on_flag_id: 2

flag
- position: 30.0 14.5 0.0
flag
- position: 22.5 31.5 0.0

trap
- position: 29.5 22 0.0
trap
- position: 29.5 23 0.0

trap
- position: 32.5 25 0.0
trap
- position: 32.5 26 0.0

trap
- position: 29.5 28 0.0
trap
- position: 29.5 29 0.0

trap
- position: 32.5 31 0.0
trap
- position: 32.5 32 0.0

trap
- position: 32.5 19 0.0
trap
- position: 32.5 20 0.0

path
- checkpoint: 28.5 17 0.0
- checkpoint: 28.5 34 0.0
- checkpoint: 30.5 34 0.0
- checkpoint: 30.5 17 0.0
- checkpoint: 28.5 17.01 0.0

skull
- path_id: 0
- speed: 3.5

skull
- path_id: 0
- speed: 3.5
- offset: 0.25

skull
- path_id: 0
- speed: 3.5
- offset: 0.50

skull
- path_id: 0
- speed: 3.5
- offset: 0.75


path
- checkpoint: 33.49 16.99 0.0
- checkpoint: 33.49 34 0.0
- checkpoint: 31.5 33.99 0.0
- checkpoint: 31.5 17 0.0
- checkpoint: 33.5 17.01 0.0

skull
- path_id: 1
- speed: 3.5
- offset: 0.125

skull
- path_id: 1
- speed: 3.5
- offset: 0.375

skull
- path_id: 1
- speed: 3.5
- offset: 0.625

skull
- path_id: 1
- speed: 3.5
- offset: 0.875

path
- checkpoint: 17.75 28.25 0.0
- checkpoint: 25.25 28.25 0.0
- checkpoint: 25.25 23.75 0.0
- checkpoint: 17.75 23.76 0.0
- checkpoint: 17.75 28.25 0.0

skull
- path_id: 2
- speed: 1.5
- offset: 0.0
skull
- path_id: 2
- speed: 1.5
- offset: 0.05
skull
- path_id: 2
- speed: 1.5
- offset: 0.1
skull
- path_id: 2
- speed: 1.5
- offset: 0.15
skull
- path_id: 2
- speed: 1.5
- offset: 0.2
skull
- path_id: 2
- speed: 1.5
- offset: 0.25
skull
- path_id: 2
- speed: 1.5
- offset: 0.30
skull
- path_id: 2
- speed: 1.5
- offset: 0.35
skull
- path_id: 2
- speed: 1.5
- offset: 0.4
skull
- path_id: 2
- speed: 1.5
- offset: 0.45
skull
- path_id: 2
- speed: 1.5
- offset: 0.5
skull
- path_id: 2
- speed: 1.5
- offset: 0.55
skull
- path_id: 2
- speed: 1.5
- offset: 0.6
skull
- path_id: 2
- speed: 1.5
- offset: 0.65
skull
- path_id: 2
- speed: 1.5
- offset: 0.7
skull
- path_id: 2
- speed: 1.5
- offset: 0.75
skull
- path_id: 2
- speed: 1.5
- offset: 0.8
skull
- path_id: 2
- speed: 1.5
- offset: 0.85
skull
- path_id: 2
- speed: 1.5
- offset: 0.9



path
- checkpoint: 7.76 28.24 0.0
- checkpoint: 7.74 23.76 0.0
- checkpoint: 15.25 23.75 0.0
- checkpoint: 15.25 28.25 0.0
- checkpoint: 7.75 28.26 0.0

skull
- path_id: 3
- speed: 1.5
- offset: 0.0
skull
- path_id: 3
- speed: 1.5
- offset: 0.05
skull
- path_id: 3
- speed: 1.5
- offset: 0.1
skull
- path_id: 3
- speed: 1.5
- offset: 0.15
skull
- path_id: 3
- speed: 1.5
- offset: 0.2
skull
- path_id: 3
- speed: 1.5
- offset: 0.25
skull
- path_id: 3
- speed: 1.5
- offset: 0.30
skull
- path_id: 3
- speed: 1.5
- offset: 0.35
skull
- path_id: 3
- speed: 1.5
- offset: 0.4
skull
- path_id: 3
- speed: 1.5
- offset: 0.45
skull
- path_id: 3
- speed: 1.5
- offset: 0.5
skull
- path_id: 3
- speed: 1.5
- offset: 0.55
skull
- path_id: 3
- speed: 1.5
- offset: 0.6
skull
- path_id: 3
- speed: 1.5
- offset: 0.7
skull
- path_id: 3
- speed: 1.5
- offset: 0.75
skull
- path_id: 3
- speed: 1.5
- offset: 0.8
skull
- path_id: 3
- speed: 1.5
- offset: 0.85
skull
- path_id: 3
- speed: 1.5
- offset: 0.9
skull
- path_id: 3
- speed: 1.5
- offset: 0.95



robot
- position: 7.75 22.5 0
- start_target_aabb: 8 24
- end_target_aabb: 15 28
- shooting_cd: 2.0

robot
- position: 9.00 22.5 0
- start_target_aabb: 8 24
- end_target_aabb: 15 28
- shooting_cd: 2.5

robot
- position: 10.25 22.5 0
- start_target_aabb: 8 24
- end_target_aabb: 15 28
- shooting_cd: 2.25

robot
- position: 12.75 22.5 0
- start_target_aabb: 8 24
- end_target_aabb: 15 28
- shooting_cd: 1.75

robot
- position: 14.00 22.5 0
- start_target_aabb: 8 24
- end_target_aabb: 15 28
- shooting_cd: 1.89

robot
- position: 15.25 22.5 0
- start_target_aabb: 8 24
- end_target_aabb: 15 28
- shooting_cd: 2.32


trap
- position: 14.0 20 0.0
trap
- position: 18.0 21 0.0

trap
- position: 15.5 4.5 0.0
trap
- position: 15.5 2.5 0.0
trap
- position: 15.5 6.5 0.0


trap
- position: 19.5 3.5 0.0
trap
- position: 19.5 5.5 0.0

trap
- position: 23.5 4.5 0.0
trap
- position: 23.5 2.5 0.0
trap
- position: 23.5 6.5 0.0


trap
- position: 11.5 3.5 0.0
trap
- position: 11.5 5.5 0.0

trap
- position: 7.5 4.5 0.0
trap
- position: 7.5 2.5 0.0
trap
- position: 7.5 6.5 0.0

push
- antiair_offset_std: 0.75

antiair
- position: 6.0 -1.0 0.0
- target: 15.5 4.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 8.0 -0.5 0.0
- target: 15.5 4.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 10.0 -1.0 0.0
- target: 15.5 4.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 12.0 -0.5 0.0
- target: 15.5 4.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 14.0 -1.0 0.0
- target: 15.5 4.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 16.0 -0.5 0.0
- target: 15.5 4.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 18.0 -1.0 0.0
- target: 15.5 4.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 20.0 -0.5 0.0
- target: 15.5 4.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 22.0 -1.0 0.0
- target: 15.5 4.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 24.0 -0.5 0.0
- target: 15.5 4.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 26.0 -1.0 0.0
- target: 15.5 4.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 6.0 1.0 0.0
- target: 15.5 4.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 8.0 1.5 0.0
- target: 15.5 4.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 10.0 1.0 0.0
- target: 15.5 4.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 12.0 1.5 0.0
- target: 15.5 4.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 14.0 1.0 0.0
- target: 15.5 4.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 16.0 1.5 0.0
- target: 15.5 4.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 18.0 1.0 0.0
- target: 15.5 4.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 20.0 1.5 0.0
- target: 15.5 4.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 22.0 1.0 0.0
- target: 15.5 4.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 24.0 1.5 0.0
- target: 15.5 4.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 26.0 1.0 0.0
- target: 15.5 4.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25


// Up

trap
- position: 15.5 14.5 0.0
trap
- position: 15.5 12.5 0.0
trap
- position: 15.5 16.5 0.0


trap
- position: 19.5 13.5 0.0
trap
- position: 19.5 15.5 0.0

trap
- position: 23.5 14.5 0.0
trap
- position: 23.5 12.5 0.0
trap
- position: 23.5 16.5 0.0


trap
- position: 11.5 13.5 0.0
trap
- position: 11.5 15.5 0.0

trap
- position: 7.5 14.5 0.0
trap
- position: 7.5 12.5 0.0
trap
- position: 7.5 16.5 0.0


antiair
- position: 8.0 9.5 0.0
- target: 15.5 14.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 10.0 9.0 0.0
- target: 15.5 14.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 12.0 9.5 0.0
- target: 15.5 14.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 14.0 9.0 0.0
- target: 15.5 14.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 16.0 9.5 0.0
- target: 15.5 14.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 18.0 9.0 0.0
- target: 15.5 14.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 20.0 9.5 0.0
- target: 15.5 14.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 22.0 9.0 0.0
- target: 15.5 14.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 24.0 9.5 0.0
- target: 15.5 14.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25


antiair
- position: 8.0 11.5 0.0
- target: 15.5 14.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 10.0 11.0 0.0
- target: 15.5 14.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 12.0 11.5 0.0
- target: 15.5 14.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 14.0 11.0 0.0
- target: 15.5 14.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 16.0 11.5 0.0
- target: 15.5 14.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 18.0 11.0 0.0
- target: 15.5 14.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 20.0 11.5 0.0
- target: 15.5 14.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 22.0 11.0 0.0
- target: 15.5 14.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25

antiair
- position: 24.0 11.5 0.0
- target: 15.5 14.5 0.0
- target_size: 16.0 4.0
- cooldown: 2.25


pop
BIG_POUNDING;

BIG_ROUND :: #string BIG_ROUND
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXGGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXGGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXGIIIIIIIIIIGGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXGIIIIIIIIIIGGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXGIIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGXXXiiiiiIIIIIIIIIIGGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGGGGiiiiiIIIIIIIIIIGGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGXXXiiiiiIIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXGIIIIIIIIIIGGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXIIIIIIXGIIIIIIIIIIGGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXIIIIIIXGIIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXIIIIIIXXXXIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXGGGIIIIIIIIIIIIIIXGGIIIIIIIIIIIIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXGGGIIIIIIIIIIIIIIXGGIIIIIIIIIIIIIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXGGGIIIIIIIIIIIIIIXXXXIIIIIIIIIIIIIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXGGGGGXIIIIIIIIIIIIIIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXGGGGGXXXXXXXXXXXXXXXXXXXIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXGGGIIIIIIIIIIIIIIXIIIIIIIIIIIIIIIIIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXGSGIIIIIIIIIIIIIIXIIIIIIIIIIIIIIIIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXGGGIIIIIIIIIIIIIIXIIIIIIIIIIIIIIIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXIIIIIIXXXXXIIIIIIIIIIIIIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

- name: Big Round

frame
- origin: 6.0 4.0
- size: 43.0 22.0

trophy
- position: 11.5 17.5 0

// First rotation

moving_frame
- key
-- position: 16 3 0
-- theta: 0
-- period: 2.5
- key
-- position: 16 3 0
-- theta: 0.5
-- period: 3
-t: 0.0

shuriken
- frame_id: 1
- position: 0.0 0 0
shuriken
- frame_id: 1
- position: 1.3 0 0
shuriken
- frame_id: 1
- position: 2.6 0 0
shuriken
- frame_id: 1
- position: -1.3 0 0
shuriken
- frame_id: 1
- position: -2.6 0 0
shuriken
- frame_id: 1
- position: 0 1.3 0
shuriken
- frame_id: 1
- position: 0 2.6 0
shuriken
- frame_id: 1
- position: 0 -1.3 0
shuriken
- frame_id: 1
- position: 0 -2.6 0


// Second rotation

moving_frame
- key
-- position: 16 11 0
-- theta: 0
-- period: 2.5
- key
-- position: 16 11 0
-- theta: 0.5
-- period: 3
-t: 0.0

shuriken
- frame_id: 2
- position: 0.0 0 0
shuriken
- frame_id: 2
- position: 1.3 0 0
shuriken
- frame_id: 2
- position: 2.6 0 0
shuriken
- frame_id: 2
- position: -1.3 0 0
shuriken
- frame_id: 2
- position: -2.6 0 0
shuriken
- frame_id: 2
- position: 0 1.3 0
shuriken
- frame_id: 2
- position: 0 2.6 0
shuriken
- frame_id: 2
- position: 0 -1.3 0
shuriken
- frame_id: 2
- position: 0 -2.6 0

key
- position: 6.5 9.5 0

gate
- position: 22.5 7 0
- wait_for_key_id: 1

flag
- position: 24 7 0


// First back and forth

moving_frame
- key
-- position: 28 6 0
-- theta: 0.6
-- period: 1.5
- key
-- position: 28 6 0
-- theta: 0.9
-- period: 1.5
- key
-- position: 28 6 0
-- theta: 0.6
-- period: 1.5
-t: 0.0

shuriken
- frame_id: 3
- position: 0 0 0
shuriken
- frame_id: 3
- position: 1 0 0
shuriken
- frame_id: 3
- position: 2 0 0
shuriken
- frame_id: 3
- position: 4 0 0



// Second back and forth

moving_frame
- key
-- position: 35 2 0
-- theta: 0.6
-- period: 1.5
- key
-- position: 35 2 0
-- theta: 0.9
-- period: 1.5
- key
-- position: 35 2 0
-- theta: 0.6
-- period: 1.5
-t: 0.0

shuriken
- frame_id: 4
- position: 0 0 0
shuriken
- frame_id: 4
- position: -1 0 0
shuriken
- frame_id: 4
- position: -2 0 0
shuriken
- frame_id: 4
- position: -4 0 0



// Third back and forth

moving_frame
- key
-- position: 42 6.5 0
-- theta: 0.6
-- period: 4.5
- key
-- position: 42 6.5 0
-- theta: 1.4
-- period: 4.5
- key
-- position: 42 6.5 0
-- theta: 0.6
-- period: 1.5
-t: 0.0

shuriken
- frame_id: 5
- position: 0.5 0 0
shuriken
- frame_id: 5
- position: 1.5 0 0
shuriken
- frame_id: 5
- position: 2.5 0 0
shuriken
- frame_id: 5
- position: 4.5 0 0




// The movers
moving_frame
- key
-- position: 23 14 0
-- theta: 0
-- period: 2.5
- key
-- position: 28 14 0
-- theta: 1
-- period: 2.5
- key
-- position: 23 14 0
-- theta: 2
-- period: 2

shuriken
- frame_id: 6
- position: 1.5 0 0
shuriken
- frame_id: 6
- position: -1.5 0 0

moving_frame
- key
-- position: 23 16 0
-- theta: 0
-- period: 2.5
- key
-- position: 28 16 0
-- theta: 1
-- period: 2.5
- key
-- position: 23 16 0
-- theta: 2
-- period: 2
- offset: 0.5

shuriken
- frame_id: 7
- position: 1.5 0 0
shuriken
- frame_id: 7
- position: -1.5 0 0


moving_frame
- key
-- position: 23 18 0
-- theta: 0
-- period: 2.5
- key
-- position: 28 18 0
-- theta: 1
-- period: 2.5
- key
-- position: 23 18 0
-- theta: 2
-- period: 2
- offset: 1

shuriken
- frame_id: 8
- position: 1.5 0 0
shuriken
- frame_id: 8
- position: -1.5 0 0

moving_frame
- key
-- position: 23 20 0
-- theta: 0
-- period: 2.5
- key
-- position: 28 20 0
-- theta: 1
-- period: 2.5
- key
-- position: 23 20 0
-- theta: 2
-- period: 2
- offset: 1.5

shuriken
- frame_id: 9
- position: 1.5 0 0
shuriken
- frame_id: 9
- position: -1.5 0 0

moving_frame
- key
-- position: 23 22 0
-- theta: 0
-- period: 2.5
- key
-- position: 28 22 0
-- theta: 1
-- period: 2.5
- key
-- position: 23 22 0
-- theta: 2
-- period: 2
- offset: 2.0

shuriken
- frame_id: 10
- position: 1.5 0 0
shuriken
- frame_id: 10
- position: -1.5 0 0

trap
- position: 29.25 16 0
trap
- position: 28.25 16 0
trap
- position: 27.25 16 0

trap
- position: 29.25 20 0
trap
- position: 28.25 20 0
trap
- position: 27.25 20 0

gate
- position: 15 17.5 0
- wait_for_key_id: 2
gate
- position: 14 17.5 0
- wait_for_key_id: 3
gate
- position: 13 17.5 0
- wait_for_key_id: 4

key
- position: 32 14 0
key
- position: 32 18 0
key
- position: 32 22 0





moving_frame
- key
-- position: 28 7 0
-- theta: 0.6
-- period: 1.5
- key
-- position: 28 7 0
-- theta: 0.9
-- period: 1.5
- key
-- position: 28 7 0
-- theta: 0.6
-- period: 1.5
-t: 0.0

shuriken
- frame_id: 11
- position: 0 0 0
shuriken
- frame_id: 11
- position: -1 0 0
shuriken
- frame_id: 11
- position: -2 0 0
shuriken
- frame_id: 11
- position: -4 0 0



moving_frame
- key
-- position: 35 11 0
-- theta: 0.6
-- period: 1.5
- key
-- position: 35 11 0
-- theta: 0.9
-- period: 1.5
- key
-- position: 35 11 0
-- theta: 0.6
-- period: 1.5
-t: 0.0

shuriken
- frame_id: 12
- position: 0 0 0
shuriken
- frame_id: 12
- position: 1 0 0
shuriken
- frame_id: 12
- position: 2 0 0
shuriken
- frame_id: 12
- position: 4 0 0



moving_frame
- key
-- position: 42 6.5 0
-- theta: 1.4
-- period: 4.5
- key
-- position: 42 6.5 0
-- theta: 0.6
-- period: 4.5
- key
-- position: 42 6.5 0
-- theta: 1.4
-- period: 1.5
-t: 0.0

shuriken
- frame_id: 13
- position: 0.5 0 0
shuriken
- frame_id: 13
- position: 1.5 0 0
shuriken
- frame_id: 13
- position: 2.5 0 0
shuriken
- frame_id: 13
- position: 4.5 0 0

flag
- position: 24 10 0
BIG_ROUND;

CHAMBER :: #string CHAMBER
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIIIIIIIIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXIIXXXXXXIIXXXXXXXXXXXIIXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXIIIIIIIIIIIIIXIIXIIIIXXXXIIIIXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXGGGXIIIIIIIXIIXIIIIXIIIIIIIXXXXIIIIXGGGXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXGGGIIIIIIIIXXXXIIIIIXXXIIIIXXXXIIIIIGGGXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXGGGXIIIIIIIXGGXIIIIIIIXIIIIXXXXIIIIXGGGXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXiXXXXXIIIIXGGXIIIIXIIIIIIIXXXXIIIIXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXiXXXXXXXXXXGGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXIXXGGGGGGGGGGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXRRRIIIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXiXXGGGGGGGGGGXXXXXXXXXXXXXXXXXXXXXXXXXXXGGGXXXXXXXXXXXXXXXX
XXXXXXXXXXXiXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXiXXXXXXIIIIIXXXXIIIIIXXXXIIIIIXXXXIIIIIXGGGXXXXXXXXXXXXXXXX
XXXXXXXXXXXiXXIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIGGGXXXXXXXXXXXXXXXX
XXXXXXXXXXXiXXIRRIIIIIIIRRIIIIIIIRRIIIIIIIRRIIIIIIXGGGXXXXXXXXXXXXXXXX
XXXXXXXXXXXiXIIRRIXXXXXIRRIXXXXXIRRIXXXXXIRRIXXXXXIiRiIXXXXXXXXXXXXXXX
XXXXXXXXGXGGGIIIIIXXXXXIIIIXXXXXIIIIXXXXXIIIIXXXXIiRRRiIXXXXXXXXXXXXXX
XXXXXXXXGGGGGIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXRRRRRRRRRXXXXXXXXXXXXX
XXXXXXXXGXGGGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIiRRRiIXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIiRiIXXXXXXXXXXXXXXX
XXXXXXXXXXGGGXIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIXGGGXXXXXXXXXXXXXXXX
XXXXXXXXXXGSGIIIIIXXXIIIIXXXIIIIXXXIIIIXXXIIIIXXXIIGGGXXXXXXXXXXXXXXXX
XXXXXXXXXXGGGXIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIXGGGXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

- name: Chamber

frame
- origin: 6.0 3.0
- size: 45.0 24.0

trophy
- position: 17 21 0

present
- position: 45.5 16.5 0

present
- position: 47.5 16.5 0
- kind: B

flag
- position: 47.0 13.5 0


present
- position: 2.5 8.5 0
- depends_on_flag_id: 1

present
- position: 2.5 10.5 0
- kind: B
- depends_on_flag_id: 1

flag
- position: 5 22.5 0

trap
- position: 12 6.75 0

antiair
- position: 12.75 5.5 0
- target: 12.0 4.5 0
- target_size: 0.0 0.0
- cooldown: 3.0

path
- checkpoint: 14.5 4 0
- checkpoint: 14.5 7 0
- checkpoint: 14.5 4 0

skull
- path_id: 0

trap
- position: 19 4.25 0

antiair
- position: 19.75 5.5 0
- target: 19.0 6.5 0
- target_size: 0.0 0.0
- cooldown: 3.0


path
- checkpoint: 21.5 7 0
- checkpoint: 21.5 4 0
- checkpoint: 21.5 7 0

skull
- path_id: 1

trap
- position: 26 6.75 0

antiair
- position: 26.75 5.5 0
- target: 26.0 4.5 0
- target_size: 0.0 0.0
- cooldown: 3.0

path
- checkpoint: 28.5 4 0
- checkpoint: 28.5 7 0
- checkpoint: 28.5 4 0

skull
- path_id: 2

trap
- position: 33 4.25 0

antiair
- position: 33.75 5.5 0
- target: 33.0 6.5 0
- target_size: 0.0 0.0
- cooldown: 3.0


path
- checkpoint: 35.5 7 0
- checkpoint: 35.5 4 0
- checkpoint: 35.5 7 0

skull
- path_id: 3

trap
- position: 40 6.75 0

antiair
- position: 40.75 5.5 0
- target: 40.0 4.5 0
- target_size: 0.0 0.0
- cooldown: 3.0

path
- checkpoint: 42.5 4 0
- checkpoint: 42.5 7 0
- checkpoint: 42.5 4 0

skull
- path_id: 4

trap
- position: 46.5 9.5 0
trap
- position: 47.15 10.15 0
trap
- position: 45.85 10.15 0

path
- checkpoint: 8.0 10.5 0
- checkpoint: 12.0 10.5 0
- checkpoint: 10.0 13.5 0
- checkpoint: 8.0 10.5 0

skull
- path_id: 5
- speed: 3
- offset: 0
skull
- path_id: 5
- speed: 3
- offset: 0.33
skull
- path_id: 5
- speed: 3
- offset: 0.66

path
- checkpoint: 26.0 10.5 0
- checkpoint: 30.0 10.5 0
- checkpoint: 28.0 13.5 0
- checkpoint: 26.0 10.5 0

skull
- path_id: 6
- speed: 3
- offset: 0
skull
- path_id: 6
- speed: 3
- offset: 0.33
skull
- path_id: 6
- speed: 3
- offset: 0.66

path
- checkpoint: 17.0 13.5 0
- checkpoint: 21.0 13.5 0
- checkpoint: 19.0 10.5 0
- checkpoint: 17.0 13.5 0

skull
- path_id: 7
- speed: 3
- offset: 0
skull
- path_id: 7
- speed: 3
- offset: 0.33
skull
- path_id: 7
- speed: 3
- offset: 0.66

path
- checkpoint: 35.0 13.5 0
- checkpoint: 39.0 13.5 0
- checkpoint: 37.0 10.5 0
- checkpoint: 35.0 13.5 0

skull
- path_id: 8
- speed: 3
- offset: 0
skull
- path_id: 8
- speed: 3
- offset: 0.33
skull
- path_id: 8
- speed: 3
- offset: 0.66

// trap
// - position: 11.5 24 0
// trap
// - position: 12 23.5 0
// trap
// - position: 12.5 23 0
// trap
// - position: 13 22.5 0

moving_frame
- key
-- position: 13 22.5 0
-- theta: 0
-- period: 2.15
- key
-- position: 13 22.5 0
-- theta: 1.0
-- period: 2

shuriken
- frame_id: 1
- position: -2.0 0 0
shuriken
- frame_id: 1
- position: -1.0 0 0
shuriken
- frame_id: 1
- position: 0.0 0 0
shuriken
- frame_id: 1
- position: 1.0 0 0
shuriken
- frame_id: 1
- position: 2.0 0 0

moving_frame
- key
-- position: 21 22.5 0
-- theta: 0
-- period: 2.15
- key
-- position: 21 22.5 0
-- theta: 1.0
-- period: 2

shuriken
- frame_id: 2
- position: -2.0 0 0
shuriken
- frame_id: 2
- position: -1.0 0 0
shuriken
- frame_id: 2
- position: 0.0 0 0
shuriken
- frame_id: 2
- position: 1.0 0 0
shuriken
- frame_id: 2
- position: 2.0 0 0

moving_frame
- key
-- position: 29 22.5 0
-- theta: 0
-- period: 2.15
- key
-- position: 29 22.5 0
-- theta: 1.0
-- period: 2

shuriken
- frame_id: 3
- position: -2.0 0 0
shuriken
- frame_id: 3
- position: -1.0 0 0
shuriken
- frame_id: 3
- position: 0.0 0 0
shuriken
- frame_id: 3
- position: 1.0 0 0
shuriken
- frame_id: 3
- position: 2.0 0 0

moving_frame
- key
-- position: 37 22.5 0
-- theta: 0
-- period: 2.15
- key
-- position: 37 22.5 0
-- theta: 1.0
-- period: 2

shuriken
- frame_id: 4
- position: -2.0 0 0
shuriken
- frame_id: 4
- position: -1.0 0 0
shuriken
- frame_id: 4
- position: 0.0 0 0
shuriken
- frame_id: 4
- position: 1.0 0 0
shuriken
- frame_id: 4
- position: 2.0 0 0

gate
- position: 17 19 0
- direction: 0 1 0
- wait_for_key_id: 1

key
- position: 41.5 22.5 0
CHAMBER;

BOMBERMAN_NORMAL :: #string BOMBERMAN_NORMAL
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXIIIGIIiIIiIIIiIIiIIGIIIXXXXXXXX
XXXXXXXIIXIXXIXXIXXXIXXIXXIXIIXXXXXXXX
XXXXXXXIIXIXXIXXIXRXIXXIXXIXIIXXXXXXXX
XXXXXXXIIXiIIGGGGGGGGGGGIIiXIIXXXXXXXX
XXXXXXXIIXIXXIXXIXXXIXXIXXIXIIXXXXXXXX
XXXXXXXIIXIXRGGIIIGIIIGGRXIXIIXXXXXXXX
XXXXXXXIIXIXXIXXIXGXIXXIXXIXIIXXXXXXXX
XXXXXXXIIIiIIiIIGGGGGIIiIIiIIIXXXXXXXX
XXXXXXXIIXIXXIXXIXGXIXXIXXIXIIXXXXXXXX
XXXXXXXIIXIXRGGIIIGIIIGGRXIXIIXXXXXXXX
XXXXXXXIIXIXXIXXIXXXIXXIXXIXIIXXXXXXXX
XXXXXXXIIXiIIGGGGGGGGGGGIIiXIIXXXXXXXX
XXXXXXXIIXIXXIXXIXRXIXXIXXIXIIXXXXXXXX
XXXXXXXIIXIXXIXXIXXXIXXIXXIXIIXXXXXXXX
XXXXXXXIIIGIIiIIiIIIiIIiIIGIIIXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

- name: Bomberman
spawn
- position: 18.5 15.5 0
- size: 0 0
frame
- position: 10 8
- size: 17 15
- origin: 0 0
block_rock
- position: 18.5 17.5 0
block_rock
- position: 20.5 15.5 0
block_rock
- position: 16.5 15.5 0
block_rock
- position: 18.5 13.5 0
block_rock
- position: 14.5 13.5 0
block_rock
- position: 13.5 13.5 0
block_rock
- position: 13.5 17.5 0
block_rock
- position: 14.5 17.5 0
block_rock
- position: 22.5 17.5 0
block_rock
- position: 23.5 17.5 0
block_rock
- position: 22.5 13.5 0
block_rock
- position: 23.5 13.5 0
block_rock
- position: 18.5 11.5 0
block_rock
- position: 19.5 11.5 0
block_rock
- position: 17.5 11.5 0
block_rock
- position: 13.5 11.5 0
block_rock
- position: 14.5 11.5 0
block_rock
- position: 23.5 11.5 0
block_rock
- position: 22.5 11.5 0
block_rock
- position: 23.5 19.5 0
block_rock
- position: 22.5 19.5 0
block_rock
- position: 19.5 19.5 0
block_rock
- position: 18.5 19.5 0
block_rock
- position: 17.5 19.5 0
block_rock
- position: 13.5 19.5 0
block_rock
- position: 14.5 19.5 0
block_rock
- position: 10.5 22.5 0
block_rock
- position: 26.5 22.5 0
block_rock
- position: 26.5 8.5 0
block_rock
- position: 10.5 8.5 0
block_rock
- position: 26.5 15.5 0
block_rock
- position: 25.5 15.5 0
block_rock
- position: 27.5 15.5 0
block_rock
- position: 10.5 15.5 0
block_rock
- position: 13.5 22.5 0
block_rock
- position: 16.5 22.5 0
block_rock
- position: 20.5 22.5 0
block_rock
- position: 23.5 22.5 0
block_rock
- position: 26.5 19.5 0
block_rock
- position: 26.5 11.5 0
block_rock
- position: 23.5 8.5 0
block_rock
- position: 20.5 8.5 0
block_rock
- position: 16.5 8.5 0
block_rock
- position: 13.5 8.5 0
block_rock
- position: 10.5 11.5 0
block_rock
- position: 10.5 19.5 0
block_rock
- position: 13.5 15.5 0
block_rock
- position: 23.5 15.5 0

BOMBERMAN_NORMAL;


S2E1 :: #string TERRAIN
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXIIIIIIIXXXXXXIIIIIGIIIIIXXXXXXIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXIIIIIIIIIXXXIIIIIXGGGXIIIIIXXXIIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXIIIXXXIIIXXIIIIIIIIGIIIIIIIIXIIIXXXXXIIXGGGXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXIIIIIXXIIIIIIIXXXXXXXXXXXIIIIIIIXIIIIIIXGGGXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXIIIIIXIIIIIIIXXXIIIIIXXXIIIIIIIXIIIIIIXGGGXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXIIIXIIIIIIXXIIIIIIIIIXXIIIIIIXIIXXXXXXGXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGIIIXIIIIIXXIIIIIIIIIIIXXIIIIIXIIIIIIIGGGXGGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGIIXXIIIIXXIIIXXIIIXXIIIXXIIIIXIIIIIIIGGGXGGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGXXXXXXXXXIIIXXIIIIIXXIIIXXXXXXXXXXXXXXXXXIIIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGXGGIIIIIIIIXXIIIXIIIXXIIIIIIIIIIIIXXXXXXXIIIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGGGIIIIIIIXXIIIXXXIIIXXIIIIIIIIIIIGGGXGGGiiiiiXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGGGIIIiXXXXIIIXXGXXIIIXXXXXXXXiIIIGGGGGGGiiiiiXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGGGIIIIIIIIIIXXGGGXXIIIIIIIIIIIIIIGGGXGGGiiiiiXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGGGIIIIIIIIIXXGGGGGXXIIIIIIIIIIIIIXXXXXXXIIIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXGXXXXXXXXXXXXXXXXXXXXXXXXIIIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGGGIIIIIIIIIIIGGGGGIIIIXIIIIIXIIIIIXIIIIIGGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGGGIIIIIIIIIIIGGGGGIIIIIIIIIIIIIIIIXIIIIIGGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGGGIIIIIIXIIIIGGGGGIIIIIIIIIIIIIIIIXIIIIIGGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGGGIIIIIIIIIIIGGGGGIIIIIIIIIIXIIIIIIIIIIIGGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGGGIIIIIIIIIIIGGGGGIIIIXIIIIIXIIIIIIIIIIIGGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

- name: S2E1 Pas les bases
spawn
- position: 9.5 9.5 0
- size: 0 0
frame
- position: 4 3.75
- size: 55.25 26.75
- origin: 9 2
flag
- position: 47.75 16.25 0
- index: 0
flag
- position: 9.5 14.75 0
- index: 1
trap
- position: 15.25 21.75 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 35.5 20.549999 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 35.549999 23.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 25.5 19 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 25.5 21.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 23 25.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 28 25.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trophy
- position: 47.5 24 0
block_rock
- position: 7 17.5 0
block_rock
- position: 9 17.5 0
jukebox
- position: 25.5 14 0
- direction: 0 -1 0
gate
- position: 46.5 15.5 0
- direction: 0 0 0
- is_closed: true
- wait_for_key_id: -1
- wait_for_trigger_id: -1
- wait_for_pressbutton_id: 1
gate
- position: 8 17.5 0
- direction: 0 1 0
- is_closed: true
- wait_for_key_id: -1
- wait_for_trigger_id: -1
- wait_for_pressbutton_id: 2
gate
- position: 47.5 21.5 0
- direction: 0 1 0
- is_closed: true
- wait_for_key_id: 1
- wait_for_trigger_id: -1
key
- position: 8.25 20 0
pressbutton
- position: 48.75 15.5 0
pressbutton
- position: 8 15 0
TERRAIN;


S2E2 :: #string TERRAIN
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXGGGGIIIIIIIIXIIIIIIIIGGGGXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXGGGGIIIIIIIIXIIIIIIIIGGGGXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXGGGGIIIIXIIIIIIIXIIIIGGGGXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXGGGGIIIIXIIIIIIIXIIIIGGGGXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXGGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXGGGGXXXXGGGGXGGGGXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXGGGGGGGGGGGGXGGGGIIIIIIIIXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXGGGGGGGGGGGGXGGGGIIIIIIIIXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXGGGGXGGGGXXXXXIIIXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXIIIIiiiiXIIIXIIIIXXXIIIIIXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXIIIIiiiiIIIIXIIIIIIXIIIIIXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXIIIIiiiiIIIIXIIIIIIXIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXIIIXiiiiIIIIXIIIIIIXIIIIIXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXiiiiXXXXXXXXXIIIIIIXIIIIIXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXiiiiXXXXGGGGXIIIIIIXXXIIIXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXiiiiXXXXGGGGXIIIIIIXIIIIIXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXiiiiXXXXXGGXXIIIIXXXIIIIIXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXIIIXiiiiIIIIXGGGGXXXIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXIIIIiiiiIIIIGGGGGXXXIIIIIXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXIIIIiiiiIIIIGGGGGXXXIIIIIXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXIIIIiiiiXIIIXGGGGXXXXXIIIXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIIIIIXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXGGGGGIIXIIIIIIIIIXIIGGGGGXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXGGGGGIIIIIIIIIIIIIIIGGGGGXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXGGGGGIIIIIIIIIIIIIIIGGGGGXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXGGGGGIIIIIIIIIIIIIIIGGGGGXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXGGGGGIIXIIIIIIIIIXIIGGGGGXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

- name: S2E2 Don't touch me
path
- checkpoint: 15.5 9 0
- checkpoint: 15.5 12 0
- checkpoint: 15.5 9 0
path
- checkpoint: 25.5 12 0
- checkpoint: 25.5 9 0
- checkpoint: 25.5 12 0
path
- checkpoint: 30.5 14 0
- checkpoint: 30.5 27 0
- checkpoint: 30.5 14 0
path
- checkpoint: 16 14 0
- checkpoint: 15 15.5 0
- checkpoint: 13 16.5 0
- checkpoint: 12 18 0
- checkpoint: 4 26 0
path
- checkpoint: 16 26 0
- checkpoint: 15 24.5 0
- checkpoint: 13 23.5 0
- checkpoint: 12 22 0
- checkpoint: 4 14 0
path
- checkpoint: 15.5 18 0
path
- checkpoint: 26 24 0
- checkpoint: 26 20 0
- checkpoint: 22 20 0
- checkpoint: 22 24 0
- closed
path
- checkpoint: 12.5 27.5 0
path
- checkpoint: 12.5 31 0
- checkpoint: 16.5 35 0
- checkpoint: 20.5 31 0
- checkpoint: 24.5 35 0
- checkpoint: 28.5 31 0
spawn
- position: 10.5 10.5 0
- size: 0 0
frame
- position: 4.25 4.75
- size: 31.25 33.25
- origin: 10 0
flag
- position: 30.5 10.5 0
- index: 0
flag
- position: 24.25 16 0
- index: 1
flag
- position: 18 28 0
- index: 2
trap
- position: 9 30.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 11 30.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trophy
- position: 31 33 0
block_rock
- position: 20.5 15 0
block_rock
- position: 20.5 17 0
jukebox
- position: 18 20 0
- direction: 0 -1 0
skull
- path_id: 0
- speed: 1
- offset: 0
skull
- path_id: 1
- speed: 1
- offset: 0.5
skull
- path_id: 1
- speed: 1
- offset: 0
skull
- path_id: 2
- speed: 2
- offset: 0.33
skull
- path_id: 2
- speed: 2
- offset: 1
skull
- path_id: 2
- speed: 2
- offset: 0.66
skull
- path_id: 3
- speed: 1
- offset: 0.82
skull
- path_id: 3
- speed: 1
- offset: 0.49
skull
- path_id: 3
- speed: 1
- offset: 0.16
skull
- path_id: 4
- speed: 1
- offset: 0.33
skull
- path_id: 4
- speed: 1
- offset: 0.66
skull
- path_id: 4
- speed: 1
- offset: 0
skull
- path_id: 6
- speed: 1.5
- offset: 0.5
skull
- path_id: 6
- speed: 1.5
- offset: 0
skull
- path_id: 8
- speed: 1
- offset: 0.2
skull
- path_id: 8
- speed: 1
- offset: 0.4
skull
- path_id: 8
- speed: 1
- offset: 0.6
skull
- path_id: 8
- speed: 1
- offset: 0.8
skull
- path_id: 8
- speed: 1
- offset: 0
skull
- path_id: 3
- speed: 1
- offset: 0.16
gate
- position: 20.5 16 0
- direction: 0 0 0
- is_closed: true
- wait_for_key_id: 1
- wait_for_trigger_id: -1
gate
- position: 10 30.5 0
- direction: 0 1 0
- is_closed: true
- wait_for_key_id: -1
- wait_for_trigger_id: -1
- wait_for_pressbutton_id: 1
key
- position: 30.5 11.5 0
pressbutton
- position: 10 28.5 0

TERRAIN

S2E3 :: #string TERRAIN
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXGGGGIIIIIIXXXXXXXGGGGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXGGGGIIIIIIXXXXXXXGGGGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXGGGGIIIIIIXXIIIIIGGGGIIIIXIIIIiiiIGGGXGGGXXXXXXXXXXXX
XXXXXXXXXXXXXGGGGIIIIIIXXIIIIIGGGGIIIIXIIIIiiiIGGGGGGGXXXXXXXXXXXX
XXXXXXXXXXXXXXXGXXXXIIIXXIIIIIGGGGIIIIXIIIIiiiIGGGXGGGXXXXXXXXXXXX
XXXXXXXXXXXXXXGGGGGXIIIXXIIIIXXXXXXIIIXIIXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXGGGGGXIIIXXIIIXXXXXXXIIIXIIIIiiiIIIIIIXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXIIIXXXIIIIXXXXXIXIXIIIIiiiIIIIIIXXXXXXXXXXXXXX
XXXXXXXXXXXXXXIIIIIIIIIXXXIIIIXXXXXIIIXIIIIiiiIIIIIIXXXXXXXXXXXXXX
XXXXXXXXXXXXXXIIIIIIIIIXXXIIIIXXXXXIIIXXXXXXXXXXXXIIXXXXXXXXXXXXXX
XXXXXXXXXXXXXXIIIIIIIIIXXXIIIIXXXXXIIIXXXXIIIIIXXXIIXXXXXXXXXXXXXX
XXXXXXXXXXXXXXIIIIIIIIIXXXIIIIXXXXXXIXXXXIIIIIIXXXIIXXXXXXXXXXXXXX
XXXXXXXXXXXXXXIIIXXXXXXXXXIIIIXXXXXIIIXXIIIIIIIXIIIIXXXXXXXXXXXXXX
XXXXXXXXXXXXXXIIIIIIIIIIIIIIIIXXXXXIIIIIIIIIXIIXIIIIXXXXXXXXXXXXXX
XXXXXXXXXXXXXXIIIIIIIIIIIIIIIIXXXXXIIIIIIIIXXIIIIIXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXIIIIIIIIIIIIIIIIXXXXXIIIIIIIXXXIIIIIXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

- name: S2E3 Bomba
path
- checkpoint: 30.5 12.25 0
- checkpoint: 30.5 18.75 0
- closed
path
- checkpoint: 27.25 5.25 0
- checkpoint: 32.25 10.5 0
- checkpoint: 34.5 7.25 0
- checkpoint: 32.25 10.5 0
- closed
spawn
- position: 2.75 19 0
- size: 0.05 0.05
frame
- position: -0.5 3.5
- size: 44 19.25
- origin: 12 3
shuriken
- position: 0 0 0
- frame_id: 1
shuriken
- position: 1 0 0
- frame_id: 1
shuriken
- position: -1 0 0
- frame_id: 1
moving_frame
- speed: 1
- offset: 0
- key
-- position: 4.5 6.5 0
-- theta: 0
-- period: 6
- key
-- position: 16 6.5 0
-- theta: 1
-- period: 3
- key
-- position: 16 12.5 0
-- theta: 1.5
-- period: 3
- key
-- position: 16 6.5 0
-- theta: 2
-- period: 6
- key
-- position: 4.5 6.5 0
-- theta: 2.999998
-- period: 6
trap
- position: 3.25 11 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 15 15 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 9.5 15.75 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trophy
- position: 6 15 0
block_rock
- position: 3.5 16.5 0
bomb_spawner
- position: 40.5 17.5 0
- explosion_time: 10
- explosion_radius: 0.5
jukebox
- position: 20 20 0
- direction: 0 -1 0
skull
- path_id: 0
- speed: 1
- offset: 0.33
skull
- path_id: 0
- speed: 1
- offset: 0.66
skull
- path_id: 0
- speed: 1
- offset: 0
skull
- path_id: 1
- speed: 2
- offset: 0.5
skull
- path_id: 1
- speed: 1
- offset: 0
gate
- position: 38.5 17.5 0
- direction: -1 -0 0
- is_closed: true
- wait_for_key_id: 1
- wait_for_trigger_id: -1
key
- position: 4 19 0
TERRAIN

S2E4 :: #string TERRAIN
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIIIIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIIIXXXXIIIXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXIIIIXXXXXXIIIXXXXXXIIIXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXIIIIIIIIXXXIIIIXXXXXXIIIXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXIIIIIIIIIIXIIIIIXXXXXXIIIXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXIIIXXXXIIIIIIIIIXXXXXXIIIXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXIIIXXXXXXIIIIIIIIIXXXXIIIXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXIIIXXXXXXIIIIIXGGGIIIIIIIXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXIIIXXXXXXIIIIIXGGGIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXIIIXXXXXXIIIIIXGGGIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXIIIXXXXIIIIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXIIIIIIIIIIIIIXIIIIGXGGGXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXIIIIIIIIXXIIXIIIIGGGGGGXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXIIIIXXXXIIXIIIIGGGGGGXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXGGXIIIIGXGGGXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGGIIIIIIIGGGGIIIIXXIIXXIIIIIIXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGGIIIIIIIGGGGIIIIXXIIXIIIIIIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGXXXXXXXXXGGGXXiiXXIIXIIIIIIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXIIIIXXXIIIIXXXIIIIXXIIXIIIIIIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXIIIIXXXIIIIXXXIIIIXXIIXIIIIIIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXIIIIiiiIIIIiiiIIIIXXIIXIIIIIIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXIIIIiiiIIIIiiiIIIIXXIIXIIIIIIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIIXXIIIIIIXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIIIIIIXGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXIIIIIIIIXXXIIIIIIXGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXIIIIIIIIIIIXXXXXXXXGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXIIIIIIIIIIIIIIIXXXXXGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXIIIIIIIIIIIIIIIIIIIIIIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXIXXIIIIIIIIIIIIIIIIIIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXGGGXXIIIIIIIIIIIIIIIIIIXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXGGGXXXIIIIIIIIIIIIIIIIXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXGGGXXXXIIIIIIIIIIIIIIXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

- name: S2E4 Merry round
spawn
- position: 15 21.75 0
- size: 0.05 0.05
frame
- position: 1 1.25
- size: 35.25 38.5
- origin: 14 4
shuriken
- position: 1 0 0
- frame_id: 1
shuriken
- position: 2.5 0 0
- frame_id: 1
shuriken
- position: 3.5 0 0
- frame_id: 1
shuriken
- position: -1 0 0
- frame_id: 1
shuriken
- position: -2.5 0 0
- frame_id: 1
shuriken
- position: -3.5 0 0
- frame_id: 1
shuriken
- position: 0 1 0
- frame_id: 1
shuriken
- position: 0 2.5 0
- frame_id: 1
shuriken
- position: 0 3.5 0
- frame_id: 1
shuriken
- position: 0 -1 0
- frame_id: 1
shuriken
- position: 0 -2.5 0
- frame_id: 1
shuriken
- position: 0 -3.5 0
- frame_id: 1
shuriken
- position: 1 0 0
- frame_id: 0
shuriken
- position: 4.25 0 0
- frame_id: 10
shuriken
- position: 3 0 0
- frame_id: 9
shuriken
- position: 4 0 0
- frame_id: 8
shuriken
- position: -4.75 0 0
- frame_id: 10
shuriken
- position: -3.5 0 0
- frame_id: 2
shuriken
- position: 0 -3.5 0
- frame_id: 2
shuriken
- position: 0 -2.5 0
- frame_id: 2
shuriken
- position: 0 -1 0
- frame_id: 2
shuriken
- position: 4 0 0
- frame_id: 7
shuriken
- position: -4 0 0
- frame_id: 7
shuriken
- position: 0 5 0
- frame_id: 7
shuriken
- position: 0 -5 0
- frame_id: 7
shuriken
- position: 0 1 0
- frame_id: 2
shuriken
- position: 0 2.5 0
- frame_id: 2
shuriken
- position: 0 3.5 0
- frame_id: 2
shuriken
- position: 1 0 0
- frame_id: 2
shuriken
- position: 3.5 0 0
- frame_id: 2
shuriken
- position: 2.5 0 0
- frame_id: 2
shuriken
- position: -1 0 0
- frame_id: 2
shuriken
- position: -2.5 0 0
- frame_id: 2
shuriken
- position: 1 0 0
- frame_id: 3
shuriken
- position: 2.25 0 0
- frame_id: 3
shuriken
- position: 3.5 0 0
- frame_id: 3
shuriken
- position: 0 1 0
- frame_id: 3
shuriken
- position: 0 2.25 0
- frame_id: 3
shuriken
- position: -0 3.5 0
- frame_id: 3
shuriken
- position: -1 0 0
- frame_id: 3
shuriken
- position: -2.25 0 0
- frame_id: 3
shuriken
- position: -3.5 0 0
- frame_id: 3
shuriken
- position: -0 -1 0
- frame_id: 3
shuriken
- position: 0 -2.25 0
- frame_id: 3
shuriken
- position: 0 -3.5 0
- frame_id: 3
shuriken
- position: 1.6 0 0
- frame_id: 13
shuriken
- position: 1.4 1.4 0
- frame_id: 4
shuriken
- position: 1.4 1.4 0
- frame_id: 17
shuriken
- position: -1.4 -1.4 0
- frame_id: 17
shuriken
- position: 0 1.8 0
- frame_id: 5
shuriken
- position: -0 -1.8 0
- frame_id: 5
shuriken
- position: 1.4 1.4 0
- frame_id: 23
shuriken
- position: 0.7 0.7 0
- frame_id: 23
shuriken
- position: 1.4 1.4 0
- frame_id: 6
shuriken
- position: 0.7 0.7 0
- frame_id: 6
shuriken
- position: 0 5 0
- frame_id: 8
shuriken
- position: 0 -5 0
- frame_id: 8
shuriken
- position: -4 0 0
- frame_id: 8
moving_frame
- speed: 1
- offset: 0
- key
-- position: 17 9 0
-- theta: 0
-- period: 4
- key
-- position: 22 7 0
-- theta: 0.5
-- period: 4
- key
-- position: 17 9 0
-- theta: 1
-- period: 4
moving_frame
- speed: 1
- offset: 1
- key
-- position: 29 7 0
-- theta: 0.5
-- period: 4
- key
-- position: 24 9 0
-- theta: 1
-- period: 4
- key
-- position: 29 7 0
-- theta: 0.5
-- period: 4
moving_frame
- speed: 1
- offset: 0
- key
-- position: 30 17 0
-- theta: 0
-- period: 4.4
- key
-- position: 30 17 0
-- theta: 0.999494
-- period: 4.4
moving_frame
- speed: 1
- offset: 0
- key
-- position: 19 16 0
-- theta: 0
-- period: 3
- key
-- position: 19 16 0
-- theta: 0.999493
-- period: 3
moving_frame
- speed: 1
- offset: 0
- key
-- position: 12 16 0
-- theta: 0
-- period: 5
- key
-- position: 12 16 0
-- theta: 0.999493
-- period: 1
moving_frame
- speed: 1
- offset: 0
- key
-- position: 5 16 0
-- theta: 0
-- period: 3
- key
-- position: 5 16 0
-- theta: 0.999493
-- period: 2.8
moving_frame
- speed: 1
- offset: 0
- key
-- position: 7 28 0
-- theta: 0
-- period: 5
- key
-- position: 9 28 0
-- theta: 0.501338
-- period: 5
- key
-- position: 7 28 0
-- theta: 0.999493
-- period: 1
moving_frame
- speed: 1
- offset: 0
- key
-- position: 21 32 0
-- theta: 0
-- period: 4
- key
-- position: 23 32 0
-- theta: 0.499747
-- period: 4
- key
-- position: 21 32 0
-- theta: 0.999493
-- period: 1
flag
- position: 32.5 11 0
- index: 0
flag
- position: 21.5 23 0
- index: 1
flag
- position: 15 21 0
- index: 2
present
- position: 26.5 23.5 0
- kind: A
- refresh_cooldown: 10
- depends_on_flag_id: -1
present
- position: 26.5 22.5 0
- kind: B
- refresh_cooldown: 10
- depends_on_flag_id: -1
present
- position: 12.5 18.5 0
- kind: A
- refresh_cooldown: 10
- depends_on_flag_id: 1
present
- position: 12.5 15.5 0
- kind: B
- refresh_cooldown: 10
- depends_on_flag_id: 1
trap
- position: 22 7 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 11.25 27.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 12.365 27.4 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 13.48 27.299999 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 14.58 27.200001 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 15.8 27.1 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 16 29.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 16.959999 30.15 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 18.039999 31.1 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 19 31.75 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trophy
- position: 18.5 27.5 0
block_rock
- position: 22.5 22 0
block_rock
- position: 22.5 24 0
jukebox
- position: 16 19 0
- direction: -0.714143 0.7 0
gate
- position: 22.5 23 0
- direction: 0 0 0
- is_closed: true
- wait_for_key_id: 1
- wait_for_trigger_id: -1
key
- position: 11.5 6.5 0
TERRAIN

S2E5 :: #string TERRAIN
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGGGIIIIiiiiXXXXiiiiIIIIiiiiXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGGGIIIIiiiiXXXXiiiiIIIIiiiiXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGGGIIIIiiiiXXXXiiiiIIIIiiiiXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGGGIIIIiiiiXXXXiiiiIIIXiiiiXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXiiiiXXXXXIIIiiiiIIIXXXXXGGGGXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXiiiiXXXXIIIIiiiiIIIIXXXXXGGXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXiiiiXXXXIIIIiiiiIIIIXXXXGGGGXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXiiiiXXXXIIIIiiiiIIIIXXXXGGGGXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXiiiiXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXGGXIIIIIIIIIIIIIIIIIIIIIGGGGXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGGGIIIIIIIIIIIIIIIIIIIIIGGGGXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGGGIIIIIIIIIIIIIIIIIIIIIGGGGXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGGGIIIIIIIIIIIIIIIIIIIIIGGGGXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXGGXXXXXXXXXXXXXXXXXXXXXXIIIIXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXGGXXXXXXXXXXXXXXXXXXXXXXIIIIXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIIIIXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGGGIIiiiiiiIIIIIiiiiiiIIGGGGXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGGGIIiiiiiiIIIIIiiiiiiIIGGGGXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGGGIIiiiiiiIIIIIiiiiiiIIGGGGXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGGGIIiiiiiiIIIIIiiiiiiIIGGGGXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

- name: S2E5 Vent d'hiver
spawn
- position: 9 8 0
- size: 0 0
frame
- position: 5 4.75
- size: 34 25.25
- origin: 10 4
flag
- position: 9 25 0
- index: 2
flag
- position: 9 15.5 0
- index: 1
flag
- position: 34 16 0
- index: 0
trap
- position: 35.5 13.6 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 34.700001 13.6 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 33.900002 13.6 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 32.049999 11.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 32.049999 12.25 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 32.799995 11.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 12 16 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 12 17.250002 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 20 17 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 28 17.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 28 16.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 28 15.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 25 14.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 15 14.75 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 9 20.1 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 7.25 20.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 9 21 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trophy
- position: 33 20 0
block_rock
- position: 32.5 21.5 0
block_rock
- position: 33.5 21.5 0
bomb_spawner
- position: 8 25 0
- explosion_time: 9
- explosion_radius: 0.5
bomb_spawner
- position: 32.5 16 0
- explosion_time: 10
- explosion_radius: 0.5
jukebox
- position: 9 13 0
- direction: 0 1 0
wind_zone
- direction: -0 -1
- aabb: 13 7 19 11
- strength: 0.4
wind_zone
- direction: -0.745929 -0.666025
- aabb: 32 11 36 14
- strength: 1
wind_zone
- direction: -1 0
- aabb: 11 14 32 18
- strength: 2
wind_zone
- direction: 1 0
- aabb: 7 18 11 23
- strength: 0.5
wind_zone
- direction: -1 0
- aabb: 15 23 27 27
- strength: 0.35
wind_zone
- direction: 0 -1
- aabb: 19 19 23 23
- strength: 0.5
wind_zone
- direction: -0.714143 -0.7
- aabb: 31 23 35 27
- strength: 0.5
wind_zone
- direction: -0 1
- aabb: 24 7 30 11
- strength: 0.4

TERRAIN;


S2E6 :: #string TERRAIN
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGXIIIIIIIXIIIIIIIXXXIIIIIIIIIIIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGXIIIIIIIXIIIIIIIXXXIIIIIIIIIIIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGXGGGXGGGXGGGXGGGXXXIIXXXXXXXXXIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGXGGGXGGGXGGGXGGGXGiiiiiIIIIIIXIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGIIIIXIIIIIIIXIIIXGiiiiiIIIIIIXIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGIIIIXIIIIIIIXIIIXXXIIXXXXXXIIXIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIIIXXGGGGXXXXXIIIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGXIIIIIIIIIGGXGGGXXGGGGXXXXXIIIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGXIIIIIIIIIGGGGGGXXGGGGXXXXXIIXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGXIIIIIIIIIGGXGGGXXGGGGXXXXXIIXIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGXIIIXXXXXXXXXXGXXXXIIXXXXXXIIXIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGXIIIXGGIIIIIIGGGIIIIIIIIXXXIIXIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGXIIIXGGIIIIIIIIIIIIIIIIIXXXIIXIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGXIIIXGGGGGGGGGGGGGGGGIIIXXXIIXIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGXIIIXXXXXXXXXXXXXXXXXIIIXXXIIXIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGXIIIIIIIIIIIIIIIIIIIIIIIXXXIIIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGGIIIIIIIIIIIIIIIIIIIIIIIXXXIIIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGGIIIIIIIIIIIIIIIIIIIIIIIXXXXIIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXGGGGIIIIiiiiiiiiiiIIiiiiGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXGGGGIIIIiiiiIIiiiiIIiiiiGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXGGGGIIIIiiiiIIiIIiIIiiiiGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXGGGGIIIIiiiiIIiIIiiiiiiiGGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIIXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

- name: S2E6 Bigflo et au lit
- night
path
- checkpoint: 11.5 19.5 0
- checkpoint: 5.5 19.5 0
- checkpoint: 5.5 13.5 0
- checkpoint: 23.5 13.5 0
- checkpoint: 23.5 17.5 0
path
- checkpoint: 11.5 20.5 0
- checkpoint: 4.5 20.5 0
- checkpoint: 4.5 12.5 0
- checkpoint: 24.5 12.5 0
- checkpoint: 24.5 16.5 0
- checkpoint: 24.5 17.5 0
path
- checkpoint: 11.5 21.5 0
- checkpoint: 3.5 21.5 0
- checkpoint: 3.5 11.5 0
- checkpoint: 25.5 11.5 0
- checkpoint: 25.5 17.5 0
path
- checkpoint: 3.5 24 0
- checkpoint: 17.5 24 0
path
- checkpoint: 17.5 28 0
- checkpoint: 4.5 28 0
- checkpoint: 3.5 28 0
spawn
- position: 8.5 7.25 0
- size: 0 0
frame
- position: -2.25 3.75
- size: 42.25 27.5
- origin: 17 6
flag
- position: 22 21.5 0
- index: 0
flag
- position: 17.4 20.5 0
- index: 1
trap
- position: 20.5 8 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 20.5 6.75 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 26.5 8 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 26.5 9.25 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 31.5 28.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 29.5 17.25 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 30.5 20.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 24.5 27.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trophy
- position: 0.5 28 0
block_rock
- position: -0.5 26.5 0
block_rock
- position: 0.25 26.5 0
block_rock
- position: 1 26.5 0
block_rock
- position: 1.75 26.5 0
block_rock
- position: 1 25.5 0
block_rock
- position: 0.25 25.5 0
block_rock
- position: -0.5 25.5 0
block_rock
- position: 1.75 25.5 0
bomb_spawner
- position: 16.5 21.5 0
- explosion_time: 10
- explosion_radius: 0.5
jukebox
- position: 8 16.5 0
- direction: 0 0 0
skull
- path_id: 0
- speed: 1
- offset: 0
skull
- path_id: 0
- speed: 1
- offset: 0
skull
- path_id: 0
- speed: 1
- offset: 0
skull
- path_id: 1
- speed: 1
- offset: 0.7
skull
- path_id: 1
- speed: 1
- offset: 0.5
skull
- path_id: 1
- speed: 1
- offset: 0.3
skull
- path_id: 1
- speed: 1
- offset: 0
skull
- path_id: 2
- speed: 12.5
- offset: 0
skull
- path_id: 0
- speed: 1
- offset: 0
skull
- path_id: 1
- speed: 1
- offset: 0
skull
- path_id: 1
- speed: 1
- offset: 0
skull
- path_id: 3
- speed: 1
- offset: 0.25
skull
- path_id: 3
- speed: 1
- offset: 0.25
skull
- path_id: 3
- speed: 1
- offset: 0.25
skull
- path_id: 3
- speed: 1
- offset: 0.25
skull
- path_id: 3
- speed: 1
- offset: 0.5
skull
- path_id: 3
- speed: 1
- offset: 0.75
skull
- path_id: 3
- speed: 1
- offset: 0
skull
- path_id: 2
- speed: 1
- offset: 0
skull
- path_id: 2
- speed: 1
- offset: 0
skull
- path_id: 2
- speed: 1
- offset: 0
skull
- path_id: 2
- speed: 1
- offset: 0
skull
- path_id: 4
- speed: 4
- offset: 0.25
skull
- path_id: 4
- speed: 4
- offset: 0
skull
- path_id: 4
- speed: 4
- offset: 0.5
skull
- path_id: 4
- speed: 4
- offset: -0.5
gate
- position: 14.5 20.5 0
- direction: 0 0 0
- is_closed: true
- wait_for_key_id: 2
- wait_for_trigger_id: -1
gate
- position: 16.5 18.5 0
- direction: 0 1 0
- is_closed: true
- wait_for_key_id: 1
- wait_for_trigger_id: -1
key
- position: 16.5 20.5 0
key
- position: 20.75 20.5 0
lantern
- position: 30.5 9.5 0
- light_aabb: 6 6 30 9.75
- button_id: 1
- intensity: 1
lantern
- position: 23 20.5 0
- light_aabb: 20 19 34 28.75
- button_id: 2
- intensity: 1
lantern
- position: 23 21.25 0
- light_aabb: 29 10 34 19
- button_id: 2
- intensity: 1
lantern
- position: 11.5 26 0
- light_aabb: 11 23 18 28.75
- button_id: 3
- intensity: 1
lantern
- position: 3.5 26 0
- light_aabb: 3 23 10 28.75
- button_id: 4
- intensity: 1
pressbutton
- position: 32 7.5 0
pressbutton
- position: 22 20.5 0
pressbutton
- position: 12.75 26 0
- radio
pressbutton
- position: 4.5 26 0
- radio
TERRAIN;

S2E7 :: #string TERRAIN
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXGGGGiiiiiiiiXXXIIIIIIIIGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXGGGGiiiiiiiiXXXIIIIIIIIGGGGGGGGXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXGGGGiiiiiiiiXXXIIIIIIIIGGGGGGGGXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXGGGGiiiiiiiiXXXXXXXXXXXGGGXXXGGXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXGGGGGGGXGGXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXiiiiXXXXIIIIIIiiiiiXXiiiiiiiXGGXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXIIIIIIiiiiiXXiiiiiiiXGGXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXiiiiXXXXIIIIIIiiiiiXXiiiiiiiXGGXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXiiiiiiiXGGXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXGGGGIIIXIXIXIXIXGGGGXiiiiiiiXGGXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXGGGGIXIXIXIXIXIXGGGGXiiiiiiiXGGXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXGGGGIXIXIXIXIXIXGGGGXiiiiiiiXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXGGGGIXIXIXIXIXIXGGGGXiiiiiiiXGGXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXiiiiiiiXGGXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXiiiiiiiXGGXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXiiiiiiiXGGXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXGGGGXXXIGGGGIIIIiiiiXiiiiiiiXGGXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXGGGGXXXIGGGGIIIIiiiiXiiiiiiiiGGXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXGGGGXXXIGGGGIIIIiiiiXiiiiiiiiGGXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXGGGGXXXIGGGGIIIIiiiiXiiiiiiiiGGXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXGGGXXXIIIiiiXXXGGGiiiXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXGGGXXXIIIiiiXXXGGGiiiIIIIIIIIIXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXGGGXXXIIXiiiXIIGGGiiiIIIIIIIIIXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXiiiiiiiiXiiiIIIGGGiiiIIIIIIIIIXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXiiiiiiiiXiiiIIIGGGiiiXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

- name: S2E7 Never give up
path
- checkpoint: 6.5 17.5 0
- checkpoint: 9.5 17.5 0
- checkpoint: 9.5 21.5 0
- checkpoint: 6.5 21.5 0
- closed
spawn
- position: 9.25 8.75 0
- size: 0 0
frame
- position: -0.75 -3
- size: 40.75 33
- origin: 14 10
flag
- position: 24 15 0
- index: 0
flag
- position: 8 15 0
- index: 1
flag
- position: 20.5 2.5 0
- index: 4
flag
- position: 30.5 24 0
- index: 3
flag
- position: 8.25 24.75 0
- index: 2
trap
- position: 22 11 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 23 11 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 24 11 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 22 12 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 22 13 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 21 13 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 20 13 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 13.5 16.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 12.5 15 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 15.5 14.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 19.5 16.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 17.5 15.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 19.5 13.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 11.5 13.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 6.5 11.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 7.5 11.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 8.5 11.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 9.5 11.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 10.5 11.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 11.5 11.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 12.5 11.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 13.5 11.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 14.5 11.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 15.5 11.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 16.5 11.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 17.5 11.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 18.5 11.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 19.5 11.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 20.5 11.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 13 22 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 13 23 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 12 22 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 11 22 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 21.5 17.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 20.5 17.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 19.5 17.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 18.5 17.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 17.5 17.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 16.5 17.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 15.5 17.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 14.5 17.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 13.5 17.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 12.5 17.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 11.5 17.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 10.5 20.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 10.5 19.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 10.5 18.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 22.5 17.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 24.5 17.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 25.5 17.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 23.5 17.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 26 18.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 26 19.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 26 20.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 26 21.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 19.5 25.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 19.5 24.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 19.5 23.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 5.5 11.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 4.5 11.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 3.5 11.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 5.5 19.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 4.5 19.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 3.5 19.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 25.049999 13 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 25.75 13 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 4.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 5.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 6.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 7.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 8.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 9.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 10.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 11.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 12.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 13.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 14.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 15.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 16.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 17.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 18.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 19.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 20.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 21.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 22.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 23.1 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 3.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 2.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 1.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 0.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: -0.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 26.5 10.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 26.5 11.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 26.5 12.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 26.5 16.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 26.5 15.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 26.5 14.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 26.5 13.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 30.5 4 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 34.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 35.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 36.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 37.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trophy
- position: 5.5 3.5 0
camp_ice
- position: 9 8 0
- cooldown_time: 1
- has_ice_cube: true
camp_ice
- position: 36 13 0
- cooldown_time: 1
- has_ice_cube: true
camp_ice
- position: 23 15 0
- cooldown_time: 1
- has_ice_cube: true
camp_ice
- position: 17 8 0
- cooldown_time: 1
- has_ice_cube: true
camp_ice
- position: 8 16.5 0
- cooldown_time: 1
- has_ice_cube: true
camp_ice
- position: 9 24 0
- cooldown_time: 1
- has_ice_cube: true
camp_ice
- position: 30.5 22.5 0
- cooldown_time: 1
- has_ice_cube: true
camp_ice
- position: 36 16 0
- cooldown_time: 1
- has_ice_cube: true
jukebox
- position: 7.5 24 0
- direction: 0 0 0
turn_table
- position: 15 25 0
- turning_speed: 0.1
- turning_offset: -0.5
turn_table
- position: 34.5 8.5 0
- turning_speed: 0
- turning_offset: 0
turn_table
- position: 34.5 7.5 0
- turning_speed: 0
- turning_offset: 0
turn_table
- position: 34.5 6.5 0
- turning_speed: 0
- turning_offset: 0
turn_table
- position: 24.5 20.5 0
- turning_speed: 0.1
- turning_offset: 0
turn_table
- position: 23.5 19.5 0
- turning_speed: 0.1
- turning_offset: 0.33
turn_table
- position: 22.5 18.5 0
- turning_speed: 0.1
- turning_offset: 0.66
turn_table
- position: 28.5 20.5 0
- turning_speed: 0
- turning_offset: 0.75
turn_table
- position: 28.5 16.5 0
- turning_speed: 0
- turning_offset: 0
turn_table
- position: 32.5 16.5 0
- turning_speed: 0
- turning_offset: -0.63
turn_table
- position: 31 18.5 0
- turning_speed: 0
- turning_offset: 0
turn_table
- position: 33.75 18.75 0
- turning_speed: 0
- turning_offset: 0.75
turn_table
- position: 33.5 11.75 0
- turning_speed: 0
- turning_offset: -0.64
turn_table
- position: 30.5 14.75 0
- turning_speed: 0
- turning_offset: 0
turn_table
- position: 32.75 14.75 0
- turning_speed: 0
- turning_offset: 0.64
turn_table
- position: 28.900002 9.25 0
- turning_speed: 0
- turning_offset: -0
turn_table
- position: 31 20.5 0
- turning_speed: 0
- turning_offset: 0.64
turn_table
- position: 30.25 17.75 0
- turning_speed: 0
- turning_offset: -0.35
turn_table
- position: 29.25 18.5 0
- turning_speed: 0
- turning_offset: -0.1
turn_table
- position: 28.5 14.75 0
- turning_speed: 0
- turning_offset: -0.25
turn_table
- position: 28.5 10.75 0
- turning_speed: 0
- turning_offset: 0
turn_table
- position: 33.5 10.5 0
- turning_speed: 0
- turning_offset: -0.34
turn_table
- position: 32.75 20.5 0
- turning_speed: 0
- turning_offset: 0.74
turn_table
- position: 32.75 18 0
- turning_speed: 0
- turning_offset: -0.37
turn_table
- position: 30.5 15.75 0
- turning_speed: 0
- turning_offset: -0.48
turn_table
- position: 27.5 15.5 0
- turning_speed: 0
- turning_offset: 0.75
turn_table
- position: 27.5 6.5 0
- turning_speed: 0
- turning_offset: 0.12
turn_table
- position: 31 9.5 0
- turning_speed: 0
- turning_offset: -0.74
turn_table
- position: 31 11.75 0
- turning_speed: 0
- turning_offset: -0.15
turn_table
- position: 25.5 1.5 0
- turning_speed: 0.3
- turning_offset: 0.66
turn_table
- position: 25.5 2.5 0
- turning_speed: 0.3
- turning_offset: 0.33
turn_table
- position: 25.5 3.5 0
- turning_speed: 0.3
- turning_offset: 0
turn_table
- position: 14.5 1 0
- turning_speed: 0.3
- turning_offset: 0
turn_table
- position: 14.5 4 0
- turning_speed: 0
- turning_offset: -0.5
turn_table
- position: 11 1 0
- turning_speed: 0.3
- turning_offset: 0
turn_table
- position: 5.5 1 0
- turning_speed: -0
- turning_offset: 0.25
turn_table
- position: 14 24 0
- turning_speed: 0.1
- turning_offset: 0
wind_zone
- direction: 0 1
- aabb: 22 6 26 13
- strength: 0.5

TERRAIN;

S2E8 :: #string TERRAIN
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXIIIIIIIXXXXXXXXXXXXIIIIIIIXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXIIIIIIIXXXXXXXXXXXXIIIIIIIXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGIIIIIIIIIIIiiiiiiiiIIIIIIIIIIIGGGXGGGXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGIIIIIXIIIIIiiiiiiiiIIIIIXIIIIIGGGGGGGXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGIIIIIIIIIIIiiiiiiiiIIIIIIIIIIIGGGXGGGXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGXXXIIIIIIIXXXXXXXXXXXXIIIIIIIXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGXXXIIIIIIIXXXXXXXXXXXXIIIIIIIXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGIIIXXIIIIIIIIXXIIIIIIIIXXIIIIIIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGIIIXXIIIIIIIIXXIIIIIIIIXXIIIIIIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGIIIXXIIIIIIIIXXIIIIIIIIXXIIIIIIIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXIIIXXIIIXXIIIXXIIIXXIIIXXIIIXXGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXIIIIIIIIXXIIIIIIIIXXIIIIIIIIXXGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXIIIIIIIIXXIIIIIIIIXXIIIIIIIIXXGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXIIIIIIIIXXIIIIIIIIXXIIIIIIIIXXXGXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXGXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGXIIIIIIIIIIIIIIIIIIIIIIIIIIIIXGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGXIIIIIIIIIIIIIIIIIIIIIIIIIIIIXGGGXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

- name: S2E8 6 Axes robotic
path
- checkpoint: 35 13.5 0
- checkpoint: 13 13.51 0
path
- checkpoint: 35 12 0
- checkpoint: 13 12.01 0
path
- checkpoint: 35 10.5 0
- checkpoint: 13 10.51 0
path
- checkpoint: 35 9 0
- checkpoint: 13 9.01 0
path
- checkpoint: 35 7.5 0
- checkpoint: 13 7.51 0
path
- checkpoint: 10 15 0
- checkpoint: 17 15 0
- checkpoint: 17 22 0
- checkpoint: 10 22.01 0
- checkpoint: 10 15 0
path
- checkpoint: 29 15 0
- checkpoint: 36 15 0
- checkpoint: 36 22 0
- checkpoint: 29 22.01 0
- checkpoint: 29 15 0
spawn
- position: 6.5 4.5 0
- size: 0.05 0.05
frame
- position: 3.5 2.25
- size: 42.5 21.5
- origin: 11 4
flag
- position: 5.5 18.5 0
- index: 1
flag
- position: 39.5 9.25 0
- index: 0
trophy
- position: 43.5 18.5 0
block_rock
- position: 39.5 7 0
block_rock
- position: 6.5 15 0
block_rock
- position: 41.5 18.5 0
bomb_spawner
- position: 5.5 5.5 0
- explosion_time: 10
- explosion_radius: 0.5
bomb_spawner
- position: 5.5 17.5 0
- explosion_time: 10
- explosion_radius: 0.5
bomb_spawner
- position: 40.5 9.5 0
- explosion_time: 10
- explosion_radius: 0.5
jukebox
- position: 6.5 12 0
- direction: 0 0 0
skull
- path_id: 0
- speed: 1.5
- offset: 0
skull
- path_id: 1
- speed: 1.5
- offset: 0
skull
- path_id: 2
- speed: 1.5
- offset: 0
skull
- path_id: 3
- speed: 1.5
- offset: 0
skull
- path_id: 4
- speed: 1.5
- offset: 0
skull
- path_id: 0
- speed: 1.5
- offset: 0.5
skull
- path_id: 1
- speed: 1.5
- offset: 0.5
skull
- path_id: 2
- speed: 1.5
- offset: 0.5
skull
- path_id: 3
- speed: 1.5
- offset: 0.5
skull
- path_id: 4
- speed: 1.5
- offset: 0.5
skull
- path_id: 5
- speed: 1.5
- offset: 0
skull
- path_id: 5
- speed: 1.5
- offset: 0.04
skull
- path_id: 5
- speed: 1.5
- offset: 0.08
skull
- path_id: 5
- speed: 1.5
- offset: 0.12
skull
- path_id: 5
- speed: 1.5
- offset: 0.16
skull
- path_id: 5
- speed: 1.5
- offset: 0.2
skull
- path_id: 5
- speed: 1.5
- offset: 0.24
skull
- path_id: 5
- speed: 1.5
- offset: 0.28
skull
- path_id: 5
- speed: 1.5
- offset: 0.32
skull
- path_id: 5
- speed: 1.5
- offset: 0.36
skull
- path_id: 5
- speed: 1.5
- offset: 0.4
skull
- path_id: 5
- speed: 1.5
- offset: 0.44
skull
- path_id: 5
- speed: 1.5
- offset: 0.48
skull
- path_id: 5
- speed: 1.5
- offset: 0.52
skull
- path_id: 5
- speed: 1.5
- offset: 0.56
skull
- path_id: 5
- speed: 1.5
- offset: 0.6
skull
- path_id: 5
- speed: 1.5
- offset: 0.64
skull
- path_id: 5
- speed: 1.5
- offset: 0.68
skull
- path_id: 5
- speed: 1.5
- offset: 0.72
skull
- path_id: 5
- speed: 1.5
- offset: 0.76
skull
- path_id: 5
- speed: 1.5
- offset: 0.8
skull
- path_id: 5
- speed: 1.5
- offset: 0.84
skull
- path_id: 5
- speed: 1.5
- offset: 0.88
skull
- path_id: 5
- speed: 1.5
- offset: 0.92
skull
- path_id: 6
- speed: 1.5
- offset: 0
skull
- path_id: 6
- speed: 1.5
- offset: 0.04
skull
- path_id: 6
- speed: 1.5
- offset: 0.08
skull
- path_id: 6
- speed: 1.5
- offset: 0.12
skull
- path_id: 6
- speed: 1.5
- offset: 0.16
skull
- path_id: 6
- speed: 1.5
- offset: 0.2
skull
- path_id: 6
- speed: 1.5
- offset: 0.24
skull
- path_id: 6
- speed: 1.5
- offset: 0.32
skull
- path_id: 6
- speed: 1.5
- offset: 0.36
skull
- path_id: 6
- speed: 1.5
- offset: 0.4
skull
- path_id: 6
- speed: 1.5
- offset: 0.44
skull
- path_id: 6
- speed: 1.5
- offset: 0.48
skull
- path_id: 6
- speed: 1.5
- offset: 0.52
skull
- path_id: 6
- speed: 1.5
- offset: 0.56
skull
- path_id: 6
- speed: 1.5
- offset: 0.6
skull
- path_id: 6
- speed: 1.5
- offset: 0.64
skull
- path_id: 6
- speed: 1.5
- offset: 0.68
skull
- path_id: 6
- speed: 1.5
- offset: 0.72
skull
- path_id: 6
- speed: 1.5
- offset: 0.76
skull
- path_id: 6
- speed: 1.5
- offset: 0.8
skull
- path_id: 6
- speed: 1.5
- offset: 0.84
skull
- path_id: 6
- speed: 1.5
- offset: 0.88
skull
- path_id: 6
- speed: 1.5
- offset: 0.92
skull
- path_id: 6
- speed: 1.5
- offset: 0.96
robot
- position: 14 1 0
- max_rotation_speed: 19.739201
- start_target_aabb: 8.5 3
- end_target_aabb: 26.5 6
- charging_time: 0.2
- effectshoot_time: 0.2
- predict: 0.3
- shooting_cd: 1.3
- shooting_time: 0.3
- shooting_offset: 0
robot
- position: 20 1 0
- max_rotation_speed: 19.739201
- start_target_aabb: 10 3
- end_target_aabb: 30 6
- charging_time: 0.2
- effectshoot_time: 0.2
- predict: 0.3
- shooting_cd: 1.3
- shooting_time: 0.3
- shooting_offset: 0
robot
- position: 26 1 0
- max_rotation_speed: 19.739201
- start_target_aabb: 16 3
- end_target_aabb: 36 6
- charging_time: 0.2
- effectshoot_time: 0.2
- predict: 0.3
- shooting_cd: 1.3
- shooting_time: 0.3
- shooting_offset: 0
robot
- position: 32 1 0
- max_rotation_speed: 19.739201
- start_target_aabb: 21.25 3
- end_target_aabb: 37 6
- charging_time: 0.2
- effectshoot_time: 0.2
- predict: 0.4
- shooting_cd: 1.3
- shooting_time: 0.3
- shooting_offset: 0
robot
- position: 12 11 0
- max_rotation_speed: 19.739201
- start_target_aabb: 8.25 7.25
- end_target_aabb: 15.75 13.75
- charging_time: 0.2
- effectshoot_time: 0.2
- predict: 0.5
- shooting_cd: 1
- shooting_time: 0.3
- shooting_offset: 0
robot
- position: 17 10 0
- max_rotation_speed: 19.739201
- start_target_aabb: 13.25 7.25
- end_target_aabb: 20.75 13.75
- charging_time: 0.2
- effectshoot_time: 0.2
- predict: 0.5
- shooting_cd: 1.3
- shooting_time: 0.3
- shooting_offset: 0
robot
- position: 22 11 0
- max_rotation_speed: 19.739201
- start_target_aabb: 18.25 7.25
- end_target_aabb: 25.75 13.75
- charging_time: 0.2
- effectshoot_time: 0.2
- predict: 0.5
- shooting_cd: 1.3
- shooting_time: 0.3
- shooting_offset: 0
robot
- position: 27 10 0
- max_rotation_speed: 19.739201
- start_target_aabb: 23.25 7.25
- end_target_aabb: 30.75 13.75
- charging_time: 0.2
- effectshoot_time: 0.2
- predict: 0.5
- shooting_cd: 1.3
- shooting_time: 0.3
- shooting_offset: 0
robot
- position: 32 11 0
- max_rotation_speed: 19.739201
- start_target_aabb: 28.25 7.25
- end_target_aabb: 35.75 13.75
- charging_time: 0.2
- effectshoot_time: 0.2
- predict: 0.5
- shooting_cd: 1.3
- shooting_time: 0.3
- shooting_offset: 0
robot
- position: 13.5 18.5 0
- max_rotation_speed: 19.739201
- start_target_aabb: 10 15
- end_target_aabb: 17 22
- charging_time: 0.2
- effectshoot_time: 0.2
- predict: 0.5
- shooting_cd: 1.5
- shooting_time: 0.3
- shooting_offset: 0
robot
- position: 13.5 18.5 0
- max_rotation_speed: 19.739201
- start_target_aabb: 10 15
- end_target_aabb: 17 22
- charging_time: 0.2
- effectshoot_time: 0.2
- predict: 0.5
- shooting_cd: 1.4
- shooting_time: 0.3
- shooting_offset: 0
robot
- position: 32.5 18.5 0
- max_rotation_speed: 19.739201
- start_target_aabb: 29 15
- end_target_aabb: 36 22
- charging_time: 0.2
- effectshoot_time: 0.2
- predict: 0.5
- shooting_cd: 1.5
- shooting_time: 0.3
- shooting_offset: 0
robot
- position: 32.5 18.5 0
- max_rotation_speed: 19.739201
- start_target_aabb: 29 15
- end_target_aabb: 36 22
- charging_time: 0.2
- effectshoot_time: 0.2
- predict: 0.5
- shooting_cd: 1.4
- shooting_time: 0.3
- shooting_offset: 0

TERRAIN;

S2E9 :: #string TERRAIN
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGGiiXIIIiiiIIIiiiiGGGGGGGGXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGGiiiIIIiiiIIIiiiiGGGGGGGGXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGGiiiIIIiiiIIIXiiiGGGGGGGGXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIIIXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIIIXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXIIIIIIIIIIXIIIIIIIIIIIIIIIIXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXIXIIIIIIIIIIIIIIIIIIIIIIIXIXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXIIIIIIIIIIIIIIIIXIIIIIIIIIIXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXIIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXGGGGGIIIIIIIIIIIIIIIIIIIIIGGGXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXGGGGGIXXIIXXIIXXXIIXXIIXXIGGGXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXGGGGGIIIIIIIIIIIIIIIIIIIIIGGGXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXGGGXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGGIIIIIIIIIIIIIIIIIIIIIGGGXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGGIIXXIIIXXIIIXXIIIXXIIGGGXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGGIIIIIIIIIIIIIIIIIIIIIGGGXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXIIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXIIXIIIIIIIIIIIIIIIIIIIIIXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGGIIIIIIIIIIIIIIIIIIIIIGGGGXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGGIIIIIIIIIIIIIIIIIIIIIGGGGXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGGIIIIIIIIIIIIIIIIIIIIIGGGGXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGGIIIIIIIIIIIIIIIIIIIIIGGGGXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGXIIIIIIIIIIIIIIIIIIIIIXiiXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGGXXXXXXXXXXXXXXXXXXXXXXiiXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGGXXXXXXXXXXXXXXXXXXXXXXiiXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGGXXXXXXXXXXXXXXXXXXXXXXiiXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXGGXIIIIIIIIIIIIIIIIIIIIIXiiXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGGIIIIIIIIIIIIIIIIIIIIIGGGGXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGGIIIIIIIIIIIIIIIIIIIIIGGGGXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGGIIIIIIIIIIIIIIIIIIIIIGGGGXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXGGGGIIIIIIIIIIIIIIIIIIIIIGGGGXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXIIIIIIIIIIIIIIIIIIIIIXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

- name: S2E9 Comme en 40
spawn
- position: 8 8 0
- size: 0 0
frame
- position: 3 2.25
- size: 34.25 42
- origin: 10 7
push
- antiair_offset_std: 0.75
flag
- position: 8 18 0
- index: 1
flag
- position: 33 17 0
- index: 0
flag
- position: 8.5 31 0
- index: 2
flag
- position: 27 40.5 0
- index: 3
trap
- position: 12.5 9.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 15.5 6.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 16.5 9.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 21.5 6.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 21.5 8.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 26.5 10.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 11.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 27.5 7.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 29.5 5.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 15.5 18.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 13.5 15.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 21.5 16.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 18.5 17.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 24.5 18.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 25.5 15.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 29.25 17.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 12.5 25.299999 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 17.5 27.700001 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 22.5 25.300001 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 27.5 27.700001 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 28.5 31.75 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 24.5 29.25 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 20.5 31.75 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 15.5 29.25 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 11.5 31.75 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trap
- position: 17.5 40.5 0
- radius_hitbox: 0.5
- stay_activated_time: 1

trophy
- position: 8.5 40.5 0
block_rock
- position: 7 10.5 0
block_rock
- position: 9 10.5 0
block_rock
- position: 30.5 39.5 0
block_rock
- position: 30.5 40.5 0
block_rock
- position: 30.5 41.5 0
block_rock
- position: 29.5 41.5 0
block_rock
- position: 29.5 40.5 0
block_rock
- position: 29.5 39.5 0
block_rock
- position: 28.5 39.5 0
block_rock
- position: 28.5 40.5 0
block_rock
- position: 28.5 41.5 0
bomb_spawner
- position: 8.5 29.5 0
- explosion_time: 10
- explosion_radius: 0.5
jukebox
- position: 7 18 0
- direction: 0 0 0
jukebox
- position: 6.5 30.5 0
- direction: 0 0 0
gate
- position: 8 10.5 0
- direction: 0 -1 0
- is_closed: true
- wait_for_key_id: -1
- wait_for_trigger_id: -1
- wait_for_pressbutton_id: 1
pressbutton
- position: 8 16 0
nutcracker
- position: 8.5 35.5 0
- target: 8.5 33 0
- time_offset: 0
- throw_time_cooldown: 1
- shoot_pattern
-- target: 8.5 33 0
-- time: 0.5
- shoot_pattern
-- target: 10 34 0
-- time: 0.5
- shoot_pattern
-- target: 14.5 35.5 0
-- time: 1.8
nutcracker
- position: 17.5 36.5 0
- target: 12 34 0
- time_offset: 0.5
- throw_time_cooldown: 1
- shoot_pattern
-- target: 12 34 0
-- time: 0.5
- shoot_pattern
-- target: 17.5 34 0
-- time: 0.5
- shoot_pattern
-- target: 23 34 0
-- time: 1.8
nutcracker
- position: 23.5 34.5 0
- target: 18 37 0
- time_offset: 1
- throw_time_cooldown: 1
- shoot_pattern
-- target: 18 37 0
-- time: 0.5
- shoot_pattern
-- target: 23.5 37 0
-- time: 0.5
- shoot_pattern
-- target: 29 37 0
-- time: 1.8
nutcracker
- position: 32.5 35.5 0
- target: 26.5 35.5 0
- time_offset: 1.5
- throw_time_cooldown: 1
- shoot_pattern
-- target: 26.5 35.5 0
-- time: 0.5
- shoot_pattern
-- target: 31 37 0
-- time: 0.5
- shoot_pattern
-- target: 32.5 39 0
-- time: 1.8
nutcracker
- position: 6 24 0
- target: 8 20 0
- time_offset: 0
- throw_time_cooldown: 1
- shoot_pattern
-- target: 8 20 0
-- time: 1
- shoot_pattern
-- target: 9 20 0
-- time: 2
nutcracker
- position: 10 24 0
- target: 8 20 0
- time_offset: 0.5
- throw_time_cooldown: 1
- shoot_pattern
-- target: 8 20 0
-- time: 1
- shoot_pattern
-- target: 7 20 0
-- time: 2
nutcracker
- position: 12.5 41.5 0
- target: 22.5 39.5 0
- time_offset: 0
- throw_time_cooldown: 1
- shoot_pattern
-- target: 22.5 39.5 0
-- time: 2
- shoot_pattern
-- target: 22.5 41.5 0
-- time: 4
nutcracker
- position: 22.5 39.5 0
- target: 12.5 41.5 0
- time_offset: 1.5
- throw_time_cooldown: 1
- shoot_pattern
-- target: 12.5 41.5 0
-- time: 2
- shoot_pattern
-- target: 12.25 39.5 0
-- time: 4
wind_zone
- direction: 0.7 0.714143
- aabb: 10 14 31 20
- strength: 1.5
antiair
- position: 11 4 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 12 3 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 13 4 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 14 3 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 15 4 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 16 3 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 17 4 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 18 3 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 19 4 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 20 3 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 21 4 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 22 3 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 23 4 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 24 3 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 25 4 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 26 3 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 27.25 4 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 28 3 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 29.5 4 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 11 13 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 12 12 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 13 13 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 14 12 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 15 13 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 16 12 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 17 13 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 18 12 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 19 13 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 20 12 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 21 13 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 22 12 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 23 13 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 24 12 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 25 13 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 26 12 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 27 13 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 28 12 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 29 13 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 30 12 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 10 12 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 12.5 2 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 14.5 2 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 16.5 2 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 18.5 2 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 20.5 2 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 22.5 2 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 24.5 2 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 26.5 2 0
- target_aabb: 10 5 31 11
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 11 21 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 13 21 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 15 21 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 17 21 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 19 21 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 21 21 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 23 21 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 25 21 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 27 21 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 29 21 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 31 21 0
- target_aabb: 10 14 31 20
- cooldown: 2
- radius: 1
- offset_time: 0
antiair
- position: 12.95 26.5 0
- target_aabb: 12.25 27.25 12.75 27.75
- cooldown: 2.25
- radius: 1
- offset_time: 0
antiair
- position: 17.950001 26.5 0
- target_aabb: 17.25 25.25 17.75 25.75
- cooldown: 2.25
- radius: 1
- offset_time: 0
antiair
- position: 22.949999 26.5 0
- target_aabb: 22.25 27.25 22.75 27.75
- cooldown: 2.25
- radius: 1
- offset_time: 0
antiair
- position: 27.949999 26.5 0
- target_aabb: 27.25 25.25 27.75 25.75
- cooldown: 2.25
- radius: 1
- offset_time: 0
antiair
- position: 12 30.5 0
- target_aabb: 11.25 29.25 11.75 29.75
- cooldown: 2.25
- radius: 1
- offset_time: 0
antiair
- position: 16 30.5 0
- target_aabb: 15.25 31.25 15.75 31.75
- cooldown: 2.25
- radius: 1
- offset_time: 0
antiair
- position: 20.5 30.5 0
- target_aabb: 20.25 29.25 20.75 29.75
- cooldown: 2.25
- radius: 1
- offset_time: 0
antiair
- position: 25 30.5 0
- target_aabb: 24.25 31.25 24.75 31.75
- cooldown: 2.25
- radius: 1
- offset_time: 0
antiair
- position: 29 30.5 0
- target_aabb: 28.25 29.25 28.75 29.75
- cooldown: 2.25
- radius: 1
- offset_time: 0
pop

TERRAIN;
