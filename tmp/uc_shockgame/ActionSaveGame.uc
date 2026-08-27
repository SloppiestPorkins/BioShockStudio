class ActionSaveGame extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var string SaveGameName;

function Variable execute()
{
	super.execute();
	parentScript.Level.GetLocalPlayerController().ConsoleCommand(__NFUN_112__("SAVEGAMESCRIPTED ", SaveGameName));
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = "Saves the game with the specified save name";
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Saves the game"
	actionHelp="Saves the game with the specified save name"
	Category="Level"
}