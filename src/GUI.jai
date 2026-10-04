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

Nine_Slice_Edge_Mode :: enum {
	Stretch;
	Mirror_Repeat;
}

Nine_Slice_Center_Mode :: enum {
	Stretch;
	Transparent;
}

Texture_Address_Mode :: enum {
	Clamp;
	Repeat;
}

Nine_Slice_Style :: struct {
	texture: *void = null;
	texture_size: V2f;
	// Source-space pixel borders in left, top, right, bottom order.
	borders: V4f;
	scale: float32 = 0.8;
	edge_mode: Nine_Slice_Edge_Mode = .Mirror_Repeat;
	center_mode: Nine_Slice_Center_Mode = .Stretch;
	fill_color: V4f = .{ 0, 0, 0, 0 };
	fill_inset: float32 = 0;
}

Table_Style :: struct {
	selectable := true;
	vertical_rules := true;
	dashed_header := true;
	header_size := 14.0;
	compact_icons := false;
	background_color: V4f = .{ 0.9, 0.9, 0.9, 1 };
	left_rail_color: V4f = .{ 0.7, 0.7, 0.7, 1 };
	header_color: V4f = .{ 1, 1, 1, 1 };
	text_color: V4f = .{ 1, 1, 1, 1 };
	separator_color: V4f = .{ 0.4, 0.4, 0.4, 1 };
	selected_color: V4f = .{ 0.6, 0.6, 0.6, 1 };
	hover_color: V4f = .{ 0.3, 0.3, 0.3, 1 };
	selected_row_skin: Nine_Slice_Style;
	button_skin: Nine_Slice_Style;
}

#load "GUI_String.jai";

Z_SLOT :: V2f.{ 0, 15 };
RELOAD_SLOT :: V2f.{ 10, 15 };
PLAY_SLOT :: V2f.{ 11, 15 };
EYE_SLOT :: V2f.{ 12, 15 };
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
SHIELD_SLOT :: V2f.{ 10, 11 };
EXPLOSION_TIME_SLOT :: V2f.{ 9, 11 };
CROSS_LENGTH_SLOT :: V2f.{ 8, 11 };

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
		FLAG_COIN :: 4;
		FLAG_COIN_SHADOW :: 8;
		pos: V2f;
		size: V2f;
		color: V4f = .{ 1.0, 1.0, 1.0, 1.0 };
		z: float32 = 0;
		texture_rect: V4f = .{ 0, 0, 0, 0 };
		custom_texture: *void = null;
		late := false;
		custom_texture_idx := -1;
		address_mode: Texture_Address_Mode = .Clamp;
		flags: u32;
		rotation: float32;
		coin_face: float32 = 1;
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
	mouse_left_owner: u64;
	mouse_right_owner: u64;

	main_font: *Platform.Font;

	Direction :: enum {
		Right :: 0;
		Down :: 1;
		Left :: 2;
		Up :: 3;
	}
	Flow :: struct {
		z := 0.0;
		direction: Direction = .Down;
		align: Align = .Top_Left;
		cursor := V2f.{ 0, 0 };
		origin := V2f.{ 0, 0 };
		padding: V2f = V2f.{ 8, 8 };
		child_ids: [..] u64;
		has_cursor_extent := false;
		cursor_extent: AABBf;
		has_fixed_bounds := false;
		fixed_bounds: AABBf;
	}
	flow_stack: [..] Flow;

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
		modal_barrier := false;

		age: int = 0;
	}
	widgets: Table(u64, Widget);

	id_stack: [..] u64;
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

flow :: (state: *GUI_State) -> *GUI_State.Flow {
	if state.flow_stack.count == 0 {
		array_add(*state.flow_stack, .{});
	}
	return *state.flow_stack[state.flow_stack.count - 1];
}

clear_flow_stack :: (state: *GUI_State) {
	for * state.flow_stack {
		array_free(it.child_ids);
	}
	state.flow_stack.count = 0;
}

push_flow :: (
	gui: *GUI_State,
	direction: GUI_State.Direction,
	origin: V2f,
	has_origin: bool,
	z: float,
	align: Align
) {
	parent := flow(gui).*;
	child := parent;
	empty_ids: [..] u64;
	child.child_ids = empty_ids;
	child.has_cursor_extent = false;
	child.cursor_extent = .{};
	child.has_fixed_bounds = false;
	child.direction = direction;
	if has_origin {
		child.cursor = origin;
		child.origin = origin;
	} else {
		child.origin = child.cursor;
	}
	if z != FLOAT32_MAX {
		child.z = z;
	}
	if align != .Undefined {
		child.align = align;
	}
	array_add(*gui.flow_stack, child);
}

begin :: (gui: *GUI_State, direction: GUI_State.Direction, z := FLOAT32_MAX, align := Align.Undefined) {
	push_flow(gui, direction, .{}, false, z, align);
}

begin :: (gui: *GUI_State, origin: V2f, direction: GUI_State.Direction, z := FLOAT32_MAX, align := Align.Undefined) {
	push_flow(gui, direction, origin, true, z, align);
}

begin :: (gui: *GUI_State, z := FLOAT32_MAX, align := Align.Undefined) {
	begin(gui, flow(gui).direction, z, align);
}

column :: (gui: *GUI_State, z := FLOAT32_MAX, align := Align.Undefined) {
	begin(gui, .Down, z, align);
}
column :: (gui: *GUI_State, direction: GUI_State.Direction, z := FLOAT32_MAX, align := Align.Undefined) {
	begin(gui, direction, z, align);
}
column :: (gui: *GUI_State, origin: V2f, direction := GUI_State.Direction.Down, z := FLOAT32_MAX, align := Align.Undefined) {
	begin(gui, origin, direction, z, align);
}
row :: (gui: *GUI_State, z := FLOAT32_MAX, align := Align.Undefined) {
	begin(gui, .Right, z, align);
}
row :: (gui: *GUI_State, direction: GUI_State.Direction, z := FLOAT32_MAX, align := Align.Undefined) {
	begin(gui, direction, z, align);
}
row :: (gui: *GUI_State, origin: V2f, direction := GUI_State.Direction.Right, z := FLOAT32_MAX, align := Align.Undefined) {
	begin(gui, origin, direction, z, align);
}


// A sized container occupies one slot in its parent flow. Its children use
// their own cursor and cannot change that slot's dimensions.
box :: (
	gui: *GUI_State,
	size: V2f,
	direction := GUI_State.Direction.Down,
	inset := V2f.{ 0, 0 },
	gap := V2f.{ 0, 0 },
	z := FLOAT32_MAX
) -> AABBf {
	origin := flow(gui).cursor;
	begin(gui, direction, z, .Top_Left);
	f := flow(gui);
	f.has_fixed_bounds = true;
	f.fixed_bounds = .{ origin, origin + size };
	f.cursor = origin + inset;
	f.origin = f.cursor;
	f.padding = gap;
	return f.fixed_bounds;
}

end :: (gui: *GUI_State) {
	assert(gui.flow_stack.count > 0);
	if gui.flow_stack.count == 0
		return;

	aabb := container_aabb(gui);
	top := *gui.flow_stack[gui.flow_stack.count - 1];

	if gui.flow_stack.count > 1 {
		parent := *gui.flow_stack[gui.flow_stack.count - 2];
		grow_flow_extent(parent, aabb);
		for id: top.child_ids {
			array_add(*parent.child_ids, id);
		}
	}

	array_free(top.child_ids);
	gui.flow_stack.count -= 1;

	if gui.flow_stack.count > 0 {
		parent := flow(gui);
		advance_cursor(gui, parent.cursor, parent.direction, aabb);
	}
}

along_direction :: (direction: GUI_State.Direction, amount: float) -> V2f {
	if #complete direction == {
		case .Right; return .{ amount, 0 };
		case .Left;  return .{ -amount, 0 };
		case .Down;  return .{ 0, amount };
		case .Up;    return .{ 0, -amount };
	}
	return .{};
}

grow_flow_extent :: (f: *GUI_State.Flow, aabb: AABBf) {
	if f.has_cursor_extent {
		f.cursor_extent = aabb_union(f.cursor_extent, aabb);
	} else {
		f.cursor_extent = aabb;
		f.has_cursor_extent = true;
	}
}

aabb_from_points :: (a: V2f, b: V2f) -> AABBf {
	return .{
		min = .{ min(a.x, b.x), min(a.y, b.y) },
		max = .{ max(a.x, b.x), max(a.y, b.y) },
	};
}

move_cursor :: (state: *GUI_State, delta: V2f) {
	f := flow(state);
	old := f.cursor;
	f.cursor += delta;
	grow_flow_extent(f, aabb_from_points(old, f.cursor));
}
move_cursor :: (state: *GUI_State, delta: float) {
	move_cursor(state, along_direction(flow(state).direction, delta));
}
space :: (state: *GUI_State, amount: float) {
	move_cursor(state, amount);
}

horizontal_rule :: (
	state: *GUI_State,
	width: float,
	color := LOBBY_SEPARATOR,
	thickness := 1.0,
	z := FLOAT32_MAX
) {
	f := flow(state);
	push_quad_screen(
		state,
		f.cursor,
		.{ width, thickness },
		v3(color),
		ifx z == FLOAT32_MAX then f.z else z,
		color.w
	);
	space(state, thickness);
}

advance_cursor :: (gui: *GUI_State, origin: V2f, dir: GUI_State.Direction, aabb: AABBf) {
	grow_flow_extent(flow(gui), aabb);
	extent := aabb_width(aabb) + flow(gui).padding.x;
	if dir == .Down || dir == .Up {
		extent = aabb_height(aabb) + flow(gui).padding.y;
	}
	flow(gui).cursor = origin + along_direction(dir, extent);
}

finish_widget :: (gui: *GUI_State, origin: V2f, id: $Id)
#modify {
	if Id == u64 || Id == s64 || Id == string {
		return true;
	}
	return false;
}
{
	aabb := widget_aabb(gui, id);
	advance_cursor(gui, origin, flow(gui).direction, aabb);
}

place :: (gui: *GUI_State, pos: V2f, z: float, align: Align) {
	f := flow(gui);
	f.cursor = pos;
	f.origin = pos;
	f.z = z;
	f.align = align;
}

