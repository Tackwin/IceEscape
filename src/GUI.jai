#scope_file
Platform :: #import "Platform";
Controls :: #import "Controls";
Scene :: #import "Scene";
#import "Basic";
#import "String";
#import "Math";
#import "Store";
#import "Common";
#import "Algebra";
#import "Assets";
#import "Hash_Table";
#import "Sort";
#import "Hash";
#import "Reflection";
#scope_export

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
DROP_SLOT :: V2f.{ 9, 14 };
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
F_OUTLINE_SLOT :: V2f.{ 9, 13 };
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
BOMB_SLOT :: V2f.{ 9, 12 };

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

action_to_icon :: (action: Action_Key, layout: Platform.Layout) -> V2f {
	return key_to_icon(action_to_platform(action, layout));
}

key_to_icon :: (key: Platform.Key) -> V2f {
	if key == {
		case .W;
			return W_OUTLINE_SLOT;
		case .A;
			return A_OUTLINE_SLOT;
		case .Q;
			return Q_OUTLINE_SLOT;
		case .S;
			return S_OUTLINE_SLOT;
		case .D;
			return D_OUTLINE_SLOT;
		case .Z;
			return Z_OUTLINE_SLOT;
		case .C;
			return C_OUTLINE_SLOT;
		case .X;
			return X_OUTLINE_SLOT;
		case .E;
			return E_OUTLINE_SLOT;
		case .R;
			return R_OUTLINE_SLOT;
		case .V;
			return V_OUTLINE_SLOT;
		case .F;
			return F_OUTLINE_SLOT;
	}
	return V_OUTLINE_SLOT;
}



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

GUI_State :: struct {
	Quad :: struct {
		pos: V2f;
		size: V2f;
		color: V4f = .{ 1.0, 1.0, 1.0, 1.0 };
		z: float32 = 0;
		texture_rect: V4f = .{ 0, 0, 0, 0 };
		late := false;
		custom_texture_idx := -1;
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

	Direction :: enum {
		Right :: 0;
		Down :: 1;
		Left :: 2;
		Up :: 3;
	}
	Default_Params :: struct {
		z := 0.0;
		direction : Direction = .Down;
		align: Align = .Top_Left;
		cursor := V2f.{ 0, 0 };
		padding: V2f = V2f.{ 8, 8 };
	};
	default_params_stack: [..] Default_Params;

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

		age: int = 0;
	}
	widgets: Table(u64, Widget);

	id_stack: [..] u64;

	register_stack: [..] [..] u64;
}

Action_Key :: enum {
	Square00 :: 0;
	Square10;
	Square20;
	Square30;
	Square01;
	Square11;
	Square21;
	Square31;
	Square02;
	Square12;
	Square22;
	Square32;
	Square03;
	Square13;
	Square23;
	Square33;
	Escape;
	Click0;
	Click1;
	Tab;

	Move_Left :: Square01;
	Move_Right :: Square21;
	Move_Up :: Square12;
	Move_Down :: Square11;
	Buy_Ask :: Square32;
	Camera_Locked :: Square00;
	Coin :: Square20;
	Klaxon :: Square10;
	Drop :: Square31;
	Safe :: Square22;
	Hook :: Square02;

	Bomberman_Drop :: Square22;
}

action_to_platform :: (action: Action_Key, layout: Platform.Layout) -> Platform.Key {
	azerty :: Platform.Key.[
		.W, .X, .C, .V,
		.Q, .S, .D, .F,
		.A, .Z, .E, .R,
		._0, ._1, ._2, ._3,
		.Escape,
		.MouseLeft,
		.MouseRight,
		.Tab
	];
	qwerty :: Platform.Key.[
		.Z, .X, .C, .V,
		.A, .S, .D, .F,
		.Q, .W, .E, .R,
		._0, ._1, ._2, ._3,
		.Escape,
		.MouseLeft,
		.MouseRight,
		.Tab
	];

	if layout == {
		case .AZERTY;
			return azerty[xx action];
		case .QWERTY;
			return qwerty[xx action];
	}
	return .Q;
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

default_params :: (state: *GUI_State) -> *GUI_State.Default_Params {
	if state.default_params_stack.count == 0 {
		array_add(*state.default_params_stack, .{});
	}
	return *state.default_params_stack[state.default_params_stack.count - 1];
}
move_cursor :: (state: *GUI_State, delta: V2f) {
	default_params(state).cursor += delta;
}
space :: (state: *GUI_State, amount: float) {
	if default_params(state).direction == .Right {
		default_params(state).cursor.x += amount;
	} else if default_params(state).direction == .Left {
		default_params(state).cursor.x -= amount;
	} else if default_params(state).direction == .Down {
		default_params(state).cursor.y += amount;
	} else if default_params(state).direction == .Up {
		default_params(state).cursor.y -= amount;
	}
}
move_cursor :: (state: *GUI_State, delta: float) {
	if default_params(state).direction == .Right {
		default_params(state).cursor.x += delta;
	} else if default_params(state).direction == .Left {
		default_params(state).cursor.x -= delta;
	} else if default_params(state).direction == .Down {
		default_params(state).cursor.y += delta;
	} else if default_params(state).direction == .Up {
		default_params(state).cursor.y -= delta;
	}
}
advance_cursor :: (gui: *GUI_State, origin: V2f, dir: GUI_State.Direction, aabb: AABBf) {
	default_params(gui).cursor = origin;
	if dir == {
		case .Right;
			default_params(gui).cursor.x += aabb_width(aabb) + default_params(gui).padding.x;
		case .Down;
			default_params(gui).cursor.y += aabb_height(aabb) + default_params(gui).padding.y;
		case .Left;
			default_params(gui).cursor.x -= aabb_width(aabb) + default_params(gui).padding.x;
		case .Up;
			default_params(gui).cursor.y -= aabb_height(aabb) + default_params(gui).padding.y;
	}
}

push_default_params :: (state: *GUI_State, params: GUI_State.Default_Params = .{}) {
	array_add(*state.default_params_stack, params);
}
pop_default_params :: (state: *GUI_State) {
	assert(state.default_params_stack.count > 0);
	if state.default_params_stack.count == 0
		return;
	state.default_params_stack.count -= 1;
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

push_register :: (state: *GUI_State) {
	ids: [..] u64;
	array_add(*state.register_stack, ids);
}

pop_register :: (state: *GUI_State) {
	if state.register_stack.count > 0 {
		array_free(state.register_stack[state.register_stack.count - 1]);
		state.register_stack.count -= 1;
	}
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
	widget = table_find_pointer(*state.widgets, iid); // Retry without the current id stack
	if widget {
		return widget.aabb;
	}
	return AABBf.{};
}

widgets_aabb :: (state: *GUI_State, ids: [] $Id) -> AABBf
#modify {
	if Id == u64 || Id == s64 || Id == string {
		return true;
	}
	return false;
}
{
	if ids.count == 0 {
		return .{};
	}

	aabb := widget_aabb(state, ids[0]);
	for 1..ids.count - 1 {
		aabb = aabb_union(aabb, widget_aabb(state, ids[it]));
	}
	return aabb;
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

widget_height :: (state: *GUI_State, id: $Id) -> float
#modify {
	if Id == u64 || Id == s64 || Id == string {
		return true;
	}
	return false;
}
{
	aabb := widget_aabb(state, id);
	return aabb.max.y - aabb.min.y;
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
	if state.register_stack.count > 0 {
		array_add(*state.register_stack[state.register_stack.count - 1], iid);
	}

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
) -> *T, *GUI_State.Widget
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
		value.age += 1;
	}
}

// The gui will process all user input one frame before the rest of the game. So that we have a
// chance to press a button, before clicking on the terrain.
// That means that at the beggining of the frame, we copy the previous frame info into the control
// state, WITH the captured flags filled out from the state of the gui at the last frame.
// BUT the gui will take the current frame info.
begin_frame :: (state: *GUI_State, info: Platform.Frame_Info, out_controls: *Controls.State, layout_override: Platform.Layout = .AZERTY) {
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
	state.controls.time = info.time;
	// Use the user's preferred layout override instead of the auto-detected one
	if info.layout == .Unknown
		state.controls.layout = layout_override;
	else
		state.controls.layout = info.layout;


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

begin_row :: (state: *GUI_State, dir: GUI_State.Direction) {
	push_register(state);
	push_default_params(state, default_params(state));
	default_params(state).direction = dir;
}

end_row :: (state: *GUI_State) {
	id_stack := state.register_stack[state.register_stack.count - 1];
	aabb := widgets_aabb(state, id_stack);

	pop_default_params(state);

	dir := default_params(state).direction;
	origin := default_params(state).cursor;
	defer {
		pop_register(state);
		advance_cursor(state, origin, dir, aabb);
	}
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

push_debug_mark :: (
	state: *GUI_State, pos: V2f, scale := 2.5, z := 100.0, color := V4f.{ 1, 0, 0, 1}
) {
	push_quad_screen(state, pos - v2(scale, scale), v2(scale * 2), v3(color), z, a = color.w);
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
	quad.texture_rect.y = (15.0 - tex_slot.y) / 16.0;
	quad.texture_rect.z = 1.0 / 16.0;
	quad.texture_rect.w = 1.0 / 16.0;
	quad.z = z;

	array_add(*state.quads, quad);
}

push_late_quad_screen :: (
	state: *GUI_State, aabb: AABBf, color: V4f, z := 0.0
) -> *state.Quad {
	return push_late_quad_screen(
		state,
		aabb.min,
		aabb.max - aabb.min,
		color = color,
		z = z
	);
}
	
push_late_quad_screen :: (
	state: *GUI_State, pos: V2f, size: V2f, color: V4f, z := 0.0
) -> *state.Quad {
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
	return *state.quads[state.quads.count - 1];
}

Align :: enum {
	Undefined :: 0b0000;
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
					
					prompt := tprint(
						"Not enough souls (%) ! Revive your friends to collect more souls!", needed
					);
					if player.server.souls >= needed {
						prompt = tprint("R to buy. % souls.", needed);
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
						state.controls.window_size.y / 2 -
						pos.y * (state.controls.window_size.y) / 2;

					atom_label(state, prompt, screen_p, 24, z=10, align = .Center, outline = true);
				}
			}
		}
	}
}

push_breaking_news :: (state: *GUI_State, news: [] Scene.Breaking_News) {
	cursor := V2f.{ state.controls.window_size.x / 2, 16};
	for news {
		t := to_float64_seconds(state.controls.time - it.time).(float);
		t = clamp(t / 5, 0.0, 1.0);

		alpha := 1.0 - t;
		text := tprint("NEWS: %", it.text);
		label := atom_label(
			state, text, .{ cursor.x, cursor.y }, 20, z=20, align = .Top_Center, outline = true,
			color = V4f.{ 1.0, 1.0, 1.0, alpha }
		);

		cursor.y += label.aabb_max.y - label.aabb_min.y + 4;
	}
}

push_app_loop_histogram :: (state: *GUI_State, pos: V2f, size: V2f, data: [] float32, current_idx: int) {
	avg := 0.0;
	for data
		avg += it;
	avg /= data.count;

	ms_text := tprint("app_loop: %.2f ms, Avg %.2f ms", 1000 * data[current_idx], 1000 * avg);
	atom_label(state, ms_text, .{ pos.x + 4, pos.y + 4 }, 16, z=11, align = .Top_Left);

	push_quad_screen(
		state,
		pos = pos,
		size = size,
		color = .{ 0.0, 0.0, 0.0 },
		z = 10
	);

	project :: (x: float32) -> float32 #expand {
		return min(1.0, (600 / (1 + exp(-x / 5)) - 300) / 300) * size.y;
	}

	n := data.count;
	for data {
		ms := 1000 * it;
		h := project(ms);
		w := size.x / data.count - 1;

		x := (it_index * size.x) / data.count;

		color := V3f.{ 1.0, 1.0, 1.0 };
		if it_index == current_idx {
			// Pink color
			color = V3f.{ 1.0, 0.0, 1.0 };
			push_quad_screen(
				state,
				pos = .{ pos.x + x, pos.y + 5 },
				size = .{ w, size.y - 10 },
				color = color,
				z = 10.1
			);
		}
		push_quad_screen(
			state,
			pos = .{ pos.x + x, pos.y + size.y - 5 - h },
			size = .{ w, h },
			color = color,
			z = 11
		);
	}

	// Reference lines for ms thresholds
	{
		h := project(8.33); // 120 fps target
		push_quad_screen(
			state,
			pos = .{ pos.x, pos.y + size.y - 5 - h },
			size = .{ size.x, 1 },
			color = .{ 0.0, 0.0, 1.0 },
			z = 12
		);
	}
	{
		h := project(16.67); // 60 fps target
		push_quad_screen(
			state,
			pos = .{ pos.x, pos.y + size.y - 5 - h },
			size = .{ size.x, 1 },
			color = .{ 0.0, 1.0, 0.0 },
			z = 12
		);
	}
	{
		h := project(33.33); // 30 fps target
		push_quad_screen(
			state,
			pos = .{ pos.x, pos.y + size.y - 5 - h },
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
	atom_label(state, fps_text, .{ pos.x + 4, pos.y + 4 }, 16, z=11, align = .Top_Left);

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
			push_quad_screen(
				state,
				pos = .{ pos.x + x, pos.y + 5 },
				size = .{ w, size.y - 10 },
				color = color,
				z = 10.1
			);
		}
		push_quad_screen(
			state,
			pos = .{ pos.x + x, pos.y + size.y - 5 - h },
			size = .{ w, h },
			color = color,
			z = 11
		);
	}

	{
		h := project(20);
		push_quad_screen(
			state,
			pos = .{ pos.x, pos.y + size.y - 5 - h },
			size = .{ size.x, 1 },
			color = .{ 0.0, 0.0, 1.0 },
			z = 12
		);
	}
	{
		h := project(80);
		push_quad_screen(
			state,
			pos = .{ pos.x, pos.y + size.y - 5 - h },
			size = .{ size.x, 1 },
			color = .{ 0.0, 1.0, 0.0 },
			z = 12
		);
	}
	{
		h := project(200);
		push_quad_screen(
			state,
			pos = .{ pos.x, pos.y + size.y - 5 - h },
			size = .{ size.x, 1 },
			color = .{ 1.0, 0.0, 0.0 },
			z = 12
		);
	}
}

