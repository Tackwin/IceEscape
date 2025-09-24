#scope_file
Platform :: #import "Platform";
#import "Basic";
#import "Math";
#import "Algebra";
#import "Assets";

Z_SLOT :: V2f.{ 0, 15 };
Q_SLOT :: V2f.{ 1, 15 };
C_SLOT :: V2f.{ 2, 15 };
UP_SLOT :: V2f.{ 3, 15 };
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
COIN_SLOT :: V2f.{ 4, 12 };
VOLUME_ON_SLOT :: V2f.{ 0, 11 };
VOLUME_OFF_SLOT :: V2f.{ 1, 11 };

Key :: Platform.Key;

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

	frame_info: Platform.Frame_Info;
	just_pressed: [Platform.Key_COUNT] bool;
	just_released: [Platform.Key_COUNT] bool;
	pressed: [Platform.Key_COUNT] bool;

	mouse_pos: V2f;
}

IM: IM_t;
im_init :: () {
	IM = .{};
}

handle_frame_info :: (info: Platform.Frame_Info) {
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

	if IM.just_pressed[Key.MouseLeft] && point_aabb(IM.mouse_pos, low, high) {
		return true;
	}
	return false;
}

push_button :: (center: V2f, size: float, tex_slot: V2f, z := 0.0) -> bool {
	push_quad_texture(
		center - V2f.{ size / 2, size / 2 }, V2f.{ size, size }, .{ 1, 1, 1 }, tex_slot
	);

	low := center - V2f.{ size / 2, size / 2 };
	high := center + V2f.{ size / 2, size / 2 };

	if IM.just_pressed[Key.MouseLeft] && point_aabb(IM.mouse_pos, low, high) {
		return true;
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
		char := IM.chars[it];
		if (align & Text_Align.HCenter) == Text_Align.HCenter {
			char.pos.x -= (x - pos.x) / 2;
		}
		if (align & Text_Align.Right) == Text_Align.Right {
			char.pos.x -= (x - pos.x);
		}
		if (align & Text_Align.VCenter) == Text_Align.VCenter {
			char.pos.y -= max_height/ 2;
		}
		if (align & Text_Align.Top) == Text_Align.Bottom {
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

push_action_palette :: (info: *Platform.Frame_Info) {

	push_quad_screen(
		pos = .{ 0, 0 },
		size = .{ 128, 128 },
		color = .{ 218/255.0, 220/255.0, 231/255.0 },
		1
	);


	render_square_at :: (x: int, y: int, key_code: int) #expand {
		color := V3f.{ 25/255.0, 159/255.0, 215/255.0 };
		if info.key_pressed[xx key_code]
			color = .{ 54/255.0, 189/255.0, 247/255.0 };
		push_quad_screen(
			pos = .{ x * 32.0 + 1, y * 32.0 + 1 },
			size = .{ 30, 30 },
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
			pos = .{ (x * 32 + 4).(float32), (y * 32 + 4).(float32) },
			size = .{ 24, 24 },
			tex_slot = tex_slot,
			color = color,
			z = 3
		);
	}
	render_hint_at :: (x: int, y: int, tex_slot: V2f) {
		push_quad_texture(
			pos = .{ (x * 32 + 18).(float32), (y * 32 + 18).(float32) },
			size = .{ 14, 14 },
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
