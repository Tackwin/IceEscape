// Small PNG reader/writer. Top-left origin, no interlacing.
// Writer uses zlib stored blocks (no compression) so the bytes stay readable.
// Reader accepts RGB8/RGBA8, filter 0-4, and zlib (stored or deflate).

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

write_rgba :: (rgba: [] u8, width: int, height: int, out: *[..] u8) -> bool {
	if width <= 0 || height <= 0 return false;
	expected := width * height * 4;
	if rgba.count < expected return false;

	out.count = 0;
	for PNG_SIGNATURE array_add(out, it);

	ihdr: [13] u8;
	png_put_u32be(*ihdr[0], xx width);
	png_put_u32be(*ihdr[4], xx height);
	ihdr[8] = 8;
	ihdr[9] = 6;
	ihdr[10] = 0;
	ihdr[11] = 0;
	ihdr[12] = 0;
	png_write_chunk(out, "IHDR", ihdr);

	row_bytes := 1 + width * 4;
	raw_count := row_bytes * height;
	raw := NewArray(raw_count, u8,, temp);
	for y: 0..height-1 {
		row := y * row_bytes;
		raw[row] = 0;
		src := y * width * 4;
		memcpy(raw.data + row + 1, rgba.data + src, width * 4);
	}

	zlib := png_zlib_store(raw,, temp);
	png_write_chunk(out, "IDAT", zlib);
	iend: [] u8;
	png_write_chunk(out, "IEND", iend);
	return true;
}

read_rgb :: (data: [] u8, rgb: *[..] u8, width: *int, height: *int) -> bool {
	rgba: [..] u8;
	rgba.allocator = rgb.allocator;
	if !read_rgba(data, *rgba, width, height) return false;
	count := width.* * height.*;
	array_resize(rgb, count * 3);
	for x: 0..count-1 {
		rgb.data[x * 3 + 0] = rgba[x * 4 + 0];
		rgb.data[x * 3 + 1] = rgba[x * 4 + 1];
		rgb.data[x * 3 + 2] = rgba[x * 4 + 2];
	}
	return true;
}