container_aabb :: (gui: *GUI_State) -> AABBf {
	if gui.flow_stack.count == 0 {
		return AABBf.{ .{ 0, 0 }, .{ 0, 0 } };
	}
	f := *gui.flow_stack[gui.flow_stack.count - 1];
	if f.has_fixed_bounds return f.fixed_bounds;
	aabb := AABBf.{ f.origin, f.origin };
	// Layout is recorded when a flow widget advances, not by walking its
	// internal state/label widgets (which may have no bounds or overlap).
	if f.has_cursor_extent {
		aabb = aabb_union(aabb, f.cursor_extent);
	}
	return aabb;
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
	array_add(*flow(state).child_ids, iid);

	user_state := table_find_pointer(*state.widgets, iid);
	if user_state {
		if user_state.user_size == size_of(T) {
			user_state.touched = true;
			return user_state.user.(*T), user_state;
		}
		free(user_state.user);
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
			free(value.user);
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
	out_controls.text_input = "";
	state.controls.text_input = info.text_input;
	state.controls.text_input_active = false;
	state.controls.text_input_consumed = false;

	state.controls.keys = Platform.advance_keys(
		state.controls.keys,
		info.keys.pressed,
		info.keys.just_released
	);
	state.controls.mouse_pos.x = info.mouse_position.x;
	state.controls.mouse_pos.y = info.mouse_position.y;
	state.controls.mouse_wheel = info.mouse_wheel;
	state.controls.window_size.x = info.window_size.x;
	state.controls.window_size.y = info.window_size.y;

	// Reset the captured flags for the frame that is about to start
	state.controls.captured_keyboard = false;
	state.controls.captured_mouse = false;
	state.controls.is_mobile = info.is_mobile;
	state.controls.touch_just_pressed = info.touch_down && !state.controls.touch_down;
	state.controls.touch_down = info.touch_down;
	state.controls.delta_time = info.delta_time;
	state.controls.time = info.time;
	// Use the user's preferred layout override instead of the auto-detected one
	if info.layout == .Unknown
		state.controls.layout = layout_override;
	else
		state.controls.layout = info.layout;


	state.chars.count = 0;
	state.quads.count = 0;

	clear_flow_stack(state);

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
	keyboard_blocked := false;
	left_available := true;
	right_available := true;
	if state.controls.just_pressed[Key.MouseLeft] state.mouse_left_owner = 0;
	if state.controls.just_pressed[Key.MouseRight] state.mouse_right_owner = 0;

	for widget_ids {
		widget := table_find_pointer(*state.widgets, it.id);
		if !widget continue;
		widget.hovered = false;
		widget.pressed = false;
		widget.released = false;
		widget.just_pressed = false;
		if keyboard_blocked || met_keyboard_focused || state.controls.just_pressed[Key.MouseLeft]
			widget.keyboard_focused = false;
		if widget.keyboard_focused met_keyboard_focused = true;
		if widget.modal_barrier {
			keyboard_blocked = true;
			state.controls.captured_keyboard = true;
		}
		if widget.physical == .Empty || area(widget.aabb) <= 0 continue;
		if !in(widget.aabb, state.controls.mouse_pos) continue;

		if left_available && (widget.physical & .Mouse_Left) != .Empty {
			widget.hovered = true;
			left_available = false;
			if state.controls.just_pressed[Key.MouseLeft] {
				state.mouse_left_owner = it.id;
				widget.just_pressed = true;
			}
			if state.mouse_left_owner == it.id {
				widget.pressed = state.controls.pressed[Key.MouseLeft];
				widget.released = state.controls.just_released[Key.MouseLeft];
			}
			state.controls.captured_mouse = true;
		}
		if right_available && (widget.physical & .Mouse_Right) != .Empty {
			widget.hovered = true;
			right_available = false;
			if state.controls.just_pressed[Key.MouseRight] {
				state.mouse_right_owner = it.id;
				widget.just_pressed = true;
			}
			if state.mouse_right_owner == it.id {
				widget.pressed |= state.controls.pressed[Key.MouseRight];
				widget.released |= state.controls.just_released[Key.MouseRight];
			}
			state.controls.captured_mouse = true;
		}
	}
	if state.controls.just_released[Key.MouseLeft] state.mouse_left_owner = 0;
	if state.controls.just_released[Key.MouseRight] state.mouse_right_owner = 0;
	state.controls.captured_keyboard |= met_keyboard_focused;
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

push_quad_custom_texture :: (
	state: *GUI_State,
	pos: V2f,
	size: V2f,
	texture: *void,
	texture_rect := V4f.{ 0, 0, 1, 1 },
	z := 0.0,
	color := V4f.{ 1, 1, 1, 1 }
) -> *state.Quad {
	quad: state.Quad;
	quad.pos = pos;
	quad.size = size;
	quad.color = color;
	quad.texture_rect = texture_rect;
	quad.custom_texture = texture;
	quad.late = true;
	quad.z = z;
	array_add(*state.quads, quad);
	return *state.quads[state.quads.count - 1];
}

push_tiled_texture :: (
	state: *GUI_State,
	pos: V2f,
	size: V2f,
	texture: *void,
	texture_size: V2f,
	z := 0.0,
	color := V4f.{ 1, 1, 1, 1 }
) -> *state.Quad {
	if !texture || texture_size.x <= 0 || texture_size.y <= 0 || size.x <= 0 || size.y <= 0
		return null;

	uv_size := V2f.{ size.x / texture_size.x, size.y / texture_size.y };
	quad := push_quad_custom_texture(
		state,
		pos,
		size,
		texture,
		.{ 0, 0, uv_size.x, uv_size.y },
		z,
		color
	);
	quad.address_mode = .Repeat;
	return quad;
}

push_nine_slice_piece :: (
	state: *GUI_State,
	pos: V2f,
	size: V2f,
	texture: *void,
	texture_size: V2f,
	source: V4f,
	z: float32,
	color: V4f,
	mirror_x := false,
	mirror_y := false
) {
	if size.x <= 0 || size.y <= 0 || source.z <= 0 || source.w <= 0
		return;

	uv: V4f;
	uv.x = (source.x + 0.5) / texture_size.x;
	uv.y = (source.y + 0.5) / texture_size.y;
	uv.z = max(source.z - 1, 0.0001) / texture_size.x;
	uv.w = max(source.w - 1, 0.0001) / texture_size.y;
	if mirror_x {
		uv.x += uv.z;
		uv.z = -uv.z;
	}
	if mirror_y {
		uv.y += uv.w;
		uv.w = -uv.w;
	}
	push_quad_custom_texture(state, pos, size, texture, uv, z, color);
}

push_nine_slice :: (
	state: *GUI_State,
	pos: V2f,
	size: V2f,
	style: Nine_Slice_Style,
	z := 0.0,
	color := V4f.{ 1, 1, 1, 1 }
) {
	texture := style.texture;
	texture_size := style.texture_size;
	if !texture || texture_size.x <= 0 || texture_size.y <= 0 || size.x <= 0 || size.y <= 0 || style.scale <= 0
		return;

	left := max(0.0, style.borders.x);
	top := max(0.0, style.borders.y);
	right := max(0.0, style.borders.z);
	bottom := max(0.0, style.borders.w);
	if left + right > texture_size.x || top + bottom > texture_size.y return;
	slice_scale := max(0.0, style.scale);
	if left + right > 0
		slice_scale = min(slice_scale, size.x / (left + right));
	if top + bottom > 0
		slice_scale = min(slice_scale, size.y / (top + bottom));
	dest_left := left * slice_scale;
	dest_top := top * slice_scale;
	dest_right := right * slice_scale;
	dest_bottom := bottom * slice_scale;
	center_width := max(0.0, size.x - dest_left - dest_right);
	center_height := max(0.0, size.y - dest_top - dest_bottom);
	source_center_width := max(0.0, texture_size.x - left - right);
	source_center_height := max(0.0, texture_size.y - top - bottom);

	if style.fill_color.w > 0 {
		fill_inset := style.fill_inset * slice_scale;
		fill_size := size - V2f.{ fill_inset * 2, fill_inset * 2 };
		if fill_size.x > 0 && fill_size.y > 0 {
			fill_color := V4f.{
				style.fill_color.x * color.x,
				style.fill_color.y * color.y,
				style.fill_color.z * color.z,
				style.fill_color.w * color.w,
			};
			push_quad_screen(
				state,
				pos + V2f.{ fill_inset, fill_inset },
				fill_size,
				v3(fill_color),
				z - 0.001,
				fill_color.w
			);
		}
	}

	if style.center_mode == .Stretch && center_width > 0 && center_height > 0 {
		push_nine_slice_piece(
			state,
			pos + V2f.{ dest_left, dest_top },
			V2f.{ center_width, center_height },
			texture,
			texture_size,
			V4f.{ left, top, source_center_width, source_center_height },
			z,
			color
		);
	}

	// Repeat the long rails at the authored UI scale; mirror alternate segments
	// so the metal grain stays continuous without stretching over large panels.
	if source_center_width > 0 && center_width > 0 {
		repeat_count := 1;
		if style.edge_mode == .Mirror_Repeat && slice_scale > 0 {
			repeat_count = max(
				1,
				ceil(center_width / (source_center_width * slice_scale * 1.25)).(int)
			);
		}
		for i: 0..repeat_count - 1 {
			segment_start := center_width * i / repeat_count;
			segment_end := center_width * (i + 1) / repeat_count;
			mirror := i % 2 == 1;
			push_nine_slice_piece(
				state,
				pos + V2f.{ dest_left + segment_start, 0 },
				V2f.{ segment_end - segment_start, dest_top },
				texture,
				texture_size,
				V4f.{ left, 0, source_center_width, top },
				z,
				color,
				mirror_x = mirror
			);
			push_nine_slice_piece(
				state,
				pos + V2f.{ dest_left + segment_start, size.y - dest_bottom },
				V2f.{ segment_end - segment_start, dest_bottom },
				texture,
				texture_size,
				V4f.{ left, texture_size.y - bottom, source_center_width, bottom },
				z,
				color,
				mirror_x = mirror
			);
		}
	}

	if source_center_height > 0 && center_height > 0 {
		repeat_count := 1;
		if style.edge_mode == .Mirror_Repeat && slice_scale > 0 {
			repeat_count = max(
				1,
				ceil(center_height / (source_center_height * slice_scale * 1.25)).(int)
			);
		}
		for i: 0..repeat_count - 1 {
			segment_start := center_height * i / repeat_count;
			segment_end := center_height * (i + 1) / repeat_count;
			mirror := i % 2 == 1;
			push_nine_slice_piece(
				state,
				pos + V2f.{ 0, dest_top + segment_start },
				V2f.{ dest_left, segment_end - segment_start },
				texture,
				texture_size,
				V4f.{ 0, top, left, source_center_height },
				z,
				color,
				mirror_y = mirror
			);
			push_nine_slice_piece(
				state,
				pos + V2f.{ size.x - dest_right, dest_top + segment_start },
				V2f.{ dest_right, segment_end - segment_start },
				texture,
				texture_size,
				V4f.{ texture_size.x - right, top, right, source_center_height },
				z,
				color,
				mirror_y = mirror
			);
		}
	}

	push_nine_slice_piece(
		state, pos, V2f.{ dest_left, dest_top }, texture, texture_size,
		V4f.{ 0, 0, left, top }, z, color
	);
	push_nine_slice_piece(
		state, pos + V2f.{ size.x - dest_right, 0 }, V2f.{ dest_right, dest_top },
		texture, texture_size, V4f.{ texture_size.x - right, 0, right, top }, z, color
	);
	push_nine_slice_piece(
		state, pos + V2f.{ 0, size.y - dest_bottom }, V2f.{ dest_left, dest_bottom },
		texture, texture_size, V4f.{ 0, texture_size.y - bottom, left, bottom }, z, color
	);
	push_nine_slice_piece(
		state, pos + V2f.{ size.x - dest_right, size.y - dest_bottom },
		V2f.{ dest_right, dest_bottom }, texture, texture_size,
		V4f.{ texture_size.x - right, texture_size.y - bottom, right, bottom }, z, color
	);
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

push_buy_prompt :: (state: *GUI_State, scene: *Scene.Scene, store: *Store) {
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

					label := atom_label(state, prompt, screen_p, 24, z=10, align = .Center, outline = true,
						color = GOLD_ACCENT);
					push_nine_slice(state,
						label.aabb_min - v2(10),
						label.aabb_max - label.aabb_min + v2(20),
						compact_button_skin(store, LOBBY_BUTTON_DARK), 9.8);
				}
			}
		}
	}
}

