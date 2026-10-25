/*
GUI2 - immediate-mode UI
========================

This module owns its layout, input, widget state, strings and draw commands.
The application supplies a Platform.Font and a Skin containing texture handles.
It has no dependency on GUI, Controls, Store or WRender.

QUICK START
-----------

    GUI2 :: #import "GUI2";

    // Persistent state. Initialize once; keep the pool alive with its strings.
    gui: GUI2.GUI_State;
    pool: GUI2.String_Pool;
    GUI2.gui_state_init(*gui, font, skin);
    GUI2.init(*pool);
    name := GUI2.make(*pool);
    GUI2.set(*name, "My terrain");
    enabled := true;
    speed := 1.0;

    GUI2.begin_frame(*gui, frame_info, keyboard_layout, blocked = console_open);
    {
        GUI2.begin_window(*gui, .{ 480, 240 }, pos = .{ 32, 32 }, id = "settings");
        defer GUI2.end(*gui);

        GUI2.label(*gui, "Settings", height = 18);
        GUI2.labeled_input_text(*gui, "Name", *name, .{ 456, 28 });
        enabled = GUI2.labeled_checkbox(*gui, "Enabled", .{ 456, 26 }, value = enabled).value;
        speed = GUI2.labeled_float_input(*gui, "Speed", .{ 456, 26 }, value = speed).value;

        GUI2.row(*gui);
        if GUI2.button(*gui, "Save", id = "save") {
            save_terrain(GUI2.view(*name));
        }
        if GUI2.button(*gui, "Cancel", id = "cancel") {
            close_settings();
        }
        GUI2.end(*gui);
    }
    GUI2.end_frame(*gui);
    // The application submits gui.quads/gui.chars through WRender.render_gui2.

API CONVENTIONS
---------------
    Ordinary widgets use this parameter order:

        gui, content, size/height, widget-specific options,
        id, pos, align, direction, z, skin

    Content is the label, text, string buffer or options, when applicable.
    Value and editing options follow the size. The final six overrides have the
    same order on every ordinary widget. Defaults come from the current flow.

    - Fixed widgets take size: V2f, including the label in labeled_* property rows.
      Both components are non-negative pixel extents; there are no width/height pairs.
    - Content-width label() and button() take height: float. Width is measured.
      Omit height to use skin.font_size for labels or skin.control_height for buttons.
    - label() and button() also have explicit size: V2f overloads for fixed boxes.
      Fixed label text_height controls its font independently of its box.
    - Containers put size first, then their options and layout overrides. Only
      row()/column() permit AUTO_SIZE or a negative component for an automatic axis.
    - Alignment anchors the whole widget at pos, or at the cursor when pos is omitted.
      Direction overrides cursor advancement without changing the parent's defaults.
    - An ordinary widget places once and calls finish() once. Composite property
      controls never advance the parent's cursor for their internal elements.
    - draw_* helpers begin with gui, then the resolved AABB or Placement, followed
      by content/style arguments. Interactive drawing helpers put id last.
      They may handle input and draw, but never advance the layout cursor.
    - Buttons return a click bool. Value controls return .value and .changed;
      vector controls also report which components changed. Text inputs modify
      their supplied String and return .changed and .committed.
      Labels return their AABB; images return the emitted Quad.

SIZING, LAYOUT AND STYLING
-------------------------

    // Content-width widgets: only their fixed height is specified.
    GUI2.label(*gui, "Position", height = 18);
    GUI2.button(*gui, "Pick", height = 26);

    // Fixed boxes: one V2f covers both dimensions, including property labels.
    GUI2.button(*gui, "Pick", .{ 120, 26 });
    GUI2.label(*gui, "Name", .{ 240, 26 }, text_height = 14);
    position = GUI2.labeled_v2_input(*gui, "Position", .{ 300, 26 }, value = position).value;

    GUI2.column(*gui, pos = .{ 20, 20 }, gap = .{ 6, 8 });
        GUI2.row(*gui);
            GUI2.label(*gui, "Position");
            GUI2.button(*gui, "Pick");
        GUI2.end(*gui);
    GUI2.end(*gui);

    GUI2.button(*gui, "Centered", pos = window_size / 2,
        align = GUI2.Align.HCenter | GUI2.Align.VCenter);

    // Automatic container axes support only starting-edge anchoring.
    GUI2.column(*gui, .{ 240, -1 }, pos = .{ 400, 20 },
        align = GUI2.Align.HCenter | GUI2.Align.Top);
        GUI2.flow(*gui).align = GUI2.Align.Top_Left;
        GUI2.button(*gui, "First");
        GUI2.button(*gui, "Second");
    GUI2.end(*gui);

    alternate_skin := skin;
    alternate_skin.button.rounded = 8;
    GUI2.row(*gui, skin = *alternate_skin);
        GUI2.button(*gui, "Rounded");
    GUI2.end(*gui);

    // Scroll size includes its gutter. The child column gets the remaining width.
    GUI2.scroll_begin(*gui, .{ 300, 400 }, id = "properties");
        for item: items {
            GUI2.push_id(*gui, item.id);
            GUI2.button(*gui, item.name, id = "select");
            GUI2.pop_id(*gui);
        }
    GUI2.scroll_end(*gui);

NOTES
-----
    - row(), column() and begin_window() pair with end(). Windows scope IDs.
      Container direction sets child flow; ending advances along the parent's flow.
    - scroll_begin() pairs with scroll_end() and scopes IDs. Content flows down;
      direction overrides advancement of the viewport in its parent.
      Offsets are pixels. Content extent/clamping has one frame of latency.
      Nested scroll zones are not supported. Dropdowns inherit the current clip.
    - Padding is inside a container; gap separates its children. Fixed containers
      keep their declared bounds when children overflow.
    - Flow clips are copied into widgets, quads and glyphs for rendering/hit testing.
    - Text input consumes committed UTF-8. Unsupported glyphs use the font fallback.
    - Click a number to edit it; drag to adjust it. Shift slows, Control speeds.
    - Quad.rounded is a pixel radius. Nine_Slice_Style.rounded masks only the fill.
    - Nine-slice corners and three-slice caps keep their authored scale, shrinking
      only when they cannot fit. Middles allow 25% stretch, then mirrored repetition.
    - On hot reload call rebind() for GUI_State and persistent String_Pools.
      Release owned strings and destroy GUI_State when their lifetime ends.

WIDGET INDEX
------------
    Parameters below follow declaration order. Defaults are in the definitions.

    label(gui, text, height: float, color, id, pos, align, direction, z, skin);
    label(gui, text, size: V2f, text_height, color, id, pos, align, direction, z, skin);
    image(gui, size: V2f, texture, texture_index, color, rounded, id, pos, align, direction, z, skin);
    button(gui, text, height: float, enabled, id, pos, align, direction, z, skin);
    button(gui, text, size: V2f, enabled, id, pos, align, direction, z, skin);
    input_text(gui, buf, size: V2f, placeholder, max_chars, id, pos, align, direction, z, skin);
    checkbox(gui, size: V2f, value, id, pos, align, direction, z, skin);
    dropdown(gui, options, size: V2f, value, id, pos, align, direction, z, skin);
    float_input(gui, size: V2f, value, min_value, max_value, drag_speed, precision, id, pos, align, direction, z, skin);
    int_input(gui, size: V2f, value, min_value, max_value, drag_speed, id, pos, align, direction, z, skin);
    labeled_input_text(gui, label, buf, size: V2f, placeholder, max_chars, label_color, id, pos, align, direction, z, skin);
    labeled_checkbox(gui, label, size: V2f, value, label_color, id, pos, align, direction, z, skin);
    labeled_dropdown(gui, label, options, size: V2f, value, label_color, id, pos, align, direction, z, skin);
    labeled_text_button(gui, label, text, size: V2f, enabled, label_color, id, pos, align, direction, z, skin);
    labeled_float_input(gui, label, size: V2f, value, min_value, max_value, drag_speed, precision, label_color, id, pos, align, direction, z, skin);
    labeled_int_input(gui, label, size: V2f, value, min_value, max_value, drag_speed, label_color, id, pos, align, direction, z, skin);
    labeled_v2_input(gui, label, size: V2f, value, min_value, max_value, drag_speed, precision, label_color, id, pos, align, direction, z, skin);
    labeled_v3_input(gui, label, size: V2f, value, min_value, max_value, drag_speed, precision, label_color, id, pos, align, direction, z, skin);

LAYOUT AND WINDOW INDEX
-----------------------
    row(gui, size: V2f, padding, gap, pos, align, direction, z, skin);
    column(gui, size: V2f, padding, gap, pos, align, direction, z, skin);
    end(gui);
    space(gui, amount);
    begin_window(gui, size: V2f, modal, padding, id, pos, align, direction, z, skin);
    scroll_begin(gui, size: V2f, padding, gap, scrollbar_width, wheel_step, id, pos, align, direction, z, skin);
    scroll_end(gui);

FRAME, STATE AND STRING INDEX
-----------------------------
    gui_state_init(gui, font, skin);
    rebind(pool, allocator);
    rebind(gui, font, skin);
    destroy(gui);
    begin_frame(gui, info, layout, blocked);
    end_frame(gui);
    push_id(gui, id);
    pop_id(gui);
    widget_aabb(gui, id);
    init(pool, allocator);
    make(pool, initial_capacity);
    view(s);
    set(s, text);
    insert(s, at, text);
    remove_range(s, at, count);
    grow(s, needed);
    release(s);

DRAWING HELPERS - NO FLOW ADVANCEMENT
------------------------------------
    draw_rect(gui, aabb, color, z, rounded);
    draw_slice_piece(gui, aabb, texture, source, z, tint, mirror_x, mirror_y);
    draw_slice(gui, aabb, style, z, tint);
    draw_three_slice(gui, aabb, style, z, tint);
    draw_panel(gui, aabb, skin, z);
    draw_text(gui, aabb, text, height, color, z, align, outline);
    draw_label(gui, p, text, height, color, id);
    draw_button(gui, p, text, enabled, id);
    draw_input_text(gui, aabb, buf, w, height, skin, placeholder, max_chars, z, unfocus_on_commit);
    draw_property_label(gui, p, text, label_color);
    draw_dropdown(gui, p, options, value, id);
    draw_number(gui, p, value, min_value, max_value, drag_speed, precision, id);

OTHER HELPERS
-------------
    flow(gui);
    placement(gui, size, pos, align, direction, z, skin);
    finish(gui, p);
    begin_container(gui, pos, direction, z, align, size, padding, gap, skin);
    container_aabb(gui);
    content_aabb(gui);
    available_width(gui);
    align_pos(pos, size, align);
    direction_delta(direction, size);
    include_bounds(f, aabb);
    get_widget(gui, id, aabb, z, physical);
    contains(aabb, p);
    text_width(gui, text, height);
    fit_text(gui, text, height, width);
    text_boundary(text, at);
    string_id(text);
    id_value(id: string);
    id_value(id: u64);
    id_value(id: s64);
    last_id(gui);
    combine_id(a, b);
*/

