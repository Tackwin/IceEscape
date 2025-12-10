#scope_file
Platform :: #import "Platform";
Controls :: #import "Controls";
Scene :: #import "Scene";
#import "Basic";
#import "String";
#import "Math";
#import "Store";
#import "Algebra";
#import "Assets";
#import "Hash_Table";
#import "Sort";
#import "Hash";
#import "Reflection";

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
R_OUTLINE_SLOT :: V2f.{ 7, 13 };
V_OUTLINE_SLOT :: V2f.{ 8, 13 };
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
HAND_OPEN_SLOT :: V2f.{ 6, 12 };
STAR_SLOT :: V2f.{ 7, 12 };
RESURRECT_SLOT :: V2f.{ 7, 11 };

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

GUI_State :: struct {
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
		size: V2f;
		color: V4f = .{ 1.0, 1.0, 1.0, 1.0 };
		z: float32 = 0;
		outline := false;
	}
	chars: [..] Char;

	Checkbox :: struct {
		pos: V2f;
		size: V2f;
		checked: bool;
	}

	// just_pressed: [Platform.Key_COUNT] bool;
	// just_released: [Platform.Key_COUNT] bool;
	// pressed: [Platform.Key_COUNT] bool;

	// mouse_pos: V2f;
	// window_size: V2f;

	controls: Controls.State;

	handled_mouse := false;

	main_font: *Platform.Font;

	Widget :: struct {
		id: u64;
		z: float32;

		user: *void;
		user_size := 0;

		touched := false;

		aabb: AABBf;

		Physical :: enum {
			Empty       :: 0b000;

			Mouse_Left  :: 0b001;
			Mouse_Right :: 0b010;
			Mouse       :: 0b011;

			Keyboard    :: 0b100;

			Solid       :: 0b111;
		}
		physical: Physical = .Empty;

		hovered := false;
		pressed := false;
		released := false;
		just_pressed := false;

		keyboard_focused := false;
	}
	widgets: Table(u64, Widget);

	id_stack: [..] u64;
}

combine_id :: (a: u64, b: u64) -> u64 {
	return a ^ (b + 0x9e3779b97f4a7c15 + (a << 12) + (a >> 4));
}

string_id :: (text: string) -> u64 {
	hash := fnv1a_hash(text.data, text.count);
	return hash;
}

gui_state_init :: (state: *GUI_State, store: *Store) {
	state.* = .{};
	state.main_font = *store.verdana;
}

last_id :: (state: *GUI_State) -> u64 {
	if state.id_stack.count > 0 {
		return state.id_stack[state.id_stack.count - 1];
	}
	return 0;
}
push_id :: (state: *GUI_State, id: u64) {
	array_add(*state.id_stack, combine_id(last_id(state), id));
}
push_id :: (state: *GUI_State, id: s64) {
	array_add(*state.id_stack, combine_id(last_id(state), id.(u64)));
}
push_id :: (state: *GUI_State, id: string) {
	array_add(*state.id_stack, combine_id(last_id(state), string_id(id)));
}
pop_id :: (state: *GUI_State) {
	assert(state.id_stack.count > 0);
	state.id_stack.count -= 1;
}

widget_aabb ::(state: *GUI_State, id: $Id) -> AABBf
#modify {
	if Id == u64 || Id == s64 || Id == string {
		return true;
	}
	return false;
}
{
	#if Id == string {
		iid := string_id(id);
	} else {
		iid := cast(u64) id;
	}
	widget := table_find_pointer(*state.widgets, combine_id(last_id(state), iid));
	if widget {
		return widget.aabb;
	}
	return AABBf.{};
}

widget_width :: (state: *GUI_State, id: $Id) -> float
#modify {
	if Id == u64 || Id == s64 || Id == string {
		return true;
	}
	return false;
}
{
	aabb := widget_aabb(state, id);
	return aabb.max.x - aabb.min.x;
}

widget :: (state: *GUI_State, raw_id: $Id, $T: Type, default: T = .{}) -> *T, *GUI_State.Widget
#modify {
	if Id == u64 || Id == s64 || Id == string {
		return true;
	}
	return false;
}
{
	#if Id == string {
		id := string_id(raw_id);
	} else {
		id := cast(u64) raw_id;
	}

	iid := combine_id(last_id(state), id);

	user_state := table_find_pointer(*state.widgets, iid);
	if user_state {
		if user_state.user_size == size_of(T) {
			user_state.touched = true;
			return user_state.user.(*T), user_state;
		}
	}

	widget_state: GUI_State.Widget;
	widget_state.id = iid;
	widget_state.user = New(T);
	widget_state.user.(*T).* = default;
	widget_state.user_size = size_of(T);
	widget_state.touched = true;
	user_state = table_set(*state.widgets, iid, widget_state);
	return widget_state.user.(*T), user_state;
}

widget_sized :: (
	state: *GUI_State,
	id: $Id,
	$T: Type,
	aabb: AABBf,
	z := 0.0,
	physical : GUI_State.Widget.Physical = .Solid,
	default: T = .{}
) -> *T
#modify {
	if Id == u64 || Id == s64 || Id == string {
		return true;
	}
	return false;
}
{
	widget_user, widget := widget(state, id, T, default);
	widget.aabb = aabb;
	widget.z = z;
	widget.physical = physical;

	return widget_user, widget;
}

gc_user_state :: (state: *GUI_State) {
	for * value, key: state.widgets {
		if !value.touched {
			remove key;
			continue;
		}
		value.touched = false;
	}
}

