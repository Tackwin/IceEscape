#import "Basic";
#import "Math";
#import "Platform";
#if OS == .WINDOWS {
    ImGui :: #import "ImGui";
}

#scope_export

// Data
g_FontTexture: GLuint = 0;
g_ShaderHandle: GLuint = 0;
g_VertHandle: GLuint = 0;
g_FragHandle: GLuint = 0;
g_AttribLocationTex: GLint = 0;
g_AttribLocationProjMtx: GLint = 0;
g_AttribLocationPosition: GLuint = 0;
g_AttribLocationUV: GLuint = 0;
g_AttribLocationColor: GLuint = 0;
g_VboHandle: GLuint = 0;
g_VaoHandle: GLuint = 0;
g_ElementsHandle: GLuint = 0;

// This is the main rendering function that you have to implement and provide to ImGui (via setting up 'RenderDrawListsFn' in the ImGuiIO structure)
// Note that this implementation is little overcomplicated because we are saving/setting up/restoring every OpenGL state explicitly, in order to be able to run within any OpenGL engine that doesn't do so.
// If text or lines are blurry when integrating ImGui in your engine: in your Render function, try translating your projection matrix by (0.5f,0.5f) or (0.375f,0.375f)
ImGui_ImplSdl_RenderDrawLists :: (rhi: RHI_proc, draw_data: *ImGui.ImDrawData) #c_call {
    // @@ Watch out, we don't have a context here!

    // Avoid rendering when minimized, scale coordinates for retina displays (screen coordinates != framebuffer coordinates)
    io := ImGui.GetIO();
    fb_width := (io.DisplaySize.x * io.DisplayFramebufferScale.x);
    fb_height := (io.DisplaySize.y * io.DisplayFramebufferScale.y);
    if fb_width == 0 || fb_height == 0 return;
    draw_data.ScaleClipRects(draw_data, *io.DisplayFramebufferScale);

    // Backup GL state
    last_active_texture: GLenum;        rhi.glGetIntegerv(GL_ACTIVE_TEXTURE, xx *last_active_texture);
    last_program: GLuint;               rhi.glGetIntegerv(GL_CURRENT_PROGRAM, xx *last_program);
    last_texture: GLuint;               rhi.glGetIntegerv(GL_TEXTURE_BINDING_2D, xx *last_texture);
    last_sampler: GLuint;               rhi.glGetIntegerv(GL_SAMPLER_BINDING, xx *last_sampler);
    last_array_buffer: GLuint;          rhi.glGetIntegerv(GL_ARRAY_BUFFER_BINDING, xx *last_array_buffer);
    last_element_array_buffer: GLuint;  rhi.glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, xx *last_element_array_buffer);
    last_vertex_array: GLuint;          rhi.glGetIntegerv(GL_VERTEX_ARRAY_BINDING, xx *last_vertex_array);
    last_polygon_mode: [2]GLuint;       rhi.glGetIntegerv(GL_POLYGON_MODE, xx last_polygon_mode.data);
    last_viewport: [4]GLint;            rhi.glGetIntegerv(GL_VIEWPORT, last_viewport.data);
    last_scissor_box : [4]GLint;        rhi.glGetIntegerv(GL_SCISSOR_BOX, last_scissor_box.data);
    last_blend_src_rgb: GLenum;         rhi.glGetIntegerv(GL_BLEND_SRC_RGB, xx *last_blend_src_rgb);
    last_blend_dst_rgb: GLenum;         rhi.glGetIntegerv(GL_BLEND_DST_RGB, xx *last_blend_dst_rgb);
    last_blend_src_alpha: GLenum;       rhi.glGetIntegerv(GL_BLEND_SRC_ALPHA, xx *last_blend_src_alpha);
    last_blend_dst_alpha: GLenum;       rhi.glGetIntegerv(GL_BLEND_DST_ALPHA, xx *last_blend_dst_alpha);
    last_blend_equation_rgb: GLenum;    rhi.glGetIntegerv(GL_BLEND_EQUATION_RGB, xx *last_blend_equation_rgb);
    last_blend_equation_alpha: GLenum;  rhi.glGetIntegerv(GL_BLEND_EQUATION_ALPHA, xx *last_blend_equation_alpha);
    last_enable_blend :=                rhi.glIsEnabled(GL_BLEND);
    last_enable_cull_face :=            rhi.glIsEnabled(GL_CULL_FACE);
    last_enable_depth_test :=           rhi.glIsEnabled(GL_DEPTH_TEST);
    last_enable_scissor_test :=         rhi.glIsEnabled(GL_SCISSOR_TEST);

    // Setup render state: alpha-blending enabled, no face culling, no depth testing, scissor enabled, polygon fill
    rhi.glActiveTexture(GL_TEXTURE0);
    rhi.glEnable(GL_BLEND);
    rhi.glBlendEquation(GL_FUNC_ADD);
    rhi.glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    rhi.glDisable(GL_CULL_FACE);
    rhi.glDisable(GL_DEPTH_TEST);
    rhi.glEnable(GL_SCISSOR_TEST);
    rhi.glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);

    // Setup viewport, orthographic projection matrix
    rhi.glViewport(0, 0, xx fb_width, xx fb_height);

    push_context {
        ortho_projection := orthographic_projection_matrix(0, io.DisplaySize.x, io.DisplaySize.y, 0, 0, 1);
        ortho_projection = transpose(ortho_projection);

        rhi.glUseProgram(g_ShaderHandle);
        rhi.glUniform1i(g_AttribLocationTex, 0);
        rhi.glUniformMatrix4fv(g_AttribLocationProjMtx, 1, GL_FALSE, xx *ortho_projection);
        rhi.glBindVertexArray(g_VaoHandle);
        rhi.glBindSampler(0, 0); // Rely on combined texture/sampler state.

        // Render command lists
        for n: 0..draw_data.CmdListsCount-1 {
            cmd_list := draw_data.CmdLists[n];
            idx_buffer_offset : *ImGui.ImDrawIdx;

            rhi.glBindBuffer(GL_ARRAY_BUFFER, g_VboHandle);
            rhi.glBufferData(GL_ARRAY_BUFFER, cmd_list.VtxBuffer.Size * size_of(ImGui.ImDrawVert), cmd_list.VtxBuffer.Data, GL_STREAM_DRAW);

            rhi.glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, g_ElementsHandle);
            rhi.glBufferData(GL_ELEMENT_ARRAY_BUFFER, cmd_list.IdxBuffer.Size * size_of(ImGui.ImDrawIdx), cmd_list.IdxBuffer.Data, GL_STREAM_DRAW);

            for cmd_i: 0..cmd_list.CmdBuffer.Size-1 {
                pcmd := *cmd_list.CmdBuffer.Data[cmd_i];
                if pcmd.UserCallback {
                    pcmd.UserCallback(cmd_list, pcmd);
                }
                else {
                    rhi.glBindTexture(GL_TEXTURE_2D, xx pcmd.TextureId);
                    rhi.glScissor(xx pcmd.ClipRect.x, xx (fb_height - pcmd.ClipRect.w), xx (pcmd.ClipRect.z - pcmd.ClipRect.x), xx (pcmd.ClipRect.w - pcmd.ClipRect.y));

                    rhi.glDrawElements(GL_TRIANGLES, pcmd.ElemCount, GL_UNSIGNED_SHORT, idx_buffer_offset);
                }
                idx_buffer_offset += pcmd.ElemCount;
            }
        }

        // Restore modified GL state
        rhi.glUseProgram(last_program);
        rhi.glBindTexture(GL_TEXTURE_2D, last_texture);
        rhi.glBindSampler(0, last_sampler);
        rhi.glActiveTexture(last_active_texture);
        rhi.glBindVertexArray(last_vertex_array);
        rhi.glBindBuffer(GL_ARRAY_BUFFER, last_array_buffer);
        rhi.glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, last_element_array_buffer);
        rhi.glBlendEquationSeparate(last_blend_equation_rgb, last_blend_equation_alpha);
        rhi.glBlendFuncSeparate(last_blend_src_rgb, last_blend_dst_rgb, last_blend_src_alpha, last_blend_dst_alpha);
        if last_enable_blend        rhi.glEnable(GL_BLEND);         else rhi.glDisable(GL_BLEND);
        if last_enable_cull_face    rhi.glEnable(GL_CULL_FACE);     else rhi.glDisable(GL_CULL_FACE);
        if last_enable_depth_test   rhi.glEnable(GL_DEPTH_TEST);    else rhi.glDisable(GL_DEPTH_TEST);
        if last_enable_scissor_test rhi.glEnable(GL_SCISSOR_TEST);  else rhi.glDisable(GL_SCISSOR_TEST);
        rhi.glPolygonMode(GL_FRONT_AND_BACK, last_polygon_mode[0]);
        rhi.glViewport(last_viewport[0], last_viewport[1], xx last_viewport[2], xx last_viewport[3]);
        rhi.glScissor(last_scissor_box[0], last_scissor_box[1], xx last_scissor_box[2], xx last_scissor_box[3]);
    }
}

