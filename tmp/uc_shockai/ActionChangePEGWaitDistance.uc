class ActionChangePEGWaitDistance extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name PEGLabel;
var travel float WaitDistance;

function Variable execute()
{
	local PlayerEscortedGatherer Iter;
	local GathererCommanderAction gca;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA8
	/*@Error*/
	// End:0xA7
	foreach parentScript.allActorLabel(Class'ShockAI.PlayerEscortedGatherer', Iter, PEGLabel)
	{
		gca = Iter.GetGathererCommanderAction();
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xA6
		/*@Error*/
		gca.SetDistanceForPEGToWait(WaitDistance);				
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
	// End:0x69
	if(__NFUN_255__(PEGLabel, 'None'))
	{
		S = __NFUN_168__(__NFUN_168__(__NFUN_168__("PEG with label", string(PEGLabel)), "set to wait at distance"), string(WaitDistance));
		goto J0x89;
		S = "PEGLabel is not set!";
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	actionDisplayName="Change the wait distance on a PEG"
	actionHelp="Change the wait distance on a PEG"
	Category="AI"
}