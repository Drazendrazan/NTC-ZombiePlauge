#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>
#include <zp50_class_zombie>
#include <xs>

#define PLUGIN "Undertaker"
#define VERSION "1.0"
#define AUTHOR "DSHGFHDS"

#define SKILLMODEL "models/zombiepile.mdl"
#define SKILLNAME "zombiecoffin"
#define SKILL_COFFIN 15214
#define TASK_COOLDAWN 1234
#define TASK_SKILLUSEING 2345
#define TASK_SKILLOVER 3456
#define TASK_ENTTHINK 4567
#define TASK_SPEEDTIME 5678

new const WEAPON_CLASSNAME[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
"weapon_ak47", "weapon_knife", "weapon_p90" }

new const zclass_name[] = { "Stamper" }



new const zclass_info[] = { "Đặt hòm" }
new zclass_desc1[] = "Đặt hòm"
new const zclass_model[] = { "zm_undertaker" }
new const zclass_clawmodel[] = { "models/zombie_plague/v_zm_undertaker.mdl" }
//new const zclass_hemodel[] = { "models/zombie_plague/v_he_undertaker.mdl" }
new const zclass_health = 2900
new const Float:zclass_speed = 1.4
new const Float:zclass_gravity = 0.8
new const Float:zclass_knockback = 1.3
new const setcoffinsound[] = "zombie_plague/zombi_stamper_iron_maiden_stamping.wav"
new const coffinexsound[] = "zombie_plague/zombi_stamper_iron_maiden_explosion.wav"
new g_zclass_undertaker, g_shokewaveSpr, humanspr, zm_zombiebomb
new skilluseing[33], setmaxspeed[33], sprremove[33], knifehit[33], removesdamage[33], removeknock[33]
new /* cvar_skillcooldawntime, */cvar_skillhealth, cvar_coffintime, cvar_exrange, cvar_exknock, cvar_speedtime, cvar_maxspeed, cvar_bot_use_skill, cvar_exdamage, cvar_exhit
enum
{
	anim_idle,
	anim_slash1,
	anim_skill,
	anim_daw,
	anim_stab,
	anim_stab_miss,
	anim_midslash1,
	anim_midslash2,
}
const DMG_HEGRENADE = (1<<24)
public plugin_init()
{
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_plugin(PLUGIN, VERSION, AUTHOR)

	RegisterHam(Ham_Killed, "player", "player_death",1)
	for (new i = 0; i < sizeof WEAPON_CLASSNAME; i++)
	{
		if (strlen(WEAPON_CLASSNAME[i]) <= 0)
		continue;
		RegisterHam(Ham_Item_Deploy, WEAPON_CLASSNAME[i], "fwItemDeploy_Post", 1)
	}
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_Weapon_SecondaryAttack")
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_Weapon_SecondaryAttack_Post", 1)
	RegisterHam(Ham_TakeDamage, "info_target", "fw_TakeDamage")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamageplayer")
	RegisterHam(Ham_TraceAttack, "info_target", "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttackplayer")
	register_forward(FM_CmdStart, "forward_CmdStart", 1)
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	register_forward(FM_PlayerPostThink, "fw_PlayerPostThink" , 1)
	register_forward(FM_UpdateClientData, "UpdateClientData_Post", 1)

	//cvar_skillcooldawntime = register_cvar("zp_undertaker_cooldawn","8.0") //技能冷却时间
	cvar_skillhealth = register_cvar("zp_undertaker_skillhealth","800") //铁处女的生命值
	cvar_coffintime = register_cvar("zp_undertaker_coffintime","10.0") //铁处女的存在时间
	cvar_exrange = register_cvar("zp_undertaker_coffinexrange","150") //铁处女爆炸影响范围
	cvar_exknock = register_cvar("zp_undertaker_coffinexknock","1000") //铁处女爆炸击退
	cvar_speedtime = register_cvar("zp_undertaker_speedtime","5.0") //铁处女速度影响时间
	cvar_maxspeed = register_cvar("zp_undertaker_maxspeed","0.5") //受影响时的行走速度
	cvar_exdamage = register_cvar("zp_undertaker_exdamage","0.35") //铁处女爆炸时的伤害(生命*数据)
	cvar_bot_use_skill = register_cvar("zp_undertaker_bot_use_skill", "150") //BOT使用技能的距离
	cvar_exhit = register_cvar("zp_undertaker_hit_ex", "5") //铁处女受重刀的最大攻击次数
}

