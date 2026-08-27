class ActionVariableAssign extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var /*0x00000000-0x00100000*/ travel name lhs;
var travel string rhs;

function Variable execute()
{
	local Variable vLhs;
	local Class<Variable> NewClass;

	super.execute();
	vLhs = tryFindVariable(string(lhs));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x119
	/*@Error*/
	// End:0xCA
	if(__NFUN_155__(__NFUN_126__(string(lhs), "."), -1))
	{
		logError(__NFUN_112__(__NFUN_112__("You can only create variables that reside within the current script (variable ", string(lhs)), " not found)"));
		return none;
		Class'Scripting.Variable'.static.bestVariableClass(rhs, NewClass);
	}
	vLhs = newVariable(lhs, NewClass);
	vLhs.SetPropertyText("value", rhs);
	return none;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(propertyDisplayString('lhs'), " = "), propertyDisplayString('rhs'));
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Assignment"
	actionHelp="Assigns one variable to another"
	Category="Variable"
	acceptAllTypes=true
}