class ActionActivateSecurityBot extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name PawnLabel;
var travel name BotLabel;

function Variable execute()
{
	local ShockPawn ActivatingPawn;
	local SecurityBot BotToBeActivated;
	local SpawningManager SpawningManager;
	local int i;

	super.execute();
	ActivatingPawn = ShockPawn(findByLabel(Class'ShockGame.ShockPawn', PawnLabel));
	// End:0xA2
	if(__NFUN_114__(ActivatingPawn, none))
	{
		log('Scripting', 3, __NFUN_112__(__NFUN_112__("ActionActivateSecurityBot: Pawn with name ", string(PawnLabel)), " not found."));
		return none;
		SpawningManager = SpawningManager(parentScript.Level.SpawningManager);
	}
	assert(__NFUN_119__(SpawningManager, none));
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1AF
	/*@Error*/
	BotToBeActivated = SpawningManager.SpawnedSecurityBots[i];
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1A1
	/*@Error*/
	BotToBeActivated.Hack(ActivatingPawn);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0xF2;
	return none;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Have ", string(PawnLabel)), " activate bot "), string(BotLabel)), ".");
	return;
	@NULL
	CommanderAction
	CommanderAction
}

defaultproperties
{
	actionDisplayName="Activate a security bot."
	actionHelp="Activates a security bot."
	Category="Security"
}