#scope_file
#import "Basic";
#import "String";
#import "Math";
#import "Algebra";
#import "Hash_Table";
Platform :: #import "Platform";

#scope_export

// Independent immediate-mode editor UI. Only the application knows about
// Store and WRender; this module owns geometry, input, strings and layout.
Align :: enum {
	Undefined :: 0;
	Left :: 1;
	Right :: 2;
	HCenter :: 3;
	Bottom :: 4;
	Top :: 8;
	VCenter :: 12;
	Top_Left :: 9;
	Top_Right :: 10;
	Top_Center :: 11;
	Bottom_Left :: 5;
	Bottom_Right :: 6;
	Bottom_Center :: 7;
	Center_Left :: 13;
	Center_Right :: 14;
	Center :: 15;
}

Direction :: enum {
	Inherit;
	Right;
	Down;
	Left;
	Up;
}

NO_POSITION :: V2f.{ FLOAT32_MAX, FLOAT32_MAX };
AUTO_SIZE :: V2f.{ -1, -1 };
INHERIT_SPACING :: V2f.{ -1, -1 };
TEXT_NORMAL :: V4f.{ 0.89, 0.87, 0.80, 1 };
INHERIT_COLOR :: V4f.{ 0, 0, 0, -1 };

String_Pool :: struct {
	allocator: Allocator;
}

String :: struct {
	count: s64;
	capacity: s64;
	data: *u8;
	pool: *String_Pool;
}

init :: (pool: *String_Pool, allocator := context.allocator) {
	pool.allocator = allocator;
}

rebind :: (pool: *String_Pool, allocator := context.allocator) {
	pool.allocator = allocator;
}

make :: (pool: *String_Pool, initial_capacity := 16) -> String {
	result: String;
	result.pool = pool;
	grow(*result, initial_capacity);
	return result;
}

grow :: (s: *String, needed: s64) {
	if needed <= s.capacity return;
	capacity := max(16, s.capacity);
	while capacity < needed {
		capacity *= 2;
	}
	s.data = xx realloc(s.data, capacity, s.capacity,, s.pool.allocator);
	s.capacity = capacity;
}

view :: (s: *String) -> string {
	return .{ s.count, s.data };
}

set :: (s: *String, text: string) {
	grow(s, text.count);
	if text.count > 0 {
		memcpy(s.data, text.data, text.count);
	}
	s.count = text.count;
}

insert :: (s: *String, at: s64, text: string) {
	assert(at >= 0 && at <= s.count);
	grow(s, s.count + text.count);
	i := s.count;
	while i > at {
		i -= 1;
		s.data[i + text.count] = s.data[i];
	}

	if text.count > 0 {
		memcpy(s.data + at, text.data, text.count);
	}
	s.count += text.count;
}

remove_range :: (s: *String, at: s64, count: s64) {
	assert(at >= 0 && count >= 0 && at + count <= s.count);
	for i: at..s.count - count - 1 {
		s.data[i] = s.data[i + count];
	}
	s.count -= count;
}

release :: (s: *String) {
	if s.data {
		free(s.data,, s.pool.allocator);
	}
	s.* = .{};
}

Texture :: struct {
	handle: *void;
	size: V2f;
}

Nine_Slice_Style :: struct {
	texture: Texture;
	borders: V4f;
	scale := 1.0;
	fill_color: V4f = .{ 0.04, 0.07, 0.08, 1 };
	rounded := 0.0; // Fill corner radius in logical pixels; the frame keeps its own alpha.
	transparent_center := true;
}

Three_Slice_Style :: struct {
	top: Texture;
	middle: Texture;
	bottom: Texture;
	scale := 1.0;
}

Skin :: struct {
	panel: Nine_Slice_Style;
	panel_fill: Texture;
	button: Nine_Slice_Style;
	input: Nine_Slice_Style;
	checkbox: Nine_Slice_Style;
	scroll_track: Three_Slice_Style;
	scroll_thumb: Three_Slice_Style;
	scrollbar_width := 24.0;
	text := TEXT_NORMAL;
	muted: V4f = .{ 0.60, 0.66, 0.67, 1 };
	accent: V4f = .{ 0.86, 0.70, 0.40, 1 };
	font_size := 14.0;
	control_height := 26.0;
}

Quad :: struct {
	pos: V2f;
	size: V2f;
	color: V4f = .{ 1, 1, 1, 1 };
	z: float;
	texture_rect: V4f;
	custom_texture: *void;
	custom_texture_idx := -1;
	repeat := false;
	rounded := 0.0; // Corner radius in logical pixels. Zero leaves the quad square.
	clip: AABBf;
}

Char :: struct {
	id: int;
	pos: V2f;
	size: V2f;
	color: V4f;
	z: float;
	outline: bool;
	clip: AABBf;
}

Input_State :: struct {
	using keys: Platform.Keys;
	text_input: string;
	text_input_active: bool;
	text_input_consumed: bool;
	mouse_pos: V2f;
	mouse_wheel: int;
	window_size: V2f;
	captured_mouse: bool;
	captured_keyboard: bool;
	delta_time: float;
	time: Apollo_Time;
	layout: Platform.Layout;
}

Flow :: struct {
	cursor: V2f;
	origin: V2f;
	insertion: V2f;
	direction := Direction.Down;
	align := Align.Top_Left;
	z: float;
	gap: V2f = .{ 6, 6 };
	padding: V2f;
	skin: Skin;
	size := AUTO_SIZE;
	content_bounds: AABBf;
	clip: AABBf;
	has_content := false;
	parent_direction: Direction;
	window := false;
	scroll_widget: *Widget;
	scroll_aabb: AABBf;
}

Scroll_State :: struct {
	offset: float; // Pixels from the top; independent of the changing content height.
	content_height: float;
	grab_offset: float;
	dragging: bool;
}

Widget :: struct {
	id: u64;
	aabb: AABBf;
	clip: AABBf;
	z: float;
	order: int;
	seen: int;
	physical := true;
	input := false;
	modal := false;
	hovered: bool;
	pressed: bool;
	released: bool;
	just_pressed: bool;
	cursor: int;
	display_start: int;
	text: String;
	editing: bool;
	dragging: bool;
	dragged: bool;
	drag_start_x: float;
	drag_start_value: float64;
	open: bool;
	popup_owner: u64;
	scroll: Scroll_State;
}

GUI_State :: struct {
	controls: Input_State;
	main_font: *Platform.Font;
	skin: Skin;
	flow_stack: [..] Flow;
	id_stack: [..] u64;
	widgets: Table(u64, *Widget);
	string_pool: String_Pool;
	quads: [..] Quad;
	chars: [..] Char;
	frame: int;
	order: int;
	mouse_owner: u64;
	focus: u64;
	blocked: bool;
	modal_z := -FLOAT32_MAX;
}

gui_state_init :: (gui: *GUI_State, font: *Platform.Font, skin: Skin) {
	gui.main_font = font;
	gui.skin = skin;
	rebind(*gui.string_pool);
}

rebind :: (gui: *GUI_State, font: *Platform.Font, skin: Skin) {
	gui_state_init(gui, font, skin);
}

destroy :: (gui: *GUI_State) {
	for w: gui.widgets {
		release(*w.text);
		free(w);
	}

	deinit(*gui.widgets);
	array_free(gui.quads);
	array_free(gui.chars);
	array_free(gui.flow_stack);
	array_free(gui.id_stack);
}

string_id :: (text: string) -> u64 {
	h: u64 = 14695981039346656037;
	for text {
		h = (h ^ it) * 1099511628211;
	}
	return h;
}

id_value :: (id: string) -> u64 {
	return string_id(id);
}

id_value :: (id: u64) -> u64 {
	return id;
}

id_value :: (id: s64) -> u64 {
	return xx id;
}

last_id :: (gui: *GUI_State) -> u64 {
	if gui.id_stack.count == 0 return 0;
	return gui.id_stack[gui.id_stack.count - 1];
}

combine_id :: (a: u64, b: u64) -> u64 {
	return (a ^ b) * 1099511628211;
}

