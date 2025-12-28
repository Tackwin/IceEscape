Platform ::  #import "Platform";
#import "Algebra";
#import "Basic";
#import "GUI";

State :: struct {
	just_pressed:  [Platform.Key_COUNT] bool;
	just_released: [Platform.Key_COUNT] bool;
	pressed:       [Platform.Key_COUNT] bool;

	mouse_pos: V2f;
	mouse_wheel: s64;
	window_size:   V2f;

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
