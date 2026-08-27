class ActionExitLoop extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	super.execute();
	parentScript.exitLoop();
	return none;
	return;
	@NULL
	Variable
}

defaultproperties
{
	actionDisplayName="Exit Loop"
	actionHelp="Ends execution of the current loop. Does nothing if no loop is running"
	Category="Script"
}