#scope_file

#scope_export

XORState :: struct {
	s: [2] u64;
}
State :: XORState;

seed :: (seed: u64) -> XORState {
	state : XORState = .{};
	state.s[0] = seed;
	state.s[1] = seed ^ 0x5DEECE66D;
	return state;
}

xor_shift_next :: (state: *XORState) -> u64 {
	s1 := state.s[0];
	s0 := state.s[1];
	res := s1 + s0;
	state.s[0] = s0;
	s1 ^= s1 << 23;
	state.s[1] = s1 ^ s0 ^ (s1 >> 18) ^ (s0 >> 5);
	return res;
}

random_u64 :: (state: *XORState) -> u64 {
	return xor_shift_next(state);
}

random_uniform :: (state: *XORState, min: float = 0.0, max: float = 1.0) -> float {
	u := random_u64(state);
	u &= 0xFFFFFFFF;
	t := (u.(float64) / ((0xFFFFFFFF).(u64)).(float64)).(float);
	return t * (max - min) + min;
}
