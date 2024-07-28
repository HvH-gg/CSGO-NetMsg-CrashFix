#include <sourcemod>
#include <sdkhooks>
#include <dhooks>

public Plugin:myinfo =
{
	name = "HvH.gg NetMsg Crash Fix",
	author = "imi-tat0r & philip015",
	description = "Fixes a crash related to NetMsg_StringCmd",
	version = "1.0.0",
}

DynamicDetour dDetour;

public void OnPluginStart()
{
	// Load signature from gamedata file
	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof buffer, "gamedata/hvhgg_netmsg_crash_fix.txt");

	if (!FileExists(buffer))
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", buffer);

	GameData hGameData = new GameData("hvhgg_netmsg_crash_fix");
	if (!hGameData)
		SetFailState("Failed to load \"hvhgg_netmsg_crash_fix.txt\" gamedata.");

	dDetour = DynamicDetour.FromConf(hGameData, "ProcessPacketHeader");
	if (!dDetour)
		SetFailState("Failed to create DynamicDetour: \"ProcessPacketHeader\"");

	if (!dDetour.Enable(Hook_Pre, ProcessPacketHeader_Pre))
		SetFailState("Failed to detour pre: \"ProcessPacketHeader\"");
}

MRESReturn ProcessPacketHeader_Pre(DHookReturn hReturn, DHookParam hParams) 
{
	Address addr = hParams.GetAddress(1);
	if (!addr)
		return MRES_Ignored;
	
	int size = LoadFromAddress(addr + view_as<Address>(0x54), NumberType_Int32);

	// arbitrary value, we might change that
	if (size > 2000)
	{
		hReturn.Value = -1;
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

public void OnPluginEnd()
{
	if (dDetour)
		dDetour.Disable(Hook_Pre, ProcessPacketHeader_Pre);
}