push_id :: (gui: *GUI_State, id: $Id) {
	array_add(*gui.id_stack, combine_id(last_id(gui), id_value(id)));
}

pop_id :: (gui: *GUI_State) {
	assert(gui.id_stack.count > 0);
	gui.id_stack.count -= 1;
}

get_widget :: (
	gui: *GUI_State,
	id: $Id,
	aabb: AABBf,
	z: float,
	physical := true
) -> *Widget {
	key := combine_id(last_id(gui), id_value(id));
	found := table_find_pointer(*gui.widgets, key);
	w: *Widget;
	if found {
		w = found.*;
	} else {
		w = New(Widget);
		w.id = key;
		w.text.pool = *gui.string_pool;
		table_add(*gui.widgets, key, w);
	}

	w.aabb = aabb;
	w.clip = flow(gui).clip;
	w.z = z;
	w.physical = physical;
	w.order = gui.order;
	gui.order += 1;
	w.seen = gui.frame;
	if gui.blocked || z < gui.modal_z {
		w.hovered = false;
		w.pressed = false;
		w.released = false;
		w.just_pressed = false;
	}
	if !contains(w.clip, gui.controls.mouse_pos) {
		w.hovered = false;
		w.released = false;
		w.just_pressed = false;
	}

	return w;
}

widget_aabb :: (gui: *GUI_State, id: $Id) -> AABBf {
	w := table_find_pointer(*gui.widgets, combine_id(last_id(gui), id_value(id)));
	if w return w.*.aabb;
	return .{};
}

contains :: (aabb: AABBf, p: V2f) -> bool {
	return p.x >= aabb.min.x && p.y >= aabb.min.y && p.x < aabb.max.x && p.y < aabb.max.y;
}

begin_frame :: (
	gui: *GUI_State,
	info: Platform.Frame_Info,
	layout := Platform.Layout.AZERTY,
	blocked := false
) {
	gui.frame += 1;
	gui.order = 0;
	gui.blocked = blocked;
	gui.controls.keys = Platform.advance_keys(gui.controls.keys, info.keys.pressed, info.keys.just_released);
	for i: 0..Platform.Key_COUNT - 1 {
		gui.controls.just_pressed[i] |= info.keys.just_pressed[i];
	}
	gui.controls.text_input = info.text_input;
	gui.controls.text_input_active = false;
	gui.controls.text_input_consumed = false;
	gui.controls.mouse_pos = info.mouse_position;
	gui.controls.window_size = info.window_size;
	gui.controls.mouse_wheel = info.mouse_wheel;
	gui.controls.time = info.time;
	gui.controls.delta_time = info.delta_time;
	gui.controls.layout = ifx info.layout == .Unknown then layout else info.layout;
	gui.controls.captured_mouse = blocked;
	gui.controls.captured_keyboard = blocked;
	gui.quads.count = 0;
	gui.chars.count = 0;
	gui.flow_stack.count = 0;
	assert(gui.id_stack.count == 0);
	gui.modal_z = -FLOAT32_MAX;
	for w, key: gui.widgets {
		if w.seen < gui.frame - 1 {
			if gui.focus == key {
				gui.focus = 0;
			}
			if gui.mouse_owner == key {
				gui.mouse_owner = 0;
			}
			release(*w.text);
			free(w);
			remove key;
			continue;
		}

		w.hovered = false;
		w.pressed = false;
		w.released = false;
		w.just_pressed = false;
		if w.modal {
			gui.modal_z = max(gui.modal_z, w.z);
		}
	}

	flow(gui);
	if blocked return;
	hit: *Widget;
	for w: gui.widgets {
		if !w.physical || w.z < gui.modal_z continue;
		if !contains(w.aabb, gui.controls.mouse_pos) || !contains(w.clip, gui.controls.mouse_pos) continue;
		if w.popup_owner != 0 {
			parent := table_find_pointer(*gui.widgets, w.popup_owner);
			if !parent || !parent.*.open || parent.*.z < gui.modal_z continue;
		}

		if !hit || w.z > hit.z || (w.z == hit.z && w.order > hit.order) {
			hit = w;
		}
	}

	if hit {
		hit.hovered = true;
		gui.controls.captured_mouse = true;
	}

	if gui.controls.just_pressed[Platform.Key.MouseLeft] {
		gui.mouse_owner = 0;
		gui.focus = 0;
		if hit {
			gui.mouse_owner = hit.id;
			hit.just_pressed = true;
			if hit.input {
				gui.focus = hit.id;
			}
		}
	}

	owner := table_find_pointer(*gui.widgets, gui.mouse_owner);
	if owner && owner.*.z >= gui.modal_z {
		owner.*.pressed = gui.controls.pressed[Platform.Key.MouseLeft];
		owner.*.released = gui.controls.just_released[Platform.Key.MouseLeft] && owner.* == hit;
		gui.controls.captured_mouse |= owner.*.pressed || gui.controls.just_released[Platform.Key.MouseLeft];
	}

	focused := table_find_pointer(*gui.widgets, gui.focus);
	if focused && focused.*.z >= gui.modal_z {
		gui.controls.captured_keyboard = true;
	} else {
		gui.focus = 0;
	}
}

end_frame :: (gui: *GUI_State) {
	assert(gui.flow_stack.count == 1, "Unbalanced GUI2 row/column/window");
	assert(gui.id_stack.count == 0, "Unbalanced GUI2 IDs");
}

flow :: (gui: *GUI_State) -> *Flow {
	if gui.flow_stack.count == 0 {
		f: Flow;
		f.skin = gui.skin;
		f.clip = .{ .{ 0, 0 }, gui.controls.window_size };
		array_add(*gui.flow_stack, f);
	}

	return *gui.flow_stack[gui.flow_stack.count - 1];
}

align_pos :: (pos: V2f, size: V2f, align: Align) -> V2f {
	result := pos;
	if (align & .HCenter) == .HCenter {
		result.x -= size.x / 2;
	} else if (align & .Right) == .Right {
		result.x -= size.x;
	}
	if (align & .VCenter) == .VCenter {
		result.y -= size.y / 2;
	} else if (align & .Bottom) == .Bottom {
		result.y -= size.y;
	}
	return result;
}

direction_delta :: (direction: Direction, size: V2f) -> V2f {
	if direction == {
		case .Right;
			return .{ size.x, 0 };
		case .Left;
			return .{ -size.x, 0 };
		case .Down;
			return .{ 0, size.y };
		case .Up;
			return .{ 0, -size.y };
	}

	return .{};
}

include_bounds :: (f: *Flow, aabb: AABBf) {
	if f.has_content {
		f.content_bounds = aabb_union(f.content_bounds, aabb);
	} else {
		f.content_bounds = aabb;
		f.has_content = true;
	}
}

Placement :: struct {
	insertion: V2f;
	aabb: AABBf;
	direction: Direction;
	z: float;
	skin: Skin;
}

placement :: (
	gui: *GUI_State,
	size: V2f,
	pos := NO_POSITION,
	align := Align.Undefined,
	direction := Direction.Inherit,
	z := FLOAT32_MAX,
	skin: *Skin = null
) -> Placement {
	assert(size.x >= 0 && size.y >= 0, "Widget size must be non-negative");
	f := flow(gui).*;
	p: Placement;
	p.insertion = ifx pos.x == FLOAT32_MAX then f.cursor else pos;
	p.direction = ifx direction == .Inherit then f.direction else direction;
	p.z = ifx z == FLOAT32_MAX then f.z else z;
	p.skin = ifx skin then skin.* else f.skin;
	a := ifx align == .Undefined then f.align else align;
	p.aabb.min = align_pos(p.insertion, size, a);
	p.aabb.max = p.aabb.min + size;
	return p;
}

finish :: (gui: *GUI_State, p: Placement) {
	f := flow(gui);
	include_bounds(f, p.aabb);
	f.cursor = p.insertion + direction_delta(p.direction, p.aabb.max - p.aabb.min + f.gap);
}

begin_container :: (
	gui: *GUI_State,
	pos: V2f,
	direction: Direction,
	z: float,
	align: Align,
	size: V2f,
	padding: V2f,
	gap: V2f,
	skin: *Skin
) {
	parent := flow(gui).*;
	f: Flow;
	f.insertion = ifx pos.x == FLOAT32_MAX then parent.cursor else pos;
	f.align = ifx align == .Undefined then parent.align else align;
	assert(
		size.x >= 0 || (f.align & .HCenter) == .Left || (f.align & .HCenter) == .Undefined,
		"GUI2 horizontal anchoring needs an explicit width"
	);
	assert(
		size.y >= 0 || (f.align & .VCenter) == .Top || (f.align & .VCenter) == .Undefined,
		"GUI2 vertical anchoring needs an explicit height"
	);
	f.origin = align_pos(f.insertion, .{ max(0.0, size.x), max(0.0, size.y) }, f.align);
	f.padding = ifx padding.x < 0 then parent.padding else padding;
	f.gap = ifx gap.x < 0 then parent.gap else gap;
	f.cursor = f.origin + f.padding;
	f.z = ifx z == FLOAT32_MAX then parent.z else z;
	f.direction = ifx direction == .Inherit then parent.direction else direction;
	f.parent_direction = parent.direction;
	f.skin = ifx skin then skin.* else parent.skin;
	f.clip = parent.clip;
	f.size = size;
	array_add(*gui.flow_stack, f);
}

row :: (
	gui: *GUI_State,
	size := AUTO_SIZE,
	padding := V2f.{ 0, 0 },
	gap := INHERIT_SPACING,
	pos := NO_POSITION,
	align := Align.Undefined,
	direction := Direction.Right,
	z := FLOAT32_MAX,
	skin: *Skin = null
) {
	begin_container(gui, pos, direction, z, align, size, padding, gap, skin);
}

