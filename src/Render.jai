#import "Basic";
#import "String";
#import "Algebra";
#import "Assets";
#import "Math";
#import "Platform";
#import "Hash_Table";
Store :: #import "Store";
STB :: #import "stb_image";
Scene :: #import "Scene";

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

Text_Align :: enum {
	Left :: 0b01;
	Right :: 0b10;
	HCenter :: 0b11;
	Top :: 0b1000;
	Bottom :: 0b0100;
	VCenter :: 0b1100;
	Center :: 0b1111;
	Bottom_Left :: 0b0101;
	Bottom_Right :: 0b0110;
	Top_Left :: 0b1001;
	Top_Right :: 0b1010;
}
push_text :: (
	text: string, pos: V2f, height := 12.0, z := 0.0, align := Text_Align.Bottom_Left
) -> V2f {
	x := pos.x;

	before := IM.chars.count;
	max_height := 0.0;
	H := MAIN_FONT.height.(float);
	H = height / H;
	for text {
		char: IM.Char;
		char.id = it - 0x20;
		char.pos.x = x;
		char.pos.y = pos.y;
		char.z = z;
		char.color = .{ 1, 1, 1 };
		char.height = height;

		sprite := MAIN_FONT.sprites[char.id];

		x += sprite.charAdvanceX * H;
		h := sprite.sourceHeight * H;

		max_height = max(max_height, h);
		array_add(*IM.chars, char);
	}

	for before..IM.chars.count-1 {
		char := IM.chars[it];
		if (align & Text_Align.HCenter) == Text_Align.HCenter {
			char.pos.x -= (x - pos.x) / 2;
		}
		if (align & Text_Align.Right) == Text_Align.Right {
			char.pos.x -= (x - pos.x);
		}
		if (align & Text_Align.VCenter) == Text_Align.VCenter {
			char.pos.y -= max_height/ 2;
		}
		if (align & Text_Align.Top) == Text_Align.Bottom {
			char.pos.y -= max_height;
		}
	}

	return .{ x - pos.x, max_height };
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
		vertices[
			it_index * 6 + 3].color = it.color;

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
	context.rhi.glBindFramebuffer(GL_FRAMEBUFFER, 0);
	render_im_quad();
	render_im_quad_texture();
	render_im_char();
}

Framebuffer :: struct {
	id: GLuint = 0;
	width: int = 0;
	height: int = 0;

	rbo: GLuint = 0;

	make :: (size: V2i, add_rbo := true) -> Framebuffer {
		framebuffer: Framebuffer;
		framebuffer.width = size.x;
		framebuffer.height = size.y;

		context.rhi.glGenFramebuffers(1, *framebuffer.id);
		context.rhi.glBindFramebuffer(GL_FRAMEBUFFER, framebuffer.id);
		if add_rbo {
			context.rhi.glGenRenderbuffers(1, *framebuffer.rbo);
			context.rhi.glBindRenderbuffer(
				GL_RENDERBUFFER, framebuffer.rbo
			);
			context.rhi.glRenderbufferStorage(
				GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, xx framebuffer.width, xx framebuffer.height
			);
			context.rhi.glFramebufferRenderbuffer(
				GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, framebuffer.rbo
			);
		}
		return framebuffer;
	}
}
attach_color :: (framebuffer: Framebuffer, texture: Texture, attachment: int) {
	context.rhi.glBindFramebuffer(GL_FRAMEBUFFER, framebuffer.id);
	context.rhi.glFramebufferTexture2D(
		GL_FRAMEBUFFER, xx (GL_COLOR_ATTACHMENT0 + attachment), GL_TEXTURE_2D, texture.id, 0
	);
}
attach_depth :: (framebuffer: Framebuffer, texture: Texture) {
	context.rhi.glBindFramebuffer(GL_FRAMEBUFFER, framebuffer.id);
	context.rhi.glFramebufferTexture2D(
		GL_FRAMEBUFFER, xx GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, texture.id, 0
	);
}
clear :: (framebuffer: Framebuffer, clear_color: V4f) {
	context.rhi.glBindFramebuffer(GL_FRAMEBUFFER, framebuffer.id);
	context.rhi.glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);
	context.rhi.glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
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

setup_vertex_attributes :: (attribute_offset: int, $V: Type) -> int {
	info := cast(*Type_Info_Struct) type_info(V);

	cursor := attribute_offset;
	for info.members {
		iit := cast(Type_Info_Struct_Member) it;
		offset := it.offset_in_bytes;
		if iit.type == type_info(M4f) {
			for i: 0..3 {
				context.rhi.glEnableVertexAttribArray(xx cursor);
				context.rhi.glVertexAttribPointer(
					xx cursor,
					4,
					GL_FLOAT,
					GL_FALSE,
					size_of(V),
					xx (it.offset_in_bytes + i * 16)
				);
				context.rhi.glVertexAttribDivisor(xx cursor, 0);
				cursor += 1;
			}
			continue;
		}

		component_type := GL_FLOAT;
		component_size := iit.type.runtime_size / size_of(float);
		if iit.notes.count > 0 {

			if compare(iit.notes[0], "int") == 0 {
				component_type = GL_INT;
				component_size = iit.type.runtime_size / size_of(s32);
			}
		}

		context.rhi.glEnableVertexAttribArray(xx cursor);
		if component_type == GL_INT {
			context.rhi.glVertexAttribIPointer(
				xx cursor,
				xx component_size,
				xx component_type,
				size_of(V),
				xx it.offset_in_bytes
			);
		} else {
			context.rhi.glVertexAttribPointer(
				xx cursor,
				xx component_size,
				xx component_type,
				GL_FALSE,
				size_of(V),
				xx it.offset_in_bytes
			);
		}
		context.rhi.glVertexAttribPointer(
			xx cursor,
			xx component_size,
			xx component_type,
			GL_FALSE,
			size_of(V),
			xx it.offset_in_bytes
		);
		context.rhi.glVertexAttribDivisor(xx cursor, 0);
		cursor += 1;
	}
	return cursor;
}

