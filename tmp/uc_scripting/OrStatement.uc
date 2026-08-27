class OrStatement extends ActionBool
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel bool lhs;
var travel bool rhs;

function Variable execute()
{
	local Class<Variable> varClass;
	local Variable lhsVAR;
	local string lhsStr;

	super.execute();
	lhsStr = string(lhs);
	Class'Scripting.Variable'.static.bestVariableClass(lhsStr, varClass);
	// End:0x99
	if(__NFUN_114__(varClass, Class'Scripting.VariableBool'))
	{
		returnVar.Value = __NFUN_132__(bool(lhsStr), bool(string(rhs)));
		goto J0xFA;
		lhsVAR = newTemporaryVariable(varClass, lhsStr);
		returnVar.Value = lhsVAR.or(string(rhs));
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
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("(", propertyDisplayString('lhs')), ") OR ("), propertyDisplayString('rhs')), ")");
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Or Statement"
	actionHelp="Returns the result of a logical or operation"
	Category="Logic"
}