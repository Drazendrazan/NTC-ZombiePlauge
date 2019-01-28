/****************************************/
/*					*/
/*	Auto Demo Recorder		*/
/*	by IzI				*/
/*					*/
/****************************************/

#include <amxmodx>

#include <register_system>
#define LIBRARY_REGISTER_SYSTEM "register_system"


new textmsg

public plugin_init() { 
	register_plugin( "DEMO ZOMBIE PLAUGE", "1.5", "IzI" );
	textmsg = get_user_msgid("SayText")
}

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module,LIBRARY_REGISTER_SYSTEM ))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}


public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public client_putinserver( id ) {
	set_task( 15.0, "Record", id );
}

public Record( id ) {

	if( !is_user_connected( id ))
		return;
	
	if(LibraryExists(LIBRARY_REGISTER_SYSTEM, LibType_Library) )
	{
		if( !is_logged(id) ) {
			set_task( 15.0, "Record", id );
			return;
		}
	}
	
	client_cmd( id, "stop; record ^"NTC_ZP^"");
	client_mau( id, "!g[Thông báo] !yChú ý server có ghi lại demo. Tên demo là !g^"NTC_ZP.dem^"");
	client_mau( id, "!g[Thông báo] !yDemo được lưu ở dường dẫn !g<thư mục CS>/cstrike/");
	client_mau( id, "!g[Thông báo] !yNếu bỏ qua thông báo này, VINA không chịu trách nhiệm nếu bạn bị ban hay kick");
}
stock client_mau(const id, const input[], any:...) 
{ 
	new count = 1, players[32] 
	
	static msg[191] 
	
	vformat(msg, 190, input, 3) 
	
	replace_all(msg, 190, "!g", "^4") 
	replace_all(msg, 190, "!y", "^1") 
	replace_all(msg, 190, "!t", "^3") 
	replace_all(msg, 190, "!t2", "^0") 
	
	if (id) players[0] = id; else get_players(players, count, "sch") 
	
	for (new i = 0; i < count; i++) 
	{ 
		if (is_user_connected(players[i])) 
		{ 
			message_begin(MSG_ONE_UNRELIABLE, textmsg , _, players[i]) 
			write_byte(players[i]) 
			write_string(msg) 
			message_end() 
		} 
	}  
}
