#import "Basic";
#import "String";
#import "Algebra";
#import "Assets";
#import "Platform";
#import "Hash_Table";
Store :: #import "Store";
STB :: #import "stb_image";

#scope_export

IM: struct {
	display_size: V2f;

	Quad :: struct {
		pos: V2f;
		size: V2f;
		color: V4f;
		z: float = 0.0;
	}

	Char :: struct {
		id: int;
		pos: V2f;
		color: V3f;
		z: float;
		height: float;
	}

	Spatial_Quad :: struct {
		center: V3f;
		size: V3f;
	}

	Quad_Texture :: struct {
		pos: V2f;
		size: V2f;
		color: V4f;
		tex_slot: V2f;
		z: float = 0.0;
	}


	quad_object: GLuint = 0;
	quad_buffer: GLuint = 0;

	char_object: GLuint = 0;
	char_buffer: GLuint = 0;

	quads: [..] Quad;
	quads_late: [..] Quad;
	quads_texture: [..] Quad_Texture;
	quad_shader: Shader;

	chars: [..] Char;
	char_shader: Shader;
	char_texture: Texture;

	Checkbox :: struct {
		pos: V2f;
		size: V2f;
		checked: bool;
	}

	frame_info: Frame_Info;
	just_pressed: [Key_COUNT] bool;
	just_released: [Key_COUNT] bool;
	pressed: [Key_COUNT] bool;

	mouse_pos: V2f;
	store: *Store.Store;
}

im_init :: (store: *Store.Store) {
	IM = .{};
	IM.store = store;
}

handle_frame_info :: (info: Frame_Info) {
	for * IM.just_pressed {
		if info.key_pressed[it_index] && !IM.pressed[it_index]
			it.* = true;
		else
			it.* = false;
	}
	for * IM.just_released {
		if !info.key_pressed[it_index] && IM.pressed[it_index]
			it.* = true;
		else
			it.* = false;
	}
	for * IM.pressed {
		it.* = info.key_pressed[it_index];
	}
	IM.mouse_pos.x = info.mouse_position.x;
	IM.mouse_pos.y = info.mouse_position.y;
}

push_checkbox :: (
	center: V2f, size: float, checked: bool
) -> bool {
	push_quad_screen(center - V2f.{ size / 2, size / 2 }, V2f.{ size, size }, .{ 0, 0, 0 }, 0.0);
	color := V3f.{ 0.1, 0.1, 0.1 };
	if checked {
		color = .{ 0, 1, 0 };
	}
	push_quad_screen(
		center - V2f.{ size / 2 - 2, size / 2 - 2 }, V2f.{ size - 4, size - 4 }, color, -0.1
	);

	low := center - V2f.{ size / 2 - 1, size / 2 - 1 };
	high := center + V2f.{ size / 2 - 1, size / 2 - 1 };

	if IM.just_pressed[Key.MouseLeft] && point_aabb(IM.mouse_pos, low, high) {
		return true;
	}
	return false;
}

push_button :: (center: V2f, size: float, tex_slot: V2f, z := 0.0) -> bool {
	push_quad_texture(
		center - V2f.{ size / 2, size / 2 }, V2f.{ size, size }, .{ 1, 1, 1 }, tex_slot
	);

	low := center - V2f.{ size / 2, size / 2 };
	high := center + V2f.{ size / 2, size / 2 };

	if IM.just_pressed[Key.MouseLeft] && point_aabb(IM.mouse_pos, low, high) {
		return true;
	}
	return false;
}

push_quad :: (quad: IM.Quad) {
	array_add(*IM.quads, quad);
}
push_quad_screen :: (pos: V2f, size: V2f, color: V3f, z := 0.0) {
	quad: IM.Quad;
	// IM.display_size
	quad.pos.x = pos.x / IM.display_size.x * 2 - 1.0;
	quad.pos.y = pos.y / IM.display_size.y * 2 - 1.0;
	quad.size.x = size.x / IM.display_size.x * 2;
	quad.size.y = size.y / IM.display_size.y * 2;
	quad.color = .{ color.x, color.y, color.z, 1.0 };
	quad.z = z;

	array_add(*IM.quads, quad);
}
push_quad_texture :: (pos: V2f, size: V2f, color: V3f, tex_slot: V2f, z := 0.0) {
	quad: IM.Quad_Texture;
	// IM.display_size
	quad.pos.x = pos.x / IM.display_size.x * 2 - 1.0;
	quad.pos.y = pos.y / IM.display_size.y * 2 - 1.0;
	quad.size.x = size.x / IM.display_size.x * 2;
	quad.size.y = size.y / IM.display_size.y * 2;
	quad.color = .{ color.x, color.y, color.z, 1.0 };
	quad.tex_slot = tex_slot;
	quad.z = z;

	array_add(*IM.quads_texture, quad);
}

