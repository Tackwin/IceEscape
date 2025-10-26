#scope_file
Platform :: #import "Platform";
Controls :: #import "Controls";
Scene :: #import "Scene";
#import "Basic";
#import "Math";
#import "Algebra";
#import "Assets";

Z_SLOT :: V2f.{ 0, 15 };
Q_SLOT :: V2f.{ 1, 15 };
C_SLOT :: V2f.{ 2, 15 };
UP_SLOT :: V2f.{ 3, 15 };
QUESTION_SLOT :: V2f.{ 9, 15 };
S_SLOT :: V2f.{ 0, 14 };
D_SLOT :: V2f.{ 1, 14 };
A_SLOT :: V2f.{ 2, 14 };
RIGHT_SLOT :: V2f.{ 3, 14 };
SPACE_SLOT :: V2f.{ 0, 13 };
W_SLOT :: V2f.{ 1, 13 };
DOWN_SLOT :: V2f.{ 2, 13 };
LEFT_SLOT :: V2f.{ 3, 13 };
W_OUTLINE_SLOT :: V2f.{ 0, 12 };
A_OUTLINE_SLOT :: V2f.{ 1, 12 };
Q_OUTLINE_SLOT :: V2f.{ 2, 12 };
S_OUTLINE_SLOT :: V2f.{ 3, 12 };
D_OUTLINE_SLOT :: V2f.{ 4, 15 };
Z_OUTLINE_SLOT :: V2f.{ 4, 14 };
C_OUTLINE_SLOT :: V2f.{ 4, 13 };
X_OUTLINE_SLOT :: V2f.{ 5, 15 };
E_OUTLINE_SLOT :: V2f.{ 6, 13 };
COIN_SLOT :: V2f.{ 4, 12 };
VOLUME_ON_SLOT :: V2f.{ 0, 11 };
VOLUME_OFF_SLOT :: V2f.{ 1, 11 };
KLAXON_SLOT :: V2f.{ 2, 11 };
LOCKED_SLOT :: V2f.{ 3, 11 };
UNLOCKED_SLOT :: V2f.{ 4, 11 };
BUBBLE_INDICATOR_SLOT :: V2f.{ 5, 14 };
BUBBLE_INDICATOR_SLOT_DOWN :: V2f.{ 5, 14 };
BUBBLE_INDICATOR_SLOT_LEFT :: V2f.{ 6, 14 };
BUBBLE_INDICATOR_SLOT_UP :: V2f.{ 7, 14 };
BUBBLE_INDICATOR_SLOT_RIGHT :: V2f.{ 8, 14 };
AWARD_SLOT :: V2f.{ 5, 13 };
REVIVE_SLOT :: V2f.{ 5, 12 };
DEATH_SLOT :: V2f.{ 5, 11 };
SCORE_SLOT :: V2f.{ 6, 11 };
SAFE_ZONE_SLOT :: V2f.{ 7, 15 };
HOOK_SLOT :: V2f.{ 8, 15 };

PLAYER_ICON_SLOT :: V2f.{ 0, 10 };
AMBULANCE_SLOT :: V2f.{ 0, 10 };
TAXI_SLOT :: V2f.{ 1, 10 };
POLICE_SLOT :: V2f.{ 2, 10 };
RACER_SLOT :: V2f.{ 3, 10 };
SPEEDSTER_SLOT :: V2f.{ 4, 10 };
DRAG_RACER_SLOT :: V2f.{ 5, 10 };
SPACESHIP_SLOT :: V2f.{ 6, 10 };
BOAT_FISHING_SLOT :: V2f.{ 7, 10 };
BOAT_ROW_SLOT :: V2f.{ 8, 10 };
MONSTER_TRUCK_SLOT :: V2f.{ 9, 10 };
SUV_SLOT :: V2f.{ 10, 10 };
BOAT_SAIL_SLOT :: V2f.{ 11, 10 };
TRACTOR_SLOT :: V2f.{ 12, 10 };

