class ActionShowTrainingMessage extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name MessageName;

function Variable execute()
{
	local VariableBool returnVar;

	super.execute();
	returnVar = VariableBool(newTemporaryVariable(Class'Scripting.VariableBool'));
	returnVar.Value = ShockGameDriver(parentScript.Level.GetGameDriver()).GetTrainingMessageManager().TriggerTrainingMessage(MessageName, none);
	return returnVar;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__("Show Message ", propertyDisplayString('MessageName'));
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Show training message"
	actionHelp="Show a training message configured in training.ini"
	returnType=Class'Scripting.VariableBool'
	Category="Training"
}