#import "Algebra";
#import "Basic";
#import "Sort";
#import "Math";

#scope_export

World :: struct {
	substeps: int;
	iterations: int;

	gravity := #run v3(0.0, 0.0, -4.81);

	bodies: []Rigid_Body;

	Fixture :: struct {
		center: V3f;
		radius: float32;
	}
	fixtures: []Fixture;
}

Rigid_Body :: struct {
	user_idx := -1;

	p: V3f;
	q: Qf;
	v: V3f;
	w: V3f;
	I: M3f;
	Ii: M3f;

	m: float32;

	kind: enum {
		Box;
		Sphere;
		ZCylinder;
	};

	half_size: V3f;  // for box
	radius: float32; // for sphere and z-cylinder
	height: float32; // for z-cylinder

	collide := false;
	collide_factor := 1.0;

	fixed := false;

	mu_d := 0.01; // dynamic friction coefficient
}

Pos_Constraint :: struct {
	compliance := 0.000000001; // For XPBD, compliance is the inverse of stiffness. Higher compliance means softer constraints.
	body_a: int;
	body_b := -1; // -1 for collision with the floor
	ra: V3f;
	rb: V3f;

	normal: V3f;
	c: float32;

	lambda_n: float32;
}

Collision_Pair :: struct {
	body_a: int;
	body_b: int;
}

step :: (world: *World, dt: float32) {
	Prev :: struct {
		p: V3f;
		v: V3f;
		q: Qf;
	}
	prevs := NewArray(world.bodies.count, Prev,, temp);
	constraints: [..] Pos_Constraint;
	constraints.allocator = temp;

	pairs: [..] Collision_Pair;
	pairs.allocator = temp;


	h := dt / world.substeps;
	for substep: 0..world.substeps - 1 {
		for * world.bodies {
			prevs[it_index].p = it.p;
			prevs[it_index].v = it.v;
			prevs[it_index].q = it.q;
		}

		for * world.bodies {
			it.v += h * world.gravity;
			it.p += h * it.v;

			Ii := it.Ii;
			R := to_rotation_matrix3(it.q);
			Ii = R * Ii * transpose(R);

			I := it.I;
			R = to_rotation_matrix3(it.q);
			I = R * I * transpose(R);
			
			// // w + hIi * (it.I * it.w) x it.w
			it.w += h * Ii * cross(I * it.w, it.w);
			it.q += h * 0.5 * Qf.{it.w.x, it.w.y, it.w.z, 0} * it.q;
			it.q = normalize(it.q);
		}


		// obb_obb_collision(world, pairs, *constraints);

		for iteration: 0..world.iterations - 1 {
			constraints.count = 0;
			// pairs.count = 0;
			// collect_collision_pairs(world, dt, *pairs);
			floor_constraint(world, *constraints);

			for * constraint: constraints {
				if constraint.body_b == -1 {
					body_a := *world.bodies[constraint.body_a];

					I := body_a.Ii;
					R := to_rotation_matrix3(body_a.q);
					I = R * I * transpose(R);

					n := constraint.normal;
					c := constraint.c;

					ra_cross_n := cross(constraint.ra, n);
					wa := dot(ra_cross_n, I * ra_cross_n);
					wa += 1 / body_a.m;

					lambda := (-c - constraint.compliance * constraint.lambda_n);
					lambda /= (wa + constraint.compliance);
					constraint.lambda_n += lambda;

					impulse := n * lambda;
					body_a.p += impulse / body_a.m;

					vq := I * cross(constraint.ra, impulse);
					body_a.q += 0.5 * Qf.{vq.x, vq.y, vq.z, 0} * body_a.q;
				}
			}
		}

		for * world.bodies {
			it.v = (it.p - prevs[it_index].p) / h;
			dq := it.q * conjugate(prevs[it_index].q);
			it.w = 2 * v3(dq.x, dq.y, dq.z) / h;
			if dq.w < 0
				it.w = -1.0 * it.w;
			// it.w *= pow(0.5, h); // Damping to help with stability
		}

		for constraint: constraints {
			if constraint.body_b != -1
				continue;

			n := constraint.normal;

			body_a := *world.bodies[constraint.body_a];
			ra := constraint.ra;

			Iworldi := body_a.Ii;
			R := to_rotation_matrix3(body_a.q);
			Iworldi = R * body_a.Ii * transpose(R);

			v_contact := body_a.v + cross(body_a.w, ra);
			vn := dot(v_contact, n);
			vt := v_contact - vn * n;

			vt_len := norm(vt);

			t := vt / vt_len;
			ra_cross_t := cross(ra, t);

			w_t := 1 / body_a.m;
			w_t += dot(ra_cross_t, Iworldi * ra_cross_t);

			max_jt := body_a.mu_d * abs(constraint.lambda_n) / h;
			required_jt := vt_len / w_t;
			jt := min(required_jt, max_jt);

			tangential_impulse := -1 * t * jt;

			body_a.v += tangential_impulse / body_a.m;
			body_a.w += Iworldi * cross(ra, tangential_impulse);
		}
	}
}

