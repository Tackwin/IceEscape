Platform ::  #import "Platform";

Maskoff :: struct {
	mouse: bool = false;
}
State :: struct {
	just_pressed:  [Platform.Key_COUNT] bool;
	just_released: [Platform.Key_COUNT] bool;
	pressed:       [Platform.Key_COUNT] bool;
	frame_info: *Platform.Frame_Info;
	maskoff: Maskoff;
}

update :: (state: *State, frame_info: *Platform.Frame_Info) {
	state.frame_info = frame_info;
	for * state.just_pressed {
		if frame_info.key_pressed[it_index] && !state.pressed[it_index]
			it.* = true;
		else
			it.* = false;
	}
	for * state.just_released {
		if !frame_info.key_pressed[it_index] && state.pressed[it_index]
			it.* = true;
		else
			it.* = false;
	}
	for * state.pressed {
		it.* = frame_info.key_pressed[it_index];
	}
}

