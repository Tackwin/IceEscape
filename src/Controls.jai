Platform ::  #import "Platform";
#import "Algebra";
#import "Basic";

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
}