// The gui will process all user input one frame before the rest of the game. So that we have a
// chance to press a button, before clicking on the terrain.
// That means that at the beggining of the frame, we copy the previous frame info into the control
// state, WITH the captured flags filled out from the state of the gui at the last frame.
// BUT the gui will take the current frame info.
begin_frame :: (state: *GUI_State, info: Platform.Frame_Info, out_controls: *Controls.State) {
	// Copy controls from previous frame to out_controls
	out_controls.* = state.controls;

	// Update gui state from current frame info
	for * state.controls.just_pressed {
		it.* = info.key_pressed[it_index] && !state.controls.pressed[it_index];
	}
	for * state.controls.just_released {
		it.* = !info.key_pressed[it_index] && state.controls.pressed[it_index];
	}
	for * state.controls.pressed {
		it.* = info.key_pressed[it_index];
	}
	state.controls.mouse_pos.x = info.mouse_position.x;
	state.controls.mouse_pos.y = info.mouse_position.y;
	state.controls.mouse_wheel = info.mouse_wheel;
	state.controls.window_size.x = info.window_size.x;
	state.controls.window_size.y = info.window_size.y;

	// Reset the captured flags for the frame that is about to start
	state.controls.captured_keyboard = false;
	state.controls.captured_mouse = false;
	state.controls.delta_time = info.delta_time;

	state.chars.count = 0;
	state.quads.count = 0;

	gc_user_state(state);

	// Now we will traverse all widgets, and handdle mouse action on them. In reverse z order.
	Pair :: struct {
		id: u64;
		z: float32;
	}
	widget_ids := NewArray(state.widgets.count, Pair,, temp);
	widget_ids.count = 0;
	for w, id: state.widgets {
		widget_ids.count += 1;
		widget_ids[widget_ids.count - 1].id = id;
		widget_ids[widget_ids.count - 1].z = w.z;
	}

	quick_sort(widget_ids, (pair) => -pair.z );

	met_keyboard_focused := false;

	for widget_ids {
		widget := table_find_pointer(*state.widgets, it.id);
		if !widget
			continue;

		if widget.physical == .Empty
			continue;

		if area(widget.aabb) == 0
			continue;

		before_pressed := widget.pressed;
		defer if !before_pressed && widget.pressed {
			widget.just_pressed = true;
		}

		widget.hovered = false;
		widget.pressed = false;
		widget.released = false;
		widget.just_pressed = false;

		if met_keyboard_focused
			widget.keyboard_focused = false;
		if widget.keyboard_focused
			met_keyboard_focused = true;

		defer {
			state.controls.captured_mouse |= widget.pressed;
			state.controls.captured_mouse |= widget.released;
		}

		if in(widget.aabb, state.controls.mouse_pos) {
			widget.hovered = (widget.physical & .Mouse) != .Empty;

			if !state.controls.captured_mouse {
				if widget.physical & .Mouse_Left {
					if state.controls.pressed[Key.MouseLeft] {
						widget.pressed = true;
					}
					if state.controls.just_pressed[Key.MouseLeft] {
						widget.just_pressed = true;
					}
					if (state.controls.just_released[Key.MouseLeft]) {
						widget.released = true;
					}
				}

				if widget.physical & .Mouse_Right {
					if state.controls.pressed[Key.MouseRight] {
						widget.pressed = true;
					}
					if state.controls.just_pressed[Key.MouseRight] {
						widget.just_pressed = true;
					}
					if (state.controls.just_released[Key.MouseRight]) {
						widget.released = true;
					}
				}
			}
		}
	}

	state.controls.captured_keyboard = met_keyboard_focused;
}


push_checkbox :: (
	state: *GUI_State, center: V2f, size: float, checked: bool
) -> bool {
	push_quad_screen(
		state, center - V2f.{ size / 2, size / 2 }, V2f.{ size, size }, .{ 0, 0, 0 }, 0.0
	);
	color := V3f.{ 0.1, 0.1, 0.1 };
	if checked {
		color = .{ 0, 1, 0 };
	}
	push_quad_screen(
		state, center - V2f.{ size / 2 - 2, size / 2 - 2 }, V2f.{ size - 4, size - 4 }, color, -0.1
	);

	low := center - V2f.{ size / 2 - 1, size / 2 - 1 };
	high := center + V2f.{ size / 2 - 1, size / 2 - 1 };

	if point_aabb(state.mouse_pos, low, high) {
		state.handled_mouse = true;
		if state.just_pressed[Key.MouseLeft] {
			return true;
		}
	}
	return false;
}

push_button :: (state: *GUI_State, center: V2f, size: float, tex_slot: V2f, z := 0.0) -> bool {
	push_quad_texture(
		state,
		center - V2f.{ size / 2, size / 2 }, V2f.{ size, size }, .{ 1, 1, 1 }, tex_slot
	);

	low := center - V2f.{ size / 2, size / 2 };
	high := center + V2f.{ size / 2, size / 2 };

	if point_aabb(state.controls.mouse_pos, low, high) {
		state.controls.captured_mouse = true;
		if state.controls.just_pressed[Key.MouseLeft] {
			return true;
		}
	}
	return false;
}

push_quad :: (state: *GUI_State, quad: state.Quad) {
	array_add(*state.quads, quad);
}
push_quad_screen :: (state: *GUI_State, aabb: AABBf, color: V3f, z := 0.0, a := 1.0) {
	push_quad_screen(
		state,
		pos = .{ aabb.min.x, aabb.min.y },
		size = .{ aabb.max.x - aabb.min.x, aabb.max.y - aabb.min.y },
		color = color,
		z = z,
		a = a
	);
}
push_quad_screen :: (state: *GUI_State, pos: V2f, size: V2f, color: V3f, z := 0.0, a := 1.0) {
	quad: state.Quad;
	// state.display_size
	quad.pos.x = pos.x;
	quad.pos.y = pos.y;
	quad.size.x = size.x;
	quad.size.y = size.y;
	quad.color = .{ color.x, color.y, color.z, a };
	quad.z = z;

	array_add(*state.quads, quad);
}
push_quad_texture :: (state: *GUI_State, pos: V2f, size: V2f, color: V3f, tex_slot: V2f, z := 0.0) {
	quad: state.Quad;
	// state.display_size
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

	array_add(*state.quads, quad);
}

push_late_quad_screen :: (state: *GUI_State, pos: V2f, size: V2f, color: V4f, z := 0.0) {
	quad: state.Quad;
	// state.display_size
	quad.pos.x = pos.x;
	quad.pos.y = pos.y;
	quad.size.x = size.x;
	quad.size.y = size.y;
	quad.color = color;
	quad.z = z;
	quad.late = true;

	array_add(*state.quads, quad);
}

Align :: enum {
	Left :: 0b01;
	Right :: 0b10;
	HCenter :: 0b11;
	Top :: 0b1000;
	Bottom :: 0b0100;
	VCenter :: 0b1100;
	Center :: 0b1111;
	Bottom_Left :: 0b0101;
	Bottom_Right :: 0b0110;
	Bottom_Center :: 0b0111;
	Top_Left :: 0b1001;
	Top_Right :: 0b1010;
	Top_Center :: 0b1011;
	Center_Left :: 0b1101;
	Center_Right :: 0b1110;
}

vertical :: (align: Align) -> Align {
	return align & 0b1100;
}
horizontal :: (align: Align) -> Align {
	return align & 0b0011;
}

push_text :: (
	state: *GUI_State,
	text: string,
	pos: V2f,
	height := 12.0,
	z := 0.0,
	align := Align.Bottom_Left,
	color := V4f.{ 1, 1, 1, 1 }
) -> V2f {
	return .{};
	// x := pos.x;

	// before := state.chars.count;
	// max_height := 0.0;
	// H := state.main_font.height.(float);
	// H = height / H;
	// for text {
	// 	char: state.Char;
	// 	char.id = it - 0x20;
	// 	char.pos.x = x;
	// 	char.pos.y = pos.y;
	// 	char.z = z;
	// 	char.color = color;
	// 	char.height = height;

	// 	sprite := state.main_font.sprites[char.id];

	// 	x += sprite.charAdvanceX * H;
	// 	h := sprite.sourceHeight * H;

	// 	max_height = max(max_height, h);
	// 	array_add(*state.chars, char);
	// }

	// for before..state.chars.count-1 {
	// 	char := *state.chars[it];
	// 	if (align & Align.HCenter) == Align.HCenter {
	// 		char.pos.x -= (x - pos.x) / 2;
	// 	}
	// 	else if (align & Align.Right) == Align.Right {
	// 		char.pos.x -= (x - pos.x);
	// 	}
	// 	if (align & Align.VCenter) == Align.VCenter {
	// 		char.pos.y -= max_height/ 2;
	// 	}
	// 	else if (align & Align.Top) == Align.Bottom {
	// 		char.pos.y -= max_height;
	// 	}
	// }

	// return .{ x - pos.x, max_height };
}

