/**
* Admin's Friendly Fire Manager by Root
*
* Description:
*   Allow admins to give/take more/less friendly fire damage, or disable it at all.
*
* Version 1.1.2
* Changelog & more info at http://goo.gl/4nKhJ
*/

// ====[ INCLUDES ]====================================================
#include <sourcemod>
#include <sdkhooks>

// ====[ CONSTANTS ]===================================================
#define PLUGIN_NAME         "Admin's Friendly Fire Manager"
#define PLUGIN_VERSION      "1.1.2"

// ====[ VARIABLES ]===================================================
new Handle:adminff_enable     = INVALID_HANDLE,
	Handle:adminff_give       = INVALID_HANDLE,
	Handle:adminff_take       = INVALID_HANDLE,
	Handle:adminff_customflag = INVALID_HANDLE

// ====[ PLUGIN ]======================================================
public Plugin:myinfo =
{
	name			= PLUGIN_NAME,
	author			= "Root",
	description		= "Changes friendly fire damage for admins",
	version			= PLUGIN_VERSION,
	url				= "http://dodsplugins.com/"
};


/* OnPluginStart()
 *
 * When the plugin starts up.
 * --------------------------------------------------------------------- */
public OnPluginStart()
{
	// Create ConVars
	CreateConVar("sm_adminff_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED)

	adminff_enable     = CreateConVar("sm_adminff_enable",     "1",   "Enable or disable plugin",                                            FCVAR_PLUGIN, true, 0.0, true, 1.0)
	adminff_give       = CreateConVar("sm_adminff_give",       "0",   "Friendly fire damage multipler.\nSet to 0 to disable FF from admins", FCVAR_PLUGIN, true, 0.0, true, 2.0)
	adminff_take       = CreateConVar("sm_adminff_take",       "0.5", "Teammates damage multipler.\nSet to 0 to disable damage to admins",   FCVAR_PLUGIN, true, 0.0, true, 2.0)
	adminff_customflag = CreateConVar("sm_adminff_customflag", "0",   "Manage FF for admins with:\n0 - Generic flag\n1 - Custom flag (6th)", FCVAR_PLUGIN, true, 0.0, true, 1.0)

	// Create and exec plugin's config from cfg/sourcemod folder
	AutoExecConfig(true)
}

/* OnClientPutInServer()
 *
 * Called when a client is entering the game.
 * --------------------------------------------------------------------- */
public OnClientPutInServer(client)
{
	// Hooks an OnTakeDamage entity
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage)
}

/* OnTakeDamage(SDKHooks)
 *
 * Called when a client takes damage to another.
 * --------------------------------------------------------------------- */
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (GetConVarBool(adminff_enable))
	{
		// Change friendly fire damage
		if (IsValidClient(attacker) && IsValidClient(victim) && GetClientTeam(attacker) == GetClientTeam(victim))
		{
			// Checking attacker's access
			if (IsClientAdmin(attacker))
			{
				// Multiply given damage
				if (GetConVarFloat(adminff_give) > 0)
					damage *= GetConVarFloat(adminff_give)
				else
					damage = 0.0
			}
			// Both client should not have any admin rights!
			else if (IsClientAdmin(victim) && !IsClientAdmin(attacker))
			{
				if (GetConVarFloat(adminff_take) > 0)
					damage *= GetConVarFloat(adminff_take)
				else /* Disable damage if value is not specified */
					damage = 0.0
			}
			// We should call Plugin_Changed if damage was changed
			return Plugin_Changed
		}
	}
	return Plugin_Continue /* Dont forget to return Plugin_Continue (otherwise no damage will deal) */
}

/* IsValidClient()
 *
 * Checks if a client is valid.
 * --------------------------------------------------------------------- */
bool:IsValidClient(client)
{
	// Client may be valid, but not in-game
	return (client > 0 || client <= MaxClients && IsClientInGame(client)) ? true : false
}

/* IsClientAdmin()
 *
 * Checks if player got admin access.
 * --------------------------------------------------------------------- */
bool:IsClientAdmin(client)
{
	// If customflag cvar is specified, check admins with 6th custom flag
	if (GetConVarBool(adminff_customflag))
		return (GetAdminFlag(GetUserAdmin(client), Admin_Custom6)) ? true : false
	else /* If not: change FF for admins with a generic abilities */
		return (GetAdminFlag(GetUserAdmin(client), Admin_Generic)) ? true : false
}