column :: (
	gui: *GUI_State,
	size := AUTO_SIZE,
	padding := V2f.{ 0, 0 },
	gap := INHERIT_SPACING,
	pos := NO_POSITION,
	align := Align.Undefined,
	direction := Direction.Down,
	z := FLOAT32_MAX,
	skin: *Skin = null
) {
	begin_container(gui, pos, direction, z, align, size, padding, gap, skin);
}

container_aabb :: (gui: *GUI_State) -> AABBf {
	f := flow(gui).*;
	b := AABBf.{ f.origin, f.origin + f.padding * 2 };
	if f.has_content {
		b.min = vmin(b.min, f.content_bounds.min - f.padding);
		b.max = vmax(b.max, f.content_bounds.max + f.padding);
	}

	if f.size.x >= 0 {
		b.min.x = f.origin.x;
		b.max.x = f.origin.x + f.size.x;
	}

	if f.size.y >= 0 {
		b.min.y = f.origin.y;
		b.max.y = f.origin.y + f.size.y;
	}

	return b;
}

content_aabb :: (gui: *GUI_State) -> AABBf {
	return flow(gui).content_bounds;
}

available_width :: (gui: *GUI_State) -> float {
	for < f: gui.flow_stack {
		if f.size.x >= 0 {
			return max(0.0, f.origin.x + f.size.x - f.padding.x - flow(gui).cursor.x);
		}
	}
	return max(0.0, gui.controls.window_size.x - flow(gui).cursor.x);
}

end :: (gui: *GUI_State) {
	assert(gui.flow_stack.count > 1);
	assert(!flow(gui).scroll_widget, "Pair scroll_begin() with scroll_end()");
	b := container_aabb(gui);
	f := flow(gui).*;
	gui.flow_stack.count -= 1;
	finish(gui, .{ insertion = f.insertion, aabb = b, direction = f.parent_direction });
	if f.window {
		pop_id(gui);
	}
}

space :: (gui: *GUI_State, amount: float) {
	f := flow(gui).*;
	size := abs(direction_delta(f.direction, v2(amount)));
	p := placement(gui, size);
	// A spacer consumes only its requested amount, with no implicit extra gap.
	include_bounds(flow(gui), p.aabb);
	flow(gui).cursor = f.cursor + direction_delta(f.direction, v2(amount));
}

draw_rect :: (
	gui: *GUI_State,
	aabb: AABBf,
	color: V4f,
	z: float,
	rounded := 0.0
) -> *Quad {
	q: Quad;
	q.pos = aabb.min;
	q.size = aabb.max - aabb.min;
	q.color = color;
	q.z = z;
	q.rounded = max(0.0, rounded);
	q.clip = flow(gui).clip;
	array_add(*gui.quads, q);
	return *gui.quads[gui.quads.count - 1];
}

draw_slice_piece :: (
	gui: *GUI_State,
	aabb: AABBf,
	texture: Texture,
	source: V4f,
	z: float,
	tint: V4f,
	mirror_x := false,
	mirror_y := false
) {
	size := aabb.max - aabb.min;
	if size.x <= 0 || size.y <= 0 || source.z <= 0 || source.w <= 0 return;

	// Keep filtering inside this source slice, including one-pixel rails.
	uv: V4f;
	uv.x = (source.x + 0.5) / texture.size.x;
	uv.y = (source.y + 0.5) / texture.size.y;
	uv.z = max(source.z - 1.0, 0.0001) / texture.size.x;
	uv.w = max(source.w - 1.0, 0.0001) / texture.size.y;
	if mirror_x {
		uv.x += uv.z;
		uv.z = -uv.z;
	}
	if mirror_y {
		uv.y += uv.w;
		uv.w = -uv.w;
	}

	q := draw_rect(gui, aabb, tint, z);
	q.custom_texture = texture.handle;
	q.texture_rect = uv;
}

draw_slice :: (
	gui: *GUI_State,
	aabb: AABBf,
	style: Nine_Slice_Style,
	z: float,
	tint := V4f.{ 1, 1, 1, 1 }
) {
	size := aabb.max - aabb.min;
	if size.x <= 0 || size.y <= 0 return;
	draw_rect(
		gui,
		shrink(aabb, 2),
		v4(
			style.fill_color.x * tint.x,
			style.fill_color.y * tint.y,
			style.fill_color.z * tint.z,
			style.fill_color.w * tint.w
		),
		z,
		rounded = style.rounded
	);
	if !style.texture.handle || style.texture.size.x <= 0 || style.texture.size.y <= 0 return;
	if style.scale <= 0 return;

	left := max(0.0, style.borders.x);
	top := max(0.0, style.borders.y);
	right := max(0.0, style.borders.z);
	bottom := max(0.0, style.borders.w);
	if left + right > style.texture.size.x || top + bottom > style.texture.size.y return;

	// Corners keep their authored size. Use one scale for both axes when the
	// destination is too small, preserving their shape and asymmetric borders.
	slice_scale := style.scale;
	if left + right > 0 {
		slice_scale = min(slice_scale, size.x / (left + right));
	}
	if top + bottom > 0 {
		slice_scale = min(slice_scale, size.y / (top + bottom));
	}

	x: [4] float = .[ 0, left * slice_scale, size.x - right * slice_scale, size.x ];
	y: [4] float = .[ 0, top * slice_scale, size.y - bottom * slice_scale, size.y ];
	source_x: [4] float = .[ 0, left, style.texture.size.x - right, style.texture.size.x ];
	source_y: [4] float = .[ 0, top, style.texture.size.y - bottom, style.texture.size.y ];

	for iy: 0..2 {
		for ix: 0..2 {
			if ix == 1 && iy == 1 && style.transparent_center continue;
			piece_size := v2(x[ix + 1] - x[ix], y[iy + 1] - y[iy]);
			source := v4(
				source_x[ix],
				source_y[iy],
				source_x[ix + 1] - source_x[ix],
				source_y[iy + 1] - source_y[iy]
			);
			if piece_size.x <= 0 || piece_size.y <= 0 || source.z <= 0 || source.w <= 0 continue;

			horizontal_rail := ix == 1 && iy != 1;
			vertical_rail := iy == 1 && ix != 1;
			repeat_count := 1;
			if horizontal_rail {
				repeat_count = max(1, ceil(piece_size.x / (source.z * slice_scale * 1.25)).(int));
			} else if vertical_rail {
				repeat_count = max(1, ceil(piece_size.y / (source.w * slice_scale * 1.25)).(int));
			}

			for i: 0..repeat_count - 1 {
				segment_min := aabb.min + v2(x[ix], y[iy]);
				segment_size := piece_size;
				if horizontal_rail {
					start := piece_size.x * i / repeat_count;
					end := piece_size.x * (i + 1) / repeat_count;
					segment_min.x += start;
					segment_size.x = end - start;
				} else if vertical_rail {
					start := piece_size.y * i / repeat_count;
					end := piece_size.y * (i + 1) / repeat_count;
					segment_min.y += start;
					segment_size.y = end - start;
				}

				draw_slice_piece(
					gui,
					.{ segment_min, segment_min + segment_size },
					style.texture,
					source,
					z + 0.01,
					tint,
					mirror_x = horizontal_rail && i % 2 == 1,
					mirror_y = vertical_rail && i % 2 == 1
				);
			}
		}
	}
}

draw_three_slice :: (
	gui: *GUI_State,
	aabb: AABBf,
	style: Three_Slice_Style,
	z: float,
	tint := V4f.{ 1, 1, 1, 1 }
) {
	size := aabb.max - aabb.min;
	if size.x <= 0 || size.y <= 0 || style.scale <= 0 return;
	width := max(style.top.size.x, max(style.middle.size.x, style.bottom.size.x));
	if width <= 0 return;

	slice_scale := min(style.scale, size.x / width);
	cap_height := style.top.size.y + style.bottom.size.y;
	if cap_height > 0 {
		slice_scale = min(slice_scale, size.y / cap_height);
	}
	top_height := style.top.size.y * slice_scale;
	bottom_height := style.bottom.size.y * slice_scale;
	middle_height := max(0.0, size.y - top_height - bottom_height);

	if style.top.handle {
		draw_slice_piece(
			gui,
			.{ aabb.min, v2(aabb.max.x, aabb.min.y + top_height) },
			style.top,
			.{ 0, 0, style.top.size.x, style.top.size.y },
			z,
			tint
		);
	}
	if style.middle.handle && style.middle.size.y > 0 && middle_height > 0 {
		repeat_count := max(1, ceil(middle_height / (style.middle.size.y * slice_scale * 1.25)).(int));
		for i: 0..repeat_count - 1 {
			start := middle_height * i / repeat_count;
			end := middle_height * (i + 1) / repeat_count;
			draw_slice_piece(
				gui,
				.{ v2(aabb.min.x, aabb.min.y + top_height + start),
					v2(aabb.max.x, aabb.min.y + top_height + end) },
				style.middle,
				.{ 0, 0, style.middle.size.x, style.middle.size.y },
				z,
				tint,
				mirror_y = i % 2 == 1
			);
		}
	}
	if style.bottom.handle {
		draw_slice_piece(
			gui,
			.{ v2(aabb.min.x, aabb.max.y - bottom_height), aabb.max },
			style.bottom,
			.{ 0, 0, style.bottom.size.x, style.bottom.size.y },
			z,
			tint
		);
	}
}