push_buy_prompt :: (state: *GUI_State, scene: *Scene.Scene) {
	V := Scene.look_at(scene.camera.position, scene.camera.target, .{ 0, 0, 1 });
	P := Scene.perspective(scene.camera);

	player := Scene.find_by_player_id(scene, scene.controlled_player_id);
	if player && !player.server.dead {
		p := player.client.position;
		for * present: scene.presents {
			if present.server.available {
				q := present.position;

				needed := 1;
				if present.kind == .B
					needed = 2;

				d := norm(p - q);
				if d < player.server.radius_hitbox_key {
					
					prompt := tprint("Not enough points (%) ! Revive your friends !", needed);
					if player.server.score.points >= needed {
						prompt = tprint("R to buy. % points.", needed);
					}

					pos := v4(q, 1);
					pos = V * pos;
					pos = P * pos;
					pos /= abs(pos.w);
					screen_p: V2f;
					screen_p.x =
						pos.x * (state.controls.window_size.x) / 2 +
						state.controls.window_size.x / 2;
					screen_p.y =
						pos.y * (state.controls.window_size.y) / 2 +
						state.controls.window_size.y / 2;

					push_text(state, prompt, screen_p, 24, z=10, align = .Center);
				}
			}
		}
	}
}

push_breaking_news :: (state: *GUI_State, news: [] Scene.Breaking_News) {
	cursor := V2f.{ state.controls.window_size.x / 2, state.controls.window_size.y - 16};
	for news {
		t := to_float64_seconds(current_time_monotonic() - it.time).(float);
		t = clamp(t / 5, 0.0, 1.0);

		alpha := 1.0 - t;
		text := tprint("NEWS: %", it.text);
		text_size := push_text(
			state,
			text,
			.{ cursor.x, cursor.y },
			20,
			z = 20,
			align = Align.Top_Center,
			color = V4f.{ 1.0, 1.0, 1.0, alpha }
		);
		cursor.y -= text_size.y + 4;
	}
}

push_fps_histogram :: (state: *GUI_State, pos: V2f, size: V2f, data: [] float32, current_idx: int) {
	avg := 0.0;
	for data
		avg += it;
	avg /= data.count;

	fps_text := tprint("FPS: %, Avg %", (1.0 / data[current_idx]).(s64), (1.0 / avg).(s64));
	atom_label(state, fps_text, .{ pos.x + 4, pos.y + size.y - 20 }, 16, z=11);

	push_quad_screen(
		state,
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
			state,
			pos = .{ pos.x + x, pos.y + 5 },
			size = .{ w, h },
			color = color,
			z = 11
		);
	}

	{
		h := project(120);
		push_quad_screen(
			state,
			pos = .{ pos.x, pos.y + 5 + h },
			size = .{ size.x, 1 },
			color = .{ 0.0, 0.0, 1.0 },
			z = 12
		);
	}
	{
		h := project(60);
		push_quad_screen(
			state,
			pos = .{ pos.x, pos.y + 5 + h },
			size = .{ size.x, 1 },
			color = .{ 0.0, 1.0, 0.0 },
			z = 12
		);
	}
	{
		h := project(30);
		push_quad_screen(
			state,
			pos = .{ pos.x, pos.y + 5 + h },
			size = .{ size.x, 1 },
			color = .{ 1.0, 0.0, 0.0 },
			z = 12
		);
	}
}

push_ping_histogram :: (state: *GUI_State, pos: V2f, size: V2f, data: [] float32, current_idx: int) {
	avg := 0.0;
	for data
		avg += it;
	avg /= data.count;

	fps_text := tprint("Ping: %, Avg % (ms)", (1000 * data[current_idx]).(s64), (1000 * avg).(s64));
	atom_label(state, fps_text, .{ pos.x + 4, pos.y + size.y - 20 }, 16, z=11);

	push_quad_screen(
		state,
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
			state,
			pos = .{ pos.x + x, pos.y + 5 },
			size = .{ w, h },
			color = color,
			z = 11
		);
	}

	{
		h := project(20);
		push_quad_screen(
			state,
			pos = .{ pos.x, pos.y + 5 + h },
			size = .{ size.x, 1 },
			color = .{ 0.0, 0.0, 1.0 },
			z = 12
		);
	}
	{
		h := project(80);
		push_quad_screen(
			state,
			pos = .{ pos.x, pos.y + 5 + h },
			size = .{ size.x, 1 },
			color = .{ 0.0, 1.0, 0.0 },
			z = 12
		);
	}
	{
		h := project(200);
		push_quad_screen(
			state,
			pos = .{ pos.x, pos.y + 5 + h },
			size = .{ size.x, 1 },
			color = .{ 1.0, 0.0, 0.0 },
			z = 12
		);
	}
}

push_point_ui :: (state: *GUI_State, player: Scene.Player) {
	cursor := V2f.{ 12, state.controls.window_size.y - 80 };

	push_quad_texture(
		state,
		pos = .{ cursor.x, cursor.y },
		size = .{ 24, 24 },
		color = .{ 1.0, 1.0, 1.0 },
		tex_slot = STAR_SLOT,
		z = 2
	);
	size := push_text(
		state,
		tprint("%", player.server.score.points),
		cursor + V2f.{ 32, 12 },
		24,
		1,
		align = .Center
	);
	cursor.y -= 1;
	cursor.x -= 1;

	push_quad_screen(
		state,
		cursor,
		V2f.{ 32 + size.x + 2, 26 },
		COLOR_BRIGHT_A,
		0,
	);
}

push_end_screen :: (state: *GUI_State, scene: Scene.Scene) {
	dt := to_float64_seconds(current_time_monotonic() - scene.end_scene_countdown_time);
	dt = scene.end_scene_countdown - dt;
	text := tprint("you have % seconds left to go through the gate !", ceil(dt).(s64));
	display_player_icon :: (player_id: int, p: V2f) #expand {
		player := Scene.find_by_player_id(scene, player_id);
		if !player
			return;
		push_quad_screen(
			state,
			pos = .{ p.x - 24 - 1, p.y - 24 - 1 },
			size = .{ 48 + 2, 48 + 2 },
			color = COLOR_HIGHLIGHT_A,
			z = 0
		);
		push_quad_screen(
			state,
			pos = .{ p.x - 24, p.y - 24 },
			size = .{ 48, 48 },
			color = COLOR_BRIGHT_A,
			z = 1
		);
		push_quad_texture(
			state,
			pos = .{ p.x - 24, p.y - 24 },
			size = .{ 48, 48 },
			color = .{ 1.0, 1.0, 1.0 },
			tex_slot = model_id_to_slot(xx player.server.model_id),
			z = 2
		);
	}

	cursor := V2f.{
		state.controls.window_size.x / 2, state.controls.window_size.y * 0.75
	};
	cursor.y -= push_text(state, "Level cleared !", cursor, 48, align = .Center).y;
	cursor.y -= 8;
	push_text(state, text, cursor, 48, -0.5, align = .Center);

	push_text(state, "Top 5 players on this level", V2f.{ 280, 374 }, 24);
	for scene.client.end_level.best_scores_id {
		display_player_icon(it, V2f.{ 280 + 32 + 64.0 * it_index, 374 - 48 });
	}

	push_text(state, "Finisher", V2f.{ 762, 374 - 00 }, 24);
	display_player_icon(scene.client.end_level.winner_id, V2f.{ 762 + 196 + 12, 374 + 12 });

	push_text(state, "Most deaths", V2f.{ 762, 374 - 64}, 24);
	display_player_icon(
		scene.client.end_level.most_death_id, V2f.{ 762 + 196 + 12, 374 - 64 + 12 }
	);

	push_text(state, "Most resurrections", V2f.{ 762, 374 - 128 }, 24);
	display_player_icon(
		scene.client.end_level.most_revive_id, V2f.{ 762 + 196 + 12, 374 - 128 + 12 }
	);
}

