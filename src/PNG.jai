// Small PNG reader/writer. RGB8, top-left origin, no interlacing.
// Writer uses zlib stored blocks (no compression) so the bytes stay readable.
// Reader accepts filter 0-4 and stored zlib. Deflate-compressed IDATs are rejected.

#import "Basic";
#import "String";

#scope_export

PNG_SIGNATURE :: u8.[137, 80, 78, 71, 13, 10, 26, 10];

write_rgb :: (rgb: [] u8, width: int, height: int, out: *[..] u8) -> bool {
	if width <= 0 || height <= 0 return false;
	expected := width * height * 3;
	if rgb.count < expected return false;

	out.count = 0;
	for PNG_SIGNATURE array_add(out, it);

	ihdr: [13] u8;
	png_put_u32be(*ihdr[0], xx width);
	png_put_u32be(*ihdr[4], xx height);
	ihdr[8] = 8;
	ihdr[9] = 2;
	ihdr[10] = 0;
	ihdr[11] = 0;
	ihdr[12] = 0;
	png_write_chunk(out, "IHDR", ihdr);

	row_bytes := 1 + width * 3;
	raw_count := row_bytes * height;
	raw := NewArray(raw_count, u8,, temp);
	for y: 0..height-1 {
		row := y * row_bytes;
		raw[row] = 0;
		src := y * width * 3;
		memcpy(raw.data + row + 1, rgb.data + src, width * 3);
	}

	zlib := png_zlib_store(raw,, temp);
	png_write_chunk(out, "IDAT", zlib);
	iend: [] u8;
	png_write_chunk(out, "IEND", iend);
	return true;
}

read_rgb :: (data: [] u8, rgb: *[..] u8, width: *int, height: *int) -> bool {
	if data.count < 8 return false;
	for 0..7 if data[it] != PNG_SIGNATURE[it] return false;

	cursor := 8;
	w := 0;
	h := 0;
	bit_depth: u8;
	color_type: u8;
	got_ihdr := false;
	idat: [..] u8;
	idat.allocator = temp;

	while cursor + 12 <= data.count {
		length := png_get_u32be(data, cursor).(int);
		cursor += 4;
		if cursor + 4 + length + 4 > data.count return false;
		typ: string = .{ data = data.data + cursor, count = 4 };
		cursor += 4;
		chunk := data;
		chunk.data += cursor;
		chunk.count = length;
		cursor += length;
		crc := png_get_u32be(data, cursor);
		cursor += 4;
		crc_span: [] u8 = .{ data = chunk.data - 4, count = length + 4 };
		if png_crc32(crc_span) != crc return false;

		if typ == "IHDR" {
			if length != 13 return false;
			w = png_get_u32be(chunk, 0).(int);
			h = png_get_u32be(chunk, 4).(int);
			bit_depth = chunk[8];
			color_type = chunk[9];
			if chunk[10] != 0 || chunk[11] != 0 || chunk[12] != 0 return false;
			got_ihdr = true;
		} else if typ == "IDAT" {
			old := idat.count;
			array_resize(*idat, old + length);
			memcpy(idat.data + old, chunk.data, length);
		} else if typ == "IEND" {
			break;
		}
	}

	if !got_ihdr || w <= 0 || h <= 0 return false;
	if bit_depth != 8 return false;
	if color_type != 2 && color_type != 6 return false;

	raw, ok := png_zlib_read_stored(idat);
	if !ok return false;

	channels := ifx color_type == 2 then 3 else 4;
	row_bytes := 1 + w * channels;
	if raw.count != row_bytes * h return false;

	array_resize(rgb, w * h * 3);
	prev: [] u8;
	for y: 0..h-1 {
		row := raw.data + y * row_bytes;
		filter := row[0];
		pixels := row + 1;
		pixel_bytes := w * channels;
		if !png_unfilter(filter, pixels, prev, pixel_bytes, channels) return false;
		prev = .{ data = pixels, count = pixel_bytes };
		dst := rgb.data + y * w * 3;
		if channels == 3 {
			memcpy(dst, pixels, w * 3);
		} else {
			for x: 0..w-1 {
				dst[x * 3 + 0] = pixels[x * 4 + 0];
				dst[x * 3 + 1] = pixels[x * 4 + 1];
				dst[x * 3 + 2] = pixels[x * 4 + 2];
			}
		}
	}

	width.* = w;
	height.* = h;
	return true;
}

#scope_file

Png_Filter :: enum u8 {
	None :: 0;
	Sub :: 1;
	Up :: 2;
	Average :: 3;
	Paeth :: 4;
}

png_xor32 :: (a: u32, b: u32) -> u32 {
	return (a | b) - (a & b);
}

png_crc32 :: (data: [] u8) -> u32 {
	crc: u32 = 0xffffffff;
	poly: u32 = 3988292384; // 0xEDB88320
	for data {
		crc = png_xor32(crc, cast(u32) it);
		for 0..7 {
			if (crc & 1) == 1 {
				crc = png_xor32(poly, crc / 2);
			} else {
				crc = crc / 2;
			}
		}
	}
	return png_xor32(crc, 4294967295); // 0xFFFFFFFF
}

png_put_u32be :: (p: *u8, value: u32) {
	p[0] = xx ((value >> 24) & 0xff);
	p[1] = xx ((value >> 16) & 0xff);
	p[2] = xx ((value >> 8) & 0xff);
	p[3] = xx (value & 0xff);
}

