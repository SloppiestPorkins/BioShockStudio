class ActionSetGathererVentPlayerCanSpawn extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name GathererVentLabel;
var travel bool Flag;

function Variable execute()
{
	local GathererVent vent;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x86
	/*@Error*/
	// End:0x85
	foreach parentScript.Level.dynamicActorLabel(Class'ShockAI.GathererVent', vent, GathererVentLabel)
	{
		vent.SetPlayerCanSpawn(Flag);				
		return none;
		return;
		@NULL
		CommanderAction
		CommanderAction
		@NULL
	}
}

function editorDisplayString(out string S)
{
	local string Insert;

	// End:0x1E
	if(Flag)
	{
		Insert = "to";
		goto J0x30;
		Insert = "to NOT";
	}
	S = __NFUN_168__(__NFUN_168__(__NFUN_168__("Set", propertyDisplayString('GathererVentLabel')), Insert), "allow the player to spawn a gatherer");
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	actionDisplayName="Set GathererVent bPlayerCanSpawn"
	actionHelp="Set whether player can spawn a gatherer at a gatherer vent"
	Category="AI"
}