Key :: Platform.Key;

model_id_to_slot :: (id: Scene.Model_Id) -> V2f {
	if id == {
		case .Racer; return RACER_SLOT;
		case .SUV; return SUV_SLOT;
		case .Speedster; return SPEEDSTER_SLOT;
		case .Drag_Racer; return DRAG_RACER_SLOT;
		case .Monster_Truck; return MONSTER_TRUCK_SLOT;
		case .Boat_Row; return BOAT_ROW_SLOT;
		case .Boat_Fishing; return BOAT_FISHING_SLOT;
		case .Spaceship; return SPACESHIP_SLOT;
		case .Ambulance; return AMBULANCE_SLOT;
		case .Taxi; return TAXI_SLOT;
		case .Police; return POLICE_SLOT;
		case .Boat_Sail; return BOAT_SAIL_SLOT;
		case .Tractor; return TRACTOR_SLOT;
	}
	return QUESTION_SLOT;
}

#scope_export

IM_t :: struct {
	display_size: V2f;

	Quad :: struct {
		pos: V2f;
		size: V2f;
		color: V4f = .{ 1.0, 1.0, 1.0, 1.0 };
		z: float32 = 0;
		texture_rect: V4f = .{ 0, 0, 0, 0 };
		late := false;
	}
	quads: [..] Quad;

	Char :: struct {
		id: int;
		pos: V2f;
		color: V3f = .{ 1.0, 1.0, 1.0 };
		z: float32 = 0;
		height: float32 = 16;
	}
	chars: [..] Char;

	Checkbox :: struct {
		pos: V2f;
		size: V2f;
		checked: bool;
	}

	just_pressed: [Platform.Key_COUNT] bool;
	just_released: [Platform.Key_COUNT] bool;
	pressed: [Platform.Key_COUNT] bool;

	mouse_pos: V2f;

	handled_mouse := false;
}

IM: IM_t;
im_init :: () {
	IM = .{};
}

handle_frame_info :: (info: Platform.Frame_Info) {
	IM.handled_mouse = false;
	for * IM.just_pressed {
		if info.key_pressed[it_index] && !IM.pressed[it_index]
			it.* = true;
		else
			it.* = false;
	}
	for * IM.just_released {
		if !info.key_pressed[it_index] && IM.pressed[it_index]
			it.* = true;
		else
			it.* = false;
	}
	for * IM.pressed {
		it.* = info.key_pressed[it_index];
	}
	IM.mouse_pos.x = info.mouse_position.x;
	IM.mouse_pos.y = info.mouse_position.y;

	IM.display_size = info.window_size;
	IM.chars.count = 0;
	IM.quads.count = 0;
}

push_checkbox :: (
	center: V2f, size: float, checked: bool
) -> bool {
	push_quad_screen(center - V2f.{ size / 2, size / 2 }, V2f.{ size, size }, .{ 0, 0, 0 }, 0.0);
	color := V3f.{ 0.1, 0.1, 0.1 };
	if checked {
		color = .{ 0, 1, 0 };
	}
	push_quad_screen(
		center - V2f.{ size / 2 - 2, size / 2 - 2 }, V2f.{ size - 4, size - 4 }, color, -0.1
	);

	low := center - V2f.{ size / 2 - 1, size / 2 - 1 };
	high := center + V2f.{ size / 2 - 1, size / 2 - 1 };

	if point_aabb(IM.mouse_pos, low, high) {
		IM.handled_mouse = true;
		if IM.just_pressed[Key.MouseLeft] {
			return true;
		}
	}
	return false;
}

push_button :: (center: V2f, size: float, tex_slot: V2f, z := 0.0) -> bool {
	push_quad_texture(
		center - V2f.{ size / 2, size / 2 }, V2f.{ size, size }, .{ 1, 1, 1 }, tex_slot
	);

	low := center - V2f.{ size / 2, size / 2 };
	high := center + V2f.{ size / 2, size / 2 };

	if point_aabb(IM.mouse_pos, low, high) {
		IM.handled_mouse = true;
		if IM.just_pressed[Key.MouseLeft] {
			return true;
		}
	}
	return false;
}