push_late_quad_screen :: (pos: V2f, size: V2f, color: V4f, z := 0.0) {
	quad: IM.Quad;
	// IM.display_size
	quad.pos.x = pos.x / IM.display_size.x * 2 - 1.0;
	quad.pos.y = pos.y / IM.display_size.y * 2 - 1.0;
	quad.size.x = size.x / IM.display_size.x * 2;
	quad.size.y = size.y / IM.display_size.y * 2;
	quad.color = color;
	quad.z = z;

	array_add(*IM.quads_late, quad);
}

push_text :: (text: string, pos: V2f, height := 12.0, z := 0.0) {
	x := pos.x;

	for text {
		char: IM.Char;
		char.id = it - 0x20;
		char.pos.x = x;
		char.pos.y = pos.y;
		char.z = z;
		char.color = .{ 1, 1, 1 };
		char.height = height;

		x += MAIN_FONT.sprites[char.id].charAdvanceX * height / MAIN_FONT.height;

		array_add(*IM.chars, char);
	}
}

render_im_quad :: () {
	if !ok(IM.quad_shader) {
		IM.quad_shader = Shader.make(QUAD_VERTEX, QUAD_FRAGMENT);
	}
	context.rhi.glUseProgram(IM.quad_shader.program);

	if !IM.quad_object {
		context.rhi.glGenVertexArrays(1, *IM.quad_object);
	}
	context.rhi.glBindVertexArray(IM.quad_object);
	
	if !IM.quad_buffer {
		context.rhi.glGenBuffers(1, *IM.quad_buffer);
	}


	Quad_Vertex :: struct {
		pos: V3f;
		color: V4f;
	}

	vertices := NewArray(
		IM.quads.count * 6, Quad_Vertex, false,, temp
	);

	for IM.quads {
		vertices[it_index * 6 + 0].pos = .{ it.pos.x, it.pos.y, it.z };
		vertices[it_index * 6 + 0].color = it.color;

		vertices[it_index * 6 + 1].pos = .{ it.pos.x + it.size.x, it.pos.y, it.z };
		vertices[it_index * 6 + 1].color = it.color;

		vertices[it_index * 6 + 2].pos = .{ it.pos.x + it.size.x, it.pos.y + it.size.y, it.z };
		vertices[it_index * 6 + 2].color = it.color;

		vertices[it_index * 6 + 3].pos = .{ it.pos.x, it.pos.y, it.z };
		vertices[it_index * 6 + 3].color = it.color;

		vertices[it_index * 6 + 4].pos = .{ it.pos.x + it.size.x, it.pos.y + it.size.y, it.z };
		vertices[it_index * 6 + 4].color = it.color;

		vertices[it_index * 6 + 5].pos = .{ it.pos.x, it.pos.y + it.size.y, it.z };
		vertices[it_index * 6 + 5].color = it.color;
	}

	context.rhi.glBindBuffer(GL_ARRAY_BUFFER, IM.quad_buffer);
	context.rhi.glBufferData(
		GL_ARRAY_BUFFER,
		vertices.count * size_of(Quad_Vertex),
		vertices.data,
		GL_DYNAMIC_DRAW
	);

	context.rhi.glEnableVertexAttribArray(0); // Position
	context.rhi.glVertexAttribPointer(
		0, 3, GL_FLOAT, GL_FALSE, size_of(Quad_Vertex), xx offset_of(Quad_Vertex, "pos")
	);

	context.rhi.glEnableVertexAttribArray(1); // Color
	context.rhi.glVertexAttribPointer(
		1, 4, GL_FLOAT, GL_FALSE, size_of(Quad_Vertex), xx offset_of(Quad_Vertex, "color")
	);

	context.rhi.glDrawArrays(GL_TRIANGLES, 0, xx vertices.count);

	IM.quads.count = 0;

	vertices = NewArray(IM.quads_late.count * 6, Quad_Vertex, false,, temp);
	for IM.quads_late {
		vertices[it_index * 6 + 0].pos = .{ it.pos.x, it.pos.y, it.z };
		vertices[it_index * 6 + 0].color = it.color;

		vertices[it_index * 6 + 1].pos = .{ it.pos.x + it.size.x, it.pos.y, it.z };
		vertices[it_index * 6 + 1].color = it.color;

		vertices[it_index * 6 + 2].pos = .{ it.pos.x + it.size.x, it.pos.y + it.size.y, it.z };
		vertices[it_index * 6 + 2].color = it.color;

		vertices[it_index * 6 + 3].pos = .{ it.pos.x, it.pos.y, it.z };
		vertices[it_index * 6 + 3].color = it.color;

		vertices[it_index * 6 + 4].pos = .{ it.pos.x + it.size.x, it.pos.y + it.size.y, it.z };
		vertices[it_index * 6 + 4].color = it.color;

		vertices[it_index * 6 + 5].pos = .{ it.pos.x, it.pos.y + it.size.y, it.z };
		vertices[it_index * 6 + 5].color = it.color;
	}

	context.rhi.glBindBuffer(GL_ARRAY_BUFFER, IM.quad_buffer);
	context.rhi.glBufferData(
		GL_ARRAY_BUFFER,
		vertices.count * size_of(Quad_Vertex),
		vertices.data,
		GL_DYNAMIC_DRAW
	);

	context.rhi.glEnableVertexAttribArray(0); // Position
	context.rhi.glVertexAttribPointer(
		0, 3, GL_FLOAT, GL_FALSE, size_of(Quad_Vertex), xx offset_of(Quad_Vertex, "pos")
	);

	context.rhi.glEnableVertexAttribArray(1); // Color
	context.rhi.glVertexAttribPointer(
		1, 4, GL_FLOAT, GL_FALSE, size_of(Quad_Vertex), xx offset_of(Quad_Vertex, "color")
	);

	context.rhi.glDepthMask(GL_FALSE);
	context.rhi.glDrawArrays(GL_TRIANGLES, 0, xx vertices.count);
	context.rhi.glDepthMask(GL_TRUE);

	IM.quads_late.count = 0;
}

