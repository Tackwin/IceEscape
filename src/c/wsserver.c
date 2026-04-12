#include "mongoose.h"
#include "mongoose.c"
#include <stdio.h>

struct mg_mgr manager;

uint8_t* receive_buffer;
uint64_t receive_buffer_capacity;
uint64_t receive_buffer_count;

uint64_t* receive_stored = NULL;
uint64_t* receive_dropped = NULL;

void (*on_open_cb)(uint64_t)  = NULL;
void (*on_close_cb)(uint64_t) = NULL;

void fn(struct mg_connection* c, int ev, void* ev_data) {
	if (ev == MG_EV_OPEN) {

	} else if (ev == MG_EV_HTTP_MSG) {
		struct mg_http_message* msg = (struct mg_http_message*)ev_data;
		if (mg_match(msg->uri, mg_str("/ws"), NULL)) {
			mg_ws_upgrade(c, msg, "Cross-Origin-Resource-Policy: cross-origin\r\n");
		}
	} else if (ev == MG_EV_WS_MSG) {
		struct mg_ws_message* msg = (struct mg_ws_message*)ev_data;
		if (msg->data.len > 0)
		{
			uint64_t to_write = msg->data.len + 16;
			if (receive_buffer_count + to_write >= receive_buffer_capacity) {
				*receive_dropped += 1;
			} else {
				uint8_t* buffer = &receive_buffer[receive_buffer_count];
				memset(buffer +  0, 0, 16);
				memcpy(buffer +  0, &c->id, sizeof(c->id));
				memcpy(buffer +  8, &msg->data.len, sizeof(msg->data.len));
				memcpy(buffer + 16, msg->data.buf, msg->data.len);
				receive_buffer_count += to_write;
				*receive_stored += 1;
			}
		}
	}
}

__declspec(dllexport) void ws_listen(const char* url, void* buffer, uint64_t buffer_capacity) {
	mg_log_set(MG_LL_ERROR);
	mg_mgr_init(&manager);
	mg_http_listen(&manager, url, fn, NULL);

	receive_buffer_capacity = buffer_capacity;
	receive_buffer = (uint8_t*)buffer;
	receive_stored = (uint64_t*)(receive_buffer + 0);
	receive_dropped = (uint64_t*)(receive_buffer + 8);
	*receive_dropped = 0;
	receive_buffer_count = 16;
}
__declspec(dllexport) void ws_send(uint64_t uid, void* data, uint64_t count) {
	for (
		struct mg_connection* connection = manager.conns; connection; connection = connection->next
	) {
		if (connection->id == uid) {
			mg_ws_send(connection, data, count, WEBSOCKET_OP_BINARY);
			break;
		}
	}
}
__declspec(dllexport) void ws_poll() {
	*receive_dropped = 0;
	*receive_stored  = 0;
	receive_buffer_count = 16;
	mg_mgr_poll(&manager, 0);
}

__declspec(dllexport) void ws_reset_buffer() {
	*receive_dropped = 0;
	*receive_stored  = 0;
	receive_buffer_count = 16;
}

__declspec(dllexport) void set_on_open(void (*cb)(uint64_t)) {
	
}
__declspec(dllexport) void set_on_close(void (*cb)(uint64_t)) {
	
}