push_score_tab :: (state: *GUI_State, scene: Scene.Scene) {
	scoreboard_center := state.controls.window_size / 2;
	scoreboard_center.y += state.controls.window_size.y / 12;
	scoreboard_size := V2f.{ 600, 400 };
	header_height := 32.0;

	cursor := V2f.{
		scoreboard_center.x - scoreboard_size.x / 2,
		scoreboard_center.y - scoreboard_size.y / 2
	};

	push_quad_screen(
		state,
		pos = cursor,
		size = scoreboard_size,
		color = COLOR_BACK_A,
		z = 5
	);

	cursor += V2f.{ 0, scoreboard_size.y };
	push_quad_screen(
		state,
		pos = .{ cursor.x, cursor.y - header_height },
		size = .{ scoreboard_size.x, header_height },
		color = COLOR_SOMBER_A,
		z = 6
	);

	push_text(
		state,
		"Scoreboard",
		.{ cursor.x + scoreboard_size.x / 2, cursor.y - header_height / 2 },
		24,
		z=7,
		align=Align.Center
	);

	cursor -= V2f.{ 0, header_height };
	push_quad_screen(
			state,
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
			state,
			pos = cursor,
			size = scoreline_size,
			color = COLOR_HIGHLIGHT_A,
			z = 10
		);
		push_quad_screen(
			state,
			pos = .{ cursor.x + 1, cursor.y + 1 },
			size = .{ scoreline_size.x - 2, scoreline_size.y - 2 },
			color = COLOR_BACK_A,
			z = 11
		);

		push_quad_texture(
			state,
			pos = .{ cursor.x + 4, cursor.y + (scoreline_size.y - model_size.y) / 2 },
			size = model_size,
			color = .{ 1.0, 1.0, 1.0 },
			tex_slot = model_id_to_slot(xx player.server.model_id),
			z = 12
		);

		cursor.x += 16;

		push_quad_texture(
			state,
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
			state,
			tprint("%", player.server.score.trophy),
			.{ cursor.x + 4 + model_size.x + 32, cursor.y + scoreline_size.y / 2 },
			height = 18,
			z = 12,
			align = Align.Center_Left
		);

		push_quad_texture(
			state,
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
			state,
			tprint("%", player.server.score.revive),
			.{
				cursor.x + 4 + model_size.x + 32 + icon_size.x + 32,
				cursor.y + scoreline_size.y / 2
			},
			height = 18,
			z = 12,
			align = Align.Center_Left
		);

		push_quad_texture(
			state,
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
			state,
			tprint("%", player.server.score.dead),
			.{
				cursor.x + 4 + model_size.x + 32 + icon_size.x + 32 + icon_size.x + 32,
				cursor.y + scoreline_size.y / 2
			},
			height = 18,
			z = 12,
			align = Align.Center_Left
		);

		push_quad_texture(
			state,
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
			state,
			tprint("%", player.server.score.score),
			.{
				cursor.x + 4 + model_size.x + 32 + icon_size.x + 32 + icon_size.x + 32 + icon_size.x + 32,
				cursor.y + scoreline_size.y / 2
			},
			height = 18,
			z = 12,
			align = Align.Center_Left
		);
	}

	for scene.players {
		x := it_index / 8;
		y := it_index % 8;
		push_scoreline(x.(float32), y.(float32), it);
	}
}

push_death_indicator :: (state: *GUI_State, scene: Scene.Scene) {
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
			screen_p2.x =
				p2.x * (state.controls.window_size.x - 50) / 2 + state.controls.window_size.x / 2;
			screen_p2.y =
				p2.y * (state.controls.window_size.y - 50) / 2 + state.controls.window_size.y / 2;

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
				state,
				pos = screen_p2 - V2f.{ 24, 24 } + indicator_dt,
				size = V2f.{ 48, 48 },
				tex_slot = indicator,
				color = .{ 1.0, 1.0, 1.0 },
				z = 19
			);

			push_quad_texture(
				state,
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

push_action_palette :: (state: *GUI_State, scene: Scene.Scene) {

	push_quad_screen(
		state,
		pos = .{ 0, 0 },
		size = .{ 168, 168 },
		color = .{ 218/255.0, 220/255.0, 231/255.0 },
		1
	);

	render_square_at :: (x: int, y: int, key_code: int) #expand {
		color := COLOR_BRIGHT_A;
		if state.controls.pressed[xx key_code]
			color = COLOR_HIGHLIGHT_A;
		push_quad_screen(
			state,
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

	render_texture_at :: (x: int, y: int, tex_slot: V2f, color := V3f.{ 1.0, 1.0, 1.0 }) #expand {
		push_quad_texture(
			state,
			pos = .{ (x * 42 + 4).(float32), (y * 42 + 4).(float32) },
			size = .{ 34, 34 },
			tex_slot = tex_slot,
			color = color,
			z = 3
		);
	}
	render_hint_at :: (x: int, y: int, tex_slot: V2f)  #expand {
		push_quad_texture(
			state,
			pos = .{ (x * 42 + 42 - 18).(float32), (y * 42 + 42 - 18).(float32) },
			size = .{ 18, 18 },
			tex_slot = tex_slot,
			color = .{ 1.0, 1.0, 1.0 },
			z = 5
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
					state,
					pos = .{ (0 * 42 + 3 + it * 6).(float32), (2 * 42 + 3).(float32) },
					size = .{ 4, 4 },
					color = .{ 1.0, 1.0, 1.0 },
					z = 6
				);
			}
		}

		if player.server.dead {
			render_texture_at(3, 0, RESURRECT_SLOT, .{ 0.5, 1.0, 0.5 });
			render_hint_at(3, 0, V_OUTLINE_SLOT);

			dt := to_float64_seconds(current_time_monotonic() - player.server.dead_time);
			t := clamp(dt / player.server.dead_cooldown, 0.0, 1.0).(float32);

			if t > 0 {
				push_quad_screen(
					state,
					pos = .{ 3 * 42.0 + 1, 0 * 42.0 + 1 + 40 * t },
					size = .{ 40, 40 * (1 - t) },
					color = COLOR_SOMBER_A,
					z = 3,
					a = 0.5
				);
			}
		}
	}

	
	render_texture_at(3, 2, HAND_OPEN_SLOT, .{ 0.5, 1.0, 0.5 });
	render_hint_at(3, 2, R_OUTLINE_SLOT);
}

