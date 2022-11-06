#include <sourcemod>
#include <shavit>
#include <shop>
#include <clientmod>
#include <clientmod/multicolors>

#pragma semicolon 1
#pragma newdecls required 

public Plugin myinfo = 
{
	name = "[shavit] Credits",
	author = "who",
	description = "Gives shop credits when you finish or beat wr on map proceed from tier",
	version = "1.0",
	url = ""
};

ConVar gH_Enabled;
ConVar gH_Amount;
ConVar gH_WrAmount;
ConVar gH_Multiplier;
ConVar gH_Type;

bool gB_StoreExists, gB_Completed[MAXPLAYERS+1] = false;
char gS_CurrentMap[128];
int g_iTier, pbCredits, wrCredits;

public void OnPluginStart()
{
	gH_Enabled = CreateConVar("shavit_credits_enabled", "1", "Store money give for map finish is enabled?", 0, true, 0.0, true, 1.0);
	gH_Multiplier = CreateConVar("shavit_credits_multiplier", "2", "Credits multiplier when tier more than 1", 0, true, 0.0, true, 1.0);	
	gH_Amount = CreateConVar("shavit_credits_pb_amount", "10", "Amount to give on finish map", 0, true, 1.0);
	gH_WrAmount = CreateConVar("shavit_credits_wr_amount", "20", "Amount to give on beat wr", 0, true, 1.0);
	gH_Type = CreateConVar("shavit_credits_type", "1", "Type of give shop credits (1 - single give credits, 2 - multiple give credits)", 0, true, 1.0);
	
	AutoExecConfig(true, "shavit-credits");
	
	gB_StoreExists = LibraryExists("shop");

	RegConsoleCmd("sm_mapinfo", CMD_MapInfo);

	LoadTranslations("shavit-credits.phrases");
}

public void OnMapStart()
{
	GetCurrentMap(gS_CurrentMap, sizeof(gS_CurrentMap));

	g_iTier = Shavit_GetMapTier(gS_CurrentMap);

	pbCredits = CalculateCredits(GetConVarInt(gH_Amount), g_iTier, GetConVarInt(gH_Multiplier));
	wrCredits = CalculateCredits(GetConVarInt(gH_WrAmount), g_iTier, GetConVarInt(gH_Multiplier));
}

public void Shavit_OnTierAssigned(const char[] map, int tier)
{
	g_iTier = tier;	

	pbCredits = CalculateCredits(GetConVarInt(gH_Amount), g_iTier, GetConVarInt(gH_Multiplier));
	wrCredits = CalculateCredits(GetConVarInt(gH_WrAmount), g_iTier, GetConVarInt(gH_Multiplier));
}

public Action CMD_MapInfo(int client, int args)
{
	if(args < 1)
	{
		Shavit_PrintToChat(client, "\x04Tier: %i \x01|| \x04PB Credits: %i \x01|| \x04WR Credits: %i", g_iTier, 
		CalculateCredits(GetConVarInt(gH_Amount), g_iTier, GetConVarInt(gH_Multiplier)),
		CalculateCredits(GetConVarInt(gH_WrAmount), g_iTier, GetConVarInt(gH_Multiplier)));

		return Plugin_Handled;
	}
	
	char arg[128]; GetCmdArg(1, arg, sizeof(arg));

	if(!IsMapValid(arg))
	{
		Shavit_PrintToChat(client, "Карта \x04%s \x01не найдена", arg);

		return Plugin_Handled;
	}

	Shavit_PrintToChat(client, "\x04Tier: %i \x01|| \x04PB Credits: %i \x01|| \x04WR Credits: %i", Shavit_GetMapTier(arg), 
	CalculateCredits(GetConVarInt(gH_Amount), Shavit_GetMapTier(arg), GetConVarInt(gH_Multiplier)),
	CalculateCredits(GetConVarInt(gH_WrAmount), Shavit_GetMapTier(arg), GetConVarInt(gH_Multiplier)));		

	return Plugin_Handled;
}

public void Shavit_OnFinish(int client, int style, float time, int jumps, int strafes, float sync, int track, float oldtime, float perfs, float avgvel, float maxvel, int timestamp)
{
	if(gB_StoreExists && gH_Enabled)
	{	
		float WrTime = Shavit_GetWorldRecord(style, track);

		if(GetConVarInt(gH_Type) == 1)
		{
			if(gB_Completed[client])
			{
				return;
			}

			gB_Completed[client] = true;

			if(WrTime != time)
			{
				Shop_GiveClientCredits(client, pbCredits);
				Shavit_PrintToChat(client, "Вы \x04прошли \x01карту и получили \x04%i \x01кредитов!", pbCredits);

				return;	
			}

			Shop_GiveClientCredits(client, wrCredits);
			Shavit_PrintToChat(client, "Вы \x04побили \x01рекорд карты и получили \x04%i \x01кредитов!", wrCredits);			
		}
		else if(GetConVarInt(gH_Type) == 2)
		{
			if(WrTime != time)
			{
				Shop_GiveClientCredits(client, pbCredits);
				Shavit_PrintToChat(client, "Вы \x04прошли \x01карту и получили \x04%i \x01кредитов!", pbCredits);

				return;	
			}

			Shop_GiveClientCredits(client, wrCredits);
			Shavit_PrintToChat(client, "Вы \x04побили \x01рекорд карты и получили \x04%i \x01кредитов!", wrCredits);
		}
	}
}

public int CalculateCredits(int amount, int tier, int multiplier)
{
	for(int i = 1; i < tier; i++) amount *= multiplier;

	return amount;
}