png_get_u32be :: (data: [] u8, offset: int) -> u32 {
	b0 := cast(u32) data[offset + 0];
	b1 := cast(u32) data[offset + 1];
	b2 := cast(u32) data[offset + 2];
	b3 := cast(u32) data[offset + 3];
	return (b0 << 24) | (b1 << 16) | (b2 << 8) | b3;
}

png_put_u32be_array :: (out: *[..] u8, value: u32) {
	array_add(out, xx ((value >> 24) & 0xff));
	array_add(out, xx ((value >> 16) & 0xff));
	array_add(out, xx ((value >> 8) & 0xff));
	array_add(out, xx (value & 0xff));
}

png_write_chunk :: (out: *[..] u8, typ: string, data: [] u8) {
	png_put_u32be_array(out, xx data.count);
	type_start := out.count;
	for 0..3 array_add(out, typ[it]);
	for data array_add(out, it);
	span: [] u8 = .{ data = out.data + type_start, count = 4 + data.count };
	png_put_u32be_array(out, png_crc32(span));
}

png_adler32 :: (data: [] u8) -> u32 {
	a: u32 = 1;
	b: u32 = 0;
	for data {
		a = (a + xx it) % 65521;
		b = (b + a) % 65521;
	}
	return (b << 16) | a;
}

png_zlib_store :: (raw: [] u8, allocator := context.allocator) -> [] u8 {
	out: [..] u8;
	out.allocator = allocator;
	array_add(*out, cast(u8) 0x78);
	array_add(*out, cast(u8) 0x01);

	remaining := raw;
	while remaining.count > 0 {
		n := min(remaining.count, 65535);
		last := n == remaining.count;
		array_add(*out, ifx last then cast(u8) 1 else cast(u8) 0);
		lo := n - (n / 256) * 256;
		hi := n / 256;
		array_add(*out, cast(u8) lo);
		array_add(*out, cast(u8) hi);
		array_add(*out, cast(u8) (255 - lo));
		array_add(*out, cast(u8) (255 - hi));
		for 0..n-1 array_add(*out, remaining[it]);
		remaining.data += n;
		remaining.count -= n;
	}
	if raw.count == 0 {
		array_add(*out, cast(u8) 1);
		array_add(*out, cast(u8) 0);
		array_add(*out, cast(u8) 0);
		array_add(*out, cast(u8) 0xff);
		array_add(*out, cast(u8) 0xff);
	}

	adler := png_adler32(raw);
	png_put_u32be_array(*out, adler);
	return out;
}

png_zlib_read_stored :: (zlib: [] u8) -> [] u8, bool {
	if zlib.count < 6 return .{}, false;
	cmf := zlib[0];
	flg := zlib[1];
	if (cmf & 0x0f) != 8 return .{}, false;
	if ((cast(int) cmf * 256 + cast(int) flg) % 31) != 0 return .{}, false;
	if (flg & 0x20) != 0 return .{}, false;

	cursor := 2;
	out: [..] u8;
	out.allocator = temp;
	while cursor < zlib.count - 4 {
		header := zlib[cursor];
		cursor += 1;
		btype := (header >> 1) & 3;
		if btype != 0 return .{}, false;
		if cursor + 4 > zlib.count - 4 return .{}, false;
		len := cast(int) zlib[cursor] + (cast(int) zlib[cursor + 1]) * 256;
		nlen := cast(int) zlib[cursor + 2] + (cast(int) zlib[cursor + 3]) * 256;
		cursor += 4;
		nlen_lo := 255 - (len - (len / 256) * 256);
		nlen_hi := 255 - (len / 256);
		if nlen != nlen_lo + nlen_hi * 256 return .{}, false;
		if cursor + len > zlib.count - 4 return .{}, false;
		old := out.count;
		array_resize(*out, old + len);
		memcpy(out.data + old, zlib.data + cursor, len);
		cursor += len;
		if (header & 1) != 0 {
			if cursor != zlib.count - 4 return .{}, false;
			adler := png_get_u32be(zlib, cursor);
			if png_adler32(out) != adler return .{}, false;
			return out, true;
		}
	}
	return .{}, false;
}

png_abs :: (v: int) -> int {
	if v < 0 return -v;
	return v;
}

png_paeth :: (a: u8, b: u8, c: u8) -> u8 {
	aa := a.(int);
	bb := b.(int);
	cc := c.(int);
	p := aa + bb - cc;
	pa := png_abs(p - aa);
	pb := png_abs(p - bb);
	pc := png_abs(p - cc);
	if pa <= pb && pa <= pc return a;
	if pb <= pc return b;
	return c;
}

png_unfilter :: (filter_byte: u8, row: *u8, prev: [] u8, count: int, bpp: int) -> bool {
	filter := cast(Png_Filter) filter_byte;
	for i: 0..count-1 {
		left := ifx i >= bpp then row[i - bpp] else 0;
		up := ifx prev.data then prev[i] else 0;
		up_left := ifx prev.data && i >= bpp then prev[i - bpp] else 0;
		if #complete filter == {
			case .None;
			case .Sub;
				row[i] += left;
			case .Up;
				row[i] += up;
			case .Average;
				avg := (cast(int) left + cast(int) up) / 2;
				row[i] += xx avg;
			case .Paeth;
				row[i] += png_paeth(left, up, up_left);
			case;
				return false;
		}
	}
	return true;
}