push_settings :: (state: *GUI_State, volume: *bool) {
	if volume.* {
		if push_button(
			state,
			.{ state.controls.window_size.x - 16, state.controls.window_size.y - 16 },
			16,
			VOLUME_ON_SLOT,
			1
		)
			volume.* = false;
	} else {
		if push_button(
			state,
			.{ state.controls.window_size.x - 16, state.controls.window_size.y - 16 },
			16,
			VOLUME_OFF_SLOT,
			1
		)
			volume.* = true;
	}
}

Escape_Menu_Ret :: struct {
	resume_clicked := false;
	leave_instance_clicked := false;
}
push_escape_menu :: (state: *GUI_State) -> Escape_Menu_Ret {
	ret: Escape_Menu_Ret;
	push_id(state, "escape_menu");
	defer pop_id(state);

	push_quad_screen(state, .{ 0, 0 }, state.controls.window_size, v3(GRAY_00), z = 10, a = 0.5);
	state.controls.captured_mouse = true;
	state.controls.captured_keyboard = true;

	popup_size := widget(state, 1, V2f, .{ 100, 50 });
	pos := (state.controls.window_size - popup_size.*) / 2;

	push_quad_screen(
		state, pos, popup_size.*, v3(GRAY_10), z = 11
	);
	push_quad_screen(
		state, pos + v2(1.0), popup_size.* - v2(2.0), v3(GRAY_80), z = 11.1
	);

	popup_size.* = V2f.{ 0, 0 };
	grow :: (_size: V2f, from: V2f, to: V2f) -> V2f {
		size := _size;
		size.x = max(size.x, to.x - from.x);
		size.y = max(size.y, to.y - from.y);
		return size;
	}

	cursor := pos + v2(16.0, 24);
	_, resume_button := text_button(
		state,
		"Resume",
		cursor,
		id = "resume",
		align = .Center_Left,
		z = 12,
		size = .Small
	);
	cursor.x += widget_width(state, "resume") + 8.0;
	popup_size.* = grow(popup_size, pos, cursor);

	__, leave_button := text_button(
		state,
		"Leave Instance",
		cursor,
		id = "leave",
		align = .Center_Left,
		z = 12,
		size = .Small
	);
	cursor.x += widget_width(state, "leave") + 8.0;
	popup_size.* = grow(popup_size, pos, cursor);

	cursor.x = pos.x + 14.0;
	cursor.y += widget_width(state, "leave") + 8.0;

	sound_label := atom_label(
		state, "Sound", cursor, 16, z = 12, align = .Center_Left, color = V4f.{ 0, 0, 0, 1 }
	);
	cursor.x += sound_label.aabb_max.x - sound_label.aabb_min.x;
	sound_checkbox := checkbox(state, cursor - v2(0.0, 2.0), 16, z = 12, align = .Center_Left);

	cursor.y += (sound_label.aabb_max.y - sound_label.aabb_min.y) / 2 + 8;
	popup_size.* = grow(popup_size, pos, cursor);

	ret.resume_clicked = resume_button.clicked;
	ret.leave_instance_clicked = leave_button.clicked;

	return ret;
}

No_Connection_Ret :: struct {
	retry_clicked: bool;
	retry_localhost_clicked: bool;
}

push_no_connection :: (state: *GUI_State) -> No_Connection_Ret {
	ret: No_Connection_Ret;
	push_quad_screen(
		state,
		pos = .{ 0, 0 },
		size = state.controls.window_size,
		color = v3(GRAY_80),
		z = 0.01
	);
	atom_label(
		state,
		"No connection to the server :(",
		.{ state.controls.window_size.x / 2, state.controls.window_size.y / 2 + 24 },
		32,
		z=1,
		align = .Center,
		color = V4f.{ 0, 0, 0, 1 }
	);

	ret.retry_clicked = text_button(
		state,
		"Retry",
		.{ state.controls.window_size.x / 2, state.controls.window_size.y / 2 - 24 },
		1,
		align = .Center,
	);

	ret.retry_localhost_clicked = text_button(
		state,
		"Retry localhost",
		.{ state.controls.window_size.x / 2, state.controls.window_size.y / 2 - 72 },
		1,
		id = "retry_localhost",
		align = .Center,
	);
	
	
	return ret;
}

Instance_Info :: struct {
	name: string;
	auto_revive: bool;
	player_count: int;
	player_capacity: int;
	level_name: string;
	instance_id: int;
}

Main_Menu_Ret :: struct {
	reload_instances_clicked := false;
	enter_instance_clicked := false;
	create_instance_clicked := false;
	selected_instance_id := -1;
	localhost := false;
}

Main_Menu_Args :: struct {
	create_instance_popup_open := false;
	instances: []Instance_Info;
}

