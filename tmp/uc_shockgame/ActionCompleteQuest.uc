class ActionCompleteQuest extends ActionQuestBase
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	local ShockPlayer Player;

	super(Action).execute();
	Player = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn);
	Player.CompleteQuest(QuestName, ShowHUDFeedBack);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Complete Quest '", string(QuestName)), "'");
	return;
	@NULL
	Item
}

defaultproperties
{
	actionDisplayName="Complete Quest."
	actionHelp="Complete a Quest."
}