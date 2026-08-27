class ActionSetBouncerCanStepBack extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var name BouncerLabel;
var bool bCanStepBack;

function Variable execute()
{
	local Bouncer Iter;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x79
	/*@Error*/
	// End:0x78
	foreach parentScript.dynamicActorLabel(Class'ShockAI.Bouncer', Iter, BouncerLabel)
	{
		Iter.SetStepBack(bCanStepBack);				
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
	// End:0xBF
	if(__NFUN_255__(BouncerLabel, 'None'))
	{
		// End:0x71
		if(bCanStepBack)
		{
			S = __NFUN_112__(__NFUN_112__("Bouncer with label ", string(BouncerLabel)), " will be able to step back");
			goto J0xBC;
			S = __NFUN_112__(__NFUN_112__("Bouncer with label ", string(BouncerLabel)), " won't be able to step back");
		}
		goto J0xE3;
		S = "BouncerLabel is not set!";
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	actionDisplayName="Set a Bouncer's ability to step back"
	actionHelp="Set a Bouncer's ability to step back"
	Category="AI"
}