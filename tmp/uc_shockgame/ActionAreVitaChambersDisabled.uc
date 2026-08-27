class ActionAreVitaChambersDisabled extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	super.execute();
	return newTemporaryVariable(Class'Scripting.VariableBool', string(ShockUserSettings(parentScript.Level.GetGameDriver().GetUserSettings()).NoVitaChamber));
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = "Check whether Vita-Chambers are disabled.";
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Are Vita-Chambers disabled through the options menu?"
	actionHelp="Are Vita-Chambers disabled through the options menu?"
	returnType=Class'Scripting.Variable'
	Category="Level"
}