#scope_export

#import "Math";

V3 :: struct(T: Type) {
	x: T = 0;
	y: T = 0;
	z: T = 0;
}

V3d :: V3(f64);
V3f :: V3(f32);

M4 :: struct(T: Type) {
	data: [16] T;
}

M4d :: M4(f64);
M4f :: M4(f32);

DEG_RAD :: PI / 180;
RAD_DEG :: 180 / PI;


operator - :: (a: V3($T), b: V3(T)) -> V3(T) #symmetric {
	return .{ a.x - b.x, a.y - b.y, a.z - b.z };
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