// You can read the io.WantCaptureMouse, io.WantCaptureKeyboard flags to tell if dear imgui wants to use your inputs.
// - When io.WantCaptureMouse is true, do not dispatch mouse input data to your main application.
// - When io.WantCaptureKeyboard is true, do not dispatch keyboard input data to your main application.
// Generally you may always pass all inputs to dear imgui, and hide them from your application based on those two flags.

ImGui_ImplSdl_CreateFontsTexture :: (rhi: RHI_proc) -> bool {
    // Build texture atlas
    io := ImGui.GetIO();
    pixels: *u8;
    width, height: s32;
    bpp: s32;
    io.Fonts.GetTexDataAsAlpha8(io.Fonts, *pixels, *width, *height, *bpp);
    //io.Fonts.GetTexDataAsRGBA32(io.Fonts, *pixels, *width, *height);

    // Upload texture to graphics system
    last_texture: GLuint;
    rhi.glGetIntegerv(GL_TEXTURE_BINDING_2D, xx *last_texture);

    rhi.glGenTextures(1, *g_FontTexture);
    rhi.glBindTexture(GL_TEXTURE_2D, g_FontTexture);
    rhi.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    rhi.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    //glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
    rhi.glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, xx width, xx height, 0, GL_RED, GL_UNSIGNED_BYTE, pixels);
    //glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, xx width, xx height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);

    // Store our identifier
    io.Fonts.TexID = xx g_FontTexture;

    // Restore state
    rhi.glBindTexture(GL_TEXTURE_2D, last_texture);

    return true;
}