public plugin_precache()
{
	g_zclass_undertaker = zp_class_zombie_register(zclass_name, zclass_info, zclass_health, zclass_speed ,zclass_gravity)

	zp_class_zombie_register_kb(g_zclass_undertaker, zclass_knockback);
	zp_class_zombie_register_model(g_zclass_undertaker, zclass_model)
	zp_class_zombie_register_claw(g_zclass_undertaker, zclass_clawmodel[0])

	zp_class_zombie_register_1(g_zclass_undertaker, zclass_desc1, 10)



	//engfunc(EngFunc_PrecacheModel,zclass_hemodel)
	engfunc(EngFunc_PrecacheModel,SKILLMODEL)
	g_shokewaveSpr = engfunc(EngFunc_PrecacheModel,"sprites/shockwave.spr")
	humanspr = engfunc(EngFunc_PrecacheModel,"sprites/un_trap.spr")
	zm_zombiebomb = engfunc(EngFunc_PrecacheModel,"sprites/zombiebomb.spr")
	engfunc(EngFunc_PrecacheSound,setcoffinsound)
	engfunc(EngFunc_PrecacheSound,coffinexsound)
	precache_sound("zombie_plague/zombi_hurt_stamper_1.wav")
	precache_sound("zombie_plague/zombi_hurt_stamper_2.wav")
	precache_sound("zombie_plague/knife_slash1.wav")
	precache_sound("zombie_plague/knife_hitwall1.wav")
	precache_sound("zombie_plague/knife_hit1.wav")
	precache_sound("zombie_plague/knife_hit3.wav")
	precache_sound("zombie_plague/zombi_death_stamper_1.wav")
	precache_sound("zombie_plague/zombi_hurt_stamper_1.wav")
}

public fw_Weapon_SecondaryAttack(iEntity)
{
	new owner = pev(iEntity, pev_owner)
	knifehit[owner] = true
}

public fw_Weapon_SecondaryAttack_Post(iEntity)
{
	new owner = pev(iEntity, pev_owner)
	knifehit[owner] = false
}
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if(!is_user_connected(attacker))
	return HAM_IGNORED;

	if(damage_type & DMG_HEGRENADE)
	return HAM_IGNORED

	if(pev(victim, pev_iuser4) == SKILL_COFFIN)
	{
		if(get_user_weapon(attacker) == CSW_KNIFE && knifehit[attacker])
		{
			set_pev(victim, pev_iuser3, pev(victim, pev_iuser3)-1)
			return HAM_SUPERCEDE
		}
		removesdamage[attacker] = true
	}

	return HAM_IGNORED
}

public fw_TakeDamageplayer(victim, inflictor, attacker, Float:damage, damage_type)
{
	if(!is_user_connected(attacker))
	return HAM_IGNORED;

	if(damage_type & DMG_HEGRENADE)
	return HAM_IGNORED

	if(removesdamage[attacker])
	{
		removesdamage[attacker] = false
		return HAM_SUPERCEDE
	}

	return HAM_IGNORED
}

public fw_TraceAttack(victim, attacker, Float:damage, Float:dir[3], ptr, damagetype)
{
	if(!is_user_alive(attacker) || !is_user_connected(attacker))
	return HAM_IGNORED

	new iVictim = get_tr2(ptr, TR_pHit)

	if(pev(iVictim, pev_iuser4) == SKILL_COFFIN && get_user_weapon(attacker) != CSW_KNIFE)
	{
		removeknock[attacker] = true
		new Float:fHitOrigin[3]
		get_tr2(ptr, TR_vecEndPos, fHitOrigin)

		engfunc(EngFunc_MessageBegin,MSG_PVS, SVC_TEMPENTITY, fHitOrigin, 0)
		write_byte(TE_GUNSHOTDECAL)
		engfunc(EngFunc_WriteCoord,fHitOrigin[0])
		engfunc(EngFunc_WriteCoord,fHitOrigin[1])
		engfunc(EngFunc_WriteCoord,fHitOrigin[2])
		write_short(0)
		write_byte(45)
		message_end()

		engfunc(EngFunc_MessageBegin,MSG_PVS, SVC_TEMPENTITY, fHitOrigin, 0)
		write_byte(TE_SPARKS)
		engfunc(EngFunc_WriteCoord,fHitOrigin[0])
		engfunc(EngFunc_WriteCoord,fHitOrigin[1])
		engfunc(EngFunc_WriteCoord,fHitOrigin[2])
		message_end()
	}

	return HAM_IGNORED
}

