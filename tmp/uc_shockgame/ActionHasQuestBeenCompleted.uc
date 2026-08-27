class ActionHasQuestBeenCompleted extends ActionQuestBase
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	super(Action).execute();
	return newTemporaryVariable(Class'Scripting.VariableBool', string(ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn).GetQuest(QuestName).Completed));
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Get the number of completed objectives for quest '", string(QuestName)), "'.");
	return;
	@NULL
	Item
}

defaultproperties
{
	actionDisplayName="Get the number of completed objectives for a quest."
	actionHelp="Get the number of completed objectives for a quest."
	returnType=Class'Scripting.Variable'
}