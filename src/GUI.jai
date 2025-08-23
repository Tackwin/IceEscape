Render :: #import "Render";
Platform :: #import "Platform";
#import "Basic";
#import "Math";
#import "Algebra";

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

	for y: 0..3 {
		for x: 0..3 {
			Render.push_quad_screen(
				pos = .{ x * 32.0 + 1, y * 32.0 + 1 },
				size = .{ 30, 30 },
				color = .{ 25/255.0, 159/255.0, 215/255.0 },
				z = -0.6
			);
		}
	}
}