public fw_TraceAttackplayer(victim, attacker, Float:damage, Float:dir[3], ptr, damagetype)
{
	if(!is_user_alive(attacker) || !is_user_connected(attacker))
	return HAM_IGNORED

	if(removeknock[attacker])
	{
		removeknock[attacker] = false
		return HAM_SUPERCEDE
	}

	return HAM_IGNORED
}

public fw_PlayerPreThink(id)
{
	if(!is_user_alive(id))
	return PLUGIN_HANDLED

	if(setmaxspeed[id]) set_speed_to_velocity(id, get_pcvar_float(cvar_maxspeed))//set_pev(id, pev_maxspeed, (pev(id, pev_maxspeed)*get_pcvar_float(cvar_maxspeed)))

	return PLUGIN_CONTINUE
}

public fw_PlayerPostThink(id)
{
	if(!is_user_alive(id) || !is_user_bot(id))
	return PLUGIN_HANDLED

	new enemy, body
	get_user_aiming(id, enemy, body)
	if ((1 <= enemy <= 32) && !zp_get_user_zombie(enemy))
	{
		new origin1[3] ,origin2[3],range
		get_user_origin(id,origin1)
		get_user_origin(enemy,origin2)
		range = get_distance(origin1, origin2)
		if(range <= get_pcvar_num(cvar_bot_use_skill)) skilluse(id)
	}
	return PLUGIN_CONTINUE
}

public UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id))
	return PLUGIN_HANDLED

	if(skilluseing[id] || sprremove[id])
	{
		set_cd(cd_handle, CD_ID, 0)
		sprremove[id] = false
	}

	return PLUGIN_CONTINUE
}

public forward_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
	return PLUGIN_HANDLED
	static button
	button = get_uc(uc_handle, UC_Buttons)

	if(skilluseing[id] && (button & IN_ATTACK))
	{
		button &= ~IN_ATTACK
		set_uc(uc_handle, UC_Buttons, button)
	}

	return PLUGIN_CONTINUE
}

public zp_user_infected_post(id, infector)
{
	alloff(id)
	setmaxspeed[id] = false
	remove_task(id)
	remove_task(id+TASK_SPEEDTIME)
}

public zp_user_humanized_post(id)
{
	alloff(id)
	setmaxspeed[id] = false
	remove_task(id)
	remove_task(id+TASK_SPEEDTIME)
}


public zp_fw_zombie_skill1_active(id , classid) {
	if( classid != g_zclass_undertaker ) return ZP_CLASS_SKILL_ACTIVE;

	if ( !(pev(id, pev_flags) & FL_ONGROUND ) )
	return ZP_CLASS_SKILL_CANT_ACTIVE;

	skilluse(id);
	return ZP_CLASS_SKILL_ACTIVE;
}
public skilluse(id)
{
	native_playanim(id,anim_skill)
	set_task(0.4, "settheent", id+TASK_SKILLUSEING)
	set_task(1.1, "skillover", id+TASK_SKILLOVER)
	skilluseing[id] = true

}

public skillover(taskid)
{
	new id = taskid - TASK_SKILLOVER
	native_playanim(id,anim_idle)
	skilluseing[id] = false
	remove_task(id+TASK_SKILLOVER)
}

