#import "String";
#import "Hash";
#import "Terrain";

embed_database_default_rosters :: (app: *App) {
	app_user := app.user_data.(*App_User);
	
	exec_database(
		app.platform,
		app_user.server.db,
		#string QUERY
			INSERT INTO terrain_rosters (id, name, terrain_ids) VALUES (
				1, "Base", "[100, 101, 102, 103, 104, 105, 106]"
			) ON CONFLICT(id) DO UPDATE SET
				terrain_ids = excluded.terrain_ids,
				name = excluded.name
			;
		QUERY
	);

	roster: [] string = .[
		"Welcome",
		"Good Intro",
		"Good Too",
		"Good Ice",
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
		"Tetris",
	];

	sb: String_Builder;
	print_to_builder(*sb, "INSERT INTO terrain_rosters (id, name, terrain_ids) VALUES (2, \"File\", \"[");
	sep := "";
	for roster {
		info := load_database(
			app.platform,
			app_user.server.db,
			"terrain_infos",
			DB_Terrain_Infos,
			tprint("name = \"%\"", it)
		);

		if info.count == 0
			continue;
		
		print_to_builder(*sb, "%1%2", sep, info[0].id);
		sep = ", ";
	}
	print_to_builder(*sb, "]\") ");
	print_to_builder(*sb, "ON CONFLICT(id) DO UPDATE SET terrain_ids = excluded.terrain_ids, name = excluded.name;");
	exec_database(app.platform, app_user.server.db, builder_to_string(*sb));
}

embed_database_default_terrains :: (app: *App) {
	app_user := app.user_data.(*App_User);
	server := *app_user.server;
	platform := app.platform;
	save :: (new_id: int, ascii: string, name: string) #expand {
		ids: [1] DB_Terrain_Id;
		ids[0].id = new_id;
		store_database(platform, server.db, "terrain_ids", ids);

		to_saves: [1] DB_Terrain_Infos;
		to_save := *to_saves[0];
		to_save.id = new_id;
		to_save.author_profile_id = -1;
		to_save.name = parse_terrain_name(ascii);
		to_save.created_ms = 0;
		store_database(platform, server.db, "terrain_infos", to_saves);

		to_asciis: [1] DB_Terrain_Ascii;
		to_ascii := *to_asciis[0];
		to_ascii.id = new_id;
		to_ascii.ascii_id = new_id;
		to_ascii.ascii = ascii;
		store_database(platform, server.db, "terrain_asciis", to_asciis, true, "ascii_id");
	}

	terrains := platform.list_files("../assets/terrain", false);
	save(100, PIKC_TERRAIN, "Built Pick");
	save(101, BIG_SHIP, "Built Big Ship");
	save(102, BIG_INTRO, "Built Big Intro");
	save(103, BIG_TURN, "Built Big Turn");
	save(104, BIG_BOMBS, "Built Big Bombs");
	save(105, BIG_POUNDING, "Built Big Pounding");
	save(106, BIG_ROUND, "Built Big Round");

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
XXXXXXXXXXXXIIGIIGIIGIIXXXXXXXXXXXXXXXXX
XXXXXXXXXXGGIIGIIGIIGIIGGXXXXXXXXXXXXXXX
XXXXXXXXXIIIIIIIIIIIIIIIIIXXXXXXXXXXXXXX
XXXXXXXXGGIIRIIIIIIIIIRIIGGXXXXXXXXXXXXX
XXXXXXXXIIIIRIIiiiiiIIRIIIIXXXXXXXXXXXXX
XXXXXXXXGGIIRIIiiiiiIIRIIGGXXXXXXXXXXXXX
XXXXXXXXIIIIRIIIIIIIIIRIIIIXXXXXXXXXXXXX
XXXXXXXXXIGIIIIIXGXIIIIIGIXXXXXXXXXXXXXX
XXXXXXXXXIGIIIGIXGXIGIIIGIXXXXXXXXXXXXXX
XXXXXXXXXXXXIIGIXGXIGIIXXXXXXXXXXXXXXXXX
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
- position: 11.5 10.5 0.0
- orientation_dir: 0 -1 0

trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 11.5 10.5 0.0
- radius: 1.0
- model_id: 1

standin
- model_id: 2
- position: 8.5 10.5 0.0
- orientation_dir: 0 -1 0

trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 8.5 10.5 0.0
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
- position: 14.5 10.5 0.0
- orientation_dir: 0 -1 0

trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 14.5 10.5 0.0
- radius: 1.0
- model_id: 3

trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 14.5 12.5 0.0
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