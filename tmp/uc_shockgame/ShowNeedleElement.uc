class ShowNeedleElement extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	local ShockPlayerController PC;

	super.execute();
	PC = ShockPlayerController(parentScript.Level.GetLocalPlayerController());
	ShockHUD(PC.myHUD).ShowNeedleElement();
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = "Show the needle HUD element for the boss fight";
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Show Needle HUD Element"
	actionHelp="Show the needle HUD element for the boss fight"
	Category="HUD"
}