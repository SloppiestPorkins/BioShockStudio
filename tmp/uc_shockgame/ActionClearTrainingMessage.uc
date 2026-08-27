class ActionClearTrainingMessage extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var name MessageName;

function Variable execute()
{
	local VariableBool returnVar;

	super.execute();
	returnVar = VariableBool(newTemporaryVariable(Class'Scripting.VariableBool'));
	returnVar.Value = ShockGameDriver(parentScript.Level.GetGameDriver()).GetTrainingMessageManager().ClearTrainingMessage(MessageName);
	return returnVar;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__("Clear Training Message ", propertyDisplayString('MessageName'));
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Stop training message from displaying if queued or currently displaying"
	actionHelp="Stop a training message configured in training.ini, returns if message was cleared or not"
	returnType=Class'Scripting.VariableBool'
	Category="Training"
}