push_quad :: (quad: IM.Quad) {
	array_add(*IM.quads, quad);
}
push_quad_screen :: (pos: V2f, size: V2f, color: V3f, z := 0.0) {
	quad: IM.Quad;
	// IM.display_size
	quad.pos.x = pos.x;
	quad.pos.y = pos.y;
	quad.size.x = size.x;
	quad.size.y = size.y;
	quad.color = .{ color.x, color.y, color.z, 1.0 };
	quad.z = z;

	array_add(*IM.quads, quad);
}
push_quad_texture :: (pos: V2f, size: V2f, color: V3f, tex_slot: V2f, z := 0.0) {
	quad: IM.Quad;
	// IM.display_size
	quad.pos.x = pos.x;
	quad.pos.y = pos.y;
	quad.size.x = size.x;
	quad.size.y = size.y;
	quad.color = .{ color.x, color.y, color.z, 1.0 };
	quad.texture_rect.x = tex_slot.x / 16.0;
	quad.texture_rect.y = tex_slot.y / 16.0;
	quad.texture_rect.z = 1.0 / 16.0;
	quad.texture_rect.w = 1.0 / 16.0;
	quad.z = z;

	array_add(*IM.quads, quad);
}

push_late_quad_screen :: (pos: V2f, size: V2f, color: V4f, z := 0.0) {
	quad: IM.Quad;
	// IM.display_size
	quad.pos.x = pos.x;
	quad.pos.y = pos.y;
	quad.size.x = size.x;
	quad.size.y = size.y;
	quad.color = color;
	quad.z = z;
	quad.late = true;

	array_add(*IM.quads, quad);
}

Text_Align :: enum {
	Left :: 0b01;
	Right :: 0b10;
	HCenter :: 0b11;
	Top :: 0b1000;
	Bottom :: 0b0100;
	VCenter :: 0b1100;
	Center :: 0b1111;
	Bottom_Left :: 0b0101;
	Bottom_Right :: 0b0110;
	Top_Left :: 0b1001;
	Top_Right :: 0b1010;
	Top_Center :: 0b1011;
	Center_Left :: 0b1101;
	Center_Right :: 0b1110;
}
push_text :: (
	text: string, pos: V2f, height := 12.0, z := 0.0, align := Text_Align.Bottom_Left
) -> V2f {
	x := pos.x;

	before := IM.chars.count;
	max_height := 0.0;
	H := MAIN_FONT.height.(float);
	H = height / H;
	for text {
		char: IM.Char;
		char.id = it - 0x20;
		char.pos.x = x;
		char.pos.y = pos.y;
		char.z = z;
		char.color = .{ 1, 1, 1 };
		char.height = height;

		sprite := MAIN_FONT.sprites[char.id];

		x += sprite.charAdvanceX * H;
		h := sprite.sourceHeight * H;

		max_height = max(max_height, h);
		array_add(*IM.chars, char);
	}

	for before..IM.chars.count-1 {
		char := *IM.chars[it];
		if (align & Text_Align.HCenter) == Text_Align.HCenter {
			char.pos.x -= (x - pos.x) / 2;
		}
		else if (align & Text_Align.Right) == Text_Align.Right {
			char.pos.x -= (x - pos.x);
		}
		if (align & Text_Align.VCenter) == Text_Align.VCenter {
			char.pos.y -= max_height/ 2;
		}
		else if (align & Text_Align.Top) == Text_Align.Bottom {
			char.pos.y -= max_height;
		}
	}

	return .{ x - pos.x, max_height };
}