ImGui_ImplSdl_CreateDeviceObjects ::(rhi: RHI_proc) -> bool {
    // Backup GL state
    last_texture, last_array_buffer, last_vertex_array: GLuint;
    rhi.glGetIntegerv(GL_TEXTURE_BINDING_2D, xx *last_texture);
    rhi.glGetIntegerv(GL_ARRAY_BUFFER_BINDING, xx *last_array_buffer);
    rhi.glGetIntegerv(GL_VERTEX_ARRAY_BINDING, xx *last_vertex_array);

    vertex_shader := #string END
        #version 330
        uniform mat4 ProjMtx;
        in vec2 Position;
        in vec2 UV;
        in vec4 Color;
        out vec2 Frag_UV;
        out vec4 Frag_Color;
        void main() {
           Frag_UV = UV;
           Frag_Color = Color;
           gl_Position = ProjMtx * vec4(Position.xy,0,1);
        }
    END

    fragment_shader := #string END
        #version 330
        uniform sampler2D Texture;
        in vec2 Frag_UV;
        in vec4 Frag_Color;
        out vec4 Out_Color;
        void main() {
           Out_Color = Frag_Color * texture( Texture, Frag_UV.st).r;
        }
    END

    g_ShaderHandle = rhi.glCreateProgram();
    g_VertHandle = rhi.glCreateShader(GL_VERTEX_SHADER);
    g_FragHandle = rhi.glCreateShader(GL_FRAGMENT_SHADER);

    {
        length : GLint = xx vertex_shader.count;
        rhi.glShaderSource(g_VertHandle, 1, *vertex_shader.data, *length);
    }
    {
        length : GLint = xx fragment_shader.count;
        rhi.glShaderSource(g_FragHandle, 1, *fragment_shader.data, *length);
    }
    rhi.glCompileShader(g_VertHandle);
    rhi.glCompileShader(g_FragHandle);
    rhi.glAttachShader(g_ShaderHandle, g_VertHandle);
    rhi.glAttachShader(g_ShaderHandle, g_FragHandle);
    rhi.glLinkProgram(g_ShaderHandle);

    g_AttribLocationTex = rhi.glGetUniformLocation(g_ShaderHandle, "Texture");
    g_AttribLocationProjMtx = rhi.glGetUniformLocation(g_ShaderHandle, "ProjMtx");
    g_AttribLocationPosition = xx rhi.glGetAttribLocation(g_ShaderHandle, "Position");
    g_AttribLocationUV = xx rhi.glGetAttribLocation(g_ShaderHandle, "UV");
    g_AttribLocationColor = xx rhi.glGetAttribLocation(g_ShaderHandle, "Color");

    rhi.glGenBuffers(1, *g_VboHandle);
    rhi.glGenBuffers(1, *g_ElementsHandle);

    rhi.glGenVertexArrays(1, *g_VaoHandle);
    rhi.glBindVertexArray(g_VaoHandle);
    rhi.glBindBuffer(GL_ARRAY_BUFFER, g_VboHandle);
    rhi.glEnableVertexAttribArray(g_AttribLocationPosition);
    rhi.glEnableVertexAttribArray(xx g_AttribLocationUV);
    rhi.glEnableVertexAttribArray(xx g_AttribLocationColor);

    // @@ Is there a function to easily get the offset of a member?
    //ImDrawVert :: struct {
    //   pos: ImVec2;       // 0
    //   uv: ImVec2;        // 8
    //   col: s32;          // 16
    //}
    rhi.glVertexAttribPointer(g_AttribLocationPosition, 2, GL_FLOAT, GL_FALSE, size_of(ImGui.ImDrawVert), xx 0);
    rhi.glVertexAttribPointer(g_AttribLocationUV, 2, GL_FLOAT, GL_FALSE, size_of(ImGui.ImDrawVert), xx 8);
    rhi.glVertexAttribPointer(g_AttribLocationColor, 4, GL_UNSIGNED_BYTE, GL_TRUE, size_of(ImGui.ImDrawVert), xx 16);

    ImGui_ImplSdl_CreateFontsTexture(rhi);

    // Restore modified GL state
    rhi.glBindTexture(GL_TEXTURE_2D, last_texture);
    rhi.glBindBuffer(GL_ARRAY_BUFFER, last_array_buffer);
    rhi.glBindVertexArray(last_vertex_array);

    return true;
}


