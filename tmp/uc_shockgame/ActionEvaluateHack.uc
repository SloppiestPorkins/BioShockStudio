class ActionEvaluateHack extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var name HackedClassName;

function Variable execute()
{
	super.execute();
	return newTemporaryVariable(Class'Scripting.VariableFloat', string(ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn).CalculateHackDifficultyForClass(HackedClassName)));
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__("Evaluate Hacking ", string(HackedClassName));
	return;
	@NULL
	Item
}

defaultproperties
{
	actionDisplayName="Evaluate difficulty of a hack expressed in number of credits to override"
	actionHelp="Evaluate difficulty of a hack expressed in number of credits to override"
	returnType=Class'Scripting.Variable'
	Category="Hacking"
}