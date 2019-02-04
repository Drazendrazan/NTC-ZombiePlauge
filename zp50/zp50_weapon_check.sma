#include <amxmodx>
#include <zp50_core>
#include <zp50_weapon>
#include <zp50_ammopacks>


public plugin_init()
{
	register_plugin("[ZP] Weapon Checker", ZP_VERSION_STRING, "ZP Dev Team")
}


public zp_wpn_select_pre(id, itemid, ignorecost)
{
	// Ignore item costs?
	if (ignorecost)
		return ZP_WEAPON_AVAILABLE;
		
	// Get current and required ammo packs
	new current_ammopacks = zp_ammopacks_get(id)
	new required_ammopacks = zp_weapons_get_cost(itemid)
	
	// Not enough ammo packs
	if (current_ammopacks < required_ammopacks)
		return ZP_WEAPON_NOT_AVAILABLE;
	
	return ZP_WEAPON_AVAILABLE;
}

public zp_fw_ap_items_select_post(id, itemid, ignorecost)
{
	// Ignore item costs?
	if (ignorecost)
		return;
	
	// Get current and required ammo packs
	new current_ammopacks = zp_ammopacks_get(id)
	new required_ammopacks = zp_weapons_get_cost(itemid)
	
	// Deduct item's ammo packs after purchase event
	zp_ammopacks_set(id, current_ammopacks - required_ammopacks)
}