render_im_quad_texture :: () {
	context.rhi.glUseProgram(IM.store.quad_texture_shader.program);

	if !IM.quad_object {
		context.rhi.glGenVertexArrays(1, *IM.quad_object);
	}
	context.rhi.glBindVertexArray(IM.quad_object);
	
	if !IM.quad_buffer {
		context.rhi.glGenBuffers(1, *IM.quad_buffer);
	}

	Quad_Vertex :: struct {
		pos: V3f;
		color: V4f;
		tex: V2f;
	}

	vertices := NewArray(
		IM.quads_texture.count * 6, Quad_Vertex, false,, temp
	);

	for IM.quads_texture {
		vertices[it_index * 6 + 0].pos = .{ it.pos.x, it.pos.y, it.z };
		vertices[it_index * 6 + 0].color = it.color;
		vertices[it_index * 6 + 0].tex = .{ it.tex_slot.x * 64, it.tex_slot.y * 64 + 64 };

		vertices[it_index * 6 + 1].pos = .{ it.pos.x + it.size.x, it.pos.y, it.z };
		vertices[it_index * 6 + 1].color = it.color;
		vertices[it_index * 6 + 1].tex = .{ it.tex_slot.x * 64 + 64, it.tex_slot.y * 64 + 64 };

		vertices[it_index * 6 + 2].pos = .{ it.pos.x + it.size.x, it.pos.y + it.size.y, it.z };
		vertices[it_index * 6 + 2].color = it.color;
		vertices[it_index * 6 + 2].tex = .{ it.tex_slot.x * 64 + 64, it.tex_slot.y * 64 };

		vertices[it_index * 6 + 3].pos = .{ it.pos.x, it.pos.y, it.z };
		vertices[it_index * 6 + 3].color = it.color;
		vertices[it_index * 6 + 3].tex = .{ it.tex_slot.x * 64, it.tex_slot.y * 64 + 64 };

		vertices[it_index * 6 + 4].pos = .{ it.pos.x + it.size.x, it.pos.y + it.size.y, it.z };
		vertices[it_index * 6 + 4].color = it.color;
		vertices[it_index * 6 + 4].tex = .{ it.tex_slot.x * 64 + 64, it.tex_slot.y * 64 };

		vertices[it_index * 6 + 5].pos = .{ it.pos.x, it.pos.y + it.size.y, it.z };
		vertices[it_index * 6 + 5].color = it.color;
		vertices[it_index * 6 + 5].tex = .{ it.tex_slot.x * 64, it.tex_slot.y * 64 };
	}

	context.rhi.glBindBuffer(GL_ARRAY_BUFFER, IM.quad_buffer);
	context.rhi.glBufferData(
		GL_ARRAY_BUFFER,
		vertices.count * size_of(Quad_Vertex),
		vertices.data,
		GL_DYNAMIC_DRAW
	);

	context.rhi.glEnableVertexAttribArray(0); // Position
	context.rhi.glVertexAttribPointer(
		0, 3, GL_FLOAT, GL_FALSE, size_of(Quad_Vertex), xx offset_of(Quad_Vertex, "pos")
	);

	context.rhi.glEnableVertexAttribArray(1); // Color
	context.rhi.glVertexAttribPointer(
		1, 4, GL_FLOAT, GL_FALSE, size_of(Quad_Vertex), xx offset_of(Quad_Vertex, "color")
	);

	context.rhi.glEnableVertexAttribArray(2); // TexCoord
	context.rhi.glVertexAttribPointer(
		2, 2, GL_FLOAT, GL_FALSE, size_of(Quad_Vertex), xx offset_of(Quad_Vertex, "tex")
	);

	set_uniform(*IM.store.quad_texture_shader, "tex_size", V2f.{
		IM.store.ui_atlas_png.width.(float),
		IM.store.ui_atlas_png.height.(float)
	});
	set_uniform(*IM.store.quad_texture_shader, "tex", IM.store.ui_atlas, 0);

	context.rhi.glDrawArrays(GL_TRIANGLES, 0, xx vertices.count);

	IM.quads_texture.count = 0;
}

