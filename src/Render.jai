#import "GL";
#import "Basic";
#import "Flat_Pool";
#import "String";
#import "Algebra";

#scope_export

Shader :: struct {
	vertex_code: string;
	fragment_code: string;

	vertex_shader: GLuint;
	fragment_shader: GLuint;
	program: GLuint;

	allocator: Allocator;

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
	gl.glUseProgram(shader.program);
	loc := gl.glGetUniformLocation(shader.program, name.data);
	if loc < 0 {
		print("Uniform % not found in shader program.\n", name);
	}

	if T == M4f {
		gl.glUniformMatrix4fv(loc, 1, GL_FALSE, value.data.data);
	}
}

compile :: (shader: *Shader) {
	status: GLint;
	// Compile vertex shader
	vertex_shader := gl.glCreateShader(GL_VERTEX_SHADER);
	x := cast(s32)(shader.vertex_code.count);
	gl.glShaderSource(vertex_shader, 1, *shader.vertex_code.data, *x);
	gl.glCompileShader(vertex_shader);
	status = 0;
	gl.glGetShaderiv(vertex_shader, GL_COMPILE_STATUS, *status);
	if status == 0 {
		buffer := NewArray(1024, u8, false,, temp);
		written: u32;
		gl.glGetShaderInfoLog(vertex_shader, xx buffer.count, *written, buffer.data);
		error_msg: string = .{ data =buffer.data, count = written };

		print("Vertex shader compilation failed: %\n", error_msg);
		gl.glDeleteShader(vertex_shader);
		return;
	}
	shader.vertex_shader = vertex_shader;

	// Compile fragment shader
	fragment_shader := gl.glCreateShader(GL_FRAGMENT_SHADER);
	x = cast(s32)(shader.fragment_code.count);
	gl.glShaderSource(fragment_shader, 1, *shader.fragment_code.data, *x);
	gl.glCompileShader(fragment_shader);
	status = 0;
	gl.glGetShaderiv(fragment_shader, GL_COMPILE_STATUS, *status);
	if status == 0 {
		buffer := NewArray(1024, u8, false,, temp);
		written: u32;
		gl.glGetShaderInfoLog(vertex_shader, xx buffer.count, *written, buffer.data);
		error_msg: string = .{ data =buffer.data, count = written };

		print("Fragment shader compilation failed: %\n", error_msg);
		gl.glDeleteShader(fragment_shader);
		gl.glDeleteShader(vertex_shader);
		return;
	}
	shader.fragment_shader = fragment_shader;

	// Create shader program
	shader_program := gl.glCreateProgram();
	gl.glAttachShader(shader_program, shader.vertex_shader);
	gl.glAttachShader(shader_program, shader.fragment_shader);
	gl.glLinkProgram(shader_program);
	status = 0;
	gl.glGetProgramiv(shader_program, GL_LINK_STATUS, *status);
	if status == 0 {
		buffer := NewArray(1024, u8, false,, temp);
		written: u32;
		gl.glGetProgramInfoLog(vertex_shader, xx buffer.count, *written, buffer.data);
		error_msg: string = .{ data =buffer.data, count = buffer.count };
		print("Shader program linking failed: %\n", error_msg);
		gl.glDeleteProgram(shader_program);
		gl.glDeleteShader(fragment_shader);
		gl.glDeleteShader(vertex_shader);
		return;
	}

	shader.program = shader_program;
}

Geometry :: struct {
	allocator: Allocator;

	Vertex_Data :: struct {
		pos: V3f;
		nor: V3f;
	}

	cpu_buffer: [] Vertex_Data;
	gpu_object: GLuint = 0;
	gpu_buffer: GLuint = 0;

	new :: (allocator: Allocator) -> Geometry {
		geometry: Geometry;
		geometry.allocator = allocator;
		return geometry;
	}

	make_from_obj :: (allocator: Allocator, obj: string) -> Geometry {
		geometry := Geometry.new(allocator);

		vertices: [..] V3f;
		vertices.allocator = temp;

		normals: [..] V3f;
		normals.allocator = temp;

		Obj_Face :: struct {
			positions: [3] u32;
			normals: [3] u32;
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

			a: u32;
			b: u32;
			c: u32;
			d: u32;
			e: u32;
			f: u32;

			if scan2(line, "v % % %", *x, *y, *z) {
				array_add(*vertices, .{ x = x, y = y, z = z });
			}
			if scan2(line, "vn % % %", *x, *y, *z) {
				array_add(*normals, .{ x = x, y = y, z = z });
			}
			if scan2(line, "f %//% %//% %//%", *a, *b, *c, *d, *e, *f) {
				face: Obj_Face;
				face.positions[0] = cast(u32)(a - 1);
				face.positions[1] = cast(u32)(c - 1);
				face.positions[2] = cast(u32)(e - 1);
				face.normals[0] = cast(u32)(b - 1);
				face.normals[1] = cast(u32)(d - 1);
				face.normals[2] = cast(u32)(f - 1);
				array_add(*faces, face);
			}
		}

		geometry.cpu_buffer = NewArray(
			faces.count * 3, Geometry.Vertex_Data, false,, geometry.allocator
		);

		for faces {
			geometry.cpu_buffer[it_index * 3 + 0].pos = vertices[it.positions[0]];
			geometry.cpu_buffer[it_index * 3 + 0].nor = normals[it.normals[0]];

			geometry.cpu_buffer[it_index * 3 + 1].pos = vertices[it.positions[1]];
			geometry.cpu_buffer[it_index * 3 + 1].nor = normals[it.normals[1]];

			geometry.cpu_buffer[it_index * 3 + 2].pos = vertices[it.positions[2]];
			geometry.cpu_buffer[it_index * 3 + 2].nor = normals[it.normals[2]];
		}

		upload(*geometry);

		return geometry;
	}
}

upload :: (geometry: *Geometry) {
	// If no object is assigned, create it.
	if geometry.gpu_object == 0 {
		gl.glGenVertexArrays(1, *geometry.gpu_object);
	}
	gl.glBindVertexArray(geometry.gpu_object);

	// If the buffer is null, create it.
	if geometry.gpu_buffer == 0 {
		gl.glGenBuffers(1, *geometry.gpu_buffer);
	}

	gl.glBindBuffer(GL_ARRAY_BUFFER, geometry.gpu_buffer);
	gl.glBufferData(
		GL_ARRAY_BUFFER,
		geometry.cpu_buffer.count * size_of(Geometry.Vertex_Data),
		geometry.cpu_buffer.data,
		GL_STATIC_DRAW
	);

	gl.glEnableVertexAttribArray(0); // Position
	gl.glVertexAttribPointer(
		0, 3, GL_FLOAT, GL_FALSE,
		size_of(Geometry.Vertex_Data), xx 0
	);

	gl.glEnableVertexAttribArray(1); // Normal
	gl.glVertexAttribPointer(
		1, 3, GL_FLOAT, GL_FALSE,
		size_of(Geometry.Vertex_Data), xx size_of(V3f)
	);

}

render :: (geometry: Geometry, shader: Shader) {
	gl.glUseProgram(shader.program);
	gl.glBindVertexArray(geometry.gpu_object);
	gl.glDrawArrays(GL_TRIANGLES, 0, xx geometry.cpu_buffer.count);
}