push_main_menu :: (
	state: *GUI_State,
	args: Main_Menu_Args
) -> Main_Menu_Ret {
	ret: Main_Menu_Ret;
	push_quad_screen(
		state,
		pos = .{ 0, 0 },
		size = state.controls.window_size,
		color = v3(GRAY_80),
		z = 0.01
	);

	atom_label(
		state,
		"Name game",
		.{ state.controls.window_size.x / 2, state.controls.window_size.y - 16 },
		32,
		z = 1,
		align = .Top_Center,
		color = V4f.{ 0, 0, 0, 1 }
	);
	push_quad_screen(
		state,
		.{ 16, state.controls.window_size.y - 64 },
		.{ state.controls.window_size.x - 32, 1 },
		v3(GRAY_10),
		z = 0.02
	);

	Row :: struct {
		instance_name: string; @"name(\"Name\")" @"size(128)" @"align(Left)"
		players_count: string; @"name(\"# Players\")" @"align(Right)"
		level_name: string; @"name(\"Level name\")" @"align(Right)"
		auto_revive: bool; @"name(\"Auto-revive\")" @"align(Right)"
		private: bool; @"name(\"Private\")" @"align(Right)"
	}
	rows := NewArray(args.instances.count, Row,, temp);
	for * rows {
		it.instance_name = args.instances[it_index].name;
		it.players_count = tprint(
			"% / %",
			formatInt(args.instances[it_index].player_count, 10, 3, #char " "),
			formatInt(args.instances[it_index].player_capacity, 10, 3, #char " ")
		);
		it.level_name = args.instances[it_index].level_name;
		it.auto_revive = args.instances[it_index].auto_revive;
		it.private = false;
	}

	table := atom_table(
		state,
		.{ state.controls.window_size.x - 16, state.controls.window_size.y - 64 - 16 },
		.{ 512 + 128, state.controls.window_size.y - 64 - 16 - 16 - 32 },
		rows,
		align = Align.Top_Right
	);

	if table.selected_row_index >= 0 && table.selected_row_index < args.instances.count {
		ret.selected_instance_id = args.instances[table.selected_row_index].instance_id;
	}

	push_quad_screen(
		state,
		.{ table.aabb_min.x, table.aabb_min.y - 4 - 32 },
		.{ table.aabb_max.x - table.aabb_min.x, 32 },
		v3(GRAY_70),
		z = 0.02
	);

	text_button_state: Text_Button;
	cursor := V2f.{ table.aabb_min.x + 8, table.aabb_min.y - 4 - 32 + 16 };
	ret.reload_instances_clicked, text_button_state = text_button(
		state, "Reload", cursor, 1, id = "reload", align = Align.Center_Left
	);
	cursor.x += widget_width(state, "reload") + 4;
	ret.enter_instance_clicked, text_button_state = text_button(
		state, "Enter instance", cursor, 1, id = "enter_instance", align = Align.Center_Left
	);
	cursor.x += widget_width(state, "enter_instance") + 4;
	ret.create_instance_clicked, text_button_state = text_button(
		state, "Create instance", cursor, 1, id = "create_instance", align = Align.Center_Left
	);

	cursor =  .{ 16, state.controls.window_size.y - 64 - 16 };

	if args.create_instance_popup_open {
		popup := begin_window(
			state,
			state.controls.window_size / 2,
			V2f.{ 400, 300 },
			Align.Center,
			"create_instance_popup",
			1
		);

		atom_label(
			state,
			"Create Instance",
			popup.pos + V2f.{ popup.size.x / 2, popup.size.y - 4 },
			scale = 24,
			z = 1.1,
			align = .Top_Center,
			color = V4f.{ 0, 0, 0, 1 }
		);

		push_quad_screen(
			state,
			popup.pos + V2f.{ 0, popup.size.y - 32 },
			V2f.{ popup.size.x, 1 },
			v3(GRAY_10),
			z = 1.1
		);

		labeled_checkbox(
			state,
			"Private Instance",
			popup.pos + V2f.{ 4, popup.size.y - 32 - 8 },
			popup.size.x - 8,
			16,
			z = 1.1,
			align = .Top_Left
		);

		labeled_checkbox(
			state,
			"Auto revive",
			popup.pos + V2f.{ 4, popup.size.y - 32 - 8 - 24 },
			popup.size.x - 8,
			16,
			z = 1.1,
			align = .Top_Left
		);

		atom_input_text(state, popup.pos + V2f.{ 4, popup.size.y - 32 - 8 - 48 },
			24,
			"Level name",
			z = 1.1,
			align = .Top_Left
		);

		end_window(state, "create_instance_popup");
	}

	return ret;
}

// --------- MODERN

div :: (a: V4f, b: float32) -> V4f {
	return V4f.{ a.x / b, a.y / b, a.z / b, a.w / b };
}

GRAY_00  :: #run div(V4f.{  35,  31,  32, 255 }, 255.0);
GRAY_10  :: #run div(V4f.{  65,  64,  66, 255 }, 255.0);
GRAY_20  :: #run div(V4f.{  88,  89,  91, 255 }, 255.0);
GRAY_30  :: #run div(V4f.{ 109, 110, 113, 255 }, 255.0);
GRAY_40  :: #run div(V4f.{ 128, 130, 133, 255 }, 255.0);
GRAY_50  :: #run div(V4f.{ 147, 149, 152, 255 }, 255.0);
GRAY_60  :: #run div(V4f.{ 167, 169, 172, 255 }, 255.0);
GRAY_70  :: #run div(V4f.{ 188, 190, 192, 255 }, 255.0);
GRAY_80  :: #run div(V4f.{ 209, 211, 212, 255 }, 255.0);
GRAY_90  :: #run div(V4f.{ 230, 231, 232, 255 }, 255.0);
GRAY_100 :: #run div(V4f.{ 255, 255, 255, 255 }, 255.0);

GREEN_BRIGHT :: #run div(V4f.{   0, 166,  81, 255 }, 255.0);

Window :: struct {
	pos: V2f;
	size: V2f;
}
begin_window :: (
	gui: *GUI_State,
	pos: V2f,
	size := V2f.{ FLOAT32_MAX, FLOAT32_MAX },
	align := Align.Center,
	id := "window",
	z := 0.0
) -> Window {

	state, comp := widget(gui, id, Window);
	comp.physical = .Solid;

	lower_left := align_pos(pos, size, align);

	window_aabb := AABBf.{ lower_left, lower_left + size };
	push_quad_screen(gui, window_aabb, v3(GRAY_20), z);
	push_quad_screen(gui, shrink(window_aabb, 1.0), v3(GRAY_80), z + 0.01);

	state.pos = lower_left;
	state.size = size;

	return state;
}

end_window :: (gui: *GUI_State, id := "window") {
	// Nothing for now
}

align_pos :: (pos: V2f, size: V2f, align: Align) -> V2f {
	ret := pos;
	if (align & Align.HCenter) == Align.HCenter {
		ret.x -= size.x / 2;
	}
	else if (align & Align.Right) == Align.Right {
		ret.x -= size.x;
	}
	if (align & Align.VCenter) == Align.VCenter {
		ret.y -= size.y / 2;
	}
	else if (align & Align.Top) == Align.Top {
		ret.y -= size.y;
	}
	return ret;
}

Atom_Label :: struct {
	aabb_min: V2f;
	aabb_max: V2f;
}
atom_label :: (
	gui: *GUI_State,
	text: string,
	pos: V2f,
	scale := 16.0,
	z := 0.0,
	align := Align.Bottom_Left,
	color := V4f.{ 1, 1, 1, 1 },
	outline := false,
	id := 0
) -> Atom_Label{
	push_id(gui, id);
	defer pop_id(gui);
	before := gui.chars.count;

	aabb_min := V2f.{ +FLOAT32_MAX, +FLOAT32_MAX };
	aabb_max := V2f.{ -FLOAT32_MAX, -FLOAT32_MAX };

	cursor := pos;
	for text {
		glyph := gui.main_font.glyphs[it];
		if glyph.unicode != it
			continue;

		char: GUI_State.Char;
		char.id = it;
		char.pos.x = cursor.x + glyph.planex * scale;
		char.pos.y = cursor.y + glyph.planey * scale;
		char.size.x = (glyph.planew - glyph.planex) * scale;
		char.size.y = (glyph.planeh - glyph.planey) * scale;
		char.z = z + (it / 256.0 / 1000.0);
		char.color = color;
		char.outline = outline;

		cursor.x += glyph.advance * scale;

		aabb_min.x = min(aabb_min.x, char.pos.x);
		aabb_min.y = min(aabb_min.y, char.pos.y);
		aabb_max.x = max(aabb_max.x, char.pos.x + char.size.x);
		aabb_max.y = max(aabb_max.y, char.pos.y + char.size.y);

		array_add(*gui.chars, char);
	}

	for before..gui.chars.count-1 {
		char := *gui.chars[it];
		if (align & Align.HCenter) == Align.HCenter {
			char.pos.x -= (cursor.x - pos.x) / 2;
		}
		else if (align & Align.Right) == Align.Right {
			char.pos.x -= (cursor.x - pos.x);
		}
		if (align & Align.VCenter) == Align.VCenter {
			char.pos.y -= (aabb_max.y - pos.y) / 2;
		}
		else if (align & Align.Top) == Align.Top {
			char.pos.y -= (aabb_max.y - pos.y);
		}
	}

	if (align & Align.HCenter) == Align.HCenter {
		shift := (cursor.x + pos.x) / 2 - pos.x;
		aabb_min.x -= shift;
		aabb_max.x -= shift;
	}
	else if (align & Align.Right) == Align.Right {
		shift := cursor.x - pos.x;
		aabb_min.x -= shift;
		aabb_max.x -= shift;
	}

	if (align & Align.VCenter) == Align.VCenter {
		shift := (aabb_max.y + pos.y) / 2 - pos.y;
		aabb_min.y -= shift;
		aabb_max.y -= shift;
	}
	else if (align & Align.Top) == Align.Top {
		shift := aabb_max.y - pos.y;
		aabb_min.y -= shift;
		aabb_max.y -= shift;
	}

	return Atom_Label.{ aabb_min, aabb_max };
}

atom_dash_quad :: (
	gui: *GUI_State, pos: V2f, size: V2f, dash: V2f, stride: V2f, color: V3f, z := 0.0
) {
	x := pos.x;
	y := pos.y;

	while x < pos.x + size.x {

		while y < pos.y + size.y {
			dash_pos := V2f.{ x, y };
			dash_size := V2f.{
				min(dash.x, pos.x + size.x - dash_pos.x),
				min(dash.y, pos.y + size.y - dash_pos.y)
			};
			push_quad_screen(gui, dash_pos, dash_size, color, z);
			y += stride.y;
		}
		y = pos.y;
		x += stride.x;
	}
}

atom_input_text :: (
	gui: *GUI_State,
	pos: V2f,
	scale: float,
	text: string,
	z := 0.0,
	align := Align.Bottom_Left,
	id := 0
) -> string {
	push_id(gui, id);
	defer pop_id(gui);

	Input_Text :: struct {
		cursor := 0;
	};

	state, comp := widget(gui, "input", Input_Text);

	label := atom_label(
		gui,
		text,
		pos,
		scale,
		align = align,
		z = z + 0.1,
		color = ifx comp.keyboard_focused then GRAY_00 else GRAY_60
	);
	comp.aabb = .{ label.aabb_min, label.aabb_max };
	comp.physical = .Solid;

	ret := tprint("%", text);

	if comp.just_pressed {
		print("Input text focused\n");
		comp.keyboard_focused = true;
	}

	if comp.keyboard_focused && gui.controls.just_pressed[Platform.Key.Escape] {
		comp.keyboard_focused = false;
	}

	if comp.keyboard_focused {

		handle_add :: (key: int, to_add: string) #expand {
			if gui.controls.just_pressed[key] {
				before := ret;
				before.count = min(state.cursor, before.count);
				after := ret;
				after.count = after.count - state.cursor;
				after.data += state.cursor;
				ret = tprint("%1%2%3", before, to_add, after);
				state.cursor += to_add.count;
			}
		}

		if gui.controls.pressed[Platform.Key.Shift] {
			#insert #run -> string {
				sb: String_Builder;
				for 65..90 {
					char8 := it.(u8);
					char: string;
					char.data = *char8;
					char.count = 1;
					print_to_builder(*sb, "handle_add(xx Platform.Key.%, \"%\");\n", char, char);
				}
				return builder_to_string(*sb);
			};
		}
		else {
			#insert #run -> string {
				sb: String_Builder;
				for 65..90 {
					char8Up := it.(u8);
					char8 := (it + 32).(u8);
					char: string;
					char.data = *char8;
					char.count = 1;
					charUp: string;
					charUp.data = *char8Up;
					charUp.count = 1;
					print_to_builder(*sb, "handle_add(xx Platform.Key.%, \"%\");\n", charUp, char);
				}
				return builder_to_string(*sb);
			};
		}
		handle_add(xx Platform.Key.Space, " ");
		handle_add(xx Platform.Key.Period, ".");

		if gui.controls.just_pressed[xx Platform.Key.Backspace] {
			if state.cursor > 0 && ret.count > 0 {
				before := ret;
				before.count = min(state.cursor - 1, before.count);
				after := ret;
				after.count = after.count - state.cursor;
				after.data += state.cursor;
				ret = tprint("%1%2", before, after);
				state.cursor -= 1;
			}
		}
		if gui.controls.just_pressed[xx Platform.Key.Left] {
			state.cursor = max(0, state.cursor - 1);
		}
		if gui.controls.just_pressed[xx Platform.Key.Right] {
			state.cursor = min(ret.count, state.cursor + 1);
		}
	}

	return "";
}