public settheent(taskid)
{
	new id = taskid - TASK_SKILLUSEING
	remove_task(id+TASK_SKILLUSEING)

	if(!zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_zclass_undertaker || zp_get_user_nemesis(id))
		return

	new Float:origin[3], Float:fAngle[3], Float:fAngle2[3], Float:vec[3]
	pev(id,pev_origin,origin)
	get_origin_distance(id, vec, 100.0)
	vec[2] += 25.0
	pev(id,pev_angles,fAngle)
	new ent = fm_create_entity("info_target")
	if(!pev_valid(ent))
	return
	pev(ent,pev_angles,fAngle2)
	fAngle[0] = fAngle2[0]
	set_pev(ent, pev_classname, SKILLNAME)
	set_pev(ent, pev_iuser4, SKILL_COFFIN)
	set_pev(ent, pev_iuser3, get_pcvar_num(cvar_exhit))
	engfunc(EngFunc_SetModel,ent,SKILLMODEL)
	engfunc(EngFunc_SetSize, ent, {-14.0, -10.0, -36.0}, {14.0, 10.0, 36.0})
	set_pev(ent, pev_mins, {-14.0, -10.0, -36.0});
	set_pev(ent, pev_maxs, {14.0, 10.0, 36.0});
	set_pev(ent, pev_absmin, {-14.0, -10.0, -36.0})
	set_pev(ent, pev_absmax, {-14.0, -10.0, -36.0})
	set_pev(ent, pev_health, float(get_pcvar_num(cvar_skillhealth))+1000.0)
	set_pev(ent, pev_gravity, 2.0)
	set_pev(ent, pev_solid,SOLID_BBOX)
	set_pev(ent, pev_movetype,MOVETYPE_TOSS)
	set_pev(ent, pev_takedamage, DAMAGE_YES)
	set_pev(ent,pev_angles,fAngle)
	engfunc(EngFunc_SetOrigin,ent, vec)
	engfunc(EngFunc_DropToFloor, ent)
	engfunc(EngFunc_EmitSound, ent, CHAN_AUTO, setcoffinsound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	set_task(get_pcvar_float(cvar_coffintime), "removecoffin", ent, _, _, "b")
	set_task(0.1, "coffinthink", ent+TASK_ENTTHINK, _, _, "b")
	new Float:iorigin[3], Float:entorigin[3]
	pev(ent, pev_origin, entorigin)
	for(new i=1;i<33;i++)
	{
		pev(i, pev_origin, iorigin)
		new Float:range = get_distance_f(entorigin, iorigin)
		if(range <= float(get_pcvar_num(cvar_exrange)) && is_user_alive(i) && !zp_get_user_zombie(i) && !setmaxspeed[id])
		{
			setmaxspeed[i] = true
			makespr(i)
			set_task(get_pcvar_float(cvar_speedtime), "overspeedtime", i+TASK_SPEEDTIME)
		}
	}
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, entorigin, 0)
	write_byte(TE_BEAMCYLINDER)
	engfunc(EngFunc_WriteCoord, entorigin[0])
	engfunc(EngFunc_WriteCoord, entorigin[1])
	engfunc(EngFunc_WriteCoord, entorigin[2]-10)
	engfunc(EngFunc_WriteCoord, entorigin[0]-150)
	engfunc(EngFunc_WriteCoord, entorigin[1])
	engfunc(EngFunc_WriteCoord, entorigin[2]+300)
	write_short(g_shokewaveSpr)
	write_byte(0)
	write_byte(0)
	write_byte(2)
	write_byte(20)
	write_byte(0)
	write_byte(255)
	write_byte(255)
	write_byte(255)
	write_byte(100)
	write_byte(2)
	message_end()
	gettheent(ent)
}

public gettheent(ent)
{
	if(!pev_valid(ent))
	return

	if(!is_player_stuck(ent) || pev(ent, pev_movetype) == MOVETYPE_NOCLIP || pev(ent,pev_solid) == SOLID_NOT)
	return

	removecoffin(ent)
}

public makespr(id)
{
	if(zp_get_user_zombie(id) || !is_user_alive(id))
	return

	new Float:hm_origin[3]
	pev(id, pev_origin, hm_origin)
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, hm_origin, 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord,hm_origin[0])
	engfunc(EngFunc_WriteCoord,hm_origin[1])
	engfunc(EngFunc_WriteCoord,hm_origin[2]+10.0)
	write_short(humanspr)
	write_byte(8)
	write_byte(255)
	message_end()

	set_task(0.1,"makespr",id)
}

public overspeedtime(taskid)
{
	new id = taskid - TASK_SPEEDTIME
	setmaxspeed[id] = false
	remove_task(id)
	remove_task(id+TASK_SPEEDTIME)
}

