class ActionHasQuestBeenAssigned extends ActionQuestBase
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	super(Action).execute();
	return newTemporaryVariable(Class'Scripting.VariableBool', string(__NFUN_129__(ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn).GetQuest(QuestName).Hidden)));
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Has quest '", string(QuestName)), "' has been assigned.");
	return;
	@NULL
	Item
}

defaultproperties
{
	actionDisplayName="Test if a quest has been assigned."
	actionHelp="Returns if a quest has been assigned."
	returnType=Class'Scripting.Variable'
}