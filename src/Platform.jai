#import "Algebra";

#scope_export



Key :: enum u32 {
	None :: 0
	Z;
	Q;
	S;
	D;
	Up;
	Left;
	Down;
	Right;

	M_Left;
	M_Right;
	M_Middle;
}

Frame_Info :: struct {
	key_pressed: [32] Key;
	key_released: [32] Key;

	mouse_position: V2f;
	window_size: V2f;
	quit := false;
}

get_frame_info :: () -> Frame_Info;

RHI_proc :: struct {
	glGetIntegerv: (pname: GLenum, data: *GLint) #c_call;
	glActiveTexture : (texture: GLenum) #c_call;
	glDisable : (cap: GLenum) #c_call;
	glEnable : (cap: GLenum) #c_call;
	glBlendEquation : (mode: GLenum) #c_call;
	glBlendFunc : (sfactor: GLenum, dfactor: GLenum) #c_call;
	glPolygonMode : (face: GLenum, mode: GLenum) #c_call;
	glViewport : (x: GLint, y: GLint, width: GLsizei, height: GLsizei) #c_call;
	glUseProgram : (program: GLuint) #c_call;
	glUniform1f : (location: GLint, v0: GLfloat) #c_call;
	glUniform2f : (location: GLint, v0: GLfloat, v1: GLfloat) #c_call;
	glUniform3f : (location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat) #c_call;
	glUniform4f : (location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat, v3: GLfloat) #c_call;
	glUniform1i : (location: GLint, v0: GLint) #c_call;
	glUniform2i : (location: GLint, v0: GLint, v1: GLint) #c_call;
	glUniform3i : (location: GLint, v0: GLint, v1: GLint, v2: GLint) #c_call;
	glUniform4i : (location: GLint, v0: GLint, v1: GLint, v2: GLint, v3: GLint) #c_call;
	glUniform1fv : (location: GLint, count: GLsizei, value: *GLfloat) #c_call;
	glUniform2fv : (location: GLint, count: GLsizei, value: *GLfloat) #c_call;
	glUniform3fv : (location: GLint, count: GLsizei, value: *GLfloat) #c_call;
	glUniform4fv : (location: GLint, count: GLsizei, value: *GLfloat) #c_call;
	glUniform1iv : (location: GLint, count: GLsizei, value: *GLint) #c_call;
	glUniform2iv : (location: GLint, count: GLsizei, value: *GLint) #c_call;
	glUniform3iv : (location: GLint, count: GLsizei, value: *GLint) #c_call;
	glUniform4iv : (location: GLint, count: GLsizei, value: *GLint) #c_call;
	glUniformMatrix2fv : (location: GLint, count: GLsizei, transpose: GLboolean, value: *GLfloat) #c_call;
	glUniformMatrix3fv : (location: GLint, count: GLsizei, transpose: GLboolean, value: *GLfloat) #c_call;
	glUniformMatrix4fv : (location: GLint, count: GLsizei, transpose: GLboolean, value: *GLfloat) #c_call;
	glValidateProgram : (program: GLuint) #c_call;
	glVertexAttrib1d : (index: GLuint, x: GLdouble) #c_call;
	glVertexAttrib1dv : (index: GLuint, v: *GLdouble) #c_call;
	glVertexAttrib1f : (index: GLuint, x: GLfloat) #c_call;
	glVertexAttrib1fv : (index: GLuint, v: *GLfloat) #c_call;
	glVertexAttrib1s : (index: GLuint, x: GLshort) #c_call;
	glVertexAttrib1sv : (index: GLuint, v: *GLshort) #c_call;
	glVertexAttrib2d : (index: GLuint, x: GLdouble, y: GLdouble) #c_call;
	glVertexAttrib2dv : (index: GLuint, v: *GLdouble) #c_call;
	glVertexAttrib2f : (index: GLuint, x: GLfloat, y: GLfloat) #c_call;
	glVertexAttrib2fv : (index: GLuint, v: *GLfloat) #c_call;
	glVertexAttrib2s : (index: GLuint, x: GLshort, y: GLshort) #c_call;
	glVertexAttrib2sv : (index: GLuint, v: *GLshort) #c_call;
	glVertexAttrib3d : (index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble) #c_call;
	glVertexAttrib3dv : (index: GLuint, v: *GLdouble) #c_call;
	glVertexAttrib3f : (index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat) #c_call;
	glVertexAttrib3fv : (index: GLuint, v: *GLfloat) #c_call;
	glVertexAttrib3s : (index: GLuint, x: GLshort, y: GLshort, z: GLshort) #c_call;
	glVertexAttrib3sv : (index: GLuint, v: *GLshort) #c_call;
	glVertexAttrib4Nbv : (index: GLuint, v: *GLbyte) #c_call;
	glVertexAttrib4Niv : (index: GLuint, v: *GLint) #c_call;
	glVertexAttrib4Nsv : (index: GLuint, v: *GLshort) #c_call;
	glVertexAttrib4Nub : (index: GLuint, x: GLubyte, y: GLubyte, z: GLubyte, w: GLubyte) #c_call;
	glVertexAttrib4Nubv : (index: GLuint, v: *GLubyte) #c_call;
	glVertexAttrib4Nuiv : (index: GLuint, v: *GLuint) #c_call;
	glVertexAttrib4Nusv : (index: GLuint, v: *GLushort) #c_call;
	glVertexAttrib4bv : (index: GLuint, v: *GLbyte) #c_call;
	glVertexAttrib4d : (index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble) #c_call;
	glVertexAttrib4dv : (index: GLuint, v: *GLdouble) #c_call;
	glVertexAttrib4f : (index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat) #c_call;
	glVertexAttrib4fv : (index: GLuint, v: *GLfloat) #c_call;
	glVertexAttrib4iv : (index: GLuint, v: *GLint) #c_call;
	glVertexAttrib4s : (index: GLuint, x: GLshort, y: GLshort, z: GLshort, w: GLshort) #c_call;
	glVertexAttrib4sv : (index: GLuint, v: *GLshort) #c_call;
	glVertexAttrib4ubv : (index: GLuint, v: *GLubyte) #c_call;
	glVertexAttrib4uiv : (index: GLuint, v: *GLuint) #c_call;
	glVertexAttrib4usv : (index: GLuint, v: *GLushort) #c_call;
	glBindVertexArray : (array: GLuint) #c_call;
	glBindSampler : (unit: GLuint, sampler: GLuint) #c_call;
	glBindBuffer : (target: GLenum, buffer: GLuint) #c_call;
	glBufferData : (target: GLenum, size: GLsizeiptr, data: *void, usage: GLenum) #c_call;
	glBindTexture : (target: GLenum, texture: GLuint) #c_call;
	glScissor : (x: GLint, y: GLint, width: GLsizei, height: GLsizei) #c_call;
	glDrawElements : (mode: GLenum, count: GLsizei, type: GLenum, indices: *void) #c_call;
	glBindSampler : (unit: GLuint, sampler: GLuint) #c_call;
	glActiveTexture : (texture: GLenum) #c_call;
	glBlendEquationSeparate : (modeRGB: GLenum, modeAlpha: GLenum) #c_call;
	glBlendFuncSeparate : (sfactorRGB: GLenum, dfactorRGB: GLenum, sfactorAlpha: GLenum, dfactorAlpha: GLenum) #c_call;
	glGenTextures : (n: GLsizei, textures: *GLuint) #c_call;
	glTexParameteri : (target: GLenum, pname: GLenum, param: GLint) #c_call;
	glTexImage2D : (target: GLenum, level: GLint, internalformat: GLint, width: GLsizei, height: GLsizei, border: GLint, format: GLenum, type: GLenum, pixels: *void) #c_call;
	glCreateProgram : () -> GLuint #c_call;
	glCreateShader : (type: GLenum) -> GLuint #c_call;
	glCompileShader : (shader: GLuint) #c_call;
	glAttachShader : (program: GLuint, shader: GLuint) #c_call;
	glLinkProgram : (program: GLuint) #c_call;
	glGetUniformLocation : (program: GLuint, name: *GLchar) -> GLint #c_call;
	glGetAttribLocation : (program: GLuint, name: *GLchar) -> GLint #c_call;
	glGenBuffers : (n: GLsizei, buffers: *GLuint) #c_call;
	glGenVertexArrays : (n: GLsizei, arrays: *GLuint) #c_call;
	glEnableVertexAttribArray : (index: GLuint) #c_call;
	glVertexAttribPointer : (index: GLuint, size: GLint, type: GLenum, normalized: GLboolean, stride: GLsizei, pointer: *void) #c_call;
	glDeleteTextures : (n: GLsizei, textures: *GLuint) #c_call;
	glIsEnabled : (cap: GLenum) -> GLboolean #c_call;
}