Atom_Table :: struct {
	aabb_min: V2f;
	aabb_max: V2f;

	just_selected_row_index := -1;
	selected_row_index := -1;
}
atom_table :: (
	gui: *GUI_State,
	pos: V2f,
	size: V2f,
	rows: [] $T,
	row_height := 26,
	z := 0.0,
	align := Align.Bottom_Left
) -> Atom_Table {
	ret: Atom_Table;

	State :: struct {
		selected_row_index: int;
	}
	state := widget(gui, 0, State);

	lower_left := align_pos(pos, size, align);
	ret.aabb_min = lower_left;
	ret.aabb_max = lower_left + size;

	push_quad_screen(gui, lower_left, size, v3(GRAY_90), z + 0.1);
	push_quad_screen(gui, lower_left, .{ 4, size.y }, v3(GRAY_70), z + 0.2);
	atom_dash_quad(
		gui,
		.{ lower_left.x + 4, lower_left.y + size.y - 2 },
		.{ size.x - 4, 2 },
		.{ 2, 2 },
		.{ 4, 2 },
		v3(GRAY_60),
		z + 0.15
	);

	Cols :: struct {
		name: string;
		size := -1;
		offset: u64;
		align_right := false;
	}
	t_info := type_info(T);
	cols := NewArray(t_info.members.count, Cols,, temp);
	for * cols {
		it.size = -1;
	}

	for * cols {
		info := t_info.members[it_index];
		it.name = info.name;
		it.offset = xx info.offset_in_bytes;

		for note: info.notes {
			if scan2(note, "name(%)", *it.name)
				continue;
			if scan2(note, "size(%)", *it.size)
				continue;
			if equal(note, "align(Right)") {
				it.align_right = true;
				continue;
			}
		}
	}

	cursor := V2f.{ lower_left.x + 4, lower_left.y + size.y - row_height / 2 };
	push_id(gui, "col");
	for * cols {
		cursor.x += 4;
		label := atom_label(
			gui, it.name, cursor, 14, align = .Center_Left, z = 0.25, color = GRAY_00, id = it_index
		);
		if it.size < 0 {
			it.size = (label.aabb_max.x - label.aabb_min.x + 16).(s64);
		}
		cursor.x += it.size;

		if it_index < cols.count {
			push_quad_screen(
				gui,
				.{ cursor.x, lower_left.y },
				.{ 1, size.y },
				v3(GRAY_40),
				z + 0.20
			);
		}
	}
	pop_id(gui);

	cursor = V2f.{ lower_left.x + 4, lower_left.y + size.y - row_height / 2 - row_height };
	for row: rows {
		push_id(gui, it_index);
		defer pop_id(gui);

		cursor.x = lower_left.x + 4;
		for cols {

			any: Any;
			any.type = t_info.members[it_index].type;
			any.value_pointer = ((*row).(*u8) + t_info.members[it_index].offset_in_bytes).(*void);
			str := tprint("%", any);

			align := Align.Center_Left;
			label_pos := cursor + v2(4.0, 0.0);
			if it.align_right {
				label_pos.x = cursor.x + it.size;
				align = Align.Center_Right;
			}

			label := atom_label(
				gui, str, label_pos, 14, align = align, z = 0.25, color = GRAY_00, id = it_index
			);

			cursor.x += it.size + 4;
		}
		row_aabb_min := V2f.{ lower_left.x + 4, cursor.y - row_height / 2 };
		row_aabb_max := V2f.{ max(cursor.x, lower_left.x + size.x), cursor.y + row_height / 2 };
		if row_aabb_max.x - row_aabb_min.x > size.x - 4 {
			row_aabb_max.x = row_aabb_min.x + size.x - 4;
		}

		background_color := V4f.{ 0, 0, 0, 0 };
		

		if state.selected_row_index == it_index {
			background_color = GRAY_60;
		}
		if point_aabb(gui.controls.mouse_pos, row_aabb_min, row_aabb_max) {
			if gui.controls.just_pressed[Key.MouseLeft] {
				state.selected_row_index = it_index;
				ret.just_selected_row_index = it_index;
			} else {
				background_color = GRAY_30;
			}

			if gui.controls.pressed[Key.MouseLeft]
				background_color = GRAY_60;
		}
		if background_color.w > 0 {
			push_quad_screen(
				gui, row_aabb_min, row_aabb_max - row_aabb_min, v3(background_color), z + 0.15
			);
		}


		cursor.y -= row_height;
		push_quad_screen(
			gui,
			.{ lower_left.x + 4, cursor.y + row_height / 2 },
			.{ size.x - 4, 1 },
			v3(GRAY_40),
			z + 0.20
		);
	}

	push_quad_screen(
		gui,
		.{ lower_left.x + 4, lower_left.y + size.y - row_height - 1 },
		.{ size.x - 4, 1 },
		v3(GRAY_00),
		z + 0.25
	);
	ret.selected_row_index = state.selected_row_index;

	return ret;
}

