#scope_export

#import "Math";

// Column vector
V3 :: struct(T: Type) {
	x: T = 0;
	y: T = 0;
	z: T = 0;
}

V3d :: V3(float64);
V3f :: V3(float32);

V4 :: struct(T: Type) {
	x: T = 0;
	y: T = 0;
	z: T = 0;
	w: T = 0;
}

V4d :: V4(float64);
V4f :: V4(float32);

V2 :: struct(T: Type) {
	x: T = 0;
	y: T = 0;
}

V2d :: V2(float64);
V2f :: V2(float32);

// Column major
M4 :: struct(T: Type) {
	data: [16] T;

	identity :: () -> M4(T) {
		M: M4(T);
		for * M.data
			it.* = 0;
		M.data[0 + 0 * 4] = 1;
		M.data[1 + 1 * 4] = 1;
		M.data[2 + 2 * 4] = 1;
		M.data[3 + 3 * 4] = 1;
		return M;
	}

	translate :: (pos: V3(T)) -> M4(T) {
		M := M4(T).identity();
		M.data[0 + 3 * 4] = pos.x;
		M.data[1 + 3 * 4] = pos.y;
		M.data[2 + 3 * 4] = pos.z;
		return M;
	}

	by_cols :: (a: V4($T), b: V4(T), c: V4(T), d: V4(T)) -> M4(T) {
		M: M4(T);
		M.data[0 + 0 * 4] = a.x;
		M.data[1 + 0 * 4] = a.y;
		M.data[2 + 0 * 4] = a.z;
		M.data[3 + 0 * 4] = a.w;

		M.data[0 + 1 * 4] = b.x;
		M.data[1 + 1 * 4] = b.y;
		M.data[2 + 1 * 4] = b.z;
		M.data[3 + 1 * 4] = b.w;

		M.data[0 + 2 * 4] = c.x;
		M.data[1 + 2 * 4] = c.y;
		M.data[2 + 2 * 4] = c.z;
		M.data[3 + 2 * 4] = c.w;

		M.data[0 + 3 * 4] = d.x;
		M.data[1 + 3 * 4] = d.y;
		M.data[2 + 3 * 4] = d.z;
		M.data[3 + 3 * 4] = d.w;

		return M;
	}

	by_rows :: (a: V4($T), b: V4(T), c: V4(T), d: V4(T)) -> M4(T) {
		M: M4(T);
		M.data[0 + 0 * 4] = a.x;
		M.data[0 + 1 * 4] = a.y;
		M.data[0 + 2 * 4] = a.z;
		M.data[0 + 3 * 4] = a.w;

		M.data[1 + 0 * 4] = b.x;
		M.data[1 + 1 * 4] = b.y;
		M.data[1 + 2 * 4] = b.z;
		M.data[1 + 3 * 4] = b.w;

		M.data[2 + 0 * 4] = c.x;
		M.data[2 + 1 * 4] = c.y;
		M.data[2 + 2 * 4] = c.z;
		M.data[2 + 3 * 4] = c.w;

		M.data[3 + 0 * 4] = d.x;
		M.data[3 + 1 * 4] = d.y;
		M.data[3 + 2 * 4] = d.z;
		M.data[3 + 3 * 4] = d.w;

		return M;
	}

	col :: (M: M4($T), idx: int) -> V4(T) {
		v: V4(T);
		v.x = M.data[0 + idx * 4];
		v.y = M.data[1 + idx * 4];
		v.z = M.data[2 + idx * 4];
		v.w = M.data[3 + idx * 4];
		return v;
	}

	row :: (M: M4($T), idx: int) -> V4(T) {
		v: V4(T);
		v.x = M.data[idx + 0 * 4];
		v.y = M.data[idx + 1 * 4];
		v.z = M.data[idx + 2 * 4];
		v.w = M.data[idx + 3 * 4];
		return v;
	}
}

M4d :: M4(float64);
M4f :: M4(float32);

Q :: struct(T: Type) {
	x: T = 0;
	y: T = 0;
	z: T = 0;
	w: T = 1;
}

Qd :: Q(float64);
Qf :: Q(float32);


axis_angle :: (axis: V3($T), angle: T) -> Q(T) {
	s := sin(angle / 2);
	return .{
		axis.x * s,
		axis.y * s,
		axis.z * s,
		cos(angle / 2)
	};
}