push_fps_histogram :: (pos: V2f, size: V2f, data: [] float32, current_idx: int) {
	avg := 0.0;
	for data
		avg += it;
	avg /= data.count;

	fps_text := tprint("FPS: %, Avg %", (1.0 / data[current_idx]).(s64), (1.0 / avg).(s64));
	push_text(fps_text, .{ pos.x + 4, pos.y + size.y - 20 }, 16, z=11);

	push_quad_screen(
		pos = pos,
		size = size,
		color = .{ 0.0, 0.0, 0.0 },
		z = 10
	);

	project :: (x: float32) -> float32 #expand {
		return min((600 / (1 + exp(-x / 100)) - 300) / 300, 1.0) * size.y;
	}

	n := data.count;
	for data {
		fps := 1.0 / it;

		h := project(fps);
		w := size.x / data.count - 1;

		x := (it_index * size.x) / data.count;

		color := V3f.{ 1.0, 1.0, 1.0 };
		if it_index == current_idx {
			// Pink color
			color = V3f.{ 1.0, 0.0, 1.0 };
		}
		push_quad_screen(
			pos = .{ pos.x + x, pos.y + 5 },
			size = .{ w, h },
			color = color,
			z = 11
		);
	}

	{
		h := project(120);
		push_quad_screen(
			pos = .{ pos.x, pos.y + 5 + h },
			size = .{ size.x, 1 },
			color = .{ 0.0, 0.0, 1.0 },
			z = 12
		);
	}
	{
		h := project(60);
		push_quad_screen(
			pos = .{ pos.x, pos.y + 5 + h },
			size = .{ size.x, 1 },
			color = .{ 0.0, 1.0, 0.0 },
			z = 12
		);
	}
	{
		h := project(30);
		push_quad_screen(
			pos = .{ pos.x, pos.y + 5 + h },
			size = .{ size.x, 1 },
			color = .{ 1.0, 0.0, 0.0 },
			z = 12
		);
	}
}

push_ping_histogram :: (pos: V2f, size: V2f, data: [] float32, current_idx: int) {
	avg := 0.0;
	for data
		avg += it;
	avg /= data.count;

	fps_text := tprint("Ping: %, Avg % (ms)", (1000 * data[current_idx]).(s64), (1000 * avg).(s64));
	push_text(fps_text, .{ pos.x + 4, pos.y + size.y - 20 }, 16, z=11);

	push_quad_screen(
		pos = pos,
		size = size,
		color = .{ 0.0, 0.0, 0.0 },
		z = 10
	);

	project :: (x: float32) -> float32 #expand {
		return min(1.0, (600 / (1 + exp(-x / 100)) - 300) / 300) * size.y;
	}

	n := data.count;
	for data {
		h := project(1000 * it);
		w := size.x / data.count - 1;

		x := (it_index * size.x) / data.count;

		color := V3f.{ 1.0, 1.0, 1.0 };
		if it_index == current_idx {
			// Pink color
			color = V3f.{ 1.0, 0.0, 1.0 };
		}
		push_quad_screen(
			pos = .{ pos.x + x, pos.y + 5 },
			size = .{ w, h },
			color = color,
			z = 11
		);
	}

	{
		h := project(20);
		push_quad_screen(
			pos = .{ pos.x, pos.y + 5 + h },
			size = .{ size.x, 1 },
			color = .{ 0.0, 0.0, 1.0 },
			z = 12
		);
	}
	{
		h := project(80);
		push_quad_screen(
			pos = .{ pos.x, pos.y + 5 + h },
			size = .{ size.x, 1 },
			color = .{ 0.0, 1.0, 0.0 },
			z = 12
		);
	}
	{
		h := project(200);
		push_quad_screen(
			pos = .{ pos.x, pos.y + 5 + h },
			size = .{ size.x, 1 },
			color = .{ 1.0, 0.0, 0.0 },
			z = 12
		);
	}
}