push_ms_histogram :: (state: *GUI_State, pos: V2f, size: V2f, data: [] float32, current_idx: int, label_prefix: string) {
	avg := 0.0;
	for data
		avg += it;
	avg /= data.count;

	ms_text := tprint(
		"%: %.% ms, Avg %.% ms",
		label_prefix,
		(1000 * data[current_idx]).(s64),
		(10000 * data[current_idx]).(s64) % 10,
		(1000 * avg).(s64),
		(10000 * avg).(s64) % 10
	);
	atom_label(state, ms_text, .{ pos.x + 4, pos.y + 4 }, 16, z=11, align = .Top_Left);

	push_quad_screen(
		state,
		pos = pos,
		size = size,
		color = .{ 0.0, 0.0, 0.0 },
		z = 10
	);

	project :: (x: float32) -> float32 #expand {
		return min(1.0, (600 / (1 + exp(-x / 15)) - 300) / 300) * size.y;
	}

	n := data.count;
	for data {
		ms := 1000 * it;
		h := project(ms);
		w := max(size.x / data.count - 1, 1);

		x := (it_index * size.x) / data.count;

		color := V3f.{ 1.0, 1.0, 1.0 };
		if it_index == current_idx {
			// Pink color
			color = V3f.{ 1.0, 0.0, 1.0 };
			push_quad_screen(
				state,
				pos = .{ pos.x + x, pos.y + 5 },
				size = .{ w, size.y - 10 },
				color = color,
				z = 10.1
			);
		}
		push_quad_screen(
			state,
			pos = .{ pos.x + x, pos.y + size.y - 5 - h },
			size = .{ w, h },
			color = color,
			z = 11
		);
	}

	// Reference lines for ms thresholds
	{
		h := project(8.33); // 120 fps target
		push_quad_screen(
			state,
			pos = .{ pos.x, pos.y + size.y - 5 - h },
			size = .{ size.x, 1 },
			color = .{ 0.0, 0.0, 1.0 },
			z = 12
		);
	}
	{
		h := project(16.67); // 60 fps target
		push_quad_screen(
			state,
			pos = .{ pos.x, pos.y + size.y - 5 - h },
			size = .{ size.x, 1 },
			color = .{ 0.0, 1.0, 0.0 },
			z = 12
		);
	}
	{
		h := project(33.33); // 30 fps target
		push_quad_screen(
			state,
			pos = .{ pos.x, pos.y + size.y - 5 - h },
			size = .{ size.x, 1 },
			color = .{ 1.0, 0.0, 0.0 },
			z = 12
		);
	}
}

push_point_ui :: (state: *GUI_State, player: Scene.Player) {
	cursor := V2f.{ 4, 32 + 12 };

	score_label := atom_label(
		state,
		tprint("Souls: %", player.server.souls),
		cursor,
		24,
		1,
		align = .Center_Left,
		outline = true
	);

	push_quad_screen(
		state, .{ score_label.aabb_min, score_label.aabb_max }, COLOR_SOMBER_A, 0, a = 0.45
	);
}

