Platform ::  #import "Platform";
#import "Algebra";
#import "Basic";

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

State :: struct {
	using keys: Platform.Keys;
	text_input: string;
	text_input_active := false;
	text_input_consumed := false;

	mouse_pos: V2f;
	mouse_wheel: s64;
	window_size:   V2f;

	is_mobile := false;
	touch_down := false;
	touch_just_pressed := false;
	joystick_active := false;
	joystick_released := false;
	joystick: V2f;
	captured_keyboard := false;
	captured_mouse := false;

	delta_time := 0.0;
	time: Apollo_Time;

	layout: Platform.Layout;
}

is_action_pressed :: (controls: *State, key: Action_Key) -> bool {
	return controls.pressed[action_to_platform(key, controls.layout)];
}

is_action_just_pressed :: (controls: *State, key: Action_Key) -> bool {
	return controls.just_pressed[action_to_platform(key, controls.layout)];
}


begin_frame :: (previous: *State, out_controls: *State, info: Platform.Frame_Info, layout_override: Platform.Layout = .AZERTY) {
	out_controls.* = previous.*;
	out_controls.text_input = "";

	previous.text_input = info.text_input;
	previous.text_input_active = false;
	previous.text_input_consumed = false;
	previous.keys = Platform.advance_keys(previous.keys, info.keys.pressed, info.keys.just_released);
	for i: 0..Platform.Key_COUNT - 1 {
		previous.keys.just_pressed[i] |= info.keys.just_pressed[i];
	}
	previous.mouse_pos = info.mouse_position;
	previous.mouse_wheel = info.mouse_wheel;
	previous.window_size = info.window_size;
	previous.captured_keyboard = false;
	previous.captured_mouse = false;
	previous.is_mobile = info.is_mobile;
	previous.touch_just_pressed = info.touch_down && !previous.touch_down;
	previous.touch_down = info.touch_down;
	previous.delta_time = info.delta_time;
	previous.time = info.time;
	previous.layout = ifx info.layout == .Unknown then layout_override else info.layout;
}
