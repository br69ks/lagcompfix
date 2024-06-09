#include <sourcemod>
#include <dhooks>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name = "Lag Compensation Fix",
    author = "brooks",
    version = "1.0"
};

Address fix1, fix2;
int fix2_bytes;
any fix1_old, fix2_old[100];
ConVar mp_teammates_are_enemies, mp_friendlyfire;

public void OnPluginStart()
{
	mp_teammates_are_enemies = FindConVar("mp_teammates_are_enemies");
	mp_friendlyfire = FindConVar("mp_friendlyfire");
	GameData data = new GameData("lagcompfix.games");
	fix1 = data.GetAddress("fix1");
	fix2 = data.GetAddress("fix2");
	fix2_bytes = data.GetOffset("fix2_bytes");
	fix1_old = LoadFromAddress(fix1, NumberType_Int32);
	StoreToAddress(fix1, 0x7F7FFFFF, NumberType_Int32);
	for (int i = 0; i < fix2_bytes; i++)
	{
		fix2_old[i] = LoadFromAddress(fix2 + view_as<Address>(i), NumberType_Int8);
		StoreToAddress(fix2 + view_as<Address>(i), 0x90, NumberType_Int8);
	}
	DynamicDetour detour = new DynamicDetour(Address_Null, CallConv_THISCALL, ReturnType_Bool, ThisPointer_CBaseEntity);
	detour.SetFromConf(data, SDKConf_Signature, "WantsLagCompensationOnEntity");
	detour.AddParam(HookParamType_CBaseEntity);
	detour.Enable(Hook_Pre, WantsLagCompensationOnEntity);
	delete data;
}

public void OnPluginEnd()
{
	StoreToAddress(fix1, fix1_old, NumberType_Int32);
	for (int i = 0; i < fix2_bytes; i++) StoreToAddress(fix2 + view_as<Address>(i), fix2_old[i], NumberType_Int8);
}

public MRESReturn WantsLagCompensationOnEntity(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	hReturn.Value = ((!mp_teammates_are_enemies.BoolValue && !mp_friendlyfire.BoolValue) && (GetClientTeam(pThis) == GetClientTeam(hParams.Get(1)))) ? false : true;
	return MRES_Supercede;
}
