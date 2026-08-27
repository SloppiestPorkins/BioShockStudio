class ActionCompleteQuestObjective extends ActionQuestBase
	editinlinenew
	collapsecategories
	hidecategories(Object);

var int NumberOfObjectivesCompleted;

function Variable execute()
{
	local ShockPlayer Player;
	local Quest theQuest;

	super(Action).execute();
	Player = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn);
	theQuest = Player.GetQuest(QuestName);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xE5
	/*@Error*/
	Player.OnCompletedQuestObjective(QuestName, NumberOfObjectivesCompleted, ShowHUDFeedBack);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Complete Objective for Quest '", string(QuestName)), "'");
	return;
	@NULL
	Item
}

defaultproperties
{
	NumberOfObjectivesCompleted=1
	actionDisplayName="Complete Quest Objective."
	actionHelp="Complete an objective for a Quest."
}