class ActionActivateResurrectionStation extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name ResurrectionStationLabel;
var travel bool ActivateStation;

function Variable execute()
{
	local BaseResurrectionStation Station;
	local ShockPlayer Player;

	super.execute();
	Player = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn);
	assert(__NFUN_119__(Player, none));
	// End:0xE3
	foreach parentScript.dynamicActorLabel(Class'ShockGame.BaseResurrectionStation', Station, ResurrectionStationLabel)
	{
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xC2
		/*@Error*/
		Station.ActivateStation(Player);
		goto J0xE2;
		Station.DeactivateStation(Player);				
		return none;
		return;
		@NULL
		Item
		Item
		@NULL
	}
}

function editorDisplayString(out string S)
{
	// End:0x57
	if(ActivateStation)
	{
		S = __NFUN_112__(__NFUN_112__("Activate resurrection station with label ", string(ResurrectionStationLabel)), ".");
		goto J0xA0;
		S = __NFUN_112__(__NFUN_112__("Deactivate resurrection station with label ", string(ResurrectionStationLabel)), ".");
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	ActivateStation=true
	actionDisplayName="Activate Resurrection Station."
	actionHelp="Activates or deactivates a resurrection station."
	Category="Machines"
}