setup_instance_attributes :: (attribute_offset: int, $I: Type) -> int {
	info := cast(*Type_Info_Struct) type_info(I);

	cursor := attribute_offset;
	for info.members {
		iit := cast(Type_Info_Struct_Member) it;
		offset := it.offset_in_bytes;
		if iit.type == type_info(M4f) {
			for i: 0..3 {
				context.rhi.glEnableVertexAttribArray(xx cursor);
				context.rhi.glVertexAttribPointer(
					xx cursor,
					4,
					GL_FLOAT,
					GL_FALSE,
					size_of(I),
					xx (it.offset_in_bytes + i * 16)
				);
				context.rhi.glVertexAttribDivisor(xx cursor, 1);
				cursor += 1;
			}
			continue;
		}

		component_type := GL_FLOAT;
		component_size := iit.type.runtime_size / size_of(float);
		if iit.notes.count > 0 {
			if compare(iit.notes[0], "int") == 0 {
				component_type = GL_INT;
				component_size = iit.type.runtime_size / size_of(s32);
			}
		}

		context.rhi.glEnableVertexAttribArray(xx cursor);
		if component_type == GL_INT {
			context.rhi.glVertexAttribIPointer(
				xx cursor,
				xx component_size,
				xx component_type,
				size_of(I),
				xx it.offset_in_bytes
			);
		} else {
			context.rhi.glVertexAttribPointer(
				xx cursor,
				xx component_size,
				xx component_type,
				GL_FALSE,
				size_of(I),
				xx it.offset_in_bytes
			);
		}
		context.rhi.glVertexAttribDivisor(xx cursor, 1);
		cursor += 1;
	}
	return cursor;
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
		// print("Uniform % not found in shader program.\n", name);
		return;
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
		// print("Uniform % not found in shader program.\n", name);
		return;
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

	make_fullscreen_quad :: () -> Geometry {
		geom: Geometry;
		context.rhi.glGenVertexArrays(1, *geom.gpu_object);
		context.rhi.glBindVertexArray(geom.gpu_object);

		context.rhi.glGenBuffers(1, *geom.gpu_buffer);
		context.rhi.glBindBuffer(GL_ARRAY_BUFFER, geom.gpu_buffer);

		data :: float.[
			-1.0, -1.0,
			1.0, -1.0,
			1.0, 1.0,
			-1.0, -1.0,
			1.0, 1.0,
			-1.0, 1.0
		];

		context.rhi.glBufferData(
			GL_ARRAY_BUFFER, data.count * size_of(float), data.data, GL_STATIC_DRAW
		);

		context.rhi.glEnableVertexAttribArray(0); // Position
		context.rhi.glVertexAttribPointer(
			0, 2, GL_FLOAT, GL_FALSE,
			2 * size_of(float32), null
		);

		return geom;
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

	make_rgba32f :: (size: V2i) -> Texture {
		texture: Texture;
		texture.width = xx size.x;
		texture.height = xx size.y;
		texture.id = 0;

		context.rhi.glGenTextures(1, *texture.id);
		context.rhi.glBindTexture(GL_TEXTURE_2D, texture.id);
		context.rhi.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		context.rhi.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		context.rhi.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		context.rhi.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		context.rhi.glTexImage2D(
			GL_TEXTURE_2D, 0, GL_RGBA32F, texture.width, texture.height, 0,
			GL_RGBA, GL_FLOAT, null
		);

		return texture;
	}
	
	make_depth :: (size: V2i) -> Texture {
		texture: Texture;
		texture.width = xx size.x;
		texture.height = xx size.y;
		texture.id = 0;

		context.rhi.glGenTextures(1, *texture.id);
		context.rhi.glBindTexture(GL_TEXTURE_2D, texture.id);
		context.rhi.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		context.rhi.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		context.rhi.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		context.rhi.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		context.rhi.glTexImage2D(
			GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT32F, texture.width, texture.height, 0,
			GL_DEPTH_COMPONENT, GL_FLOAT, null
		);

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

Framegraph :: struct {
	main_framebuffer: Framebuffer;
	main_color: Texture;

	shadow_framebuffer: Framebuffer;
	shadow_depth: Texture;

	fullscreen_quad: Geometry;

	postpro_shader: *Shader;
}

Camera_Matrix :: struct {
	V: M4f;
	P: M4f;

	viewport: V2f;
}

Shaders :: struct {
	tile_shader: *Shader;
	textured_shader: *Shader;
	instanced_shader: *Shader;
	instanced_texture_shader: *Shader;
	particle_shader: *Shader;
}

bind :: (framegraph: Framegraph) {
	context.rhi.glBindFramebuffer(GL_FRAMEBUFFER, framegraph.main_framebuffer.id);
}

create_framegraph :: (framegraph: *Framegraph, store: *Store.Store) {
	framegraph.main_framebuffer = Framebuffer.make(V2i.{ 1920, 1080 });

	framegraph.main_color = Texture.make_rgba32f(V2i.{ 1920, 1080 });
	attach_color(framegraph.main_framebuffer, framegraph.main_color, 0);

	framegraph.shadow_framebuffer = Framebuffer.make(V2i.{ 4096, 4096 }, false);
	framegraph.shadow_depth = Texture.make_depth(V2i.{ 4096, 4096 });
	attach_depth(framegraph.shadow_framebuffer, framegraph.shadow_depth);

	framegraph.fullscreen_quad = Geometry.make_fullscreen_quad();
	framegraph.postpro_shader = *store.postpro_shader;
}

render :: (
	framegraph: Framegraph, scene: Scene.Scene, camera_matrix: Camera_Matrix
) {
	store := scene.store;

	shaders: Shaders;
	shaders.tile_shader = *store.tile_shader;

	context.rhi.glBindFramebuffer(GL_FRAMEBUFFER, framegraph.shadow_framebuffer.id);
	context.rhi.glViewport(
		0, 0, xx framegraph.shadow_framebuffer.width, xx framegraph.shadow_framebuffer.height
	);
	clear(framegraph.shadow_framebuffer, V4f.{ 0.0, 0.0, 0.0, 1 });

	center := V3f.{ 0, 0, 0 };
	center.x += scene.terrain.tiles_count.x / 2.0;
	center.y += scene.terrain.tiles_count.y / 2.0;
	SV := Scene.look_at(center + V3f.{ 100, 100, 100 }, center, V3f.{ 0, 1, 0 });
	SP := Scene.orthographic(-40, 40, -40, 40, 0.1, 500);
	set_uniform(*store.shadow_shader, "V", SV);
	set_uniform(*store.shadow_shader, "P", SP);
	set_uniform(*store.shadow_instanced_shader, "V", SV);
	set_uniform(*store.shadow_instanced_shader, "P", SP);
	set_uniform(*store.shadow_instanced_texture_shader, "V", SV);
	set_uniform(*store.shadow_instanced_texture_shader, "P", SP);
	
	shaders.textured_shader = *store.shadow_shader;
	shaders.instanced_shader = *store.shadow_instanced_shader;
	shaders.instanced_texture_shader = *store.shadow_instanced_texture_shader;
	render_terrain_props(scene, scene.props, shaders);
	render_keys(scene, shaders);
	render_standin(scene, shaders);
	if scene.state != .Wipe_Fade_In
		render_players(scene, shaders);
	render_skulls(scene, shaders);
	render_shurikens(scene, shaders);
	render_gates(scene, shaders);
	render_tombstones(scene, shaders);
	render_flags(scene, shaders);
	render_robots(scene, shaders);

	shaders.textured_shader = *store.texture_shader;
	shaders.instanced_shader = *store.instance_shader;
	shaders.instanced_texture_shader = *store.instanced_texture_shader;
	shaders.particle_shader = *store.particle_shader;
	context.rhi.glBindFramebuffer(GL_FRAMEBUFFER, framegraph.main_framebuffer.id);
	context.rhi.glViewport(0, 0, xx camera_matrix.viewport.x, xx camera_matrix.viewport.y);
	clear(framegraph.main_framebuffer, V4f.{ 0.45, 0.55, 0.60, 1 });
	V := Scene.look_at(scene.camera.position, scene.camera.target, .{ 0, 0, 1 });
	P := Scene.perspective(scene.camera);

	set_uniform(*store.model_shader, "V", V);
	set_uniform(*store.model_shader, "P", P);
	set_uniform(shaders.textured_shader, "V", V);
	set_uniform(shaders.textured_shader, "P", P);
	set_uniform(shaders.particle_shader, "V", V);
	set_uniform(shaders.particle_shader, "P", P);
	set_uniform(shaders.particle_shader, "albedo", store.particle_texture, 0);
	set_uniform(shaders.particle_shader, "shadow", framegraph.shadow_depth, 1);
	set_uniform(shaders.particle_shader, "shadowV", SV);
	set_uniform(shaders.particle_shader, "shadowP", SP);
	set_uniform(*store.tile_shader, "V", V);
	set_uniform(*store.tile_shader, "P", P);
	set_uniform(*store.skybox_shader, "V", V);
	set_uniform(*store.skybox_shader, "P", P);
	set_uniform(*store.tile_shader, "shadow", framegraph.shadow_depth, 1);
	set_uniform(*store.tile_shader, "shadowV", SV);
	set_uniform(*store.tile_shader, "shadowP", SP);
	set_uniform(*store.instanced_texture_shader, "shadow", framegraph.shadow_depth, 1);
	set_uniform(*store.instanced_texture_shader, "shadowV", SV);
	set_uniform(*store.instanced_texture_shader, "shadowP", SP);
	set_uniform(*store.instance_shader, "V", V);
	set_uniform(*store.instance_shader, "P", P);
	set_uniform(*store.instanced_texture_shader, "V", V);
	set_uniform(*store.instanced_texture_shader, "P", P);

	set_uniform(*store.instanced_texture_shader, "tint", V3f.{ 1.0, 1.0, 1.0 });
	set_uniform(*store.instance_shader, "tint", V3f.{ 1.0, 1.0, 1.0 });
	set_uniform(shaders.textured_shader, "tint", V3f.{ 1.0, 1.0, 1.0 });
	set_uniform(shaders.textured_shader, "texture_offset", V2f.{ 0, 0 });

	render_terrain(scene, *scene.terrain, shaders);

	set_uniform(shaders.textured_shader, "texture_sampler", store.coin_texture, 0);
	for * scene.coins {
		R := to_rotation_matrix(axis_angle(V3f.{ 0, 0, 1 }, it.client.theta));

		M := M4f.translate(it.client.position) * R;
		set_uniform(shaders.textured_shader, "M", M);
		render(store.coin_geometry, shaders.textured_shader);
	}

	render_keys(scene, shaders);
	render_standin(scene, shaders);
	if scene.state != .Wipe_Fade_In
		render_players(scene, shaders);
	render_skulls(scene, shaders);
	render_shurikens(scene, shaders);
	render_gates(scene, shaders);
	render_tombstones(scene, shaders);
	render_flags(scene, shaders);
	render_robots(scene, shaders);
	render_within_zones(scene, shaders);
	render_particles(scene, shaders);
	render_explosions(scene, shaders);

	if to_float64_seconds(current_time_monotonic() - scene.mark_clicked_time) < 0.8 {
		set_uniform(shaders.textured_shader, "texture_sampler", store.mark_texture, 0);
		M := M4f.translate(scene.mark_clicked_pos);
		set_uniform(shaders.textured_shader, "M", M);
		t := to_float64_seconds(current_time_monotonic() - scene.mark_clicked_time);
		t /= 0.8;
		t = 1 - ((1 - t) * (1 - t) * (1 - t) * (1 - t) * (1 - t));
		offset := V2f.{ 0, xx -t };
		set_uniform(shaders.textured_shader, "texture_offset", offset);
		context.rhi.glDisable(GL_CULL_FACE);
		render(store.mark_geometry, shaders.textured_shader);
		context.rhi.glEnable(GL_CULL_FACE);
	}

	render_skybox(scene);

	context.rhi.glBindFramebuffer(GL_FRAMEBUFFER, 0);
	context.rhi.glUseProgram(framegraph.postpro_shader.program);
	set_uniform(framegraph.postpro_shader, "hdr", framegraph.main_color, 0);
	set_uniform(
		framegraph.postpro_shader,
		"hdr_size",
		V2f.{ xx framegraph.main_color.width, xx framegraph.main_color.height }
	);
	set_uniform(
		framegraph.postpro_shader,
		"viewport_size",
		camera_matrix.viewport
	);
	context.rhi.glBindVertexArray(framegraph.fullscreen_quad.gpu_object);
	context.rhi.glDrawArrays(GL_TRIANGLES, 0, xx 6);
}

render_explosions :: (scene: Scene.Scene, shaders: Shaders) {
	store := scene.store;

	Instance :: struct {
		M: M4f;
	};
	instanced := NewArray(scene.robots.count, Instance, initialized = false,, temp);
	instanced.count = 0;

	for scene.explosions {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];

		ts := ease_out_quad(clamp(it.age / it.lifetime, 0.0, 1.0)) * it.max_size;

		instance.M = M4f.translate(it.position);
		instance.M *= scale_matrix(V3f.{ ts, ts, ts });
	}

	if instanced.count > 0 {
		add_instance(*store.unit_sphere_geometry, .{
			data = xx instanced.data,
			count = instanced.count * size_of(Instance)
		});

		context.rhi.glBindVertexArray(store.unit_sphere_geometry.gpu_object);
		context.rhi.glBindBuffer(GL_ARRAY_BUFFER, store.unit_sphere_geometry.gpu_buffer);
		cursor := setup_vertex_attributes(0, Geometry.Vertex_Data);
		context.rhi.glBindBuffer(GL_ARRAY_BUFFER, store.unit_sphere_geometry.instanced_buffer);
		cursor = setup_instance_attributes(cursor, Instance);
		render_instanced(
			store.unit_sphere_geometry, shaders.instanced_texture_shader, instanced.count
		);
	}
}

render_robots :: (scene: Scene.Scene, shaders: Shaders) {
	store := scene.store;

	Instance :: struct {
		M: M4f;
	};

	Instance_Particle :: struct {
		M: M4f;
		texture_rec: V4f;
		color: V4f;
	}

	instanced := NewArray(scene.robots.count, Instance, initialized = false,, temp);

	for 0..5 {
		instanced.count = 0;
		for robot: scene.robots {
			instanced.count += 1;
			instance := *instanced[instanced.count - 1];

			instance.M = Scene.robot_to_axis(robot, it);
		}
		geom := Store.get_axes_geometry(store, it);

		add_instance(geom, .{
			data = xx instanced.data,
			count = instanced.count * size_of(Instance)
		});

		context.rhi.glBindVertexArray(geom.gpu_object);
		context.rhi.glBindBuffer(GL_ARRAY_BUFFER, geom.gpu_buffer);
		cursor := setup_vertex_attributes(0, Geometry.Vertex_Data);
		context.rhi.glBindBuffer(GL_ARRAY_BUFFER, geom.instanced_buffer);
		cursor = setup_instance_attributes(cursor, Instance);
		render_instanced(geom, shaders.instanced_texture_shader, instanced.count);
	}

	instanced.count = 0;
	instanced_particles := NewArray(
		scene.robots.count, Instance_Particle, initialized = false,, temp
	);
	instanced_particles.count = 0;
	for robot: scene.robots {
		M := Scene.robot_matrix_local_to_joint(robot, 6);
		if robot.shooting_cd < robot.shooting_time
		&& robot.shooting_time < robot.shooting_cd + robot.charging_time
		{
			ray_origin := v3(M * V4f.{ 0, 0, 0, 1 });
			ray_direction := normalize(v3(M * V4f.{ 0, 0, 1, 0 }));

			target, hit := ray_plane(ray_origin, ray_direction, V3f.{ 0, 0, 1 });
			if hit {
				instanced_particles.count += 1;
				particle := *instanced_particles[instanced_particles.count - 1];
				particle.M = M4f.translate(target + V3f.{ -1.0, -1.0, 0.01 });
				particle.M *= scale_matrix(V3f.{ 2.0, 2.0, 1.0 });
				particle.texture_rec = V4f.{ 0, 0, 1 / 4.0, 1 / 4.0 };
				particle.color = V4f.{ 1.0, 0.0, 0.0, 1.0 };
			}
		}


		if !((robot.shooting_cd + robot.charging_time) < robot.shooting_time
		&& robot.shooting_time < (robot.shooting_cd + robot.charging_time + robot.effectshoot_time))
			continue;

		instanced.count += 1;
		instance := *instanced[instanced.count - 1];

		over_t := robot.shooting_time - robot.shooting_cd - robot.charging_time;
		t := clamp(over_t / robot.effectshoot_time, 0.0, 1.0);

		ts := ease_up_and_back(clamp(t * 5, 0.0, 1.0)) * 0.3;
		tz := ease_out_quad(clamp(t * 20, 0.0, 1.0)) * 100;

		instance.M = M;
		instance.M *= scale_matrix(V3f.{ ts, ts, tz });
	}

	if instanced.count > 0 {
		add_instance(*store.unit_cylinder_geometry, .{
			data = xx instanced.data,
			count = instanced.count * size_of(Instance)
		});

		context.rhi.glBindVertexArray(store.unit_cylinder_geometry.gpu_object);
		context.rhi.glBindBuffer(GL_ARRAY_BUFFER, store.unit_cylinder_geometry.gpu_buffer);
		cursor := setup_vertex_attributes(0, Geometry.Vertex_Data);
		context.rhi.glBindBuffer(GL_ARRAY_BUFFER, store.unit_cylinder_geometry.instanced_buffer);
		cursor = setup_instance_attributes(cursor, Instance);
		render_instanced(
			store.unit_cylinder_geometry, shaders.instanced_texture_shader, instanced.count
		);
	}

	if instanced_particles.count > 0 && shaders.particle_shader {
		context.rhi.glBlendFunc(GL_SRC_ALPHA, GL_ONE);
		context.rhi.glDepthMask(GL_FALSE);
		defer {
			context.rhi.glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
			context.rhi.glDepthMask(GL_TRUE);
		}

		add_instance(*store.z_facing_unit_square_geometry, .{
			data = xx instanced_particles.data,
			count = instanced_particles.count * size_of(Instance_Particle)
		});
		set_uniform(shaders.particle_shader, "albedo", store.particle_texture, 0);

		context.rhi.glBindVertexArray(store.z_facing_unit_square_geometry.gpu_object);
		context.rhi.glBindBuffer(GL_ARRAY_BUFFER, store.z_facing_unit_square_geometry.gpu_buffer);
		cursor := setup_vertex_attributes(0, Geometry.Vertex_Data);
		context.rhi.glBindBuffer(GL_ARRAY_BUFFER, store.z_facing_unit_square_geometry.instanced_buffer);
		cursor = setup_instance_attributes(cursor, Instance_Particle);
		render_instanced(
			store.z_facing_unit_square_geometry,
			shaders.particle_shader,
			instanced_particles.count
		);

	}
}

render_within_zones :: (scene: Scene.Scene, shaders: Shaders) {
	store := scene.store;
	set_uniform(*store.instanced_texture_shader, "colormap", store.prop_colormap, 0);

	Instance :: struct {
		M: M4f;
	};

	instanced := NewArray(scene.within_zones.count, Instance, initialized = false,, temp);
	instanced.count = 0;
	for scene.within_zones {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];

		instance.M = M4f.translate(v3(it.pos, 0.001));
		instance.M *= scale_matrix(v3(it.size, 1.0));
	}

	add_instance(*store.indicator_outline_geometry, .{
		data = xx instanced.data,
		count = instanced.count * size_of(Instance)
	});

	context.rhi.glBlendFunc(GL_SRC_ALPHA, GL_ONE);
	context.rhi.glBindVertexArray(store.indicator_outline_geometry.gpu_object);
	context.rhi.glBindBuffer(GL_ARRAY_BUFFER, store.indicator_outline_geometry.gpu_buffer);
	cursor := setup_vertex_attributes(0, Geometry.Vertex_Data);
	context.rhi.glBindBuffer(GL_ARRAY_BUFFER, store.indicator_outline_geometry.instanced_buffer);
	cursor = setup_instance_attributes(cursor, Instance);
	render_instanced(
		store.indicator_outline_geometry, shaders.instanced_texture_shader, instanced.count
	);

	instanced.count = 0;
	for scene.within_zones {
		if it.time_stayed <= 0.0
			continue;
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];

		instance.M = M4f.translate(v3(it.pos + V2f.{ it.size.x * 0.15, it.size.y * 0.15 }, 0.001));

		t := clamp(it.time_stayed / it.time_to_stay, 0.0, 1.0);
		t = t * 0.7;
		t *= it.size.y;
		instance.M *= scale_matrix(V3f.{it.size.x * 0.7, t , 1.0});
	}

	add_instance(*store.indicator_stroke_geometry, .{
		data = xx instanced.data,
		count = instanced.count * size_of(Instance)
	});

	context.rhi.glBindVertexArray(store.indicator_stroke_geometry.gpu_object);
	context.rhi.glBindBuffer(GL_ARRAY_BUFFER, store.indicator_stroke_geometry.gpu_buffer);
	cursor = setup_vertex_attributes(0, Geometry.Vertex_Data);
	context.rhi.glBindBuffer(GL_ARRAY_BUFFER, store.indicator_stroke_geometry.instanced_buffer);
	cursor = setup_instance_attributes(cursor, Instance);
	render_instanced(
		store.indicator_stroke_geometry, shaders.instanced_texture_shader, instanced.count
	);

	context.rhi.glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	for scene.within_zones {
		if it.time_stayed >= it.time_to_stay
			continue;

		needed := ceil(scene.players.count * it.min_player_percent).(int);
		left := needed - it.last_player_count;

		pos := v3(it.pos, 0.0) + V3f.{ it.size.x / 2, -0.5, 0.5 };
		while left > 0 {
			M := M4f.translate(pos);
			if it.count_changed_juice_t > 0 {
				M = M * scale_matrix(
					1.0 + ease_up_and_back(1.0 - it.count_changed_juice_t) * 0.5
				);
			}
			set_uniform(shaders.textured_shader, "M", M);

			geom := Store.get_number_geometry(store, left % 10);
			if geom
				render(geom, shaders.textured_shader);

			left /= 10;
			pos.x -= 0.3;
		}
	}
}

