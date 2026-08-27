class ActionGetResearchLevel extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name ResearchTrack;

function Variable execute()
{
	super.execute();
	return newTemporaryVariable(Class'Scripting.VariableFloat', string(ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn).GetResearchLevelForTrack(ResearchTrack)));
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_168__("Get the current research level for", string(ResearchTrack));
	return;
	@NULL
	Item
}

defaultproperties
{
	actionDisplayName="Get current research level for a research track."
	actionHelp="Get current research level for a research track."
	returnType=Class'Scripting.Variable'
	Category="Research"
}