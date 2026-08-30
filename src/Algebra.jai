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
V3f_MAX :: V3f.{ FLOAT32_MAX, FLOAT32_MAX, FLOAT32_MAX };

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
V2i :: V2(int);

AABB :: struct(T: Type) {
	min: V2(T);
	max: V2(T);
}
AABBf :: AABB(float32);
AABBd :: AABB(float64);

pos_size :: (pos: V2($T), size: V2(T)) -> AABB(T) {
	aabb: AABB(T);
	aabb.min = pos;
	aabb.max = pos + size;
	return aabb;
}
pos_size :: (px: $T, py: T, size: V2(T)) -> AABB(T) {
	aabb: AABB(T);
	aabb.min.x = px;
	aabb.min.y = py;
	aabb.max = aabb.min + size;
	return aabb;
}
pos_size :: (px: $T, py: T, sx: T, sy: T) -> AABB(T) {
	aabb: AABB(T);
	aabb.min.x = px;
	aabb.min.y = py;
	aabb.max.x = aabb.min.x + sx;
	aabb.max.y = aabb.min.y + sy;
	return aabb;
}
size :: (aabb: AABB($T)) -> V2(T) {
	return aabb.max - aabb.min;
}
pow :: (v: V3f, p: float) -> V3f {
	return .{
		pow(v.x, p),
		pow(v.y, p),
		pow(v.z, p)
	};
}
span_x :: (aabb: AABB($T), beg_x: T, end_x: T) -> AABB(T) {
	new_aabb := aabb;
	new_aabb.min.x = aabb.min.x + (aabb.max.x - aabb.min.x) * beg_x;
	new_aabb.max.x = aabb.min.x + (aabb.max.x - aabb.min.x) * end_x;
	return new_aabb;
}
move :: (_aabb: AABB($T), delta: V2(T)) -> AABB(T) {
	aabb := _aabb;
	aabb.min += delta;
	aabb.max += delta;
	return aabb;
}
center :: (aabb: AABB($T)) -> V2(T) {
	return (aabb.min + aabb.max) * 0.5;
}
width :: (aabb: AABB($T)) -> T {
	s := size(aabb);
	return s.x;
}
aabb_width :: width;
height :: (aabb: AABB($T)) -> T {
	s := size(aabb);
	return s.y;
}
aabb_height :: height;
top :: (aabb: AABB($T)) -> T {
	return aabb.min.y;
}
bottom :: (aabb: AABB($T)) -> T {
	return aabb.max.y;
}
uv :: (aabb: AABB($T), uv: V2(T)) -> T {
	return v2(
		(aabb.max - aabb.min).x * uv.x + aabb.min.x,
		(aabb.max - aabb.min).y * uv.y + aabb.min.y
	);
}
uv :: (aabb: AABB($T), uvx: T, uvy: T) -> T {
	return v2(
		(aabb.max - aabb.min).x * uvx + aabb.min.x,
		(aabb.max - aabb.min).y * uvy + aabb.min.y
	);
}
area :: (aabb: AABB($T)) -> T {
	s := size(aabb);
	return s.x * s.y;
}
aabb_union :: (A: AABB($T), B: AABB(T)) -> AABB(T) {
	return .{
		min = .{ min(A.min.x, B.min.x), min(A.min.y, B.min.y) },
		max = .{ max(A.max.x, B.max.x), max(A.max.y, B.max.y) }
	};
}
shrink :: (_aabb: AABB($T), amount: T) -> AABB(T) {
	aabb := _aabb;
	aabb.min.x += amount;
	aabb.min.y += amount;
	aabb.max.x -= amount;
	aabb.max.y -= amount;
	return aabb;
}
shrink :: (_aabb: AABB($T), amount: V2(T)) -> AABB(T) {
	aabb := _aabb;
	aabb.min.x += amount.x;
	aabb.min.y += amount.y;
	aabb.max.x -= amount.x;
	aabb.max.y -= amount.y;
	return aabb;
}
in :: (aabb: AABB($T), point: V2(T)) -> bool {
	return point.x >= aabb.min.x && point.x <= aabb.max.x &&
		   point.y >= aabb.min.y && point.y <= aabb.max.y;
}

