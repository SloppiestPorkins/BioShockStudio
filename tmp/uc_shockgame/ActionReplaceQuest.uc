class ActionReplaceQuest extends ActionQuestBase
	config
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name ReplacementQuestName;
var travel bool CopyObjectivesCompleted;
var config localized string UpdatedMessage;

function Variable execute()
{
	local ShockPlayer Player;
	local Quest theQuest;

	super(Action).execute();
	Player = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn);
	Player.ReplaceQuest(QuestName, ReplacementQuestName, CopyObjectivesCompleted, ShowHUDFeedBack);
	theQuest = Player.GetQuest(QuestName);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x16A
	/*@Error*/
	parentScript.Level.GetLocalPlayerController().ClientMessage(__NFUN_112__(__NFUN_112__(UpdatedMessage, ": "), Player.GetQuestFriendlyName(QuestName)), 'Quests');
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Replace Quest '", string(QuestName)), "'"), " with '"), string(ReplacementQuestName)), "'");
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	CopyObjectivesCompleted=true
	UpdatedMessage="Goal Updated"
	actionDisplayName="Replace Quest."
	actionHelp="Replace a Quest."
}