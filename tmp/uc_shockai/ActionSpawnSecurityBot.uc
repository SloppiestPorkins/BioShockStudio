class ActionSpawnSecurityBot extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var SecurityBotSpawner Spawner;
var bool ImmediatelyGiveBotToPawn;
var name ReceivingPawnLabel;

function DisplaySpawners(LevelInfo Level, out array<SecurityBotSpawner> Spawners)
{
	local SecurityBotSpawner Iter;

	// End:0x44
	foreach Level.__NFUN_304__(Class'ShockAI.SecurityBotSpawner', Iter)
	{
		Spawners[Spawners.Length] = Iter;				
		return;
		@NULL
		CommanderAction
		CommanderAction
		@NULL
	}
}

function string DisplaySpawnerName(SecurityBotSpawner Spawner)
{
	// End:0x2B
	if(__NFUN_119__(Spawner, none))
	{
		return string(Spawner.Name);
		goto J0x3D;
		return "Spawner Not Set";
	}
	return;
	@NULL
	CommanderAction
	J0x3D:

	CommanderAction
}

function Variable execute()
{
	local SecurityBot SpawnedBot;
	local ShockPawn DestinationPawn;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xF4
	/*@Error*/
	// End:0xC0
	if(ImmediatelyGiveBotToPawn)
	{
		DestinationPawn = ShockPawn(findByLabel(Class'ShockGame.ShockPawn', ReceivingPawnLabel));
		// End:0xC0
		if(__NFUN_114__(DestinationPawn, none))
		{
			log('Spawning', 3, __NFUN_112__(__NFUN_112__("Could not find pawn ", string(ReceivingPawnLabel)), " to receive bot.  Not spawning bot."));
			return none;
			SpawnedBot = Spawner.SpawnScriptedSecurityBot(ImmediatelyGiveBotToPawn, DestinationPawn);
		}
	}
	return none;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__("Spawn Security Bot using spawner ", propertyDisplayString('Spawner'));
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Spawn a Security Bot"
	actionHelp="Spawns a Security Bot"
	Category="AI"
}