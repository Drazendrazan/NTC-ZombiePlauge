/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>

#define PLUGIN "[ZP] Wait 30s"
#define VERSION "1.0"
#define AUTHOR "VINAGHOST"

new ready = 30;
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
		
	set_task(1.0, "timer");
}

public timer() {
	
	if( ready ) {
		ready --;
		set_task(1.0, "timer");
	}
	else
	{
		server_cmd("sv_restart 1")
	}
		
}
public client_connect(id)  {
	if( ready )
	{
		server_cmd("kick #%d ^"Server đang config. Xin hãy quay lại sau %d giây^"", id, ready)
	}
}
