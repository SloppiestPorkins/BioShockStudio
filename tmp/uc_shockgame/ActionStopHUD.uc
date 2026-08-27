class ActionStopHUD extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	parentScript.Level.GetFlashGUIController().StopMovie('HUD');
	return none;
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	actionDisplayName="STOP the HUD"
	actionHelp="Stops the HUD movie."
	Category="DO NOT USE UNLESS YOU KNOW WHAT YOU ARE DOING"
	bIsGameCritical=false
}