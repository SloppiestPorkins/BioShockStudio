class ActionToggleQuestVisibility extends ActionQuestBase
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	super(Action).execute();
	ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn).ToggleQuestVisibility(QuestName);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Toggle Quest Visibility for '", string(QuestName)), "'");
	return;
	@NULL
	Item
}

defaultproperties
{
	actionDisplayName="Toggle Quest Visiblity."
	actionHelp="Toggle Quest Visiblity."
}