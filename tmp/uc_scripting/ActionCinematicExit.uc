class ActionCinematicExit extends Action
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	super.execute();
	cinematicExit();
	PlayerController(parentScript.Level.GetLocalPlayerController().Pawn.Controller).myHUD.bHideHUD = false;
	return none;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

// Export UActionCinematicExit::execcinematicExit(FFrame&, void* const)
native static function cinematicExit();

function editorDisplayString(out string S)
{
	S = "Exit cinematic mode";
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Cinematic Mode: Exit"
	actionHelp="Exit cinematic mode"
	Category="Cinematic"
}