render_im_char :: () {
	if IM.chars.count == 0
		return;

	if !ok(IM.char_shader) {
		IM.char_shader = Shader.make(FONT_VERTEX, FONT_FRAGMENT);
	}
	if !ok(IM.char_texture) {
		IM.char_texture = Texture.make_from_image(MAIN_FONT.atlas);
	}
	context.rhi.glUseProgram(IM.char_shader.program);
	set_uniform(*IM.char_shader, "font_sampler", IM.char_texture, 0);

	if !IM.char_object {
		context.rhi.glGenVertexArrays(1, *IM.char_object);
	}
	context.rhi.glBindVertexArray(IM.char_object);
	
	if !IM.char_buffer {
		context.rhi.glGenBuffers(1, *IM.char_buffer);
	}


	Char_Vertex :: struct {
		pos: V3f;
		color: V3f;
		tex: V2f;
	}

	vertices := NewArray(
		IM.chars.count * 6, Char_Vertex, false,, temp
	);
	for IM.chars {
		sprite := MAIN_FONT.sprites[it.id];
		x := it.pos.x / IM.display_size.x * 2 - 1.0;
		y := it.pos.y / IM.display_size.y * 2 - 1.0;
		width := sprite.sourceWidth * it.height / MAIN_FONT.height;
		width = width / IM.display_size.x * 2;
		height := sprite.sourceHeight * it.height / MAIN_FONT.height;
		height = height / IM.display_size.y * 2;
		pos := V2f.{ xx (sprite.positionX - sprite.padding), xx (sprite.positionY - sprite.padding) };
		size := V2f.{ xx sprite.sourceWidth, xx sprite.sourceHeight };
		pos.x /= MAIN_FONT.atlas.width;
		pos.y /= MAIN_FONT.atlas.height;
		size.x /= MAIN_FONT.atlas.width;
		size.y /= MAIN_FONT.atlas.height;
		pos.y = pos.y + size.y;
		size.y = -size.y;

		vertices[it_index * 6 + 0].pos = .{ x, y, it.z };
		vertices[it_index * 6 + 0].color = it.color;
		vertices[it_index * 6 + 0].tex = .{ pos.x + 0 * size.x, pos.y + 0 * size.y };

		vertices[it_index * 6 + 1].pos = .{ x + width, y, it.z };
		vertices[it_index * 6 + 1].color = it.color;
		vertices[it_index * 6 + 1].tex = .{ pos.x + 1 * size.x, pos.y + 0 * size.y };

		vertices[it_index * 6 + 2].pos = .{ x + width, y + height, it.z };
		vertices[it_index * 6 + 2].color = it.color;
		vertices[it_index * 6 + 2].tex = .{ pos.x + 1 * size.x, pos.y + 1 * size.y };

		vertices[it_index * 6 + 3].pos = .{ x, y, it.z };
		vertices[it_index * 6 + 3].color = it.color;
		vertices[it_index * 6 + 3].tex = .{ pos.x + 0 * size.x, pos.y + 0 * size.y };

		vertices[it_index * 6 + 4].pos = .{ x + width, y + height, it.z };
		vertices[it_index * 6 + 4].color = it.color;
		vertices[it_index * 6 + 4].tex = .{ pos.x + 1 * size.x, pos.y + 1 * size.y };

		vertices[it_index * 6 + 5].pos = .{ x, y + height, it.z };
		vertices[it_index * 6 + 5].color = it.color;
		vertices[it_index * 6 + 5].tex = .{ pos.x + 0 * size.x, pos.y + 1 * size.y };
	}

	context.rhi.glBindBuffer(GL_ARRAY_BUFFER, IM.char_buffer);
	context.rhi.glBufferData(
		GL_ARRAY_BUFFER,
		vertices.count * size_of(Char_Vertex),
		vertices.data,
		GL_DYNAMIC_DRAW
	);

	context.rhi.glEnableVertexAttribArray(0); // Position
	context.rhi.glVertexAttribPointer(
		0, 3, GL_FLOAT, GL_FALSE,
		size_of(Char_Vertex), xx offset_of(Char_Vertex, "pos")
	);

	context.rhi.glEnableVertexAttribArray(1); // Color
	context.rhi.glVertexAttribPointer(
		1, 3, GL_FLOAT, GL_FALSE,
		size_of(Char_Vertex), xx offset_of(Char_Vertex, "color")
	);

	context.rhi.glEnableVertexAttribArray(2); // Color
	context.rhi.glVertexAttribPointer(
		2, 2, GL_FLOAT, GL_FALSE,
		size_of(Char_Vertex), xx offset_of(Char_Vertex, "tex")
	);

	context.rhi.glDrawArrays(GL_TRIANGLES, 0, xx vertices.count);

	IM.chars.count = 0;
}