Text_Button :: struct {
	Size :: enum {
		Small;
		Medium;
		Large;
	}
	size: Size;

	time_mouse_enter: Apollo_Time;
	time_mouse_leave: Apollo_Time;
	time_clicked: Apollo_Time;

	last_hover: bool;

	aabb_padding: V2f = V2f.{ 4, 4 };
	border: V2f = V2f.{ 1, 1 };
	border_color: V4f = V4f.{ 0, 0, 0, 1 };

	clicked := false;
}
text_button :: (
	gui: *GUI_State,
	text: string,
	pos: V2f,
	z := 0.0,
	id := "text_button",
	align := Align.Bottom_Left,
	size: Text_Button.Size = .Small
) -> bool, Text_Button
{
	state, widget := widget(gui, id, Text_Button);

	push_id(gui, id);
	defer pop_id(gui);

	widget.physical = .Mouse;
	state.aabb_padding = .{ 4, 4 };
	state.border = .{ 1, 1 };
	state.clicked = false;

	label_color := V4f.{ 0, 0, 0, 1 };
	background_color := V4f.{ 1, 1, 1, 1 };
	if state.last_hover && !gui.controls.pressed[Key.MouseLeft] {
		label_color = V4f.{ 1, 1, 1, 1 };
		background_color = V4f.{ 0, 0, 0, 1 };
	}

	scale := 16.0;
	if size == .Medium {
		scale = 20.0;
		state.aabb_padding = .{ 6, 6 };
		state.border = .{ 1.5, 1.5 };
	} else if size == .Large {
		scale = 24.0;
		state.aabb_padding = .{ 8, 8 };
		state.border = .{ 2, 2 };
	}

	label := atom_label(
		gui, text, pos, scale = scale, z = z + 1.0, align = align, color = label_color
	);
	widget.aabb.min = label.aabb_min - state.aabb_padding;
	widget.aabb.max = label.aabb_max + state.aabb_padding;
	push_quad_screen(gui, widget.aabb, v3(state.border_color), z);
	push_quad_screen(gui, shrink(widget.aabb, state.border), v3(background_color), z + 0.5);

	state.last_hover = widget.hovered;
	state.clicked = widget.released;

	return state.clicked, state;
}

Checkbox :: struct {
	checked: bool;
	aabb_min: V2f;
	aabb_max: V2f;

	just_checked := false;
}
checkbox :: (
	gui: *GUI_State,
	pos: V2f,
	size: float,
	z := 0.0,
	id := "checkbox",
	align := Align.Center
) -> Checkbox {
	push_id(gui, id);
	defer pop_id(gui);

	state, widget := widget(gui, 0, Checkbox);

	lower_left := align_pos(pos, .{ size, size }, align);

	push_quad_screen(gui, lower_left, .{ size, size }, v3(GRAY_80), z);
	push_quad_screen(gui, lower_left + .{ 1, 1 }, .{ size - 2, size - 2 }, v3(GRAY_10), z + 1);

	if state.checked {
		push_quad_screen(
			gui, lower_left + .{ 4, 4 }, .{ size - 8, size - 8 }, v3(GREEN_BRIGHT), z + 2
		);
	}

	state.aabb_min = lower_left;
	state.aabb_max = lower_left + .{ size, size };
	state.just_checked = false;
	if point_aabb(gui.controls.mouse_pos, lower_left, lower_left + .{ size, size }) {
		if gui.controls.just_pressed[Key.MouseLeft] {
			gui.controls.captured_mouse = true;
			state.checked = !state.checked;
			state.just_checked = true;
		}
	}

	return state.*;
}
labeled_checkbox :: (
	gui: *GUI_State,
	label: string,
	pos: V2f,
	width: float,
	size: float,
	z := 0.0,
	id := "labeled_checkbox",
	align := Align.Center
) -> Checkbox {
	push_id(gui, id);
	defer pop_id(gui);

	lower_left := align_pos(pos, .{ width, size }, horizontal(align));

	label_comp := atom_label(
		gui,
		label,
		lower_left + v2(4.0, 0.0),
		size,
		z,
		align = vertical(align) | Align.Left,
		color = v4(0.0, 0, 0, 1),
		id = xx string_id("label")
	);

	checkbox_comp := checkbox(
		gui,
		lower_left + v2(width - 4.0, 0.0),
		size,
		z,
		align = vertical(align) | Align.Right,
		id = "checkbox"
	);

	return checkbox_comp;
}