ImGui_Impl_InvalidateDeviceObjects :: (rhi: RHI_proc) {
    if g_FontTexture {
        rhi.glDeleteTextures(1, *g_FontTexture);
        ImGui.GetIO().Fonts.TexID = null;
        g_FontTexture = 0;
    }
}

ImGui_Impl_Shutdown :: (platform: Platform) {
    ImGui_Impl_InvalidateDeviceObjects(platform.rhi);
}

ImGui_Impl_NewFrame :: (frame_info: Frame_Info, platform: Platform) {
    if !g_FontTexture
        ImGui_ImplSdl_CreateDeviceObjects(platform.rhi);

    io := ImGui.GetIO();
    io.DisplaySize = .{xx frame_info.window_size.x, xx frame_info.window_size.y};
    io.DisplayFramebufferScale = .{
        cast(float) frame_info.framebuffer_size.x / frame_info.window_size.x,
        cast(float) frame_info.framebuffer_size.y / frame_info.window_size.y
    }; 
    io.DeltaTime = frame_info.delta_time;

    io.MousePos = .{-FLOAT32_MAX,-FLOAT32_MAX};
    if frame_info.window_focused {
        io.MousePos = .{xx frame_info.mouse_position.x, xx frame_info.mouse_position.y };
    }

    io.MouseDown[0] = frame_info.key_pressed[Key.MouseLeft];
    io.MouseDown[1] = frame_info.key_pressed[Key.MouseRight];
    io.MouseDown[2] = frame_info.key_pressed[Key.MouseMiddle];
    io.MouseWheel = xx frame_info.mouse_wheel;
}
