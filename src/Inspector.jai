Reflection :: #import "Reflection";
#load "imgui_sdl_gl.jai";

inspect :: (name: *u8, t : *$T) {

    ImGui.Begin(name, *show_inspector);

    inspect(name, t, type_info(T));

    ImGui.End();
}


inspect :: (name: *u8, data: *void, info:*Type_Info) {
    default_size: ImGui.ImVec2;

    using Type_Info_Tag;
    if #complete info.type == {
        case INTEGER;
            info_int := cast(*Type_Info_Integer) info;
            ImGui.InputInt(name, data); // @@ Add support for unsigned, and larger int types.
        case FLOAT;
            if info.runtime_size == {
                case 4;
                    //ImGui.DragFloat(name, data, display_format="%.3f");
                    ImGui.InputFloat(name, data, 0.01, 1.0);
                case 8;
                    x : float = xx <<cast(*float64) data;
                    if ImGui.InputFloat(name, *x, 0.01, 1.0) { <<cast(*float64) data = x; };
            }
        case BOOL;
            //ImGui.Checkbox(name, data);
            index : s32 = xx <<cast(*bool)data;
            if ImGui.Combo(name, *index, "false\0true\0\0") { <<cast(*bool)data = xx index; };
        case STRING;
            s := << cast(*string) data;  // For now we assume non-relative strings only.
            if s.count ImGui.InputText(name, s.data, xx s.count, ImGui.InputTextFlags.ReadOnly);    // @@ We could allow editing of strings too.
            else ImGui.InputText(name, "(null)", 6, ImGui.InputTextFlags.ReadOnly);

        case POINTER;
            // @@ Open in new window?
            ImGui.Text("pointer");
        case PROCEDURE;
            ImGui.Text("procedure");
        case VOID;
            ImGui.Text("void");
        case CODE;
            ImGui.Text("Code");
        case STRUCT;
            info_struct := cast(*Type_Info_Struct) info;
            if ImGui.TreeNode(name, "%: %", to_string(name), info_struct.name) {
                for member: info_struct.members {
                    inspect(temp_c_string(member.name), data + member.offset_in_bytes, member.type);
                }
                ImGui.TreePop();
            }
        case ARRAY;
            info_array := cast(*Type_Info_Array) info;
            array_count, array_data := Reflection.get_array_count_and_data(data, info_array);
            array_name := to_string(name);
            element_size := info_array.element_type.runtime_size;
            if ImGui.TreeNode(name, "% (count = %)", array_name, array_count) {
                for 0..array_count-1 {
                    item_name := temp_c_string(tprint("%[%]", array_name, it));
                    inspect(item_name, array_data + it * element_size, info_array.element_type);
                }
                ImGui.TreePop();
            }
        case ANY;
            // @@ Display type and inspect value.
            ImGui.Text("Any!");
        case ENUM;
            info_enum := cast(*Type_Info_Enum) info;

            if info_enum.enum_type_flags & .FLAGS {
                // @@ How to handle flags?
            }
            else {
                value := Reflection.get_enum_value(data, info_enum);
                value_name := "";
                for info_enum.names {
                    if value == info_enum.values[it_index]  value_name = it;
                }

                if ImGui.BeginCombo(name, temp_c_string(value_name)) {
                    for info_enum.names {
                        is_selected := value == info_enum.values[it_index];
                        if ImGui.Selectable(temp_c_string(it), is_selected, size=*default_size) {
                            Reflection.set_enum_value(data, info_enum, info_enum.values[it_index]);
                        }
                        if is_selected ImGui.SetItemDefaultFocus();
                    }

                    ImGui.EndCombo();
                }
            }


        case POLYMORPHIC_VARIABLE;
            // @@ ??
        case TYPE;
            // @@
        case OVERLOAD_SET;
            // @@
        case VARIANT;
        // @Incomplete: Can do something better here.
            tiv := cast(*Type_Info_Variant) info;
            inspect(name, data, tiv.variant_of);
        case UNTYPED_LITERAL;
            ImGui.Text("(untyped literal)");
        case UNTYPED_ENUM;
            ImGui.Text("(untyped enum)");
    }

}
