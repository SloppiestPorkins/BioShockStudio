class ActionVariableAdd extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var /*0x00000000-0x00100000*/ travel name lhs;
var travel string rhs;

function Variable execute()
{
	local Variable vLhs, Result;

	super.execute();
	vLhs = findVariable(string(lhs));
	// End:0x77
	if(__NFUN_114__(vLhs, none))
	{
		logError("lhs of an arithmetic operation must be a variable");
		return none;
		Result = newTemporaryVariable(vLhs.Class, vLhs.GetPropertyTextByName('Value'));
	}
	Result.Add(rhs);
	return Result;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(propertyDisplayString('lhs'), " + "), propertyDisplayString('rhs'));
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Addition"
	actionHelp="Returns the result of the addition of one variable to another"
	returnType=Class'Scripting.Variable'
	Category="Variable"
}