draw_panel :: (
	gui: *GUI_State,
	aabb: AABBf,
	skin: Skin,
	z: float
) {
	draw_slice(gui, aabb, skin.panel, z);
	if skin.panel_fill.handle {
		inner := AABBf.{ aabb.min + v2(6.0), aabb.max - v2(6.0) };
		q := draw_rect(gui, inner, .{ 0.18, 0.24, 0.27, 1 }, z + 0.001);
		q.custom_texture = skin.panel_fill.handle;
		q.repeat = true;
		q.rounded = max(0.0, skin.panel.rounded - 6.0);
		q.texture_rect = .{ 0, 0, (inner.max.x - inner.min.x) / 180, (inner.max.y - inner.min.y) / 180 };
	}
}

scroll_begin :: (
	gui: *GUI_State,
	size: V2f,
	padding := V2f.{ 0, 0 },
	gap := INHERIT_SPACING,
	scrollbar_width := -1.0,
	wheel_step := 30.0,
	id := "scroll",
	pos := NO_POSITION,
	align := Align.Undefined,
	direction := Direction.Inherit,
	z := FLOAT32_MAX,
	skin: *Skin = null
) -> *Scroll_State {
	assert(size.x >= 0 && size.y >= 0, "A scroll zone needs an explicit viewport size");
	for f: gui.flow_stack {
		assert(!f.scroll_widget, "Nested scroll zones are not supported");
	}
	p := placement(gui, size, pos, align, direction, z, skin);
	parent_clip := flow(gui).clip;
	bar_width := ifx scrollbar_width < 0 then p.skin.scrollbar_width else scrollbar_width;
	bar_width = clamp(bar_width, 0.0, size.x);
	content_width := max(0.0, size.x - bar_width);
	viewport := AABBf.{ p.aabb.min, v2(p.aabb.min.x + content_width, p.aabb.max.y) };

	push_id(gui, id);
	w := get_widget(gui, "zone", p.aabb, p.z);
	state := *w.scroll;
	// Use the previous frame's extent. Store only pixels, never a scroll ratio.
	max_scroll := max(0.0, state.content_height - size.y);
	state.offset = clamp(state.offset, 0.0, max_scroll);
	interactive := !gui.blocked && p.z >= gui.modal_z;
	if interactive && contains(p.aabb, gui.controls.mouse_pos) && contains(parent_clip, gui.controls.mouse_pos) {
		gui.controls.captured_mouse = true;
		state.offset = clamp(state.offset - gui.controls.mouse_wheel * wheel_step, 0.0, max_scroll);
		gui.controls.mouse_wheel = 0;
	}
	if !interactive || !gui.controls.pressed[Platform.Key.MouseLeft] {
		state.dragging = false;
	}

	if max_scroll > 0 && size.y > 0 && bar_width > 0 {
		track_aabb := AABBf.{ v2(viewport.max.x, p.aabb.min.y), p.aabb.max };
		track := get_widget(gui, "track", track_aabb, p.z + 0.1);
		min_thumb := max(20.0, (p.skin.scroll_thumb.top.size.y + p.skin.scroll_thumb.bottom.size.y)
			* p.skin.scroll_thumb.scale);
		thumb_height := min(size.y, max(min_thumb, size.y * size.y / state.content_height));
		travel := max(0.0, size.y - thumb_height);
		thumb_y := p.aabb.min.y + travel * state.offset / max_scroll;
		thumb_width := p.skin.scroll_thumb.middle.size.x * p.skin.scroll_thumb.scale;
		if thumb_width <= 0 thumb_width = bar_width * 0.75;
		thumb_width = min(bar_width, thumb_width);
		thumb_x := track_aabb.min.x + (bar_width - thumb_width) / 2;
		thumb_aabb := AABBf.{ v2(thumb_x, thumb_y), v2(thumb_x + thumb_width, thumb_y + thumb_height) };
		thumb := get_widget(gui, "thumb", thumb_aabb, p.z + 0.2);

		if thumb.just_pressed {
			state.dragging = true;
			state.grab_offset = gui.controls.mouse_pos.y - thumb_y;
		}
		if state.dragging && gui.mouse_owner == thumb.id && travel > 0 {
			state.offset = clamp(
				(gui.controls.mouse_pos.y - p.aabb.min.y - state.grab_offset) * max_scroll / travel,
				0.0,
				max_scroll
			);
			gui.controls.captured_mouse = true;
		} else if track.just_pressed {
			step := ifx gui.controls.mouse_pos.y < thumb_y then -size.y else size.y;
			state.offset = clamp(state.offset + step, 0.0, max_scroll);
		}
		thumb_y = p.aabb.min.y + travel * state.offset / max_scroll;
		thumb_aabb = .{ v2(thumb_x, thumb_y), v2(thumb_x + thumb_width, thumb_y + thumb_height) };
		thumb.aabb = thumb_aabb;

		if p.skin.scroll_track.middle.handle {
			draw_three_slice(gui, track_aabb, p.skin.scroll_track, p.z + 0.1);
		} else {
			draw_rect(gui, track_aabb, .{ 0.02, 0.04, 0.05, 1 }, p.z + 0.1);
		}
		tint := ifx state.dragging then v4(0.75, 0.75, 0.75, 1)
			else ifx thumb.hovered then v4(1.2, 1.2, 1.2, 1) else v4(1.0, 1.0, 1.0, 1);
		if p.skin.scroll_thumb.middle.handle {
			draw_three_slice(gui, thumb_aabb, p.skin.scroll_thumb, p.z + 0.2, tint);
		} else {
			draw_rect(gui, thumb_aabb, p.skin.accent, p.z + 0.2, rounded = 4);
		}
	} else {
		state.dragging = false;
	}

	column(gui, pos = viewport.min, size = .{ content_width, -1 }, align = .Top_Left,
		z = p.z, padding = padding, gap = gap, skin = *p.skin);
	f := flow(gui);
	f.insertion = p.insertion;
	f.parent_direction = p.direction;
	f.origin.y -= state.offset;
	f.cursor.y -= state.offset;
	f.clip = .{ vmax(parent_clip.min, viewport.min), vmin(parent_clip.max, viewport.max) };
	f.scroll_widget = w;
	f.scroll_aabb = p.aabb;
	return state;
}

scroll_end :: (gui: *GUI_State) {
	assert(gui.flow_stack.count > 1 && flow(gui).scroll_widget != null, "Unbalanced scroll_end()");
	f := flow(gui).*;
	content_height := f.padding.y * 2;
	if f.has_content {
		content_height = max(content_height, f.content_bounds.max.y - f.origin.y + f.padding.y);
	}
	// A changed extent affects clamping next frame, after all this frame's content is drawn.
	f.scroll_widget.scroll.content_height = content_height;
	gui.flow_stack.count -= 1;
	finish(gui, .{ insertion = f.insertion, aabb = f.scroll_aabb, direction = f.parent_direction });
	pop_id(gui);
}

begin_window :: (
	gui: *GUI_State,
	size: V2f,
	modal := false,
	padding := V2f.{ 16, 16 },
	id := "window",
	pos := NO_POSITION,
	align := Align.Undefined,
	direction := Direction.Down,
	z := FLOAT32_MAX,
	skin: *Skin = null
) {
	assert(size.x >= 0 && size.y >= 0, "A window needs an explicit size");
	window_z := ifx z == FLOAT32_MAX then flow(gui).z else z;
	push_id(gui, id);
	column(
		gui,
		pos = pos,
		direction = direction,
		z = window_z + 1,
		align = align,
		size = size,
		padding = padding,
		skin = skin
	);
	f := flow(gui);
	f.align = .Top_Left;
	f.window = true;
	b := container_aabb(gui);
	draw_panel(gui, b, f.skin, window_z);
	w := get_widget(
		gui,
		"window_panel",
		ifx modal then AABBf.{ .{ 0, 0 }, gui.controls.window_size } else b,
		window_z
	);
	w.modal = modal;
	if modal {
		gui.modal_z = max(gui.modal_z, window_z);
		draw_rect(gui, .{ .{ 0, 0 }, gui.controls.window_size }, .{ 0, 0, 0, 0.65 }, window_z - 0.1);
		gui.controls.captured_mouse = true;
		gui.controls.captured_keyboard = true;
	} else if contains(b, gui.controls.mouse_pos) && contains(f.clip, gui.controls.mouse_pos) {
		gui.controls.captured_mouse = true;
	}
}

text_width :: (gui: *GUI_State, text: string, height: float) -> float {
	width := 0.0;
	i := 0;
	while i < text.count {
		cp, next := Platform.text_next(text, i);
		if gui.main_font {
			width += Platform.text_glyph(gui.main_font, cp).advance * height;
		} else {
			width += height / 2;
		}
		i = next;
	}

	return width;
}

fit_text :: (
	gui: *GUI_State,
	text: string,
	height: float,
	width: float
) -> string {
	i := 0;
	advance := 0.0;
	while i < text.count {
		cp, next := Platform.text_next(text, i);
		step := ifx gui.main_font then Platform.text_glyph(gui.main_font, cp).advance * height else height / 2;
		if advance + step > width break;
		advance += step;
		i = next;
	}

	return slice(text, 0, i);
}

