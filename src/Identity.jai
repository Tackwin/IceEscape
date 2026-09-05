#import "Basic";
#import "String";

#scope_export

// Change the game here. Everything else is derived.
GAME_NAME :: "Arena";
LOCAL_SERVER_PORT :: 2468;

ident :: (suffix: string) -> string {
	return copy_string(join(GAME_NAME, suffix));
}

identity_cstr :: (s: string) -> *u8 {
	return tprint("%\0", s).data;
}

GAME_NAME_LOWER :: #run copy_string(to_lower_copy(GAME_NAME));
GAME_SERVER_NAME :: #run ident("Server");
GAME_LINUX_SERVER_NAME :: "LinuxServer";
GAME_DLL :: #run ident(".dll");
GAME_PDB :: #run copy_string(join(GAME_NAME, ".dll.pdb"));
GAME_SERVER_DLL :: #run ident("Server.dll");
GAME_SERVER_PDB :: #run copy_string(join(GAME_SERVER_NAME, ".dll.pdb"));
GAME_EXE :: #run ident(".exe");
GAME_SERVER_EXE :: #run ident("Server.exe");
GAME_WASM :: #run ident(".wasm");
GAME_EXE_PDB :: #run copy_string(join(GAME_NAME, ".exe.pdb"));
GAME_SERVER_EXE_PDB :: #run copy_string(join(GAME_SERVER_NAME, ".exe.pdb"));
GAME_SERVER_DB :: #run ident("Server.db");
GAME_SERVER_DEV_DB :: #run ident("ServerDev.db");
GAME_CONTROL_PIPE :: #run ident("Control");
GAME_TEMP_DLL :: #run ident("_temp.dll");
GAME_TEMP_PDB :: #run ident("_temp.pdb");
GAME_SERVER_TEMP_DLL :: #run ident("Server_temp.dll");
GAME_CONTROL_PIPE_PATH :: #run copy_string(join("\\\\.\\pipe\\", GAME_CONTROL_PIPE, "\0"));
GAME_SYSTEMD_SERVICE :: "linuxserver.service";
GAME_WEB_ROOT :: #run copy_string(join("www/", GAME_NAME_LOWER));
