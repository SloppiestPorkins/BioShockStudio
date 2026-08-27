class ActionManipulateSpawnZoneRepopulation extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

enum ESpawnZoneRepopulationState
{
	NoChange,                       // 0
	Enable,                         // 1
	Disable                         // 2
};

var travel name SpawnZoneName;
var travel ActionManipulateSpawnZoneRepopulation.ESpawnZoneRepopulationState AggressorRepopulationState;
var travel ActionManipulateSpawnZoneRepopulation.ESpawnZoneRepopulationState ProtectorRepopulationState;

function OutputSpawnZonesToBox(LevelInfo Level, out array<name> S)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x5B
	/*@Error*/
	SpawningManager(Level.SpawningManager).OutputSpawnZonesToBox(Level, S);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Variable execute()
{
	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x187
	/*@Error*/
	// End:0x7C
	if(__NFUN_154__(int(AggressorRepopulationState), int(1)))
	{
		SpawningManager(parentScript.Level.SpawningManager).SetAggressorRepopulationEnabledInSpawnZone(SpawnZoneName, true);
		goto J0xD4;
		// End:0xD4
		if(__NFUN_154__(int(AggressorRepopulationState), int(2)))
		{
			SpawningManager(parentScript.Level.SpawningManager).SetAggressorRepopulationEnabledInSpawnZone(SpawnZoneName, false);
		}
		// End:0x12F
		if(__NFUN_154__(int(ProtectorRepopulationState), int(1)))
		{
			SpawningManager(parentScript.Level.SpawningManager).SetProtectorRepopulationEnabledInSpawnZone(SpawnZoneName, true);
		}
		goto J0x187;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x187
		/*@Error*/
		SpawningManager(parentScript.Level.SpawningManager).SetProtectorRepopulationEnabledInSpawnZone(SpawnZoneName, false);
		return none;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0xCD
	if(__NFUN_255__(SpawnZoneName, 'None'))
	{
		S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Manipulate SpawnZone ", string(SpawnZoneName)), " Repopulation to "), string(GetEnum(Enum'ShockAI.ActionManipulateSpawnZoneRepopulation.ESpawnZoneRepopulationState', int(AggressorRepopulationState)))), " for Aggressors and "), string(GetEnum(Enum'ShockAI.ActionManipulateSpawnZoneRepopulation.ESpawnZoneRepopulationState', int(ProtectorRepopulationState)))), " for Protectors.");
		goto J0xF2;
		S = "SpawnZoneName is not set!";
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	actionDisplayName="Manipulate Repopulation of a SpawnZone"
	actionHelp="Manipulate Repopulation of a SpawnZone"
	Category="AI"
}