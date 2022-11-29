#include <sourcemod>
#include <shavit>
#include <shop>

#pragma semicolon 1
#pragma newdecls required 

public Plugin myinfo = 
{
	name = "[shavit] Credits",
	author = "who",
	description = "Gives shop credits when you finish or beat wr on map proceed from tier",
	version = "1.1",
	url = ""
};

ConVar gH_Amount, gH_WrAmount, gH_Type, gH_BonusPbAmount, gH_BonusWrAmount;

bool gB_StoreExists, gB_Completed[MAXPLAYERS+1] = false;
char gS_CurrentMap[128];
int g_iTier, pbCredits, wrCredits;

public void OnPluginStart()
{
	gH_Amount = CreateConVar("shavit_credits_pb_amount", "10", "Amount to give on finish map", 0, true, 1.0);
	gH_WrAmount = CreateConVar("shavit_credits_wr_amount", "20", "Amount to give on beat wr", 0, true, 1.0);
	gH_BonusPbAmount = CreateConVar("shavit_credits_bonuspb_amount", "10", "Amount to give on finish bonus", 0, true, 1.0);
	gH_BonusWrAmount = CreateConVar("shavit_credits_bonuswr_amount", "10", "Amount to give on beat wr on bonus", 0, true, 1.0);	
	gH_Type = CreateConVar("shavit_credits_type", "2", "Type of give shop credits (1 - single give credits, 2 - multiple give credits)", 0, true, 1.0);
	
	AutoExecConfig(true, "shavit-credits");
	
	gB_StoreExists = LibraryExists("shop");

	RegConsoleCmd("sm_mapinfo", CMD_MapInfo);

	LoadTranslations("shavit-credits.phrases");
}

public void OnMapStart()
{
	GetCurrentMap(gS_CurrentMap, sizeof(gS_CurrentMap));

	g_iTier = Shavit_GetMapTier(gS_CurrentMap);

	pbCredits = CalculateCredits(GetConVarInt(gH_Amount), g_iTier);
	wrCredits = CalculateCredits(GetConVarInt(gH_WrAmount), g_iTier);
}

void DisplayInfoMenu(int client, char[] map)
{
	if(!IsMapValid(map))
	{
		Shavit_PrintToChat(client, "Карта \x04%s \x01не найдена", map);

		return;
	}

	char buffer[128], buffer2[128], buffer3[128], buffer4[128], buffer5[128];

	Menu menu = new Menu(Menu_Handler);

	
	Format(buffer, sizeof(buffer), "Tier: %i", Shavit_GetMapTier(map));
	Format(buffer2, sizeof(buffer2), "[MAIN] PB Credits: %i", CalculateCredits(GetConVarInt(gH_Amount), Shavit_GetMapTier(map)));
	Format(buffer3, sizeof(buffer3), "[MAIN] WR Credits: %i", CalculateCredits(GetConVarInt(gH_WrAmount), Shavit_GetMapTier(map)));
	Format(buffer4, sizeof(buffer4), "[BONUS] PB Credits: %i", GetConVarInt(gH_BonusPbAmount));
	Format(buffer5, sizeof(buffer5), "[BONUS] WR Credits: %i", GetConVarInt(gH_BonusWrAmount));

	menu.SetTitle("Map Info");
	menu.AddItem("item", buffer);
	menu.AddItem("item2", buffer2);
	menu.AddItem("item3", buffer3);
	menu.AddItem("item4", buffer4);
	menu.AddItem("item5", buffer5);

	menu.ExitButton = true;
	menu.Display(client, 30);	
}

public void Shavit_OnTierAssigned(const char[] map, int tier)
{
	g_iTier = tier;	

	pbCredits = CalculateCredits(GetConVarInt(gH_Amount), g_iTier);
	wrCredits = CalculateCredits(GetConVarInt(gH_WrAmount), g_iTier);
}

public Action CMD_MapInfo(int client, int args)
{
	if(args < 1)
	{
		DisplayInfoMenu(client, gS_CurrentMap);

		return Plugin_Handled;
	}

	char arg[128]; GetCmdArg(1, arg, sizeof(arg));

	DisplayInfoMenu(client, arg);

	return Plugin_Handled;
}

public void Shavit_OnFinish(int client, int style, float time, int jumps, int strafes, float sync, int track, float oldtime, float perfs, float avgvel, float maxvel, int timestamp)
{
	if(gB_StoreExists && gH_Enabled)
	{	
		if(track < 1) // MAIN TRACK
		{
			float WrTime = Shavit_GetWorldRecord(style, track);

			if(GetConVarInt(gH_Type) == 1)
			{
				if(gB_Completed[client]) return;

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
		else // ANY BONUSES TRACKS
		{
			float WrTime = Shavit_GetWorldRecord(style, track);

			if(GetConVarInt(gH_Type) == 1)
			{
				if(gB_Completed[client]) return;

				gB_Completed[client] = true;

				if(WrTime != time)
				{
					Shop_GiveClientCredits(client, GetConVarInt(gH_BonusPbAmount));
					Shavit_PrintToChat(client, "Вы \x04прошли \x01бонус и получили \x04%i \x01кредитов!", GetConVarInt(gH_BonusPbAmount));

					return;	
				}

				Shop_GiveClientCredits(client, GetConVarInt(gH_BonusWrAmount));
				Shavit_PrintToChat(client, "Вы \x04побили \x01рекорд бонуса и получили \x04%i \x01кредитов!", GetConVarInt(gH_BonusWrAmount));			
			}
			else if(GetConVarInt(gH_Type) == 2)
			{
				if(WrTime != time)
				{
					Shop_GiveClientCredits(client, GetConVarInt(gH_BonusWrAmount));
					Shavit_PrintToChat(client, "Вы \x04прошли \x01бонус и получили \x04%i \x01кредитов!", GetConVarInt(gH_BonusWrAmount));

					return;	
				}

				Shop_GiveClientCredits(client, GetConVarInt(gH_BonusWrAmount));
				Shavit_PrintToChat(client, "Вы \x04побили \x01рекорд бонуса и получили \x04%i \x01кредитов!", GetConVarInt(gH_BonusWrAmount));
			}			
		}
	}
}

public int CalculateCredits(int amount, int tier)
{
	for(int i = 1; i < tier; i++) amount *= 2;

	return amount;
}

public int Menu_Handler(Menu menu, MenuAction action, int param, int param2)
{
	if(action == MenuAction_End) delete menu;
}
