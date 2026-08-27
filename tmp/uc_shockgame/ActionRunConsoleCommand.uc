class ActionRunConsoleCommand extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel string Command;

function Variable execute()
{
	super.execute();
	parentScript.Level.GetLocalPlayerController().ConsoleCommand(Command);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(" Run command ", Command), ".");
	return;
	@NULL
	Item
}

defaultproperties
{
	actionDisplayName="Run a console command. DEBUG PURPOSES ONLY."
	actionHelp="Run a console command. DEBUG PURPOSES ONLY."
	Category="Debug"
}