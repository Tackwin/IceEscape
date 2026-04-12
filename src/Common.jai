#import "Basic";

tprint_sized :: (format: string, args: .. Any, min_size: int = 128) -> string {
	str := tprint(format, ..args);

	if str.count >= min_size {
		return str;
	}

	padded_str: string;
	padded_str.count = min_size;
	padded_str.data = NewArray(min_size, u8,, temp).data;
	memcpy(padded_str.data, str.data, str.count);
	return padded_str;
}

string_from_arr :: (arr: []u8) -> string {
	str: string;
	str.data = arr.data;
	str.count = arr.count;
	for arr {
		if it == 0 {
			str.count = it_index;
			break;
		}
	}
	return str;
}

string_to_arr :: (str: string, into: [] u8) {
	memcpy(into.data, str.data, min(str.count, into.count));
}