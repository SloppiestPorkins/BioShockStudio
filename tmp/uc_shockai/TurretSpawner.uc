class TurretSpawner extends SpawnerBase
	native
	config(Spawning)
	placeable
	hidecategories(DrawScale3D,DisplayAdvanced,Advanced,Collision,Display,Force,Havok,LightColor,Lighting,Sound);

var(Turret) Class<Turret> TurretType;
var(Turret) bool ForScriptedSpawn;
var(Turret) private float UpperPitchLimit;
var(Turret) private float LowerPitchLimit;
var(Turret) private float DefaultPitchDegrees;
var(Turret) private float SightDistance;
var(Turret) export editinline Container LootContainer;
var(Turret) private name SpawnedTurretLabel;
var(Turret) private bool ShouldAttackPlayerEscortedGatherers;
var(Hacking) private name HackInfoName;
var(Hacking) private bool CanBeHacked;
var(Turret) private bool bBlocksPaths;
var(Turret) private bool bCantBeTargeted;

// Export UTurretSpawner::execSpawnScriptedTurret(FFrame&, void* const)
native function SpawnScriptedTurret();

function OutputTypesToBox(LevelInfo Level, out array< Class<ShockAI> > S)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x5B
	/*@Error*/
	SpawningManager(Level.SpawningManager).DisplayTurretTypes(Level, S);
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
	UpperPitchLimit=15.0000000
	LowerPitchLimit=-45.0000000
	SightDistance=1000.0000000
	HackInfoName="TurretDefault"
	CanBeHacked=true
	DrawType=2
}