push_end_screen :: (state: *GUI_State, scene: Scene.Scene) {
	display_player_icon :: (
		player_id: int, p: V2f, z := 10.0, size := 24
	) #expand {
		player := Scene.find_by_player_id(scene, player_id);
		if !player
			return;
		push_quad_screen(
			state,
			pos = .{ p.x - size, p.y - size },
			size = .{ size * 2, size * 2 },
			color = COLOR_HIGHLIGHT_A,
			z = z + 0.1
		);
		push_quad_screen(
			state,
			pos = .{ p.x - size - 1, p.y - size - 1 },
			size = .{ 2 * size, 2 * size },
			color = COLOR_BRIGHT_A,
			z = z + 0.2
		);
		push_quad_texture(
			state,
			pos = .{ p.x - size - 1, p.y - size - 1 },
			size = .{ 2 * size - 2, 2 * size - 2 },
			color = .{ 1.0, 1.0, 1.0 },
			tex_slot = model_id_to_slot(xx player.server.model_id),
			z = z + 0.3
		);
	}
	center := v2(state.controls.window_size.x / 2, state.controls.window_size.y / 4);
	size   := v2(1024.0 - 128, 258.0);

	window_aabb := pos_size(center - size / 2.0, size);
	push_quad_screen(state, window_aabb, v3(GRAY_20), z = 10.0);
	push_quad_screen(state, shrink(window_aabb, 1), v3(GRAY_80), z = 10.1);

	atom_label(
		state,
		"Level cleared",
		v2(center.x, top(window_aabb) + 8),
		z = 11.0,
		align=.Top_Center,
		scale=24,
		color = GRAY_00
	);
	dt := to_float64_seconds(state.controls.time - scene.end_scene_countdown_time);
	dt = scene.end_scene_countdown - dt;
	text := tprint("% seconds before next level !", ceil(dt).(s64));
	atom_label(
		state,
		text,
		v2(center.x, top(window_aabb) + 32 + 8),
		z = 11.0,
		align=.Top_Center,
		scale=16,
		color = GRAY_20
	);

	push_quad_screen(
		state,
		pos_size(window_aabb.min.x, window_aabb.min.y + 64, width(window_aabb), 1),
		v3(GRAY_20),
		z = 10.2
	);
	atom_label(
		state,
		"Winner:",
		v2(center.x - 8, top(window_aabb) + 64 + 32),
		z = 11.0,
		align=.Center_Right,
		scale=24,
		color = GRAY_00
	);
	display_player_icon(
		scene.client.end_level.winner_id, .{ center.x + 8 + 24, top(window_aabb) + 64 + 32 }, z = 10
	);
	push_quad_screen(
		state,
		pos_size(window_aabb.min.x, window_aabb.min.y + 64 + 64, width(window_aabb), 1),
		v3(GRAY_20),
		z = 10.2
	);
	atom_label(
		state,
		"Most deaths",
		v2(window_aabb.min.x + width(window_aabb) / 4, top(window_aabb) + 64 + 64 + 16),
		z = 11.0,
		align=.Center,
		scale=16,
		color = GRAY_00
	);
	push_quad_screen(
		state,
		pos_size(center.x, window_aabb.min.y + 64 + 32, 1, 64 + 32),
		v3(GRAY_20),
		z = 10.2
	);
	atom_label(
		state,
		"Most revives",
		v2(window_aabb.min.x + 3 * width(window_aabb) / 4, top(window_aabb) + 64 + 64 + 16),
		z = 11.0,
		align=.Center,
		scale=16,
		color = GRAY_00
	);
	push_quad_screen(
		state,
		pos_size(window_aabb.min.x, window_aabb.min.y + 64 + 64 + 64 + 32, width(window_aabb), 1),
		v3(GRAY_20),
		z = 10.2
	);
	time := scene.client.end_level.time;
	minutes := floor(time / 60);
	seconds := fmod_cycling(time, 60);
	milliseconds := frac(time) * 1000;
	atom_label(
		state,
		tprint(
			"Time: %:%s %ms",
			formatInt(minutes.(int), minimum_digits = 3, padding = #char "_"),
			formatInt(seconds.(int), minimum_digits = 2, padding = #char "_"),
			formatInt(milliseconds.(int), minimum_digits = 3, padding = #char "_")
		),
		v2(window_aabb.min.x + 1 * width(window_aabb) / 4, top(window_aabb) + 64 + 64 + 64 + 32 + 16),
		z = 11.0,
		align=.Center,
		scale=16,
		color = GRAY_00
	);

	wr_string := "WR xx:xx s xx ms";
	{
		wr_time_ms := scene.client.leaderboard.wr_time_ms;
		wr_minutes := wr_time_ms / 60000;
		wr_seconds := (wr_time_ms / 1000) % 60;
		wr_milliseconds := wr_time_ms % 1000;

		username := "Anonymous";
		if scene.client.leaderboard.wr_username.count > 0 {
			username = scene.client.leaderboard.wr_username;
		}

		wr_string = tprint(
			"WR %:%s %ms (%)",
			formatInt(wr_minutes.(int), minimum_digits = 3, padding = #char "_"),
			formatInt(wr_seconds.(int), minimum_digits = 2, padding = #char "_"),
			formatInt(wr_milliseconds.(int), minimum_digits = 3, padding = #char "_"),
			username
		);
	}
	atom_label(
		state,
		wr_string,
		v2(window_aabb.min.x + 3 * width(window_aabb) / 4, top(window_aabb) + 64 + 64 + 64 + 32 + 16),
		z = 11.0,
		align=.Center,
		scale=16,
		color = GRAY_00
	);
	push_quad_screen(
		state,
		pos_size(window_aabb.min.x, window_aabb.min.y + 64 + 64 + 64 + 32 + 32 + 2, width(window_aabb), 1),
		v3(GRAY_20),
		z = 10.2
	);
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
					if dy > 0 {
						indicator = BUBBLE_INDICATOR_SLOT_UP;
						indicator_dt = V2f.{ 0, -5 };
					}
					else {
						indicator = BUBBLE_INDICATOR_SLOT_DOWN;
						indicator_dt = V2f.{ 0, 5 };
					}
			}

			screen_p2: V2f;
			screen_p2.x =
				p2.x * (state.controls.window_size.x - 50) / 2 + state.controls.window_size.x / 2;
			screen_p2.y =
				state.controls.window_size.y / 2 -
				p2.y * (state.controls.window_size.y - 50) / 2;

			// Check if too close to the bottom left ui palette
			action_palette_safety := V2f.{ 168 + 25, 168 + 25 };
			if screen_p2.x < action_palette_safety.x && screen_p2.y > state.controls.window_size.y - action_palette_safety.y {
				dx := abs(screen_p2.x - action_palette_safety.x);
				dy := abs(screen_p2.y - (state.controls.window_size.y - action_palette_safety.y));
				if dx < dy
					screen_p2.x = action_palette_safety.x;
				else
					screen_p2.y = state.controls.window_size.y - action_palette_safety.y;
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
	palette_h := 168.0;
	palette_y := state.controls.window_size.y - palette_h;

	push_quad_screen(
		state,
		pos = .{ 0, palette_y },
		size = .{ 168, 168 },
		color = .{ 218/255.0, 220/255.0, 231/255.0 },
		1
	);

	cell_y :: (y: int) -> float32 #expand {
		return palette_y + (3 - y) * 42.0;
	}

	render_square_at :: (x: int, y: int, key_code: int) #expand {
		color := COLOR_BRIGHT_A;
		if state.controls.pressed[xx key_code]
			color = COLOR_HIGHLIGHT_A;
		push_quad_screen(
			state,
			pos = .{ x * 42.0 + 1, cell_y(y) + 1 },
			size = .{ 40, 40 },
			color = color,
			z = 2
		);
	}
	render_square_at(0, 0, xx action_to_platform(Action_Key.Square00, state.controls.layout));
	render_square_at(1, 0, xx action_to_platform(Action_Key.Square10, state.controls.layout));
	render_square_at(2, 0, xx action_to_platform(Action_Key.Square20, state.controls.layout));
	render_square_at(3, 0, xx action_to_platform(Action_Key.Square30, state.controls.layout));
	render_square_at(0, 1, xx action_to_platform(Action_Key.Square01, state.controls.layout));
	render_square_at(1, 1, xx action_to_platform(Action_Key.Square11, state.controls.layout));
	render_square_at(2, 1, xx action_to_platform(Action_Key.Square21, state.controls.layout));
	render_square_at(3, 1, xx action_to_platform(Action_Key.Square31, state.controls.layout));
	render_square_at(0, 2, xx action_to_platform(Action_Key.Square02, state.controls.layout));
	render_square_at(1, 2, xx action_to_platform(Action_Key.Square12, state.controls.layout));
	render_square_at(2, 2, xx action_to_platform(Action_Key.Square22, state.controls.layout));
	render_square_at(3, 2, xx action_to_platform(Action_Key.Square32, state.controls.layout));
	render_square_at(0, 3, xx action_to_platform(Action_Key.Square03, state.controls.layout));
	render_square_at(1, 3, xx action_to_platform(Action_Key.Square13, state.controls.layout));
	render_square_at(2, 3, xx action_to_platform(Action_Key.Square23, state.controls.layout));
	render_square_at(3, 3, xx action_to_platform(Action_Key.Square33, state.controls.layout));

	render_texture_at :: (x: int, y: int, tex_slot: V2f, color := V3f.{ 1.0, 1.0, 1.0 }) #expand {
		push_quad_texture(
			state,
			pos = .{ (x * 42 + 4).(float32), cell_y(y) + 4 },
			size = .{ 34, 34 },
			tex_slot = tex_slot,
			color = color,
			z = 3
		);
	}
	render_hint_at :: (x: int, y: int, tex_slot: V2f)  #expand {
		push_quad_texture(
			state,
			pos = .{ (x * 42 + 42 - 18).(float32), cell_y(y) + 42 - 18 },
			size = .{ 18, 18 },
			tex_slot = tex_slot,
			color = .{ 1.0, 1.0, 1.0 },
			z = 5
		);
	}

	if scene.params.mode == {
		case .Standard;
		render_texture_at(0, 1, LEFT_SLOT);
		render_hint_at(0, 1, action_to_icon(Action_Key.Square01, state.controls.layout));

		render_texture_at(1, 1, DOWN_SLOT);
		render_hint_at(1, 1, action_to_icon(Action_Key.Square11, state.controls.layout));

		render_texture_at(2, 1, RIGHT_SLOT);
		render_hint_at(2, 1, action_to_icon(Action_Key.Square21, state.controls.layout));

		render_texture_at(1, 2, UP_SLOT);
		render_hint_at(1, 2, action_to_icon(Action_Key.Square12, state.controls.layout));
		
		render_texture_at(2, 0, COIN_SLOT);
		render_hint_at(2, 0, action_to_icon(Action_Key.Square20, state.controls.layout));

		render_texture_at(1, 0, KLAXON_SLOT);
		render_hint_at(1, 0, action_to_icon(Action_Key.Square10, state.controls.layout));

		if scene.camera_locked
			render_texture_at(0, 0, UNLOCKED_SLOT);
		else
			render_texture_at(0, 0, LOCKED_SLOT);
		render_hint_at(0, 0, action_to_icon(Action_Key.Square00, state.controls.layout));

		player := Scene.find_by_player_id(scene, scene.controlled_player_id);
		if player {
			if Scene.find_bomb_by_holder_id(scene, player.id) {
				render_texture_at(3, 1, DROP_SLOT);
				render_hint_at(3, 1, action_to_icon(Action_Key.Square31, state.controls.layout));
			}
			if player.server.has_safe_present {
				render_texture_at(2, 2, SAFE_ZONE_SLOT, .{ 0.5, 1.0, 0.5 });
				render_hint_at(2, 2, action_to_icon(Action_Key.Square22, state.controls.layout));
			}
			if player.server.has_hook_present {
				render_texture_at(0, 2, HOOK_SLOT, .{ 0.5, 1.0, 0.5 });
				render_hint_at(0, 2, action_to_icon(Action_Key.Square02, state.controls.layout));

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
				render_hint_at(3, 0, action_to_icon(Action_Key.Square30, state.controls.layout));

				dt := scene.client.clock - player.server.dead_time;
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
		render_hint_at(3, 2, action_to_icon(Action_Key.Square32, state.controls.layout));
		case .Bomberman;
		render_texture_at(1, 0, KLAXON_SLOT);
		render_hint_at(1, 0, action_to_icon(Action_Key.Square10, state.controls.layout));

		render_texture_at(2, 2, BOMB_SLOT);
		render_hint_at(2, 2, action_to_icon(Action_Key.Square22, state.controls.layout));
	}
	


}

Escape_Menu_Args :: struct {
	sound_enabled := false;
	keyboard_layout: Platform.Layout = .AZERTY;

	// Render settings
	shadows_enabled := true;
	lighting_enabled := true;
	shadow_samples_index := 1; // 0=4, 1=9, 2=25
	aa_mode_index := 0; // 0=FXAA, 1=MSAA 2x, 2=MSAA 4x, 3=No AA
	particles_enabled := true;
	props_enabled := true;
	shadow_map_size_index := 1; // 0=1024, 1=2048, 2=4096
}
Escape_Menu_Ret :: struct {
	sound_checked := false;
	resume_clicked := false;
	editor_clicked := false;
	leave_instance_clicked := false;
	keyboard_layout: Platform.Layout;
	layout_changed := false;

	// Render settings
	lighting_enabled := true;
	lighting_changed := false;
	shadows_enabled := true;
	shadows_changed := false;
	shadow_samples_index := 1;
	shadow_samples_changed := false;
	aa_mode_index := 0;
	aa_mode_changed := false;
	particles_enabled := true;
	particles_changed := false;
	props_enabled := true;
	props_changed := false;
	shadow_map_size_index := 1;
	shadow_map_size_changed := false;
	slowdown_enabled := false;
	slowdown_changed := false;
}
push_escape_menu :: (state: *GUI_State, args: Escape_Menu_Args) -> Escape_Menu_Ret {
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
	cursor.y += 64.0;

	ret.sound_checked = labeled_checkbox(
		state,
		"Sound",
		cursor,
		popup_size.x - 28,
		16,
		z = 12,
		"sound_checkbox",
		align = .Bottom_Left,
		padding = 0,
		default = args.sound_enabled
	).checked;
	cursor.y += widget_height(state, "sound_checkbox") + 4;
	popup_size.* = grow(popup_size, pos, cursor);

	// Keyboard layout dropdown
	layout_options :: string.[ "AZERTY", "QWERTY" ];
	current_layout_index := cast(int) args.keyboard_layout;
	layout_dropdown := labeled_dropdown(
		state,
		"Keyboard",
		layout_options,
		cursor,
		popup_size.x - 28,
		24,
		z = 12,
		"keyboard_dropdown",
		align = .Bottom_Left,
		padding = 0,
		default_index = current_layout_index
	);
	ret.keyboard_layout = cast(Platform.Layout) layout_dropdown.selected_index;
	ret.layout_changed = layout_dropdown.changed;
	cursor.y += widget_height(state, "keyboard_dropdown") + 4;
	popup_size.* = grow(popup_size, pos, cursor);

	// Shadows checkbox
	shadows_checkbox := labeled_checkbox(
		state,
		"Shadows",
		cursor,
		popup_size.x - 28,
		16,
		z = 12,
		"shadows_checkbox",
		align = .Bottom_Left,
		padding = 0,
		default = args.shadows_enabled
	);
	ret.shadows_enabled = shadows_checkbox.checked;
	ret.shadows_changed = shadows_checkbox.just_checked;
	cursor.y += widget_height(state, "shadows_checkbox") + 4;
	popup_size.* = grow(popup_size, pos, cursor);

	// Lighting checkbox
	// lighting_checkbox := labeled_checkbox(
	// 	state,
	// 	"Lighting",
	// 	cursor,
	// 	popup_size.x - 28,
	// 	16,
	// 	z = 12,
	// 	"lighting_checkbox",
	// 	align = .Bottom_Left,
	// 	padding = 0,
	// 	default = args.lighting_enabled
	// );
	// ret.lighting_enabled = lighting_checkbox.checked;
	// ret.lighting_changed = lighting_checkbox.just_checked;
	// cursor.y += widget_height(state, "lighting_checkbox") + 4;
	// popup_size.* = grow(popup_size, pos, cursor);

	// // Shadow samples dropdown
	// shadow_samples_options :: string.[ "4", "9", "25" ];
	// shadow_samples_dropdown := labeled_dropdown(
	// 	state,
	// 	"Shadow Samples",
	// 	shadow_samples_options,
	// 	cursor,
	// 	popup_size.x - 28,
	// 	24,
	// 	z = 12,
	// 	"shadow_samples_dropdown",
	// 	align = .Bottom_Left,
	// 	padding = 0,
	// 	default_index = args.shadow_samples_index
	// );
	// ret.shadow_samples_index = shadow_samples_dropdown.selected_index;
	// ret.shadow_samples_changed = shadow_samples_dropdown.changed;
	// cursor.y += widget_height(state, "shadow_samples_dropdown") + 4;
	// popup_size.* = grow(popup_size, pos, cursor);

	// // Shadow map size dropdown
	// shadow_map_size_options :: string.[ "1024", "2048", "4096" ];
	// shadow_map_size_dropdown := labeled_dropdown(
	// 	state,
	// 	"Shadow Map",
	// 	shadow_map_size_options,
	// 	cursor,
	// 	popup_size.x - 28,
	// 	24,
	// 	z = 12,
	// 	"shadow_map_size_dropdown",
	// 	align = .Bottom_Left,
	// 	padding = 0,
	// 	default_index = args.shadow_map_size_index
	// );
	// ret.shadow_map_size_index = shadow_map_size_dropdown.selected_index;
	// ret.shadow_map_size_changed = shadow_map_size_dropdown.changed;
	// cursor.y += widget_height(state, "shadow_map_size_dropdown") + 4;
	// popup_size.* = grow(popup_size, pos, cursor);

	// // Anti-aliasing dropdown
	// aa_mode_options :: string.[ "FXAA", "MSAA 2x", "MSAA 4x", "No AA" ];
	// aa_mode_dropdown := labeled_dropdown(
	// 	state,
	// 	"Anti-Aliasing",
	// 	aa_mode_options,
	// 	cursor,
	// 	popup_size.x - 28,
	// 	24,
	// 	z = 12,
	// 	"aa_mode_dropdown",
	// 	align = .Bottom_Left,
	// 	padding = 0,
	// 	default_index = args.aa_mode_index
	// );
	// ret.aa_mode_index = aa_mode_dropdown.selected_index;
	// ret.aa_mode_changed = aa_mode_dropdown.changed;
	// cursor.y += widget_height(state, "aa_mode_dropdown") + 4;
	// popup_size.* = grow(popup_size, pos, cursor);

	// // Particles checkbox
	particles_checkbox := labeled_checkbox(
		state,
		"Particles",
		cursor,
		popup_size.x - 28,
		16,
		z = 12,
		"particles_checkbox",
		align = .Bottom_Left,
		padding = 0,
		default = args.particles_enabled
	);
	ret.particles_enabled = particles_checkbox.checked;
	ret.particles_changed = particles_checkbox.just_checked;
	cursor.y += widget_height(state, "particles_checkbox") + 4;
	popup_size.* = grow(popup_size, pos, cursor);

	// // Props checkbox
	props_checkbox := labeled_checkbox(
		state,
		"Props",
		cursor,
		popup_size.x - 28,
		16,
		z = 12,
		"props_checkbox",
		align = .Bottom_Left,
		padding = 0,
		default = args.props_enabled
	);
	ret.props_enabled = props_checkbox.checked;
	ret.props_changed = props_checkbox.just_checked;
	cursor.y += widget_height(state, "props_checkbox") + 4;
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
		.{ state.controls.window_size.x / 2, state.controls.window_size.y / 2 - 24 },
		32,
		z=1,
		align = .Center,
		color = V4f.{ 0, 0, 0, 1 }
	);

	ret.retry_clicked = text_button(
		state,
		"Retry",
		.{ state.controls.window_size.x / 2, state.controls.window_size.y / 2 + 24 },
		1,
		align = .Center,
	);

	ret.retry_localhost_clicked = text_button(
		state,
		"Retry localhost",
		.{ state.controls.window_size.x / 2, state.controls.window_size.y / 2 + 72 },
		1,
		id = "retry_localhost",
		align = .Center,
	);
	
	
	return ret;
}

Instance_Info :: struct {
	name: string;
	auto_revive: bool;
	private: bool;
	player_count: int;
	player_capacity: int;
	level_name: string;
	instance_id: int;
}

Main_Menu_Ret :: struct {
	reload_instances_clicked := false;
	enter_instance_clicked := false;
	create_instance_clicked := false;
	create_instance_private: bool;
	create_instance_auto_revive: bool;
	create_instance_create_clicked: bool;
	create_instance_cancel_clicked: bool;

	selected_instance_id := -1;
	localhost := false;

	temp_create_instance_name: string;
	temp_create_instance_password: string;

	temp_enter_instance_password: string;
}

Main_Menu_Args :: struct {
	create_instance_popup_open := false;
	create_instance_name: string;
	create_instance_password: string;

	enter_instance_password: string;

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
		.{ state.controls.window_size.x / 2, 16 },
		32,
		z = 1,
		align = .Top_Center,
		color = V4f.{ 0, 0, 0, 1 }
	);
	push_quad_screen(
		state,
		.{ 16, 64 },
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
		it.private = args.instances[it_index].private;
	}

	table := atom_table(
		state,
		.{ state.controls.window_size.x - 16, 64 + 16 },
		.{ 512 + 128, state.controls.window_size.y - 64 - 16 - 16 - 32 },
		rows,
		id = "table",
		align = Align.Top_Right
	);

	if table.selected_row_index >= 0 && table.selected_row_index < args.instances.count {
		ret.selected_instance_id = args.instances[table.selected_row_index].instance_id;
	}

	lower_input_aabb := pos_size(
		V2f.{ table.aabb_min.x, table.aabb_max.y + 4 },
		V2f.{ table.aabb_max.x - table.aabb_min.x, 32 }
	);
	push_quad_screen(state, lower_input_aabb, v3(GRAY_70), z = 0.02);

	text_button_state: Text_Button;
	cursor := V2f.{ table.aabb_min.x + 8, table.aabb_max.y + 4 + 16 };
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

	input_text_aabb := pos_size(v2(0.0), v2(128.0, 24.0));
	input_text_aabb = align_aabb(input_text_aabb, shrink(lower_input_aabb, 4), Align.Bottom_Right);
	password_input := string_id("password_input");
	ret.temp_enter_instance_password = atom_input_text(
		state,
		args.enter_instance_password,
		24,
		128.0,
		id = password_input,
		placeholder = "Password",
		max_chars = 8,
		_z=1,
		_pos = input_text_aabb.min,
		_align = Align.Bottom_Left
	);

	cursor =  .{ 16, 64 + 16 };

	if args.create_instance_popup_open {
		popup := begin_window(
			state,
			state.controls.window_size / 2,
			V2f.{ 400, 300 },
			Align.Center,
			"create_instance_popup",
			10
		);

		atom_label(
			state,
			"Create Instance",
			popup.pos + V2f.{ popup.size.x / 2, 4 },
			scale = 24,
			z = 10.1,
			align = .Top_Center,
			color = V4f.{ 0, 0, 0, 1 }
		);

		push_quad_screen(
			state,
			popup.pos + V2f.{ 0, 32 },
			V2f.{ popup.size.x, 1 },
			v3(GRAY_10),
			z = 10.1
		);

		cursor := 32.0 + 8 + 8;

		ret.create_instance_private = labeled_checkbox(
			state,
			"Private Instance",
			popup.pos + V2f.{ 4, cursor },
			popup.size.x - 8,
			16,
			z = 10.1,
			align = .Center_Left,
			id = "private_instance_checkbox"
		).checked;
		cursor += 24;

		if ret.create_instance_private {
			ret.temp_create_instance_password = labeled_input_text(
				state,
				"Password",
				args.create_instance_password,
				popup.size.x - 32,
				24,
				scale = 16,
				_pos = popup.pos + V2f.{ 4 + 32, cursor },
				_z = 10.1,
				_align = .Center_Left,
				placeholder = "****",
				max_chars = 8,
				id = "private_instance_password_input",
			);
			cursor += 24;
		}

		ret.create_instance_auto_revive = labeled_checkbox(
			state,
			"Auto revive",
			popup.pos + V2f.{ 4, cursor },
			popup.size.x - 8,
			16,
			z = 10.1,
			align = .Center_Left,
			id = "auto_revive_checkbox"
		).checked;
		cursor += 24;

		ret.temp_create_instance_name = labeled_input_text(
			state,
			"Instance Name",
			args.create_instance_name,
			popup.size.x,
			24,
			scale = 16,
			_pos = popup.pos + V2f.{ 4, cursor },
			_z = 10.1,
			_align = .Center_Left,
			placeholder = "Name",
			max_chars = 16,
			id = "instance_name_input",
		);
		cursor += 24;

		create_clicked, create_button, create_widget := text_button(
			state,
			"Create",
			popup.pos + v2(popup.size.x, popup.size.y) + v2(-14.0, -15),
			align = .Bottom_Right,
			id = "create_instance_button",
			z = 10.1
		);
		ret.create_instance_create_clicked = create_clicked;

		cancel_clicked := text_button(
			state,
			"Cancel",
			popup.pos + v2(popup.size.x, popup.size.y) + v2(-14.0, -15) - v2(width(create_widget.aabb) + 8.0, 0),
			z = 10.1,
			id = "cancel_create_instance_button",
			align = .Bottom_Right
		);
		ret.create_instance_cancel_clicked = cancel_clicked;

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
	push_id(gui, string_id(id));

	state, comp := widget(gui, id, Window);
	comp.physical = .Solid;

	lower_left := align_pos(pos, size, align);

	window_aabb := AABBf.{ lower_left, lower_left + size };
	push_quad_screen(gui, window_aabb, v3(GRAY_20), z);
	push_quad_screen(gui, shrink(window_aabb, 1.0), v3(GRAY_80), z + 0.01);

	state.pos = lower_left;
	state.size = size;

	push_default_params(gui);
	default_params(gui).cursor = lower_left + v2(8.0, 8.0);
	default_params(gui).align = Align.Top_Left;
	default_params(gui).z = z + 0.02;
	default_params(gui).direction = .Down;

	return state;
}

end_window :: (gui: *GUI_State, id := "window") {
	pop_default_params(gui);
	pop_id(gui);
}

Atom_Label :: struct {
	aabb_min: V2f;
	aabb_max: V2f;
	offsets: [] float;
	gui_char_start_index: int;
	gui_char_count: int;
	baseline_y_from_bottom: float;
}
_atom_label :: (
	gui: *GUI_State,
	text: string,
	scale := 16.0,
	color := V4f.{ 1, 1, 1, 1 },
	outline := false,
	id : string = "atom_label",
	_z := FLOAT32_MAX,
	_align := Align.Undefined,
	_pos: V2f = .{ FLOAT32_MAX, FLOAT32_MAX },
	generate_offsets := false,
	offset_pos := V2f.{ 0, 0 }
) -> Atom_Label {
	pos := ifx _pos.x == FLOAT32_MAX then default_params(gui).cursor else _pos;
	z := ifx _z == FLOAT32_MAX then default_params(gui).z else _z;
	align := ifx _align == Align.Undefined then default_params(gui).align else _align;
	pos += offset_pos;

	origin := default_params(gui).cursor;
	defer {
		aabb := widget_aabb(gui, id);
		dir := default_params(gui).direction;
		advance_cursor(gui, origin, dir, aabb);
	}
	return atom_label(
		gui,
		text,
		pos,
		scale,
		z,
		align,
		color,
		outline,
		string_id(id),
		generate_offsets
	);
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
	id : u64 = 0,
	generate_offsets := false
) -> Atom_Label {
	_, w := widget(gui, id, struct {});

	push_id(gui, id);
	defer pop_id(gui);

	ret: Atom_Label;
	ret.baseline_y_from_bottom = 0;

	aabb_min := V2f.{ +FLOAT32_MAX, +FLOAT32_MAX };
	aabb_max := V2f.{ -FLOAT32_MAX, -FLOAT32_MAX };

	if generate_offsets {
		ret.offsets = NewArray(text.count + 1, float,, temp);
		ret.offsets[0] = 0.0;
	}

	cursor := pos;
	ret.gui_char_start_index = gui.chars.count;
	for text {
		glyph := gui.main_font.glyphs[it];
		if glyph.unicode != it
			continue;

		char: GUI_State.Char;
		char.id = it;
		char.pos.x = cursor.x + glyph.planex * scale;
		char.pos.y = cursor.y - glyph.planeh * scale;
		char.size.x = (glyph.planew - glyph.planex) * scale;
		char.size.y = (glyph.planeh - glyph.planey) * scale;
		char.z = z + (it / 256.0 / 1000.0);
		char.color = color;
		char.outline = outline;

		cursor.x += glyph.advance * scale;
		if generate_offsets {
			ret.offsets[it_index + 1] = cursor.x - pos.x;
		}

		aabb_min.x = min(aabb_min.x, char.pos.x);
		aabb_min.y = min(aabb_min.y, char.pos.y);
		aabb_max.x = max(aabb_max.x, char.pos.x + char.size.x);
		aabb_max.y = max(aabb_max.y, char.pos.y + char.size.y);
		ret.baseline_y_from_bottom = min(ret.baseline_y_from_bottom, glyph.planey * scale);
		array_add(*gui.chars, char);
	}
	ret.gui_char_count = gui.chars.count - ret.gui_char_start_index;

	for ret.gui_char_start_index..gui.chars.count-1 {
		char := *gui.chars[it];
		if (align & Align.HCenter) == Align.HCenter {
			char.pos.x -= (cursor.x - pos.x) / 2;
		}
		else if (align & Align.Right) == Align.Right {
			char.pos.x -= (cursor.x - pos.x);
		}
		if (align & Align.VCenter) == Align.VCenter {
			char.pos.y -= (aabb_min.y + aabb_max.y) / 2 - pos.y;
		}
		else if (align & Align.Bottom) == Align.Bottom {
			char.pos.y -= aabb_max.y - pos.y;
		}
		else if (align & Align.Top) == Align.Top {
			char.pos.y -= aabb_min.y - pos.y;
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
		shift := (aabb_min.y + aabb_max.y) / 2 - pos.y;
		aabb_min.y -= shift;
		aabb_max.y -= shift;
	}
	else if (align & Align.Bottom) == Align.Bottom {
		shift := aabb_max.y - pos.y;
		aabb_min.y -= shift;
		aabb_max.y -= shift;
	}
	else if (align & Align.Top) == Align.Top {
		shift := aabb_min.y - pos.y;
		aabb_min.y -= shift;
		aabb_max.y -= shift;
	}

	ret.aabb_min = aabb_min;
	ret.aabb_max = aabb_max;
	w.aabb = .{ ret.aabb_min, ret.aabb_max };
	ret.baseline_y_from_bottom = -ret.baseline_y_from_bottom;
	return ret;
}

atom_label_replace :: (gui: *GUI_State, label: *Atom_Label, aabb: AABBf, align: Align) {
	pos := label.aabb_min;
	size := label.aabb_max - label.aabb_min;

	if (align & Align.HCenter) == Align.HCenter {
		pos.x = (aabb.min.x + aabb.max.x) / 2 - size.x / 2;
	} else if (align & Align.Left) == Align.Left {
		pos.x = aabb.min.x;
	} else if (align & Align.Right) == Align.Right {
		pos.x = aabb.max.x - size.x;
	}

	if (align & Align.VCenter) == Align.VCenter {
		pos.y = (aabb.min.y + aabb.max.y) / 2 - size.y / 2;
	} else if (align & Align.Top) == Align.Top {
		pos.y = aabb.min.y;
	} else if (align & Align.Bottom) == Align.Bottom {
		pos.y = aabb.max.y - size.y;
	}

	shift := pos - label.aabb_min;
	label.aabb_min += shift;
	label.aabb_max += shift;
	for label.gui_char_start_index..label.gui_char_start_index + label.gui_char_count - 1 {
		char := *gui.chars[it];
		char.pos += shift;
	}
}

// Change the position so that (pos, size) is aligned according to align.
// For example, if align is Align.Top_Right, the returned (pos, size) top right corner will be at pos.
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
	else if (align & Align.Bottom) == Align.Bottom {
		ret.y -= size.y;
	}
	return ret;
}
align_aabb :: (aabb: AABBf, align: Align) -> AABBf {
	aligned := aabb;
	aligned.min = align_pos(aabb.min, aabb.max - aabb.min, align);
	aligned.max = aligned.min + (aabb.max - aabb.min);
	return aligned;
}

// Returns the anchor point inside the AABB according to the alignment
// For example, Align.Top_Right returns the top-right corner of the AABB
// Align.Center returns the center point of the AABB
anchor_aabb :: (zone: AABBf, align: Align) -> V2f {
	ret: V2f;
	if (align & Align.HCenter) == Align.HCenter
		ret.x = (zone.min.x + zone.max.x) / 2;
	else if (align & Align.Right) == Align.Right
		ret.x = zone.max.x;
	else
		ret.x = zone.min.x;

	if (align & Align.VCenter) == Align.VCenter
		ret.y = (zone.min.y + zone.max.y) / 2;
	else if (align & Align.Bottom) == Align.Bottom
		ret.y = zone.max.y;
	else
		ret.y = zone.min.y;
	return ret;
}


align_aabb :: (to_align: AABBf, zone: AABBf, align: Align) -> AABBf {
	pos := to_align.min;
	size := to_align.max - to_align.min;
	if (align & Align.HCenter) == Align.HCenter {
		pos.x = (zone.min.x + zone.max.x) / 2 - size.x / 2;
	} else if (align & Align.Left) == Align.Left {
		pos.x = zone.min.x;
	} else if (align & Align.Right) == Align.Right {
		pos.x = zone.max.x - size.x;
	}

	if (align & Align.VCenter) == Align.VCenter {
		pos.y = (zone.min.y + zone.max.y) / 2 - size.y / 2;
	} else if (align & Align.Top) == Align.Top {
		pos.y = zone.min.y;
	} else if (align & Align.Bottom) == Align.Bottom {
		pos.y = zone.max.y - size.y;
	}

	return AABBf.{ pos, pos + size };
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
	text: string,
	scale: float,
	width := 128.0,
	_pos := V2f.{ FLOAT32_MAX, FLOAT32_MAX },
	_z := FLOAT32_MAX,
	_align := Align.Undefined,
	id : u64 = 0,
	placeholder := "",
	max_chars := -1,
	margin := 2.0
) -> string {
	_max_chars := ifx max_chars < 0 then 1024 else max_chars;

	pos := ifx _pos.x == FLOAT32_MAX then default_params(gui).cursor else _pos;
	z := ifx _z == FLOAT32_MAX then default_params(gui).z else _z;
	align := ifx _align == Align.Undefined then default_params(gui).align else _align;

	push_id(gui, id);
	defer pop_id(gui);

	Input_Text :: struct {
		cursor := 0;
	};

	size := v2(width, scale);

	state, comp := widget(gui, "input", Input_Text);
	comp.aabb.min = align_pos(pos, size, align);
	comp.aabb.max = comp.aabb.min + size;
	comp.physical = .Solid;

	push_quad_screen(gui, comp.aabb, v3(GRAY_20), z + 0.01);
	push_quad_screen(gui, shrink(comp.aabb, 1.0), v3(GRAY_90), z + 0.02);

	label := atom_label(
		gui,
		ifx text.count == 0 then placeholder else text,
		comp.aabb.min,
		scale * 0.6,
		z = z + 0.03,
		color = ifx comp.keyboard_focused then GRAY_00 else GRAY_60,
		generate_offsets = true
	);
	atom_label_replace(gui, *label, move(comp.aabb, v2(margin, 0)), .Center_Left);

	ret := tprint("%", text);
	ret.count = min(ret.count, _max_chars);

	if comp.just_pressed {
		comp.keyboard_focused = true;
	}

	if comp.keyboard_focused && gui.controls.just_pressed[Platform.Key.Escape] {
		comp.keyboard_focused = false;
	}

	if comp.keyboard_focused {
		state.cursor = clamp(state.cursor, 0, ret.count);
		cursor_aabb := AABBf.{
			comp.aabb.min + v2(3.0, 5.0),
			V2f.{ 2.0, scale * 0.6 }
		};
		if text.count > 0 {
			cursor_aabb = .{
				label.aabb_min + v2(label.offsets[state.cursor], 0),
				V2f.{ 2.0, label.aabb_max.y - label.aabb_min.y}
			};
		}
		cursor_aabb.max += cursor_aabb.min;
		if placeholder.count == 0 || text.count > 0
			push_quad_screen(gui, cursor_aabb, v3(GRAY_00), z + 0.04);

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
		handle_add(xx Platform.Key._0, "0");
		handle_add(xx Platform.Key._1, "1");
		handle_add(xx Platform.Key._2, "2");
		handle_add(xx Platform.Key._3, "3");
		handle_add(xx Platform.Key._4, "4");
		handle_add(xx Platform.Key._5, "5");
		handle_add(xx Platform.Key._6, "6");
		handle_add(xx Platform.Key._7, "7");
		handle_add(xx Platform.Key._8, "8");
		handle_add(xx Platform.Key._9, "9");
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

	ret.count = min(ret.count, _max_chars);

	return ret;
}

Atom_Table :: struct {
	aabb_min: V2f;
	aabb_max: V2f;

	just_selected_row_index := -1;
	selected_row_index := -1;

	clicked_row_index := -1;
	clicked_col_index := -1;
}
table :: (
	gui: *GUI_State,
	rows: [] $T,
	size: V2f,
	id := "table",
	row_height := 26,
	_pos := V2f.{ FLOAT32_MAX, FLOAT32_MAX },
	_z := FLOAT32_MAX,
	_align := Align.Undefined
) -> Atom_Table {
	pos := ifx _pos.x == FLOAT32_MAX then default_params(gui).cursor else _pos;
	z := ifx _z == FLOAT32_MAX then default_params(gui).z else _z;
	align := ifx _align == Align.Undefined then default_params(gui).align else _align;

	return atom_table(
		gui,
		pos,
		size,
		rows,
		id,
		row_height,
		z,
		align
	);
}

atom_table :: (
	gui: *GUI_State,
	pos: V2f,
	size: V2f,
	rows: [] $T,
	id := "table",
	row_height := 26,
	z := 0.0,
	align := Align.Bottom_Left
) -> Atom_Table {
	ret: Atom_Table;

	State :: struct {
		selected_row_index: int;
	}
	state := widget(gui, id, State);

	lower_left := align_pos(pos, size, align);
	ret.aabb_min = lower_left;
	ret.aabb_max = lower_left + size;

	push_quad_screen(gui, lower_left, size, v3(GRAY_90), z + 0.1);
	push_quad_screen(gui, lower_left, .{ 4, size.y }, v3(GRAY_70), z + 0.2);
	atom_dash_quad(
		gui,
		.{ lower_left.x + 4, lower_left.y },
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
		align_center := false;
		button := false;
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
			if equal(note, "button") {
				it.button = true;
				continue;
			}
			if equal(note, "align(Right)") {
				it.align_right = true;
				continue;
			}
			if equal(note, "align(Center)") {
				it.align_center = true;
				continue;
			}
		}
	}

	cursor := V2f.{ lower_left.x + 4, lower_left.y + row_height / 2 };
	push_id(gui, "col");
	for * cols {
		cursor.x += 4;
		label := atom_label(
			gui,
			it.name,
			cursor,
			14,
			align = .Center_Left,
			z = z + 0.25,
			color = GRAY_00,
			id = xx it_index
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

	cursor = V2f.{ lower_left.x + 4, lower_left.y + row_height / 2 + row_height };
	for row, row_index: rows {
		push_id(gui, row_index);
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
			if it.align_center {
				label_pos.x = cursor.x + it.size / 2;
				align = Align.Center;
			}
			
			if it.button {
				clicked := text_button(
					gui, str, label_pos, z = z + 0.25, id = tprint("%", it_index), align = align
				);
				if clicked {
					ret.clicked_row_index = row_index;
					ret.clicked_col_index = it_index;
				}
			} else {
				atom_label(
					gui,
					str,
					label_pos,
					14,
					align = align,
					z = z + 0.25,
					color = GRAY_00,
					id = xx it_index
				);
			}

			cursor.x += it.size + 4;
		}
		row_aabb_min := V2f.{ lower_left.x + 4, cursor.y - row_height / 2 };
		row_aabb_max := V2f.{ max(cursor.x, lower_left.x + size.x), cursor.y + row_height / 2 };
		if row_aabb_max.x - row_aabb_min.x > size.x - 4 {
			row_aabb_max.x = row_aabb_min.x + size.x - 4;
		}

		background_color := V4f.{ 0, 0, 0, 0 };
		

		if state.selected_row_index == row_index {
			background_color = GRAY_60;
		}
		if point_aabb(gui.controls.mouse_pos, row_aabb_min, row_aabb_max) {
			if gui.controls.just_pressed[Key.MouseLeft] {
				state.selected_row_index = row_index;
				ret.just_selected_row_index = row_index;
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


		cursor.y += row_height;
		push_quad_screen(
			gui,
			.{ lower_left.x + 4, cursor.y - row_height / 2 },
			.{ size.x - 4, 1 },
			v3(GRAY_40),
			z + 0.20
		);
	}

	push_quad_screen(
		gui,
		.{ lower_left.x + 4, lower_left.y + row_height - 1 },
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
	pressed := false;
}

_text_button :: (
	gui: *GUI_State,
	text: string,
	id := "text_button",
	_pos: V2f = V2f.{ FLOAT32_MAX, FLOAT32_MAX },
	_z := FLOAT32_MAX,
	_align := Align.Undefined,
	size: Text_Button.Size = .Small
) -> bool, Text_Button, *GUI_State.Widget
{
	pos := ifx _pos.x == FLOAT32_MAX then default_params(gui).cursor else _pos;
	z := ifx _z == FLOAT32_MAX then default_params(gui).z else _z;
	align := ifx _align == Align.Undefined then default_params(gui).align else _align;

	origin := default_params(gui).cursor;
	defer {
		aabb := widget_aabb(gui, id);
		dir := default_params(gui).direction;
		advance_cursor(gui, origin, dir, aabb);
	}

	a, b, c := text_button(gui, text, pos, z, id, align, size);
	return a, b, c;
}

text_button :: (
	gui: *GUI_State,
	text: string,
	pos: V2f,
	z := 0.0,
	id := "text_button",
	align := Align.Bottom_Left,
	size: Text_Button.Size = .Small
) -> bool, Text_Button, *GUI_State.Widget
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

	scale := 20.0;
	if size == .Medium {
		scale = 24.0;
	} else if size == .Large {
		scale = 28.0;
	}
	text_scale := scale * 0.75;

	label := atom_label(
		gui, text, pos, scale = text_scale, z = z + 1.0, align = align, color = label_color
	);
	// The text could have variable height, so we will make sur that the space between the baseline
	// and the bottom of the button is always the same
	// After adjusting the bottom, we will need to 
	if label.baseline_y_from_bottom < state.aabb_padding.y {
		label.aabb_max.y += state.aabb_padding.y - label.baseline_y_from_bottom;
	}
	widget.aabb.min = label.aabb_min - state.aabb_padding;
	widget.aabb.max = label.aabb_max + state.aabb_padding;
	push_quad_screen(gui, widget.aabb, v3(state.border_color), z);
	push_quad_screen(gui, shrink(widget.aabb, state.border), v3(background_color), z + 0.5);

	state.last_hover = widget.hovered;
	state.clicked = widget.released;
	state.pressed = widget.hovered && gui.controls.pressed[Key.MouseLeft];

	return state.clicked, state, widget;
}

labeled_text_button :: (
	gui: *GUI_State,
	label: string,
	button_text: string,
	width: float,
	height: float,
	_pos := V2f.{ FLOAT32_MAX, FLOAT32_MAX },
	_z := FLOAT32_MAX,
	id := "labeled_text_button",
	_align := Align.Undefined,
	padding := 4.0,
	size: Text_Button.Size = .Small
) -> bool, Text_Button, *GUI_State.Widget {
	_, w := widget(gui, id, struct {});

	pos := ifx _pos.x == FLOAT32_MAX then default_params(gui).cursor else _pos;
	z := ifx _z == FLOAT32_MAX then default_params(gui).z else _z;
	align := ifx _align == Align.Undefined then default_params(gui).align else _align;

	origin := default_params(gui).cursor;
	defer {
		aabb := widget_aabb(gui, id);
		dir := default_params(gui).direction;
		advance_cursor(gui, origin, dir, aabb);
	}

	push_id(gui, id);
	defer pop_id(gui);


	lower_left := align_pos(pos, .{ width, height }, horizontal(align));

	label_comp := atom_label(
		gui,
		label,
		lower_left + v2(padding, 0.0),
		height * 0.6,
		z,
		align = vertical(align) | Align.Left,
		color = GRAY_80,
		id = xx string_id("label")
	);

	clicked, button_state, button_widget := text_button(
		gui,
		button_text,
		lower_left + v2(width - padding, 0),
		z = z,
		id = "button",
		align = vertical(align) | Align.Right,
		size = size
	);

	w.aabb = widgets_aabb(gui, string.[ "label", "button" ]);
	return clicked, button_state, button_widget;
}

Checkbox :: struct {
	checked: bool;

	just_checked := false;
}
checkbox :: (
	gui: *GUI_State,
	pos: V2f,
	size: float,
	z := 0.0,
	id := "checkbox",
	align := Align.Center,
	default := false
) -> Checkbox {
	state, widget := widget(gui, id, Checkbox);

	push_id(gui, id);
	defer pop_id(gui);

	if widget.age == 0 {
		state.checked = default;
	}

	lower_left := align_pos(pos, .{ size, size }, align);

	push_quad_screen(gui, lower_left, .{ size, size }, v3(GRAY_80), z);
	push_quad_screen(gui, lower_left + .{ 1, 1 }, .{ size - 2, size - 2 }, v3(GRAY_10), z + 1);

	if state.checked {
		push_quad_screen(
			gui, lower_left + .{ 4, 4 }, .{ size - 8, size - 8 }, v3(GREEN_BRIGHT), z + 2
		);
	}

	widget.aabb = pos_size(lower_left, v2(size));
	widget.physical = .Mouse;
	state.just_checked = false;
	if point_aabb(gui.controls.mouse_pos, widget.aabb) {
		if gui.controls.just_pressed[Key.MouseLeft] {
			gui.controls.captured_mouse = true;
			state.checked = !state.checked;
			state.just_checked = true;
		}
	}

	return state.*;
}
_labeled_checkbox :: (
	gui: *GUI_State,
	label: string,
	width: float,
	size: float,
	id := "labeled_checkbox",
	_pos: V2f = .{ FLOAT32_MAX, FLOAT32_MAX },
	_z := FLOAT32_MAX,
	_align := Align.Undefined,
	padding := 4.0,
	default := false,
	label_color := GRAY_00
) -> Checkbox {
	pos := ifx _pos.x == FLOAT32_MAX then default_params(gui).cursor else _pos;
	z := ifx _z == FLOAT32_MAX then default_params(gui).z else _z;
	align := ifx _align == Align.Undefined then default_params(gui).align else _align;

	return labeled_checkbox(
		gui,
		label,
		pos,
		width,
		size,
		z,
		id,
		align,
		padding,
		default,
		label_color = label_color
	);
}
labeled_checkbox :: (
	gui: *GUI_State,
	label: string,
	pos: V2f,
	width: float,
	size: float,
	z := 0.0,
	id := "labeled_checkbox",
	align := Align.Center,
	padding := 4.0,
	default := false,
	label_color := GRAY_00
) -> Checkbox {
	_, w := widget(gui, id, struct {});


	origin := default_params(gui).cursor;
	defer {
		aabb := widget_aabb(gui, id);
		dir := default_params(gui).direction;
		advance_cursor(gui, origin, dir, aabb);
	}

	push_id(gui, id);
	defer pop_id(gui);

	lower_left := align_pos(pos, .{ width, size }, horizontal(align));

	label_comp := atom_label(
		gui,
		label,
		lower_left + v2(padding, 0.0),
		size,
		z,
		align = vertical(align) | Align.Left,
		color = label_color,
		id = xx string_id("label")
	);

	checkbox_comp := checkbox(
		gui,
		lower_left + v2(width - padding, 0.0),
		size,
		z,
		align = vertical(align) | Align.Right,
		id = "checkbox",
		default = default
	);

	w.aabb = widgets_aabb(gui, string.[ "label", "checkbox" ]);
	return checkbox_comp;
}

Dropdown :: struct {
	selected_index: int;
	changed := false;
}

dropdown :: (
	gui: *GUI_State,
	options: [] string,
	pos: V2f,
	width: float,
	height: float,
	z := 0.0,
	id := "dropdown",
	align := Align.Bottom_Left,
	default_index := 0
) -> Dropdown {

	Dropdown_Widget :: struct {
		selected_index := 0;
		is_open := false;
	}

	state, widget := widget(gui, id, Dropdown_Widget, .{
		selected_index = default_index,
		is_open = false
	});

	push_id(gui, id);
	defer pop_id(gui);

	ret: Dropdown;
	ret.selected_index = state.selected_index;
	ret.changed = false;

	// Ensure selected index is valid
	if state.selected_index < 0 || state.selected_index >= options.count {
		state.selected_index = 0;
	}

	lower_left := align_pos(pos, .{ width, height }, align);
	header_aabb := AABBf.{ lower_left, lower_left + v2(width, height) };

	// Draw dropdown header (the selected item display)
	push_quad_screen(gui, header_aabb, v3(0.0, 0.0, 0.0), z);
	push_quad_screen(gui, shrink(header_aabb, v2(1.0, 1.0)), v3(1.0, 1.0, 1.0), z + 0.1);

	// Display selected option
	if options.count > 0 && state.selected_index >= 0 && state.selected_index < options.count {
		atom_label(
			gui,
			options[state.selected_index],
			lower_left + v2(4.0, height / 2),
			height * 0.6,
			z + 0.2,
			align = .Center_Left,
			color = v4(0.0, 0.0, 0.0, 1.0),
			id = xx string_id("selected_label")
		);
	}

	// Draw arrow indicator
	arrow_x := lower_left.x + width - height / 2;
	arrow_y := lower_left.y + height / 2;
	arrow_size := height * 0.3;
	if state.is_open {
		// Up arrow (triangle)
		atom_label(
			gui, "^", .{ arrow_x, arrow_y }, height * 0.5, z + 0.2,
			align = .Center, color = v4(0.0, 0.0, 0.0, 1.0), id = xx string_id("arrow")
		);
	} else {
		// Down arrow (v)
		atom_label(
			gui, "v", .{ arrow_x, arrow_y }, height * 0.5, z + 0.2,
			align = .Center, color = v4(0.0, 0.0, 0.0, 1.0), id = xx string_id("arrow")
		);
	}

	// Create header widget for interaction
	_, header_widget := widget_sized(
		gui, "header", struct {}, header_aabb, z + 0.3, .Mouse
	);

	// Toggle dropdown on click
	if header_widget.just_pressed {
		state.is_open = !state.is_open;
	}

	// Draw dropdown list if open
	if state.is_open {
		gui.controls.captured_mouse = true;

		list_y := lower_left.y + height;
		for options {
			option_aabb := AABBf.{
				.{ lower_left.x, list_y },
				.{ lower_left.x + width, list_y + height }
			};

			is_selected := it_index == state.selected_index;
			bg_color := v3(1.0, 1.0, 1.0);
			text_color := v4(0.0, 0.0, 0.0, 1.0);

			// Create widget for this option
			option_id := sprint("option_%", it_index);
			_, option_widget := widget_sized(
				gui, option_id, struct {}, option_aabb, z + 1.0, .Mouse
			);

			// Highlight on hover
			if option_widget.hovered {
				bg_color = v3(0.8, 0.8, 0.8);
			}

			// Highlight if selected
			if is_selected {
				bg_color = v3(0.9, 0.9, 0.9);
			}

			// Draw option background
			push_quad_screen(gui, option_aabb, v3(0.0, 0.0, 0.0), z + 0.9);
			push_quad_screen(gui, shrink(option_aabb, v2(1.0, 1.0)), bg_color, z + 1.0);

			// Draw option text
			atom_label(
				gui,
				it,
				.{ lower_left.x + 4.0, list_y + height / 2 },
				height * 0.6,
				z + 1.1,
				align = .Center_Left,
				color = text_color,
				id = xx string_id(option_id)
			);

			// Handle option click
			if option_widget.just_pressed {
				if state.selected_index != it_index {
					state.selected_index = it_index;
					ret.changed = true;
				}
				state.is_open = false;
			}

			list_y += height;
		}
	}

	widget.aabb = header_aabb;
	ret.selected_index = state.selected_index;

	return ret;
}

_labeled_dropdown :: (
	gui: *GUI_State,
	label: string,
	options: [] string,
	width: float,
	height: float,
	_pos: V2f = .{ FLOAT32_MAX, FLOAT32_MAX },
	_z := FLOAT32_MAX,
	id := "labeled_dropdown",
	_align := Align.Undefined,
	label_color := GRAY_00,
	padding := 4.0,
	default_index := 0
) -> Dropdown {
	pos := ifx _pos.x == FLOAT32_MAX then default_params(gui).cursor else _pos;
	z := ifx _z == FLOAT32_MAX then default_params(gui).z else _z;
	align := ifx _align == Align.Undefined then default_params(gui).align else _align;

	origin := default_params(gui).cursor;
	defer {
		aabb := widget_aabb(gui, id);
		dir := default_params(gui).direction;
		advance_cursor(gui, origin, dir, aabb);
	}

	return labeled_dropdown(
		gui,
		label,
		options,
		pos,
		width,
		height,
		z,
		id,
		align,
		padding,
		default_index,
		label_color=label_color
	);
}

labeled_dropdown :: (
	gui: *GUI_State,
	label: string,
	options: [] string,
	pos: V2f,
	width: float,
	height: float,
	z := 0.0,
	id := "labeled_dropdown",
	align := Align.Bottom_Left,
	padding := 4.0,
	default_index := 0,
	label_color := GRAY_00
) -> Dropdown {
	_, w := widget(gui, id, struct {});

	push_id(gui, id);
	defer pop_id(gui);

	row_aabb := AABBf.{ pos, pos + v2(width, height) };
	row_aabb = align_aabb(row_aabb, align);

	lower_left := align_pos(pos, .{ width, height }, horizontal(align));

	align_label := vertical(align) | Align.Left;
	align_input := vertical(align) | Align.Right;

	label_comp := atom_label(
		gui,
		label,
		anchor_aabb(row_aabb, .Center_Left) + v2(padding, 0.0),
		16,
		z,
		align = Align.Center_Left,
		color = label_color,
		id = xx string_id("label")
	);

	dropdown_width := min(width - widget_width(gui, "label") - padding * 3, 64 + 32);
	dropdown_comp := dropdown(
		gui,
		options,
		anchor_aabb(row_aabb, .Center_Right) - v2(padding, 0.0),
		dropdown_width,
		height,
		z,
		align = Align.Center_Right,
		id = "dropdown",
		default_index = default_index
	);

	w.aabb = widgets_aabb(gui, string.[ "label", "dropdown" ]);
	return dropdown_comp;
}

labeled_input_text :: (
	gui: *GUI_State,
	label: string,
	text: string,
	width: float,
	size: float,
	scale := 16.0,
	id := "labeled_input_text",
	_pos: V2f = .{ FLOAT32_MAX, FLOAT32_MAX },
	max_input_width := 128.0,
	_z := FLOAT32_MAX,
	_align := Align.Undefined,
	label_color := GRAY_00,
	max_chars := -1,
	padding := 4.0,
	placeholder := ""
) -> string {
	_, w := widget(gui, id, struct {});

	origin := default_params(gui).cursor;
	defer {
		aabb := widget_aabb(gui, id);
		dir := default_params(gui).direction;
		advance_cursor(gui, origin, dir, aabb);
	}

	push_id(gui, id);
	defer pop_id(gui);

	pos := ifx _pos.x == FLOAT32_MAX then default_params(gui).cursor else _pos;
	z := ifx _z == FLOAT32_MAX then default_params(gui).z else _z;
	align := ifx _align == Align.Undefined then default_params(gui).align else _align;

	row_aabb := AABBf.{ pos, pos + v2(width, size) };
	row_aabb = align_aabb(row_aabb, align);

	align_label := vertical(align) | Align.Left;
	align_input := vertical(align) | Align.Right;

	lower_left := align_pos(pos, .{ width, size }, horizontal(align));
	label_comp := _atom_label(
		gui,
		label,
		scale,
		_pos = anchor_aabb(row_aabb, .Center_Left) + v2(padding, 0.0),
		_z = z,
		_align = .Center_Left,
		color = label_color,
		id = "label"
	);
	
	input_comp := atom_input_text(
		gui,
		text,
		scale / 0.6,
		min(width - widget_width(gui, "label") - padding * 3, max_input_width),
		_z = z,
		_pos = anchor_aabb(row_aabb, .Center_Right) - v2(padding, 0.0),
		_align = .Center_Right,
		id = xx string_id("input_text"),
		max_chars = max_chars,
		placeholder = placeholder
	);

	w.aabb = row_aabb;
	return input_comp;
}

Integer_Input :: struct {
	value: int;
	changed := false;
	aabb_min: V2f;
	aabb_max: V2f;
}

integer_input :: (
	gui: *GUI_State,
	pos: V2f,
	width: float,
	height: float,
	default_value := 0,
	min_value := S64_MIN,
	max_value := S64_MAX,
	z := 0.0,
	id := "integer_input",
	align := Align.Center
) -> Integer_Input {
	state, widget := widget(gui, id, Integer_Input);

	push_id(gui, id);
	defer pop_id(gui);

	if widget.age == 0 {
		state.value = default_value;
	}

	lower_left := align_pos(pos, .{ width, height }, align);

	text := tprint("%", state.value);
	result := atom_input_text(
		gui,
		AABBf.{ lower_left, lower_left + .{ width, height } },
		height * 0.6,
		text,
		z,
		align = Align.Bottom_Left,
		id = xx string_id("input"),
		max_chars = 20
	);

	state.aabb_min = lower_left;
	state.aabb_max = lower_left + .{ width, height };
	state.changed = false;

	if result != text {
		parsed_value, success := string_to_int(result);
		if success {
			parsed_value = clamp(parsed_value, min_value, max_value);
			if parsed_value != state.value {
				state.value = parsed_value;
				state.changed = true;
			}
		}
	}

	return state.*;
}

labeled_integer_input :: (
	gui: *GUI_State,
	label: string,
	pos: V2f,
	width: float,
	height: float,
	default_value := 0,
	min_value := S64_MIN,
	max_value := S64_MAX,
	z := 0.0,
	id := "labeled_integer_input",
	align := Align.Center,
	padding := 4.0
) -> Integer_Input {
	_, w := widget(gui, id, struct {});

	origin := default_params(gui).cursor;
	defer {
		aabb := widget_aabb(gui, id);
		dir := default_params(gui).direction;
		advance_cursor(gui, origin, dir, aabb);
	}

	push_id(gui, id);
	defer pop_id(gui);

	lower_left := align_pos(pos, .{ width, height }, horizontal(align));

	label_comp := atom_label(
		gui,
		label,
		lower_left + v2(padding, 0.0),
		height * 0.6,
		z,
		align = vertical(align) | Align.Left,
		color = v4(0.0, 0, 0, 1),
		id = xx string_id("label")
	);

	input_width := min(width - widget_width(gui, "label") - padding * 3, 128.0);
	input_comp := integer_input(
		gui,
		lower_left + v2(width - padding, height / 2),
		input_width,
		height,
		default_value = default_value,
		min_value = min_value,
		max_value = max_value,
		z = z,
		align = vertical(align) | Align.Right,
		id = "input"
	);

	w.aabb = widgets_aabb(gui, string.[ "label", "input" ]);
	return input_comp;
}

Slider :: struct {
	value: float;
	changed := false;
	dragging := false;
	aabb_min: V2f;
	aabb_max: V2f;
}

slider :: (
	gui: *GUI_State,
	pos: V2f,
	width: float,
	height: float,
	min_value := 0.0,
	max_value := 1.0,
	default_value := 0.5,
	z := 0.0,
	id := "slider",
	align := Align.Center
) -> Slider {
	state, widget := widget(gui, id, Slider);

	push_id(gui, id);
	defer pop_id(gui);

	if widget.age == 0 {
		state.value = clamp(default_value, min_value, max_value);
	}

	lower_left := align_pos(pos, .{ width, height }, align);

	// Draw background track
	track_height := height * 0.3;
	track_y := lower_left.y + (height - track_height) / 2;
	push_quad_screen(gui, .{ lower_left.x, track_y }, .{ width, track_height }, v3(GRAY_40), z);
	push_quad_screen(gui, .{ lower_left.x + 1, track_y + 1 }, .{ width - 2, track_height - 2 }, v3(GRAY_80), z + 0.01);

	// Calculate handle position
	normalized := (state.value - min_value) / (max_value - min_value);
	normalized = clamp(normalized, 0.0, 1.0);
	handle_size := height * 0.8;
	handle_x := lower_left.x + normalized * (width - handle_size);
	handle_y := lower_left.y + (height - handle_size) / 2;

	// Draw handle
	handle_color := ifx state.dragging then v3(GREEN_BRIGHT) else v3(GRAY_00);
	push_quad_screen(gui, .{ handle_x, handle_y }, .{ handle_size, handle_size }, handle_color, z + 0.02);
	push_quad_screen(gui, .{ handle_x + 2, handle_y + 2 }, .{ handle_size - 4, handle_size - 4 }, v3(GRAY_70), z + 0.03);

	state.aabb_min = lower_left;
	state.aabb_max = lower_left + .{ width, height };
	state.changed = false;

	// Handle interaction
	mouse_in_widget := point_aabb(gui.controls.mouse_pos, lower_left, lower_left + .{ width, height });

	if mouse_in_widget && gui.controls.just_pressed[Key.MouseLeft] {
		state.dragging = true;
		gui.controls.captured_mouse = true;
	}

	if !gui.controls.pressed[Key.MouseLeft] {
		state.dragging = false;
	}

	if state.dragging {
		gui.controls.captured_mouse = true;
		mouse_x := clamp(gui.controls.mouse_pos.x, lower_left.x, lower_left.x + width);
		normalized_new := (mouse_x - lower_left.x) / width;
		new_value := min_value + normalized_new * (max_value - min_value);
		new_value = clamp(new_value, min_value, max_value);

		if new_value != state.value {
			state.value = new_value;
			state.changed = true;
		}
	}

	return state.*;
}

labeled_slider :: (
	gui: *GUI_State,
	label: string,
	pos: V2f,
	width: float,
	height: float,
	min_value := 0.0,
	max_value := 1.0,
	default_value := 0.5,
	z := 0.0,
	id := "labeled_slider",
	align := Align.Center,
	padding := 4.0,
	show_value := true
) -> Slider {
	_, w := widget(gui, id, struct {});

	push_id(gui, id);
	defer pop_id(gui);

	lower_left := align_pos(pos, .{ width, height }, horizontal(align));

	label_comp := atom_label(
		gui,
		label,
		lower_left + v2(padding, 0.0),
		height * 0.6,
		z,
		align = vertical(align) | Align.Left,
		color = v4(0.0, 0, 0, 1),
		id = xx string_id("label")
	);

	value_width := ifx show_value then 50.0 else 0.0;
	slider_width := width - widget_width(gui, "label") - padding * 3 - value_width - ifx show_value then padding else 0.0;
	slider_comp := slider(
		gui,
		lower_left + v2(width - padding - value_width - ifx show_value then padding else 0.0, height / 2),
		slider_width,
		height,
		min_value = min_value,
		max_value = max_value,
		default_value = default_value,
		z = z,
		align = vertical(align) | Align.Right,
		id = "slider"
	);

	if show_value {
		value_label := tprint("%.2f", slider_comp.value);
		atom_label(
			gui,
			value_label,
			lower_left + v2(width - padding, 0.0),
			height * 0.5,
			z,
			align = vertical(align) | Align.Right,
			color = v4(0.0, 0, 0, 1),
			id = xx string_id("value_label")
		);
	}

	w.aabb = widgets_aabb(gui, string.[ "label", "slider" ]);
	return slider_comp;
}

// ============================================================================
// Scroll List Widget
// ============================================================================

Scroll_List :: struct {
	scroll_offset: float;
	content_height: float;
	visible_height: float;
	aabb: AABBf;

	// For clipping - items outside this range should not be rendered
	visible_min_y: float;
	visible_max_y: float;

	is_scrolling := false;
	hovered := false;
}

scroll_list_begin :: (
	gui: *GUI_State,
	pos: V2f,
	width: float,
	height: float,
	content_height: float,
	z := 0.0,
	id := "scroll_list",
	align := Align.Bottom_Left,
	background_color := GRAY_80,
	scrollbar_width := 12.0
) -> *Scroll_List {
	state, widget := widget(gui, id, Scroll_List);

	push_id(gui, id);

	lower_left := align_pos(pos, .{ width, height }, align);

	state.visible_height = height;
	state.content_height = max(content_height, height);
	state.aabb = pos_size(lower_left, v2(width, height));
	state.visible_min_y = lower_left.y;
	state.visible_max_y = lower_left.y + height;

	// Clamp scroll offset
	max_scroll := max(0.0, state.content_height - height);
	state.scroll_offset = clamp(state.scroll_offset, 0.0, max_scroll);

	// Draw background
	push_quad_screen(gui, lower_left, .{ width, height }, v3(GRAY_40), z);
	push_quad_screen(gui, lower_left + v2(1), .{ width - 2, height - 2 }, v3(background_color), z + 0.01);

	// Check if mouse is in the scroll area
	content_area := pos_size(lower_left, v2(width - scrollbar_width, height));
	state.hovered = point_aabb(gui.controls.mouse_pos, content_area);

	// Handle mouse wheel scrolling
	if state.hovered && !gui.controls.captured_mouse {
		scroll_delta := gui.controls.mouse_wheel.(float) * 30.0;
		state.scroll_offset -= scroll_delta;
		state.scroll_offset = clamp(state.scroll_offset, 0.0, max_scroll);
		if gui.controls.mouse_wheel != 0 {
			gui.controls.captured_mouse = true;
		}
	}

	// Draw scrollbar if content is larger than visible area
	if state.content_height > height {
		scrollbar_x := lower_left.x + width - scrollbar_width;
		scrollbar_track_height := height - 4;

		// Track
		push_quad_screen(gui, .{ scrollbar_x + 2, lower_left.y + 2 }, .{ scrollbar_width - 4, scrollbar_track_height }, v3(GRAY_60), z + 0.02);

		// Calculate thumb size and position
		visible_ratio := height / state.content_height;
		thumb_height := max(20.0, scrollbar_track_height * visible_ratio);
		scroll_ratio := state.scroll_offset / max_scroll;
		thumb_y := lower_left.y + 2 + (scrollbar_track_height - thumb_height) * scroll_ratio;

		// Thumb
		thumb_color := ifx state.is_scrolling then v3(GREEN_BRIGHT) else v3(GRAY_20);
		push_quad_screen(gui, .{ scrollbar_x + 4, thumb_y }, .{ scrollbar_width - 8, thumb_height }, thumb_color, z + 0.03);

		// Handle scrollbar dragging
		scrollbar_aabb := pos_size(v2(scrollbar_x, lower_left.y), v2(scrollbar_width, height));
		if point_aabb(gui.controls.mouse_pos, scrollbar_aabb) {
			if gui.controls.just_pressed[Key.MouseLeft] {
				state.is_scrolling = true;
				gui.controls.captured_mouse = true;
			}
		}

		if !gui.controls.pressed[Key.MouseLeft] {
			state.is_scrolling = false;
		}

		if state.is_scrolling {
			gui.controls.captured_mouse = true;
			// Map mouse Y position to scroll offset
			mouse_y_normalized := (gui.controls.mouse_pos.y - lower_left.y - 2 - thumb_height / 2) / (scrollbar_track_height - thumb_height);
			mouse_y_normalized = clamp(mouse_y_normalized, 0.0, 1.0);
			state.scroll_offset = mouse_y_normalized * max_scroll;
		}
	}

	widget.aabb = state.aabb;
	widget.physical = .Mouse;

	return state;
}

// Helper to check if an item is visible within the scroll list
scroll_list_item_visible :: (scroll_list: *Scroll_List, item_y: float, item_height: float) -> bool {
	item_top := item_y;
	item_bottom := item_y + item_height;
	return item_top < scroll_list.visible_max_y && item_bottom > scroll_list.visible_min_y;
}

// Get the adjusted Y position for an item accounting for scroll offset
scroll_list_item_y :: (scroll_list: *Scroll_List, item_index: int, item_height: float, padding := 2.0) -> float {
	base_y := scroll_list.aabb.min.y + padding + item_index.(float) * (item_height + padding);
	return base_y - scroll_list.scroll_offset;
}

scroll_list_end :: (gui: *GUI_State) {
	pop_id(gui);
}

// ============================================================================
// Float Input Widget (Blender-style draggable)
// ============================================================================

Float_Input :: struct {
	value: float;
	changed := false;
	dragging := false;
	editing := false;  // Text editing mode
	drag_start_value: float;
	drag_start_x: float;
	aabb_min: V2f;
	aabb_max: V2f;

	edit_text: [32] u8;
	edit_text_len: int;
	edit_cursor: int;
}

Int_Input :: struct {
	value: int;
	changed := false;
	dragging := false;
	editing := false;  // Text editing mode
	drag_start_value: int;
	drag_start_x: float;
	aabb_min: V2f;
	aabb_max: V2f;

	edit_text: [32] u8;
	edit_text_len: int;
	edit_cursor: int;
}

float_input :: (
	gui: *GUI_State,
	width: float,
	height: float,
	value := 0.0,
	min_value := -FLOAT32_MAX,
	max_value := FLOAT32_MAX,
	drag_speed := 0.01,
	precision := 3,
	_pos: V2f,
	_z := FLOAT32_MAX,
	_align := Align.Center,
	id := "float_input"
) -> Float_Input {
	state, widget := widget(gui, id, Float_Input);
	
	pos := ifx _pos.x == FLOAT32_MAX then default_params(gui).cursor else _pos;
	z := ifx _z == FLOAT32_MAX then default_params(gui).z else _z;
	align := ifx _align == Align.Undefined then default_params(gui).align else _align;

	origin := default_params(gui).cursor;
	defer {
		aabb := widget_aabb(gui, id);
		dir := default_params(gui).direction;
		advance_cursor(gui, origin, dir, aabb);
	}

	push_id(gui, id);
	defer pop_id(gui);
	state.value = clamp(value, min_value, max_value);

	lower_left := align_pos(pos, .{ width, height }, align);

	state.aabb_min = lower_left;
	state.aabb_max = lower_left + .{ width, height };
	state.changed = false;

	widget.aabb = pos_size(lower_left, v2(width, height));
	widget.physical = .Solid;

	mouse_in_widget := point_aabb(gui.controls.mouse_pos, widget.aabb);

	// Background
	border_color := ifx state.editing then v3(GREEN_BRIGHT) else ifx state.dragging then v3(GRAY_00) else v3(GRAY_40);
	push_quad_screen(gui, lower_left, .{ width, height }, border_color, z);
	push_quad_screen(gui, lower_left + v2(1), .{ width - 2, height - 2 }, v3(GRAY_90), z + 0.01);

	// Draw drag indicator arrows on the sides when not editing
	if !state.editing {
		arrow_width := 6.0;
		// Left arrow indicator
		push_quad_screen(gui, lower_left + v2(2.0, height/2.0 - 3.0), v2(arrow_width, 6.0), v3(GRAY_50), z + 0.02);
		// Right arrow indicator
		push_quad_screen(gui, lower_left + v2(width - arrow_width - 2.0, height/2.0 - 3.0), v2(arrow_width, 6.0), v3(GRAY_50), z + 0.02);
	}

	if state.editing {
		// Text editing mode
		text: string;
		text.data = state.edit_text.data;
		text.count = state.edit_text_len;

		label := atom_label(
			gui,
			text,
			lower_left + v2(4.0, height / 2.0),
			height * 0.6,
			z = z + 0.03,
			align = .Center_Left,
			color = GRAY_00,
			generate_offsets = true
		);

		// Draw cursor
		state.edit_cursor = clamp(state.edit_cursor, 0, state.edit_text_len);
		cursor_x := lower_left.x + 4.0 + (ifx label.offsets.count > state.edit_cursor then label.offsets[state.edit_cursor] else 0.0);
		cursor_aabb := pos_size(v2(cursor_x, lower_left.y + 4.0), v2(2.0, height - 8.0));
		push_quad_screen(gui, cursor_aabb, v3(GRAY_00), z + 0.04);

		// Handle keyboard input for text editing
		if widget.keyboard_focused {
			handle_char :: (key: int, char: u8, shift_char: u8 = 0) #expand {
				if gui.controls.just_pressed[key] {
					if state.edit_text_len < 31 {
						actual_char := ifx gui.controls.pressed[Platform.Key.Shift] && shift_char != 0 then shift_char else char;
						// Shift characters after cursor
						for < i: state.edit_text_len..state.edit_cursor + 1 {
							state.edit_text[i] = state.edit_text[i - 1];
						}
						state.edit_text[state.edit_cursor] = actual_char;
						state.edit_text_len += 1;
						state.edit_cursor += 1;
					}
				}
			}

			// Numbers
			handle_char(xx Platform.Key._0, #char "0");
			handle_char(xx Platform.Key._1, #char "1");
			handle_char(xx Platform.Key._2, #char "2");
			handle_char(xx Platform.Key._3, #char "3");
			handle_char(xx Platform.Key._4, #char "4");
			handle_char(xx Platform.Key._5, #char "5");
			handle_char(xx Platform.Key._6, #char "6");
			handle_char(xx Platform.Key._7, #char "7");
			handle_char(xx Platform.Key._8, #char "8");
			handle_char(xx Platform.Key._9, #char "9");
			handle_char(xx Platform.Key.Period, #char ".");
			handle_char(xx Platform.Key.Minus, #char "-");

			// Backspace
			if gui.controls.just_pressed[Platform.Key.Backspace] {
				if state.edit_cursor > 0 && state.edit_text_len > 0 {
					for i: state.edit_cursor - 1..state.edit_text_len - 2 {
						state.edit_text[i] = state.edit_text[i + 1];
					}
					state.edit_text_len -= 1;
					state.edit_cursor -= 1;
				}
			}

			// Arrow keys
			if gui.controls.just_pressed[Platform.Key.Left] {
				state.edit_cursor = max(0, state.edit_cursor - 1);
			}
			if gui.controls.just_pressed[Platform.Key.Right] {
				state.edit_cursor = min(state.edit_text_len, state.edit_cursor + 1);
			}

			// Enter to confirm
			if gui.controls.just_pressed[Platform.Key.Enter] {
				text_str: string;
				text_str.data = state.edit_text.data;
				text_str.count = state.edit_text_len;
				parsed, success := string_to_float(text_str);
				if success {
					parsed = clamp(parsed, min_value, max_value);
					if parsed != state.value {
						state.value = parsed;
						state.changed = true;
					}
				}
				state.editing = false;
				widget.keyboard_focused = false;
			}

			// Escape to cancel
			if gui.controls.just_pressed[Platform.Key.Escape] {
				state.editing = false;
				widget.keyboard_focused = false;
			}
		}
	} else {
		// Display mode - show value
		value_text := tprint("%", formatFloat(state.value, width=precision));
		atom_label(
			gui,
			value_text,
			lower_left + v2(width / 2, height / 2),
			height * 0.6,
			z = z + 0.03,
			align = .Center,
			color = GRAY_00
		);

		// Handle interactions
		if mouse_in_widget {
			// Double-click to enter edit mode
			if widget.released && widget.age > 0 && !state.dragging {
				// Check for double-click (this is a simplified check)
				state.editing = true;
				widget.keyboard_focused = true;
				// Initialize edit text with current value
				value_str := tprint("%", formatFloat(state.value, width=precision));
				for i: 0..min(value_str.count, 31) - 1 {
					state.edit_text[i] = value_str[i];
				}
				state.edit_text_len = min(value_str.count, 31);
				state.edit_cursor = state.edit_text_len;
			}

			// Start dragging on mouse press
			if gui.controls.just_pressed[Key.MouseLeft] {
				state.dragging = true;
				state.drag_start_value = state.value;
				state.drag_start_x = gui.controls.mouse_pos.x;
				gui.controls.captured_mouse = true;
			}
		}
		// Handle dragging
		if state.dragging {
			gui.controls.captured_mouse = true;

			if !gui.controls.pressed[Key.MouseLeft] {
				state.dragging = false;
			} else {
				delta_x := floor((gui.controls.mouse_pos.x - state.drag_start_x) / 4);

				// Adjust speed based on modifiers
				actual_speed := drag_speed;
				if gui.controls.pressed[Platform.Key.Shift] {
					actual_speed *= 0.1;  // Slow down with shift
				}
				if gui.controls.pressed[Platform.Key.Control] {
					actual_speed *= 10.0;  // Speed up with ctrl
				}

				new_value := state.drag_start_value + delta_x * actual_speed;
				new_value = clamp(new_value, min_value, max_value);

				if new_value != state.value {
					state.value = new_value;
					state.changed = true;
				}
			}
		}
	}

	return state.*;
}

int_input :: (
	gui: *GUI_State,
	width: float,
	height: float,
	value: int,
	min_value := S64_MIN,
	max_value := S64_MAX,
	drag_speed := 1,
	_pos := V2f.{ FLOAT32_MAX, FLOAT32_MAX },
	_z := FLOAT32_MAX,
	_align := Align.Undefined,
	id := "int_input"
) -> Int_Input {
	state, widget := widget(gui, id, Int_Input);

	pos := ifx _pos.x == FLOAT32_MAX then default_params(gui).cursor else _pos;
	z := ifx _z == FLOAT32_MAX then default_params(gui).z else _z;
	align := ifx _align == Align.Undefined then default_params(gui).align else _align;

	origin := default_params(gui).cursor;
	defer {
		aabb := widget_aabb(gui, id);
		dir := default_params(gui).direction;
		advance_cursor(gui, origin, dir, aabb);
	}

	push_id(gui, id);
	defer pop_id(gui);
	state.value = clamp(value, min_value, max_value);

	lower_left := align_pos(pos, .{ width, height }, align);

	state.aabb_min = lower_left;
	state.aabb_max = lower_left + .{ width, height };
	state.changed = false;

	widget.aabb = pos_size(lower_left, v2(width, height));
	widget.physical = .Solid;

	mouse_in_widget := point_aabb(gui.controls.mouse_pos, widget.aabb);

	// Background
	border_color := ifx state.editing then v3(GREEN_BRIGHT) else ifx state.dragging then v3(GRAY_00) else v3(GRAY_40);
	push_quad_screen(gui, lower_left, .{ width, height }, border_color, z);
	push_quad_screen(gui, lower_left + v2(1), .{ width - 2, height - 2 }, v3(GRAY_90), z + 0.01);

	// Draw drag indicator arrows on the sides when not editing
	if !state.editing {
		arrow_width := 6.0;
		// Left arrow indicator
		push_quad_screen(gui, lower_left + v2(2.0, height/2.0 - 3.0), v2(arrow_width, 6.0), v3(GRAY_50), z + 0.02);
		// Right arrow indicator
		push_quad_screen(gui, lower_left + v2(width - arrow_width - 2.0, height/2.0 - 3.0), v2(arrow_width, 6.0), v3(GRAY_50), z + 0.02);
	}

	if state.editing {
		// Text editing mode
		text: string;
		text.data = state.edit_text.data;
		text.count = state.edit_text_len;

		label := atom_label(
			gui,
			text,
			lower_left + v2(4.0, height / 2.0),
			height * 0.6,
			z = z + 0.03,
			align = .Center_Left,
			color = GRAY_00,
			generate_offsets = true
		);

		// Draw cursor
		state.edit_cursor = clamp(state.edit_cursor, 0, state.edit_text_len);
		cursor_x := lower_left.x + 4.0 + (ifx label.offsets.count > state.edit_cursor then label.offsets[state.edit_cursor] else 0.0);
		cursor_aabb := pos_size(v2(cursor_x, lower_left.y + 4.0), v2(2.0, height - 8.0));
		push_quad_screen(gui, cursor_aabb, v3(GRAY_00), z + 0.04);

		// Handle keyboard input for text editing
		if widget.keyboard_focused {
			handle_char :: (key: int, char: u8) #expand {
				if gui.controls.just_pressed[key] {
					if state.edit_text_len < 31 {
						// Shift characters after cursor
						for < i: state.edit_text_len..state.edit_cursor + 1 {
							state.edit_text[i] = state.edit_text[i - 1];
						}
						state.edit_text[state.edit_cursor] = char;
						state.edit_text_len += 1;
						state.edit_cursor += 1;
					}
				}
			}

			// Numbers
			handle_char(xx Platform.Key._0, #char "0");
			handle_char(xx Platform.Key._1, #char "1");
			handle_char(xx Platform.Key._2, #char "2");
			handle_char(xx Platform.Key._3, #char "3");
			handle_char(xx Platform.Key._4, #char "4");
			handle_char(xx Platform.Key._5, #char "5");
			handle_char(xx Platform.Key._6, #char "6");
			handle_char(xx Platform.Key._7, #char "7");
			handle_char(xx Platform.Key._8, #char "8");
			handle_char(xx Platform.Key._9, #char "9");
			handle_char(xx Platform.Key.Minus, #char "-");

			// Backspace
			if gui.controls.just_pressed[Platform.Key.Backspace] {
				if state.edit_cursor > 0 && state.edit_text_len > 0 {
					for i: state.edit_cursor - 1..state.edit_text_len - 2 {
						state.edit_text[i] = state.edit_text[i + 1];
					}
					state.edit_text_len -= 1;
					state.edit_cursor -= 1;
				}
			}

			// Arrow keys
			if gui.controls.just_pressed[Platform.Key.Left] {
				state.edit_cursor = max(0, state.edit_cursor - 1);
			}
			if gui.controls.just_pressed[Platform.Key.Right] {
				state.edit_cursor = min(state.edit_text_len, state.edit_cursor + 1);
			}

			// Enter to confirm
			if gui.controls.just_pressed[Platform.Key.Enter] {
				text_str: string;
				text_str.data = state.edit_text.data;
				text_str.count = state.edit_text_len;
				parsed, success, _ := string_to_int(text_str);
				if success {
					parsed = clamp(parsed, min_value, max_value);
					if parsed != state.value {
						state.value = parsed;
						state.changed = true;
					}
				}
				state.editing = false;
				widget.keyboard_focused = false;
			}

			// Escape to cancel
			if gui.controls.just_pressed[Platform.Key.Escape] {
				state.editing = false;
				widget.keyboard_focused = false;
			}
		}
	} else {
		// Display mode - show value
		value_text := tprint("%", state.value);
		atom_label(
			gui,
			value_text,
			lower_left + v2(width / 2, height / 2),
			height * 0.6,
			z = z + 0.03,
			align = .Center,
			color = GRAY_00
		);

		// Handle interactions
		if mouse_in_widget {
			// Double-click to enter edit mode
			if widget.released && widget.age > 0 && !state.dragging {
				state.editing = true;
				widget.keyboard_focused = true;
				// Initialize edit text with current value
				value_str := tprint("%", state.value);
				for i: 0..min(value_str.count, 31) - 1 {
					state.edit_text[i] = value_str[i];
				}
				state.edit_text_len = min(value_str.count, 31);
				state.edit_cursor = state.edit_text_len;
			}

			// Start dragging on mouse press
			if gui.controls.just_pressed[Key.MouseLeft] {
				state.dragging = true;
				state.drag_start_value = state.value;
				state.drag_start_x = gui.controls.mouse_pos.x;
				gui.controls.captured_mouse = true;
			}
		}
		// Handle dragging
		if state.dragging {
			gui.controls.captured_mouse = true;

			if !gui.controls.pressed[Key.MouseLeft] {
				state.dragging = false;
			} else {
				delta_x := cast(int) floor((gui.controls.mouse_pos.x - state.drag_start_x) / 4);

				// Adjust speed based on modifiers
				actual_speed := drag_speed;
				if gui.controls.pressed[Platform.Key.Shift] {
					actual_speed = max(1, actual_speed / 10);  // Slow down with shift
				}
				if gui.controls.pressed[Platform.Key.Control] {
					actual_speed *= 10;  // Speed up with ctrl
				}

				new_value := state.drag_start_value + delta_x * actual_speed;
				new_value = clamp(new_value, min_value, max_value);

				if new_value != state.value {
					state.value = new_value;
					state.changed = true;
				}
			}
		}
	}

	return state.*;
}

labeled_float_input :: (
	gui: *GUI_State,
	label: string,
	width: float,
	height: float,
	value: float,
	min_value := -FLOAT32_MAX,
	max_value := FLOAT32_MAX,
	drag_speed := 0.01,
	precision := 3,
	_pos: V2f = V2f.{ FLOAT32_MAX, FLOAT32_MAX },
	_z := FLOAT32_MAX,
	_align := Align.Undefined,
	id := "labeled_float_input",
	padding := 4.0
) -> Float_Input {
	_, w := widget(gui, id, struct {});

	pos := ifx _pos.x == FLOAT32_MAX then default_params(gui).cursor else _pos;
	z := ifx _z == FLOAT32_MAX then default_params(gui).z else _z;
	align := ifx _align == Align.Undefined then default_params(gui).align else _align;

	origin := default_params(gui).cursor;
	defer {
		aabb := widget_aabb(gui, id);
		dir := default_params(gui).direction;
		advance_cursor(gui, origin, dir, aabb);
	}

	push_id(gui, id);
	defer pop_id(gui);

	lower_left := align_pos(pos, .{ width, height }, horizontal(align));

	label_comp := atom_label(
		gui,
		label,
		lower_left + v2(padding, 0.0),
		height * 0.6,
		z,
		align = vertical(align) | Align.Left,
		color = GRAY_80,
		id = xx string_id("label")
	);

	input_width := min(width - widget_width(gui, "label") - padding * 3, 128.0);
	input_comp := float_input(
		gui,
		input_width,
		height,
		_pos = lower_left + v2(width - padding, 0),
		value = value,
		min_value = min_value,
		max_value = max_value,
		drag_speed = drag_speed,
		precision = precision,
		_z = z,
		_align = vertical(align) | Align.Right,
		id = "input"
	);

	w.aabb = widgets_aabb(gui, string.[ "label", "input" ]);
	return input_comp;
}

labeled_int_input :: (
	gui: *GUI_State,
	label: string,
	width: float,
	height: float,
	value: int,
	min_value := S64_MIN,
	max_value := S64_MAX,
	drag_speed := 1,
	_pos := V2f.{ FLOAT32_MAX, FLOAT32_MAX },
	_z := FLOAT32_MAX,
	id := "labeled_int_input",
	_align := Align.Undefined,
	padding := 4.0
) -> Int_Input {
	_, w := widget(gui, id, struct {});

	origin := default_params(gui).cursor;
	defer {
		aabb := widget_aabb(gui, id);
		dir := default_params(gui).direction;
		advance_cursor(gui, origin, dir, aabb);
	}

	push_id(gui, id);
	defer pop_id(gui);

	pos := ifx _pos.x == FLOAT32_MAX then default_params(gui).cursor else _pos;
	z := ifx _z == FLOAT32_MAX then default_params(gui).z else _z;
	align := ifx _align == Align.Undefined then default_params(gui).align else _align;

	lower_left := align_pos(pos, .{ width, height }, horizontal(align));

	label_comp := atom_label(
		gui,
		label,
		lower_left + v2(padding, 0.0),
		height * 0.6,
		z,
		align = vertical(align) | Align.Left,
		color = GRAY_80,
		id = xx string_id("label")
	);

	input_width := min(width - widget_width(gui, "label") - padding * 3, 128.0);
	input_comp := int_input(
		gui,
		input_width,
		height,
		value = value,
		min_value = min_value,
		max_value = max_value,
		drag_speed = drag_speed,
		_pos = lower_left + v2(width - padding, 0.0),
		_z = z,
		_align = vertical(align) | Align.Right,
		id = "input"
	);

	w.aabb = widgets_aabb(gui, string.[ "label", "input" ]);
	return input_comp;
}

// ============================================================================
// Vector Input Widgets (using Float_Input)
// ============================================================================

V2_Input :: struct {
	value: V2f;
	changed := false;
	x_changed := false;
	y_changed := false;
}

v2_input :: (
	gui: *GUI_State,
	width: float,
	height: float,
	value: V2f,
	min_value := V2f.{ -FLOAT32_MAX, -FLOAT32_MAX },
	max_value := V2f.{ FLOAT32_MAX, FLOAT32_MAX },
	drag_speed := 0.01,
	precision := 3,
	_z := FLOAT32_MAX,
	_pos: V2f = .{ FLOAT32_MAX, FLOAT32_MAX },
	_align := Align.Undefined,
	id := "v2_input",
	labels := string.[ "X", "Y" ],
	label_color := GRAY_00
) -> V2_Input {
	pos := ifx _pos.x == FLOAT32_MAX then default_params(gui).cursor else _pos;
	z := ifx _z == FLOAT32_MAX then default_params(gui).z else _z;
	align := ifx _align == Align.Undefined then default_params(gui).align else _align;

	origin := default_params(gui).cursor;
	defer {
		aabb := widget_aabb(gui, id);
		dir := default_params(gui).direction;
		advance_cursor(gui, origin, dir, aabb);
	}
	state, w := widget(gui, id, V2_Input);

	push_id(gui, id);
	defer pop_id(gui);

	state.value = value;

	lower_left := align_pos(pos, .{ width, height }, align);

	component_width := (width - 4.0) / 2.0;
	input_width := component_width - 4.0;

	state.changed = false;
	state.x_changed = false;
	state.y_changed = false;

	// X component
	x_input := float_input(
		gui,
		input_width,
		height - 4,
		value = state.value.x,
		min_value = min_value.x,
		max_value = max_value.x,
		drag_speed = drag_speed,
		precision = precision,
		_pos = lower_left + v2(0 + 2.0, height / 2),
		_z = z,
		_align = .Center_Left,
		id = "x"
	);
	if x_input.changed {
		state.value.x = x_input.value;
		state.x_changed = true;
		state.changed = true;
	}

	// Y component
	x_offset := component_width + 4.0;
	y_input := float_input(
		gui,
		input_width,
		height - 4,
		value = state.value.y,
		min_value = min_value.y,
		max_value = max_value.y,
		drag_speed = drag_speed,
		precision = precision,
		_pos = lower_left + v2(x_offset + 0 + 2.0, height / 2),
		_z = z,
		_align = .Center_Left,
		id = "y"
	);
	if y_input.changed {
		state.value.y = y_input.value;
		state.y_changed = true;
		state.changed = true;
	}

	w.aabb = pos_size(lower_left, v2(width, height));
	return state.*;
}
labeled_v2_input :: (
	gui: *GUI_State,
	label: string,
	width: float,
	height: float,
	value: V2f,
	min_value := V2f.{ -FLOAT32_MAX, -FLOAT32_MAX },
	max_value := V2f.{ FLOAT32_MAX, FLOAT32_MAX },
	drag_speed := 0.01,
	precision := 3,
	_pos := V2f.{ FLOAT32_MAX, FLOAT32_MAX },
	_z := FLOAT32_MAX,
	id := "labeled_v2_input",
	_align := Align.Undefined,
	padding := 4.0,
	labels := string.[ "X", "Y" ],
	label_color := GRAY_00
) -> V2_Input {
	_, w := widget(gui, id, struct {});

	origin := default_params(gui).cursor;
	defer {
		aabb := widget_aabb(gui, id);
		dir := default_params(gui).direction;
		advance_cursor(gui, origin, dir, aabb);
	}

	push_id(gui, id);
	defer pop_id(gui);

	pos := ifx _pos.x == FLOAT32_MAX then default_params(gui).cursor else _pos;
	z := ifx _z == FLOAT32_MAX then default_params(gui).z else _z;
	align := ifx _align == Align.Undefined then default_params(gui).align else _align;

	lower_left := align_pos(pos, .{ width, height }, align);

	label_comp := atom_label(
		gui,
		label,
		lower_left + v2(padding, 0.0),
		height * 0.6,
		z,
		align = Align.Center_Left,
		color = label_color,
		id = xx string_id("label")
	);

	input_width := width - widget_width(gui, "label") - padding * 3;
	input_comp := v2_input(
		gui,
		input_width,
		height,
		value = value,
		min_value = min_value,
		max_value = max_value,
		drag_speed = drag_speed,
		precision = precision,
		_pos = lower_left + v2(width - padding, 0.0),
		_z = z,
		_align = Align.Center_Right,
		id = "input",
		labels = labels,
		label_color = label_color
	);

	w.aabb = widgets_aabb(gui, string.[ "label", "input" ]);
	return input_comp;
}


V3_Input :: struct {
	value: V3f;
	changed := false;
	x_changed := false;
	y_changed := false;
	z_changed := false;
}

v3_input :: (
	gui: *GUI_State,
	width: float,
	height: float,
	value: V3f,
	id := "v3_input",
	min_value := V3f.{ -FLOAT32_MAX, -FLOAT32_MAX, -FLOAT32_MAX },
	max_value := V3f.{ FLOAT32_MAX, FLOAT32_MAX, FLOAT32_MAX },
	drag_speed := 0.01,
	precision := 3,
	_pos: V2f = .{ FLOAT32_MAX, FLOAT32_MAX },
	_z := FLOAT32_MAX,
	_align := Align.Undefined,
	labels := string.[ "X", "Y", "Z" ]
) -> V3_Input {
	pos := ifx _pos.x == FLOAT32_MAX then default_params(gui).cursor else _pos;
	z := ifx _z == FLOAT32_MAX then default_params(gui).z else _z;
	align := ifx _align == Align.Undefined then default_params(gui).align else _align;

	state, w := widget(gui, id, V3_Input);
 
	push_id(gui, id);
	defer pop_id(gui);

	state.value = value;

	lower_left := align_pos(pos, .{ width, height }, align);

	component_width := width / 3.0;
	label_width := 16.0;
	input_width := component_width - label_width - 4.0;

	state.changed = false;
	state.x_changed = false;
	state.y_changed = false;
	state.z_changed = false;

	// X component
	// atom_label(
	// 	gui,
	// 	labels[0],
	// 	lower_left + v2(2.0, height / 2.0),
	// 	height * 0.5, z, align = .Center_Left, color = GRAY_80, id = xx 0
	// );
	x_input := float_input(
		gui,
		component_width,
		height - 4.0,
		value = state.value.x,
		min_value = min_value.x,
		max_value = max_value.x,
		drag_speed = drag_speed,
		precision = precision,
		_pos = lower_left + v2(0.0, height / 2.0),
		_align = .Center_Left,
		id = "x"
	);
	if x_input.changed {
		state.value.x = x_input.value;
		state.x_changed = true;
		state.changed = true;
	}

	// Y component
	x_offset := component_width + 4.0;
	// atom_label(gui, labels[1], lower_left + v2(x_offset + 2.0, height / 2.0), height * 0.5, z, align = .Center_Left, color = GRAY_80, id = xx 1);
	y_input := float_input(
		gui,
		component_width,
		height - 4.0,
		value = state.value.y,
		min_value = min_value.y,
		max_value = max_value.y,
		drag_speed = drag_speed,
		precision = precision,
		_pos = lower_left + v2(x_offset + 2.0, height / 2.0),
		_align = .Center_Left,
		id = "y"
	);
	if y_input.changed {
		state.value.y = y_input.value;
		state.y_changed = true;
		state.changed = true;
	}

	// Z component
	x_offset2 := 2.0 * component_width + 8.0;
	// atom_label(gui, labels[2], lower_left + v2(x_offset2 + 2.0, height / 2.0), height * 0.5, z, align = .Center_Left, color = GRAY_80, id = xx 2);
	z_input := float_input(
		gui,
		component_width,
		height - 4.0,
		value = state.value.z,
		min_value = min_value.z,
		max_value = max_value.z,
		drag_speed = drag_speed,
		precision = precision,
		_pos = lower_left + v2(x_offset2 + 2.0, height / 2.0),
		_align = .Center_Left,
		id = "zcomp"
	);
	if z_input.changed {
		state.value.z = z_input.value;
		state.z_changed = true;
		state.changed = true;
	}

	w.aabb = pos_size(lower_left, v2(width, height));
	return state.*;
}

labeled_v3_input :: (
	gui: *GUI_State,
	label: string,
	width: float,
	height: float,
	value: V3f,
	min_value := V3f.{ -FLOAT32_MAX, -FLOAT32_MAX, -FLOAT32_MAX },
	max_value := V3f.{ FLOAT32_MAX, FLOAT32_MAX, FLOAT32_MAX },
	drag_speed := 0.01,
	precision := 3,
	_pos := V2f.{ FLOAT32_MAX, FLOAT32_MAX },
	_z := FLOAT32_MAX,
	id := "labeled_v3_input",
	_align := Align.Undefined,
	padding := 4.0,
	labels := string.[ "X", "Y", "Z" ]
) -> V3_Input {
	_, w := widget(gui, id, struct {});

	origin := default_params(gui).cursor;
	defer {
		aabb := widget_aabb(gui, id);
		dir := default_params(gui).direction;
		advance_cursor(gui, origin, dir, aabb);
	}
	push_id(gui, id);
	defer pop_id(gui);

	pos := ifx _pos.x == FLOAT32_MAX then default_params(gui).cursor else _pos;
	z := ifx _z == FLOAT32_MAX then default_params(gui).z else _z;
	align := ifx _align == Align.Undefined then default_params(gui).align else _align;

	lower_left := align_pos(pos, .{ width, height }, horizontal(align));

	label_comp := atom_label(
		gui,
		label,
		lower_left + v2(padding, 0.0),
		height * 0.6,
		z,
		align = vertical(align) | Align.Left,
		color = GRAY_80,
		id = xx string_id("label")
	);

	input_width := width - widget_width(gui, "label") - padding * 3;
	input_comp := v3_input(
		gui,
		input_width,
		height,
		value = value,
		min_value = min_value,
		max_value = max_value,
		drag_speed = drag_speed,
		precision = precision,
		_pos = lower_left + v2(width - padding, 0.0),
		_z = z,
		_align = vertical(align) | Align.Right,
		id = "input",
		labels = labels
	);

	w.aabb = widgets_aabb(gui, string.[ "label", "input" ]);
	return input_comp;
}