collect_collision_pairs :: (world: *World, dt: float32, pairs: *[..] Collision_Pair) {
	for i: 0..world.bodies.count-1 {
		a := world.bodies[i];
		if !a.collide
			continue;

		ra := norm(a.half_size);
		for j: i+1..world.bodies.count-1 {
			b := world.bodies[j];
			if !b.collide
				continue;

			pa := a.p;
			pb := b.p;

			safety := (norm(a.v) + norm(b.v)) * dt * 2;
			r := ra + norm(b.half_size);

			if norm(pa - pb) < r + safety {
				pair: Collision_Pair;
				pair.body_a = i;
				pair.body_b = j;
				array_add(pairs, pair);
			}
		}
	}
}

// update_constraints :: (world: *World, constraints: [] Pos_Constraint) {
// 	for * constraint: constraints {
// 		if constraint.body_b == -1 {
// 			body := world.bodies[constraint.body_a];
// 			oob: OBB;
// 			oob.center = body.p;
// 			oob.q = body.q;
// 			oob.half_extents = body.half_size;

// 			collision := obb_floor_penetration(oob, 0);
// 			if collision.penetration.z != 0.0 {
// 				constraint.delta = collision.penetration;
// 				constraint.ra = collision.ra;
// 			} else {
// 				constraint.delta = v3(0.0, 0.0, 0.0);
// 				constraint.lambda_n = 0;
// 			}
// 		} else {
// 			a := world.bodies[constraint.body_a];
// 			b := world.bodies[constraint.body_b];

// 			if a.kind == .Box && b.kind == .Box {
// 				ooba: OBB;
// 				ooba.center = a.p;
// 				ooba.q = a.q;
// 				ooba.half_extents = a.half_size;

// 				oobb: OBB;
// 				oobb.center = b.p;
// 				oobb.q = b.q;
// 				oobb.half_extents = b.half_size;

// 				collision := obb_penetration(ooba, oobb);
// 				if collision.penetration.x != 0.0
// 				|| collision.penetration.y != 0.0
// 				|| collision.penetration.z != 0.0 {
// 					constraint.ra = collision.ra;
// 					constraint.rb = collision.rb;
// 					constraint.delta = collision.penetration;
// 				} else {
// 					constraint.delta = v3(0.0, 0.0, 0.0);
// 					constraint.lambda_n = 0;
// 				}
// 			}
// 		}
// 	}
// }

floor_constraint :: (world: *World, constraints: *[..] Pos_Constraint) {
	for * world.bodies {
		body_index := it_index;
		if it.kind == .Box {
			h := it.half_size;
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

			for local_corner: local_corners {
				world_corner := it.p + it.q * local_corner;
				if world_corner.z < 0.0 {
					constraint: Pos_Constraint;
					constraint.body_a = body_index;
					constraint.body_b = -1;
					constraint.ra = it.q * local_corner;
					constraint.normal = v3(0.0, 0.0, 1);
					constraint.c = world_corner.z;
					array_add(constraints, constraint);
				}
			}
		}
	}
}

obb_obb_collision :: (world: *World, pairs: [] Collision_Pair, constraints: *[..] Pos_Constraint) {
	for pair: pairs {
		i := pair.body_a;
		j := pair.body_b;
		a := world.bodies[i];
		b := world.bodies[j];

		if a.kind == .Box && b.kind == .Box {
			ooba: OBB;
			ooba.center = a.p;
			ooba.q = a.q;
			ooba.half_extents = a.half_size;

			oobb: OBB;
			oobb.center = b.p;
			oobb.q = b.q;
			oobb.half_extents = b.half_size;

			collision := obb_penetration(ooba, oobb);
			if collision.penetration.x != 0.0
			|| collision.penetration.y != 0.0
			|| collision.penetration.z != 0.0 {
				constraint: Pos_Constraint;
				constraint.body_a = i;
				constraint.body_b = j;
				constraint.ra = collision.ra;
				constraint.rb = collision.rb;
				// constraint.delta = collision.penetration;
				array_add(constraints, constraint);
			}
		}
	}
}