render_im :: () {
	render_im_quad();
	render_im_quad_texture();
	render_im_char();
}

Shader :: struct {
	vertex_code: string;
	fragment_code: string;

	vertex_shader: GLuint = 0;
	fragment_shader: GLuint = 0;
	program: GLuint = 0;

	locations: Table(string, int, null, (a: string, b: string) -> bool { return compare(a, b) == 0;});
	keys: [..] string;

	make :: (from_vertex_code: string, from_fragment_code: string) -> Shader {
		shader: Shader;

		shader.vertex_code.data =
			NewArray(from_vertex_code.count, u8, false,, temp).data;
		shader.vertex_code.count = from_vertex_code.count;
		shader.fragment_code.data =
			NewArray(from_fragment_code.count, u8, false,, temp).data;
		shader.fragment_code.count = from_fragment_code.count;

		memcpy(shader.vertex_code.data, from_vertex_code.data, shader.vertex_code.count);
		memcpy(shader.fragment_code.data, from_fragment_code.data, shader.fragment_code.count);

		compile(*shader);
		return shader;
	}

	free :: (shader: *Shader) {
		deinit(*shader.locations);
		for shader.keys {
			free(it);
		}
		array_free(shader.keys);
	}

}
ok :: (shader: Shader) -> bool {
	return shader.program > 0;
}

set_uniform :: (shader: *Shader, name: string, value: $T) {
	context.rhi.glUseProgram(shader.program);

	found, loc := table_find_new(*shader.locations, name);
	if !found {
		loc = context.rhi.glGetUniformLocation(shader.program, name.data);
		allocated_name: string;
		allocated_name.data = xx alloc(name.count);
		allocated_name.count = name.count;
		memcpy(allocated_name.data, name.data, name.count);
		array_add(*shader.keys, allocated_name);
		table_add(*shader.locations, allocated_name, loc);
	}

	if loc < 0 {
		print("Uniform % not found in shader program.\n", name);
	}

	#if T == M4f {
		context.rhi.glUniformMatrix4fv(xx loc, 1, GL_FALSE, value.data.data);
	}
	else #if T == V3f {
		context.rhi.glUniform3f(xx loc, value.x, value.y, value.z);
	}
	else #if T == V2f {
		context.rhi.glUniform2f(xx loc, value.x, value.y);
	} else #if T == float32 {
		context.rhi.glUniform1f(xx loc, value);
	}
	else {
		print("Unsupported uniform type for %: %\n", name, typeof(value));
		assert(false);
	}
}
set_uniform :: (shader: *Shader, name: string, value: Texture, unit: int) {
	context.rhi.glUseProgram(shader.program);

	found, loc := table_find_new(*shader.locations, name);
	if !found {
		loc = context.rhi.glGetUniformLocation(shader.program, name.data);
		allocated_name: string;
		allocated_name.data = xx alloc(name.count);
		allocated_name.count = name.count;
		memcpy(allocated_name.data, name.data, name.count);
		array_add(*shader.keys, allocated_name);
		table_add(*shader.locations, allocated_name, loc);
	}

	if loc < 0 {
		print("Uniform % not found in shader program.\n", name);
	}
 
	context.rhi.glActiveTexture(xx (GL_TEXTURE0 + unit));
	context.rhi.glBindTexture(GL_TEXTURE_2D, value.id);
	context.rhi.glUniform1i(xx loc, xx unit);
}

release :: (shader: *Shader) {
	if shader.vertex_shader > 0 {
		context.rhi.glDeleteShader(shader.vertex_shader);
		shader.vertex_shader = 0;
	}
	if shader.fragment_shader > 0 {
		context.rhi.glDeleteShader(shader.fragment_shader);
		shader.fragment_shader = 0;
	}
	if shader.program > 0 {
		context.rhi.glDeleteProgram(shader.program);
		shader.program = 0;
	}
}

