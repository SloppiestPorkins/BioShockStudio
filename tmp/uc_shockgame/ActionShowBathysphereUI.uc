class ActionShowBathysphereUI extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name BathysphereSystem;

function Variable execute()
{
	super.execute();
	ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn).ShowBathysphereUI(BathysphereSystem);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = "Open bathysphere travel UI";
	return;
	@NULL
}

defaultproperties
{
	BathysphereSystem="BioshockBathyspheres"
	actionDisplayName="Open bathysphere travel UI"
	actionHelp="Open bathysphere travel UI"
	Category="Level"
}