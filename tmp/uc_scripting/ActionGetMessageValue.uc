class ActionGetMessageValue extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name Property;

function messageProperties(LevelInfo Level, out array<name> S)
{
	local name PropName;

	// End:0x5E
	if(__NFUN_114__(parentScript.scriptMessageClass, none))
	{
		logError("This script does not have a message class set for it");
		return;
		// End:0xB2
		foreach AllProperties(parentScript.scriptMessageClass, Class'Engine.Message', PropName)
		{
		}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x056! */
		S[S.Length] = PropName;				
		return;
		@NULL
		Variable
		Variable
		@NULL
	}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x000! */
}

function Variable execute()
{
	local Message currMessage;
	local Class<Variable> varClass;
	local Variable V;
	local string Val;

	super.execute();
	currMessage = parentScript.triggeringMessage();
	// End:0x3C
	if(__NFUN_114__(currMessage, none))
	{
		return none;
		Val = currMessage.GetPropertyTextByName(Property);
	}
	Class'Scripting.Variable'.static.bestVariableClass(Val, varClass);
	V = newTemporaryVariable(varClass);
	V.SetPropertyText("value", Val);
	return V;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(string(parentScript.scriptMessageClass.Name), "."), propertyDisplayString('Property'));
	return;
	@NULL
	Variable
	Variable
	@NULL
}

defaultproperties
{
	actionDisplayName="Get Message Value"
	actionHelp="Gets a value from the message that triggered the script"
	returnType=Class'Scripting.Variable'
	Category="Script"
}