class ShockGameDriver extends GameDriver
	transient
	native
	config(ShockGame);

struct native atomic PresenceMode
{
	var name LevelLabel;
	var int Mode;
};

var private transient TrainingMessageManager TrainingMessageManager;
var private transient PlayerStatsManager PlayerStatsManager;
var private transient FactDatabase FactDatabase;
var private transient DifficultyManager DifficultyManager;
var private transient SubtitleManager SubtitleManager;
var private transient ShockUserSettings UserSettings;
var transient array<CameraPhoto> SavedPhotos;
var config array<PresenceMode> PresenceModes;
var private LevelInfo Level;

function PreGameEngineInit()
{
	super.PreGameEngineInit();
	FactDatabase = Class'ShockGame.FactDatabase'.static.Allocate(self).;
	construct_ShockGameDriver(self);
	TrainingMessageManager = Class'ShockGame.TrainingMessageManager'.static.Allocate(self).;
	construct_ShockGameDriver(self);
	DifficultyManager = Class'ShockGame.DifficultyManager'.static.Allocate(self).;
	construct_ShockGameDriver(self);
	PlayerStatsManager = Class'ShockGame.PlayerStatsManager'.static.Allocate(self).;
	construct_ShockGameDriver(self);
	UserSettings = Class'ShockGame.ShockUserSettings'.static.Allocate(self).;
	Construct_Void();
	UserSettings.Initialize();
	SubtitleManager = Class'ShockGame.SubtitleManager'.static.Allocate(self).;
	construct_ShockGameDriver(self);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function PostGameEngineInit()
{
	super.PostGameEngineInit();
	NativePostGameEngineInit();
	return;
	@NULL
}

// Export UShockGameDriver::execNativePostGameEngineInit(FFrame&, void* const)
native function NativePostGameEngineInit();

function PreLevelLoad()
{
	super.PreLevelLoad();
	PlayerStatsManager.PreLevelLoad();
	TrainingMessageManager.PreLevelLoad();
	FactDatabase.PreLevelLoad();
	Level = none;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function PostLevelLoad(LevelInfo Level)
{
	super.PostLevelLoad(Level);
	self.Level = Level;
	PlayerStatsManager.PostLevelLoad();
	TrainingMessageManager.PostLevelLoad();
	FactDatabase.PostLevelLoad();
	SetPresenceMode();
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

// Export UShockGameDriver::execSetPresenceMode(FFrame&, void* const)
native function SetPresenceMode();

function LevelInfo GetLevel()
{
	return Level;
	return;
	@NULL
}

function PlayerStatsManager GetPlayerStatsManager()
{
	return PlayerStatsManager;
	return;
	@NULL
}

function TrainingMessageManager GetTrainingMessageManager()
{
	return TrainingMessageManager;
	return;
	@NULL
}

function FactDatabase GetFactDatabase()
{
	return FactDatabase;
	return;
	@NULL
}

function SubtitleManagerBase GetSubtitleManager()
{
	return SubtitleManager;
	return;
	@NULL
}

function DifficultyManager GetDifficultyManager()
{
	return DifficultyManager;
	return;
	@NULL
}

function UserSettings GetUserSettings()
{
	return UserSettings;
	return;
	@NULL
}

defaultproperties
{
	PresenceModes[0]=(LevelLabel="0-Lighthouse",Mode=1)
	PresenceModes[1]=(LevelLabel="1-Welcome",Mode=2)
	PresenceModes[2]=(LevelLabel="1-Medical",Mode=3)
	PresenceModes[3]=(LevelLabel="2-Fisheries",Mode=4)
	PresenceModes[4]=(LevelLabel="2-SubBay",Mode=5)
	PresenceModes[5]=(LevelLabel="3-Arcadia",Mode=6)
	PresenceModes[6]=(LevelLabel="3-Market",Mode=7)
	PresenceModes[7]=(LevelLabel="4-Recreation",Mode=8)
	PresenceModes[8]=(LevelLabel="5-Hephaestus",Mode=9)
	PresenceModes[9]=(LevelLabel="5-Ryan",Mode=10)
	PresenceModes[10]=(LevelLabel="6-Resi",Mode=11)
	PresenceModes[11]=(LevelLabel="6-Slums",Mode=12)
	PresenceModes[12]=(LevelLabel="7-Science",Mode=13)
	PresenceModes[13]=(LevelLabel="7-Gauntlet",Mode=14)
	PresenceModes[14]=(LevelLabel="7-BossFight",Mode=15)
	PresenceModes[15]=(LevelLabel="challengeroomcombat",Mode=16)
	PresenceModes[16]=(LevelLabel="challengeroomdecoy",Mode=17)
	PresenceModes[17]=(LevelLabel="challengeroomelectric",Mode=18)
	PresenceModes[18]=(LevelLabel="Museum",Mode=19)
}