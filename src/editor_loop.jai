Editor_Page :: struct {
	scene: Scene.Scene;
}

enter_editor :: (state: *State, scene: *Scene.Scene) {
	state.screen_state = .Editor;
}

process_editor :: (state: *State, command: Command) -> bool {

}

editor_loop :: (app_user: *App_User) -> bool {
	return false;
}