draw_text :: (
	gui: *GUI_State,
	aabb: AABBf,
	text: string,
	height: float,
	color: V4f,
	z: float,
	align := Align.Center_Left,
	outline := false
) {
	if !gui.main_font return;
	text_size := v2(text_width(gui, text, height), height);
	anchor := aabb.min;
	if (align & .HCenter) == .HCenter {
		anchor.x += (aabb.max.x - aabb.min.x) / 2;
	} else if (align & .Right) == .Right {
		anchor.x = aabb.max.x;
	}
	if (align & .VCenter) == .VCenter {
		anchor.y += (aabb.max.y - aabb.min.y) / 2;
	} else if (align & .Bottom) == .Bottom {
		anchor.y = aabb.max.y;
	}
	p := align_pos(anchor, text_size, align);
	i := 0;
	while i < text.count {
		cp, next := Platform.text_next(text, i);
		glyph := Platform.text_glyph(gui.main_font, cp);
		ch: Char;
		ch.id = glyph.unicode;
		ch.pos = p + v2(glyph.planex * height, (0.8 - glyph.planeh) * height);
		ch.size = v2(glyph.planew - glyph.planex, glyph.planeh - glyph.planey) * height;
		ch.z = z;
		ch.color = color;
		ch.outline = outline;
		ch.clip = flow(gui).clip;
		array_add(*gui.chars, ch);
		p.x += glyph.advance * height;
		i = next;
	}
}

draw_label :: (
	gui: *GUI_State,
	p: Placement,
	text: string,
	height: float,
	color: V4f,
	id: string
) {
	get_widget(gui, id, p.aabb, p.z, false);
	draw_text(
		gui,
		p.aabb,
		fit_text(gui, text, height, p.aabb.max.x - p.aabb.min.x),
		height,
		ifx color.w < 0 then p.skin.text else color,
		p.z
	);
}

label :: (
	gui: *GUI_State,
	text: string,
	height := -1.0,
	color := INHERIT_COLOR,
	id := "label",
	pos := NO_POSITION,
	align := Align.Undefined,
	direction := Direction.Inherit,
	z := FLOAT32_MAX,
	skin: *Skin = null
) -> AABBf {
	s := ifx skin then skin.* else flow(gui).skin;
	actual_height := ifx height < 0 then s.font_size else height;
	size := v2(text_width(gui, text, actual_height), actual_height);
	p := placement(gui, size, pos, align, direction, z, skin);
	draw_label(gui, p, text, actual_height, color, id);
	finish(gui, p);
	return p.aabb;
}

label :: (
	gui: *GUI_State,
	text: string,
	size: V2f,
	text_height := -1.0,
	color := INHERIT_COLOR,
	id := "label",
	pos := NO_POSITION,
	align := Align.Undefined,
	direction := Direction.Inherit,
	z := FLOAT32_MAX,
	skin: *Skin = null
) -> AABBf {
	p := placement(gui, size, pos, align, direction, z, skin);
	actual_height := ifx text_height < 0 then p.skin.font_size else text_height;
	draw_label(gui, p, text, actual_height, color, id);
	finish(gui, p);
	return p.aabb;
}

image :: (
	gui: *GUI_State,
	size: V2f,
	texture: *void = null,
	texture_index := -1,
	color := V4f.{ 1, 1, 1, 1 },
	rounded := 0.0,
	id := "image",
	pos := NO_POSITION,
	align := Align.Undefined,
	direction := Direction.Inherit,
	z := FLOAT32_MAX,
	skin: *Skin = null
) -> *Quad {
	p := placement(gui, size, pos, align, direction, z, skin);
	get_widget(gui, id, p.aabb, p.z, false);
	q := draw_rect(gui, p.aabb, color, p.z, rounded = rounded);
	q.custom_texture = texture;
	q.custom_texture_idx = texture_index;
	if texture || texture_index >= 0 {
		q.texture_rect = .{ 0, 0, 1, 1 };
	}
	finish(gui, p);
	return q;
}

draw_button :: (
	gui: *GUI_State,
	p: Placement,
	text: string,
	enabled: bool,
	id: string
) -> bool {
	w := get_widget(gui, id, p.aabb, p.z, enabled);
	tint := ifx !enabled then v4(0.5, 0.5, 0.5, 1) else ifx w.pressed then v4(0.72, 0.72, 0.72, 1)
		else ifx w.hovered then v4(1.2, 1.2, 1.2, 1) else v4(1.0, 1.0, 1.0, 1);
	draw_slice(gui, p.aabb, p.skin.button, p.z, tint);
	draw_text(
		gui,
		p.aabb,
		fit_text(gui, text, p.skin.font_size, max(0.0, p.aabb.max.x - p.aabb.min.x - 8)),
		p.skin.font_size,
		p.skin.text,
		p.z + 0.1,
		.Center
	);
	return enabled && w.released;
}

button :: (
	gui: *GUI_State,
	text: string,
	height := -1.0,
	enabled := true,
	id := "button",
	pos := NO_POSITION,
	align := Align.Undefined,
	direction := Direction.Inherit,
	z := FLOAT32_MAX,
	skin: *Skin = null
) -> bool {
	s := ifx skin then skin.* else flow(gui).skin;
	actual_height := ifx height < 0 then s.control_height else height;
	size := v2(max(26.0, text_width(gui, text, s.font_size) + 16), actual_height);
	p := placement(gui, size, pos, align, direction, z, skin);
	clicked := draw_button(gui, p, text, enabled, id);
	finish(gui, p);
	return clicked;
}

button :: (
	gui: *GUI_State,
	text: string,
	size: V2f,
	enabled := true,
	id := "button",
	pos := NO_POSITION,
	align := Align.Undefined,
	direction := Direction.Inherit,
	z := FLOAT32_MAX,
	skin: *Skin = null
) -> bool {
	p := placement(gui, size, pos, align, direction, z, skin);
	clicked := draw_button(gui, p, text, enabled, id);
	finish(gui, p);
	return clicked;
}

Input_Text_Result :: struct {
	changed: bool;
	committed: bool;
}

text_boundary :: (text: string, at: int) -> int {
	i := 0;
	end := clamp(at, 0, text.count);
	while i < end {
		_, next := Platform.text_next(text, i);
		if next > end break;
		i = next;
	}

	return i;
}

draw_input_text :: (
	gui: *GUI_State,
	aabb: AABBf,
	buf: *String,
	w: *Widget,
	height: float,
	skin: Skin,
	placeholder: string,
	max_chars: int,
	z: float,
	unfocus_on_commit := true
) -> Input_Text_Result {
	result: Input_Text_Result;
	w.input = true;
	text := view(buf);
	w.cursor = text_boundary(text, w.cursor);
	if w.just_pressed {
		gui.focus = w.id;
		w.cursor = text_boundary(text, w.display_start);
		x := aabb.min.x + 4;
		while w.cursor < text.count {
			cp, next := Platform.text_next(text, w.cursor);
			advance := ifx gui.main_font then Platform.text_glyph(gui.main_font, cp).advance * height else height / 2;
			if gui.controls.mouse_pos.x < x + advance / 2 break;
			x += advance;
			w.cursor = next;
		}
	}

	focused := gui.focus == w.id && !gui.blocked && z >= gui.modal_z;
	if focused {
		gui.controls.captured_keyboard = true;
		gui.controls.text_input_active = true;
		if gui.controls.just_pressed[Platform.Key.Escape] {
			gui.focus = 0;
			focused = false;
		} else {
			if !gui.controls.text_input_consumed {
				gui.controls.text_input_consumed = true;
				i := 0;
				count := Platform.text_character_count(view(buf));
				while i < gui.controls.text_input.count {
					cp, next := Platform.text_next(gui.controls.text_input, i);
					if cp >= 32 && cp != 127 && (max_chars < 0 || count < max_chars) {
						part := slice(gui.controls.text_input, i, next - i);
						insert(buf, w.cursor, part);
						w.cursor += part.count;
						count += 1;
						result.changed = true;
					}

					i = next;
				}
			}

			if gui.controls.just_pressed[Platform.Key.Backspace] && w.cursor > 0 {
				previous := Platform.text_previous(view(buf), w.cursor);
				remove_range(buf, previous, w.cursor - previous);
				w.cursor = previous;
				result.changed = true;
			}

			if gui.controls.just_pressed[Platform.Key.Delete] && w.cursor < buf.count {
				_, next := Platform.text_next(view(buf), w.cursor);
				remove_range(buf, w.cursor, next - w.cursor);
				result.changed = true;
			}

			if gui.controls.just_pressed[Platform.Key.Left] {
				w.cursor = Platform.text_previous(view(buf), w.cursor);
			}
			if gui.controls.just_pressed[Platform.Key.Right] && w.cursor < buf.count {
				_, next := Platform.text_next(view(buf), w.cursor);
				w.cursor = next;
			}

			if gui.controls.just_pressed[Platform.Key.Home] {
				w.cursor = 0;
			}
			if gui.controls.just_pressed[Platform.Key.End] {
				w.cursor = buf.count;
			}
			if gui.controls.just_pressed[Platform.Key.Enter] {
				result.committed = true;
				if unfocus_on_commit {
					gui.focus = 0;
				}
			}
		}
	}

	draw_slice(gui, aabb, skin.input, z);
	if focused {
		draw_rect(gui, .{ aabb.min, v2(aabb.max.x, aabb.min.y + 1) }, skin.accent, z + 0.02);
	}
	inner := AABBf.{ aabb.min + v2(4.0, 0.0), aabb.max - v2(4.0, 0.0) };
	width := max(0.0, inner.max.x - inner.min.x - 1);
	text = view(buf);
	w.display_start = 0;
	if focused {
		while w.display_start < w.cursor && text_width(gui, slice(text, w.display_start, w.cursor - w.display_start), height) > width {
			_, next := Platform.text_next(text, w.display_start);
			w.display_start = next;
		}
	}

	displayed := ifx text.count > 0 then slice(
		text,
		w.display_start,
		text.count - w.display_start
	) else placeholder;
	draw_text(gui, inner, fit_text(gui, displayed, height, width), height,
		ifx text.count > 0 then skin.text else skin.muted, z + 0.03);
	if focused {
		x := inner.min.x + text_width(gui, slice(text, w.display_start, w.cursor - w.display_start), height);
		draw_rect(gui, .{ v2(x, aabb.min.y + 4), v2(x + 1, aabb.max.y - 4) }, skin.accent, z + 0.04);
	}

	return result;
}

