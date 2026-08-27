class actionSetQuestHint extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name QuestName;
var travel name HintName;

function Variable execute()
{
	local ShockPlayer Player;
	local Quest Quest;
	local int i;

	super.execute();
	Player = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn);
	Quest = Player.GetQuest(QuestName);
	// End:0x13F
	if(__NFUN_119__(Quest, none))
	{
		i = 0;
		// End:0x13F
		if(__NFUN_150__(i, Quest.QuestHints.Length))
		{
			// End:0x131
			if(__NFUN_254__(Quest.QuestHints[i].HintName, HintName))
			{
				Quest.CurrentHintName = HintName;
				Quest.HasSeenCurrentHint = false;
				return none;
				__NFUN_165__(i);
				// [Loop Continue]
				goto J0x92;
				log('Quest', 2, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("WARNING: ", string(self)), " tried to set invalid hint "), string(HintName)), " on quest "), string(QuestName)));
			}
			return none;
			return;
			@NULL
			Item
		}
	}
	Item
	@NULL
}

function AllQuestNames(LevelInfo Level, out array<name> S)
{
	local int i;
	local QuestManager QuestManager;

	QuestManager = Class'ShockGame.QuestManager'.static.Allocate(self).;
	Construct_Void();
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA3
	/*@Error*/
	S[i] = QuestManager.QuestNames[i];
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x3C;
	QuestManager.__NFUN_200__();
	return;
	@NULL
	Item
	Item
	@NULL
}

function AllQuestHintNames(LevelInfo Level, out array<name> S)
{
	local int i;
	local Quest Quest;

	Quest = Class'ShockGame.Quest'.static.Allocate(self, none, string(QuestName)).;
	Construct_Void();
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xC0
	/*@Error*/
	S[i] = Quest.QuestHints[i].HintName;
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x48;
	Quest.__NFUN_200__();
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__("Show Hint ", string(HintName)), " for Quest "), string(QuestName));
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	actionDisplayName="Set Quest Hint."
	actionHelp="Set Quest Hint."
	Category="Quests"
}