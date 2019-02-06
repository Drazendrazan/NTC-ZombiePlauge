/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <engine>
#include <hamsandwich>
#include <fun>
#include <zp50_core>
#include <zp50_class_zombie>

#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>


#define PLUGIN "[ZP] Addons: Healing for zombie"
#define VERSION "1.0"
#define AUTHOR "VINAGHOST"

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

#define TASK_HEAL 560
#define TASK_HEALING 650

#define HEALTH 100

new g_Moving;
new g_health_bouns;
new msg_ScreenFade;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	RegisterHam(Ham_Killed,"player","HamHook_Player_Killed_Post",1)
	
	
	msg_ScreenFade = get_user_msgid( "ScreenFade")
}
public plugin_cfg() {
	g_health_bouns = get_cvar_num ("zp_infection_health_bonus")
}
public plugin_natives() {
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_NEMESIS))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public HamHook_Player_Killed_Post(id/*,killer,shouldgib*/)
{ 	
	if(task_exists(id+TASK_HEAL) )
		remove_task(id + TASK_HEAL)
	if(task_exists(id+TASK_HEALING) )
		remove_task(id + TASK_HEALING)
}

public client_PostThink(id)
{
	if( !is_user_alive(id) ) return
	if( !zp_core_is_zombie(id) ) return
	
	new Float:velocity[3]
	get_user_velocity(id,velocity)
	if(velocity[0]==0.0 && velocity[1]==0.0 && velocity[2]==0.0)
	{
		set_task(4.0, "Heal", id + TASK_HEAL)
		UnSet_BitVar(g_Moving, id)
	}
	else
	{
		Set_BitVar(g_Moving, id)
		if(task_exists(id+TASK_HEAL) )
			remove_task(id + TASK_HEAL)
	}
}
public Heal(id) {
	
	id -= TASK_HEAL;
	set_task(1.0, "Healing", id + TASK_HEALING)
}
public zp_fw_core_cure_post(id) {
	if(task_exists(id+TASK_HEAL) )
		remove_task(id + TASK_HEAL)
	if(task_exists(id+TASK_HEALING) )
		remove_task(id + TASK_HEALING)
}
public Healing(id) {
	id -= TASK_HEALING
	
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id))
		return;
		
	if( Get_BitVar(g_Moving, id) ) return;
	
	new Health = get_user_health(id) + HEALTH;
	new MaxHealth = zp_class_zombie_get_max_health(id, zp_class_zombie_get_current(id) )
	
	if( zp_core_is_first_zombie(id) ) {
		MaxHealth += g_health_bouns
	}
	
	if( Health < MaxHealth ) set_user_health(id, Health);
	
	else set_user_health(id, MaxHealth);
	
	ScreenFade(id, 1.0, 0, 0, 255, 40)
	set_task(1.0, "Healing", id + TASK_HEALING) 
}
stock ScreenFade(plr, Float:fDuration, red, green, blue, alpha)
{
	
	message_begin(MSG_ONE_UNRELIABLE, msg_ScreenFade, {0, 0, 0}, plr);
	write_short(floatround(4096.0 * fDuration, floatround_round));
	write_short(floatround(4096.0 * fDuration, floatround_round));
	write_short(4096);
	write_byte(red);
	write_byte(green);
	write_byte(blue);
	write_byte(alpha);
	message_end();
	
	return 1;
}
