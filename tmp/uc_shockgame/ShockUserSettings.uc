class ShockUserSettings extends UserSettings
	native
	config;

var config bool HasPlasmidPack_1;
var config bool NeedToShowPlasmidAnnouncement;
var config int Brightness;
var config int Contrast;
var config int Gamma;
var config bool VSync;
var config float DLC1_Combat_Easy_BestTimeInSeconds;
var config float DLC1_Combat_Medium_BestTimeInSeconds;
var config float DLC1_Combat_Hard_BestTimeInSeconds;
var config float DLC1_Combat_Survivor_BestTimeInSeconds;
var config float DLC1_Electric_BestTimeInSeconds;
var config float DLC1_Decoy_BestTimeInSeconds;
var config bool bPlayedChallengeRoom;
var config bool bViewedDLC1AvailableNow;
var config int LevelCompletionMask;
var config int TrialsCompletionMask;

function float GetBrightness()
{
	// End:0x2F
	if(__NFUN_152__(Brightness, 0))
	{
		Brightness = Class.default.Brightness;
		return __NFUN_172__(float(Brightness), 1000.0000000);
		return;
	}
	@NULL
	Item
	Item
	@NULL
}

function float GetContrast()
{
	// End:0x2F
	if(__NFUN_152__(Contrast, 0))
	{
		Contrast = Class.default.Contrast;
		return __NFUN_172__(float(Contrast), 1000.0000000);
		return;
	}
	@NULL
	Item
	Item
	@NULL
}

function SetBrightness(float inBrightness)
{
	Brightness = __NFUN_250__(1, int(__NFUN_171__(inBrightness, 1000.0000000)));
	return;
	@NULL
	Item
}

function SetContrast(float inContrast)
{
	Contrast = __NFUN_250__(1, int(__NFUN_171__(inContrast, 1000.0000000)));
	return;
	@NULL
	Item
}

defaultproperties
{
	Brightness=500
	Contrast=500
	VSync=true
	AdaptiveTraining=true
	QuestArrow=true
}