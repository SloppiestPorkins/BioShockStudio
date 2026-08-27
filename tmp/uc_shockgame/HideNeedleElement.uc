class HideNeedleElement extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	local ShockPlayerController PC;

	super.execute();
	PC = ShockPlayerController(parentScript.Level.GetLocalPlayerController());
	ShockHUD(PC.myHUD).HideNeedleElement();
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = "Hide the needle HUD element for the boss fight";
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Hide Needle HUD Element"
	actionHelp="Hide the needle HUD element for the boss fight"
	Category="HUD"
}