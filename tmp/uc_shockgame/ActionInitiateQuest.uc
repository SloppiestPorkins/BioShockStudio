class ActionInitiateQuest extends ActionQuestBase
	config
	editinlinenew
	collapsecategories
	hidecategories(Object);

var bool SetAsActiveQuest;
var config localized string NewQuestMessage;

function Variable execute()
{
	local ShockPlayer Player;
	local bool QuestWasInitiated;

	super(Action).execute();
	Player = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn);
	QuestWasInitiated = Player.InitiateQuest(QuestName, ShowHUDFeedBack);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x139
	/*@Error*/
	parentScript.Level.GetLocalPlayerController().ClientMessage(__NFUN_112__(__NFUN_112__(NewQuestMessage, ": "), Player.GetQuestFriendlyName(QuestName)), 'Quests');
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x139
	/*@Error*/
	Player.SetQuestActive(QuestName, true);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Initiate Quest '", string(QuestName)), "'");
	return;
	@NULL
	Item
}

defaultproperties
{
	SetAsActiveQuest=true
	NewQuestMessage="New Goal"
	actionDisplayName="Initiate Quest."
	actionHelp="Initiate a Quest."
}