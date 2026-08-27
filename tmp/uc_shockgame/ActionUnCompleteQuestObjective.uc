class ActionUnCompleteQuestObjective extends ActionQuestBase
	config
	editinlinenew
	collapsecategories
	hidecategories(Object);

var config localized string ObjectiveMessage;

function Variable execute()
{
	local ShockPlayer Player;

	super(Action).execute();
	Player = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn);
	Player.OnUnCompletedQuestObjective(QuestName, ShowHUDFeedBack);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xF1
	/*@Error*/
	parentScript.Level.GetLocalPlayerController().ClientMessage(__NFUN_112__(__NFUN_112__(ObjectiveMessage, ": "), Player.GetQuestFriendlyName(QuestName)), 'Quests');
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Un-Complete Objective for Quest '", string(QuestName)), "'");
	return;
	@NULL
	Item
}

defaultproperties
{
	ObjectiveMessage="Objective Un-Completed"
	actionDisplayName="Un-Complete Quest Objective."
	actionHelp="Un-Completes an objective for a Quest."
}