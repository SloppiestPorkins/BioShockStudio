class ActionDisableOrEnableAdaptiveDifficulty extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel bool Enable;

function Variable execute()
{
	super.execute();
	ShockGameDriver(parentScript.Level.GetGameDriver()).GetDifficultyManager().SetAdaptiveDifficulty(Enable);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x22
	if(Enable)
	{
		S = "Enable";
		goto J0x35;
		S = "Disable";
	}
	S = __NFUN_112__(S, " adaptive difficulty");
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="Enable or disable adaptive difficulty"
	actionHelp="Enables or disables adaptive difficulty"
	Category="Difficulty"
}