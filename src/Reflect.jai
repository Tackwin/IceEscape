#scope_file
#import "Basic";
#import "String";
#import "Algebra";
Scene :: #import "Scene";

#scope_export

has_field :: (ti: Type_Info_Struct, name: string) -> bool {
	if ti.type != .STRUCT
		return false;
	for member: ti.members {
		if compare(member.name, name) == 0
			return true;
	}
	return false;
}

type_info_to_type :: (info: Type_Info) -> Type {
	ptr := *info;
	ptr_type := ptr.(*Type);
	return ptr_type.*;
}

list_array_element_type :: (ti: Type_Info_Struct) -> [] Type_Info {
	subs: [..] Type_Info;
	subs.allocator = temp;
	
	for member: scene_info.members {
		if member.type.type != .ARRAY
			continue;

		member_array := member.type.(*Type_Info_Array);
		if member_array.array_type == .RESIZABLE {
			array_add(*subs, member_array.element_type);
		}
	}

	return subs;
}


Scene_Placeable_Entity :: struct {
	name: string;
	type: Type_Info_Struct;
	array_offset : s64 = 0;
}

get_scene_placeable_entities :: () -> [] Scene_Placeable_Entity {
	list: [..] Scene_Placeable_Entity;
	list.allocator = temp;

	scene_info := type_info(Scene.Scene);
	for member: scene_info.members {
		if member.type.type != .ARRAY
			continue;

		member_array := member.type.(*Type_Info_Array);
		if member_array.array_type == .RESIZABLE {
			if member_array.element_type.type == .STRUCT {
				element_type := member_array.element_type.(*Type_Info_Struct);
				if !has_field(element_type, "position")
					continue;
				if !has_field(element_type, "id")
					continue;

				entity: Scene_Placeable_Entity;
				entity.name = member.name;
				entity.type = element_type;
				entity.array_offset = member.offset_in_bytes;
				array_add(*list, entity);
			}
		}
	}

	return list;
}

offset_of :: (type: Type_Info_Struct, member_name: string) -> int {
	for member: type.members {
		if compare(member.name, member_name) == 0
			return xx member.offset_in_bytes;
	}
	return 0;
}
member_pointer :: (data: *$T, member_name: string, $type: Type) -> *type {
	ti := type_info(data);
	if ti.type != .STRUCT
		return null;
	ti_struct := ti.(*Type_Info_Struct);
	return member_pointer(ti_struct, data.(*void), member_name, type);
}
member_pointer :: (info: Type_Info_Struct, base: *void, member_name: string, $type: Type) -> *type {
	for member: info.members {
		if compare(member.name, member_name) == 0
			return ((*base).(int) + member.offset_in_bytes).(*type);
	}
	return null;
}

get_count :: (scene: *Scene.Scene, entity: Scene_Placeable_Entity) -> int {
	return (scene.(int) + entity.array_offset).(*int).*;
}
get_pointer  :: (scene: *Scene.Scene, entity: Scene_Placeable_Entity, idx: int) -> *void {
	data_ptr := (scene.(int) + entity.array_offset + 8).(*int).*;
	return (data_ptr + entity.type.runtime_size * idx).(*void);
}

get_position :: (scene: *Scene.Scene, entity: Scene_Placeable_Entity, idx: int) -> V3f {
	position_off := offset_of(entity.type, "position");
	data_ptr := (scene.(int) + entity.array_offset + 8).(*int).*;
	pos := (
		data_ptr + position_off + entity.type.runtime_size.(int) * idx
	).(*float);
	return v3(pos[0], pos[1], pos[2]);
}
