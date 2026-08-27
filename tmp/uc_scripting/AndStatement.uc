class AndStatement extends ActionBool
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
		returnVar.Value = __NFUN_130__(bool(lhsStr), bool(string(rhs)));
		goto J0x14B;
		log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__("AndStatement lhs class is ", string(varClass.Name)), " for "), lhsStr));
	}
	lhsVAR = newTemporaryVariable(varClass, lhsStr);
	returnVar.Value = lhsVAR.and(string(rhs));
	return returnVar;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("(", propertyDisplayString('lhs')), ") AND ("), propertyDisplayString('rhs')), ")");
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="And Statement"
	actionHelp="Returns the result of a logical and operation"
	Category="Logic"
}