from_unit_vectors :: (a: V3($T), b: V3(T)) -> Q(T) {
	if (a.x == -b.x && a.y == -b.y && a.z == -b.z) {
		axis := normalize(cross(V3f.{1, 0, 0}, a));
		return axis_angle(axis, PI);
	}
	half := normalize(a + b);
	v := cross(a, half);
	return .{ v.x, v.y, v.z, dot(a, half) };
}

to_rotation_matrix :: (q: Q($T)) -> M4(T) {
	x := q * V3(T).{1, 0, 0};
	y := q * V3(T).{0, 1, 0};
	z := q * V3(T).{0, 0, 1};
	return M4f.by_rows(
		V4f.{ x.x, y.x, z.x, 0.0 },
		V4f.{ x.y, y.y, z.y, 0.0 },
		V4f.{ x.z, y.z, z.z, 0.0 },
		V4f.{ 0.0, 0.0, 0.0, 1.0 }
	);
}

DEG_RAD :: PI / 180;
RAD_DEG :: 180 / PI;

operator * :: (v: V3($T), f: T) -> V3(T) #symmetric {
	return .{ v.x * f, v.y * f, v.z * f };
}

operator * :: (q: Q($T), v: V3(T)) -> V3(T) {
	u := V3f.{q.x, q.y, q.z};
	s := q.w;

	return 2 * dot(u, v) * u
		+ (s * s - dot(u, u)) * v
		+ 2 * s * cross(u, v);
}

operator - :: (a: V3($T), b: V3(T)) -> V3(T) #symmetric {
	return .{ a.x - b.x, a.y - b.y, a.z - b.z };
}

operator + :: (a: V3($T), b: V3(T)) -> V3(T) #symmetric {
	return .{ a.x + b.x, a.y + b.y, a.z + b.z };
}

normalize :: (a: V3($T)) -> V3(T) {
	l := sqrt(a.x * a.x + a.y * a.y + a.z * a.z);
	if l == 0
		return .{ 0, 0, 0 };
	return .{ a.x / l, a.y / l, a.z / l };
}

cross :: (a: V3($T), b: V3(T)) -> V3(T) {
	return .{
		a.y * b.z - a.z * b.y,
		a.z * b.x - a.x * b.z,
		a.x * b.y - a.y * b.x
	};
}

dot :: (a: V3($T), b: V3(T)) -> T {
	return a.x * b.x + a.y * b.y + a.z * b.z;
}
dot :: (a: V4($T), b: V4(T)) -> T {
	return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;
}

operator * :: (A: M4($T), B: M4(T)) -> M4(T) {
	C: M4(T);
	for i: 0..3
	for j: 0..3
	for k: 0..3 {
		C.data[i * 4 + j] += A.data[k * 4 + j] * B.data[i * 4 + k];
	}
	return C;
}

operator * :: (M: M4($T), v4: V4(T)) -> V4(T) {
	v: V4(T);
	v.x = dot(M.row(M, 0), v4);
	v.y = dot(M.row(M, 1), v4);
	v.z = dot(M.row(M, 2), v4);
	v.w = dot(M.row(M, 3), v4);
	return v;
}

v3 :: (v4: V4($T)) -> V3(T) {
	return .{ v4.x, v4.y, v4.z };
}

v4 :: (v3: V3($T), w := 1.0) -> V4(T) {
	return .{ v3.x, v3.y, v3.z, w };
}

