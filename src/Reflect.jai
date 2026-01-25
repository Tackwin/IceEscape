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

get_field :: (ti: Type_Info_Struct, name: string) -> *Type_Info {
	if ti.type != .STRUCT
		return type_info(void);
	for member: ti.members {
		if compare(member.name, name) == 0
			return member.type;
	}
	return type_info(void);
}

get_field_path :: (ti: Type_Info_Struct, path: string) -> Type_Info {
	names := split(path, ".",, temp);

	sub_ti := ti;
	sub_field: Type_Info;

	for name, name_idx: names {
		if !has_field(sub_ti, name)
			return type_info(void);
		
		sub_field = get_field(sub_ti, name);
		if name_idx == names.count - 1
			return sub_field;
		
		if sub_field.type != .STRUCT
			return type_info(void);
		sub_ti = sub_field.type.(*Type_Info_Struct);
	}
	
	return type_info(void);
}

has_field_path :: (ti: Type_Info_Struct, path: string) -> bool {
	names := split(path, ".",, temp);

	sub_ti := ti;

	for name, name_idx: names {
		if name_idx == names.count - 1
			return has_field(sub_ti, name);
		if !has_field(sub_ti, name)
			return false;
		
		sub := get_field(sub_ti, name);
		if sub.type != .STRUCT
			return false;

		sub_ti = sub.(*Type_Info_Struct);
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
	position_path: string;
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
				if !has_field(element_type, "id")
					continue;

				has_position := false;
				position_path := "";
				if has_field(element_type, "position") {
					position_path = "position";
					has_position = true;
				}

				if !has_position {
					if has_field_path(element_type, "server.position") {
						position_path = "server.position";
						has_position = true;
					}
				}
				if !has_position
					continue;

				entity: Scene_Placeable_Entity;
				entity.name = member.name;
				entity.type = element_type;
				entity.position_path = position_path;
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
	return -1;
}
offset_of_rec :: (type: Type_Info_Struct, member_name: string, offset := 0) -> int {
	delta := offset_of(type, member_name);
	if delta >= 0
		return offset + delta;

	for member: type.members {
		if member.type.type != .STRUCT
			continue;
		sub_type := member.type.(*Type_Info_Struct);
		sub_offset := offset_of_rec(sub_type, member_name, offset + member.offset_in_bytes);
		if sub_offset >= 0
			return sub_offset;
	}
	return -1;
}
member_pointer :: (_info: Type_Info_Struct, base: *void, member_name: string, $type: Type) -> *type {
	info := _info;
	names := split(member_name, ".",, temp);
	for name_idx: 0..names.count - 1 {
		name := names[name_idx];
		if name_idx == names.count - 1 {
			offset := offset_of(info, name);
			if offset < 0
				return null;

			return (base.(int) + offset).(*type);
		} else {
			offset := offset_of(info, name);
			if offset < 0
				return null;

			base = (base.(int) + offset).(*void);
			sub_info := get_field(info, name);
			if sub_info.type != .STRUCT
				return null;

			info = sub_info.(*Type_Info_Struct).*;
		}
	}

	return null;
}
member_pointer_rec :: (info: Type_Info_Struct, base: *void, member_name: string, $type: Type) -> *type {
	offset := offset_of(info, member_name);
	if offset >= 0
		return (base.(int) + offset).(*type);
	
	for member: info.members {
		if member.type.type != .STRUCT
			continue;
		sub_info := member.type.(*Type_Info_Struct);
		sub_base := (base.(int) + member.offset_in_bytes).(*void);
		result := member_pointer_rec(sub_info, sub_base, member_name, type);
		if result != null
			return result;
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
	position_off := offset_of_rec(entity.type, "position");
	data_ptr := (scene.(int) + entity.array_offset + 8).(*int).*;
	pos := (
		data_ptr + position_off + entity.type.runtime_size.(int) * idx
	).(*float);
	return v3(pos[0], pos[1], pos[2]);
}

has_note :: (ti: Type_Info_Struct_Member, note: string) -> bool {
	for member_note: ti.notes {
		if compare(member_note, note) == 0
			return true;
	}
	return false;
}

Edit_Field :: struct {
	path: string;
	type: *Type_Info;
	offset: int;
}

get_edit_fields :: (ti: *Type_Info_Struct) -> [] Edit_Field {
	fields: [..] Edit_Field;
	fields.allocator = temp;
	get_edit_fields(ti, "", 0, *fields);
	return fields;
}
get_edit_fields :: (
	ti: *Type_Info_Struct, path_prefix: string, offset: int, fields: *[..] Edit_Field
) {
	for member: ti.members {
		if has_note(member, "edit") {
			field: Edit_Field;
			field.path = tprint("%1%2", path_prefix, member.name);
			field.type = member.type;
			field.offset = member.offset_in_bytes + offset;
			array_add(fields, field);
		}

		if member.type.type == .STRUCT {
			get_edit_fields(
				member.type.(*Type_Info_Struct),
				tprint("%1%2.", path_prefix, member.name),
				member.offset_in_bytes + offset,
				fields
			);
		}
	}
}