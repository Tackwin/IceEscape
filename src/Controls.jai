Platform ::  #import "Platform";

State :: struct {
	just_pressed:  [Platform.Key_COUNT] bool;
	just_released: [Platform.Key_COUNT] bool;
	pressed:       [Platform.Key_COUNT] bool;
	frame_info: *Platform.Frame_Info;
}

Maskoff :: struct {
	mouse: bool;
}

update :: (state: *State, frame_info: *Platform.Frame_Info, maskoff: Maskoff) {
	state.frame_info = frame_info;
	for * state.just_pressed {
		if maskoff.mouse {
			if it_index == xx Platform.Key.MouseLeft
				continue;
			if it_index == xx Platform.Key.MouseRight
				continue;
			if it_index == xx Platform.Key.MouseMiddle
				continue;
		}
		if frame_info.key_pressed[it_index] && !state.pressed[it_index]
			it.* = true;
		else
			it.* = false;
	}
	for * state.just_released {
		if maskoff.mouse {
			if it_index == xx Platform.Key.MouseLeft
				continue;
			if it_index == xx Platform.Key.MouseRight
				continue;
			if it_index == xx Platform.Key.MouseMiddle
				continue;
		}
		if !frame_info.key_pressed[it_index] && state.pressed[it_index]
			it.* = true;
		else
			it.* = false;
	}
	for * state.pressed {
		if maskoff.mouse {
			if it_index == xx Platform.Key.MouseLeft
				continue;
			if it_index == xx Platform.Key.MouseRight
				continue;
			if it_index == xx Platform.Key.MouseMiddle
				continue;
		}
		it.* = frame_info.key_pressed[it_index];
	}
}

