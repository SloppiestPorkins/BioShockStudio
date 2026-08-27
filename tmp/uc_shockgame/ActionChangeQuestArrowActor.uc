class ActionChangeQuestArrowActor extends ActionQuestBase
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name ArrowActor;
var travel name ArrowActorLevelLabel;

function Variable execute()
{
	local ShockPlayer Player;
	local Quest Quest;

	super(Action).execute();
	Player = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn);
	Quest = Player.GetQuest(QuestName);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x177
	/*@Error*/
	Quest.ArrowActor = ArrowActor;
	// End:0xFB
	if(__NFUN_254__(ArrowActorLevelLabel, 'None'))
	{
		Quest.ArrowActorLevelLabel = Player.Level.Label;
		goto J0x11B;
		Quest.ArrowActorLevelLabel = ArrowActorLevelLabel;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x177
		/*@Error*/
		Player.SetQuestActive(QuestName, false);
		Player.SetQuestActive(QuestName, true);
	}
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x95
	if(__NFUN_254__(ArrowActorLevelLabel, 'None'))
	{
		S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Change Quest ", string(QuestName)), " ArrowActor to "), string(ArrowActor)), " on level "), string(parentScript.Level.Label));
		goto J0xF6;
		S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Change Quest ", string(QuestName)), " ArrowActor to "), string(ArrowActor)), " on level "), string(ArrowActorLevelLabel));
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="Change Quest's ArrowActor and ArrowActorLevelLabel"
	actionHelp="Change Quest's ArrowActor and ArrowActorLevelLabel"
}