render_particles :: (scene: Scene.Scene, shaders: Shaders) {
	store := scene.store;

	Instance :: struct {
		M: M4f;
		texture_rec: V4f;
		color: V4f;
	}

	dt := normalize(scene.camera.target - scene.camera.position);

	instances := NewArray(scene.particles.count, Instance, false,, temp);
	for scene.particles {
		instance := *instances[it_index];
		instance.M = M4f.identity();
		instance.M *= M4f.translate(it.position);
		instance.M *= to_rotation_matrix(from_unit_vectors(V3f.{ 0, 0, -1 }, dt));
		instance.M *= scale_matrix(it.size);
		instance.M *= to_rotation_matrix(axis_angle(V3f.{ 0, 0, 1 }, it.rotation));
		instance.M *= M4f.translate(V3f.{ -0.5, -0.5, 0 });
		instance.texture_rec = .{
			it.texture_rec.x, it.texture_rec.y, it.texture_rec.z, it.texture_rec.w
		};
		instance.color = .{ it.color.x, it.color.y, it.color.z, it.color.w };
		if it.fade_out_time > 0 {
			t := clamp((it.lifetime - it.age) / it.fade_out_time, 0.0, 1.0);
			instance.color.w *= t;
		}
	}

	instances_u8: [] u8;
	instances_u8.data = instances.data.(*u8);
	instances_u8.count = instances.count * size_of(Instance);
	add_instance(*store.z_facing_unit_square_geometry, instances_u8);
	set_uniform(shaders.particle_shader, "albedo", store.particle_texture, 0);
	
	context.rhi.glBindVertexArray(store.z_facing_unit_square_geometry.gpu_object);
	context.rhi.glBindBuffer(GL_ARRAY_BUFFER, store.z_facing_unit_square_geometry.gpu_buffer);
	cursor := setup_vertex_attributes(0, store.z_facing_unit_square_geometry.Vertex_Data);
	context.rhi.glBindBuffer(GL_ARRAY_BUFFER, store.z_facing_unit_square_geometry.instanced_buffer);
	cursor = setup_instance_attributes(cursor, Instance);

	render_instanced(store.z_facing_unit_square_geometry, *store.particle_shader, instances.count);
}