abs :: (v: V3($T)) -> V3(T) {
	return .{ abs(v.x), abs(v.y), abs(v.z) };
}
abs :: (v: V2($T)) -> V2(T) {
	return .{ abs(v.x), abs(v.y) };
}
vmin :: (a: V3($T), b: V3(T)) -> V3(T) {
	return .{ min(a.x, b.x), min(a.y, b.y), min(a.z, b.z) };
}
vmax :: (a: V3($T), b: V3(T)) -> V3(T) {
	return .{ max(a.x, b.x), max(a.y, b.y), max(a.z, b.z) };
}
vmin :: (a: V2($T), b: V2(T)) -> V2(T) {
	return .{ min(a.x, b.x), min(a.y, b.y) };
}
vmax :: (a: V2($T), b: V2(T)) -> V2(T) {
	return .{ max(a.x, b.x), max(a.y, b.y) };
}

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

	translate :: (M: *M4(T), v:  V3(T)) {
		M.data[0 + 3 * 4] += v.x;
		M.data[1 + 3 * 4] += v.y;
		M.data[2 + 3 * 4] += v.z;
	}

	scale :: (M: *M4(T), s: V3(T)) {
		M.data[0 + 0 * 4] *= s.x;
		M.data[0 + 1 * 4] *= s.x;
		M.data[0 + 2 * 4] *= s.x;
		M.data[1 + 0 * 4] *= s.y;
		M.data[1 + 1 * 4] *= s.y;
		M.data[1 + 2 * 4] *= s.y;
		M.data[2 + 0 * 4] *= s.z;
		M.data[2 + 1 * 4] *= s.z;
		M.data[2 + 2 * 4] *= s.z;
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

	z_rotate :: (M: *M4($T), angle: T) {
		c := cos(angle);
		s := sin(angle);
		for i: 0..3 {
			x := M.data[i + 0 * 4];
			y := M.data[i + 1 * 4];
			M.data[i + 0 * 4] = x * c - y * s;
			M.data[i + 1 * 4] = x * s + y * c;
		}
	}

	z_rotate :: (M: *M4($T), cos_angle: T, sin_angle: T) {
		c := cos_angle;
		s := sin_angle;
		for i: 0..3 {
			x := M.data[i + 0 * 4];
			y := M.data[i + 1 * 4];
			M.data[i + 0 * 4] = x * c - y * s;
			M.data[i + 1 * 4] = x * s + y * c;
		}
	}
}

M4d :: M4(float64);
M4f :: M4(float32);

M3 :: struct(T: Type) {
	data: [9] T;

	identity :: () -> M3(T) {
		M: M3(T);
		for * M.data
			it.* = 0;
		M.data[0 + 0 * 3] = 1;
		M.data[1 + 1 * 3] = 1;
		M.data[2 + 2 * 3] = 1;
		return M;
	}

	by_rows :: (a: V3($T), b: V3(T), c: V3(T)) -> M3(T) {
		M: M3(T);
		M.data[0 + 0 * 3] = a.x;
		M.data[0 + 1 * 3] = a.y;
		M.data[0 + 2 * 3] = a.z;

		M.data[1 + 0 * 3] = b.x;
		M.data[1 + 1 * 3] = b.y;
		M.data[1 + 2 * 3] = b.z;

		M.data[2 + 0 * 3] = c.x;
		M.data[2 + 1 * 3] = c.y;
		M.data[2 + 2 * 3] = c.z;

		return M;
	}
}

M3d :: M3(float64);
M3f :: M3(float32);

Q :: struct(T: Type) {
	x: T = 0;
	y: T = 0;
	z: T = 0;
	w: T = 1;
}

Qd :: Q(float64);
Qf :: Q(float32);

vector_part :: (q: Q($T)) -> V3(T) {
	return V3(T).{ q.x, q.y, q.z };
}
scalar_part :: (q: Q($T)) -> T {
	return q.w;
}

axis_angle :: (axis: V3($T), angle: T) -> Q(T) {
	s := sin(angle / 2);
	return .{
		axis.x * s,
		axis.y * s,
		axis.z * s,
		cos(angle / 2)
	};
}
axis_angle_matrix :: (axis: V3($T), angle: T) -> M4(T) {
	M: M4(T);
	s := sin(angle);
	c := cos(angle);
	c1 := 1 - c;
	M.data[0 + 0 * 4] = axis.x * axis.x * c1 + c;
	M.data[0 + 1 * 4] = axis.x * axis.y * c1 - axis.z * s;
	M.data[0 + 2 * 4] = axis.x * axis.z * c1 + axis.y * s;
	M.data[1 + 0 * 4] = axis.y * axis.x * c1 + axis.z * s;
	M.data[1 + 1 * 4] = axis.y * axis.y * c1 + c;
	M.data[1 + 2 * 4] = axis.y * axis.z * c1 - axis.x * s;
	M.data[2 + 0 * 4] = axis.z * axis.x * c1 - axis.y * s;
	M.data[2 + 1 * 4] = axis.z * axis.y * c1 + axis.x * s;
	M.data[2 + 2 * 4] = axis.z * axis.z * c1 + c;
	M.data[3 + 3 * 4] = 1;
	return M;
}
z_angle_matrix :: (angle: $T) -> M4(T) {
	M: M4(T);
	s := sin(angle);
	c := cos(angle);
	M.data[0 + 0 * 4] = c;
	M.data[0 + 1 * 4] = -s;
	M.data[1 + 0 * 4] = s;
	M.data[1 + 1 * 4] = c;
	M.data[2 + 2 * 4] = 1;
	M.data[3 + 3 * 4] = 1;
	return M;
}
to_axis_angle :: (q: Q($T)) -> V3(T), T {
	angle := 2 * acos(clamp(q.w, -1.0, 1.0));
	s := sqrt(1 - clamp(q.w * q.w, 0, 1));
	if s < 0.001
		return V3(T).{ q.x, q.y, q.z }, angle;
	return V3(T).{ q.x / s, q.y / s, q.z / s }, angle;
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

scale_matrix :: (s: float) -> M4(float) {
	M: M4(float);
	for * M.data {
		it.* = 0;
	}
	M.data[0 + 0 * 4] = s;
	M.data[1 + 1 * 4] = s;
	M.data[2 + 2 * 4] = s;
	M.data[3 + 3 * 4] = 1;
	return M;
}
scale_matrix :: (s: V3($T)) -> M4(T) {
	M: M4(T);
	for * M.data {
		it.* = 0;
	}
	M.data[0 + 0 * 4] = s.x;
	M.data[1 + 1 * 4] = s.y;
	M.data[2 + 2 * 4] = s.z;
	M.data[3 + 3 * 4] = 1;
	return M;
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
to_rotation_matrix3 :: (q: Q($T)) -> M3(T) {
	x := q * V3(T).{1, 0, 0};
	y := q * V3(T).{0, 1, 0};
	z := q * V3(T).{0, 0, 1};
	return M3f.by_rows(
		V3f.{ x.x, y.x, z.x },
		V3f.{ x.y, y.y, z.y },
		V3f.{ x.z, y.z, z.z }
	);
}

angle_between :: (from: V3($T), to: V3(T), up: V3(T)) -> T {
	s := cross(from, to);
	c := dot(from, to);

	return atan2(dot(s, up), c);
}

DEG_RAD :: PI / 180;
RAD_DEG :: 180 / PI;

operator / :: (v: V4($T), f: T) -> V4(T) {
	return .{ v.x / f, v.y / f, v.z / f, v.w / f };
}
operator / :: (v: V3($T), f: T) -> V3(T) {
	return .{ v.x / f, v.y / f, v.z / f };
}
operator * :: (v: V3($T), f: T) -> V3(T) #symmetric {
	return .{ v.x * f, v.y * f, v.z * f };
}
operator * :: (v: Q($T), f: T) -> Q(T) #symmetric {
	return .{ v.x * f, v.y * f, v.z * f, v.w * f };
}
operator * :: (v: V2($T), f: T) -> V2(T) #symmetric {
	return .{ v.x * f, v.y * f };
}
operator / :: (v: V2($T), f: T) -> V2(T) {
	return .{ v.x / f, v.y / f };
}
operator * :: (v: V3($T), f: float64) -> V3(T) #symmetric {
	return .{ cast(T)(v.x * f), cast(T)(v.y * f), cast(T)(v.z * f) };
}

