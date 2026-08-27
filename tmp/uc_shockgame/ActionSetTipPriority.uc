class ActionSetTipPriority extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var name TipName;
var TrainingMessageManager.QueuePriority Priority;

function Variable execute()
{
	super.execute();
	ShockGameDriver(parentScript.Level.GetGameDriver()).GetTrainingMessageManager().SetTipPriority(TipName, Priority);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__("Set ", string(TipName)), " Priority to "), string(Priority));
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	actionDisplayName="Set Tip Priority"
	actionHelp="Set the priority of a loading screen tip"
	Category="Training"
}