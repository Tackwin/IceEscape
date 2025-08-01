#load "imgui_sdl_gl.jai"

#import "Algebra";

#scope_export

Camera :: struct {
	position: V3f;
	target:   V3f;

	fov  := 65.0;
	near := 1.0;
	far  := 100.0;
	aspect := 
}

perspective :: (camera: Camera) -> M4f {
	f := 1.0 / tan(camera.fov * DEG_RAD / 2);
	M: M4f = ---;
	M.data[0 + 0 * 4] = f / aspect;
	M.data[1 + 0 * 4] = 0;
	M.data[2 + 0 * 4] = 0;
	M.data[3 + 0 * 4] = 0;
	M.data[0 + 1 * 4] = 0;
	M.data[1 + 1 * 4] = f;
	M.data[2 + 1 * 4] = 0;
	M.data[3 + 1 * 4] = 0;
	M.data[0 + 2 * 4] = 0;
	M.data[1 + 2 * 4] = 0;
	M.data[2 + 2 * 4] = -(camera.far + camera.near) / (camera.far - camera.near);
	M.data[3 + 2 * 4] = -1;
	M.data[0 + 2 * 4] = 0;
	M.data[1 + 2 * 4] = 0;
	M.data[2 + 2 * 4] = -2 * (camera.far * camera.near) / (camera.far - camera.near);
	M.data[3 + 2 * 4] = 0;
	return M;
}

look_at :: (eye: V3f, target: V3f, up: V3f) -> M4f {
	M: M4f = ---;

	z := normalize(eye - target);
	x := normalize(cross(up, z));
	y := cross(z, x);
	m.m[0]  = x.x;
	m.m[1]  = y.x;
	m.m[2]  = z.x;
	m.m[3]  = 0;
	m.m[4]  = x.y;
	m.m[5]  = y.y;
	m.m[6]  = z.y;
	m.m[7]  = 0;
	m.m[8]  = x.z;
	m.m[9]  = y.z;
	m.m[10] = z.z;
	m.m[11] = 0;
	m.m[12] = -dot(eye, x);
	m.m[13] = -dot(eye, y);
	m.m[14] = -dot(eye, z);
	m.m[15] = 1.0f;
	return m;
}