inverse :: (mm: M4($T)) -> M4(T) {
	minv: M4(T);
	inv := minv.data.data;
	m := mm.data.data;

	inv[0] = m[5]  * m[10] * m[15] -
				m[5]  * m[11] * m[14] -
				m[9]  * m[6]  * m[15] +
				m[9]  * m[7]  * m[14] +
				m[13] * m[6]  * m[11] -
				m[13] * m[7]  * m[10];

	inv[4] = -m[4]  * m[10] * m[15] +
				m[4]  * m[11] * m[14] +
				m[8]  * m[6]  * m[15] -
				m[8]  * m[7]  * m[14] -
				m[12] * m[6]  * m[11] +
				m[12] * m[7]  * m[10];

	inv[8] = m[4]  * m[9] * m[15] -
				m[4]  * m[11] * m[13] -
				m[8]  * m[5] * m[15] +
				m[8]  * m[7] * m[13] +
				m[12] * m[5] * m[11] -
				m[12] * m[7] * m[9];

	inv[12] = -m[4]  * m[9] * m[14] +
				m[4]  * m[10] * m[13] +
				m[8]  * m[5] * m[14] -
				m[8]  * m[6] * m[13] -
				m[12] * m[5] * m[10] +
				m[12] * m[6] * m[9];

	inv[1] = -m[1]  * m[10] * m[15] +
				m[1]  * m[11] * m[14] +
				m[9]  * m[2] * m[15] -
				m[9]  * m[3] * m[14] -
				m[13] * m[2] * m[11] +
				m[13] * m[3] * m[10];

	inv[5] = m[0]  * m[10] * m[15] -
				m[0]  * m[11] * m[14] -
				m[8]  * m[2] * m[15] +
				m[8]  * m[3] * m[14] +
				m[12] * m[2] * m[11] -
				m[12] * m[3] * m[10];

	inv[9] = -m[0]  * m[9] * m[15] +
				m[0]  * m[11] * m[13] +
				m[8]  * m[1] * m[15] -
				m[8]  * m[3] * m[13] -
				m[12] * m[1] * m[11] +
				m[12] * m[3] * m[9];

	inv[13] = m[0]  * m[9] * m[14] -
				m[0]  * m[10] * m[13] -
				m[8]  * m[2] * m[13] +
				m[8]  * m[1] * m[14] +
				m[12] * m[1] * m[10] -
				m[12] * m[2] * m[9];

	inv[2] = m[1]  * m[6] * m[15] -
				m[1]  * m[7] * m[14] -
				m[5]  * m[2] * m[15] +
				m[5]  * m[3] * m[14] +
				m[13] * m[2] * m[7] -
				m[13] * m[3] * m[6];

	inv[6] = -m[0]  * m[6] * m[15] +
				m[0]  * m[7] * m[14] +
				m[4]  * m[2] * m[15] -
				m[4]  * m[3] * m[14] -
				m[12] * m[2] * m[7] +
				m[12] * m[3] * m[6];

	inv[10] = m[0]  * m[5] * m[15] -
				m[0]  * m[7] * m[13] -
				m[4]  * m[1] * m[15] +
				m[4]  * m[3] * m[13] +
				m[12] * m[1] * m[7] -
				m[12] * m[3] * m[5];

	inv[14] = -m[0]  * m[5] * m[14] +
				m[0]  * m[6] * m[13] +
				m[4]  * m[1] * m[14] -
				m[4]  * m[2] * m[13] -
				m[12] * m[1] * m[6] +
				m[12] * m[2] * m[5];

	inv[3] = -m[1] * m[6] * m[11] +
				m[1] * m[7] * m[10] +
				m[5] * m[2] * m[11] -
				m[5] * m[3] * m[10] -
				m[9] * m[2] * m[7] +
				m[9] * m[3] * m[6];

	inv[7] = m[0] * m[6] * m[11] -
				m[0] * m[7] * m[10] -
				m[4] * m[2] * m[11] +
				m[4] * m[3] * m[10] +
				m[8] * m[2] * m[7] -
				m[8] * m[3] * m[6];

	inv[11] = -m[0] * m[5] * m[11] +
				m[0] * m[7] * m[9] +
				m[4] * m[1] * m[11] -
				m[4] * m[3] * m[9] -
				m[8] * m[1] * m[7] +
				m[8] * m[3] * m[5];

	inv[15] = m[0] * m[5] * m[10] -
				m[0] * m[6] * m[9] -
				m[4] * m[1] * m[10] +
				m[4] * m[2] * m[9] +
				m[8] * m[1] * m[6] -
				m[8] * m[2] * m[5];

	det := m[0] * inv[0] + m[1] * inv[4] + m[2] * inv[8] + m[3] * m[12];
	if (det == 0)
		return .{};
	det = 1.0 / det;

	for i: 0..15
		inv[i] = inv[i] * det;

	return minv;
}

// Ray plane intersection
// Ray = (o, d)
// Plane centered at 0 and normal n
ray_plane :: (o: V3($T), d: V3(T), n: V3(T)) -> V3(T), bool {
	f := dot(n, d);
	if f == 0
		return .{ 0, 0, 0 }, false;
	t := dot(n, o) / f;
	if (t > 0)
		return .{ 0, 0, 0 }, false; // No intersection
	return o - d * t, true;
}
