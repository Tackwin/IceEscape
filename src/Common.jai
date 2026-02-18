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

