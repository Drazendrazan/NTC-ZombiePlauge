/* Plugin generated by AMXX-Studio */

#include <amxmodx>

#include <zp50_items>
#include <zp50_gamemodes>
#include <zp50_colorchat>

#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>

#define PLUGIN "[ZP] Item: Buy Nemesis"
#define VERSION "1.0"
#define AUTHOR "VINAGHOST"

new g_Nem, index, bool:h_Nem;
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0")  
	
	g_Nem = zp_money_items_register("Mua Nemesis" , 80000);
}

public event_new_round() {
	if( h_Nem ) {
		zp_class_nemesis_set(index)
		h_Nem = false;
		index = -1;
	}
}
public zp_fw_money_items_select_pre(id, itemid) {
	if( itemid != g_Nem ) return ZP_ITEM_AVAILABLE;
	
	if( h_Nem ) return ZP_ITEM_NOT_AVAILABLE;
	
	return ZP_ITEM_AVAILABLE;
}
public zp_fw_money_items_select_post(id, itemid) {
	if( itemid != g_Nem ) return;
	
	index = id;
	h_Nem = true;
	
	zp_colored_print(id, "Da mua Nemesis");
	new name[33]
	get_user_name(id, name, charsmax(name))
	zp_colored_print(0, "%s da mua ^x04Nemesis^x01, khong the mua duoc nua", name);
}

public client_disconnect(id) {
	if( id == index ) {
		h_Nem = false;
		index = -1;
	}
}
	