operator * :: (q: Q($T), v: V3(T)) -> V3(T) {
	u := V3f.{q.x, q.y, q.z};
	s := q.w;

	return 2 * dot(u, v) * u
		+ (s * s - dot(u, u)) * v
		+ 2 * s * cross(u, v);
}

operator * :: (a: Q($T), b: Q(T)) -> Q(T) {
	c: Q(T);
	scalar := a.w * b.w - dot(vector_part(a), vector_part(b));
	v := scalar_part(b) * vector_part(a);
	v += scalar_part(a) * vector_part(b);
	v += cross(vector_part(a), vector_part(b));
	return .{ v.x, v.y, v.z, scalar };
}

operator - :: (a: V3($T), b: V3(T)) -> V3(T) #symmetric {
	return .{ a.x - b.x, a.y - b.y, a.z - b.z };
}

operator - :: (a: V2($T), b: V2(T)) -> V2(T) #symmetric {
	return .{ a.x - b.x, a.y - b.y };
}

operator + :: (a: V3($T), b: V3(T)) -> V3(T) #symmetric {
	return .{ a.x + b.x, a.y + b.y, a.z + b.z };
}
operator + :: (a: Q($T), b: Q(T)) -> Q(T) #symmetric {
	return .{ a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w };
}
operator - :: (a: Q($T), b: Q(T)) -> Q(T) #symmetric {
	return .{ a.x - b.x, a.y - b.y, a.z - b.z, a.w - b.w };
}

operator + :: (a: V2($T), b: V2(T)) -> V2(T) #symmetric {
	return .{ a.x + b.x, a.y + b.y };
}

normalize :: (a: V3($T)) -> V3(T) {
	l := sqrt(a.x * a.x + a.y * a.y + a.z * a.z);
	if l == 0
		return .{ 0, 0, 0 };
	return .{ a.x / l, a.y / l, a.z / l };
}

normalize :: (q: Q($T)) -> Q(T) {
	l := sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w);
	if l == 0
		return .{ 0, 0, 0, 1 };
	return .{ q.x / l, q.y / l, q.z / l, q.w / l };
}

cross :: (a: V3($T), b: V3(T)) -> V3(T) {
	return .{
		a.y * b.z - a.z * b.y,
		a.z * b.x - a.x * b.z,
		a.x * b.y - a.y * b.x
	};
}

dot :: (a: V2($T), b: V2(T)) -> T {
	return a.x * b.x + a.y * b.y;
}
dot :: (a: V3($T), b: V3(T)) -> T {
	return a.x * b.x + a.y * b.y + a.z * b.z;
}
dot :: (a: V4($T), b: V4(T)) -> T {
	return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;
}

norm :: (a: V3($T)) -> T {
	return sqrt(dot(a, a));
}
norm :: (a: V2($T)) -> T {
	return sqrt(dot(a, a));
}

operator * :: (m: M3($T), v: T) -> M3(T) #symmetric {
	y := m;
	for * y.data
		it.* *= v;
	return y;
}

operator * :: (m: M3($T), v: V3(T)) -> V3(T) {
	return .{
		m.data[0] * v.x + m.data[3] * v.y + m.data[6] * v.z,
		m.data[1] * v.x + m.data[4] * v.y + m.data[7] * v.z,
		m.data[2] * v.x + m.data[5] * v.y + m.data[8] * v.z
	};
}