render_skybox :: (scene: Scene.Scene) {
	store := scene.store;
	set_uniform(*store.skybox_shader, "skybox", store.skybox_ski, 0);
	render(store.skybox_geometry, store.skybox_shader);
}

render_flags :: (scene: Scene.Scene, shaders: Shaders) {
	store := scene.store;
	set_uniform(shaders.textured_shader, "texture_sampler", store.vehicle_colormap, 0);
	for * scene.flags {
		M := M4f.translate(it.position);
		if it.activated_juice_t > 0 {
			R := axis_angle(
				V3f.{ 0, 0, 1}, it.activated_juice_t * 3.1415926 * 2.0 * 5.0
			);
			S := scale_matrix(1.0 + ease_up_and_back(1.0 - it.activated_juice_t));

			M = M * to_rotation_matrix(R) * S;
		}
		if !it.activated && it.count_changed_juice_t > 0 {
			M = M * scale_matrix(1.0 + ease_up_and_back(1.0 - it.count_changed_juice_t));
		}

		set_uniform(shaders.textured_shader, "M", M);

		if it.activated && it.activated_juice_t < 0.5 {
			render(store.flag_geometry, shaders.textured_shader);
		} else {
			render(store.flag_down_geometry, shaders.textured_shader);

			needed := ceil(scene.players.count / 1.5).(int);
			left := needed - it.last_player_count;
			if left > 0 {
				M := M4f.translate(it.position + V3f.{ 0, 0, 2 });
				if it.count_changed_juice_t > 0 {
					M = M * scale_matrix(
						1.0 + ease_up_and_back(1.0 - it.count_changed_juice_t) * 0.5
					);
				}
				set_uniform(shaders.textured_shader, "M", M);

				geom := Store.get_number_geometry(store, left);
				if geom
					render(geom, shaders.textured_shader);
			}
		}
	}
}