push_end_screen :: (scene: Scene.Scene) {
	dt := to_float64_seconds(current_time_monotonic() - scene.end_scene_countdown_time);
	dt = scene.end_scene_countdown - dt;
	text := tprint("you have % seconds left to go through the gate !", ceil(dt).(s64));
	display_player_icon :: (player_id: int, p: V2f) #expand {
		player := Scene.find_by_player_id(scene, player_id);
		if !player
			return;
		push_quad_screen(
			pos = .{ p.x - 24 - 1, p.y - 24 - 1 },
			size = .{ 48 + 2, 48 + 2 },
			color = COLOR_HIGHLIGHT_A,
			z = 0
		);
		push_quad_screen(
			pos = .{ p.x - 24, p.y - 24 },
			size = .{ 48, 48 },
			color = COLOR_BRIGHT_A,
			z = 1
		);
		push_quad_texture(
			pos = .{ p.x - 24, p.y - 24 },
			size = .{ 48, 48 },
			color = .{ 1.0, 1.0, 1.0 },
			tex_slot = model_id_to_slot(xx player.server.model_id),
			z = 2
		);
	}

	cursor := V2f.{
		IM.display_size.x / 2, IM.display_size.y * 0.75
	};
	cursor.y -= push_text("Level cleared !", cursor, 48, align = .Center).y;
	cursor.y -= 8;
	push_text(text, cursor, 48, -0.5, align = .Center);

	push_text("Top 5 players on this level", V2f.{ 280, 374 }, 24);

	for scene.client.end_level.best_scores_id {
		display_player_icon(it, V2f.{ 280 + 32 + 64.0 * it_index, 374 - 48 });
	}

	push_text("Finisher", V2f.{ 762, 374 - 00 }, 24);
	display_player_icon(scene.client.end_level.winner_id, V2f.{ 762 + 196 + 12, 374 + 12 });

	push_text("Most deaths", V2f.{ 762, 374 - 64}, 24);
	display_player_icon(
		scene.client.end_level.most_death_id, V2f.{ 762 + 196 + 12, 374 - 64 + 12 }
	);

	push_text("Most resurrections", V2f.{ 762, 374 - 128 }, 24);
	display_player_icon(
		scene.client.end_level.most_revive_id, V2f.{ 762 + 196 + 12, 374 - 128 + 12 }
	);
}