push_breaking_news :: (state: *GUI_State, news: [] Scene.Breaking_News, store: *Store) {
	cursor := V2f.{ state.controls.window_size.x / 2, 16};
	for news {
		t := to_float64_seconds(state.controls.time - it.time).(float);
		t = clamp(t / 5, 0.0, 1.0);

		alpha := 1.0 - t;
		text := tprint("NEWS: %", it.text);
		label := atom_label(
			state, text, .{ cursor.x, cursor.y }, 20, z=20, align = .Top_Center, outline = true,
			color = V4f.{ GOLD_ACCENT.x, GOLD_ACCENT.y, GOLD_ACCENT.z, alpha }
		);
		fill := LOBBY_BUTTON_DARK;
		fill.w = alpha;
		push_nine_slice(state, label.aabb_min - v2(10),
			label.aabb_max - label.aabb_min + v2(20), compact_button_skin(store, fill), 19.8);

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

push_point_ui :: (state: *GUI_State, player: Scene.Player, store: *Store) {
	cursor := V2f.{ 12, 40 + 12 };

	score_label := atom_label(
		state,
		tprint("Souls: %", player.server.souls),
		cursor,
		24,
		1,
		align = .Center_Left,
		outline = true,
		color = TEXT_NORMAL
	);

	push_nine_slice(
		state, score_label.aabb_min - v2(8),
		score_label.aabb_max - score_label.aabb_min + v2(16),
		compact_button_skin(store, LOBBY_BUTTON_DARK),
		0
	);
}

#load "GUI_End_Level.jai";


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
			action_palette_safety := V2f.{ 196 + 25, 196 + 25 };
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

// Felt repeats at native density; only the straight metal rails repeat.
compact_button_skin :: (store: *Store, fill_color := V4f.{ 0.04, 0.09, 0.12, 1 }) -> Nine_Slice_Style {
	skin: Nine_Slice_Style;
	skin.texture = *store.ui_compact_frame;
	skin.texture_size = .{ store.ui_compact_frame.width.(float32), store.ui_compact_frame.height.(float32) };
	skin.borders = .{ 8, 8, 8, 8 };
	skin.scale = 1;
	skin.center_mode = .Transparent;
	skin.fill_color = fill_color;
	skin.fill_inset = 3;
	return skin;
}

lobby_button_skin :: (store: *Store, fill_color := LOBBY_BUTTON_DARK, compact := false) -> Nine_Slice_Style {
	if compact return compact_button_skin(store, fill_color);
	skin: Nine_Slice_Style;
	skin.texture = *store.lobby_button_frame;
	skin.texture_size = .{ store.lobby_button_frame.width.(float32), store.lobby_button_frame.height.(float32) };
	skin.borders = .{ 20, 20, 20, 20 };
	skin.scale = 0.8;
	skin.center_mode = .Transparent;
	skin.fill_color = fill_color;
	skin.fill_inset = 12;
	return skin;
}

themed_button :: (
	gui: *GUI_State, store: *Store, text: string, id: string, size: V2f,
	fill_color := LOBBY_BUTTON_DARK, icon := V2f.{ -1, -1 }, enabled := true,
	font_size := 14.0, z := FLOAT32_MAX
) -> bool, bool {
	skin := lobby_button_skin(store, fill_color, compact = size.x < 160 || size.y < 32);
	clicked, pressed := button_sized(gui, text, size, id, skin = skin, icon = icon,
		enabled = enabled, font_size = font_size, z = z);
	return clicked, pressed;
}

push_felt_panel :: (state: *GUI_State, store: *Store, pos: V2f, size: V2f, z := 1.0) {
	push_tiled_texture(state, pos + v2(10.0), size - v2(20.0), *store.ui_felt,
		.{ 900, 764 }, z, .{ 0.13, 0.18, 0.21, 1 });
	skin: Nine_Slice_Style;
	skin.texture = *store.lobby_panel_heavy_frame;
	skin.texture_size = .{ store.lobby_panel_heavy_frame.width.(float32), store.lobby_panel_heavy_frame.height.(float32) };
	skin.borders = .{ 48, 48, 48, 48 };
	skin.scale = 0.7; // Fixed corners, including the shallow lobby header.
	skin.center_mode = .Transparent;
	push_nine_slice(state, pos, size, skin, z + 0.01);
}

push_action_palette :: (state: *GUI_State, scene: Scene.Scene, store: *Store) {
	palette_h := 196.0;
	palette_y := state.controls.window_size.y - palette_h;
	push_felt_panel(state, store, .{ 0, palette_y }, .{ 196, 196 }, 1);
	push_quad_screen(state, .{ 14, palette_y + 14 }, .{ 168, 168 }, v3(LOBBY_TABLE_BACKGROUND), 1.1, a = 0.96);

	cell_y :: (y: int) -> float32 #expand {
		return palette_y + 14 + (3 - y) * 42.0;
	}

	render_square_at :: (x: int, y: int, key_code: int) #expand {
		color := LOBBY_BUTTON_DARK;
		if state.controls.pressed[xx key_code]
			color = LOBBY_ACTION_BLUE;
		push_quad_screen(state, .{ x * 42.0 + 15, cell_y(y) + 1 }, .{ 41, 41 },
			v3(color), 2, a = color.w);
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
	for 1..4 {
		push_quad_screen(state, .{ (it * 42 + 14).(float32), palette_y + 14 }, .{ 1, 168 },
			v3(LOBBY_SEPARATOR), 2.1, a = LOBBY_SEPARATOR.w);
		push_quad_screen(state, .{ 14, palette_y + 14 + it * 42 }, .{ 168, 1 },
			v3(LOBBY_SEPARATOR), 2.1, a = LOBBY_SEPARATOR.w);
	}

	render_texture_at :: (x: int, y: int, tex_slot: V2f, color := V3f.{ 1.0, 1.0, 1.0 }) #expand {
		push_quad_texture(
			state,
			pos = .{ (x * 42 + 18).(float32), cell_y(y) + 4 },
			size = .{ 34, 34 },
			tex_slot = tex_slot,
			color = color,
			z = 3
		);
	}
	render_hint_at :: (x: int, y: int, tex_slot: V2f)  #expand {
		push_quad_texture(
			state,
			pos = .{ (x * 42 + 56 - 18).(float32), cell_y(y) + 42 - 18 },
			size = .{ 18, 18 },
			tex_slot = tex_slot,
			color = .{ 1.0, 1.0, 1.0 },
			z = 5
		);
	}
	render_text_at :: (x: int, y: int, text: string, color := V3f.{ 1.0, 1.0, 1.0 }) #expand {
		atom_label(
			state,
			text,
			.{ (x * 42 + 56 - 10).(float32), cell_y(y) + 42 - 10 },
			z = 5.0,
			align=.Center,
			scale=16,
			color = v4(color, 1.0)
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
						pos = .{ (17 + it * 6).(float32), cell_y(2) + 3 },
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
						pos = .{ 3 * 42.0 + 15, cell_y(0) + 1 + 40 * t },
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
		
		player := Scene.find_by_player_id(scene, scene.controlled_player_id);
		if player {
			render_texture_at(0, 3, CROSS_LENGTH_SLOT);
			render_text_at(0, 3, tprint("%", player.server.bomberman.cross_chain_power));
			render_texture_at(1, 3, EXPLOSION_TIME_SLOT);
			render_text_at(1, 3, tprint("%", player.server.bomberman.explosion_speed_power));
			render_texture_at(2, 3, SHIELD_SLOT);
			render_text_at(2, 3, tprint("%", player.server.bomberman.shield_power));
		}
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
push_escape_menu :: (state: *GUI_State, args: Escape_Menu_Args, store: *Store = null) -> Escape_Menu_Ret {
	ret: Escape_Menu_Ret;
	push_id(state, "escape_menu");
	defer pop_id(state);

	push_quad_screen(state, .{ 0, 0 }, state.controls.window_size, v3(GRAY_00), z = 10, a = 0.5);
	state.controls.captured_mouse = true;
	state.controls.captured_keyboard = true;

	popup_size := V2f.{ 520, 560 };
	pos := (state.controls.window_size - popup_size) / 2;
	if store {
		push_felt_panel(state, store, pos, popup_size, z = 11.0);
	} else {
		push_quad_screen(state, pos, popup_size, v3(GRAY_10), z = 11);
		push_quad_screen(state, pos + v2(1.0), popup_size - v2(2.0), v3(GRAY_80), z = 11.1);
	}
	atom_label(state, "Settings", .{ pos.x + popup_size.x / 2, pos.y + 28 },
		20, z = 12.1, align = .Center, color = GOLD_ACCENT);
	push_quad_screen(state, .{ pos.x + 24, pos.y + 48 },
		.{ popup_size.x - 48, 1 }, v3(LOBBY_SEPARATOR), z = 12.0);

	row(state, pos + v2(32.0, 64.0), .Right, z = 12, align = .Top_Left);
	if store {
		ret.resume_clicked, _ = themed_button(
			state, store, "Resume", "resume", .{ 215, 40 }, LOBBY_ACTION_BLUE
		);
		space(state, 16);
		ret.leave_instance_clicked, _ = themed_button(
			state, store, "Leave Instance", "leave", .{ 215, 40 }, LOBBY_BUTTON_DARK
		);
	} else {
		ret.resume_clicked = button(state, "Resume", id = "resume");
		space(state, 16);
		ret.leave_instance_clicked = button(state, "Leave Instance", id = "leave");
	}
	end(state);

	control_skin := ifx store then compact_button_skin(store, LOBBY_BUTTON_DARK) else .{};
	column(state, pos + v2(32.0, 124.0), z = 12, align = .Top_Left);
	ret.sound_checked = labeled_checkbox(state, "Sound", popup_size.x - 64, 24,
		id = "sound_checkbox", default = args.sound_enabled, label_color = TEXT_NORMAL,
		skin = control_skin).checked;
	space(state, 8);
	layout_options :: string.[ "AZERTY", "QWERTY" ];
	layout_dropdown := labeled_dropdown(state, "Keyboard", layout_options, popup_size.x - 64, 32,
		id = "keyboard_dropdown", default_index = cast(int) args.keyboard_layout,
		label_color = TEXT_NORMAL, skin = control_skin);
	ret.keyboard_layout = cast(Platform.Layout) layout_dropdown.selected_index;
	ret.layout_changed = layout_dropdown.changed;
	space(state, 8);
	shadows_checkbox := labeled_checkbox(state, "Shadows", popup_size.x - 64, 24,
		id = "shadows_checkbox", default = args.shadows_enabled, label_color = TEXT_NORMAL,
		skin = control_skin);
	ret.shadows_enabled = shadows_checkbox.checked;
	ret.shadows_changed = shadows_checkbox.just_checked;
	space(state, 8);
	lighting_checkbox := labeled_checkbox(state, "Lighting", popup_size.x - 64, 24,
		id = "lighting_checkbox", default = args.lighting_enabled, label_color = TEXT_NORMAL,
		skin = control_skin);
	ret.lighting_enabled = lighting_checkbox.checked;
	ret.lighting_changed = lighting_checkbox.just_checked;
	space(state, 8);
	shadow_samples_options :: string.[ "4 samples", "9 samples", "25 samples" ];
	shadow_samples := labeled_dropdown(state, "Shadow quality", shadow_samples_options,
		popup_size.x - 64, 32, id = "shadow_samples_dropdown",
		default_index = args.shadow_samples_index, label_color = TEXT_NORMAL, skin = control_skin);
	ret.shadow_samples_index = shadow_samples.selected_index;
	ret.shadow_samples_changed = shadow_samples.changed;
	space(state, 8);
	aa_options :: string.[ "FXAA", "MSAA 2x", "MSAA 4x", "No AA" ];
	aa := labeled_dropdown(state, "Anti-aliasing", aa_options, popup_size.x - 64, 32,
		id = "aa_mode_dropdown", default_index = args.aa_mode_index,
		label_color = TEXT_NORMAL, skin = control_skin);
	ret.aa_mode_index = aa.selected_index;
	ret.aa_mode_changed = aa.changed;
	space(state, 8);
	shadow_map_options :: string.[ "1024", "2048", "4096" ];
	shadow_map := labeled_dropdown(state, "Shadow map", shadow_map_options, popup_size.x - 64, 32,
		id = "shadow_map_dropdown", default_index = args.shadow_map_size_index,
		label_color = TEXT_NORMAL, skin = control_skin);
	ret.shadow_map_size_index = shadow_map.selected_index;
	ret.shadow_map_size_changed = shadow_map.changed;
	space(state, 8);
	particles_checkbox := labeled_checkbox(state, "Particles", popup_size.x - 64, 24,
		id = "particles_checkbox", default = args.particles_enabled, label_color = TEXT_NORMAL,
		skin = control_skin);
	ret.particles_enabled = particles_checkbox.checked;
	ret.particles_changed = particles_checkbox.just_checked;
	space(state, 8);
	props_checkbox := labeled_checkbox(state, "Props", popup_size.x - 64, 24,
		id = "props_checkbox", default = args.props_enabled, label_color = TEXT_NORMAL,
		skin = control_skin);
	ret.props_enabled = props_checkbox.checked;
	ret.props_changed = props_checkbox.just_checked;
	end(state);

	return ret;
}

No_Connection_Ret :: struct {
	retry_clicked: bool;
	retry_localhost_clicked: bool;
}

push_no_connection :: (state: *GUI_State, store: *Store = null) -> No_Connection_Ret {
	ret: No_Connection_Ret;
	center := state.controls.window_size / 2;
	push_quad_screen(state, .{ 0, 0 }, state.controls.window_size, LOBBY_BACKGROUND, z = 0.01);
	if store push_felt_panel(state, store, center - v2(280.0, 112.0), .{ 560, 224 }, z = 0.5);
	atom_label(state, "No connection to the server", .{ center.x, center.y - 48 }, 24,
		z = 1, align = .Center, color = GOLD_ACCENT);
	atom_label(state, "Check the server, then try again.", .{ center.x, center.y - 12 }, 13,
		z = 1, align = .Center, color = TEXT_MUTE);
	row(state, .{ center.x - 174, center.y + 52 }, .Right, z = 1, align = .Top_Left);
	if store {
		ret.retry_clicked, _ =
			themed_button(state, store, "Retry", "retry", .{ 164, 40 });
		space(state, 16);
		ret.retry_localhost_clicked, _ =
			themed_button(state, store, "Retry localhost", "retry_localhost", .{ 164, 40 });
	} else {
		ret.retry_clicked = button(state, "Retry", id = "retry");
		ret.retry_localhost_clicked = button(state, "Retry localhost", id = "retry_localhost");
	}
	end(state);
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

TEXT_MUTE   :: GRAY_50;
TEXT_NORMAL :: GRAY_80;
GOLD_ACCENT :: V4f.{ 0.81, 0.70, 0.48, 1 };

LOBBY_BACKGROUND       :: V3f.{ 0.03, 0.055, 0.075 };
MENU_BASE_BACKGROUND   :: V3f.{ 0.1, 0.1, 0.1 };
LOBBY_BUTTON_DARK      :: V4f.{ 0.04, 0.09, 0.12, 1 };
LOBBY_ACTION_BLUE      :: V4f.{ 0.06, 0.16, 0.22, 1 };
LOBBY_ACTION_OLIVE     :: V4f.{ 0.16, 0.22, 0.10, 1 };
LOBBY_ROW_SELECTED     :: V4f.{ 0.09, 0.22, 0.29, 0.75 };
LOBBY_ROW_HOVER        :: V4f.{ 0.20, 0.32, 0.36, 0.24 };
LOBBY_TABLE_BACKGROUND :: V4f.{ 0.015, 0.045, 0.055, 0.08 };
LOBBY_SEPARATOR        :: V4f.{ 0.22, 0.30, 0.32, 0.55 };
LOBBY_READY            :: V4f.{ 0.58, 0.72, 0.62, 1 };

BUTTON_DISABLED_TINT :: V4f.{ 0.5, 0.5, 0.5, 1 };
BUTTON_PRESSED_TINT  :: V4f.{ 0.78, 0.78, 0.78, 1 };
BUTTON_HOVER_TINT    :: V4f.{ 1.18, 1.18, 1.18, 1 };
BUTTON_IDLE_TINT     :: V4f.{ 1, 1, 1, 1 };
BUTTON_LABEL_TINT    :: V4f.{ 0.9, 0.85, 0.74, 1 };

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
	z := 0.0,
	modal := false,
	store: *Store = null
) -> Window {
	push_id(gui, string_id(id));

	state, comp := widget(gui, id, Window);
	comp.physical = .Solid;

	lower_left := align_pos(pos, size, align);

	window_aabb := AABBf.{ lower_left, lower_left + size };
	comp.aabb = ifx modal then AABBf.{ .{ 0, 0 }, gui.controls.window_size } else window_aabb;
	comp.z = z;
	comp.modal_barrier = modal;
	if modal
		push_quad_screen(gui, .{ 0, 0 }, gui.controls.window_size, LOBBY_BACKGROUND, z - 0.01, a = 0.72);
	if store {
		push_felt_panel(gui, store, window_aabb.min, window_aabb.max - window_aabb.min, z);
	} else {
		push_quad_screen(gui, window_aabb, v3(GRAY_20), z);
		push_quad_screen(gui, shrink(window_aabb, 1.0), v3(GRAY_80), z + 0.01);
	}

	state.pos = lower_left;
	state.size = size;

	column(gui, lower_left + v2(8.0, 8.0), z = z + 0.02, align = .Top_Left);

	return state;
}

end_window :: (gui: *GUI_State, id := "window") {
	end(gui);
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
label :: (
	gui: *GUI_State,
	text: string,
	scale := 16.0,
	color := V4f.{ 1, 1, 1, 1 },
	outline := false,
	id : string = "label",
	generate_offsets := false,
	offset_pos := V2f.{ 0, 0 }
) -> Atom_Label {
	f := flow(gui);
	pos := f.cursor + offset_pos;
	origin := f.cursor;
	defer finish_widget(gui, origin, id);
	return atom_label(
		gui,
		text,
		pos,
		scale,
		f.z,
		f.align,
		color,
		outline,
		string_id(id),
		generate_offsets
	);
}

label_box :: (
	gui: *GUI_State,
	text: string,
	size: V2f,
	scale := 16.0,
	color := V4f.{ 1, 1, 1, 1 },
	align := Align.Center_Left,
	id := "label"
) {
	f := flow(gui).*;
	aabb := AABBf.{ f.cursor, f.cursor + size };
	label := atom_label(gui, text, f.cursor, scale, f.z, .Top_Left, color, id = string_id(id));
	atom_label_replace(gui, *label, aabb, align);
	advance_cursor(gui, f.cursor, f.direction, aabb);
}

input_text :: (
	gui: *GUI_State,
	buf: *String,
	scale: float32,
	width := 128.0,
	id := "input_text",
	placeholder := "",
	max_chars := -1,
	password_mask := false,
	dark_style := false,
	margin := 2.0,
	skin: Nine_Slice_Style = .{}
) -> Input_Text_Result {
	f := flow(gui).*;
	result := atom_input_text(
		gui, buf, scale, width, f.cursor, f.z, f.align,
		id = string_id(id), placeholder = placeholder, max_chars = max_chars,
		password_mask = password_mask, dark_style = dark_style, margin = margin, skin = skin
	);
	// The atom owns its focus widget under a private ID scope.
	// Flow consumes the input rectangle, not that internal widget's ID.
	pos := align_pos(f.cursor, .{ width, scale }, f.align);
	advance_cursor(gui, f.cursor, f.direction, .{ pos, pos + v2(width, scale) });
	return result;
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
	byte_offset := 0;
	while byte_offset < text.count {
		codepoint, next_offset := Platform.text_next(text, byte_offset);
		glyph := Platform.text_glyph(gui.main_font, codepoint);
		if generate_offsets {
			for byte_offset..next_offset - 1 ret.offsets[it] = cursor.x - pos.x;
		}

		char: GUI_State.Char;
		char.id = glyph.unicode;
		char.pos.x = cursor.x + glyph.planex * scale;
		char.pos.y = cursor.y - glyph.planeh * scale;
		char.size.x = (glyph.planew - glyph.planex) * scale;
		char.size.y = (glyph.planeh - glyph.planey) * scale;
		char.z = z;
		char.color = color;
		char.outline = outline;

		cursor.x += glyph.advance * scale;
		if generate_offsets {
			ret.offsets[next_offset] = cursor.x - pos.x;
		}

		aabb_min.x = min(aabb_min.x, char.pos.x);
		aabb_min.y = min(aabb_min.y, char.pos.y);
		aabb_max.x = max(aabb_max.x, char.pos.x + char.size.x);
		aabb_max.y = max(aabb_max.y, char.pos.y + char.size.y);
		ret.baseline_y_from_bottom = min(ret.baseline_y_from_bottom, glyph.planey * scale);
		array_add(*gui.chars, char);
		byte_offset = next_offset;
	}
	ret.gui_char_count = gui.chars.count - ret.gui_char_start_index;
	if ret.gui_char_count == 0 {
		ret.aabb_min = pos;
		ret.aabb_max = pos;
		w.aabb = .{ pos, pos };
		return ret;
	}

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

Input_Text_Result :: struct {
	changed := false;
	committed := false;
}

text_byte_boundary :: (text: string, offset: int) -> int {
	offset = clamp(offset, 0, text.count);
	i := 0;
	while i < offset {
		_, next := Platform.text_next(text, i);
		if next > offset break;
		i = next;
	}
	return i;
}

input_character_advance :: (gui: *GUI_State, codepoint: int, font_size: float, password_mask: bool) -> float {
	if password_mask codepoint = #char "*";
	return Platform.text_glyph(gui.main_font, codepoint).advance * font_size;
}

atom_input_text :: (
	gui: *GUI_State,
	buf: *String,
	scale: float,
	width := 128.0,
	pos: V2f,
	z := 0.0,
	align := Align.Bottom_Left,
	id : u64 = 0,
	placeholder := "",
	max_chars := -1,
	margin := 2.0,
	unfocus_on_commit := true,
	force_focus := false,
	cursor_to_end := false,
	skin: Nine_Slice_Style = .{},
	dark_style := false,
	text_size := 13.0,
	password_mask := false
) -> Input_Text_Result {
	result: Input_Text_Result;

	push_id(gui, id);
	defer pop_id(gui);

	Input_Text :: struct {
		cursor := 0;
		display_start := 0;
	};

	size := v2(width, scale);

	state, comp := widget(gui, "input", Input_Text);
	comp.aabb.min = align_pos(pos, size, align);
	comp.aabb.max = comp.aabb.min + size;
	comp.z = z;
	comp.physical = .Solid;

	if force_focus {
		comp.keyboard_focused = true;
	}

	if comp.just_pressed {
		comp.keyboard_focused = true;
		state.cursor = text_byte_boundary(view(buf), state.display_start);
		x := comp.aabb.min.x + margin;
		font_size := ifx dark_style then text_size else scale * 0.6;
		current_text := view(buf);
		i := state.cursor;
		while i < current_text.count {
			codepoint, next := Platform.text_next(current_text, i);
			advance := input_character_advance(gui, codepoint, font_size, password_mask);
			if gui.controls.mouse_pos.x < x + advance / 2 break;
			x += advance;
			state.cursor = next;
			i = next;
		}
	}

	if comp.keyboard_focused && gui.controls.just_pressed[Platform.Key.Escape] {
		comp.keyboard_focused = false;
	}

	if comp.keyboard_focused {
		gui.controls.captured_keyboard = true;
		gui.controls.text_input_active = true;
		state.cursor = text_byte_boundary(view(buf), state.cursor);
		if cursor_to_end {
			state.cursor = buf.count;
		}

		if !gui.controls.text_input_consumed {
			gui.controls.text_input_consumed = true;
			committed_text := gui.controls.text_input;
			character_count := Platform.text_character_count(view(buf));
			i := 0;
			while i < committed_text.count {
				codepoint, next := Platform.text_next(committed_text, i);
				if codepoint >= 32 && codepoint != 127 && (max_chars < 0 || character_count < max_chars) {
					to_add := slice(committed_text, i, next - i);
					insert(buf, state.cursor, to_add);
					state.cursor += to_add.count;
					character_count += 1;
					result.changed = true;
				}
				i = next;
			}
		}

		if gui.controls.just_pressed[xx Platform.Key.Backspace] {
			if state.cursor > 0 && buf.count > 0 {
				previous := Platform.text_previous(view(buf), state.cursor);
				remove_range(buf, previous, state.cursor - previous);
				state.cursor = previous;
				result.changed = true;
			}
		}
		if gui.controls.just_pressed[Platform.Key.Delete] && state.cursor < buf.count {
			_, next := Platform.text_next(view(buf), state.cursor);
			remove_range(buf, state.cursor, next - state.cursor);
			result.changed = true;
		}
		if gui.controls.just_pressed[xx Platform.Key.Left] {
			state.cursor = Platform.text_previous(view(buf), state.cursor);
		}
		if gui.controls.just_pressed[xx Platform.Key.Right] && state.cursor < buf.count {
			_, next := Platform.text_next(view(buf), state.cursor);
			state.cursor = next;
		}
		if gui.controls.just_pressed[Platform.Key.Home] state.cursor = 0;
		if gui.controls.just_pressed[Platform.Key.End] state.cursor = buf.count;
		if gui.controls.just_pressed[Platform.Key.Enter] {
			result.committed = true;
			if unfocus_on_commit comp.keyboard_focused = false;
		}
	}

	text := view(buf);

	if skin.texture {
		push_nine_slice(gui, comp.aabb.min, comp.aabb.max - comp.aabb.min, skin, z + 0.01);
	} else if dark_style {
		border := ifx comp.keyboard_focused then V3f.{ 0.70, 0.56, 0.32 } else V3f.{ 0.30, 0.34, 0.34 };
		push_quad_screen(gui, comp.aabb, border, z + 0.01);
		push_quad_screen(gui, shrink(comp.aabb, 1.0), V3f.{ 0.025, 0.045, 0.055 }, z + 0.02);
	} else {
		push_quad_screen(gui, comp.aabb, v3(GRAY_20), z + 0.01);
		push_quad_screen(gui, shrink(comp.aabb, 1.0), v3(GRAY_90), z + 0.02);
	}

	font_size := ifx dark_style then text_size else scale * 0.6;
	inner_width := max(0.0, width - 2 * margin - 2);
	state.cursor = text_byte_boundary(text, state.cursor);
	state.display_start = 0;
	if comp.keyboard_focused {
		caret_width := 0.0;
		i := 0;
		while i < state.cursor {
			codepoint, next := Platform.text_next(text, i);
			caret_width += input_character_advance(gui, codepoint, font_size, password_mask);
			i = next;
		}
		while caret_width > inner_width && state.display_start < state.cursor {
			codepoint, next := Platform.text_next(text, state.display_start);
			caret_width -= input_character_advance(gui, codepoint, font_size, password_mask);
			state.display_start = next;
		}
	}
	visible_end := state.display_start;
	visible_width := 0.0;
	while visible_end < text.count {
		codepoint, next := Platform.text_next(text, visible_end);
		next_width := visible_width + input_character_advance(gui, codepoint, font_size, password_mask);
		if next_width > inner_width break;
		visible_width = next_width;
		visible_end = next;
	}
	displayed := ifx text.count == 0 then fit_text(gui, placeholder, font_size, inner_width)
		else slice(text, state.display_start, visible_end - state.display_start);
	caret_offset := state.cursor - state.display_start;
	if password_mask && text.count > 0 {
		masked := NewArray(Platform.text_character_count(displayed), u8,, temp);
		for *masked it.* = #char "*";
		caret_offset = Platform.text_character_count(slice(text, state.display_start, min(state.cursor, visible_end) - state.display_start));
		displayed = .{ masked.count, masked.data };
	}
	label := atom_label(gui, displayed, comp.aabb.min, font_size, z = z + 0.03,
		color = ifx dark_style then (ifx text.count > 0 then V4f.{ 0.86, 0.88, 0.85, 1 } else V4f.{ 0.48, 0.56, 0.58, 1 })
			else (ifx comp.keyboard_focused then GRAY_00 else GRAY_60), generate_offsets = true);
	atom_label_replace(gui, *label, .{ comp.aabb.min + v2(margin, 0), comp.aabb.max - v2(margin, 0) }, .Center_Left);
	if comp.keyboard_focused {
		cursor_x := comp.aabb.min.x + margin;
		if text.count > 0 cursor_x += label.offsets[clamp(caret_offset, 0, label.offsets.count - 1)];
		push_quad_screen(gui, .{ cursor_x, comp.aabb.min.y + (scale - font_size) / 2 }, .{ 1, font_size },
			ifx dark_style then V3f.{ 0.85, 0.74, 0.51 } else v3(GRAY_00), z + 0.04);
	}

	return result;
}

fit_text :: (gui: *GUI_State, text: string, scale: float32, max_width: float32) -> string {
	width := 0.0;
	i := 0;
	while i < text.count {
		codepoint, next := Platform.text_next(text, i);
		width += Platform.text_glyph(gui.main_font, codepoint).advance * scale;
		i = next;
	}
	if width <= max_width return text;
	dots_width := Platform.text_glyph(gui.main_font, #char ".").advance * scale * 3;
	if max_width < dots_width return "";
	width = 0;
	i = 0;
	while i < text.count {
		codepoint, next := Platform.text_next(text, i);
		width += Platform.text_glyph(gui.main_font, codepoint).advance * scale;
		if width + dots_width > max_width return tprint("%...", slice(text, 0, i));
		i = next;
	}
	return text;
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
	skin: *Table_Style = null,
	selected_row: *int = null
) -> Atom_Table {
	f := flow(gui);
	origin := f.cursor;
	defer {
		advance_cursor(gui, origin, f.direction, AABBf.{ origin, origin + size });
	}
	return atom_table(
		gui,
		f.cursor,
		size,
		rows,
		id,
		row_height,
		f.z,
		f.align,
		skin,
		selected_row
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
	align := Align.Bottom_Left,
	skin: *Table_Style = null,
	selected_row: *int = null
) -> Atom_Table {
	ret: Atom_Table;

	State :: struct {
		selected_row_index: int;
	}
	state := widget(gui, id, State);
	if selected_row state.selected_row_index = selected_row.*;
	state.selected_row_index = ifx rows.count > 0 then clamp(state.selected_row_index, 0, rows.count - 1) else -1;
	push_id(gui, id);
	defer pop_id(gui);

	lower_left := align_pos(pos, size, align);
	ret.aabb_min = lower_left;
	ret.aabb_max = lower_left + size;

	background_color := ifx skin then skin.background_color else GRAY_90;
	left_rail_color := ifx skin then skin.left_rail_color else GRAY_70;
	header_color := ifx skin then skin.header_color else GRAY_00;
	text_color := ifx skin then skin.text_color else GRAY_00;
	separator_color := ifx skin then skin.separator_color else GRAY_40;
	dash_color := ifx skin then skin.separator_color else GRAY_60;
	end_rule_color := ifx skin then skin.separator_color else GRAY_00;
	selected_color := ifx skin then skin.selected_color else GRAY_60;
	hover_color := ifx skin then skin.hover_color else GRAY_30;
	push_quad_screen(gui, lower_left, size, v3(background_color), z + 0.1, background_color.w);
	push_quad_screen(gui, lower_left, .{ 4, size.y }, v3(left_rail_color), z + 0.2, left_rail_color.w);
	if !skin || skin.dashed_header atom_dash_quad(
		gui,
		.{ lower_left.x + 4, lower_left.y },
		.{ size.x - 4, 2 },
		.{ 2, 2 },
		.{ 4, 2 },
		v3(dash_color),
		z + 0.15
	);

	Cols :: struct {
		name: string;
		size := -1;
		offset: u64;
		align_right := false;
		align_center := false;
		button := false;
		icon_slot := V2f.{ -1, -1 };
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
			if scan2(note, "icon(%,%)", *it.icon_slot.x, *it.icon_slot.y) continue;
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
		header_pos := cursor;
		header_align := Align.Center_Left;
		if it.size >= 0 && it.align_center {
			header_pos.x += it.size / 2 - 4;
			header_align = .Center;
		} else if it.size >= 0 && it.align_right {
			header_pos.x += it.size - 4;
			header_align = .Center_Right;
		}
		label := atom_label(
			gui,
			it.name,
			header_pos,
			ifx skin then skin.header_size else 14.0,
			align = header_align,
			z = z + 0.25,
			color = header_color,
			id = xx it_index
		);
		if it.size < 0 {
			it.size = (label.aabb_max.x - label.aabb_min.x + 16).(s64);
		}
		cursor.x += it.size;

		if it_index < cols.count - 1 && (!skin || skin.vertical_rules) {
			push_quad_screen(
				gui,
				.{ cursor.x, lower_left.y },
				.{ 1, size.y },
				v3(separator_color),
				z + 0.20, separator_color.w
			);
		}
	}
	pop_id(gui);

	cursor = V2f.{ lower_left.x + 4, lower_left.y + row_height / 2 + row_height };
	for row, row_index: rows {
		if ((row_index + 2) * row_height).(float32) > size.y break;
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
			
			if it.button && skin && skin.compact_icons && it.icon_slot.x >= 0 {
				button_pos := label_pos - V2f.{ 14, 11 };
				_, button := widget_sized(gui, tprint("%", it_index), struct {},
					AABBf.{ button_pos, button_pos + V2f.{ 28, 22 } }, z + 0.3, .Mouse_Left);
				push_nine_slice(gui, button_pos, .{ 28, 22 }, skin.button_skin, z + 0.26,
					ifx button.pressed then V4f.{ 0.7, 0.7, 0.7, 1 } else
					(ifx button.hovered then V4f.{ 1.2, 1.2, 1.2, 1 } else V4f.{ 1, 1, 1, 1 }));
				push_quad_texture(gui, button_pos + V2f.{ 6, 3 }, .{ 16, 16 }, .{ 1, 1, 1 },
					it.icon_slot, z + 0.28);
				if button.released {
					state.selected_row_index = row_index;
					ret.clicked_row_index = row_index;
					ret.clicked_col_index = it_index;
				}
			} else if it.button {
				clicked := text_button(
					gui,
					str,
					label_pos,
					z = z + 0.25,
					id = tprint("%", it_index),
					align = align,
					skin = ifx skin then skin.button_skin else .{}
				);
				if clicked {
					state.selected_row_index = row_index;
					ret.clicked_row_index = row_index;
					ret.clicked_col_index = it_index;
				}
			} else {
				atom_label(
					gui,
					fit_text(gui, str, 14, (it.size - 6).(float32)),
					label_pos,
					14,
					align = align,
					z = z + 0.25,
					color = text_color,
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

		row_background_color := V4f.{ 0, 0, 0, 0 };

		if (!skin || skin.selectable) && state.selected_row_index == row_index {
			row_background_color = selected_color;
		}
		_, row_widget := widget_sized(gui, "row_selection", struct {},
			AABBf.{ row_aabb_min, row_aabb_max }, z + 0.21,
			ifx !skin || skin.selectable then GUI_State.Widget.Physical.Mouse_Left else .Empty);
		if row_widget.released {
			state.selected_row_index = row_index;
			ret.just_selected_row_index = row_index;
		}
		if row_widget.hovered row_background_color = hover_color;
		if (!skin || skin.selectable) && state.selected_row_index == row_index
			row_background_color = selected_color;
		if state.selected_row_index == row_index && skin && skin.selectable && skin.selected_row_skin.texture {
			push_nine_slice(
				gui,
				row_aabb_min,
				row_aabb_max - row_aabb_min,
				skin.selected_row_skin,
				z + 0.15
			);
		} else if row_background_color.w > 0 {
			push_quad_screen(
				gui,
				row_aabb_min,
				row_aabb_max - row_aabb_min,
				v3(row_background_color),
				z + 0.15,
				row_background_color.w
			);
		}


		if skin && skin.selectable && !skin.vertical_rules && state.selected_row_index == row_index {
			push_quad_screen(gui, row_aabb_min, .{ 2, row_height.(float32) }, V3f.{ 0.78, 0.65, 0.39 }, z + 0.22);
		}
		cursor.y += row_height;
		push_quad_screen(
			gui,
			.{ lower_left.x + 4, cursor.y - row_height / 2 },
			.{ size.x - 4, 1 },
			v3(separator_color),
			z + 0.20, separator_color.w
		);
	}

	push_quad_screen(
		gui,
		.{ lower_left.x + 4, lower_left.y + row_height - 1 },
		.{ size.x - 4, 1 },
		v3(end_rule_color),
		z + 0.25, end_rule_color.w
	);
	ret.selected_row_index = state.selected_row_index;
	if selected_row selected_row.* = state.selected_row_index;

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

button :: (
	gui: *GUI_State,
	text: string,
	id := "button",
	size: Text_Button.Size = .Small,
	align := Align.Undefined
) -> bool, Text_Button, *GUI_State.Widget
{
	f := flow(gui);
	_align := align;
	if _align == Align.Undefined {
		_align = f.align;
	}
	origin := f.cursor;
	defer finish_widget(gui, origin, id);
	a, b, c := text_button(gui, text, f.cursor, f.z, id, _align, size);
	return a, b, c;
}

button_sized :: (
	gui: *GUI_State,
	text: string,
	size: V2f,
	id := "button",
	skin: Nine_Slice_Style = .{},
	z := FLOAT32_MAX,
	font_size := 14.0,
	icon := V2f.{ -1, -1 },
	enabled := true,
	align := Align.Bottom_Left
) -> bool, bool {
	f := flow(gui);
	button_z := ifx z == FLOAT32_MAX then f.z else z;
	origin := f.cursor;
	_, widget := widget_sized(
		gui, id, struct {}, AABBf.{ origin, origin + size }, button_z, .Mouse
	);
	widget.physical = ifx enabled then GUI_State.Widget.Physical.Mouse_Left else .Empty;

	clicked := enabled && widget.released;
	pressed := enabled && widget.pressed;
	hovered := enabled && widget.hovered;
	tint := ifx !enabled then BUTTON_DISABLED_TINT else
		(ifx pressed then BUTTON_PRESSED_TINT else
		(ifx hovered then BUTTON_HOVER_TINT else BUTTON_IDLE_TINT));

	push_nine_slice(gui, origin, size, skin, button_z, tint);
	content_pos := origin + size / 2 + (ifx pressed then v2(1.0) else v2(0.0));
	if icon.x >= 0 {
		icon_size := min(24.0, size.y - 10);
		push_quad_texture(
			gui,
			origin + v2(8.0, (size.y - icon_size) / 2),
			v2(icon_size),
			v3(tint),
			icon,
			button_z + 0.4
		);
		if text.count > 0 content_pos.x += 12;
	}
	if text.count > 0 {
		push_id(gui, id);
		atom_label(
			gui,
			text,
			content_pos,
			font_size,
			button_z + 0.5,
			Align.Center,
			V4f.{ BUTTON_LABEL_TINT.x * tint.x, BUTTON_LABEL_TINT.y * tint.y, BUTTON_LABEL_TINT.z * tint.z, 1 },
			id = string_id("label")
		);
		pop_id(gui);
	}

	finish_widget(gui, origin, id);
	return clicked, pressed;
}

text_button :: (
	gui: *GUI_State,
	text: string,
	pos: V2f,
	z := 0.0,
	id := "text_button",
	align := Align.Bottom_Left,
	size: Text_Button.Size = .Small,
	skin: Nine_Slice_Style = .{}
) -> bool, Text_Button, *GUI_State.Widget
{
	state, widget := widget(gui, id, Text_Button);

	push_id(gui, id);
	defer pop_id(gui);

	widget.physical = .Mouse_Left;
	widget.z = z;
	state.aabb_padding = .{ 4, 4 };
	state.border = .{ 1, 1 };
	state.clicked = false;

	label_color := V4f.{ 0, 0, 0, 1 };
	background_color := V4f.{ 1, 1, 1, 1 };
	if skin.texture {
		label_color = V4f.{ 0.9, 0.84, 0.7, 1 };
		background_color = V4f.{ 1.12, 1.12, 1.12, 1 };
	}
	if state.last_hover && !gui.controls.pressed[Key.MouseLeft] {
		label_color = V4f.{ 1, 0.95, 0.83, 1 };
		if !skin.texture
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
	if skin.texture {
		push_nine_slice(gui, widget.aabb.min, widget.aabb.max - widget.aabb.min, skin, z, background_color);
	} else {
		push_quad_screen(gui, widget.aabb, v3(state.border_color), z);
		push_quad_screen(gui, shrink(widget.aabb, state.border), v3(background_color), z + 0.5);
	}

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
	id := "labeled_text_button",
	padding := 4.0,
	size: Text_Button.Size = .Small
) -> bool, Text_Button, *GUI_State.Widget {
	_, w := widget(gui, id, struct {});

	f := flow(gui);
	pos := f.cursor;
	z := f.z;
	align := f.align;
	origin := f.cursor;
	defer finish_widget(gui, origin, id);

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
	default := false,
	skin: Nine_Slice_Style = .{}
) -> Checkbox {
	state, widget := widget(gui, id, Checkbox);

	push_id(gui, id);
	defer pop_id(gui);

	if widget.age == 0 {
		state.checked = default;
	}

	lower_left := align_pos(pos, .{ size, size }, align);

	if skin.texture {
		push_nine_slice(gui, lower_left, .{ size, size }, skin, z);
	} else {
		push_quad_screen(gui, lower_left, .{ size, size }, v3(GRAY_80), z);
		push_quad_screen(gui, lower_left + .{ 1, 1 }, .{ size - 2, size - 2 }, v3(GRAY_10), z + 1);
	}

	if state.checked {
		checked_color := ifx skin.texture then v3(LOBBY_READY) else v3(GREEN_BRIGHT);
		push_quad_screen(
			gui, lower_left + .{ 4, 4 }, .{ size - 8, size - 8 }, checked_color, z + 0.1
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

checkbox :: (gui: *GUI_State, size: float, id := "checkbox", default := false,
	skin: Nine_Slice_Style = .{}) -> Checkbox {
	f := flow(gui);
	origin := f.cursor;
	defer finish_widget(gui, origin, id);
	return checkbox(gui, f.cursor, size, f.z, id, f.align, default, skin);
}

labeled_checkbox :: (
	gui: *GUI_State,
	label: string,
	width: float,
	size: float,
	id := "labeled_checkbox",
	padding := 4.0,
	default := false,
	label_color := GRAY_00,
	skin: Nine_Slice_Style = .{}
) -> Checkbox {
	_, w := widget(gui, id, struct {});

	f := flow(gui);
	pos := f.cursor;
	z := f.z;
	align := f.align;
	origin := f.cursor;
	defer finish_widget(gui, origin, id);

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
		default = default,
		skin = skin
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
	default_index := 0,
	skin: Nine_Slice_Style = .{}
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
	if skin.texture {
		push_nine_slice(gui, lower_left, .{ width, height }, skin, z);
	} else {
		push_quad_screen(gui, header_aabb, v3(0.0, 0.0, 0.0), z);
		push_quad_screen(gui, shrink(header_aabb, v2(1.0, 1.0)), v3(1.0, 1.0, 1.0), z + 0.1);
	}

	// Display selected option
	if options.count > 0 && state.selected_index >= 0 && state.selected_index < options.count {
		atom_label(
			gui,
			options[state.selected_index],
			lower_left + v2(4.0, height / 2),
			height * 0.6,
			z + 0.2,
			align = .Center_Left,
			color = ifx skin.texture then TEXT_NORMAL else v4(0.0, 0.0, 0.0, 1.0),
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
			align = .Center, color = ifx skin.texture then GOLD_ACCENT else v4(0.0, 0.0, 0.0, 1.0), id = xx string_id("arrow")
		);
	} else {
		// Down arrow (v)
		atom_label(
			gui, "v", .{ arrow_x, arrow_y }, height * 0.5, z + 0.2,
			align = .Center, color = ifx skin.texture then GOLD_ACCENT else v4(0.0, 0.0, 0.0, 1.0), id = xx string_id("arrow")
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
				bg_color = ifx skin.texture then v3(LOBBY_ROW_HOVER) else v3(0.8, 0.8, 0.8);
			}

			// Highlight if selected
			if is_selected {
				bg_color = ifx skin.texture then v3(LOBBY_ROW_SELECTED) else v3(0.9, 0.9, 0.9);
			}

			// Draw option background
			if skin.texture {
				option_skin := skin;
				if bg_color.x != 1.0 || bg_color.y != 1.0 || bg_color.z != 1.0 {
					option_skin.fill_color = v4(bg_color, 1);
				}
				push_nine_slice(gui, option_aabb.min, option_aabb.max - option_aabb.min, option_skin, z + 1.0);
				text_color = TEXT_NORMAL;
			} else {
				push_quad_screen(gui, option_aabb, v3(0.0, 0.0, 0.0), z + 0.9);
				push_quad_screen(gui, shrink(option_aabb, v2(1.0, 1.0)), bg_color, z + 1.0);
			}

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

dropdown :: (
	gui: *GUI_State,
	options: [] string,
	width: float,
	height: float,
	id := "dropdown",
	default_index := 0,
	skin: Nine_Slice_Style = .{}
) -> Dropdown {
	f := flow(gui);
	origin := f.cursor;
	defer finish_widget(gui, origin, id);
	return dropdown(gui, options, f.cursor, width, height, f.z, id, f.align, default_index, skin);
}

labeled_dropdown :: (
	gui: *GUI_State,
	label: string,
	options: [] string,
	width: float,
	height: float,
	id := "labeled_dropdown",
	label_color := GRAY_00,
	padding := 4.0,
	default_index := 0,
	skin: Nine_Slice_Style = .{}
) -> Dropdown {
	_, w := widget(gui, id, struct {});

	f := flow(gui);
	pos := f.cursor;
	z := f.z;
	align := f.align;
	origin := f.cursor;
	defer finish_widget(gui, origin, id);

	push_id(gui, id);
	defer pop_id(gui);

	row_aabb := AABBf.{ pos, pos + v2(width, height) };
	row_aabb = align_aabb(row_aabb, align);

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

	dropdown_width := min(width - widget_width(gui, "label") - padding * 3, 64 + 64);
	dropdown_comp := dropdown(
		gui,
		options,
		anchor_aabb(row_aabb, .Center_Right) - v2(padding, 0.0),
		dropdown_width,
		height,
		z,
		align = Align.Center_Right,
		id = "dropdown",
		default_index = default_index,
		skin = skin
	);

	w.aabb = widgets_aabb(gui, string.[ "label", "dropdown" ]);
	return dropdown_comp;
}

labeled_input_text :: (
	gui: *GUI_State,
	label: string,
	buf: *String,
	width: float,
	size: float,
	scale := 16.0,
	id := "labeled_input_text",
	max_input_width := 128.0,
	label_color := GRAY_00,
	max_chars := -1,
	padding := 4.0,
	placeholder := "",
	skin: Nine_Slice_Style = .{},
	dark_style := false
) -> Input_Text_Result {
	_, w := widget(gui, id, struct {});

	f := flow(gui);
	pos := f.cursor;
	z := f.z;
	align := f.align;
	origin := f.cursor;
	defer finish_widget(gui, origin, id);

	push_id(gui, id);
	defer pop_id(gui);

	row_aabb := AABBf.{ pos, pos + v2(width, size) };
	row_aabb = align_aabb(row_aabb, align);

	atom_label(
		gui,
		label,
		anchor_aabb(row_aabb, .Center_Left) + v2(padding, 0.0),
		scale,
		z,
		.Center_Left,
		color = label_color,
		id = xx string_id("label")
	);

	result := atom_input_text(
		gui,
		buf,
		scale / 0.6,
		min(width - widget_width(gui, "label") - padding * 3, max_input_width),
		anchor_aabb(row_aabb, .Center_Right) - v2(padding, 0.0),
		z,
		.Center_Right,
		id = xx string_id("input_text"),
		max_chars = max_chars,
		placeholder = placeholder,
		skin = skin,
		dark_style = dark_style
	);

	w.aabb = row_aabb;
	return result;
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

	pool: String_Pool;
	init(*pool, temp);
	buf := make(*pool, 20);
	set(*buf, tprint("%", state.value));
	input := atom_input_text(
		gui,
		*buf,
		height,
		width,
		lower_left,
		z,
		Align.Bottom_Left,
		id = xx string_id("input"),
		max_chars = 20
	);

	state.aabb_min = lower_left;
	state.aabb_max = lower_left + .{ width, height };
	state.changed = false;

	if input.changed {
		parsed_value, success := string_to_int(view(*buf));
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

integer_input :: (
	gui: *GUI_State,
	width: float,
	height: float,
	default_value := 0,
	min_value := S64_MIN,
	max_value := S64_MAX,
	id := "integer_input"
) -> Integer_Input {
	f := flow(gui);
	origin := f.cursor;
	defer finish_widget(gui, origin, id);
	return integer_input(gui, f.cursor, width, height, default_value, min_value, max_value, f.z, id, f.align);
}

labeled_integer_input :: (
	gui: *GUI_State,
	label: string,
	width: float,
	height: float,
	default_value := 0,
	min_value := S64_MIN,
	max_value := S64_MAX,
	id := "labeled_integer_input",
	padding := 4.0
) -> Integer_Input {
	_, w := widget(gui, id, struct {});

	f := flow(gui);
	pos := f.cursor;
	z := f.z;
	align := f.align;
	origin := f.cursor;
	defer finish_widget(gui, origin, id);

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

slider :: (
	gui: *GUI_State,
	width: float,
	height: float,
	min_value := 0.0,
	max_value := 1.0,
	default_value := 0.5,
	id := "slider"
) -> Slider {
	f := flow(gui);
	origin := f.cursor;
	defer finish_widget(gui, origin, id);
	return slider(gui, f.cursor, width, height, min_value, max_value, default_value, f.z, id, f.align);
}

labeled_slider :: (
	gui: *GUI_State,
	label: string,
	width: float,
	height: float,
	min_value := 0.0,
	max_value := 1.0,
	default_value := 0.5,
	id := "labeled_slider",
	padding := 4.0,
	show_value := true
) -> Slider {
	_, w := widget(gui, id, struct {});

	f := flow(gui);
	pos := f.cursor;
	z := f.z;
	align := f.align;
	origin := f.cursor;
	defer finish_widget(gui, origin, id);

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

numeric_text_input :: (gui: *GUI_State, storage: [] u8, length: *int, cursor: *int, floating: bool) {
	gui.controls.captured_keyboard = true;
	gui.controls.text_input_active = true;
	if !gui.controls.text_input_consumed {
		gui.controls.text_input_consumed = true;
		text := gui.controls.text_input;
		i := 0;
		while i < text.count {
			codepoint, next := Platform.text_next(text, i);
			allowed := (codepoint >= #char "0" && codepoint <= #char "9") ||
				codepoint == #char "-" || codepoint == #char "+";
			if floating && (codepoint == #char "." || codepoint == #char "e" || codepoint == #char "E") allowed = true;
			if allowed && length.* < storage.count - 1 {
				for < j: length.*..cursor.* + 1 storage[j] = storage[j - 1];
				storage[cursor.*] = xx codepoint;
				length.* += 1;
				cursor.* += 1;
			}
			i = next;
		}
	}
	if gui.controls.just_pressed[Platform.Key.Backspace] && cursor.* > 0 {
		for i: cursor.* - 1..length.* - 2 storage[i] = storage[i + 1];
		length.* -= 1;
		cursor.* -= 1;
	}
	if gui.controls.just_pressed[Platform.Key.Delete] && cursor.* < length.* {
		for i: cursor.*..length.* - 2 storage[i] = storage[i + 1];
		length.* -= 1;
	}
	if gui.controls.just_pressed[Platform.Key.Left] cursor.* = max(0, cursor.* - 1);
	if gui.controls.just_pressed[Platform.Key.Right] cursor.* = min(length.*, cursor.* + 1);
	if gui.controls.just_pressed[Platform.Key.Home] cursor.* = 0;
	if gui.controls.just_pressed[Platform.Key.End] cursor.* = length.*;
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
	id := "float_input",
	skin: Nine_Slice_Style = .{}
) -> Float_Input {
	state, widget := widget(gui, id, Float_Input);

	f := flow(gui);
	pos := f.cursor;
	z := f.z;
	align := f.align;
	origin := f.cursor;
	defer finish_widget(gui, origin, id);

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
	if skin.texture {
		push_nine_slice(gui, lower_left, .{ width, height }, skin, z);
	} else {
		border_color := ifx state.editing then v3(GREEN_BRIGHT) else ifx state.dragging then v3(GRAY_00) else v3(GRAY_40);
		push_quad_screen(gui, lower_left, .{ width, height }, border_color, z);
		push_quad_screen(gui, lower_left + v2(1), .{ width - 2, height - 2 }, v3(GRAY_90), z + 0.01);
	}

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
			color = ifx skin.texture then TEXT_NORMAL else GRAY_00,
			generate_offsets = true
		);

		// Draw cursor
		state.edit_cursor = clamp(state.edit_cursor, 0, state.edit_text_len);
		cursor_x := lower_left.x + 4.0 + (ifx label.offsets.count > state.edit_cursor then label.offsets[state.edit_cursor] else 0.0);
		cursor_aabb := pos_size(v2(cursor_x, lower_left.y + 4.0), v2(2.0, height - 8.0));
		push_quad_screen(gui, cursor_aabb, v3(GRAY_00), z + 0.04);

		// Handle keyboard input for text editing
		if widget.keyboard_focused {
			numeric_text_input(gui, state.edit_text, *state.edit_text_len, *state.edit_cursor, true);

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
			color = ifx skin.texture then TEXT_NORMAL else GRAY_00
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
	id := "int_input",
	skin: Nine_Slice_Style = .{}
) -> Int_Input {
	state, widget := widget(gui, id, Int_Input);

	f := flow(gui);
	pos := f.cursor;
	z := f.z;
	align := f.align;
	origin := f.cursor;
	defer finish_widget(gui, origin, id);

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
	if skin.texture {
		push_nine_slice(gui, lower_left, .{ width, height }, skin, z);
	} else {
		border_color := ifx state.editing then v3(GREEN_BRIGHT) else ifx state.dragging then v3(GRAY_00) else v3(GRAY_40);
		push_quad_screen(gui, lower_left, .{ width, height }, border_color, z);
		push_quad_screen(gui, lower_left + v2(1), .{ width - 2, height - 2 }, v3(GRAY_90), z + 0.01);
	}

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
			color = ifx skin.texture then TEXT_NORMAL else GRAY_00,
			generate_offsets = true
		);

		// Draw cursor
		state.edit_cursor = clamp(state.edit_cursor, 0, state.edit_text_len);
		cursor_x := lower_left.x + 4.0 + (ifx label.offsets.count > state.edit_cursor then label.offsets[state.edit_cursor] else 0.0);
		cursor_aabb := pos_size(v2(cursor_x, lower_left.y + 4.0), v2(2.0, height - 8.0));
		push_quad_screen(gui, cursor_aabb, v3(GRAY_00), z + 0.04);

		// Handle keyboard input for text editing
		if widget.keyboard_focused {
			numeric_text_input(gui, state.edit_text, *state.edit_text_len, *state.edit_cursor, false);

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
			color = ifx skin.texture then TEXT_NORMAL else GRAY_00
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
	id := "labeled_float_input",
	padding := 4.0,
	skin: Nine_Slice_Style = .{},
	label_color := TEXT_NORMAL
) -> Float_Input {
	_, w := widget(gui, id, struct {});

	f := flow(gui);
	pos := f.cursor;
	z := f.z;
	align := f.align;
	origin := f.cursor;
	defer finish_widget(gui, origin, id);

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
		color = label_color,
		id = xx string_id("label")
	);

	input_width := min(width - widget_width(gui, "label") - padding * 3, 128.0);
	place(gui, lower_left + v2(width - padding, 0), z, vertical(align) | Align.Right);
	input_comp := float_input(
		gui,
		input_width,
		height,
		value = value,
		min_value = min_value,
		max_value = max_value,
		drag_speed = drag_speed,
		precision = precision,
		id = "input",
		skin = skin
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
	id := "labeled_int_input",
	padding := 4.0,
	skin: Nine_Slice_Style = .{},
	label_color := TEXT_NORMAL
) -> Int_Input {
	_, w := widget(gui, id, struct {});

	f := flow(gui);
	pos := f.cursor;
	z := f.z;
	align := f.align;
	origin := f.cursor;
	defer finish_widget(gui, origin, id);

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
		color = label_color,
		id = xx string_id("label")
	);

	input_width := min(width - widget_width(gui, "label") - padding * 3, 128.0);
	place(gui, lower_left + v2(width - padding, 0.0), z, vertical(align) | Align.Right);
	input_comp := int_input(
		gui,
		input_width,
		height,
		value = value,
		min_value = min_value,
		max_value = max_value,
		drag_speed = drag_speed,
		id = "input",
		skin = skin
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
	id := "v2_input",
	labels := string.[ "X", "Y" ],
	label_color := GRAY_00
) -> V2_Input {
	f := flow(gui);
	pos := f.cursor;
	z := f.z;
	align := f.align;
	origin := f.cursor;
	defer finish_widget(gui, origin, id);
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

	place(gui, lower_left + v2(2.0, height / 2), z, .Center_Left);
	x_input := float_input(
		gui,
		input_width,
		height - 4,
		value = state.value.x,
		min_value = min_value.x,
		max_value = max_value.x,
		drag_speed = drag_speed,
		precision = precision,
		id = "x"
	);
	if x_input.changed {
		state.value.x = x_input.value;
		state.x_changed = true;
		state.changed = true;
	}

	x_offset := component_width + 4.0;
	place(gui, lower_left + v2(x_offset + 2.0, height / 2), z, .Center_Left);
	y_input := float_input(
		gui,
		input_width,
		height - 4,
		value = state.value.y,
		min_value = min_value.y,
		max_value = max_value.y,
		drag_speed = drag_speed,
		precision = precision,
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
	id := "labeled_v2_input",
	padding := 4.0,
	labels := string.[ "X", "Y" ],
	label_color := GRAY_00
) -> V2_Input {
	_, w := widget(gui, id, struct {});

	f := flow(gui);
	pos := f.cursor;
	z := f.z;
	align := f.align;
	origin := f.cursor;
	defer finish_widget(gui, origin, id);

	push_id(gui, id);
	defer pop_id(gui);

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
	place(gui, lower_left + v2(width - padding, 0.0), z, Align.Center_Right);
	input_comp := v2_input(
		gui,
		input_width,
		height,
		value = value,
		min_value = min_value,
		max_value = max_value,
		drag_speed = drag_speed,
		precision = precision,
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
	labels := string.[ "X", "Y", "Z" ]
) -> V3_Input {
	f := flow(gui);
	pos := f.cursor;
	z := f.z;
	align := f.align;
	origin := f.cursor;
	defer finish_widget(gui, origin, id);

	state, w := widget(gui, id, V3_Input);

	push_id(gui, id);
	defer pop_id(gui);

	state.value = value;

	lower_left := align_pos(pos, .{ width, height }, align);

	component_width := width / 3.0;

	state.changed = false;
	state.x_changed = false;
	state.y_changed = false;
	state.z_changed = false;

	place(gui, lower_left + v2(0.0, height / 2.0), z, .Center_Left);
	x_input := float_input(
		gui,
		component_width,
		height - 4.0,
		value = state.value.x,
		min_value = min_value.x,
		max_value = max_value.x,
		drag_speed = drag_speed,
		precision = precision,
		id = "x"
	);
	if x_input.changed {
		state.value.x = x_input.value;
		state.x_changed = true;
		state.changed = true;
	}

	x_offset := component_width + 4.0;
	place(gui, lower_left + v2(x_offset + 2.0, height / 2.0), z, .Center_Left);
	y_input := float_input(
		gui,
		component_width,
		height - 4.0,
		value = state.value.y,
		min_value = min_value.y,
		max_value = max_value.y,
		drag_speed = drag_speed,
		precision = precision,
		id = "y"
	);
	if y_input.changed {
		state.value.y = y_input.value;
		state.y_changed = true;
		state.changed = true;
	}

	x_offset2 := 2.0 * component_width + 8.0;
	place(gui, lower_left + v2(x_offset2 + 2.0, height / 2.0), z, .Center_Left);
	z_input := float_input(
		gui,
		component_width,
		height - 4.0,
		value = state.value.z,
		min_value = min_value.z,
		max_value = max_value.z,
		drag_speed = drag_speed,
		precision = precision,
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
	id := "labeled_v3_input",
	padding := 4.0,
	labels := string.[ "X", "Y", "Z" ]
) -> V3_Input {
	_, w := widget(gui, id, struct {});

	f := flow(gui);
	pos := f.cursor;
	z := f.z;
	align := f.align;
	origin := f.cursor;
	defer finish_widget(gui, origin, id);
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

	input_width := width - widget_width(gui, "label") - padding * 3;
	place(gui, lower_left + v2(width - padding, 0.0), z, vertical(align) | Align.Right);
	input_comp := v3_input(
		gui,
		input_width,
		height,
		value = value,
		min_value = min_value,
		max_value = max_value,
		drag_speed = drag_speed,
		precision = precision,
		id = "input",
		labels = labels
	);

	w.aabb = widgets_aabb(gui, string.[ "label", "input" ]);
	return input_comp;
}