render_keys :: (scene: Scene.Scene, shaders: Shaders) {
	store := scene.store;
	set_uniform(shaders.textured_shader, "texture_sampler", store.vehicle_colormap, 0);
	for * scene.keys {
		p := it.client.position;
		if it.holder >= 0
			p.z += 1;

		M := M4f.translate(p);
		set_uniform(shaders.textured_shader, "M", M);
		render(store.key_geometry, shaders.textured_shader);
	}
}

render_tombstones :: (scene: Scene.Scene, shaders: Shaders) {
	store := scene.store;
	set_uniform(shaders.textured_shader, "texture_sampler", store.vehicle_colormap, 0);
	for * scene.tombstones {
		M := M4f.translate(it.position);
		set_uniform(shaders.textured_shader, "M", M);
		render(store.tombstone_geometry, shaders.textured_shader);
	}
}

render_gates :: (scene: Scene.Scene, shaders: Shaders) {
	store := scene.store;
	set_uniform(shaders.textured_shader, "texture_sampler", store.vehicle_colormap, 0);
	for * scene.gates {
		R := to_rotation_matrix(from_unit_vectors(V3f.{ 1, 0, 0 }, it.direction));

		M := M4f.translate(it.position) * R;
		set_uniform(shaders.textured_shader, "M", M);

		if it.is_end {
			if it.is_closed {
				render(store.gate_finish_close_geometry, shaders.textured_shader);
			} else {
				render(store.gate_finish_geometry, shaders.textured_shader);
			}
		} else {
			if it.is_closed {
				render(store.gate_close_geometry, shaders.textured_shader);
			} else {
				render(store.gate_geometry, shaders.textured_shader);
			}
		}
	}
}