public coffinthink(taskent)
{
	new ent = taskent - TASK_ENTTHINK
	if(!pev_valid(ent))
	return

	if(pev(ent, pev_health) <= 1000.0 || pev(ent, pev_iuser3) <= 0) removecoffin(ent)
}

public removecoffin(ent)
{
	new Float:iorigin[3], Float:entorigin[3], maxdamage, health
	pev(ent, pev_origin, entorigin)
	for(new i=1;i<33;i++)
	{
		pev(i, pev_origin, iorigin)
		new Float:range = get_distance_f(entorigin, iorigin)
		if(range <= float(get_pcvar_num(cvar_exrange)) && is_user_alive(i))
		{
			health = pev(i, pev_health)
			maxdamage = floatround(health*get_pcvar_float(cvar_exdamage))
			if(health > maxdamage)
			fm_fakedamage(i, "coffindamge", float(maxdamage), DMG_BLAST)
			set_velocity_from_origin(i, entorigin, float(get_pcvar_num(cvar_exknock)))
			if(!setmaxspeed[i] && !zp_get_user_zombie(i))
			{
				setmaxspeed[i] = true
				makespr(i)
				set_task(get_pcvar_float(cvar_speedtime), "overspeedtime", i+TASK_SPEEDTIME)
			}
		}
	}
	engfunc(EngFunc_EmitSound, ent, CHAN_AUTO, coffinexsound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	engfunc(EngFunc_MessageBegin, MSG_ALL, SVC_TEMPENTITY, entorigin, 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, entorigin[0])
	engfunc(EngFunc_WriteCoord, entorigin[1])
	engfunc(EngFunc_WriteCoord, entorigin[2]+38.0)
	write_short(zm_zombiebomb)
	write_byte(20)
	write_byte(255)
	message_end()

	remove_task(ent)
	remove_task(ent+TASK_ENTTHINK)
	engfunc(EngFunc_RemoveEntity, ent)
}

public alloff(id)
{
	skilluseing[id] = false
	remove_task(id+TASK_SKILLUSEING)
	remove_task(id+TASK_COOLDAWN)
	remove_task(id+TASK_SKILLOVER)
}

public fwItemDeploy_Post(ent)
{
	new id = get_pdata_cbase(ent, 41, 4)
	if(zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_zclass_undertaker && !zp_get_user_nemesis(id))
	{
		remove_task(id+TASK_SKILLUSEING)
		remove_task(id+TASK_SKILLOVER)
		skilluseing[id] = false
	}
}

public player_death(id)
{
	if(zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_zclass_undertaker && !zp_get_user_nemesis(id))
	{
		alloff(id)
		setmaxspeed[id] = false
		remove_task(id)
		remove_task(id+TASK_SPEEDTIME)
	}
}

new Debug
public client_putinserver(id)
{
	if(Debug == 1)return
	new classname[32]
	pev(id,pev_classname,classname,31)
	if(!equal(classname,"player"))
	{
		Debug=1
		set_task(1.0,"_Debug",id)
	}
}

public _Debug(id)
{
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamageplayer")
	RegisterHamFromEntity(Ham_Killed,id,"player_death", 1)
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttackplayer")
}

stock native_playanim(player,anim)
{
	set_pev(player, pev_weaponanim, anim)
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, player)
	write_byte(anim)
	write_byte(pev(player, pev_body))
	message_end()
}

stock get_origin_distance( index, Float:origin[3], Float:dist )
{
	new Float:start[ 3 ];
	new Float:view_ofs[ 3 ];

	pev( index, pev_origin, start );
	pev( index, pev_view_ofs, view_ofs );
	xs_vec_add( start, view_ofs, start );

	new Float:dest[3];
	pev(index, pev_angles, dest );

	engfunc( EngFunc_MakeVectors, dest );
	global_get( glb_v_forward, dest );

	xs_vec_mul_scalar( dest, dist, dest );
	xs_vec_add( start, dest, dest );

	engfunc( EngFunc_TraceLine, start, dest, 0, index, 0 );
	get_tr2( 0, TR_vecEndPos, origin );

	return 1;
}

