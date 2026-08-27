class TruthStatement extends ActionBool
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name Value;

function Variable execute()
{
	local Class<Variable> varClass;
	local Variable valueVar;
	local string valueStr;

	super.execute();
	valueStr = string(Value);
	Class'Scripting.Variable'.static.bestVariableClass(valueStr, varClass);
	// End:0x85
	if(__NFUN_114__(varClass, Class'Scripting.VariableBool'))
	{
		returnVar.Value = bool(valueStr);
		goto J0xDA;
		valueVar = newTemporaryVariable(varClass, valueStr);
		returnVar.Value = valueVar.truth();
	}
	return returnVar;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = propertyDisplayString('Value');
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Truth Statement"
	actionHelp="Returns value evaluated as a boolean"
	Category="Logic"
}