push_score_tab :: (scene: Scene.Scene) {
	scoreboard_center := IM.display_size / 2;
	scoreboard_center.y += IM.display_size.y / 12;
	scoreboard_size := V2f.{ 600, 400 };
	header_height := 32.0;

	cursor := V2f.{
		scoreboard_center.x - scoreboard_size.x / 2,
		scoreboard_center.y - scoreboard_size.y / 2
	};

	push_quad_screen(
		pos = cursor,
		size = scoreboard_size,
		color = COLOR_BACK_A,
		z = 5
	);

	cursor += V2f.{ 0, scoreboard_size.y };
	push_quad_screen(
		pos = .{ cursor.x, cursor.y - header_height },
		size = .{ scoreboard_size.x, header_height },
		color = COLOR_SOMBER_A,
		z = 6
	);

	push_text(
		"Scoreboard",
		.{ cursor.x + scoreboard_size.x / 2, cursor.y - header_height / 2 },
		24,
		z=7,
		align=Text_Align.Center
	);

	cursor -= V2f.{ 0, header_height };
	push_quad_screen(
		pos = .{ cursor.x, cursor.y - 1 },
		size = .{ scoreboard_size.x, 1 },
		color = .{ 1.0, 1.0, 1.0 },
		z = 7
	);

	scoreline_size := V2f.{ scoreboard_size.x / 2, 48 };

	push_scoreline :: (x: float, y: float, player: Scene.Player) #expand {
		cursor := scoreboard_center;
		cursor.x -= scoreboard_size.x / 2;
		cursor.y += scoreboard_size.y / 2;
		cursor.y -= header_height + 1;
		cursor.x += x * scoreline_size.x;
		cursor.y -= (y + 1) * scoreline_size.y;

		model_size :: V2f.{ 48, 48 };
		icon_size :: V2f.{ 24, 24 };

		push_quad_screen(
			pos = cursor,
			size = scoreline_size,
			color = COLOR_HIGHLIGHT_A,
			z = 10
		);
		push_quad_screen(
			pos = .{ cursor.x + 1, cursor.y + 1 },
			size = .{ scoreline_size.x - 2, scoreline_size.y - 2 },
			color = COLOR_BACK_A,
			z = 11
		);

		push_quad_texture(
			pos = .{ cursor.x + 4, cursor.y + (scoreline_size.y - model_size.y) / 2 },
			size = model_size,
			color = .{ 1.0, 1.0, 1.0 },
			tex_slot = model_id_to_slot(xx player.server.model_id),
			z = 12
		);

		cursor.x += 16;

		push_quad_texture(
			pos = .{
				cursor.x + 4 + model_size.x + 4,
				cursor.y + (scoreline_size.y - icon_size.y) / 2
			},
			size = icon_size,
			color = .{ 1.0, 1.0, 1.0 },
			tex_slot = AWARD_SLOT,
			z = 12
		);
		push_text(
			tprint("%", player.server.score.trophy),
			.{ cursor.x + 4 + model_size.x + 32, cursor.y + scoreline_size.y / 2 },
			height = 18,
			z = 12,
			align = Text_Align.Center_Left
		);

		push_quad_texture(
			pos = .{
				cursor.x + model_size.x + 4 + 32 + icon_size.x + 4,
				cursor.y + (scoreline_size.y - icon_size.y) / 2
			},
			size = icon_size,
			color = .{ 1.0, 1.0, 1.0 },
			tex_slot = REVIVE_SLOT,
			z = 12
		);
		push_text(
			tprint("%", player.server.score.revive),
			.{
				cursor.x + 4 + model_size.x + 32 + icon_size.x + 32,
				cursor.y + scoreline_size.y / 2
			},
			height = 18,
			z = 12,
			align = Text_Align.Center_Left
		);

		push_quad_texture(
			pos = .{
				cursor.x + model_size.x + 4 + 32 + icon_size.x + 4 + 32 + icon_size.x + 4,
				cursor.y + (scoreline_size.y - icon_size.y) / 2
			},
			size = icon_size,
			color = .{ 1.0, 1.0, 1.0 },
			tex_slot = DEATH_SLOT,
			z = 12
		);
		push_text(
			tprint("%", player.server.score.dead),
			.{
				cursor.x + 4 + model_size.x + 32 + icon_size.x + 32 + icon_size.x + 32,
				cursor.y + scoreline_size.y / 2
			},
			height = 18,
			z = 12,
			align = Text_Align.Center_Left
		);

		push_quad_texture(
			pos = .{
				cursor.x + model_size.x + 4 + 32 + icon_size.x + 4 + 32 + icon_size.x + 32 + icon_size.x + 4,
				cursor.y + (scoreline_size.y - icon_size.y) / 2
			},
			size = icon_size,
			color = .{ 1.0, 1.0, 1.0 },
			tex_slot = SCORE_SLOT,
			z = 12
		);
		push_text(
			tprint("%", player.server.score.score),
			.{
				cursor.x + 4 + model_size.x + 32 + icon_size.x + 32 + icon_size.x + 32 + icon_size.x + 32,
				cursor.y + scoreline_size.y / 2
			},
			height = 18,
			z = 12,
			align = Text_Align.Center_Left
		);
	}

	for scene.players {
		x := it_index / 8;
		y := it_index % 8;
		push_scoreline(x.(float32), y.(float32), it);
	}
}

