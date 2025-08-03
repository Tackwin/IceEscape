#import "Basic";
#import "String";
#import "Algebra";
#import "Assets";
#import "Platform";
#import "Hash_Table";

#scope_export

Shader :: struct {
	vertex_code: string;
	fragment_code: string;

	vertex_shader: GLuint;
	fragment_shader: GLuint;
	program: GLuint;

	allocator: Allocator;

	locations: Table(string, int);

	new :: (allocator: Allocator) -> Shader {
		shader: Shader;
		shader.allocator = allocator;
		return shader;
	}

	make :: (allocator: Allocator, from_vertex_code: string, from_fragment_code: string) -> Shader {
		shader := Shader.new(allocator);

		shader.vertex_code.data =
			NewArray(from_vertex_code.count, u8, false,, shader.allocator).data;
		shader.vertex_code.count = from_vertex_code.count;
		shader.fragment_code.data =
			NewArray(from_fragment_code.count, u8, false,, shader.allocator).data;
		shader.fragment_code.count = from_fragment_code.count;

		memcpy(shader.vertex_code.data, from_vertex_code.data, shader.vertex_code.count);
		memcpy(shader.fragment_code.data, from_fragment_code.data, shader.fragment_code.count);

		compile(*shader);
		return shader;
	}
}

set_uniform :: (shader: Shader, name: string, value: $T) {
	context.rhi.glUseProgram(shader.program);

	found, loc := table_find_new(*shader.locations, name);
	if !found {
		loc = context.rhi.glGetUniformLocation(shader.program, name.data);
		table_add(*shader.locations, name, loc);
	}

	if loc < 0 {
		print("Uniform % not found in shader program.\n", name);
	}

	if T == M4f {
		context.rhi.glUniformMatrix4fv(xx loc, 1, GL_FALSE, value.data.data);
	}
}
set_uniform :: (shader: Shader, name: string, value: Texture, unit: int) {
	context.rhi.glUseProgram(shader.program);

	found, loc := table_find_new(*shader.locations, name);
	if !found {
		loc = context.rhi.glGetUniformLocation(shader.program, name.data);
		table_add(*shader.locations, name, loc);
	}

	if loc < 0 {
		print("Uniform % not found in shader program.\n", name);
	}
 
	context.rhi.glActiveTexture(xx (GL_TEXTURE0 + unit));
	context.rhi.glBindTexture(GL_TEXTURE_2D, value.id);
	context.rhi.glUniform1i(xx loc, xx unit);
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
		context.rhi.glGetShaderInfoLog(vertex_shader, xx buffer.count, *written, buffer.data);
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
		context.rhi.glGetProgramInfoLog(vertex_shader, xx buffer.count, *written, buffer.data);
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
	allocator: Allocator;

	Vertex_Data :: struct {
		pos: V3f;
		nor: V3f;
		tex: V2f;
	}

	cpu_buffer: [] Vertex_Data;
	gpu_object: GLuint = 0;
	gpu_buffer: GLuint = 0;

	new :: (allocator: Allocator) -> Geometry {
		geometry: Geometry;
		geometry.allocator = allocator;
		return geometry;
	}

	make_square :: (allocator: Allocator, v1: V3f, v2: V3f, v3: V3f, v4: V3f) -> Geometry {
		geometry := new(allocator);

		n := normalize(cross(v2 - v1, v3 - v1));

		geometry.cpu_buffer = NewArray(6, Geometry.Vertex_Data, false,, geometry.allocator);
		geometry.cpu_buffer[0] = .{ pos = v1, nor = n, tex = .{ 0, 0 } };
		geometry.cpu_buffer[1] = .{ pos = v2, nor = n, tex = .{ 1, 0 } };
		geometry.cpu_buffer[2] = .{ pos = v3, nor = n, tex = .{ 1, 1 } };
		geometry.cpu_buffer[3] = .{ pos = v1, nor = n, tex = .{ 0, 0 } };
		geometry.cpu_buffer[4] = .{ pos = v3, nor = n, tex = .{ 1, 1 } };
		geometry.cpu_buffer[5] = .{ pos = v4, nor = n, tex = .{ 0, 1 } };

		upload(*geometry);

		return geometry;
	}

	make_from_obj :: (allocator: Allocator, obj: string) -> Geometry {
		geometry := Geometry.new(allocator);

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

			x: float32;
			y: float32;
			z: float32;

			i: [9] u32;

			if scan2(line, "v % % %", *x, *y, *z) {
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
			faces.count * 3, Geometry.Vertex_Data, false,, geometry.allocator
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

render :: (geometry: Geometry, shader: Shader) {
	context.rhi.glUseProgram(shader.program);
	context.rhi.glBindVertexArray(geometry.gpu_object);
	context.rhi.glDrawArrays(GL_TRIANGLES, 0, xx geometry.cpu_buffer.count);
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

		upload(*texture, image.data);
		return texture;
	}
}
upload :: (texture: *Texture, data: [] u8) {
	context.rhi.glGenTextures(1, *texture.id);
	context.rhi.glBindTexture(GL_TEXTURE_2D, texture.id);
	context.rhi.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	context.rhi.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	context.rhi.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	context.rhi.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	context.rhi.glTexImage2D(
		GL_TEXTURE_2D, 0, GL_RGB8, texture.width, texture.height, 0,
		GL_RGB, GL_UNSIGNED_BYTE, data.data
	);
}
