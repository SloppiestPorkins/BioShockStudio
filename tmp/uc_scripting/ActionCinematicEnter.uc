class ActionCinematicEnter extends Action
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	super.execute();
	cinematicEnter();
	PlayerController(parentScript.Level.GetLocalPlayerController().Pawn.Controller).myHUD.bHideHUD = true;
	return none;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

// Export UActionCinematicEnter::execcinematicEnter(FFrame&, void* const)
native static function cinematicEnter();

function editorDisplayString(out string S)
{
	S = "Enter cinematic mode";
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Cinematic Mode: Enter"
	actionHelp="Enter cinematic mode"
	Category="Cinematic"
}