render_standin :: (scene: Scene.Scene, shaders: Shaders) {
	store := scene.store;
	for * scene.stand_in {
		M := M4f.translate(it.position);
		M = M * to_rotation_matrix(it.orientation);
		set_uniform(shaders.textured_shader, "M", M);
		geometry := Store.get_geometry(scene.store, it.model_id);
		if !geometry {
			geometry = *store.spirit_geometry;
		}
		set_uniform(shaders.textured_shader, "texture_sampler", store.vehicle_colormap, 0);
		render(geometry.*, shaders.textured_shader);
	}
}

render_players :: (scene: Scene.Scene, shaders: Shaders) {
	store := scene.store;
	colors :: V3f.[
		V3f.{ 1.0, 0.8, 0.8 },
		V3f.{ 0.8, 1.0, 0.8 },
		V3f.{ 0.8, 0.8, 1.0 },
		V3f.{ 1.0, 1.0, 0.8 },
		V3f.{ 1.0, 0.8, 1.0 },
		V3f.{ 0.8, 1.0, 1.0 },
		V3f.{ 1.0, 1.0, 1.0 }
	];
	set_uniform(shaders.textured_shader, "texture_offset", V2f.{ 0, 0 });
	for * scene.players {
		if !it.server.dead {
			M := M4f.identity();

			q := from_unit_vectors(V3f.{ 1, 0, 0 }, it.client.direction);
			M = to_rotation_matrix(q);

			M = M4f.translate(it.client.position) * M;

			set_uniform(shaders.textured_shader, "M", M);
			// set_uniform(*scene.texture_shader, "tint", colors[it.id % colors.count]);
			set_uniform(shaders.textured_shader, "texture_sampler", store.vehicle_colormap, 0);

			geometry := Store.get_geometry(scene.store, it.server.model_id);
			if !geometry {
				geometry = *store.spirit_geometry;
			}

			render(geometry.*, shaders.textured_shader);
		}
	}
	// set_uniform(*scene.model_shader, "tint", V3f.{ 1, 1, 1 });
}