input_text :: (
	gui: *GUI_State,
	buf: *String,
	size: V2f,
	placeholder := "",
	max_chars := -1,
	id := "input_text",
	pos := NO_POSITION,
	align := Align.Undefined,
	direction := Direction.Inherit,
	z := FLOAT32_MAX,
	skin: *Skin = null
) -> Input_Text_Result {
	p := placement(gui, size, pos, align, direction, z, skin);
	w := get_widget(gui, id, p.aabb, p.z);
	result := draw_input_text(
		gui,
		p.aabb,
		buf,
		w,
		min(p.skin.font_size, size.y * 0.65),
		p.skin,
		placeholder,
		max_chars,
		p.z
	);
	finish(gui, p);
	return result;
}

// Property widgets have a single outer placement. Their private controls do
// not advance or mutate the caller's flow.
draw_property_label :: (
	gui: *GUI_State,
	p: Placement,
	text: string,
	label_color: V4f
) -> AABBf {
	width := p.aabb.max.x - p.aabb.min.x;
	label_width := min(width * 0.43, max(48.0, text_width(gui, text, p.skin.font_size) + 8));
	l := p.aabb;
	l.max.x = l.min.x + label_width;
	draw_text(gui, l, fit_text(gui, text, p.skin.font_size, max(0.0, label_width - 6)), p.skin.font_size,
		ifx label_color.w < 0 then p.skin.text else label_color, p.z + 0.1);
	input := p.aabb;
	input.min.x += label_width;
	return input;
}

labeled_input_text :: (
	gui: *GUI_State,
	label: string,
	buf: *String,
	size: V2f,
	placeholder := "",
	max_chars := -1,
	label_color := INHERIT_COLOR,
	id := "labeled_input_text",
	pos := NO_POSITION,
	align := Align.Undefined,
	direction := Direction.Inherit,
	z := FLOAT32_MAX,
	skin: *Skin = null
) -> Input_Text_Result {
	p := placement(gui, size, pos, align, direction, z, skin);
	push_id(gui, id);
	a := draw_property_label(gui, p, label, label_color);
	w := get_widget(gui, "input", a, p.z);
	result := draw_input_text(gui, a, buf, w, p.skin.font_size, p.skin, placeholder, max_chars, p.z);
	pop_id(gui);
	get_widget(gui, id, p.aabb, p.z, false);
	finish(gui, p);
	return result;
}

Checkbox :: struct {
	value: bool;
	changed: bool;
}

checkbox :: (
	gui: *GUI_State,
	size: V2f,
	value := false,
	id := "checkbox",
	pos := NO_POSITION,
	align := Align.Undefined,
	direction := Direction.Inherit,
	z := FLOAT32_MAX,
	skin: *Skin = null
) -> Checkbox {
	p := placement(gui, size, pos, align, direction, z, skin);
	w := get_widget(gui, id, p.aabb, p.z);
	checked := ifx w.released then !value else value;
	draw_slice(gui, p.aabb, p.skin.checkbox, p.z);
	if checked {
		draw_text(gui, p.aabb, "X", p.skin.font_size, p.skin.accent, p.z + 0.1, .Center);
	}
	finish(gui, p);
	return .{ checked, w.released };
}

labeled_checkbox :: (
	gui: *GUI_State,
	label: string,
	size: V2f,
	value := false,
	label_color := INHERIT_COLOR,
	id := "labeled_checkbox",
	pos := NO_POSITION,
	align := Align.Undefined,
	direction := Direction.Inherit,
	z := FLOAT32_MAX,
	skin: *Skin = null
) -> Checkbox {
	p := placement(gui, size, pos, align, direction, z, skin);
	a := draw_property_label(gui, p, label, label_color);
	w := get_widget(gui, id, p.aabb, p.z);
	checked := ifx w.released then !value else value;
	a.min.x = max(a.min.x, a.max.x - size.y);
	a.max.x = a.min.x + size.y;
	draw_slice(gui, a, p.skin.checkbox, p.z);
	if checked {
		draw_text(gui, a, "X", p.skin.font_size, p.skin.accent, p.z + 0.1, .Center);
	}
	finish(gui, p);
	return .{ checked, w.released };
}

Dropdown :: struct {
	value: int;
	changed: bool;
}

draw_dropdown :: (
	gui: *GUI_State,
	p: Placement,
	options: [] string,
	value: int,
	id: string
) -> Dropdown {
	w := get_widget(gui, id, p.aabb, p.z);
	was_open := w.open;
	if w.just_pressed {
		w.open = !w.open;
	}
	if was_open || w.open {
		// Closing the popup must consume that click/Escape rather than pass it to the scene.
		gui.controls.captured_keyboard = true;
		gui.controls.captured_mouse = true;
	}

	if gui.controls.just_pressed[Platform.Key.Escape] || gui.blocked || p.z < gui.modal_z {
		w.open = false;
	}
	if gui.controls.just_pressed[Platform.Key.MouseLeft] && !w.hovered && gui.mouse_owner != w.id {
		// Option ownership keeps the popup open until that option consumes release.
		owner := table_find_pointer(*gui.widgets, gui.mouse_owner);
		if !owner || owner.*.z < p.z + 100 {
			w.open = false;
		}
	}

	result: Dropdown;
	result.value = clamp(value, 0, max(0, options.count - 1));
	draw_slice(gui, p.aabb, p.skin.button, p.z);
	if options.count > 0 draw_text(gui, p.aabb, fit_text(gui, options[result.value], p.skin.font_size,
		max(0.0, p.aabb.max.x - p.aabb.min.x - 22)), p.skin.font_size, p.skin.text, p.z + 0.1);
	draw_text(
		gui,
		.{ p.aabb.max - v2(18.0, p.aabb.max.y - p.aabb.min.y), p.aabb.max },
		"v",
		p.skin.font_size,
		p.skin.accent,
		p.z + 0.2,
		.Center
	);
	if w.open {
		push_id(gui, id);
		defer pop_id(gui);
		height := p.aabb.max.y - p.aabb.min.y;
		for options {
			a := p.aabb;
			a.min.y += height * (it_index + 1);
			a.max.y += height * (it_index + 1);
			option := get_widget(gui, it_index, a, p.z + 100);
			option.popup_owner = w.id;
			draw_slice(gui, a, p.skin.button, p.z + 100);
			draw_text(gui, a, fit_text(gui, it, p.skin.font_size, max(0.0, a.max.x - a.min.x - 8)),
				p.skin.font_size, ifx option.hovered then p.skin.accent else p.skin.text, p.z + 100.1);
			if option.released {
				result.value = it_index;
				result.changed = true;
				w.open = false;
			}
		}

		gui.controls.captured_mouse = true;
	}

	return result;
}

dropdown :: (
	gui: *GUI_State,
	options: [] string,
	size: V2f,
	value := 0,
	id := "dropdown",
	pos := NO_POSITION,
	align := Align.Undefined,
	direction := Direction.Inherit,
	z := FLOAT32_MAX,
	skin: *Skin = null
) -> Dropdown {
	p := placement(gui, size, pos, align, direction, z, skin);
	result := draw_dropdown(gui, p, options, value, id);
	finish(gui, p);
	return result;
}

labeled_dropdown :: (
	gui: *GUI_State,
	label: string,
	options: [] string,
	size: V2f,
	value := 0,
	label_color := INHERIT_COLOR,
	id := "labeled_dropdown",
	pos := NO_POSITION,
	align := Align.Undefined,
	direction := Direction.Inherit,
	z := FLOAT32_MAX,
	skin: *Skin = null
) -> Dropdown {
	p := placement(gui, size, pos, align, direction, z, skin);
	push_id(gui, id);
	input := p;
	input.aabb = draw_property_label(gui, p, label, label_color);
	result := draw_dropdown(gui, input, options, value, "input");
	pop_id(gui);
	get_widget(gui, id, p.aabb, p.z, false);
	finish(gui, p);
	return result;
}

labeled_text_button :: (
	gui: *GUI_State,
	label: string,
	text: string,
	size: V2f,
	enabled := true,
	label_color := INHERIT_COLOR,
	id := "labeled_text_button",
	pos := NO_POSITION,
	align := Align.Undefined,
	direction := Direction.Inherit,
	z := FLOAT32_MAX,
	skin: *Skin = null
) -> bool {
	p := placement(gui, size, pos, align, direction, z, skin);
	input := p;
	input.aabb = draw_property_label(gui, p, label, label_color);
	push_id(gui, id);
	clicked := draw_button(gui, input, text, enabled, "button");
	pop_id(gui);
	get_widget(gui, id, p.aabb, p.z, false);
	finish(gui, p);
	return clicked;
}

Float_Input :: struct {
	value: float;
	changed: bool;
}

Int_Input :: struct {
	value: int;
	changed: bool;
}

V2_Input :: struct {
	value: V2f;
	changed: bool;
	x_changed: bool;
	y_changed: bool;
}

V3_Input :: struct {
	value: V3f;
	changed: bool;
	x_changed: bool;
	y_changed: bool;
	z_changed: bool;
}

