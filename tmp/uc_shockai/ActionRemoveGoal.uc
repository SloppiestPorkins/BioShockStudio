class ActionRemoveGoal extends TyrionScriptAction
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name Target;
var travel string goalName;

function Variable latentExecute()
{
	local ShockAI AI;

	execute();
	// End:0x5C
	foreach parentScript.dynamicActorLabel(Class'ShockAI.ShockAI', AI, Target)
	{
		unPostGoal(AI, goalName);				
		return none;
		return;
		@NULL
		EcologyAI
		CommanderAction
		@NULL
	}
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__("Remove goal named ", goalName), " from "), propertyDisplayString('Target'));
	return;
	@NULL
	CommanderAction
}

defaultproperties
{
	actionDisplayName="Remove Goal"
	actionHelp="Removes a goal from an AI"
	Category="AI"
}