render_shurikens :: (scene: Scene.Scene, shaders: Shaders) {
	store := scene.store;
	instanced := NewArray(
		scene.shurikens.count, Geometry.Instance_Data, initialized = false,, temp
	);

	for * scene.shurikens {
		M := Scene.compute_moving_frame_server_world_matrix(
			scene, Scene.find_by_frame_id(scene, it.frame_id)
		);
		M *= M4f.translate(it.server.position) * to_rotation_matrix(
			axis_angle(V3f.{ 0, 0, 1 }, it.client.theta)
		);
		instance := *instanced[it_index];
		instance.kind = -1;
		instance.M = M;
	}

	add_instance(*store.shuriken_geometry, .{
		data = xx instanced.data,
		count = instanced.count * size_of(Geometry.Instance_Data)
	});

	enable_instanced_attributes(3);
	render_instanced(store.shuriken_geometry, shaders.instanced_shader, instanced.count);
}

render_skulls :: (scene: Scene.Scene, shaders: Shaders) {
	store := scene.store;
	instanced := NewArray(
		scene.skulls.count, Geometry.Instance_Data, initialized = false,, temp
	);

	for * skull: scene.skulls {
		instance := *instanced[it_index];
		instance.kind = -1;
		instance.M = Scene.compute_skull_matrix(scene, skull);
	}

	add_instance(*store.skull_geometry, .{
		data = xx instanced.data,
		count = instanced.count * size_of(Geometry.Instance_Data)
	});

	enable_instanced_attributes(3);
	render_instanced(store.skull_geometry, shaders.instanced_shader, instanced.count);
}