read_rgba :: (data: [] u8, rgba: *[..] u8, width: *int, height: *int) -> bool {
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

	raw, ok := png_zlib_inflate(idat);
	if !ok return false;

	channels := ifx color_type == 2 then 3 else 4;
	row_bytes := 1 + w * channels;
	if raw.count != row_bytes * h return false;

	array_resize(rgba, w * h * 4);
	prev: [] u8;
	for y: 0..h-1 {
		row := raw.data + y * row_bytes;
		filter := row[0];
		pixels := row + 1;
		pixel_bytes := w * channels;
		if !png_unfilter(filter, pixels, prev, pixel_bytes, channels) return false;
		prev = .{ data = pixels, count = pixel_bytes };
		dst := rgba.data + y * w * 4;
		if channels == 4 {
			memcpy(dst, pixels, w * 4);
		} else {
			for x: 0..w-1 {
				dst[x * 4 + 0] = pixels[x * 3 + 0];
				dst[x * 4 + 1] = pixels[x * 3 + 1];
				dst[x * 4 + 2] = pixels[x * 3 + 2];
				dst[x * 4 + 3] = 255;
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

PNG_DEFLATE_MAXBITS :: 15;

Png_Deflate :: struct {
	data: [] u8;
	byte_i: int;
	bitbuf: u32;
	bitcnt: int;
	out: [..] u8;
}

Png_Huff :: struct {
	count: [16] int;
	symbol: [288] int;
}

png_deflate_bit :: (s: *Png_Deflate) -> u32, bool {
	if s.bitcnt == 0 {
		if s.byte_i >= s.data.count return 0, false;
		s.bitbuf = s.data[s.byte_i];
		s.byte_i += 1;
		s.bitcnt = 8;
	}
	bit := s.bitbuf & 1;
	s.bitbuf = s.bitbuf / 2;
	s.bitcnt -= 1;
	return bit, true;
}

png_deflate_bits :: (s: *Png_Deflate, n: int) -> u32, bool {
	value: u32 = 0;
	for i: 0..n-1 {
		bit, ok := png_deflate_bit(s);
		if !ok return 0, false;
		value |= bit << i;
	}
	return value, true;
}

png_deflate_align_byte :: (s: *Png_Deflate) {
	s.bitcnt = 0;
}

png_huff_construct :: (h: *Png_Huff, length: [] u8) -> bool {
	for i: 0..15 h.count[i] = 0;
	for length {
		if it > PNG_DEFLATE_MAXBITS return false;
		h.count[it] += 1;
	}
	if h.count[0] == length.count return true;

	left := 1;
	for len: 1..PNG_DEFLATE_MAXBITS {
		left *= 2;
		left -= h.count[len];
		if left < 0 return false;
	}

	offs: [16] int;
	offs[1] = 0;
	for len: 1..PNG_DEFLATE_MAXBITS-1 {
		offs[len + 1] = offs[len] + h.count[len];
	}
	for symbol: 0..length.count-1 {
		len := length[symbol].(int);
		if len == 0 continue;
		h.symbol[offs[len]] = symbol;
		offs[len] += 1;
	}
	return true;
}

png_huff_decode :: (s: *Png_Deflate, h: *Png_Huff) -> int, bool {
	code := 0;
	first := 0;
	index := 0;
	for len: 1..PNG_DEFLATE_MAXBITS {
		bit, ok := png_deflate_bit(s);
		if !ok return 0, false;
		code |= xx bit;
		count := h.count[len];
		if code - first < count return h.symbol[index + (code - first)], true;
		index += count;
		first += count;
		first *= 2;
		code *= 2;
	}
	return 0, false;
}

png_len_base :: u16.[
	3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31,
	35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258
];
png_len_extra :: u8.[
	0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2,
	3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0
];
png_dist_base :: u16.[
	1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193,
	257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577
];
png_dist_extra :: u8.[
	0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6,
	7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13
];
png_clen_order :: u8.[16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15];

png_deflate_copy :: (s: *Png_Deflate, dist: int, length: int) -> bool {
	if dist < 1 || dist > s.out.count return false;
	for 0..length-1 {
		array_add(*s.out, s.out[s.out.count - dist]);
	}
	return true;
}

png_deflate_codes :: (s: *Png_Deflate, lit: *Png_Huff, dist: *Png_Huff) -> bool {
	while true {
		symbol, ok := png_huff_decode(s, lit);
		if !ok return false;
		if symbol < 256 {
			array_add(*s.out, xx symbol);
			continue;
		}
		if symbol == 256 return true;
		if symbol > 285 return false;

		len_i := symbol - 257;
		length := png_len_base[len_i].(int);
		extra := png_len_extra[len_i].(int);
		if extra > 0 {
			add, extra_ok := png_deflate_bits(s, extra);
			if !extra_ok return false;
			length += xx add;
		}

		dsymbol, dist_ok := png_huff_decode(s, dist);
		if !dist_ok return false;
		if dsymbol > 29 return false;
		distance := png_dist_base[dsymbol].(int);
		dextra := png_dist_extra[dsymbol].(int);
		if dextra > 0 {
			add, extra_ok := png_deflate_bits(s, dextra);
			if !extra_ok return false;
			distance += xx add;
		}
		if !png_deflate_copy(s, distance, length) return false;
	}
	return false;
}

png_deflate_stored :: (s: *Png_Deflate) -> bool {
	png_deflate_align_byte(s);
	if s.byte_i + 4 > s.data.count return false;
	len := cast(int) s.data[s.byte_i] + (cast(int) s.data[s.byte_i + 1]) * 256;
	nlen := cast(int) s.data[s.byte_i + 2] + (cast(int) s.data[s.byte_i + 3]) * 256;
	s.byte_i += 4;
	if nlen != 65535 - len return false;
	if s.byte_i + len > s.data.count return false;
	for 0..len-1 {
		array_add(*s.out, s.data[s.byte_i]);
		s.byte_i += 1;
	}
	return true;
}

png_deflate_fixed :: (s: *Png_Deflate) -> bool {
	length: [288] u8;
	for i: 0..143 length[i] = 8;
	for i: 144..255 length[i] = 9;
	for i: 256..279 length[i] = 7;
	for i: 280..287 length[i] = 8;
	lit: Png_Huff;
	if !png_huff_construct(*lit, length) return false;

	dlength: [32] u8;
	for i: 0..31 dlength[i] = 5;
	dist: Png_Huff;
	if !png_huff_construct(*dist, dlength) return false;

	return png_deflate_codes(s, *lit, *dist);
}

png_deflate_dynamic :: (s: *Png_Deflate) -> bool {
	hlit, hlit_ok := png_deflate_bits(s, 5);
	hdist, hdist_ok := png_deflate_bits(s, 5);
	hclen, hclen_ok := png_deflate_bits(s, 4);
	if !hlit_ok || !hdist_ok || !hclen_ok return false;
	nlit := 257 + xx hlit;
	ndist := 1 + xx hdist;
	nclen := 4 + xx hclen;
	if nlit > 288 || ndist > 32 || nclen > 19 return false;

	clen_len: [19] u8;
	for i: 0..nclen-1 {
		bits, ok := png_deflate_bits(s, 3);
		if !ok return false;
		clen_len[png_clen_order[i]] = xx bits;
	}
	clen: Png_Huff;
	if !png_huff_construct(*clen, clen_len) return false;

	lengths: [320] u8;
	n := nlit + ndist;
	i := 0;
	while i < n {
		symbol, ok := png_huff_decode(s, *clen);
		if !ok return false;
		if symbol < 16 {
			lengths[i] = xx symbol;
			i += 1;
			continue;
		}
		fill: u8 = 0;
		rep := 0;
		if symbol == 16 {
			if i == 0 return false;
			fill = lengths[i - 1];
			extra, extra_ok := png_deflate_bits(s, 2);
			if !extra_ok return false;
			rep = 3 + xx extra;
		} else if symbol == 17 {
			extra, extra_ok := png_deflate_bits(s, 3);
			if !extra_ok return false;
			rep = 3 + xx extra;
		} else if symbol == 18 {
			extra, extra_ok := png_deflate_bits(s, 7);
			if !extra_ok return false;
			rep = 11 + xx extra;
		} else {
			return false;
		}
		if i + rep > n return false;
		for 0..rep-1 {
			lengths[i] = fill;
			i += 1;
		}
	}

	lit: Png_Huff;
	lit_len: [] u8;
	lit_len.data = xx *lengths[0];
	lit_len.count = nlit;
	if !png_huff_construct(*lit, lit_len) return false;

	dist: Png_Huff;
	dist_len: [] u8;
	dist_len.data = xx *lengths[nlit];
	dist_len.count = ndist;
	if !png_huff_construct(*dist, dist_len) return false;

	return png_deflate_codes(s, *lit, *dist);
}

png_zlib_inflate :: (zlib: [] u8) -> [] u8, bool {
	if zlib.count < 6 return .{}, false;
	cmf := zlib[0];
	flg := zlib[1];
	if (cmf & 0x0f) != 8 return .{}, false;
	if ((cast(int) cmf * 256 + cast(int) flg) % 31) != 0 return .{}, false;
	if (flg & 0x20) != 0 return .{}, false;

	s: Png_Deflate;
	s.data.data = zlib.data + 2;
	s.data.count = zlib.count - 6;
	s.out.allocator = temp;

	last := false;
	while !last {
		bfinal, final_ok := png_deflate_bits(*s, 1);
		btype, type_ok := png_deflate_bits(*s, 2);
		if !final_ok || !type_ok return .{}, false;
		last = bfinal != 0;
		ok := false;
		if btype == 0 {
			ok = png_deflate_stored(*s);
		} else if btype == 1 {
			ok = png_deflate_fixed(*s);
		} else if btype == 2 {
			ok = png_deflate_dynamic(*s);
		}
		if !ok return .{}, false;
	}

	adler := png_get_u32be(zlib, zlib.count - 4);
	if png_adler32(s.out) != adler return .{}, false;
	return s.out, true;
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