operator * :: (A: M3($T), B: M3(T)) -> M3(T) {
	C: M3(T) = ---;

	ad := A.data.data;
	bd := B.data.data;
	cd := C.data.data;

	elem :: (x: int, y: int) #expand {
		cd[y * 3 + x] = ad[0 * 3 + x] * bd[y * 3 + 0];
		cd[y * 3 + x] += ad[1 * 3 + x] * bd[y * 3 + 1];
		cd[y * 3 + x] += ad[2 * 3 + x] * bd[y * 3 + 2];
	}
	elem(0, 0);
	elem(0, 1);
	elem(0, 2);
	elem(1, 0);
	elem(1, 1);
	elem(1, 2);
	elem(2, 0);
	elem(2, 1);
	elem(2, 2);
	return C;
}

operator * :: (A: M4($T), B: M4(T)) -> M4(T) {
	C: M4(T) = ---;

	ad := A.data.data;
	bd := B.data.data;
	cd := C.data.data;

	elem :: (x: int, y: int) #expand {
		cd[y * 4 + x] = ad[0 * 4 + x] * bd[y * 4 + 0];
		cd[y * 4 + x] += ad[1 * 4 + x] * bd[y * 4 + 1];
		cd[y * 4 + x] += ad[2 * 4 + x] * bd[y * 4 + 2];
		cd[y * 4 + x] += ad[3 * 4 + x] * bd[y * 4 + 3];

	}
	elem(0, 0);
	elem(0, 1);
	elem(0, 2);
	elem(0, 3);
	elem(1, 0);
	elem(1, 1);
	elem(1, 2);
	elem(1, 3);
	elem(2, 0);
	elem(2, 1);
	elem(2, 2);
	elem(2, 3);
	elem(3, 0);
	elem(3, 1);
	elem(3, 2);
	elem(3, 3);
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

compose_rotation :: (A: *M4($T), B: M4(T)) {
	C: M4(T) = ---;

	at :: (x: int, y: int) -> int {
		return x + y * 4;
	}

	C.data[at(0, 0)] = A.data[at(0, 0)] * B.data[at(0, 0)];
	C.data[at(0, 0)] += A.data[at(1, 0)] * B.data[at(0, 1)];
	C.data[at(0, 0)] += A.data[at(2, 0)] * B.data[at(0, 2)];
	C.data[at(0, 1)] = A.data[at(0, 0)] * B.data[at(1, 0)];
	C.data[at(0, 1)] += A.data[at(1, 0)] * B.data[at(1, 1)];
	C.data[at(0, 1)] += A.data[at(2, 0)] * B.data[at(1, 2)];
	C.data[at(0, 2)] = A.data[at(0, 0)] * B.data[at(2, 0)];
	C.data[at(0, 2)] += A.data[at(1, 0)] * B.data[at(2, 1)];
	C.data[at(0, 2)] += A.data[at(2, 0)] * B.data[at(2, 2)];
	C.data[at(1, 0)] = A.data[at(0, 1)] * B.data[at(0, 0)];
	C.data[at(1, 0)] += A.data[at(1, 1)] * B.data[at(0, 1)];
	C.data[at(1, 0)] += A.data[at(2, 1)] * B.data[at(0, 2)];
	C.data[at(1, 1)] = A.data[at(0, 1)] * B.data[at(1, 0)];
	C.data[at(1, 1)] += A.data[at(1, 1)] * B.data[at(1, 1)];
	C.data[at(1, 1)] += A.data[at(2, 1)] * B.data[at(1, 2)];
	C.data[at(1, 2)] = A.data[at(0, 1)] * B.data[at(2, 0)];
	C.data[at(1, 2)] += A.data[at(1, 1)] * B.data[at(2, 1)];
	C.data[at(1, 2)] += A.data[at(2, 1)] * B.data[at(2, 2)];
	C.data[at(2, 0)] = A.data[at(0, 2)] * B.data[at(0, 0)];
	C.data[at(2, 0)] += A.data[at(1, 2)] * B.data[at(0, 1)];
	C.data[at(2, 0)] += A.data[at(2, 2)] * B.data[at(0, 2)];
	C.data[at(2, 1)] = A.data[at(0, 2)] * B.data[at(1, 0)];
	C.data[at(2, 1)] += A.data[at(1, 2)] * B.data[at(1, 1)];
	C.data[at(2, 1)] += A.data[at(2, 2)] * B.data[at(1, 2)];
	C.data[at(2, 2)] = A.data[at(0, 2)] * B.data[at(2, 0)];
	C.data[at(2, 2)] += A.data[at(1, 2)] * B.data[at(2, 1)];
	C.data[at(2, 2)] += A.data[at(2, 2)] * B.data[at(2, 2)];

	for y: 0..2 {
		for x: 0..2 {
			A.data[at(x, y)] = C.data[at(x, y)];
		}
	}
}

v2 :: (v: float32) -> V2(float32) {
	return .{ v, v };
}
v2 :: (v: float64) -> V2(float64) {
	return .{ v, v };
}
v2 :: (v: V2($T)) -> V2(T) {
	return v;
}
v2 :: (a: $T, b: T) -> V2(T) {
	return .{ a, b };
}
v2 :: (v3: V3($T)) -> V2(T) {
	return .{ v3.x, v3.y };
}
v3 :: (x: $T, y: T, z: T) -> V3(T) {
	return .{ x, y, z };
}
v3 :: (v2: V2($T), z := 0.0) -> V3(T) {
	return .{ v2.x, v2.y, z };
}
v3 :: (v4: V4($T)) -> V3(T) {
	return .{ v4.x, v4.y, v4.z };
}