render_terrain_props :: (scene: Scene.Scene, props: [] Scene.Prop, shaders: Shaders) {
	store := scene.store;
	set_uniform(*store.instanced_texture_shader, "colormap", store.prop_colormap, 0);

	max_id := 0;
	for props
		if it.id > max_id
			max_id = it.id;


	Instance :: struct {
		M: M4f;
	};

	instanced := NewArray(props.count, Instance, initialized = false,, temp);
	for prop_id: 0..max_id {
		geometry := Store.get_prop(store, xx prop_id);
		if !geometry
			continue;

		instanced.count = 0;

		for props {
			if it.id != prop_id
				continue;
			
			instanced.count += 1;
			instanced[instanced.count - 1].M = it.M;
		}
		if instanced.count == 0
			continue;

		add_instance(geometry, .{
			data = xx instanced.data,
			count = instanced.count * size_of(Instance)
		});

		context.rhi.glBindVertexArray(geometry.gpu_object);
		context.rhi.glBindBuffer(GL_ARRAY_BUFFER, geometry.gpu_buffer);
		cursor := setup_vertex_attributes(0, Geometry.Vertex_Data);
		context.rhi.glBindBuffer(GL_ARRAY_BUFFER, geometry.instanced_buffer);
		cursor = setup_instance_attributes(cursor, Instance);
		render_instanced(geometry, shaders.instanced_texture_shader, instanced.count);
	}

}

render_terrain :: (scene: Scene.Scene, terrain: *Scene.Terrain, shaders: Shaders) {
	store := scene.store;
	if terrain.tiles_count.x <= 0 || terrain.tiles_count.y <= 0
		return;

	render_terrain_props(scene, scene.props, shaders);

	Instance :: struct {
		M: M4f;
		kind: u32; @int
	};

	instanced := NewArray(
		terrain.tiles.count, Instance, initialized = false,, temp
	);

	set_uniform(shaders.tile_shader, "atlas", store.tile_atlas, 0);
	playerPos := V3f.{ 0, 0, 0 };
	{
		for scene.players {
			if it.id == scene.controlled_player_id {
				playerPos = it.client.position;
				break;
			}
		}
	}
	set_uniform(shaders.tile_shader, "playerPos", playerPos);

	for * tile: terrain.tiles {
		x := it_index % terrain.tiles_count.x;
		y := it_index / terrain.tiles_count.x;

		instance := *instanced[it_index];
		instance.kind = xx tile.kind;
		pos := V3f.{ x.(float), y.(float), 0 };
		pos -= v3(scene.camera_min, 0.0);
		instance.M = M4f.translate(pos);
	}

	add_instance(*store.tile_geometry, .{
		data = xx instanced.data,
		count = terrain.tiles.count * size_of(Geometry.Instance_Data)
	});

	context.rhi.glBindVertexArray(store.tile_geometry.gpu_object);
	context.rhi.glBindBuffer(GL_ARRAY_BUFFER, store.tile_geometry.gpu_buffer);
	cursor := setup_vertex_attributes(0, Geometry.Vertex_Data);
	context.rhi.glBindBuffer(GL_ARRAY_BUFFER, store.tile_geometry.instanced_buffer);
	setup_instance_attributes(cursor, Instance);
	render_instanced(store.tile_geometry, shaders.tile_shader, terrain.tiles.count);
}
