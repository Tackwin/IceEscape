String_Pool :: struct {
	allocator: Allocator;
}

String :: struct {
	count: s64;
	capacity: s64;
	data: *u8;
	pool: *String_Pool;
}

init :: (pool: *String_Pool, allocator := context.allocator) {
	pool.allocator = allocator;
}

rebind :: (pool: *String_Pool, allocator := context.allocator) {
	pool.allocator = allocator;
}

make :: (pool: *String_Pool, initial_capacity := 16) -> String {
	s: String;
	s.pool = pool;
	if initial_capacity > 0 {
		grow(*s, initial_capacity);
	}
	return s;
}

grow :: (s: *String, needed: s64) {
	if needed <= s.capacity return;

	new_cap := s.capacity;
	if new_cap < 16 new_cap = 16;
	while new_cap < needed {
		new_cap = new_cap * 2;
	}

	s.data = xx realloc(s.data, new_cap, s.capacity,, s.pool.allocator);
	s.capacity = new_cap;
}

set :: (s: *String, text: string) {
	grow(s, text.count);
	if text.count > 0 {
		memcpy(s.data, text.data, text.count);
	}
	s.count = text.count;
}

insert :: (s: *String, at: s64, text: string) {
	grow(s, s.count + text.count);

	tail := s.count - at;
	if tail > 0 {
		i := tail;
		while i > 0 {
			i -= 1;
			s.data[at + text.count + i] = s.data[at + i];
		}
	}
	memcpy(s.data + at, text.data, text.count);
	s.count += text.count;
}

remove_range :: (s: *String, at: s64, n: s64) {
	end := at + n;
	tail := s.count - end;
	if tail > 0 {
		i := 0;
		while i < tail {
			s.data[at + i] = s.data[end + i];
			i += 1;
		}
	}
	s.count -= n;
}

view :: (s: *String) -> string {
	result: string;
	result.count = s.count;
	result.data = s.data;
	return result;
}

release :: (s: *String) {
	free(s.data,, s.pool.allocator);
	s.* = .{};
}
