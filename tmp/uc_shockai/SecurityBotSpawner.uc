class SecurityBotSpawner extends SpawnerBase
	native
	config(Spawning)
	placeable
	hidecategories(DrawScale3D,DisplayAdvanced,Advanced,Collision,Display,Force,Havok,LightColor,Lighting,Sound);

var(SecurityBot) Class<SecurityBot> SecurityBotType;
var(SecurityBot) bool ForScriptedSpawn;
var(SecurityBot) bool StartHacked;
var(SecurityBot) bool StartFrozen;
var(SecurityBot) bool PlayStartupSequence;
var(SecurityBot) name HackInfoName;
var(SecurityBot) name SpawnedSecurityBotLabel;
var(SecurityBot) export editinline Container LootContainer;

function SecurityBot SpawnScriptedSecurityBot(bool ImmediatelyGiveBotToPawn, ShockPawn DestinationPawn)
{
	//native.ImmediatelyGiveBotToPawn;
	//native.DestinationPawn;	
	@NULL
	@NULL
}

function OutputTypesToBox(LevelInfo Level, out array< Class<ShockAI> > S)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x5B
	/*@Error*/
	SpawningManager(Level.SpawningManager).DisplaySecurityBotTypes(Level, S);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function AllHackInfoNames(LevelInfo Level, out array<name> S)
{
	local int i;
	local HackInfoList HackInfoList;

	HackInfoList = Class'ShockGame.HackInfoList'.static.Allocate(self).;
	Construct_Void();
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA3
	/*@Error*/
	S[i] = HackInfoList.HackInfoName[i];
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x3C;
	HackInfoList.__NFUN_200__();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function string DisplayAITypeName(Class<ShockAI> AIClass)
{
	// End:0x2B
	if(__NFUN_119__(AIClass, none))
	{
		return string(AIClass.Name);
		goto J0x3B;
		return "Class Not Set";
	}
	return;
	@NULL
	CommanderAction
	J0x3B:

	CommanderAction
}

defaultproperties
{
	PlayStartupSequence=true
	DrawType=2
}