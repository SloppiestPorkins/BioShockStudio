class ActionStartChallengeTimer extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	local ShockPlayer Player;

	super.execute();
	Player = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn);
	Player.StartChallengeTimer();
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = "Challenge Room timer started";
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Start the challenge timer"
	actionHelp="Start the challenge timer for the DLC1 ChallengeRooms"
	Category="Other"
}