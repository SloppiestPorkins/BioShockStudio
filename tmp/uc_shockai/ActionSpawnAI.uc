class ActionSpawnAI extends Action
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel Class<ShockAI> AITypeToSpawn;
var travel name SpawnLocationLabel;
var travel name SpawnedAILabel;
var export editinline travel Container SpawnedAILootContainer;
var travel name SpawnedAIPatrol;
var travel float MinRadiusToSpawnAroundSpawnLoc;
var travel float MaxRadiusToSpawnAroundSpawnLoc;
var travel bool StartOutAsMimic;
var travel Range ProtectorGuardRange;
var travel array<name> OverriddenAIArchetypeNames;
var travel bool bCorpseCanBeRemoved;
var travel PoseData SpawnedMimicInitialPose;
var travel Gatherer.GathererVulnerableState GathererVulnerableState;
var travel bool bForceSpawn;

function DisplayAITypes(LevelInfo Level, out array< Class<ShockAI> > S)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x5B
	/*@Error*/
	SpawningManager(Level.SpawningManager).DisplayAllAITypes(Level, S);
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

function OutputPatrolsToBox(LevelInfo Level, out array<name> S)
{
	Class'ShockAI.SpawningManager'.static.OutputPatrolsToBox(Level, S);
	return;
	@NULL
	CommanderAction
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

function enumAnimationsForType(Class<Aggressor> AggressorType, LevelInfo Level, out array<name> S)
{
	local int i;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x82
	/*@Error*/
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x82
	/*@Error*/
	S[S.Length] = AggressorType.default.MimicPoseAnimations[i];
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x1A;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function enumAnimations(LevelInfo Level, out array<name> S)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x57
	/*@Error*/
	enumAnimationsForType(Class<Aggressor>(AITypeToSpawn), Level, S);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Variable execute()
{
	local SpawningManager SpawningManager;
	local name OverriddenArchetypeName;
	local ShockAI SpawnedAI;

	super.execute();
	// End:0x3A
	if(__NFUN_151__(OverriddenAIArchetypeNames.Length, 0))
	{
		OverriddenArchetypeName = OverriddenAIArchetypeNames[__NFUN_167__(OverriddenAIArchetypeNames.Length)];
		SpawningManager = SpawningManager(parentScript.Level.SpawningManager);
	}
	SpawnedAI = SpawningManager.SpawnScriptedAI(AITypeToSpawn, SpawnLocationLabel, SpawnedAILabel, SpawnedAILootContainer, SpawnedAIPatrol, MinRadiusToSpawnAroundSpawnLoc, MaxRadiusToSpawnAroundSpawnLoc, StartOutAsMimic, ProtectorGuardRange, OverriddenArchetypeName, bCorpseCanBeRemoved, bForceSpawn);
	AssertWithDescription(__NFUN_132__(__NFUN_129__(AITypeToSpawn.__NFUN_258__(AITypeToSpawn, Class'ShockAI.ScriptedAI')), __NFUN_255__(OverriddenArchetypeName, 'None')), __NFUN_168__(__NFUN_168__("A ScriptedAI is being spawned in", string(Name)), "without an OverridenArchetypeName set"));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x24A
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x205
	/*@Error*/
	Aggressor(SpawnedAI).SetMimicInitialPose(SpawnedMimicInitialPose);
	goto J0x24A;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x24A
	/*@Error*/
	Gatherer(SpawnedAI).SetVulnerableState(GathererVulnerableState);
	return newTemporaryVariable(Class'Scripting.VariableBool', string(__NFUN_119__(SpawnedAI, none)));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__("Spawn AI ", propertyDisplayString('AITypeToSpawn'));
	// End:0xB5
	if(__NFUN_130__(__NFUN_177__(MinRadiusToSpawnAroundSpawnLoc, 0.0000000), __NFUN_177__(MaxRadiusToSpawnAroundSpawnLoc, 0.0000000)))
	{
		S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(S, " between "), string(MinRadiusToSpawnAroundSpawnLoc)), " and "), string(MaxRadiusToSpawnAroundSpawnLoc)), " units from "), string(SpawnLocationLabel));
		goto J0xDD;
		S = __NFUN_112__(__NFUN_112__(S, " at "), string(SpawnLocationLabel));
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	bCorpseCanBeRemoved=true
	GathererVulnerableState=1
	actionDisplayName="Spawn AI"
	actionHelp="Spawns an AI"
	returnType=Class'Scripting.VariableBool'
	Category="AI"
}