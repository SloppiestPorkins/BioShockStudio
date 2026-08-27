class ActionRandomNumber extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel float minimum;
var travel float maximum;

function Variable execute()
{
	local float DONTforceWholeNumber;

	super.execute();
	DONTforceWholeNumber = __NFUN_174__(__NFUN_171__(__NFUN_195__(), __NFUN_175__(maximum, minimum)), minimum);
	return newTemporaryVariable(Class'Scripting.VariableFloat', string(DONTforceWholeNumber));
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__("A random number between ", propertyDisplayString('minimum')), " and "), propertyDisplayString('maximum'));
	return;
	@NULL
}

defaultproperties
{
	maximum=1.0000000
	actionDisplayName="Random Number"
	actionHelp="Generates a random number within a given range"
	returnType=Class'Scripting.Variable'
	Category="Variable"
}