class ActionEndGame extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel int NumberOfGatherersKilledToGetBadEnding;

function Variable execute()
{
	local FlashMovie movie;
	local ShockPlayer Player;

	super.execute();
	Player = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn);
	parentScript.Level.GetFlashGUIController().FinishedGame();
	Player.SaveGamePlusData();
	// End:0x196
	if(__NFUN_153__(Player.AwardAchievementsManager.GetNumberOfGatherersHarvested(), NumberOfGatherersKilledToGetBadEnding))
	{
		ShockGameDriver(parentScript.Level.GetGameDriver()).GetPlayerStatsManager().GameFinished(Player, false);
		parentScript.Level.GetFlashGUIController().HideAllMovies();
		movie = parentScript.Level.GetFlashGUIController().PlayMovie('EndingMovieHarvestedGatherers');
		goto J0x260;
		ShockGameDriver(parentScript.Level.GetGameDriver()).GetPlayerStatsManager().GameFinished(Player, true);
		parentScript.Level.GetFlashGUIController().HideAllMovies();
	}
	movie = parentScript.Level.GetFlashGUIController().PlayMovie('EndingMovieSavedGatherers');
	movie.CallMethodInt("SetDialogSubtitles", int(parentScript.Level.GetGameDriver().GetUserSettings().GetDialogSubtitlesSetting()));
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = "Play ending sequence and return to main menu";
	return;
	@NULL
}

defaultproperties
{
	NumberOfGatherersKilledToGetBadEnding=14
	actionDisplayName="End the game"
	actionHelp="Signify that the game has ended."
	Category="Other"
}