stock set_velocity_from_origin( ent, Float:fOrigin[3], Float:fSpeed )
{
	new Float:fVelocity[3]

	get_velocity_from_origin( ent, fOrigin, fSpeed, fVelocity )
	set_pev( ent, pev_velocity, fVelocity )

	return 1
}

stock get_velocity_from_origin( ent, Float:fOrigin[3], Float:fSpeed, Float:fVelocity[3] )
{
	new Float:fEntOrigin[3];
	pev( ent, pev_origin, fEntOrigin );

	new Float:fDistance[3];
	fDistance[0] = fEntOrigin[0] - fOrigin[0]
	fDistance[1] = fEntOrigin[1] - fOrigin[1]
	fDistance[2] = fEntOrigin[2] - fOrigin[2]

	new Float:fTime = ( vector_distance( fEntOrigin,fOrigin ) / fSpeed )

	fVelocity[0] = fDistance[0] / fTime
	fVelocity[1] = fDistance[1] / fTime
	fVelocity[2] = fDistance[2] / fTime

	return ( fVelocity[0] && fVelocity[1] && fVelocity[2] )
}

stock is_player_stuck(id)
{
	static Float:originF[3]
	pev(id, pev_origin, originF)

	engfunc(EngFunc_TraceHull, originF, originF, 0, (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN, id, 0)

	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
	return true

	return false
}

stock set_speed_to_velocity(id, Float:scalar = 1.0)
{
	new Float:velocity[3]
	pev(id, pev_velocity, velocity)
	xs_vec_mul_scalar(velocity, scalar, velocity)
	velocity[2] = velocity[2]/scalar
	set_pev(id, pev_velocity, velocity)

	return 1
}

// Emit Sound Forward
public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
     // 内容限定只对僵尸作用
     if (!is_user_connected(id) || !zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_zclass_undertaker)
     return FMRES_IGNORED;

     // 僵尸被攻击的叫声
     if (equal(sample[7], "bhit", 4))
     {
     	if (zp_get_user_nemesis(id))
     	engfunc(EngFunc_EmitSound, id, channel, "zombie_plague/zombi_hurt_stamper_1.wav", volume, attn, flags, pitch)
     	else
     	engfunc(EngFunc_EmitSound, id, channel, "zombie_plague/zombi_hurt_stamper_2.wav", volume, attn, flags, pitch)
     	return FMRES_SUPERCEDE;
     }

     // 僵尸用爪子攻击的声音
     if (equal(sample[8], "kni", 3))
     {
           if (equal(sample[14], "sla", 3)) // 爪子空挥的音效
           {
           	engfunc(EngFunc_EmitSound, id, channel, "zombie_plague/knife_slash1.wav", volume, attn, flags, pitch)
           	return FMRES_SUPERCEDE;
           }
           if (equal(sample[14], "hit", 3)) // 爪子命中物体的音效
           {
                 if (sample[17] == 'w') // 爪子命中的是墙壁
                 {
                 	engfunc(EngFunc_EmitSound, id, channel, "zombie_plague/knife_hitwall1.wav", volume, attn, flags, pitch)
                 	return FMRES_SUPERCEDE;
                 }
                 else // 爪子命中的是人物
                 {
                 	engfunc(EngFunc_EmitSound, id, channel, "zombie_plague/knife_hit1.wav", volume, attn, flags, pitch)
                 	return FMRES_SUPERCEDE;
                 }
             }
           if (equal(sample[14], "sta", 3)) // 爪子重砍命中人物
           {
           	engfunc(EngFunc_EmitSound, id, channel, "zombie_plague/knife_hit3.wav", volume, attn, flags, pitch)
           	return FMRES_SUPERCEDE;
           }
       }

     // 僵尸死亡的声音
     if (equal(sample[7], "die", 3) || equal(sample[7], "dea", 3))
     {
     	engfunc(EngFunc_EmitSound, id, channel, "zombie_plague/zombi_death_stamper_1.wav", volume, attn, flags, pitch)
     	return FMRES_SUPERCEDE;
     }

     // 僵尸摔伤的声音
     if (equal(sample[10], "fall", 4))
     {
     	engfunc(EngFunc_EmitSound, id, channel, "zombie_plague/zombi_hurt_stamper_1.wav", volume, attn, flags, pitch)
     	return FMRES_SUPERCEDE;
     }

     return FMRES_IGNORED;
 }
