class SpawnerBase extends Actor
	abstract
	native
	config(Spawning)
	placeable
	hidecategories(DrawScale3D,DisplayAdvanced,Advanced,Collision,Display,Force,Havok,LightColor,Lighting,Sound);

var const editconstarray editconst array<name> SpawnZones;
var bool bCorpseCanBeRemoved;
var config float MinDistanceToSpawnRepopulationAIIfPlayerLookingOtherWay;
var private bool bIsEnabledForRepopulation;

function SetRepopulationState(bool inEnabledForRepopulation)
{
	bIsEnabledForRepopulation = inEnabledForRepopulation;
	return;
	@NULL
	CommanderAction
}

defaultproperties
{
	MinDistanceToSpawnRepopulationAIIfPlayerLookingOtherWay=1000.0000000
	bIsEnabledForRepopulation=true
	bHidden=true
	bDirectional=true
}