compile :: (shader: *Shader) {
	status: GLint;
	// Compile vertex shader
	vertex_shader := context.rhi.glCreateShader(GL_VERTEX_SHADER);
	x := cast(s32)(shader.vertex_code.count);
	context.rhi.glShaderSource(vertex_shader, 1, *shader.vertex_code.data, *x);
	context.rhi.glCompileShader(vertex_shader);
	status = 0;
	context.rhi.glGetShaderiv(vertex_shader, GL_COMPILE_STATUS, *status);
	if status == 0 {
		buffer := NewArray(1024, u8, false,, temp);
		written: u32;
		context.rhi.glGetShaderInfoLog(vertex_shader, xx buffer.count, *written, buffer.data);
		error_msg: string = .{ data =buffer.data, count = written };

		print("Vertex shader compilation failed: %\n", error_msg);
		context.rhi.glDeleteShader(vertex_shader);
		return;
	}
	shader.vertex_shader = vertex_shader;

	// Compile fragment shader
	fragment_shader := context.rhi.glCreateShader(GL_FRAGMENT_SHADER);
	x = cast(s32)(shader.fragment_code.count);
	context.rhi.glShaderSource(fragment_shader, 1, *shader.fragment_code.data, *x);
	context.rhi.glCompileShader(fragment_shader);
	status = 0;
	context.rhi.glGetShaderiv(fragment_shader, GL_COMPILE_STATUS, *status);
	if status == 0 {
		buffer := NewArray(1024, u8, false,, temp);
		written: u32;
		context.rhi.glGetShaderInfoLog(fragment_shader, xx buffer.count, *written, buffer.data);
		error_msg: string = .{ data =buffer.data, count = written };

		print("Fragment shader compilation failed: %\n", error_msg);
		context.rhi.glDeleteShader(fragment_shader);
		context.rhi.glDeleteShader(vertex_shader);
		return;
	}
	shader.fragment_shader = fragment_shader;

	// Create shader program
	shader_program := context.rhi.glCreateProgram();
	context.rhi.glAttachShader(shader_program, shader.vertex_shader);
	context.rhi.glAttachShader(shader_program, shader.fragment_shader);
	context.rhi.glLinkProgram(shader_program);
	status = 0;
	context.rhi.glGetProgramiv(shader_program, GL_LINK_STATUS, *status);
	if status == 0 {
		buffer := NewArray(1024, u8, false,, temp);
		written: u32;
		context.rhi.glGetProgramInfoLog(shader_program, xx buffer.count, *written, buffer.data);
		error_msg: string = .{ data =buffer.data, count = buffer.count };
		print("Shader program linking failed: %\n", error_msg);
		context.rhi.glDeleteProgram(shader_program);
		context.rhi.glDeleteShader(fragment_shader);
		context.rhi.glDeleteShader(vertex_shader);
		return;
	}

	shader.program = shader_program;
}

Geometry :: struct {
	Instance_Data :: struct {
		M: M4f;
		kind: int;
	}

	Vertex_Data :: struct {
		pos: V3f;
		nor: V3f;
		tex: V2f;
	}

	cpu_buffer: [] Vertex_Data;
	gpu_object: GLuint = 0;
	gpu_buffer: GLuint = 0;
	instanced_buffer: GLuint = 0;

	make_square :: (v1: V3f, v2: V3f, v3: V3f, v4: V3f) -> Geometry {
		geometry: Geometry;

		n := normalize(cross(v2 - v1, v3 - v1));

		geometry.cpu_buffer = NewArray(6, Geometry.Vertex_Data, false);
		geometry.cpu_buffer[0] = .{ pos = v1, nor = n, tex = .{ 0, 0 } };
		geometry.cpu_buffer[1] = .{ pos = v2, nor = n, tex = .{ 1, 0 } };
		geometry.cpu_buffer[2] = .{ pos = v3, nor = n, tex = .{ 1, 1 } };
		geometry.cpu_buffer[3] = .{ pos = v1, nor = n, tex = .{ 0, 0 } };
		geometry.cpu_buffer[4] = .{ pos = v3, nor = n, tex = .{ 1, 1 } };
		geometry.cpu_buffer[5] = .{ pos = v4, nor = n, tex = .{ 0, 1 } };

		upload(*geometry);

		return geometry;
	}

	make_from_obj :: (obj: [] u8) -> Geometry {
		return make_from_obj(obj.(string));
	}
	make_from_obj :: (obj: string) -> Geometry {
		geometry: Geometry;

		vertices: [..] V3f;
		vertices.allocator = temp;
		array_add(*vertices, .{ 0, 0, 0 });

		normals: [..] V3f;
		normals.allocator = temp;
		array_add(*normals, .{ 0, 0, 0 });

		textures: [..] V2f;
		textures.allocator = temp;
		array_add(*textures, .{ 0, 0 });

		Obj_Face :: struct {
			positions: [3] u32 = .[ 0, 0, 0 ];
			normals: [3] u32 = .[ 0, 0, 0 ];
			textures: [3] u32 = .[ 0, 0, 0 ];
		}

		faces: [..] Obj_Face;
		faces.allocator = temp;

		cursor := 0;
		line: string;

		while true {
			next_cursor := find_index_from_left(obj, "\n", cursor);
			if next_cursor < 0
				break;

			line.data = obj.data + cursor;
			line.count = next_cursor - cursor;
			cursor = next_cursor + 1;
			if line.count == 0
				continue;

			x: float32;
			y: float32;
			z: float32;
			r: float32;
			g: float32;
			b: float32;

			i: [9] u32;

			if scan2(line, "v % % %", *x, *y, *z) {
				array_add(*vertices, .{ x = x, y = y, z = z });
			}
			if scan2(line, "v % % % % % %", *x, *y, *z, *r, *g, *b) {
				array_add(*vertices, .{ x = x, y = y, z = z });
			}
			if scan2(line, "vn % % %", *x, *y, *z) {
				array_add(*normals, .{ x = x, y = y, z = z });
			}
			if scan2(line, "vt % %", *x, *y) {
				array_add(*textures, .{ x = x, y = y });
			}
			if scan2(
				line,
				"f %/%/% %/%/% %/%/%",
				*i[0], *i[1], *i[2], *i[3], *i[4], *i[5], *i[6], *i[7], *i[8]
			) {
				face: Obj_Face;
				face.positions[0] = i[0];
				face.positions[1] = i[3];
				face.positions[2] = i[6];
				face.normals[0] = i[2];
				face.normals[1] = i[5];
				face.normals[2] = i[8];
				face.textures[0] = i[1];
				face.textures[1] = i[4];
				face.textures[2] = i[7];
				array_add(*faces, face);
			}
			if scan2(
				line,
				"f %//% %//% %//%",
				*i[0], *i[1], *i[2], *i[3], *i[4], *i[5]
			) {
				face: Obj_Face;
				face.positions[0] = i[0];
				face.positions[1] = i[2];
				face.positions[2] = i[4];
				face.normals[0] = i[1];
				face.normals[1] = i[3];
				face.normals[2] = i[5];
				array_add(*faces, face);
			}
		}

		geometry.cpu_buffer = NewArray(
			faces.count * 3, Geometry.Vertex_Data, false
		);

		for faces {
			geometry.cpu_buffer[it_index * 3 + 0].pos = vertices[it.positions[0]];
			geometry.cpu_buffer[it_index * 3 + 0].nor = normals[it.normals[0]];
			geometry.cpu_buffer[it_index * 3 + 0].tex = textures[it.textures[0]];

			geometry.cpu_buffer[it_index * 3 + 1].pos = vertices[it.positions[1]];
			geometry.cpu_buffer[it_index * 3 + 1].nor = normals[it.normals[1]];
			geometry.cpu_buffer[it_index * 3 + 1].tex = textures[it.textures[1]];

			geometry.cpu_buffer[it_index * 3 + 2].pos = vertices[it.positions[2]];
			geometry.cpu_buffer[it_index * 3 + 2].nor = normals[it.normals[2]];
			geometry.cpu_buffer[it_index * 3 + 2].tex = textures[it.textures[2]];
		}

		upload(*geometry);

		return geometry;
	}
}

