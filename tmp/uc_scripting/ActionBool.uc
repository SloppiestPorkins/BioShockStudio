class ActionBool extends Action
	abstract
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var transient VariableBool returnVar;

function Variable makeVariable(string Val)
{
	local Class<Variable> varClass;
	local Variable V;

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

function Variable execute()
{
	super.execute();
	// End:0x51
	if(__NFUN_114__(returnVar, none))
	{
		returnVar = Class'Scripting.VariableBool'.static.Allocate(self,,, 134217728).;
		Construct_Void();
		return returnVar;
		return;
		@NULL
		Variable
	}
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	return;
}

defaultproperties
{
	returnType=Class'Scripting.VariableBool'
}