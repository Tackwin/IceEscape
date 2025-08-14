#scope_module
wallocator_g: WAllocator;

max :: (a: $T, b: T) -> T {
	if a > b return a;
	return b;
}

min :: (a: $T, b: T) -> T {
	if a < b return a;
	return b;
}


init_wallocator :: (wallocator: *WAllocator) {
	if !wallocator.backing.proc {
		wallocator.backing = context.default_allocator;
	}

	wallocator.free_nodes.data = wallocator.backing.proc(
		.ALLOCATE, 1024 * size_of(WAllocator.Free_Node), 0, null, wallocator.backing.data
	);
	wallocator.free_nodes_allocated = 1024;
	wallocator.free_nodes.count = 0;
}

grow_free_list :: (wallocator: *WAllocator) {
	new_size := max(1024, wallocator.free_nodes_allocated * 2);

	new_nodes := wallocator.backing.proc(
		.ALLOCATE, new_size * size_of(WAllocator.Free_Node), 0, null, wallocator.backing.data
	).(*WAllocator.Free_Node);
	if !new_nodes {
		return;
	}

	for wallocator.free_nodes {
		new_nodes[it_index] = it;
	}

	wallocator.backing.proc(.FREE, 0, 0, wallocator.free_nodes.data, wallocator.backing.data);
	wallocator.free_nodes.data = new_nodes;
	wallocator.free_nodes_allocated = new_size;
	wallocator.free_nodes.count = wallocator.free_nodes.count;
}

is_magic :: (ptr: *WAllocator.Allocation_Header) -> bool {
	for 0..7
		if ptr.magic[it] != it
			return false;
	return true;
}

// This file is part of the Jai Standard Library.

#scope_export

WAllocator :: struct {
	backing: Allocator;

	Free_Node :: struct {
		begin: *void;
		size: s64;
	}

	Allocation_Header :: struct {
		magic: [8]u8 = .[ 0, 1, 2, 3, 4, 5, 6, 7 ];
		begin: *void;
		size: s64;
	}

	free_nodes: [] Free_Node;
	free_nodes_allocated := 0;
	chunk_size: s64 = 1024*64;

	alignment : s64 = 8;
}


wallocator_proc :: (
	mode: Allocator_Mode, size: s64, old_size: s64, old_memory: *void, allocator_data: *void
) -> *void
{
	wallocator := *wallocator_g;
	if allocator_data
		wallocator = allocator_data.(*WAllocator);

	if mode == {
		case .ALLOCATE;
			if wallocator.free_nodes.count == 0 {
				init_wallocator(wallocator);
			}

			whole_size := size + size_of(WAllocator.Allocation_Header);
			// Align whole_size to the alignment.
			// whole_size = (whole_size + wallocator.alignment - 1) & ~(wallocator.alignment - 1);

			// Look for a free node
			for * wallocator.free_nodes {
				padding_to_align := wallocator.alignment - (it.begin.(s64) % wallocator.alignment);

				if it.size >= whole_size + padding_to_align {
					// If we found a free node, use it

					ptr := it.begin;
					ptr += padding_to_align;
					header := ptr.(*WAllocator.Allocation_Header);
					header.* = .{};
					header.size = whole_size + padding_to_align;
					header.begin = it.begin;
					ptr += size_of(WAllocator.Allocation_Header);

					it.size -= padding_to_align + whole_size;
					it.begin += padding_to_align + whole_size;
					if it.size == 0
						remove it;

					memset(ptr, 0xCC, size);
					return ptr;
				}
			}

			// Otherwise, we need to allocate a new chunk

			node: WAllocator.Free_Node;
			node.size = max(whole_size, wallocator.chunk_size);
			node.begin = wallocator.backing.proc(
				.ALLOCATE, node.size, 0, null, wallocator.backing.data
			);
			if !node.begin {
				return null;
			}

			padding_to_align := wallocator.alignment - (node.begin.(s64) % wallocator.alignment);
			ptr := node.begin;
			ptr += padding_to_align;
			header := ptr.(*WAllocator.Allocation_Header);
			header.* = .{};
			header.begin = node.begin;
			header.size = whole_size + padding_to_align;
			ptr += size_of(WAllocator.Allocation_Header);

			node.size -= padding_to_align + whole_size;
			node.begin += padding_to_align + whole_size;
			if node.size > 0 {
				wallocator.free_nodes.count += 1;
				wallocator.free_nodes[wallocator.free_nodes.count - 1] = node;
			}

			memset(ptr, 0xCC, size);
			return ptr;
		
		case .FREE;
			memset(old_memory, 0xDD, old_size);

			if !old_memory {
				return null;
			}

			header := (old_memory - size_of(WAllocator.Allocation_Header))
				.(*WAllocator.Allocation_Header);
			if !is_magic(header) {
				write_string("Invalid allocation header!\n");
				return null; // Invalid header
			}

			// We need to add the freed memory the free list.
			// But let's look to see if we can merge it with an existing free node.

			for * wallocator.free_nodes {
				if it.begin + it.size == header.begin {
					// The freed memory is right after this free node, so we can merge them.
					it.size += header.size;
					return null;
				}
				if header.begin + header.size == it.begin {
					// The freed memory is right before this free node, so we can merge them.
					it.begin = header.begin;
					it.size += header.size;
					return null;
				}
			}

			// If we reach here, it means we couldn't merge the freed memory with any existing free
			// node, so we need to add it as a new free node.

			// First we check if there is an empty slot in our free_node array to receive to new
			// chunk.

			if wallocator.free_nodes_allocated <= wallocator.free_nodes.count {
				// If there isn't, we need to reallocate all of our chunks with more spaces.
				grow_free_list(wallocator);
			}

			new: WAllocator.Free_Node;
			new.begin = header.begin;
			new.size = header.size;
			wallocator.free_nodes.count += 1;
			wallocator.free_nodes[wallocator.free_nodes.count - 1] = new;
		case .RESIZE;
			new_ptr := wallocator_proc(
				.ALLOCATE, size, old_size, old_memory, allocator_data
			);

			if !new_ptr {
				return null;
			}

			memcpy(
				new_ptr, old_memory, min(size, old_size)
			);

			wallocator_proc(.FREE, 0, 0, old_memory, allocator_data);
			return new_ptr;
		case .CAPS;
			return xx Allocator_Caps.FREE;
	}
	return null;
}
