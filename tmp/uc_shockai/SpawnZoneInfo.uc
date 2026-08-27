class SpawnZoneInfo extends Object
	native
	config(Spawning)
	editinlinenew
	hidecategories(Object);

var name SpawnZoneName;
var(Aggressors) IntegerRange DesiredAggressorCount;
var(Aggressors) config Range AggressorRepopulationTimeDelta;
var(Protectors) IntegerRange DesiredProtectorCount;
var(Protectors) config Range ProtectorRepopulationTimeDelta;
var bool bAggressorRepopulationEnabled;
var bool bProtectorRepopulationEnabled;
var const array<AggressorSpawner> AggressorSpawners;
var const array<ProtectorSpawner> ProtectorSpawners;
var const array<GathererVent> GathererVents;
var const array<IBooty> Booty;
var const float NextAggressorRepopulationTime;
var const float NextProtectorRepopulationTime;
var const float LastAICountInSpawnZoneTime;

defaultproperties
{
	AggressorRepopulationTimeDelta=(Min=30.0000000,Max=60.0000000)
	ProtectorRepopulationTimeDelta=(Min=30.0000000,Max=60.0000000)
	bAggressorRepopulationEnabled=true
	bProtectorRepopulationEnabled=true
}