push_death_indicator :: (scene: Scene.Scene) {
	V := Scene.look_at(scene.camera.position, scene.camera.target, .{ 0, 0, 1 });
	P := Scene.perspective(scene.camera);

	// V * <world> = <view>
	// P * <view> = <clip>

	for scene.players {
		if it.server.dead && it.id != scene.controlled_player_id {
			p := v4(it.server.position, 1);
			p = V * p;
			p = P * p;
			p /= abs(p.w);

			if -1.0 <= p.x && p.x <= 1.0 && -1.0 <= p.y && p.y <= 1.0 // On screen
				continue;

			p2 := closest_aabb(V2f.{ p.x, p.y }, .{ -1.0, -1.0 }, .{ 1.0, 1.0 });
			indicator := BUBBLE_INDICATOR_SLOT_UP;
			indicator_dt := V2f.{ 0, 0 };
			{
				dx := p.x - p2.x;
				dy := p.y - p2.y;
				if abs(dx) > abs(dy)
					if dx < 0 {
						indicator = BUBBLE_INDICATOR_SLOT_LEFT;
						indicator_dt = V2f.{ -5, 0 };
					}
					else {
						indicator = BUBBLE_INDICATOR_SLOT_RIGHT;
						indicator_dt = V2f.{ 5, 0 };
					}
				else
					if dy < 0 {
						indicator = BUBBLE_INDICATOR_SLOT_DOWN;
						indicator_dt = V2f.{ 0, -5 };
					}
					else {
						indicator = BUBBLE_INDICATOR_SLOT_UP;
						indicator_dt = V2f.{ 0, 5 };
					}
			}

			screen_p2: V2f;
			screen_p2.x = p2.x * (IM.display_size.x - 50) / 2 + IM.display_size.x / 2;
			screen_p2.y = p2.y * (IM.display_size.y - 50) / 2 + IM.display_size.y / 2;

			// Check if too close to the bottom left ui palette
			action_palette_safety := V2f.{ 168 + 25, 168 + 25 };
			if screen_p2.x < action_palette_safety.x && screen_p2.y < action_palette_safety.y {
				dx := abs(screen_p2.x - action_palette_safety.x);
				dy := abs(screen_p2.y - action_palette_safety.y);
				if dx < dy
					screen_p2.x = action_palette_safety.x;
				else
					screen_p2.y = action_palette_safety.y;
			}

			push_quad_texture(
				pos = screen_p2 - V2f.{ 24, 24 } + indicator_dt,
				size = V2f.{ 48, 48 },
				tex_slot = indicator,
				color = .{ 1.0, 1.0, 1.0 },
				z = 19
			);

			push_quad_texture(
				pos = screen_p2 - V2f.{ 20, 20 },
				size = V2f.{ 40, 40 },
				tex_slot = model_id_to_slot(xx it.server.model_id),
				color = .{ 0.3, 0.3, 0.3 },
				z = 20
			);
		}
	}
}


COLOR_SOMBER_A :: V3f.{ 5/255.0, 107/255.0, 150/255.0 };
COLOR_BRIGHT_A :: V3f.{ 25/255.0, 159/255.0, 215/255.0 };
COLOR_HIGHLIGHT_A :: V3f.{ 54/255.0, 189/255.0, 247/255.0 };
COLOR_BACK_A :: V3f.{ 3/255.0, 60/255.0, 84/255.0 };

