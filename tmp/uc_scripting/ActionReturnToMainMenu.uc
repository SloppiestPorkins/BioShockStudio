class ActionReturnToMainMenu extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	super.execute();
	parentScript.Level.GetFlashGUIController().LaunchMainMenu();
	return none;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = "Return to main menu";
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Return to main menu"
	actionHelp="Return to main menu"
	Category="Other"
}