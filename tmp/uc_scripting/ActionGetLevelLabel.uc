class ActionGetLevelLabel extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	local Variable ret;

	super.execute();
	ret = newTemporaryVariable(Class'Scripting.VariableName', string(parentScript.Level.Label));
	return ret;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = "Get the label of the Level.";
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Get Level's Label"
	actionHelp="Returns the label of the current level."
	returnType=Class'Scripting.Variable'
	Category="Level"
}