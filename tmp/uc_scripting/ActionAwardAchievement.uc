class ActionAwardAchievement extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name Achievement;

function Variable execute()
{
	super.execute();
	parentScript.Level.GetGameDriver().GetAchievementManager().AwardAchievement(Achievement);
	return none;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__("Award achievement ", propertyDisplayString('Achievement'));
	return;
	@NULL
}

function enumAchievements(LevelInfo Level, out array<name> S)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x84
	/*@Error*/
	S[S.Length] = Class'Engine.AchievementManager'.default.Achievements[i].Name;
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

defaultproperties
{
	actionDisplayName="Award Achievement"
	actionHelp="Award an achievement to the player"
	Category="Other"
}