offset_of :: ($T: Type, $member: string) -> int {
	for type_info(T).members {
		if it.name == member
			return it.offset_in_bytes;
	}

	assert(false, "Type '%' does not have member '%'", T, member);
	return -1;
}

upload :: (geometry: *Geometry) {
	// If no object is assigned, create it.
	if geometry.gpu_object == 0 {
		context.rhi.glGenVertexArrays(1, *geometry.gpu_object);
	}
	context.rhi.glBindVertexArray(geometry.gpu_object);

	// If the buffer is null, create it.
	if geometry.gpu_buffer == 0 {
		context.rhi.glGenBuffers(1, *geometry.gpu_buffer);
	}

	context.rhi.glBindBuffer(GL_ARRAY_BUFFER, geometry.gpu_buffer);
	context.rhi.glBufferData(
		GL_ARRAY_BUFFER,
		geometry.cpu_buffer.count * size_of(Geometry.Vertex_Data),
		geometry.cpu_buffer.data,
		GL_STATIC_DRAW
	);

	context.rhi.glEnableVertexAttribArray(0); // Position
	context.rhi.glVertexAttribPointer(
		0, 3, GL_FLOAT, GL_FALSE,
		size_of(Geometry.Vertex_Data), xx offset_of(Geometry.Vertex_Data, "pos")
	);

	context.rhi.glEnableVertexAttribArray(1); // Normal
	context.rhi.glVertexAttribPointer(
		1, 3, GL_FLOAT, GL_FALSE,
		size_of(Geometry.Vertex_Data), xx offset_of(Geometry.Vertex_Data, "nor")
	);

	context.rhi.glEnableVertexAttribArray(2); // Texture
	context.rhi.glVertexAttribPointer(
		2, 2, GL_FLOAT, GL_FALSE,
		size_of(Geometry.Vertex_Data),  xx offset_of(Geometry.Vertex_Data, "tex")
	);
}

add_instance :: (geometry: *Geometry, instanced: [] u8) {
	context.rhi.glBindVertexArray(geometry.gpu_object);
	if geometry.instanced_buffer == 0 {
		context.rhi.glGenBuffers(1, *geometry.instanced_buffer);
	}
	context.rhi.glBindBuffer(GL_ARRAY_BUFFER, geometry.instanced_buffer);
	context.rhi.glBufferData(
		GL_ARRAY_BUFFER,
		instanced.count * size_of(u8),
		instanced.data,
		GL_STATIC_DRAW
	);
}

