class ActionSpawnPlayerEscortedGatherer extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name GathererVentLabel;
var travel name SpawnPositionLabel;
var travel name SpawnedGathererLabel;
var travel bool bCorpseCanBeRemoved;
var travel bool bDontWaitForPlayer;
var travel bool bForceSpawn;
var travel bool bShouldPlayerEscort;
var travel array<name> OverriddenAIArchetypeNames;
var travel Gatherer.GathererVulnerableState GathererVulnerableState;

function Variable latentExecute()
{
	local SpawningManager SpawningManager;
	local PlayerEscortedGatherer SpawnedGatherer;
	local GathererVent vent;
	local ShockPlayer Player;
	local Actor Marker;
	local name OverriddenArchetypeName;

	execute();
	SpawningManager = SpawningManager(parentScript.Level.SpawningManager);
	// End:0x70
	if(__NFUN_151__(OverriddenAIArchetypeNames.Length, 0))
	{
		OverriddenArchetypeName = OverriddenAIArchetypeNames[__NFUN_167__(OverriddenAIArchetypeNames.Length)];
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x3C2
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x3C2
		/*@Error*/
		Player = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn);
	}
	assert(__NFUN_119__(Player, none));
	vent = GathererVent(findByLabel(Class'ShockAI.GathererVent', GathererVentLabel));
	SpawningManager.SetArchetypeOverrideName(OverriddenArchetypeName);
	// End:0x1EE
	if(__NFUN_254__(SpawnPositionLabel, 'None'))
	{
		SpawnedGatherer = PlayerEscortedGatherer(vent.SpawnGatherer(Player, SpawnedGathererLabel, bForceSpawn));
		SpawnedGatherer.bDontWaitForPlayer = bDontWaitForPlayer;
		// End:0x1EB
		if(__NFUN_129__(bCorpseCanBeRemoved))
		{
			__NFUN_163__(SpawnedGatherer.DelayCorpseRemoval);
			goto J0x382;
			Marker = findByLabel(Class'Engine.Actor', SpawnPositionLabel);
			SpawnedGatherer = PlayerEscortedGatherer(parentScript.Level.__NFUN_278__(vent.GetGathererClass(true),,, Marker.Location, Marker.Rotation, bForceSpawn, SpawnedGathererLabel));
			SpawnedGatherer.SetCurrentVent(vent);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x2EA
			/*@Error*/
			SpawnedGatherer.SetEscort(Player);
		}
	}
	SpawnedGatherer.BecomePhysical();
	SpawnedGatherer.SetSkipExitFlag(true);
	SpawnedGatherer.bDontWaitForPlayer = bDontWaitForPlayer;
	SpawnedGatherer.SetVulnerableState(GathererVulnerableState);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x382
	/*@Error*/
	__NFUN_163__(SpawnedGatherer.DelayCorpseRemoval);
	Player.EscortedGatherer = SpawnedGatherer;
	SpawningManager.SetArchetypeOverrideName('None');
	return none;
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_168__("Spawn a player escorted gatherer at", propertyDisplayString('GathererVentLabel'));
	return;
	@NULL
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
	SpawnedGathererLabel="PlayerEscortedGatherer"
	bCorpseCanBeRemoved=true
	actionDisplayName="Spawn a player escorted gatherer"
	actionHelp="Spawns a gatherer that uses the player as an escort"
	Category="AI"
}