v4 :: (a: $T, b: T, c: T, w := 1.0) -> V4(T) {
	return .{ a, b, c, w };
}
v4 :: (v3: V3($T), w := 1.0) -> V4(T) {
	return .{ v3.x, v3.y, v3.z, w };
}

conjugate :: (q: Q($T)) -> Q(T) {
	return .{ -q.x, -q.y, -q.z, q.w };
}

x_extract :: (q: Q($T)) -> V3(T) {
	// return the result of q * V3(T).{1, 0, 0}
	return .{
		q.w * q.w + q.x * q.x - q.y * q.y - q.z * q.z,
		2 * (q.x * q.y + q.w * q.z),
		2 * (q.x * q.z - q.w * q.y)
	};
}

y_extract :: (q: Q($T)) -> V3(T) {
	// return the result of q * V3(T).{0, 1, 0}
	return .{
		2 * (q.x * q.y - q.w * q.z),
		q.w * q.w - q.x * q.x + q.y * q.y - q.z * q.z,
		2 * (q.y * q.z + q.w * q.x)
	};
}

z_extract :: (q: Q($T)) -> V3(T) {
	// return the result of q * V3(T).{0, 0, 1}
	return .{
		2 * (q.x * q.z + q.w * q.y),
		2 * (q.y * q.z - q.w * q.x),
		q.w * q.w - q.x * q.x - q.y * q.y + q.z * q.z
	};
}

transpose :: (m: M3($T)) -> M3(T) {
	mt: M3(T);
	for y: 0..2 {
		for x: 0..2 {
			mt.data[x + y * 3] = m.data[y + x * 3];
		}
	}
	return mt;
}

