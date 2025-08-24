#scope_file
Render :: #import "Render";
Platform :: #import "Platform";
#import "Basic";
#import "Math";
#import "Algebra";

Z_SLOT :: V2f.{ 0, 0 };
Q_SLOT :: V2f.{ 1, 0 };
C_SLOT :: V2f.{ 2, 0 };
UP_SLOT :: V2f.{ 3, 0 };
S_SLOT :: V2f.{ 0, 1 };
D_SLOT :: V2f.{ 1, 1 };
A_SLOT :: V2f.{ 2, 1 };
RIGHT_SLOT :: V2f.{ 3, 1 };
SPACE_SLOT :: V2f.{ 0, 2 };
W_SLOT :: V2f.{ 1, 2 };
DOWN_SLOT :: V2f.{ 2, 2 };
LEFT_SLOT :: V2f.{ 3, 2 };
W_OUTLINE_SLOT :: V2f.{ 0, 3 };
A_OUTLINE_SLOT :: V2f.{ 1, 3 };
Q_OUTLINE_SLOT :: V2f.{ 2, 3 };
S_OUTLINE_SLOT :: V2f.{ 3, 3 };
D_OUTLINE_SLOT :: V2f.{ 4, 0 };
Z_OUTLINE_SLOT :: V2f.{ 4, 1 };
C_OUTLINE_SLOT :: V2f.{ 4, 2 };
COIN_SLOT :: V2f.{ 4, 3 };
VOLUME_ON_SLOT :: V2f.{ 0, 4 };
VOLUME_OFF_SLOT :: V2f.{ 1, 4 };


#scope_export

render_fps_histogram :: (pos: V2f, size: V2f, data: [] float32, current_idx: int) {
	avg := 0.0;
	for data
		avg += it;
	avg /= data.count;

	fps_text := tprint("FPS: %, Avg %", (1.0 / data[current_idx]).(s64), (1.0 / avg).(s64));
	Render.push_text(fps_text, .{ pos.x + 4, pos.y + size.y - 20 }, 16, z=-0.3);

	Render.push_quad_screen(
		pos = pos,
		size = size,
		color = .{ 0.0, 0.0, 0.0 },
		z = 0.0
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
		Render.push_quad_screen(
			pos = .{ pos.x + x, pos.y + 5 },
			size = .{ w, h },
			color = color,
			z = -0.1
		);
	}

	{
		h := project(120);
		Render.push_quad_screen(
			pos = .{ pos.x, pos.y + 5 + h },
			size = .{ size.x, 1 },
			color = .{ 0.0, 0.0, 1.0 },
			z = -0.2
		);
	}
	{
		h := project(60);
		Render.push_quad_screen(
			pos = .{ pos.x, pos.y + 5 + h },
			size = .{ size.x, 1 },
			color = .{ 0.0, 1.0, 0.0 },
			z = -0.2
		);
	}
	{
		h := project(30);
		Render.push_quad_screen(
			pos = .{ pos.x, pos.y + 5 + h },
			size = .{ size.x, 1 },
			color = .{ 1.0, 0.0, 0.0 },
			z = -0.2
		);
	}
}

render_ping_histogram :: (pos: V2f, size: V2f, data: [] float32, current_idx: int) {
	avg := 0.0;
	for data
		avg += it;
	avg /= data.count;

	fps_text := tprint("Ping: %, Avg % (ms)", (1000 * data[current_idx]).(s64), (1000 * avg).(s64));
	Render.push_text(fps_text, .{ pos.x + 4, pos.y + size.y - 20 }, 16, z=-0.3);

	Render.push_quad_screen(
		pos = pos,
		size = size,
		color = .{ 0.0, 0.0, 0.0 },
		z = 0.0
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
		Render.push_quad_screen(
			pos = .{ pos.x + x, pos.y + 5 },
			size = .{ w, h },
			color = color,
			z = -0.1
		);
	}

	{
		h := project(20);
		Render.push_quad_screen(
			pos = .{ pos.x, pos.y + 5 + h },
			size = .{ size.x, 1 },
			color = .{ 0.0, 0.0, 1.0 },
			z = -0.2
		);
	}
	{
		h := project(80);
		Render.push_quad_screen(
			pos = .{ pos.x, pos.y + 5 + h },
			size = .{ size.x, 1 },
			color = .{ 0.0, 1.0, 0.0 },
			z = -0.2
		);
	}
	{
		h := project(200);
		Render.push_quad_screen(
			pos = .{ pos.x, pos.y + 5 + h },
			size = .{ size.x, 1 },
			color = .{ 1.0, 0.0, 0.0 },
			z = -0.2
		);
	}
}

render_action_palette :: (info: *Platform.Frame_Info) {
	Render.push_quad_screen(
		pos = .{ 0, 0 },
		size = .{ 128, 128 },
		color = .{ 218/255.0, 220/255.0, 231/255.0 },
		-0.5
	);


	render_square_at :: (x: int, y: int, key_code: int) #expand {
		color := V3f.{ 25/255.0, 159/255.0, 215/255.0 };
		if info.key_pressed[xx key_code]
			color = .{ 54/255.0, 189/255.0, 247/255.0 };
		Render.push_quad_screen(
			pos = .{ x * 32.0 + 1, y * 32.0 + 1 },
			size = .{ 30, 30 },
			color = color,
			z = -0.6
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
		Render.push_quad_texture(
			pos = .{ (x * 32 + 4).(float32), (y * 32 + 4).(float32) },
			size = .{ 24, 24 },
			tex_slot = tex_slot,
			color = color,
			z = -0.7
		);
	}
	render_hint_at :: (x: int, y: int, tex_slot: V2f) {
		Render.push_quad_texture(
			pos = .{ (x * 32 + 18).(float32), (y * 32 + 18).(float32) },
			size = .{ 14, 14 },
			tex_slot = tex_slot,
			color = .{ 1.0, 1.0, 1.0 },
			z = -0.8
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

render_settings :: (volume: *bool, info: *Platform.Frame_Info) {
	if volume.* {
		if Render.push_button(
			.{ info.window_size.x - 16, info.window_size.y - 16 },
			16,
			VOLUME_ON_SLOT,
			-0.5
		)
			volume.* = false;
	} else {
		if Render.push_button(
			.{ info.window_size.x - 16, info.window_size.y - 16 },
			16,
			VOLUME_OFF_SLOT,
			-0.5
		)
			volume.* = true;
	}
}
