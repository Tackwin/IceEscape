#scope_export


Window_Query :: struct {
	Kind :: enum u32 {
		Create  :: 0;
		Destroy :: 1;
		Update  :: 2;
		Context :: 3;
	};

	kind: Kind;

	id := 0;
	title: string;

	width := 0;
	height := 0;

	ask_quit := false;
};

Opengl_Query :: struct {
	Kind :: enum u32 {
		Create_Buffer :: 0;

	}
};