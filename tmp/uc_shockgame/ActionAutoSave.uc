class ActionAutoSave extends Action
	config
	editinlinenew
	collapsecategories
	hidecategories(Object);

var config string Command;

function Variable latentExecute()
{
	parentScript.Level.GetLocalPlayerController().ConsoleCommand(Command);
	return none;
	return;
	@NULL
	Collectable
	Item
	@NULL
}

defaultproperties
{
	Command="savegame autosave"
	actionDisplayName="Autosave"
	actionHelp="Autosaves the game."
	Category="Other"
	bIsGameCritical=false
}