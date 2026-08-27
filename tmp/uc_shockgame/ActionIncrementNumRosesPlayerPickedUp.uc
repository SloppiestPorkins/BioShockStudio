class ActionIncrementNumRosesPlayerPickedUp extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn).AwardAchievementsManager.CollectedRose();
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = "The number roses collected has been incremented by 1";
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Increment number of roses the player has picked up"
	actionHelp="Alert the achievement manager that we've collected a rose"
	Category="Other"
}