render :: (geometry: Geometry, shader: Shader) {
	context.rhi.glUseProgram(shader.program);
	context.rhi.glBindVertexArray(geometry.gpu_object);
	context.rhi.glDrawArrays(GL_TRIANGLES, 0, xx geometry.cpu_buffer.count);
}

render_instanced :: (geometry: Geometry, shader: Shader, n: int) {
	context.rhi.glUseProgram(shader.program);
	context.rhi.glBindVertexArray(geometry.gpu_object);
	context.rhi.glDrawArraysInstanced(GL_TRIANGLES, 0, xx geometry.cpu_buffer.count, xx n);
}
enable_instanced_attributes :: (slot: int) {
	context.rhi.glEnableVertexAttribArray(xx (slot + 0)); // Matrix
	context.rhi.glEnableVertexAttribArray(xx (slot + 1)); // Matrix
	context.rhi.glEnableVertexAttribArray(xx (slot + 2)); // Matrix
	context.rhi.glEnableVertexAttribArray(xx (slot + 3)); // Matrix
	context.rhi.glVertexAttribPointer(
		xx (slot + 0),
		4,
		GL_FLOAT,
		GL_FALSE,
		size_of(Geometry.Instance_Data),
		xx (offset_of(Geometry.Instance_Data, "M") + 00)
	);
	context.rhi.glVertexAttribPointer(
		xx (slot + 1),
		4,
		GL_FLOAT,
		GL_FALSE,
		size_of(Geometry.Instance_Data),
		xx (offset_of(Geometry.Instance_Data, "M") + 16)
	);
	context.rhi.glVertexAttribPointer(
		xx (slot + 2),
		4,
		GL_FLOAT,
		GL_FALSE,
		size_of(Geometry.Instance_Data),
		xx (offset_of(Geometry.Instance_Data, "M") + 32)
	);
	context.rhi.glVertexAttribPointer(
		xx (slot + 3),
		4,
		GL_FLOAT,
		GL_FALSE,
		size_of(Geometry.Instance_Data),
		xx (offset_of(Geometry.Instance_Data, "M") + 48)
	);
	context.rhi.glVertexAttribDivisor(xx (slot + 0), 1);
	context.rhi.glVertexAttribDivisor(xx (slot + 1), 1);
	context.rhi.glVertexAttribDivisor(xx (slot + 2), 1);
	context.rhi.glVertexAttribDivisor(xx (slot + 3), 1);
	context.rhi.glEnableVertexAttribArray(xx (slot + 4)); // Matrix
	context.rhi.glVertexAttribIPointer(
		xx (slot + 4), 1, GL_INT,
		size_of(Geometry.Instance_Data),  xx offset_of(Geometry.Instance_Data, "kind")
	);
	context.rhi.glVertexAttribDivisor(xx (slot + 4), 1);
}

Texture :: struct {
	width: u32;
	height: u32;
	id: GLuint;

	make_from_image :: (image: Image) -> Texture {
		texture: Texture;
		texture.width = image.width;
		texture.height = image.height;
		texture.id = 0;

		upload(*texture, image.data, image.channels);
		return texture;
	}
}

ok :: (texture: Texture) -> bool {
	return texture.id > 0;
}
upload :: (texture: *Texture, data: [] u8, channels: int) {
	context.rhi.glGenTextures(1, *texture.id);
	context.rhi.glBindTexture(GL_TEXTURE_2D, texture.id);
	context.rhi.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	context.rhi.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	context.rhi.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	context.rhi.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	if channels == 4 {
		context.rhi.glTexImage2D(
			GL_TEXTURE_2D, 0, GL_RGBA8, texture.width, texture.height, 0,
			GL_RGBA, GL_UNSIGNED_BYTE, data.data
		);
	} else if channels == 3 {
		context.rhi.glTexImage2D(
			GL_TEXTURE_2D, 0, GL_RGB8, texture.width, texture.height, 0,
			GL_RGB, GL_UNSIGNED_BYTE, data.data
		);
	} else if channels == 1 {
		context.rhi.glTexImage2D(
			GL_TEXTURE_2D, 0, GL_R8, texture.width, texture.height, 0,
			GL_RED, GL_UNSIGNED_BYTE, data.data
		);
	} else {
		print("Unsupported channel count %\n", channels);
	}
}
set_parameter :: (texture: Texture, parameter: GLenum, value: GLint) {
	context.rhi.glBindTexture(GL_TEXTURE_2D, texture.id);
	context.rhi.glTexParameteri(GL_TEXTURE_2D, parameter, value);
}
set_clamp :: (texture: Texture, dir: enum { S; T; }) {
	context.rhi.glBindTexture(GL_TEXTURE_2D, texture.id);
	context.rhi.glTexParameteri(
		GL_TEXTURE_2D,
		xx (ifx dir == .S then GL_TEXTURE_WRAP_S else GL_TEXTURE_WRAP_T),
		GL_CLAMP_TO_EDGE
	);
}