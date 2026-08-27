class ActionVariableDecrement extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var /*0x00000000-0x00100000*/ travel name Target;

function Variable execute()
{
	local Variable vTarget, Result;

	super.execute();
	vTarget = findVariable(string(Target));
	// End:0x7A
	if(__NFUN_114__(vTarget, none))
	{
		logError("Target of the increment operation must be a variable");
		return none;
		vTarget.subtract("1");
	}
	Result = newTemporaryVariable(vTarget.Class, vTarget.GetPropertyTextByName('Value'));
	return Result;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__("Decrement ", propertyDisplayString('Target'));
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Decrement"
	actionHelp="Subtracts 1 from the variable"
	returnType=Class'Scripting.Variable'
	Category="Variable"
}