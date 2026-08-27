class ActionTriggerReactiveActor extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name ReactiveActorLabel;

function Variable execute()
{
	local ReactiveActor A;

	super.execute();
	// End:0x6D
	foreach parentScript.allActorLabel(Class'VengeanceShared.ReactiveActor', A, ReactiveActorLabel)
	{
		A.OnTriggeredByScript(parentScript.Label);				
		return none;
		return;
		@NULL
		Item
		Item
		@NULL
	}
}

defaultproperties
{
	actionDisplayName="Make a ReactiveActor execute its TriggeredReactions"
	actionHelp="Make a ReactiveActor execute its TriggeredReactions"
	Category="Actor"
}