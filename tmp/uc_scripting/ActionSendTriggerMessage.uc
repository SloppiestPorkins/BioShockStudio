class ActionSendTriggerMessage extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name Instigator;

function Variable execute()
{
	super.execute();
	// End:0x41
	if(__NFUN_254__(Instigator, 'None'))
	{
		Instigator = parentScript.Label;
		parentScript.dispatchMessage(Class'Scripting.MessageTrigger'.static.Allocate(self)., construct_NameName(parentScript.Label, Instigator));
	}
	return none;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

defaultproperties
{
	actionDisplayName="Send Trigger Message"
	actionHelp="Sends a MessageTrigger that can be used to open doors, move movers, etc."
	Category="Script"
}