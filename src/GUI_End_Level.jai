#scope_file
#import "Basic";
#import "Math";
#import "String";
#import "Algebra";
#import "Store";
Play_Session :: #import "Play_Session";
#scope_export

// The renderer only consumes a frozen result and an independent clock.
Dividend_Page :: struct { page: int; }

end_level_time :: (milliseconds: int) -> string {
	return tprint("%:%.%", milliseconds / 60000,
		formatInt((milliseconds / 1000) % 60, minimum_digits = 2, padding = #char "0"),
		formatInt(milliseconds % 1000, minimum_digits = 3, padding = #char "0"));
}

dividend_card :: (
	gui: *GUI_State, store: *Store, result: Play_Session.Result, index: int,
	clock: float64, size: V2f, caption: string, score_override: int = -1
) -> AABBf {
	player := result.players[index];
	push_id(gui, player.player_id);
	defer pop_id(gui);
	bounds := box(gui, size, inset = .{ 14, 9 }, z = 12);
	push_nine_slice(gui, bounds.min, size, lobby_button_skin(store), 11);
	label_box(gui, caption, .{ size.x - 28, 18 }, 12, GOLD_ACCENT, id = "role");
	row(gui);
	icon := box(gui, .{ 58, 52 });
	push_quad_texture(gui, icon.min + v2(3.0, 3.0), .{ 44, 44 }, v3(TEXT_NORMAL),
		model_id_to_slot(xx player.icon_id), 12);
	end(gui);
	text_width := size.x - 28 - 58;
	box(gui, .{ text_width, 52 });
	name := player.display_name;
	if name.count == 0 name = tprint("Player %", player.player_id);
	label_box(gui, name, .{ text_width, 20 }, 15, TEXT_NORMAL, id = "name");
	row(gui);
	score := score_override;
	if score < 0 score = Play_Session.displayed_score(result, index, clock);
	label_box(gui, tprint("%", score),
		.{ 96, 32 }, 25, GOLD_ACCENT, id = "score");
	label_box(gui, "points", .{ max(0.0, text_width - 96), 32 }, 12, TEXT_MUTE, id = "points");
	end(gui);
	end(gui);
	end(gui);
	end(gui);
	return bounds;
}

push_end_screen :: (
	gui: *GUI_State, result: Play_Session.Result, presentation: Play_Session.Presentation, store: *Store
) {
	push_id(gui, "end_level");
	defer pop_id(gui);
	n := result.players.count;
	winner := -1;
	for result.players if it.player_id == result.winner_id winner = it_index;
	if winner < 0 return;
	size := v2(1080.0, 612.0);
	origin := (v2(gui.controls.window_size) - size) / 2;
	push_quad_screen(gui, v2(0.0), v2(gui.controls.window_size), MENU_BASE_BACKGROUND, 9, a = 0.78);
	column(gui, origin, z = 12, align = .Top_Left);
	panel := box(gui, size, inset = .{ 24, 24 });
	push_felt_panel(gui, store, panel.min, size, 10);
	width := size.x - 48;
	label_box(gui, "LEVEL CLEARED", .{ width, 26 }, 24, GOLD_ACCENT, .Center, "title");
	label_box(gui, "RESURRECTION DIVIDENDS", .{ width, 18 }, 12, TEXT_MUTE, .Center, "subtitle");
	label_box(gui, tprint("%   |   Time %   |   Personal share weight %", result.level_name,
		end_level_time(result.duration_ms), result.personal_share_weight),
		.{ width, 20 }, 13, TEXT_NORMAL, .Center, "level");
	space(gui, 12);
	anchors := NewArray(n, AABBf,, temp);
	visible := NewArray(n, bool,, temp);
	animation, animation_widget := widget(gui, "dividend_particles", Dividend_Animation);
	row(gui);
	space(gui, (width - 360) / 2);
	anchors[winner] = dividend_card(gui, store, result, winner, presentation.clock,
		.{ 360, 96 }, "LEVEL WINNER  /  BASE AWARD + DIVIDENDS",
		dividend_counter(animation, result, winner, presentation.clock));
	visible[winner] = true;
	end(gui);
	space(gui, 36);

	page, page_widget := widget(gui, "dividend_page", Dividend_Page);
	page_count := max(1, (n - 1 + 5) / 6);
	page.page = clamp(page.page, 0, page_count - 1);
	row(gui);
	status := "Base award: 1,000  /  awaiting direct shares";
	if presentation.clock >= Play_Session.SETTLEMENT_SECONDS status = "Settlement complete";
	else if presentation.clock >= Play_Session.RECURSIVE_START status = "Round 2 of 2  /  recursive difference";
	else if presentation.clock >= Play_Session.INITIAL_HOLD_SECONDS + Play_Session.DIRECT_SECONDS status = "Direct shares settled";
	else if presentation.clock >= Play_Session.INITIAL_HOLD_SECONDS status = "Round 1 of 2  /  direct trophy shares";
	label_box(gui, status, .{ width - 180, 24 }, 14, GOLD_ACCENT, id = "status");
	if page_count > 1 {
		previous, pressed := themed_button(gui, store, "<", "previous", .{ 32, 24 }, enabled = page.page > 0);
		if previous page.page -= 1;
		label_box(gui, tprint("% / %", page.page+1, page_count), .{ 116, 24 }, 12, TEXT_MUTE, .Center, "page");
		next, next_pressed := themed_button(gui, store, ">", "next", .{ 32, 24 }, enabled = page.page+1 < page_count);
		if next page.page += 1;
	} else label_box(gui, tprint("% shareholders", n-1), .{ 180, 24 }, 12, TEXT_MUTE, .Center_Right, "count");
	end(gui);

	grid := box(gui, .{ width, 252 }, inset = .{ 16, 12 });
	push_nine_slice(gui, grid.min, grid.max-grid.min, compact_button_skin(store), 10.5);
	label_box(gui, "SHAREHOLDERS  /  SORTED BY FINAL DIVIDEND", .{ width-32, 18 }, 12, TEXT_MUTE, id = "grid_title");
	space(gui, 8);
	indices := NewArray(max(0, n-1), int,, temp);
	cursor := 0;
	for id: result.ranked_player_ids {
		if id == result.winner_id continue;
		for player: result.players if player.player_id == id {
			indices[cursor] = it_index;
			cursor += 1;
			break;
		}
	}
	card_width := (width - 32 - 24) / 3;
	for grid_row: 0..1 {
		row(gui);
		flow(gui).padding = .{ 12, 0 };
		for grid_column: 0..2 {
			rank := page.page*6 + grid_row*3 + grid_column;
			if rank >= cursor continue;
			index := indices[rank];
			player := result.players[index];
			anchors[index] = dividend_card(gui, store, result, index, presentation.clock,
				.{ card_width, 90 }, tprint("RANK %  /  % REVIVES  /  % DEATHS", rank+1, player.revive_count, player.death_count),
				dividend_counter(animation, result, index, presentation.clock));
			visible[index] = true;
		}
		end(gui);
		if grid_row == 0 space(gui, 8);
	}
	if cursor == 0 label_box(gui, "No other players this level", .{ width-32, 80 }, 16, TEXT_MUTE, .Center, "empty");
	end(gui);
	space(gui, 8);
	wr := "World record loading...";
	if result.record.status == .Missing wr = "No world record yet";
	if result.record.status == .Available wr = tprint("World record %  /  %", end_level_time(result.record.time_ms), result.record.holder);
	label_box(gui, wr, .{ width, 20 }, 13, TEXT_NORMAL, .Center, "record");
	label_box(gui, tprint("Next: %  /  % seconds", result.next_level_name,
		ceil(max(cast(float64) 0, presentation.countdown_remaining)).(int)), .{ width, 20 }, 13, TEXT_MUTE, .Center, "next_level");
	label_box(gui, "Winner: 1,000 points. Other finishers: 900. Plus revive shares.",
		.{ width, 18 }, 12, TEXT_MUTE, .Center, "explanation");
	end(gui);
	end(gui);
	dividend_update(animation, result, presentation.clock, anchors, visible);
	push_dividend_coins(gui, animation);
}

// Coin transfer animation for the end-level panel.
Dividend_Coin :: struct {
	source: int;
	destination: int;
	start, finish, control_a, control_b: V2f;
	position, velocity: V2f;
	birth, flight, value: float64;
	radius, rotation, spin, tilt, tumble: float32;
	active, arrived: bool;
}

Dividend_Animation :: struct {
	MAX_COINS :: 256;
	MAX_SLOTS :: 7; // Winner and the six cards on the current page.
	STEP :: 1.0 / 120.0;
	coins: [MAX_COINS] Dividend_Coin;
	coin_count: int;
	bounds: [MAX_SLOTS] AABBf;
	players: [MAX_SLOTS] int;
	received: [MAX_SLOTS] float64;
	slot_count: int;
	signature: float64 = -1;
	clock: float64;
	phase: int;
	contacts: int;
}

// Small bounded integer PRNG: deterministic playback, without signed overflow.
dividend_random :: (seed: *u32) -> float32 {
	seed.* = ((seed.*.(u64) * 1664525 + 1013904223) & 0xffffffff).(u32);
	return (seed.* >> 8).(float32) / 16777216;
}

dividend_port :: (bounds: AABBf, other: V2f, jitter: float32) -> V2f, V2f {
	center := (bounds.min + bounds.max) * 0.5;
	delta := other - center;
	size := bounds.max - bounds.min;
	if abs(delta.x)*size.y > abs(delta.y)*size.x {
		normal := v2(1.0, 0.0);
		if delta.x < 0 normal.x = -1;
		return center + v2(normal.x * size.x*0.5, jitter*(size.y*0.5-18)), normal;
	}
	normal := v2(0.0, 1.0);
	if delta.y < 0 normal.y = -1;
	return center + v2(jitter*(size.x*0.5-24), normal.y * size.y*0.5), normal;
}

dividend_path :: (coin: *Dividend_Coin, t: float32) -> V2f, V2f {
	u := 1-t;
	p := coin.start*(u*u*u) + coin.control_a*(3*u*u*t) + coin.control_b*(3*u*t*t) + coin.finish*(t*t*t);
	v := (coin.control_a-coin.start)*(3*u*u) + (coin.control_b-coin.control_a)*(6*u*t) + (coin.finish-coin.control_b)*(3*t*t);
	return p, v / coin.flight.(float32);
}

dividend_phase :: (clock: float64) -> int {
	if clock < Play_Session.INITIAL_HOLD_SECONDS return 0;
	if clock < Play_Session.INITIAL_HOLD_SECONDS + Play_Session.DIRECT_SECONDS return 1;
	if clock < Play_Session.RECURSIVE_START return 2;
	if clock < Play_Session.SETTLEMENT_SECONDS return 3;
	return 4;
}

dividend_launch :: (animation: *Dividend_Animation, result: Play_Session.Result, phase: int) {
	animation.coin_count = 0;
	n := result.players.count;
	seed: u32 = 73519;
	// Keep the same packet density for one source; bound it when many finishers pay shares.
	sources := 0;
	for slot: 0..animation.slot_count-1
		if Play_Session.base_reward(result, animation.players[slot]) > 0 sources += 1;
	max_packets := min(16, animation.MAX_COINS / max(1, sources * (animation.slot_count - 1)));
	for source: 0..animation.slot_count-1 for destination: 0..animation.slot_count-1 {
		if source == destination continue;
		i := animation.players[destination]; j := animation.players[source];
		amount: float64;
		if phase == 1 {
			amount = Play_Session.base_reward(result, j) * result.revives[i*n+j].(float64) / result.client.share_denominators[j];
		} else amount = result.client.secondary_transfers[i*n+j];
		if amount < 0.01 continue;
		count := clamp(ceil(amount / 45).(int), 3, max_packets);
		if phase == 3 count = clamp(ceil(amount / 32).(int), 2, 6);
		for packet: 0..count-1 {
			assert(animation.coin_count < animation.MAX_COINS);
			coin := *animation.coins[animation.coin_count];
			animation.coin_count += 1;
			coin.* = .{};
			coin.source = source; coin.destination = destination;
			coin.radius = 9 + dividend_random(*seed)*3;
			from := animation.bounds[source]; to := animation.bounds[destination];
			start, from_normal := dividend_port(from, (to.min+to.max)*0.5, (dividend_random(*seed)*2-1)*0.8);
			finish, to_normal := dividend_port(to, (from.min+from.max)*0.5, (dividend_random(*seed)*2-1)*0.8);
			coin.start = start + from_normal*(coin.radius+1);
			coin.finish = finish + to_normal*(coin.radius+1);
			coin.position = coin.start;
			distance := norm(coin.finish-coin.start);
			spread := v2((dividend_random(*seed)*2-1)*60, (dividend_random(*seed)*2-1)*40);
			coin.control_a = coin.start + from_normal*60 + spread;
			coin.control_b = coin.finish + to_normal*60 - spread;
			// Lower-card transfers lift out of the tiles rather than crossing their text.
			if phase == 3 && abs(from_normal.x) > 0.5 && abs(to_normal.x) > 0.5 {
				ceiling := min(from.min.y, to.min.y) - 65 - dividend_random(*seed)*45;
				coin.control_a.y = ceiling; coin.control_b.y = ceiling;
			}
			phase_start: float64 = Play_Session.INITIAL_HOLD_SECONDS;
			phase_length: float64 = Play_Session.DIRECT_SECONDS;
			stagger := 0.36;
			if phase == 3 {
				phase_start = Play_Session.RECURSIVE_START; phase_length = Play_Session.RECURSIVE_SECONDS;
				stagger = 0.65;
			}
			coin.birth = phase_start + 0.04 + stagger*packet.(float32)/count.(float32) + dividend_random(*seed)*0.14;
			coin.flight = 0.8 + distance*0.0008 + dividend_random(*seed)*0.3;
			if phase == 3 coin.flight += 0.3;
			coin.flight = min(coin.flight, phase_start+phase_length-coin.birth-0.12);
			coin.value = amount/count;
			coin.rotation = dividend_random(*seed)*6.2831853;
			coin.spin = (dividend_random(*seed)*2-1)*9;
			coin.tilt = dividend_random(*seed)*6.2831853;
			coin.tumble = 6 + dividend_random(*seed)*8;
			path_start, velocity := dividend_path(coin, 0);
			coin.velocity = velocity;
		}
	}
}

dividend_step :: (animation: *Dividend_Animation, result: Play_Session.Result, clock: float64) {
	phase := dividend_phase(clock);
	if phase != animation.phase {
		animation.phase = phase;
		if phase == 1 || phase == 3 dividend_launch(animation, result, phase);
		else animation.coin_count = 0;
		if phase >= 2 for slot: 0..animation.slot_count-1 {
			index := animation.players[slot];
			animation.received[slot] = result.client.direct_scores[index];
			if phase == 4 animation.received[slot] = result.players[index].dividend;
		}
	}
	dt: float32 = animation.STEP;
	for *coin: array_view(animation.coins, 0, animation.coin_count) {
		if coin.arrived || clock < coin.birth continue;
		coin.active = true;
		progress := clamp(((clock-coin.birth)/coin.flight).(float32), 0.0, 1.0);
		reference, desired_velocity := dividend_path(coin, progress);
		acceleration := (reference-coin.position)*100 + (desired_velocity-coin.velocity)*16;
		coin.velocity += acceleration*dt;
		coin.position += coin.velocity*dt;
		coin.rotation += coin.spin*dt;
		coin.tilt += coin.tumble*dt;
		if progress >= 1 || (progress > 0.85 && norm(coin.position-coin.finish) < coin.radius+8) {
			coin.arrived = true; coin.active = false;
			animation.received[coin.destination] += coin.value;
		}
	}
	// Genuine contacts: positional separation, restitution, tangential spin kicks.
	for i: 0..animation.coin_count-1 {
		a := *animation.coins[i];
		if !a.active continue;
		for j: i+1..animation.coin_count-1 {
			b := *animation.coins[j];
			if !b.active continue;
			delta := b.position-a.position;
			distance := norm(delta);
			separation := a.radius+b.radius;
			if distance >= separation continue;
			normal := v2(1.0, 0.0);
			if distance > 0.001 normal = delta/distance;
			a.position -= normal*((separation-distance)*0.5);
			b.position += normal*((separation-distance)*0.5);
			relative := b.velocity-a.velocity;
			closing := dot(relative, normal);
			if closing >= 0 continue;
			impulse := normal*(-closing*0.85);
			a.velocity -= impulse; b.velocity += impulse;
			tangent := v2(-normal.y, normal.x);
			kick := dot(relative, tangent)*0.025;
			a.spin = clamp(a.spin-kick, -18.0, 18.0);
			b.spin = clamp(b.spin+kick, -18.0, 18.0);
			a.tumble = clamp(a.tumble+kick*0.4, -18.0, 18.0);
			b.tumble = clamp(b.tumble-kick*0.4, -18.0, 18.0);
			animation.contacts += 1;
		}
	}
}

dividend_update :: (animation: *Dividend_Animation, result: Play_Session.Result, clock: float64, bounds: [] AABBf, visible: [] bool) {
	// Changing page or rewinding the presentation replays the fixed-step simulation.
	// No dependence on frame rate, networking, wall time, or live scene state.
	signature := result.duration_ms.(float64) + result.winner_id*19 + result.level_id*31 + result.personal_share_weight*37;
	for result.players signature += (it_index+1)*(it.dividend + it.player_id*13);
	slots := 0;
	reset := signature != animation.signature || clock < animation.clock;
	for visible if it {
		if slots >= animation.MAX_SLOTS break;
		if animation.players[slots] != it_index ||
			animation.bounds[slots].min.x != bounds[it_index].min.x || animation.bounds[slots].min.y != bounds[it_index].min.y ||
			animation.bounds[slots].max.x != bounds[it_index].max.x || animation.bounds[slots].max.y != bounds[it_index].max.y reset = true;
		slots += 1;
	}
	if slots != animation.slot_count reset = true;
	if reset {
		animation.* = .{};
		animation.signature = signature;
		for visible if it && animation.slot_count < animation.MAX_SLOTS {
			slot := animation.slot_count; animation.slot_count += 1;
			animation.players[slot] = it_index; animation.bounds[slot] = bounds[it_index];
			animation.received[slot] = Play_Session.base_reward(result, it_index);
		}
	}
	target := clamp(clock, cast(float64) 0, cast(float64) Play_Session.SETTLEMENT_SECONDS);
	while animation.clock + animation.STEP <= target {
		animation.clock += animation.STEP;
		dividend_step(animation, result, animation.clock);
	}
	if target >= Play_Session.SETTLEMENT_SECONDS && animation.phase != 4 dividend_step(animation, result, target);
}

dividend_counter :: (animation: *Dividend_Animation, result: Play_Session.Result, index: int, clock: float64) -> int {
	if clock >= Play_Session.SETTLEMENT_SECONDS return result.players[index].score;
	if clock < Play_Session.INITIAL_HOLD_SECONDS || clock < animation.clock {
		return Play_Session.base_reward(result, index).(int);
	}
	for slot: 0..animation.slot_count-1 if animation.players[slot] == index {
		return min(result.players[index].score, max(0, floor(animation.received[slot]).(int)));
	}
	return Play_Session.displayed_score(result, index, clock);
}

push_dividend_coins :: (gui: *GUI_State, animation: *Dividend_Animation) {
	for coin: array_view(animation.coins, 0, animation.coin_count) {
		if !coin.active continue;
		face := cos(coin.tilt);
		width := coin.radius*2*max(0.16, abs(face));
		quad: GUI_State.Quad;
		quad.texture_rect = .{ 0, 0, 1, 1 };
		quad.flags = GUI_State.Quad.FLAG_COIN | GUI_State.Quad.FLAG_COIN_SHADOW;
		quad.size = .{ coin.radius*2.2, coin.radius*0.55 };
		quad.pos = coin.position - quad.size*0.5 + v2(3.0, coin.radius+4);
		quad.color = .{ MENU_BASE_BACKGROUND.x, MENU_BASE_BACKGROUND.y, MENU_BASE_BACKGROUND.z, 0.45 };
		quad.z = 11.8;
		push_quad(gui, quad);
		quad.flags = GUI_State.Quad.FLAG_COIN;
		quad.size = .{ width, coin.radius*2 };
		quad.pos = coin.position-quad.size*0.5;
		quad.rotation = coin.rotation;
		quad.coin_face = face*0.5+0.5;
		quad.color = GOLD_ACCENT;
		// Above the panel/card artwork, below its text: no unreadable status labels.
		quad.z = 11.9;
		push_quad(gui, quad);
	}
}