inverse :: (mm: M3($T)) -> M3(T) {
	minv: M3(T);
	inv := minv.data.data;
	m := mm.data.data;

	inv[0] = m[4]  * m[8] - m[5]  * m[7];
	inv[1] = m[2]  * m[7] - m[1]  * m[8];
	inv[2] = m[1]  * m[5] - m[2]  * m[4];
	inv[3] = m[5]  * m[6] - m[3]  * m[8];
	inv[4] = m[0]  * m[8] - m[2]  * m[6];
	inv[5] = m[2]  * m[3] - m[0]  * m[5];
	inv[6] = m[3]  * m[7] - m[4]  * m[6];
	inv[7] = m[1]  * m[6] - m[0]  * m[7];
	inv[8] = m[0]  * m[4] - m[1]  * m[3];

	det := m[0] * inv[0] + m[1] * inv[3] + m[2] * inv[6];
	if det == 0
		return M3(T).identity();

	det_inv := 1 / det;
	for i: 0..9 {
		inv[i] *= det_inv;
	}
	return minv;
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


damp :: (a: $T, b: T, lamda: float64, dt: float64) -> T {
	return cast(T) (a + (b - a) * (1 - exp(-lamda * dt)));
}
damp_snap :: (a: $T, b: T, lamda: float64, dt: float64, snap: T = 1) -> T {
	if abs(a - b) > snap
		return b;
	return cast(T) (a + (b - a) * (1 - exp(-lamda * dt)));
}

#import "Basic";

damp_angle_between :: (a: V3($T), b: V3(T), lambda: T, dt: T) -> V3(T) {
	axis := cross(a, b);
	if norm(axis) == 0 {
		axis = cross(V3f.{1, 0, 0}, a);
	}
	axis = normalize(axis);

	angle := angle_between(a, b, axis);
	if angle == 0
		return a;

	return axis_angle(axis, damp(-angle, 0, cast(float64) lambda, cast(float64) dt)) * b;
}

closest_aabb :: (p: V2($T), low: V2(T), high: V2(T)) -> V2(T) {
	q := p;
	q.x = clamp(q.x, low.x, high.x);
	q.y = clamp(q.y, low.y, high.y);
	return q;
}

closest_aabb :: (p: V3($T), low: V3(T), high: V3(T)) -> V3(T) {
	q := p;
	q.x = clamp(q.x, low.x, high.x);
	q.y = clamp(q.y, low.y, high.y);
	q.z = clamp(q.z, low.z, high.z);
	return q;
}

dist_aabb :: (p: V3($T), low: V3(T), high: V3(T)) -> T {
	q := p;
	q.x = clamp(q.x, low.x, high.x);
	q.y = clamp(q.y, low.y, high.y);
	q.z = clamp(q.z, low.z, high.z);
	return norm(q - p);
}

line_line :: (a1: V2($T), a2: V2(T), b1: V2(T), b2: V2(T)) -> bool {
	b := a2 - a1;
	d := b2 - b1;
	bDotDPerp := b.x * d.y - b.y * d.x;
	if bDotDPerp == 0
		return false;

	c := b1 - a1;
	t := (c.x * d.y - c.y * d.x) / bDotDPerp;
	if t < 0 || t > 1
		return false;

	u := (c.x * b.y - c.y * b.x) / bDotDPerp;
	if u < 0 || u > 1
		return false;

	return true;
}

line_aabb :: (a1: V2($T), b: V2(T), low: V2(T), high: V2(T)) -> bool {
	return line_line(
		a1, a1 + b,
		low, V2(T).{ low.x, high.y }
	) || line_line(
		a1, a1 + b,
		V2(T).{ low.x, high.y }, high
	) || line_line(
		a1, a1 + b,
		V2(T).{ high.x, high.y }, V2(T).{ high.x, low.y }
	) || line_line(
		a1, a1 + b,
		V2(T).{ high.x, low.y }, low
	);
}

cone_square :: (
	cone_center: V2($T), cone_dir: V2(T), cone_angle: T, square_center: V2(T), square_size: T
) -> bool {
	to_square := square_center - cone_center;
	to_square_len := norm(to_square);
	if to_square_len == 0
		return true;
	to_square_dir := to_square / to_square_len;
	angle_to_square := acos(dot(cone_dir, to_square_dir));
	return angle_to_square < cone_angle && to_square_len < square_size * sqrt(2.0);
}

point_aabb :: (p: V2($T), low: V2(T), high: V2(T)) -> bool {
	return p.x >= low.x && p.x <= high.x && p.y >= low.y && p.y <= high.y;
}

point_aabb :: (p: V2($T), aabb: AABB(T)) -> bool {
	return point_aabb(p, aabb.min, aabb.max);
}

ease_quad :: (x: float) -> float {
	return x * x;
}

ease_in_quad :: ease_quad;

ease_out_quad :: (x: float) -> float {
	return 1 - (1 - x) * (1 - x);
}
ease_in_cubic :: (x: float) -> float {
	return x * x * x;
}

ease_up_and_back :: (x: float) -> float {
	if x < 0.5
		return 2 * x;
	return 2 * (1 - x);
}

ease_out_bounce :: (x: float) -> float {
	n1 :: 7.5625;
	d1 :: 2.75;

	if (x < 1 / d1) {
		return n1 * x * x;
	} else if (x < 2 / d1) {
		x -= 1.5 / d1;
		return n1 * x * x + 0.75;
	} else if (x < 2.5 / d1) {
		x -= 2.25 / d1;
		return n1 * x * x + 0.9375;
	} else {
		x -= 2.625 / d1;
		return n1 * x * x + 0.984375;
	}
}
ease_in_out_bounce :: (x: float) -> float {
	return ifx x < 0.5
		then (1 - ease_out_bounce(1 - 2 * x)) / 2
		else (1 + ease_out_bounce(2 * x - 1)) / 2;
}

linear_step :: (x: float, edge0: float, edge1: float) -> float {
	t := clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
	return t;
}

smoothstep :: (x: float, edge0: float, edge1: float) -> float {
	t := clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
	return t * t * (3 - 2 * t);
}

det :: (m: M3($T)) -> T {
	return m.data[0] * (m.data[4] * m.data[8] - m.data[5] * m.data[7])
		- m.data[1] * (m.data[3] * m.data[8] - m.data[5] * m.data[6])
		+ m.data[2] * (m.data[3] * m.data[7] - m.data[4] * m.data[6]);
}

covariance_tetrahedron :: (a: V3($T), b: V3(T), c: V3(T), d: V3(T)) -> M3(T) {
	centroid := (a + b + c + d) / 4;
	cov: M3(T);
	memset(cov.data.data, 0, 9 * sizeof(T));
	for v: .[ a, b, c, d ] {
		diff := v - centroid;
		cov += M3(T).by_rows(
			V3(T).{ diff.x * diff.x, diff.x * diff.y, diff.x * diff.z },
			V3(T).{ diff.y * diff.x, diff.y * diff.y, diff.y * diff.z },
			V3(T).{ diff.z * diff.x, diff.z * diff.y, diff.z * diff.z }
		);
	}
	return cov / 4;
}

covariance_to_inertia :: (cov: M3($T), mass: T) -> M3(T) {
	inertia: M3(T);
	inertia.data[0] = mass * (cov.data[4] + cov.data[8]);
	inertia.data[4] = mass * (cov.data[0] + cov.data[8]);
	inertia.data[8] = mass * (cov.data[0] + cov.data[4]);
	inertia.data[1] = inertia.data[3] = -mass * cov.data[1];
	inertia.data[2] = inertia.data[6] = -mass * cov.data[2];
	inertia.data[5] = inertia.data[7] = -mass * cov.data[5];
	return inertia;
}

compute_inertia_moment :: (P: [3] V3f, i: int) -> float {
	Pd := P.data.(*float);
	result := 0.0;
	result += Pd[3 * 0 + i] * Pd[3 * 0 + i] + Pd[3 * 1 + i] * Pd[3 * 2 + i];
	result += Pd[3 * 1 + i] * Pd[3 * 1 + i] + Pd[3 * 0 + i] * Pd[3 * 2 + i];
	result += Pd[3 * 2 + i] * Pd[3 * 2 + i] + Pd[3 * 0 + i] * Pd[3 * 1 + i];
	return result;
}

compute_inertia_product :: (P: [3] V3f, i: int, j: int) -> float {
	Pd := P.data.(*float);
	result := 0.0;
	result += 2.0 * Pd[3 * 0 + i] * Pd[3 * 0 + j];
	result += Pd[3 * 1 + i] * Pd[3 * 2 + j] + Pd[3 * 2 + i] * Pd[3 * 1 + j];
	
	result += 2.0 * Pd[3 * 1 + i] * Pd[3 * 1 + j];
	result += Pd[3 * 0 + i] * Pd[3 * 2 + j] + Pd[3 * 2 + i] * Pd[3 * 0 + j];
	
	result += 2.0 * Pd[3 * 2 + i] * Pd[3 * 2 + j];
	result += Pd[3 * 0 + i] * Pd[3 * 1 + j] + Pd[3 * 1 + i] * Pd[3 * 0 + j];
	
	return result;
}

compute_inertia :: (size: V3($T)) -> M3(T), V3(T), float {
	M := size.x * size.y * size.z;
	
	Ia := (size.y * size.y + size.z * size.z) / 12;
	Ib := (size.x * size.x + size.z * size.z) / 12;
	Ic := (size.x * size.x + size.y * size.y) / 12;

	I: M3(T) = ---;
	memset(I.data.data, 0, 9 * size_of(T));
	I.data[0] = Ia * M;
	I.data[4] = Ib * M;
	I.data[8] = Ic * M;

	return I, size / 2, M;
}

compute_inertia :: (V: [] V3f, F: [] u16, off_indices := 0) -> M3f, V3f, float {
	Ia := 0.0;
	Ib := 0.0;
	Ic := 0.0;
	Iap := 0.0;
	Ibp := 0.0;
	Icp := 0.0;

	mass := 0.0;
	center_of_mass := v3(0.0, 0.0, 0.0);

	for 0..F.count / 3 - 1 {
		ai := F[it * 3 + 0] - off_indices;
		bi := F[it * 3 + 1] - off_indices;
		ci := F[it * 3 + 2] - off_indices;

		P := V3f.[ V[ai], V[bi], V[ci] ];

		detj := dot(cross(P[1] - P[0], P[2] - P[0]), P[0]);
		volume := detj / 6;
		com := (P[0] + P[1] + P[2]) / 4;

		v100 := compute_inertia_moment(P, 0);
		v010 := compute_inertia_moment(P, 1);
		v001 := compute_inertia_moment(P, 2);

		Ia += detj * (v010 + v001);
		Ib += detj * (v100 + v001);
		Ic += detj * (v100 + v010);

		Iap += detj * compute_inertia_product(P, 1, 2);
		Ibp += detj * compute_inertia_product(P, 0, 1);
		Icp += detj * compute_inertia_product(P, 0, 2);

		mass += volume;
		center_of_mass += com * volume;
	}

	center_of_mass /= mass;
	Ia = Ia / 60 - mass * (center_of_mass.y * center_of_mass.y + center_of_mass.z * center_of_mass.z);
	Ib = Ib / 60 - mass * (center_of_mass.x * center_of_mass.x + center_of_mass.z * center_of_mass.z);
	Ic = Ic / 60 - mass * (center_of_mass.x * center_of_mass.x + center_of_mass.y * center_of_mass.y);
	Iap = Iap / 120 - mass * center_of_mass.y * center_of_mass.z;
	Ibp = Ibp / 120 - mass * center_of_mass.x * center_of_mass.y;
	Icp = Icp / 120 - mass * center_of_mass.x * center_of_mass.z;

	I: M3f = ---;
	memset(I.data.data, 0, 9 * size_of(float));
	I.data[0] = Ia;
	I.data[4] = Ib;
	I.data[8] = Ic;
	I.data[1] = -Iap;
	I.data[3] = -Iap;
	I.data[2] = -Icp;
	I.data[6] = -Icp;
	I.data[5] = -Ibp;
	I.data[7] = -Ibp;

	return I, center_of_mass, mass;
}

OBB :: struct {
	center: V3f;
	half_extents: V3f;
	q: Qf;
}

Penetration :: struct {
	penetration: V3f;

	ra: V3f; // from center of A to contact point, in the body space of each box
	rb: V3f; // from center of B to contact point, in the body space of each box
}

support :: (obb: OBB, dir: V3f) -> V3f {
	localDir := conjugate(obb.q) * dir;
	localSupport := v3(
		ifx localDir.x > 0 then obb.half_extents.x else -obb.half_extents.x,
		ifx localDir.y > 0 then obb.half_extents.y else -obb.half_extents.y,
		ifx localDir.z > 0 then obb.half_extents.z else -obb.half_extents.z
	);
	return localSupport;
}


raw_projected_radius :: (obb: OBB, axis: V3f) -> float {
	return abs(dot(obb.q * v3(1.0, 0.0, 0.0), axis)) * obb.half_extents.x +
			abs(dot(obb.q * v3(0.0, 1.0, 0.0), axis)) * obb.half_extents.y +
			abs(dot(obb.q * v3(0.0, 0.0, 1.0), axis)) * obb.half_extents.z;
}
obb_floor_penetration :: (A: OBB, floor: float) -> Penetration {
	normal := v3(0.0, 0.0, 1.0);
	signed_dist := dot(A.center, normal) - floor;  // positive = center above plane

	rA := raw_projected_radius(A, normal);

	pen := rA - signed_dist;
	if pen <= 0.0 {
		return .{};
	}

	penetrationVector := normal * pen;  // +z * depth

	// Contact point = centroid of all vertices at or below the floor.
	// Using a single support corner creates a spurious moment arm for
	// edge/face contacts (flat-resting boxes), injecting rotational energy.
	h := A.half_extents;
	local_corners := V3f.[
		V3f.{ -h.x, -h.y, -h.z },
		V3f.{  h.x, -h.y, -h.z },
		V3f.{ -h.x,  h.y, -h.z },
		V3f.{  h.x,  h.y, -h.z },
		V3f.{ -h.x, -h.y,  h.z },
		V3f.{  h.x, -h.y,  h.z },
		V3f.{ -h.x,  h.y,  h.z },
		V3f.{  h.x,  h.y,  h.z },
	];

	centroid := v3(0.0, 0.0, 0.0);
	count := 0;
	for corner: local_corners {
		world_z := A.center.z + (A.q * corner).z;
		if world_z <= floor {
			centroid += corner;
			count += 1;
		}
	}

	contactA: V3f;
	if count > 0 {
		contactA = centroid / cast(float32) count;
	} else {
		// Fallback: use the single lowest corner (support)
		contactA = support(A, -1 * normal);
	}

	contactB := v3(A.center.x, A.center.y, floor);

	return .{-1 * penetrationVector, contactA, contactB};
}

obb_penetration :: (A: OBB, B: OBB) -> Penetration {
	delta := B.center - A.center;
	if norm(delta) > norm(A.half_extents) + norm(B.half_extents)
		return .{};

	minPenetration := -1.0;
	bestNormal := v3(0.0, 0.0, 0.0);          // will always be unit at the end

	A_axes: [3] V3f;
	B_axes: [3] V3f;

	A_axes[0] = x_extract(A.q);
	A_axes[1] = y_extract(A.q);
	A_axes[2] = z_extract(A.q);

	B_axes[0] = x_extract(B.q);
	B_axes[1] = y_extract(B.q);
	B_axes[2] = z_extract(B.q);

	// --------------------------------------------------------------
	// 1. Test A's 3 face normals (already unit)
	for i: 0..2 {
		axis := A_axes[i];
		rA := raw_projected_radius(A, axis);
		rB := raw_projected_radius(B, axis);
		dist := abs(dot(delta, axis));
		pen := rA + rB - dist;

		if pen < 0.0
			return .{};
		if pen < minPenetration || minPenetration < 0 {
			minPenetration = pen;
			bestNormal = axis;
		}
	}

    // --------------------------------------------------------------
    // 2. Test B's 3 face normals (already unit)
    for i: 0..2 {
        axis := B_axes[i];
        rA := raw_projected_radius(A, axis);
        rB := raw_projected_radius(B, axis);
        dist := abs(dot(delta, axis));
        pen := rA + rB - dist;

        if pen < 0.0
            return .{};
        if pen < minPenetration || minPenetration < 0 {
            minPenetration = pen;
            bestNormal = axis;
        }
    }

    // --------------------------------------------------------------
    // 3. Test 9 cross-product axes (the expensive ones)
    for i: 0..2 {
        for j: 0..2 {
            rawAxis := cross(A_axes[i], B_axes[j]);
            lenSq := dot(rawAxis, rawAxis);
            if lenSq < 0.000001 continue;

            rA_raw := raw_projected_radius(A, rawAxis);
            rB_raw := raw_projected_radius(B, rawAxis);
            absDistRaw := abs(dot(delta, rawAxis));

            // Separation test — NO sqrt required!
            if absDistRaw > rA_raw + rB_raw {
                return .{};
            }

            // Overlaps → compute real penetration depth (requires sqrt)
            len := sqrt(lenSq);
            pen := (rA_raw + rB_raw - absDistRaw) / len;

            if pen < minPenetration || minPenetration < 0 {
                minPenetration = pen;
                bestNormal = rawAxis / len;   // unit normal
            }
        }
    }

	if minPenetration < 0.0
		return .{};

    // --------------------------------------------------------------
    // No separating axis found → collision
    // Make normal point from A → B
    if (dot(delta, bestNormal) < 0.0) {
        bestNormal = -1 * bestNormal;
    }

    penetrationVector := bestNormal * minPenetration;

    contactA := support(A, bestNormal);
    contactB := support(B, -1 * bestNormal);

    return .{penetrationVector, contactA, contactB};
}

// lut_sin_norm_angle :: (angle: float, $LUT: [N] float) -> float {
// 	mul := +1;

// 	if angle > PI {
// 		mul = -1;
// 		angle -= PI;
// 	}

// 	flip_idx := false;
// 	if angle > PI / 2 {
// 		flip_idx = true;
// 		angle = PI / 2 - angle;
// 	}

// 	idx := (angle / (2 * PI)) * (LUT.len - 1);
// 	low_idx := idx.(int);
// 	high_idx := low_idx + 1;
// 	lerp := idx - low_idx;

// 	if flip_idx {
// 		low_idx = LUT.len - low_idx;
// 		high_idx = LUT.len - high_idx;
// 		lerp = 1 - lerp;
// 	}

// 	s := LUT[low_idx] + (LUT[high_idx] - LUT[low_idx]) * lerp;
// 	return s * mul;
// }

// fast_sin_cos_pos_angle :: (angle: float, $LUT_N: int) -> float, float {
// 	lut :: #run {
// 		lut: [LUT_N + 1] float;
// 		for i: 0..LUT_N - 1 {
// 			a := (PI64 * i / 2) / (LUT_N - 1.0);
// 			lut[i] = sin(a);
// 		}
// 		lut[LUT_N] = 1.0;
// 		return lut;
// 	}

// 	fmod_cycling(angle, 2 * PI);
// 	sin := lut_sin_norm_angle(angle, lut);
// 	cos := lut_sin_norm_angle(angle + PI / 2, lut);
// 	return sin, cos;
// }
