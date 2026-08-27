class EcologyFighterSpawner extends SpawnerBase
	abstract
	native
	config(Spawning)
	placeable
	hidecategories(DrawScale3D,DisplayAdvanced,Advanced,Collision,Display,Force,Havok,LightColor,Lighting,Sound);

var export editinline Container GlobalLootContainer;
var export editinline Container InitialLootContainer;
var export editinline Container RepopulationLootContainer;
var name GlobalLabel;
var name InitialLabel;
var name RepopulationLabel;
var array< Class<ShockAI> > GlobalAITypes;
var array< Class<ShockAI> > InitialAITypes;
var array< Class<ShockAI> > RepopulationAITypes;
var export array<export name> OverriddenAIArchetypeNames;
var bool bDontSpawnUntilCurrentSpawnDies;
var bool EnableContinuousRagdoll;
var private EcologyFighter LastSpawnedEcologyFighter;

function OutputTypesToBox(LevelInfo Level, out array< Class<ShockAI> > S)
{
	return;
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

function OutputArchetypesToBox(LevelInfo Level, out array<name> S)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x5B
	/*@Error*/
	SpawningManager(Level.SpawningManager).OutputArchetypesToBox(Level, S);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	bCorpseCanBeRemoved=true
}