push_action_palette :: (scene: Scene.Scene, info: *Platform.Frame_Info) {

	push_quad_screen(
		pos = .{ 0, 0 },
		size = .{ 168, 168 },
		color = .{ 218/255.0, 220/255.0, 231/255.0 },
		1
	);

	render_square_at :: (x: int, y: int, key_code: int) #expand {
		color := COLOR_BRIGHT_A;
		if info.key_pressed[xx key_code]
			color = COLOR_HIGHLIGHT_A;
		push_quad_screen(
			pos = .{ x * 42.0 + 1, y * 42.0 + 1 },
			size = .{ 40, 40 },
			color = color,
			z = 2
		);
	}
	render_square_at(0, 0, xx Platform.Key.W);
	render_square_at(1, 0, xx Platform.Key.X);
	render_square_at(2, 0, xx Platform.Key.C);
	render_square_at(3, 0, xx Platform.Key.V);
	render_square_at(0, 1, xx Platform.Key.Q);
	render_square_at(1, 1, xx Platform.Key.S);
	render_square_at(2, 1, xx Platform.Key.D);
	render_square_at(3, 1, xx Platform.Key.F);
	render_square_at(0, 2, xx Platform.Key.A);
	render_square_at(1, 2, xx Platform.Key.Z);
	render_square_at(2, 2, xx Platform.Key.E);
	render_square_at(3, 2, xx Platform.Key.R);
	render_square_at(0, 3, xx Platform.Key._1);
	render_square_at(1, 3, xx Platform.Key._2);
	render_square_at(2, 3, xx Platform.Key._3);
	render_square_at(3, 3, xx Platform.Key._4);

	render_texture_at :: (x: int, y: int, tex_slot: V2f, color := V3f.{ 1.0, 1.0, 1.0 }) {
		push_quad_texture(
			pos = .{ (x * 42 + 4).(float32), (y * 42 + 4).(float32) },
			size = .{ 34, 34 },
			tex_slot = tex_slot,
			color = color,
			z = 3
		);
	}
	render_hint_at :: (x: int, y: int, tex_slot: V2f) {
		push_quad_texture(
			pos = .{ (x * 42 + 42 - 18).(float32), (y * 42 + 42 - 18).(float32) },
			size = .{ 18, 18 },
			tex_slot = tex_slot,
			color = .{ 1.0, 1.0, 1.0 },
			z = 4
		);
	}

	render_texture_at(0, 1, LEFT_SLOT);
	render_hint_at(0, 1, Q_OUTLINE_SLOT);

	render_texture_at(1, 1, DOWN_SLOT);
	render_hint_at(1, 1, S_OUTLINE_SLOT);

	render_texture_at(2, 1, RIGHT_SLOT);
	render_hint_at(2, 1, D_OUTLINE_SLOT);

	render_texture_at(1, 2, UP_SLOT);
	render_hint_at(1, 2, Z_OUTLINE_SLOT);
	
	render_texture_at(2, 0, COIN_SLOT);
	render_hint_at(2, 0, C_OUTLINE_SLOT);

	render_texture_at(1, 0, KLAXON_SLOT);
	render_hint_at(1, 0, X_OUTLINE_SLOT);

	if scene.camera_locked
		render_texture_at(0, 0, UNLOCKED_SLOT);
	else
		render_texture_at(0, 0, LOCKED_SLOT);
	render_hint_at(0, 0, W_OUTLINE_SLOT);

	player := Scene.find_by_player_id(scene, scene.controlled_player_id);
	if player {
		if player.server.has_safe_present {
			render_texture_at(2, 2, SAFE_ZONE_SLOT, .{ 0.5, 1.0, 0.5 });
			render_hint_at(2, 2, E_OUTLINE_SLOT);
		}
		if player.server.has_hook_present {
			render_texture_at(0, 2, HOOK_SLOT, .{ 0.5, 1.0, 0.5 });
			render_hint_at(0, 2, A_OUTLINE_SLOT);

			for 0..player.server.has_hook_present-1 {
				push_quad_screen(
					pos = .{ (0 * 42 + 3 + it * 6).(float32), (2 * 42 + 3).(float32) },
					size = .{ 4, 4 },
					color = .{ 1.0, 1.0, 1.0 },
					z = 5
				);
			}
		}
	}
}

push_settings :: (volume: *bool, info: *Platform.Frame_Info) {
	if volume.* {
		if push_button(
			.{ info.window_size.x - 16, info.window_size.y - 16 },
			16,
			VOLUME_ON_SLOT,
			1
		)
			volume.* = false;
	} else {
		if push_button(
			.{ info.window_size.x - 16, info.window_size.y - 16 },
			16,
			VOLUME_OFF_SLOT,
			1
		)
			volume.* = true;
	}
}
