class NotStatement extends ActionBool
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel bool rhs;

function Variable execute()
{
	local Class<Variable> varClass;
	local Variable rhsVAR;
	local string rhsStr;

	super.execute();
	rhsStr = string(rhs);
	Class'Scripting.Variable'.static.bestVariableClass(rhsStr, varClass);
	// End:0x88
	if(__NFUN_114__(varClass, Class'Scripting.VariableBool'))
	{
		returnVar.Value = __NFUN_129__(bool(rhsStr));
		goto J0xDD;
		rhsVAR = newTemporaryVariable(varClass, rhsStr);
		returnVar.Value = rhsVAR.not();
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
	S = __NFUN_112__(__NFUN_112__("NOT(", propertyDisplayString('rhs')), ")");
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Not Statement"
	actionHelp="Returns the result of a logical not operation"
	Category="Logic"
}