draw_number :: (
	gui: *GUI_State,
	p: Placement,
	value: $T,
	min_value: T,
	max_value: T,
	drag_speed: T,
	precision: int,
	id: string
) -> T, bool {
	w := get_widget(gui, id, p.aabb, p.z);
	result := clamp(value, min_value, max_value);
	interactive := !gui.blocked && p.z >= gui.modal_z;
	if !interactive {
		w.dragging = false;
	}

	if w.just_pressed && !w.editing {
		w.dragging = true;
		w.dragged = false;
		w.drag_start_x = gui.controls.mouse_pos.x;
		w.drag_start_value = xx result;
	}

	if w.dragging {
		dx := gui.controls.mouse_pos.x - w.drag_start_x;
		if abs(dx) > 3 {
			w.dragged = true;
		}
		if w.dragged && gui.controls.pressed[Platform.Key.MouseLeft] && interactive {
			speed := drag_speed.(float64);
			if gui.controls.pressed[Platform.Key.Shift] {
				speed *= 0.1;
			}
			if gui.controls.pressed[Platform.Key.Control] {
				speed *= 10;
			}
			number := w.drag_start_value + dx * speed;
			#if T == int number = floor(number + 0.5);
			// Bound before converting: S64_MAX rounds up when represented as f64.
			if number <= min_value.(float64) {
				result = min_value;
			} else if number >= max_value.(float64) {
				result = max_value;
			} else {
				result = xx number;
			}
		}

		if !gui.controls.pressed[Platform.Key.MouseLeft] || gui.blocked {
			w.dragging = false;
			if w.released && !w.dragged {
				w.editing = true;
				gui.focus = w.id;
				#if T == int text := tprint("%", result);
				else text := tprint("%", formatFloat(result, width = precision));
				set(*w.text, text);
				w.cursor = text.count;
			}
		}
	}

	if w.editing {
		input_result := draw_input_text(gui, p.aabb, *w.text, w, p.skin.font_size, p.skin, "", 64, p.z);
		if input_result.committed || gui.focus != w.id {
			if !gui.controls.just_pressed[Platform.Key.Escape] {
				#if T == int parsed, ok := string_to_int(view(*w.text));
				else parsed, ok := string_to_float(view(*w.text));
				if ok && is_finite(parsed.(float64)) {
					result = xx clamp(parsed, min_value, max_value);
				}
			}

			w.editing = false;
			if gui.focus == w.id {
				gui.focus = 0;
			}
		}
	} else {
		draw_slice(gui, p.aabb, p.skin.input, p.z);
		#if T == int text := tprint("%", result);
		else text := tprint("%", formatFloat(result, width = precision));
		draw_text(gui, p.aabb,
			fit_text(gui, text, p.skin.font_size, max(0.0, p.aabb.max.x - p.aabb.min.x - 8)), p.skin.font_size, p.skin.text, p.z + 0.1, .Center);
	}

	w.input = w.editing;
	return result, result != value;
}

float_input :: (
	gui: *GUI_State,
	size: V2f,
	value: float,
	min_value := -FLOAT32_MAX,
	max_value := FLOAT32_MAX,
	drag_speed := 0.01,
	precision := 3,
	id := "float_input",
	pos := NO_POSITION,
	align := Align.Undefined,
	direction := Direction.Inherit,
	z := FLOAT32_MAX,
	skin: *Skin = null
) -> Float_Input {
	p := placement(gui, size, pos, align, direction, z, skin);
	result: Float_Input;
	result.value, result.changed = draw_number(gui, p, value, min_value, max_value, drag_speed, precision, id);
	finish(gui, p);
	return result;
}

int_input :: (
	gui: *GUI_State,
	size: V2f,
	value: int,
	min_value := S64_MIN,
	max_value := S64_MAX,
	drag_speed: int = 1,
	id := "int_input",
	pos := NO_POSITION,
	align := Align.Undefined,
	direction := Direction.Inherit,
	z := FLOAT32_MAX,
	skin: *Skin = null
) -> Int_Input {
	p := placement(gui, size, pos, align, direction, z, skin);
	result: Int_Input;
	result.value, result.changed = draw_number(gui, p, value, min_value, max_value, drag_speed, 0, id);
	finish(gui, p);
	return result;
}

labeled_float_input :: (
	gui: *GUI_State,
	label: string,
	size: V2f,
	value: float,
	min_value := -FLOAT32_MAX,
	max_value := FLOAT32_MAX,
	drag_speed := 0.01,
	precision := 3,
	label_color := INHERIT_COLOR,
	id := "labeled_float_input",
	pos := NO_POSITION,
	align := Align.Undefined,
	direction := Direction.Inherit,
	z := FLOAT32_MAX,
	skin: *Skin = null
) -> Float_Input {
	p := placement(gui, size, pos, align, direction, z, skin);
	push_id(gui, id);
	input := p;
	input.aabb = draw_property_label(gui, p, label, label_color);
	result: Float_Input;
	result.value, result.changed = draw_number(
		gui,
		input,
		value,
		min_value,
		max_value,
		drag_speed,
		precision,
		"input"
	);
	pop_id(gui);
	get_widget(gui, id, p.aabb, p.z, false);
	finish(gui, p);
	return result;
}

labeled_int_input :: (
	gui: *GUI_State,
	label: string,
	size: V2f,
	value: int,
	min_value := S64_MIN,
	max_value := S64_MAX,
	drag_speed: int = 1,
	label_color := INHERIT_COLOR,
	id := "labeled_int_input",
	pos := NO_POSITION,
	align := Align.Undefined,
	direction := Direction.Inherit,
	z := FLOAT32_MAX,
	skin: *Skin = null
) -> Int_Input {
	p := placement(gui, size, pos, align, direction, z, skin);
	push_id(gui, id);
	input := p;
	input.aabb = draw_property_label(gui, p, label, label_color);
	result: Int_Input;
	result.value, result.changed = draw_number(gui, input, value, min_value, max_value, drag_speed, 0, "input");
	pop_id(gui);
	get_widget(gui, id, p.aabb, p.z, false);
	finish(gui, p);
	return result;
}

labeled_v2_input :: (
	gui: *GUI_State,
	label: string,
	size: V2f,
	value: V2f,
	min_value := V2f.{ -FLOAT32_MAX, -FLOAT32_MAX },
	max_value := V2f.{ FLOAT32_MAX, FLOAT32_MAX },
	drag_speed := 0.01,
	precision := 3,
	label_color := INHERIT_COLOR,
	id := "labeled_v2_input",
	pos := NO_POSITION,
	align := Align.Undefined,
	direction := Direction.Inherit,
	z := FLOAT32_MAX,
	skin: *Skin = null
) -> V2_Input {
	p := placement(gui, size, pos, align, direction, z, skin);
	push_id(gui, id);
	input := p;
	input.aabb = draw_property_label(gui, p, label, label_color);
	component_width := max(0.0, (input.aabb.max.x - input.aabb.min.x - 4) / 2);
	input.aabb.max.x = input.aabb.min.x + component_width;
	result: V2_Input;
	result.value.x, result.x_changed = draw_number(
		gui,
		input,
		value.x,
		min_value.x,
		max_value.x,
		drag_speed,
		precision,
		"x"
	);
	input.aabb.min.x += component_width + 4;
	input.aabb.max.x += component_width + 4;
	result.value.y, result.y_changed = draw_number(
		gui,
		input,
		value.y,
		min_value.y,
		max_value.y,
		drag_speed,
		precision,
		"y"
	);
	result.changed = result.x_changed || result.y_changed;
	pop_id(gui);
	get_widget(gui, id, p.aabb, p.z, false);
	finish(gui, p);
	return result;
}

labeled_v3_input :: (
	gui: *GUI_State,
	label: string,
	size: V2f,
	value: V3f,
	min_value := V3f.{ -FLOAT32_MAX, -FLOAT32_MAX, -FLOAT32_MAX },
	max_value := V3f.{ FLOAT32_MAX, FLOAT32_MAX, FLOAT32_MAX },
	drag_speed := 0.01,
	precision := 3,
	label_color := INHERIT_COLOR,
	id := "labeled_v3_input",
	pos := NO_POSITION,
	align := Align.Undefined,
	direction := Direction.Inherit,
	z := FLOAT32_MAX,
	skin: *Skin = null
) -> V3_Input {
	p := placement(gui, size, pos, align, direction, z, skin);
	push_id(gui, id);
	input := p;
	input.aabb = draw_property_label(gui, p, label, label_color);
	component_width := max(0.0, (input.aabb.max.x - input.aabb.min.x - 8) / 3);
	input.aabb.max.x = input.aabb.min.x + component_width;
	result: V3_Input;
	result.value.x, result.x_changed = draw_number(
		gui,
		input,
		value.x,
		min_value.x,
		max_value.x,
		drag_speed,
		precision,
		"x"
	);
	input.aabb.min.x += component_width + 4;
	input.aabb.max.x += component_width + 4;
	result.value.y, result.y_changed = draw_number(
		gui,
		input,
		value.y,
		min_value.y,
		max_value.y,
		drag_speed,
		precision,
		"y"
	);
	input.aabb.min.x += component_width + 4;
	input.aabb.max.x += component_width + 4;
	result.value.z, result.z_changed = draw_number(
		gui,
		input,
		value.z,
		min_value.z,
		max_value.z,
		drag_speed,
		precision,
		"z"
	);
	result.changed = result.x_changed || result.y_changed || result.z_changed;
	pop_id(gui);
	get_widget(gui, id, p.aabb, p.z, false);
	finish(gui, p);
	return result;
}
