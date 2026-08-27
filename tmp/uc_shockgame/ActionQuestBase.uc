class ActionQuestBase extends Action
	abstract
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name QuestName;
var travel bool ShowHUDFeedBack;

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

defaultproperties
{
	ShowHUDFeedBack=true
	Category="Quests"
}