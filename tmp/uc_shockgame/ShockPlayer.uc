class ShockPlayer extends ShockPawn implements IHandleMovieEvents, IObserveUseFocus, IEffectObserver
	native
	config(ShockPawn)
	hidecategories(DrawScale3D,DisplayAdvanced);

const NUM_RESEARCH_LEVELS = 5;
const kAimHighLimitDegrees = 70.0f;
const kAimLowLimitDegrees = 62.0f;
const kAimLeftLimitDegrees = 54.0f;
const kAimRightLimitDegrees = 77.0f;
const kMinNextTurnEffectEventTriggerYawDelta = 80;
const kMaxNextTurnEffectEventTriggerYawDelta = 100;
const kTriggerGatherStepFullVelocityRampDownTime = 0.25;

enum EPhotoGrade
{
	GRADE_F,                        // 0
	GRADE_D,                        // 1
	GRADE_C,                        // 2
	GRADE_B,                        // 3
	GRADE_A,                        // 4
	GRADE_S                         // 5
};

enum ELeanState
{
	kLeanStateNone,                 // 0
	kLeanStateLeft,                 // 1
	kLeanStateRight                 // 2
};

struct native atomic PhotoScoreGradeMapping
{
	var ShockPlayer.EPhotoGrade Grade;
	var int Score;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic PhotoScore
{
	var int Centering;
	var int Size;
	var int Pose;
	var int DeadPenalty;
	var int RepeatPenalty;
	var int NumSubjects;
	var int TotalScore;
	var TrainingMessageManager.EPhotoRejectReason RejectReason;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic PhotoGroupScore
{
	var travel name Label;
	var travel name ResistanceSetName;
	var travel int BaseScore;
	var travel int BonusScore;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic ResearchDamageType
{
	var DamageStimuliSet.DamageStimulusType Type;
	var localized string FriendlyName;
};

struct native atomic ConfigResearchData
{
	var name ResearchName;
	var localized string FriendlyName;
	var int MaxScore;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic ResearchTrack
{
	var travel name ResearchName;
	var localized travel string FriendlyName;
	var travel name ResistanceSetName;
	var travel int CurrentScore;
	var travel int MaxScore;
	var travel bool LeveledUp;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic ResearchLevel
{
	var name ResearchName;
	var int LevelNumber;
	var int ScoreRequired;
	var localized string Text;
	var localized string ExtendedText;
	var Class<Item> AwardItemClass;
	var bool AwardResistanceInfo;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic JournalEntry
{
	var travel Class<QuestLog> LogClass;
	var travel bool Played;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

var config travel int BasePlasmidSlots;
var private config float MinimumCollisionVelocity;
var private config float CollisionDamageRatio;
var private travel string LastPlayerInputContext;
var private travel Head Head;
var private travel PlasmidManager PlasmidManager;
var private travel InventoryManager InventoryManager;
var private travel QuestManager QuestManager;
var private travel InGameManualManager InGameManualManager;
var travel array< Class<Item> > ItemFiltrationList;
var travel bool disableInventoryWarnings;
var bool ShowPlayerPosition;
var private ShockMachine CurrentStation;
var travel bool bHasHacked;
var config float HackingCostModifierF;
var config float HackingCostModifierG;
var config float HackingCostModifierA;
var config float HackingCostModifierS;
var config float HackingCostModifierC;
var config float HackingCostModifierL;
var config float HackingCostModifierR;
var config float HackingCostModifierK;
var config float PCFlowSpeedModifier;
var config float PCInitialFlowSpeedModifier;
var config int MaxBotsWhenHackFailsDuringAlarm;
var array< Class > PreloadClasses;
var config name SanctuaryModelSocket;
var config Class<Actor> SanctuaryModelClass;
var travel Actor SanctuaryModel;
var config float MaximumSanctuaryMoveDistance;
var travel Vector SanctuaryLocation;
var travel bool bIsInSanctuary;
var private const bool bChameleonBloodActivated;
var private const float ChameleonBloodAvoidDetectionStartTime;
var private config float ChameleonBloodAvoidDetectionTime;
var private bool ChargingChargedBurst;
var private float NextChargedBurstReleaseTime;
var private config float ChargedBurstChargeTime;
var private config name ChargedBurstDamageStimuliSetName;
var private config float ChargedBurstInnerAttenuationRadius;
var private config float ChargedBurstOuterAttenuationRadius;
var config travel bool TeleportBeaconSet;
var private bool TeleportBeaconRequireCrouch;
var private config Vector TeleportBeaconLocation;
var private config Rotator TeleportBeaconRotation;
var private config float TeleportEffectTime;
var private config float TeleportFlyMaxDistance;
var private float TeleportViewSmoothVel;
var private config float TeleportViewMaxVel;
var private config float TeleportViewSmoothTime;
var array<Actor> TeleportPathList;
var private Vector TeleportStartLocation;
var transient float LastTimeTeleported;
var private config float TimeToConsiderHiddenAfterTeleporting;
var private config float EveBarPercentageToRestoreOnRessurection;
var private travel bool ShowGPSNodes;
var private config Vector GPSOffsetWidescreenPC;
var private config Vector GPSOffsetPC;
var private config float GPSArrowMaxVel;
var private config float GPSArrowSmoothTime;
var private config Vector GPSOffsetWidescreen;
var private config Vector GPSOffset;
var private config localized string GPSDestinationArrivedMessage;
var private config localized string GPSNoDestinationMessage;
var private config localized string GPSNotInLevelMessage;
var private config float GPSRePathFindInterval;
var private config float GPSCheckOnPathInterval;
var array<Actor> GPSPathList;
var private int GPSCurrentPathNodeIndex;
var private Vector GPSDestination;
var private Actor GPSDestinationActor;
var private bool GPSDestinationSet;
var private bool ForceSetGPSArrow;
var private bool InGPSDestinationZone;
var private bool RecomputeGPSPath;
var private float GPSArrowSmoothVel;
var private Rotator GPSArrowRotation;
var private float GPSRePathFindLevelTime;
var private float GPSCheckOnPathLevelTime;
var private travel GPSArrow GPSArrow;
var bool PathFindThroughLockedDoors;
var bool HudElementsDisabled;
var bool bReticleDisabled;
var private config travel int Credits;
var private config travel int MaxCredits;
var private travel int ADAM;
var private config travel float BioAmmo;
var private config travel float MaxBioAmmo;
var travel float UpgradedBioAmmoBonus;
var private config travel int BaseInventorySize;
var private config travel float FrozenFlowSpeedPercentBonus;
var const config float NearDeathHealthThreshold;
var const config float IneffectivePlasmidEffectTime;
var const config float MaxAllowCrouchAcceleration;
var private config float LowHealthInvulnerabilityTime;
var private config float LowHealthInvulnerabilityResetTime;
var private config float LowHealthInvulnerabilityHealthNeededToReset;
var private float LowHealthInvulnerabilityLevelTime;
var private float LowHealthInvulnerabilityLevelResetTime;
var private float LowHealthInvulnerabilityLevelHealthNeededToReset;
var private config float LowHealthRestorationTimeout;
var private config float LowHealthRestorationHealthCap;
var private config float LowHealthRestorationHealthPerSecond;
var travel array<JournalEntry> JournalEntries;
var private travel int UnplayedJournalEntryIndex;
var travel array<JournalEntry> QueuedJournalEntries;
var private Actor CurrentlyPlayingLog;
var private name CurrentlyPlayingLogType;
var private name CurrentlyPlayingLogName;
var config int RadioCountDisplayMax;
var private travel Class<UsableItem> ActiveUsableItem;
var private bool bUIMachineInteractionDirty;
var private config localized string NewPlasmidActiveTrackMessage;
var private config localized string NewPlasmidPhysicalTrackMessage;
var private config localized string NewPlasmidEngineeringTrackMessage;
var private config localized string NewPlasmidCombatTrackMessage;
var travel bool HasReplacedActiveTrack;
var travel bool HasReceivedActiveTrack;
var travel bool HasReceivedPhysicalTrack;
var travel bool HasReceivedEngineeringTrack;
var travel bool HasReceivedCombatTrack;
var travel bool HasUnlockedActiveTrack;
var travel bool HasUnlockedPhysicalTrack;
var travel bool HasUnlockedEngineeringTrack;
var travel bool HasUnlockedCombatTrack;
var private config localized string NewSlotActiveTrackMessage;
var private config localized string NewSlotPhysicalTrackMessage;
var private config localized string NewSlotEngineeringTrackMessage;
var private config localized string NewSlotCombatTrackMessage;
var private config localized string ComfirmActionNewPlasmidMessage;
var private config localized string ComfirmActionEmptySlotMessage;
var private config localized string ComfirmActionNoPlasmidsMessage;
var private config localized string PlasmiNowUIHighlightNewPlasmidMessage;
var private config localized string PlasmiNowUIHighlightNewSlotMessage;
var private config localized string PlasmiNowUIHighlightNewTonicMessage;
var private config localized string PlasmiNowUIHighlightNewTonicSlotMessage;
var private config localized string ReplacedActivePlasmidMessage;
var private config localized string ResearchBonusText;
var private config localized string HackingResultOverloadedText;
var private config localized string HackingResultShortCircuitText;
var private config localized string HackingResultAlarmText;
var private config localized string HackingResultNoHackAttemptedText;
var private config localized string HackingResultSuccessText;
var private config localized string GoldMedalInChallengeRoomSuccessText;
var private config localized string GoldMedalInChallengeRoomFailureText;
var private const config float ResurrectionDelay;
var private transient BaseResurrectionStation ClosestResurrectionStation;
var private bool ShowHandsWhenResurrected;
var travel array<float> LastTipDisplayTimes;
var travel array<TrainingMessageManager.QueuePriority> TipsQueuePriority;
var travel array<float> LastMessageDisplayTimes;
var travel array<TrainingScript> TrainingScripts;
var travel array<Fact> PersistentFacts;
var travel array<PersistentDifficultyStat> PersistentDifficultyStats;
var travel float GameplayTime;
var bool bWantsToLeanLeft;
var bool bWantsToLeanRight;
var const ShockPlayer.ELeanState DesiredLeanState;
var const ShockPlayer.ELeanState LeanState;
var const int LeanLockedYaw;
var const float LeanAlpha;
var private Vector LeanPositionOffset;
var private Rotator LeanRotationOffset;
var private float LastLeanOffsetsUpdateTime;
var private config float LeanTransitionDuration;
var private config float LeanHorizontalDistance;
var private config float LeanVerticalDistance;
var private config float LeanRollDegrees;
var private config float LeanBezierPt1X;
var private config float LeanBezierPt1Y;
var private config float LeanBezierPt2X;
var private config float LeanBezierPt2Y;
var private bool IsDisplayingPhoto;
var private PhotoScore CurrentPhotoScore;
var private name CurrentPhotoLabel;
var private CameraPhoto CurrentPhoto;
var array<CameraPhoto> SavedPhotos;
var IPhotographTarget CurrentPhotoSubject;
var private int TestDisplayPhotoIndex;
var config array<PhotoScoreGradeMapping> PhotoScoreToGradeMapping;
var private config localized string NoPhotoSubjectOnScreenMessage;
var private config localized string NoPhotoSubjectInFrameMessage;
var private config localized string NoEnemyPhotoSubjectMessage;
var private config localized string LowScoreMessage;
var private config localized string ResearchCompleteMessage;
var private CameraPhoto ResearchStationPhoto;
var private int ResearchStationPhotoX;
var private int ResearchStationPhotoY;
var private int ResearchStationPhotoWidth;
var private int ResearchStationPhotoHeight;
var travel array<PhotoGroupScore> UnresearchedPhotos;
var /*0x00000000-0x01000000*/ config localized array<localized ConfigResearchData> ResearchTrackData;
var config localized array<localized ResearchLevel> ResearchLevels;
var config localized array<localized ResearchDamageType> ResearchDamageTypes;
var private config localized string ResearchResistanceToString;
var private config localized string ResearchVulnerableToString;
var travel array<ResearchTrack> ResearchTracks;
var travel array< Class<CraftingFormula> > CraftingFormulae;
var private travel Holdable LastWeapon;
var private travel Class<Ability> LastAbility;
var private travel Actor TargetIndicator;
var travel Vector TargetIndicatorOffset;
var Vector LastTargetLocation;
var bool TargetLocationIsValid;
var Timer TakeAllTimer;
var private int TakeAllIndex;
var private config float TakeAllDelayTime;
var array<IWatchForPlayerAttacks> PlayerAttacksNotificationList;
var BaseShockAI EscortedGatherer;
var private transient Vector PreHavokUpdateLocation;
var private config float CollisionLatency;
var private transient float LastCollisionTime;
var private config float MaximumCrouchingDepth;
var private config float MaximumJumpingDepth;
var private config float MaximumLeaningDepth;
var BaseShockAI CurrentExorcismTarget;
var ICanBeHarvested CurrentHarvestTarget;
var travel bool HasGathererTool;
var transient BioAmmoHypoBase CurrentHypo;
var private const float CurrentIlluminationLevel;
var private const float LastIlluminationCalcTime;
var transient int LastTurnEffectEventTriggerYaw;
var transient int NextTurnEffectEventTriggerYawDelta;
var transient float LastFullVelocityTimeForGatherStep;
var config array<name> BathysphereManagerNames;
var private BathysphereManager BathysphereManager;
var private bool BathysphereUIOpen;
var private int BathysphereSelectedIndex;
var const travel array<BathysphereManager> BathysphereManagers;
var config bool UnlockDownloadContentBathysphereHub;
var config name DownloadContentBathysphereHubMapName;
var travel AwardAchievementsManager AwardAchievementsManager;
var name LastInfoPanelTab;
var travel UserSettings.EGameDifficulty CurrentDifficultySetting;
var private travel string HACKPlayerInventoryDataString;
var private travel bool UseGamePlusData;
var private travel bool UsingGamePlusData;
var bool bChallengeTimerIsStarted;
var private float ChallengeTimerLevelStartTime;
var private float ChallengeTimerEndTime;
var bool DontRetriggerWeaponModEffectEvents;
var private travel Class<Ability> ActiveAbility;
var travel array< Class<Ability> > AvailableAbilities;
var config array< Class<Ability> > PossibleAbilities;
var private native const noexport TMap_Padding AbilityMap;

// Export UShockPlayer::execGetInfernoID(FFrame&, void* const)
native function int GetInfernoID();

function SetInfernoID(int id)
{
	//native.id;	
	@NULL
}

// Export UShockPlayer::execNotifyAudioSubsystemLogBegan(FFrame&, void* const)
private native final function NotifyAudioSubsystemLogBegan();

// Export UShockPlayer::execNotifyAudioSubsystemLogEnded(FFrame&, void* const)
private native final function NotifyAudioSubsystemLogEnded();

// Export UShockPlayer::execShouldKickToEntry(FFrame&, void* const)
native final function bool ShouldKickToEntry();

function Material GetCopyOfPhoto(name Label)
{
	//native.Label;	
	@NULL
}

function AddPhotoScore(out array<PhotoGroupScore> GroupScores, name Label, int Score, int BonusScore, name ResistanceSetName)
{
	local int i;
	local PhotoGroupScore GroupScore;

	i = 0;
	// End:0xC3
	if(__NFUN_150__(i, GroupScores.Length))
	{
		// End:0xB5
		if(__NFUN_254__(Label, GroupScores[i].Label))
		{
			__NFUN_161__(GroupScores[i].BaseScore, Score);
			__NFUN_161__(GroupScores[i].BonusScore, BonusScore);
			return;
			__NFUN_165__(i);
			// [Loop Continue]
			goto J0x0B;
			GroupScore.Label = Label;
			GroupScore.BaseScore = Score;
			GroupScore.BonusScore = BonusScore;
			GroupScore.ResistanceSetName = ResistanceSetName;
		}
	}
	GroupScores[GroupScores.Length] = GroupScore;
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function ResetPhotoDisplayUI()
{
	local int PlasmidBonusPercent;
	local float PlasmidBonus;
	local int i, curLevel, curLevelIndex, nextLevelIndex, curLevelRequiredPoints;

	local float pointsRange;
	local int curPercentage, newPercentage;
	local ShockPlayer.EPhotoGrade photoGrade;
	local bool isSplicerPhoto;

	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("ClearPhotoInfo");
	Level.GetFlashGUIController().HideMovie('HUD');
	i = 0;
	// End:0xE0F
	if(__NFUN_150__(i, ResearchTracks.Length))
	{
		// End:0xE01
		if(__NFUN_254__(CurrentPhotoLabel, ResearchTracks[i].ResearchName))
		{
			Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodString("DisplayPhotoInfo", ICanBeFocused(CurrentPhotoSubject).GetFocusDisplayName());
			Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodStringString("AddPhotoInfo", "Track", ResearchTracks[i].FriendlyName);
			Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodString("AttachTrackIcon", string(ResearchTracks[i].ResearchName));
			Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodInt("AddPhotoBarMin", 0);
			Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodInt("AddPhotoBarMax", 100);
			isSplicerPhoto = __NFUN_132__(__NFUN_132__(__NFUN_132__(__NFUN_132__(__NFUN_254__(CurrentPhotoLabel, 'MeleeThug'), __NFUN_254__(CurrentPhotoLabel, 'RangedAggressor')), __NFUN_254__(CurrentPhotoLabel, 'Grenadier')), __NFUN_254__(CurrentPhotoLabel, 'CeilingCrawler')), __NFUN_254__(CurrentPhotoLabel, 'Assassin'));
			curLevel = GetResearchLevelForScore(ResearchTracks[i].ResearchName, ResearchTracks[i].CurrentScore);
			// End:0x42E
			if(__NFUN_151__(GetResearchLevelForScore(ResearchTracks[i].ResearchName, __NFUN_146__(ResearchTracks[i].CurrentScore, CurrentPhotoScore.TotalScore)), curLevel))
			{
				TriggerEffectEvent('NewLevelAchieved');
				Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodStringInt("AddPhotoInfoBar", Class'ShockGame.FlashStrings'.default.Center, CurrentPhotoScore.Centering);
				Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodStringInt("AddPhotoInfoBar", Class'ShockGame.FlashStrings'.default.Size, CurrentPhotoScore.Size);
				// End:0x5BE
				if(__NFUN_151__(CurrentPhotoScore.Pose, 0))
				{
					Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodStringString("AddPhotoInfo", Class'ShockGame.FlashStrings'.default.Bonus, Class'ShockGame.FlashStrings'.default.ActionBonusMessage);
				}
				// End:0x654
				if(__NFUN_151__(CurrentPhotoScore.DeadPenalty, 0))
				{
					Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodStringString("AddPhotoInfo", Class'ShockGame.FlashStrings'.default.DeadPenalty, Class'ShockGame.FlashStrings'.default.DeadPenaltyMessage);
					// End:0x6EA
					if(__NFUN_151__(CurrentPhotoScore.RepeatPenalty, 0))
					{
						Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodStringString("AddPhotoInfo", Class'ShockGame.FlashStrings'.default.RepeatPenalty, Class'ShockGame.FlashStrings'.default.RepeatPenaltyMessage);
						// End:0x780
						if(__NFUN_151__(CurrentPhotoScore.NumSubjects, 1))
						{
							Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodStringString("AddPhotoInfo", Class'ShockGame.FlashStrings'.default.Bonus, Class'ShockGame.FlashStrings'.default.Subjects);
						}
						PlasmidBonus = ModifyStat('EyeForDetailScoring_PercentBonus', 1.0000000);
						// End:0x862
						if(__NFUN_177__(PlasmidBonus, 1.0000000))
						{
							PlasmidBonus = __NFUN_174__(__NFUN_171__(__NFUN_175__(PlasmidBonus, 1.0000000), 100.0000000), 0.5000000);
							PlasmidBonusPercent = int(PlasmidBonus);
							Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodStringString("AddPhotoInfo", Class'ShockGame.FlashStrings'.default.PlasmidBonus, __NFUN_112__(string(PlasmidBonusPercent), "%"));
						}
						photoGrade = GetGradeFromScore(CurrentPhotoScore.TotalScore);
						ShockPlayerController(Controller).GetPlayerStatsManager().GradePhoto(self, photoGrade, isSplicerPhoto);
						switch(photoGrade)
						{
							// End:0x8E2
							case 5:
								// End:0x951
								case 4:
									Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodStringString("AddPhotoInfo", "Grade", "A");
								}/* !MISMATCHING REMOVE, tried If got Type:Case Position:0x6DE! */
								TriggerEffectEvent('GreatPhotoTaken');
								// End:0xB10
								break;
								// End:0x9C0
								case 3:
									Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodStringString("AddPhotoInfo", "Grade", "B");
								}/* !MISMATCHING REMOVE, tried If got Type:Case Position:0x745! */
								TriggerEffectEvent('NormalPhotoTaken');
								// End:0xB10
								break;
								// End:0xA2F
								case 2:
									Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodStringString("AddPhotoInfo", "Grade", "C");
									TriggerEffectEvent('NormalPhotoTaken');
									// End:0xB10
									break;
									// End:0xA9E
									case 1:
										Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodStringString("AddPhotoInfo", "Grade", "D");
									}/* !MISMATCHING REMOVE, tried If got Type:Case Position:0x813! */
									TriggerEffectEvent('NormalPhotoTaken');
									// End:0xB10
									break;
									// End:0xB0D
									case 0:
										Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodStringString("AddPhotoInfo", "Grade", "F");
										TriggerEffectEvent('NormalPhotoTaken');
										// End:0xB10
										break;
										// End:0xFFFF
										default:
											break;/* Tried to find Switch scope, found Case instead */
									curLevelRequiredPoints = 0;
									// End:0xB7E
									if(__NFUN_151__(curLevel, 0))
									{
										curLevelIndex = GetResearchLevelIndex(CurrentPhotoLabel, curLevel);
										curLevelRequiredPoints = ResearchLevels[curLevelIndex].ScoreRequired;
										nextLevelIndex = GetResearchLevelIndex(CurrentPhotoLabel, __NFUN_146__(curLevel, 1));
										pointsRange = float(__NFUN_147__(ResearchLevels[nextLevelIndex].ScoreRequired, curLevelRequiredPoints));/* !MISMATCHING REMOVE, tried Case got Type:If Position:0x8EB! */
									curPercentage = int(__NFUN_171__(__NFUN_172__(float(__NFUN_147__(ResearchTracks[i].CurrentScore, curLevelRequiredPoints)), pointsRange), 100.0000000));
									newPercentage = int(__NFUN_171__(__NFUN_172__(float(__NFUN_147__(__NFUN_146__(ResearchTracks[i].CurrentScore, CurrentPhotoScore.TotalScore), curLevelRequiredPoints)), pointsRange), 100.0000000));
								// End:0xCB8
								if(__NFUN_151__(newPercentage, 100))
								{
									newPercentage = 100;
									Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodInt("SetOldPhotoBarScore", curPercentage);/* !MISMATCHING REMOVE, tried Case got Type:If Position:0x9E0! */
								Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodInt("SetCurrentPhotoBarScore", newPercentage);
								Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("DisplayPhotoInfo");
							Level.GetFlashGUIController().UnhideMovie('HUD');
							TriggerEffectEvent('PhotoTaken');/* !MISMATCHING REMOVE, tried Case got Type:Switch Position:0x6D2! */
					}/* !MISMATCHING REMOVE, tried Switch got Type:If Position:0x4E8! */
					return;
					__NFUN_165__(i);
					// [Loop Continue]
					goto J0x85;
					Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodString("DisplayPhotoInfo", ICanBeFocused(CurrentPhotoSubject).GetFocusDisplayName());
					Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("HidePhotoGrading");
				}
				Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodStringString("AddPhotoInfo", "Track", ICanBeFocused(CurrentPhotoSubject).GetFocusDisplayName());
				Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodString("AttachTrackIcon", string(CurrentPhotoLabel));
				Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodInt("AddPhotoBarMin", 0);
				Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodInt("AddPhotoBarMax", 100);
			}
			photoGrade = GetGradeFromScore(CurrentPhotoScore.TotalScore);
			ShockPlayerController(Controller).GetPlayerStatsManager().GradePhoto(self, photoGrade, isSplicerPhoto);
			switch(photoGrade)
			{
				// End:0x10AF
				case 5:
					// End:0x111E
					case 4:
						Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodStringString("AddPhotoInfo", "Grade", "A");
						TriggerEffectEvent('GreatPhotoTaken');
						// End:0x12DD
						break;
						// End:0x118D
						case 3:
							Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodStringString("AddPhotoInfo", "Grade", "B");
						}/* !MISMATCHING REMOVE, tried If got Type:Case Position:0xDBE! */
					}/* !MISMATCHING REMOVE, tried If got Type:Case Position:0xD57! */
					TriggerEffectEvent('NormalPhotoTaken');
					// End:0x12DD
					break;
					// End:0x11FC
					case 2:
						Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodStringString("AddPhotoInfo", "Grade", "C");
						TriggerEffectEvent('NormalPhotoTaken');
						// End:0x12DD
						break;
						// End:0x126B
						case 1:
							Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodStringString("AddPhotoInfo", "Grade", "D");
							TriggerEffectEvent('NormalPhotoTaken');
							// End:0x12DD
							break;
							// End:0x12DA
							case 0:
								Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodStringString("AddPhotoInfo", "Grade", "F");
								TriggerEffectEvent('NormalPhotoTaken');
								// End:0x12DD
								break;
								// End:0xFFFF
								default:
									Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodInt("SetOldPhotoBarScore", 0);
									Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodInt("SetCurrentPhotoBarScore", CurrentPhotoScore.TotalScore);
									Level.GetFlashGUIController().UnhideMovie('HUD');
									TriggerEffectEvent('PhotoTaken');
									return;
									break;
							}/* !MISMATCHING REMOVE, tried Switch got Type:Case Position:0xEF3! */
							@NULL
							Item
							ShockPawn
							@NULL
	// Failed to format remaining nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 724
	// 1 & Type:Case Position:0x10AF
}

function OnCameraClick(PhotoScore Score, IPhotographTarget Subject)
{
	local ShockPawn SubjectPawn;
	local int OriginalTotalScore;

	CurrentPhotoScore = Score;
	CurrentPhotoSubject = Subject;
	// End:0x59
	if(__NFUN_119__(Subject, none))
	{
		CurrentPhotoLabel = Subject.GetPhotographLabel();
		goto J0x6C;
		CurrentPhotoLabel = 'None';
		// End:0x402
		if(__NFUN_154__(int(CurrentPhotoScore.RejectReason), int(0)))
		{
		}
		OriginalTotalScore = CurrentPhotoScore.TotalScore;
		__NFUN_159__(CurrentPhotoScore.TotalScore, ModifyStat('EyeForDetailScoring_PercentBonus', 1.0000000));
		SubjectPawn = ShockPawn(Subject);
		// End:0x16A
		if(__NFUN_114__(SubjectPawn, none))
		{
			AddPhotoScore(UnresearchedPhotos, CurrentPhotoLabel, OriginalTotalScore, __NFUN_147__(CurrentPhotoScore.TotalScore, OriginalTotalScore), 'None');
			goto J0x1CB;
			AddPhotoScore(UnresearchedPhotos, CurrentPhotoLabel, OriginalTotalScore, __NFUN_147__(CurrentPhotoScore.TotalScore, OriginalTotalScore), SubjectPawn.GetResistanceSetName());
			log(,, "##################################################");
		}
		log(,, __NFUN_112__("Centering:", string(CurrentPhotoScore.Centering)));
		log(,, __NFUN_112__("Size:", string(CurrentPhotoScore.Size)));
		log(,, __NFUN_112__("Pose:", string(CurrentPhotoScore.Pose)));
		log(,, __NFUN_112__("Dead Penalty:-", string(CurrentPhotoScore.DeadPenalty)));
		log(,, __NFUN_112__("Repeat Penalty:-", string(CurrentPhotoScore.RepeatPenalty)));
		log(,, __NFUN_112__("Number of Subjects:", string(CurrentPhotoScore.NumSubjects)));
		log(,, __NFUN_112__("Subject:", string(Subject)));
		log(,, "--------------------------------------------------");
		log(,, __NFUN_112__("Total after bonus:", string(CurrentPhotoScore.TotalScore)));
		log(,, "##################################################");
		ShockPlayerController(Controller).GetPlayerStatsManager().PictureTaken(CurrentPhotoScore.RejectReason);
		IsDisplayingPhoto = true;
		// End:0x48E
		if(__NFUN_155__(int(CurrentPhotoScore.RejectReason), int(0)))
		{
			TriggerEffectEvent('PhotoRejected');
			switch(CurrentPhotoScore.RejectReason)
			{
				// End:0x4EE
				case 2:
					ShockPlayerController(Controller).ClientMessage(NoEnemyPhotoSubjectMessage, 'Important');
					FinishedPhotoDisplay();
					// End:0x634
					break;
					// End:0x532
					case 1:
						ShockPlayerController(Controller).ClientMessage(NoPhotoSubjectInFrameMessage, 'Important');
						FinishedPhotoDisplay();
						// End:0x634
						break;
						// End:0x576
						case 4:
						}/* !MISMATCHING REMOVE, tried If got Type:Case Position:0x3FE! */
						ShockPlayerController(Controller).ClientMessage(LowScoreMessage, 'Important');
						FinishedPhotoDisplay();
						// End:0x634
						break;
						// End:0x5BA
						case 3:
							ShockPlayerController(Controller).ClientMessage(NoPhotoSubjectOnScreenMessage, 'Important');
							FinishedPhotoDisplay();
							// End:0x634
							break;
							// End:0x5FE
							case 5:
								ShockPlayerController(Controller).ClientMessage(ResearchCompleteMessage, 'Important');
							}/* !MISMATCHING REMOVE, tried If got Type:Case Position:0x46E! */
							FinishedPhotoDisplay();
							// End:0x634
							break;
							// End:0x631
							case 0:
								ResearchCamera(GetActiveHoldable()).UseFilm();
								ResetPhotoDisplayUI();
								// End:0x634
								break;
								// End:0xFFFF
								default:
									return;
									break;
							}/* !MISMATCHING REMOVE, tried Switch got Type:Case Position:0x4A6! */
							@NULL
							Item
							stop;
							default.@NULL
	// Failed to format remaining nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 724
	// 1 & Type:Case Position:0x4EE
}

function ShockPlayer.EPhotoGrade GetGradeFromScore(int Score)
{
	local ShockPlayer.EPhotoGrade HighestGrade;
	local int i;

	HighestGrade = 0;
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xD5
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xC7
	/*@Error*/
	HighestGrade = PhotoScoreToGradeMapping[i].Grade;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x17;
	return HighestGrade;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function int GetResearchLevelForScore(name ResearchName, int Score)
{
	local int Level, i;

	Level = 0;
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xDB
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xCD
	/*@Error*/
	Level = __NFUN_250__(Level, ResearchLevels[i].LevelNumber);
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x16;
	return Level;
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function int GetResearchLevelIndex(name ResearchName, int Level)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA1
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x93
	/*@Error*/
	return i;
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x0B;
	return -1;
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function int GetResearchLevelForTrack(name ResearchName)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x9B
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x8D
	/*@Error*/
	return GetResearchLevelForScore(ResearchName, ResearchTracks[i].CurrentScore);
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x0B;
	return 0;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function int GetResearchScoreForTrack(name ResearchName)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x88
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x7A
	/*@Error*/
	return ResearchTracks[i].CurrentScore;
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x0B;
	return 0;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function ShowPhotoLevelUpBox(name ResistanceSetName, string ResearchLevelText)
{
	//native.ResistanceSetName;
	//native.ResearchLevelText;	
	@NULL
	@NULL
}

function ShowWrenchHitBox()
{
	local Wrench Wrench;

	Wrench = Wrench(GetHoldableByClassName('Wrench'));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x66
	/*@Error*/
	Wrench.ShowHitBox = __NFUN_129__(Wrench.ShowHitBox);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function testDisplayPhoto(int Index)
{
	TestDisplayPhotoIndex = Index;
	return;
	@NULL
	Item
}

function testAddResearchPoints(name ResearchName, int Score)
{
	local int i;
	local PhotoGroupScore GroupScore;

	// End:0x93
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'testAddResearchPoints', but that command is disabled in the CENSORED version.");
		goto J0x201;
		log('Testing', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::testAddResearchPoints( "), string(ResearchName)), " )"));
	}
	i = 0;
	// End:0x197
	if(__NFUN_150__(i, ResearchTracks.Length))
	{
		J0xE1:

		// End:0x189 [Loop If]
		if(__NFUN_254__(ResearchName, ResearchTracks[i].ResearchName))
		{
			GroupScore.Label = ResearchName;
			GroupScore.BaseScore = Score;
			ResearchPhotoGroup(GroupScore, false);
			return;
			__NFUN_165__(i);
			// [Loop Continue]
			goto J0xE1;
			log('Testing', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::testAddResearchPoints failed since "), string(ResearchName)), " isn't a valid research track"));
		}
	}
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function bool IsResearchComplete(name TrackName)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xC3
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB5
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB3
	/*@Error*/
	return false;
	goto J0xB5;
	return true;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return false;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function bool IsAllResearchComplete()
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x8C
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x7E
	/*@Error*/
	return false;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return true;
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool IsResearchingAll()
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5D
	/*@Error*/
	// End:0x4F
	if(__NFUN_154__(ResearchTracks[i].CurrentScore, 0))
	{
		return false;
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x0B;
		return true;
		return;
		@NULL
		Item
		Item
	}
	@NULL
}

function ResearchPhotoGroup(PhotoGroupScore GroupScore, bool AllowAwardingAchievements)
{
	local int i, OldLevel, newLevel, LevelIndex;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x41B
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x40D
	/*@Error*/
	OldLevel = GetResearchLevelForScore(ResearchTracks[i].ResearchName, ResearchTracks[i].CurrentScore);
	__NFUN_161__(ResearchTracks[i].CurrentScore, GroupScore.BaseScore);
	__NFUN_161__(ResearchTracks[i].CurrentScore, GroupScore.BonusScore);
	newLevel = GetResearchLevelForScore(ResearchTracks[i].ResearchName, ResearchTracks[i].CurrentScore);
	ResearchTracks[i].LeveledUp = __NFUN_151__(newLevel, OldLevel);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x36F
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x36F
	/*@Error*/
	__NFUN_163__(OldLevel);
	TriggerEffectEvent('ResearchLevelUp',,,,,,,, string(__NFUN_112__(__NFUN_112__(string(GroupScore.Label), "_"), string(OldLevel))));
	LevelIndex = GetResearchLevelIndex(ResearchTracks[i].ResearchName, OldLevel);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x31A
	/*@Error*/
	GiveItemClass(1, ResearchLevels[LevelIndex].AwardItemClass);
	goto J0x36C;
	ShowPhotoLevelUpBox(ResearchTracks[i].ResistanceSetName, ResearchLevels[LevelIndex].Text);
	// [Loop Continue]
	goto J0x200;
	ShockPlayerController(Controller).GetPlayerStatsManager().ResearchedTrack(self, ResearchTracks[i].ResearchName, AllowAwardingAchievements);
	ResearchTracks[i].ResistanceSetName = GroupScore.ResistanceSetName;
	return;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	stop;
	return @NULL;
}

function ResearchPhotos()
{
	local int i;

	i = 0;
	// End:0x58
	if(__NFUN_150__(i, ResearchTracks.Length))
	{
		ResearchTracks[i].LeveledUp = false;
		__NFUN_165__(i);
		// [Loop Continue]
		goto J0x0B;
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xA7
		/*@Error*/
		ResearchPhotoGroup(UnresearchedPhotos[i], true);
	}
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x63;
	UnresearchedPhotos.Length = 0;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function BathysphereManager GetBathysphereManager(name BathyspheresName)
{
	//native.BathyspheresName;	
	@NULL
}

// Export UShockPlayer::execDumpBathysphereManagers(FFrame&, void* const)
native function DumpBathysphereManagers();

function UnlockBathysphereDestination(name BathyspheresName, name MapName)
{
	BathysphereManager = GetBathysphereManager(BathyspheresName);
	BathysphereManager.UnlockDestination(MapName);
	return;
	@NULL
	Item
	Item
	@NULL
}

function testUnlockBathysphereDestination(name MapName)
{
	// End:0x9E
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'testUnlockBathysphereDestination', but that command is disabled in the CENSORED version.");
		goto J0xDB;
		BathysphereManager = GetBathysphereManager('BioshockBathyspheres');
	}
	BathysphereManager.UnlockDestination(MapName);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function UnhideManualTopicWithoutShowingHelpTagInfo(name TopicName)
{
	InGameManualManager.UnhideManualTopic(TopicName);
	return;
	@NULL
	Item
}

function ShowAllManualTopics()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x26
	/*@Error*/
	InGameManualManager.ShowAllManualTopics();
	return;
	@NULL
	Item
}

function UnhideManualTopic(name TopicName)
{
	local string DisplayText;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x12F
	/*@Error*/
	// End:0x77
	if(Level.GetFlashGUIController().GetUseXBoxController())
	{
		DisplayText = ShockPlayerController(Controller).WhatIsThisText;
		goto J0xA0;
		DisplayText = ShockPlayerController(Controller).PCWhatIsThisText;
		Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodString("ShowHelpTagInfoNow", Level.GetFlashGUIController().SubstituteKeyMappingTags(DisplayText, "ShowContextHelp"));
	}
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function ShowBathysphereUI(name BathyspheresName)
{
	local int i, j, lastMap;
	local bool bButtonProcessed;

	BathysphereManager = GetBathysphereManager(BathyspheresName);
	Level.GetFlashGUIController().PlayMovie('Bathysphere');
	// End:0x78
	if(UnlockDownloadContentBathysphereHub)
	{
		BathysphereManager.UnlockDestination(DownloadContentBathysphereHubMapName);
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x390
		/*@Error*/
	}
	bButtonProcessed = false;
	j = 0;
	// End:0x2EF
	if(__NFUN_150__(j, BathysphereManager.UnlockedDestinations.Length))
	{
		// End:0x2E1
		if(__NFUN_154__(BathysphereManager.UnlockedDestinations[j], i))
		{
			// End:0x214
			if(__NFUN_254__(BathysphereManager.Destinations[i].MapName, Outer.Name))
			{
				Level.GetFlashGUIController().GetPlayingMovie('Bathysphere').CallMethodStringString("AddDisabledButton", string(BathysphereManager.Destinations[i].MapName), BathysphereManager.Destinations[i].Title);
				goto J0x2BF;
				Level.GetFlashGUIController().GetPlayingMovie('Bathysphere').CallMethodStringString("AddButton", string(BathysphereManager.Destinations[i].MapName), BathysphereManager.Destinations[i].Title);
				bButtonProcessed = true;
				lastMap = i;
				goto J0x2EF;
				__NFUN_163__(j);
				// [Loop Continue]
				goto J0xBF;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x382
				/*@Error*/
			}
			Level.GetFlashGUIController().GetPlayingMovie('Bathysphere').CallMethodStringString("AddDisabledButton", string(BathysphereManager.Destinations[i].MapName), "");
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x83;
			Level.GetFlashGUIController().GetPlayingMovie('Bathysphere').CallMethodString("SelectMap", string(BathysphereManager.Destinations[lastMap].MapName));
		}
		return;
	}
	@NULL
	Item
	default.Item
	@NULL
}

function BathysphereDestinationUp()
{
	Level.GetFlashGUIController().GetPlayingMovie('Bathysphere').CallMethodVoid("UIHighlightUp");
	return;
	@NULL
	Item
}

function BathysphereDestinationDown()
{
	Level.GetFlashGUIController().GetPlayingMovie('Bathysphere').CallMethodVoid("UIHighlightDown");
	return;
	@NULL
	Item
}

function SelectBathysphereDestination(name DestinationName)
{
	local string AdditionalOptions;
	local BathysphereEntry Entry;
	local int i;

	i = 0;
	// End:0xD8
	if(__NFUN_150__(i, BathysphereManager.UnlockedDestinations.Length))
	{
		// End:0xCA
		if(__NFUN_254__(BathysphereManager.Destinations[BathysphereManager.UnlockedDestinations[i]].MapName, DestinationName))
		{
			Entry = BathysphereManager.Destinations[BathysphereManager.UnlockedDestinations[i]];
			goto J0xD8;
			__NFUN_165__(i);
			// [Loop Continue]
			goto J0x0B;
			AssertWithDescription(__NFUN_255__(Entry.MapName, 'None'), __NFUN_112__("Couldn't find a valid Bathysphere Destination entry for ", string(DestinationName)));
		}
	}
	Level.GetFlashGUIController().StopMovie('Bathysphere');
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1CF
	/*@Error*/
	AdditionalOptions = __NFUN_112__("#", string(Entry.StartLocationLabel));
	AdditionalOptions = __NFUN_112__(AdditionalOptions, "?TRAVEL");
	Level.ServerTravel(__NFUN_112__(string(Entry.MapName), AdditionalOptions));
	return;
	@NULL
	Item
	default.Item
	@NULL
}

exec function CancelSelectBathysphereDestination()
{
	return;
}

function DrawBathysphereUI(Canvas Canvas)
{
	local int i, CurX, CurY;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x244
	/*@Error*/
	Canvas.Font = Canvas.DefaultFont;
	Canvas.DrawColor.R = byte(255);
	Canvas.DrawColor.G = byte(255);
	Canvas.DrawColor.B = byte(255);
	Canvas.DrawColor.A = byte(255);
	CurX = 200;
	CurY = 200;
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x244
	/*@Error*/
	Canvas.SetPos(float(CurX), float(CurY));
	Canvas.__NFUN_465__(BathysphereManager.Destinations[BathysphereManager.UnlockedDestinations[i]].Title);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x229
	/*@Error*/
	Canvas.SetPos(float(__NFUN_147__(CurX, 10)), float(CurY));
	Canvas.DrawBox(Canvas, 10.0000000, 10.0000000);
	__NFUN_161__(CurY, 20);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x10D;
	return;
	@NULL
	Item
	Item
	@NULL
}

function DisplayPhotoLight(Canvas Canvas)
{
	local ShockGameInfo ShockInfo;
	local DamageFactory Factory;
	local PhotoScore PhotoScore;

	ShockInfo = ShockGameInfo(Level.Game);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x358
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x358
	/*@Error*/
	Factory = ShockInfo.GetDamageFactory(Weapon(static.GetActiveHoldable()).GetCurrentAmmoSelection().default.DamageModel);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x358
	/*@Error*/
	CurrentPhotoSubject = none;
	CameraDamageFactory(Factory).CalculatePhoto(self, PhotoScore, CurrentPhotoSubject);
	// End:0x1EF
	if(__NFUN_152__(PhotoScore.TotalScore, 20))
	{
		Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodString("UpdatePhotoIndicator", "Ugly");
		goto J0x2C2;
		// End:0x26A
		if(__NFUN_152__(PhotoScore.TotalScore, 60))
		{
			Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodString("UpdatePhotoIndicator", "Bad");
			goto J0x2C2;
			Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodString("UpdatePhotoIndicator", "Good");
		}
		Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodInt("UpdatePhotoBar", PhotoScore.TotalScore);
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x358
	/*@Error*/
	CurrentPhotoSubject = none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function DisplayPhoto(Canvas Canvas)
{
	// End:0x78
	if(__NFUN_155__(TestDisplayPhotoIndex, -1))
	{
		Canvas.SetPos(100.0000000, 100.0000000);
		Canvas.__NFUN_466__(SavedPhotos[TestDisplayPhotoIndex], 256.0000000, 256.0000000, 0.0000000, 0.0000000, 256.0000000, 256.0000000);
		goto J0x111;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x111
		/*@Error*/
	}
	Canvas.SetPos(float(ResearchStationPhotoX), float(ResearchStationPhotoY));
	Canvas.__NFUN_466__(ResearchStationPhoto, float(ResearchStationPhotoWidth), float(ResearchStationPhotoHeight), 0.0000000, 0.0000000, 256.0000000, 256.0000000);
	return;
	@NULL
	Item
	Item
	@NULL
}

function FinishedPhotoDisplay()
{
	// End:0x11
	if(__NFUN_129__(IsDisplayingPhoto))
	{
		return;
		UnTriggerEffectEvent('PhotoTaken');
	}
	// End:0x60
	if(__NFUN_119__(Level.Pauser, none))
	{
		ShockPlayerController(Controller).Pause();
		Level.EffectsSystem.RemovePersistentContext('PauseByCamera');
	}
	ShockPlayerController(Controller).bDisablePause = false;
	Level.GetFlashGUIController().UnhideMovie('HUD');
	PlayerController(Controller).Player.Console.ConsoleCommand("POPINPUTCONTEXT PhotoGradingUIActive");
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("ClearPhotoInfo");
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("ShowAll");
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("ShowCameraOverlay");
	IsDisplayingPhoto = false;
	ResearchPhotos();
	ResearchCamera(GetActiveHoldable()).PhotoDisplayInProgress = false;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function GPSDebug(Canvas Canvas)
{
	//native.Canvas;	
	@NULL
}

function SetGPSDestination(Vector Vector)
{
	GPSDestination = Vector;
	GPSDestinationActor = none;
	GPSDestinationSet = true;
	ForceSetGPSArrow = true;
	InGPSDestinationZone = false;
	ShockPlayerController(Controller).GetPlayerStatsManager().GPSUsed();
	return;
	@NULL
	Item
	Item
	@NULL
}

function SetGPSDestinationActor(Actor Actor)
{
	GPSDestinationActor = Actor;
	GPSDestination = Actor.Location;
	GPSDestinationSet = true;
	ForceSetGPSArrow = true;
	InGPSDestinationZone = false;
	ShockPlayerController(Controller).GetPlayerStatsManager().GPSUsed();
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function ClearGPSDestination()
{
	GPSDestinationActor = none;
	GPSDestinationSet = false;
	ForceSetGPSArrow = false;
	GPSPathList.Length = 0;
	ShockPlayerController(Controller).GetPlayerStatsManager().GPSCleared();
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function ZoneChange(ZoneInfo NewZone)
{
	local int i, OldRegionIndex, NewRegionIndex;

	OldRegionIndex = -1;
	NewRegionIndex = -1;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x647
	/*@Error*/
	log('MapRegion', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Player changed from Zone '", string(Region.Zone.Name)), "' ("), string(Region.ZoneNumber)), ") to '"), string(NewZone)), "'"));
	// End:0x291
	if(__NFUN_132__(__NFUN_114__(Region.Zone, none), __NFUN_130__(__NFUN_119__(NewZone, none), __NFUN_255__(Region.Zone.MapUIRegion, NewZone.MapUIRegion))))
	{
		log('MapRegion', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Map UI Region change: Player went from Region [", string(Region.Zone.MapUIRegion)), "] to Region ["), string(NewZone.MapUIRegion)), "]"));
		dispatchMessage(Class'ShockGame.MessagePlayerChangedMapUIRegion'.static.Allocate(self)., construct_LevelInfoNameName(Level, Region.Zone.MapUIRegion, NewZone.MapUIRegion));
		ShockPlayerController(Controller).GetPlayerStatsManager().ChangedMapUIRegion(NewZone.MapUIRegion);
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x647
		/*@Error*/
		// End:0x465
		if(__NFUN_254__(Level.MapUIRegions[i].MapUIRegion, NewZone.MapUIRegion))
		{
			log('MapRegion', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Changing TimeLastVisited for NEW region from ", string(Level.MapUIRegions[i].TimeLastVisited)), " to "), string(Level.TimeSeconds)), " for MapUIRegion '"), string(NewZone.MapUIRegion)));
		}
		NewRegionIndex = i;
		Level.MapUIRegions[i].Revealed = true;
		Level.MapUIRegions[i].TimeLastVisited = Level.TimeSeconds;
		goto J0x616;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x616
		/*@Error*/
		log('MapRegion', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Changing TimeLastVisited for OLD region from ", string(Level.MapUIRegions[i].TimeLastVisited)), " to "), string(Level.TimeSeconds)), " for MapUIRegion '"), string(Region.Zone.MapUIRegion)));
		OldRegionIndex = i;
		Level.MapUIRegions[i].TimeLastVisited = Level.TimeSeconds;
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x639
	/*@Error*/
	goto J0x647;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x29C;
	return;
	@NULL
	Item
	Item
	@NULL
}

function ToggleGPSNodes()
{
	ShowGPSNodes = __NFUN_129__(ShowGPSNodes);
	return;
	@NULL
	Item
}

function TestGPS(optional name MapUIRegion)
{
	local ZoneInfo Zone;

	// End:0x6B
	if(__NFUN_255__(MapUIRegion, 'None'))
	{
		// End:0x67
		foreach __NFUN_304__(Class'Engine.ZoneInfo', Zone)
		{
			// End:0x66
			if(__NFUN_254__(Zone.MapUIRegion, MapUIRegion))
			{
				SetGPSDestinationActor(Zone);								
				goto J0x7E;
				SetGPSDestination(Location);
				return;
				@NULL
				Item
			}
		}
		default.Item
	}
	@NULL
}

function SetGPSMapRegion(name MapUIRegion)
{
	local ZoneInfo Zone;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x6B
	/*@Error*/
	// End:0x6A
	foreach __NFUN_304__(Class'Engine.ZoneInfo', Zone)
	{
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x69
		/*@Error*/
		SetGPSDestinationActor(Zone);		
		return;				
		ClearGPSDestination();
		return;
		@NULL
		Item
		stop;
		default.@NULL
	}
}

function DisableNormalHudElements()
{
	HudElementsDisabled = true;
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("HideAllExceptMessages");
	return;
	@NULL
	Item
	Item
}

function EnableNormalHudElements()
{
	HudElementsDisabled = false;
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("ShowAll");
	return;
	@NULL
	Item
	Item
}

function DisableReticle()
{
	bReticleDisabled = true;
	return;
	@NULL
}

function EnableReticle()
{
	bReticleDisabled = false;
	return;
	@NULL
}

function bool ShouldHideReticle()
{
	return bReticleDisabled;
	return;
	@NULL
}

function AddCraftingFormula(Class<CraftingFormula> Formula)
{
	local int i;

	i = 0;
	// End:0x54
	if(__NFUN_150__(i, CraftingFormulae.Length))
	{
		// End:0x46
		if(__NFUN_114__(CraftingFormulae[i], Formula))
		{
			return;
			__NFUN_165__(i);
			// [Loop Continue]
			goto J0x0B;
			CraftingFormulae.Insert(0, 1);
			CraftingFormulae[0] = Formula;
		}
		return;
		@NULL
	}
	Item
	stop;
	default.@NULL
}

function RemoveCraftingFormula(Class<CraftingFormula> Formula)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x68
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5A
	/*@Error*/
	CraftingFormulae.Remove(i, 1);
	return;
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function RegisterPossibleAbilities()
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5C
	/*@Error*/
	RegisterObserver(self, PossibleAbilities[i].default.ModGroupName);
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	Item
	@NULL
}

// Export UShockPlayer::execShouldInitialize(FFrame&, void* const)
native function bool ShouldInitialize();

function PreBeginPlay()
{
	local int i;
	local ResearchTrack Track;

	SetLabel('Player');
	i = 0;
	// End:0x11E
	if(__NFUN_150__(i, ResearchTrackData.Length))
	{
		Track.ResearchName = ResearchTrackData[i].ResearchName;
		Track.FriendlyName = ResearchTrackData[i].FriendlyName;
		Track.MaxScore = ResearchTrackData[i].MaxScore;
		ResearchTracks[i] = Track;
		__NFUN_165__(i);
		// [Loop Continue]
		goto J0x1E;
		// End:0x12F
		if(__NFUN_129__(ShouldInitialize()))
		{
			return;
			super.PreBeginPlay();
			// End:0x15F
			if(Level.bIsDLC1Level)
			{
				BasePlasmidSlots = 4;
				RegisterPossibleAbilities();
				TrainingInitialization();
				UpdateInventorySize();
				switch(Level.GetFlashGUIController().DifficultySelected)
				{
					// End:0x1BE
					case 'ExtremeModeSelected':
					}/* !MISMATCHING REMOVE, tried If got Type:Case Position:0x113! */
					CurrentDifficultySetting = 3;
					// End:0x251
					break;
					// End:0x1D9
					case 'HardModeSelected':
					}/* !MISMATCHING REMOVE, tried If got Type:Case Position:0x12A! */
					CurrentDifficultySetting = 2;
					// End:0x251
					break;
					// End:0x1F4
					case 'NormalModeSelected':
						CurrentDifficultySetting = 1;
						// End:0x251
						break;
						// End:0x20F
						case 'EasyModeSelected':
						}/* !MISMATCHING REMOVE, tried If got Type:Case Position:0x158! */
						CurrentDifficultySetting = 0;
						// End:0x251
						break;
						// End:0xFFFF
						default:
							CurrentDifficultySetting = Level.GetGameDriver().GetUserSettings().GameDifficulty;
							// End:0x251
							break;
							break;
					}/* !MISMATCHING REMOVE, tried Switch got Type:Case Position:0x141! */
					ShockUserSettings(Level.GetGameDriver().GetUserSettings()).GameDifficulty = CurrentDifficultySetting;/* !MISMATCHING REMOVE, tried Case got Type:Switch Position:0x0F9! *//* !MISMATCHING REMOVE, tried Case got Type:If Position:0x0C1! */
			CurrentDifficultySetting = Level.GetGameDriver().GetUserSettings().GameDifficulty;/* !MISMATCHING REMOVE, tried Case got Type:If Position:0x0AA! */
		Level.GetFlashGUIController().LoadPCOptionsFromUserSettings();/* !MISMATCHING REMOVE, tried Case got Type:If Position:0x016! */
	return;
	@NULL
	Item
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.get_CurrentToken() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 40
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 845
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:Switch Position:0x251
	// Failed to format remaining nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 724
	// 1 & Type:Switch Position:0x251
}

function PostBeginPlay()
{
	// End:0x62
	if(ShockUserSettings(Level.GetGameDriver().GetUserSettings()).HasPlasmidPack_1)
	{
		InGameManualManager.UnhideManualTopic('PlasmidPack_1');
		goto J0x82;
		InGameManualManager.HideManualTopic('PlasmidPack_1');
	}
	AwardAchievementsManager.StartingDifficultySet();
	// End:0x167
	if(__NFUN_130__(Level.bIsDLC1Level, __NFUN_129__(ShockUserSettings(Level.GetGameDriver().GetUserSettings()).bPlayedChallengeRoom)))
	{
		ShockUserSettings(Level.GetGameDriver().GetUserSettings()).bPlayedChallengeRoom = true;
		Level.GetGameDriver().GetUserSettings().SaveSettings();
		// End:0x1B6
		if(Level.bIsDLC1Level)
		{
			Level.GetGameDriver().GetUserSettings().UseGamePlusData = false;
		}
		UseGamePlusData = Level.GetGameDriver().GetUserSettings().UseGamePlusData;
		// End:0x205
		if(__NFUN_129__(ShouldInitialize()))
		{
			return;
			super(Pawn).PostBeginPlay();
			// End:0x235
			if(Level.bIsDLC1Level)
			{
			}
			else
			{
				BasePlasmidSlots = 4;
				__NFUN_280__(0.5000000, false);
				log(,, __NFUN_112__(string(self), "::PostBeginPlay()"));
				DumpJournal();
				Level.GetLocalPlayerController().ConsoleCommand("SETINPUTCONTEXTSTACK Default");
			}
		}
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2D0
	/*@Error*/
	TakeAllTimer = __NFUN_278__(Class'Engine.Timer');
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x33F
	/*@Error*/
	ShockUserSettings(Level.GetGameDriver().GetUserSettings()).ArtSubtitles = true;
	return;
	@NULL
	Item
	Item
	@NULL
}

function Head GetHead()
{
	return Head;
	return;
	@NULL
}

function ApplyDifficultyMods()
{
	UnTriggerEffectEvent('SetDifficulty', 'Extreme');
	UnTriggerEffectEvent('SetDifficulty', 'Hard');
	UnTriggerEffectEvent('SetDifficulty', 'Easy');
	switch(CurrentDifficultySetting)
	{
		// End:0x8A
		case 3:
			TriggerEffectEvent('SetDifficulty',,,,,,,, 'Extreme');
			// End:0xE3
			break;
			// End:0xB5
			case 2:
			TriggerEffectEvent('SetDifficulty',,,,,,,, 'Hard');
			// End:0xE3
			break;
			// End:0xE0
			case 0:
			TriggerEffectEvent('SetDifficulty',,,,,,,, 'Easy');
			// End:0xE3
			break;
			// End:0xFFFF
			default:
				return;
				break;
		}/* !MISMATCHING REMOVE, tried Switch got Type:Case Position:0x05B! *//* !MISMATCHING REMOVE, tried Case got Type:Switch Position:0x054! */
	@NULL
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:Switch Position:0x0E3
	// Failed to format remaining nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 724
	// 1 & Type:Switch Position:0x0E3
}

function Timer()
{
	local Class<Item> ItemClass;

	// End:0xA8
	if(Level.GetFlashGUIController().ForceSavingGamePlusData)
	{
		Level.GetFlashGUIController().ForceSavingGamePlusData = false;
		SaveGamePlusData();
		PlayerController(Controller).Player.Console.ConsoleCommand("open 0-lighthouse");
		return;
		UnlockTrackSlot(1);
		UnlockTrackSlot(1);
		UnlockTrackSlot(2);
		UnlockTrackSlot(2);
	}
	UnlockTrackSlot(3);
	UnlockTrackSlot(3);
	UnlockTrackSlot(4);
	UnlockTrackSlot(4);
	ItemClass = Class<Item>(DynamicLoadObject("ShockDesignerClasses.AntipersonnelBulletFormula", Class'Core.Class'));
	GiveItemClass(1, ItemClass);
	ItemClass = Class<Item>(DynamicLoadObject("ShockDesignerClasses.HighExplosiveBuckshotFormula", Class'Core.Class'));
	GiveItemClass(1, ItemClass);
	ItemClass = Class<Item>(DynamicLoadObject("ShockDesignerClasses.ArmorPiercingMachineGunBulletFormula", Class'Core.Class'));
	GiveItemClass(1, ItemClass);
	ItemClass = Class<Item>(DynamicLoadObject("ShockDesignerClasses.AutoHackFormula", Class'Core.Class'));
	GiveItemClass(1, ItemClass);
	UpdateUIStats();
	ApplyDifficultyMods();
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

// Export UShockPlayer::execPreLevelTravel(FFrame&, void* const)
native event PreLevelTravel();

// Export UShockPlayer::execRebasePhotos(FFrame&, void* const)
native function RebasePhotos();

function PostLevelTravel()
{
	// End:0x7A
	if(__NFUN_130__(UseGamePlusData, __NFUN_254__(Level.Label, '1-Medical')))
	{
		UseGamePlusData = false;
		UsingGamePlusData = true;
		// End:0x7A
		if(HasGamePlusData())
		{
			ActiveHoldable.UnEquip(true);
			LoadGamePlusData();
			// End:0x9F
			if(__NFUN_114__(TakeAllTimer, none))
			{
				TakeAllTimer = __NFUN_278__(Class'Engine.Timer');
			}
		}
		ResetUIState();
		// End:0x175
		if(__NFUN_130__(__NFUN_255__(GetHands().__NFUN_284__(), 'ExorcisingGatherer'), __NFUN_255__(GetHands().__NFUN_284__(), 'PlayingScriptedHandAnimation')))
		{
		}
		// End:0x13F
		if(__NFUN_129__(GetHands().InWeaponsMode()))
		{
			TriggerEffectEvent('SwitchedToPlasmidHands');
			// End:0x13C
			if(__NFUN_119__(LastAbility, none))
			{
				SetActiveAbilityClass(LastAbility, true);
				goto J0x175;
				TriggerEffectEvent('SwitchedToWeaponHands');
				// End:0x175
				if(__NFUN_119__(LastWeapon, none))
				{
					Equip(LastWeapon, true);
				}
			}
			SavedPhotos = ShockGameDriver(Level.GetGameDriver()).SavedPhotos;
			RebasePhotos();
			ShockGameDriver(Level.GetGameDriver()).SavedPhotos.Length = 0;
		}
	}
	RestorePersistentTrainingInfo();
	log(,, __NFUN_112__(string(self), "::PostLevelTravel()"));
	DumpJournal();
	NativePostLevelTravel();
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function TravelPostAccept()
{
	super(Actor).TravelPostAccept();
	ResetUIState();
	InventoryManager.CheckDups();
	log(,, __NFUN_112__(string(self), "::TravelPostAccept()"));
	DumpJournal();
	return;
	@NULL
	Item
}

// Export UShockPlayer::execNativePostLevelTravel(FFrame&, void* const)
native function NativePostLevelTravel();

function UpdateMaxBioAmmo()
{
	local float PreviousMaxBioAmmo;

	PreviousMaxBioAmmo = MaxBioAmmo;
	MaxBioAmmo = ModifyStat('MaxBioAmmo_Bonus', __NFUN_174__(default.MaxBioAmmo, UpgradedBioAmmoBonus));
	AddBioAmmo(0.0000000);
	UpdateUIStats();
	ShockPlayerController(Controller).GetPlayerStatsManager().PlayerMaxBioAmmoUpdated(self);
	// End:0x10A
	if(__NFUN_177__(MaxBioAmmo, PreviousMaxBioAmmo))
	{
		TriggerEffectEvent('MaxBioAmmoIncreased');
		Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("MaxBioAmmoIncreased");
		goto J0x185;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x185
		/*@Error*/
		TriggerEffectEvent('MaxBioAmmoDecreased');
		Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("MaxBioAmmoDecreased");
	}
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function UpdateMaxHealth()
{
	super.UpdateMaxHealth();
	ShockPlayerController(Controller).GetPlayerStatsManager().PlayerMaxHealthUpdated(self);
	return;
	@NULL
	Item
	Item
}

// Export UShockPlayer::execUpdateUIBioAmmoBank(FFrame&, void* const)
native function UpdateUIBioAmmoBank();

// Export UShockPlayer::execUpdateUIStats(FFrame&, void* const)
native function UpdateUIStats();

// Export UShockPlayer::execUpdateUIAmmoTotals(FFrame&, void* const)
native function UpdateUIAmmoTotals();

// Export UShockPlayer::execGetCredits(FFrame&, void* const)
native function int GetCredits();

// Export UShockPlayer::execGetMaxCredits(FFrame&, void* const)
native function int GetMaxCredits();

function AddCredits(int numCredits)
{
	//native.numCredits;	
	@NULL
}

function RemoveCredits(int numCredits)
{
	//native.numCredits;	
	@NULL
}

// Export UShockPlayer::execGetADAM(FFrame&, void* const)
native function int GetADAM();

function AddADAM(int numADAM)
{
	//native.numADAM;	
	@NULL
}

function RemoveADAM(int numADAM)
{
	//native.numADAM;	
	@NULL
}

// Export UShockPlayer::execGetBioAmmo(FFrame&, void* const)
native function float GetBioAmmo();

// Export UShockPlayer::execGetMaxBioAmmo(FFrame&, void* const)
native function float GetMaxBioAmmo();

function AddBioAmmo(float numBioAmmo)
{
	//native.numBioAmmo;	
	@NULL
}

function RemoveBioAmmo(float numBioAmmo)
{
	//native.numBioAmmo;	
	@NULL
}

function SwitchHandModes()
{
	log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::SwitchHandModes() ... LastAbility = "), string(LastAbility)), ", LastWeapon = "), string(LastWeapon)));
	// End:0x123
	if(GetHands().InWeaponsMode())
	{
		// End:0x120
		if(__NFUN_130__(__NFUN_119__(LastAbility, none), __NFUN_153__(GetAbilityClassIndex(LastAbility), 0)))
		{
			TriggerEffectEvent('SwitchedToPlasmidHands');
			SetActiveAbilityClass(LastAbility, true);
			Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("ShowPCAbilitySelector");
			goto J0x222;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x222
			/*@Error*/
			TriggerEffectEvent('SwitchedToWeaponHands');
		}
	}
	Equip(LastWeapon, true);
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("ShowPCWeaponSelector");
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodString("SelectAmmo", string(Weapon(LastWeapon).GetCurrentAmmoSelection().Name));
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function SwitchToPlasmids()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xBF
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xBF
	/*@Error*/
	TriggerEffectEvent('SwitchedToPlasmidHands');
	SetActiveAbilityClass(LastAbility, true);
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("ShowPCAbilitySelector");
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function SwitchToWeapons()
{
	// End:0xA5
	if(__NFUN_129__(GetHands().InWeaponsMode()))
	{
		// End:0xA5
		if(__NFUN_119__(LastWeapon, none))
		{
			TriggerEffectEvent('SwitchedToWeaponHands');
			Equip(LastWeapon, true);
			Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("ShowPCWeaponSelector");
			return;
			@NULL
			Item
			default.Item
		}
	}
	@NULL
}

function ResetCurrentHandMode()
{
	log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::ResetCurrentHandMode() ... LastAbility = "), string(LastAbility)), ", LastWeapon = "), string(LastWeapon)));
	// End:0xAD
	if(__NFUN_129__(GetHands().InWeaponsMode()))
	{
		TriggerEffectEvent('SwitchedToPlasmidHands');
		SetActiveAbilityClass(LastAbility, true);
		goto J0xD4;
		TriggerEffectEvent('SwitchedToWeaponHands');
	}
	Equip(LastWeapon, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function ZoomCycle()
{
	GetHands().ToggleZoom();
	return;
}

function ICanBeHarvested GetHarvestingTarget()
{
	return CurrentHarvestTarget;
	return;
	@NULL
}

function bool CanHarvestAdam()
{
	return HasGathererTool;
	return;
	@NULL
}

function GivePlayerGathererTool()
{
	HasGathererTool = true;
	return;
	@NULL
}

function bool BeginHarvestingAdam(ICanBeHarvested theHarvestTarget)
{
	local bool Success;

	// End:0x51
	if(__NFUN_119__(CurrentHarvestTarget, theHarvestTarget))
	{
		// End:0x51
		if(GetHands().UseGathererTool())
		{
			CurrentHarvestTarget = theHarvestTarget;
			Success = true;
			return Success;
			return;
			@NULL
			Item
			Item
		}
	}
	@NULL
}

function EndHarvestingAdam()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x27
	/*@Error*/
	GetHands().StopUsingGathererTool();
	return;
	@NULL
}

function HarvestTarget(float HarvestAmount)
{
	AddADAM(int(HarvestAmount));
	CurrentHarvestTarget.OnHarvestedAmount(HarvestAmount);
	return;
	@NULL
	Item
	Item
}

function OnCompletedHarvestingAdam()
{
	CurrentHarvestTarget = none;
	return;
	@NULL
}

function BeginExorcisingGatherer(BaseShockAI theGatherer, bool PacifyHer)
{
	ShockPlayerController(Controller).ResetFocii();
	ShockPlayerController(Controller).DontUpdateFocus = true;
	// End:0xB9
	if(Level.bIsDLC1Level)
	{
		StopChallengeTimer();
		AwardAchievementsManager.CollectedGatherer();
		dispatchMessage(Class'ShockGame.MessagePlayerCollectedGatherer'.static.Allocate(self)., construct_BaseShockAI(theGatherer));
		return;
		CurrentExorcismTarget = theGatherer;
		CurrentExorcismTarget.PlayerStartedInteractingWithGatherer(self, PacifyHer);
		// End:0x138
		if(PacifyHer)
		{
		}
		else
		{
			dispatchMessage(Class'ShockGame.MessagePlayerStartedPacifyingGatherer'.static.Allocate(self)., construct_BaseShockAI(CurrentExorcismTarget));
			goto J0x172;
			dispatchMessage(Class'ShockGame.MessagePlayerStartedSavingGatherer'.static.Allocate(self)., construct_BaseShockAI(CurrentExorcismTarget));
			Level.GetFlashGUIController().HideMovie('HUD');
		}
	}
	ShockGameInfo(Level.Game).MakeAllPawnsInvincible(true);
	Level.SpawningManager.DisableAllAIsExcept(CurrentExorcismTarget);
	Controller.ConsoleCommand("PUSHINPUTCONTEXT NullInput");
	ShockPlayerController(Controller).DisableSaveGameOption();
	GetHands().ExorciseGatherer(theGatherer, PacifyHer);
	SetBusy(true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnCompletedExorcisingGatherer(bool WasPacified)
{
	local int NumExorcised, NumInLevel;
	local ShockGameInfo theGame;

	theGame = ShockGameInfo(Level.Game);
	Level.GetFlashGUIController().UnhideMovie('HUD');
	CurrentExorcismTarget.PlayerFinishedInteractingWithGatherer(self, WasPacified);
	// End:0x109
	if(WasPacified)
	{
		theGame.IncrementNumHarvestedGatherersThisLevel();
		dispatchMessage(Class'ShockGame.MessagePlayerPacifiedGatherer'.static.Allocate(self)., construct_BaseShockAI(CurrentExorcismTarget));
		ShockPlayerController(Controller).GetPlayerStatsManager().PacifiedGatherer(self);
		goto J0x189;
		theGame.IncrementNumSavedGatherersThisLevel();
		dispatchMessage(Class'ShockGame.MessagePlayerSavedGatherer'.static.Allocate(self)., construct_BaseShockAI(CurrentExorcismTarget));
	}
	ShockPlayerController(Controller).GetPlayerStatsManager().SavedGatherer(self);
	NumExorcised = __NFUN_146__(theGame.GetNumSavedGatherersThisLevel(), theGame.GetNumHarvestedGatherersThisLevel());
	NumInLevel = __NFUN_146__(NumExorcised, theGame.GetNumRoamingGatherersThisLevel());
	AwardAchievementsManager.InteractedWithGatherer(Level.Outer.Name, NumExorcised);
	ShockPlayerController(Controller).ClientMessage(FormatTextString(Class'ShockGame.FlashStrings'.default.ExorcisedGatherer, string(NumExorcised), string(NumInLevel)), 'Important');
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnGathererInteractionCompleted()
{
	Level.GetFlashGUIController().UnhideMovie('HUD');
	ShockGameInfo(Level.Game).MakeAllPawnsInvincible(false);
	Level.SpawningManager.EnableAllAIs();
	Controller.ConsoleCommand("POPINPUTCONTEXT NullInput");
	ShockPlayerController(Controller).EnableSaveGameOption();
	ShockPlayerController(Controller).ResetFocii();
	ShockPlayerController(Controller).DontUpdateFocus = false;
	CurrentExorcismTarget = none;
	SetBusy(false);
	return;
	@NULL
	Item
	Item
	@NULL
}

function InterruptGathererInteraction()
{
	// End:0x62
	if(__NFUN_119__(CurrentExorcismTarget, none))
	{
		CurrentExorcismTarget.PlayerInterruptedInteractingWithGatherer(self, GetHands().IsPacifyingGatherer);
		ResetCurrentHandMode();
		// End:0x62
		if(__NFUN_119__(CurrentExorcismTarget, none))
		{
			OnGathererInteractionCompleted();
			return;
			@NULL
			Item
			default.Item
		}
	}
	@NULL
}

function OnCompletedInjectingEve()
{
	CurrentHypo.FinishedUsing(self);
	return;
	@NULL
}

function OnSpawnedDamageEmitter(DamageEmitter Emitter)
{
	// End:0x3D
	if(__NFUN_258__(GetActiveAbilityClass(), Class'ShockGame.EmitterAttackAbility'))
	{
		GetHands().OnSpawnedDamageEmitter(Emitter);
		goto J0x50;
		super.OnSpawnedDamageEmitter(Emitter);
	}
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function SetTargetIndicator(Class<Actor> TargetIndicatorClass, Vector inTargetIndicatorOffset)
{
	log(,, __NFUN_112__(__NFUN_112__(string(self), "::SetTargetIndicator... TargetIndicatorClass = "), string(TargetIndicatorClass)));
	TargetIndicator = __NFUN_278__(TargetIndicatorClass);
	assert(__NFUN_119__(TargetIndicator, none));
	TargetIndicator.SetHidden(true);
	TargetIndicatorOffset = inTargetIndicatorOffset;
	return;
	@NULL
	Item
	Item
	@NULL
}

function ClearTargetIndicator()
{
	log(,, __NFUN_112__(string(self), "::ClearTargetIndicator..."));
	TargetIndicator.__NFUN_279__();
	return;
	@NULL
}

function int GetNumAvailableAbilities()
{
	return AvailableAbilities.Length;
	return;
	@NULL
}

function Class<Ability> GetAbilityClass(int Index)
{
	// End:0x2B
	if(__NFUN_132__(__NFUN_150__(Index, 0), __NFUN_151__(Index, GetNumAvailableAbilities())))
	{
		return none;
		return AvailableAbilities[Index];
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function Class<Ability> GetAbilityClassByClassName(name AbilityClassName)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x73
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x65
	/*@Error*/
	return AvailableAbilities[i];
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x0B;
	return none;
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

function int GetAbilityClassIndex(Class<Ability> inAbility)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5C
	/*@Error*/
	// End:0x4E
	if(__NFUN_114__(AvailableAbilities[i], inAbility))
	{
		return i;
		__NFUN_165__(i);
		// [Loop Continue]
		goto J0x0B;
		return -1;
		return;
		@NULL
		Item
	}
	Item
	@NULL
}

function AddAvailableAbilityClass(Class<Ability> inAbility)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x8F
	/*@Error*/
	AvailableAbilities[AvailableAbilities.Length] = inAbility;
	log(,, __NFUN_112__("ADDED ABILITY ", string(inAbility)));
	LastAbility = inAbility;
	SetActiveAbilityClass(inAbility);
	ResetUIAbilities();
	return;
	@NULL
	Item
	Item
	@NULL
}

function UIAddAbilityClass(Class<Ability> inAbility)
{
	//native.inAbility;	
	@NULL
}

function PCWeaponSelectionAddAbilityClass(Class<Ability> inAbility)
{
	//native.inAbility;	
	@NULL
}

function RemoveAvailableAbilityClass(Class<Ability> inAbility)
{
	local int Index;

	Index = GetAbilityClassIndex(inAbility);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x96
	/*@Error*/
	AvailableAbilities.Remove(Index, 1);
	log(,, __NFUN_112__("REMOVED ABILITY ", string(inAbility)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x8C
	/*@Error*/
	SetActiveAbilityClass(none);
	ResetUIAbilities();
	return;
	@NULL
	Item
	Item
	@NULL
}

function UIRemoveAbilityClass(Class<Ability> inAbility)
{
	//native.inAbility;	
	@NULL
}

function Class<Ability> GetActiveAbilityClass()
{
	return ActiveAbility;
	return;
	@NULL
}

function Ability GetActiveAbility()
{
	return GetAbilityFromClass(GetActiveAbilityClass());
	return;
}

function SetActiveAbilityClass(Class<Ability> theAbility, optional bool forceSwitch)
{
	DropObject();
	// End:0x107
	if(__NFUN_130__(__NFUN_119__(GetHands(), none), __NFUN_129__(GetHands().CanChangeActiveAbility())))
	{
		log('Weapons', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::SetActiveAbilityClass( "), string(theAbility)), ", "), string(forceSwitch)), " ) Could not change the active ability because the hands were in a state that did not permit an ability to be equipped."));
		return;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x1CD
		/*@Error*/
	}
	ActiveAbility = theAbility;
	// End:0x172
	if(__NFUN_119__(GetHands(), none))
	{
		GetHands().SetActiveAbility(GetActiveAbility());
		// End:0x194
		if(__NFUN_119__(theAbility, none))
		{
			UISelectAbilityClass(theAbility);
			ShockPlayerController(Controller).GetPlayerStatsManager().SelectedAbility(self, GetActiveAbility());
		}
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function UISelectAbilityClass(Class<Ability> theAbility)
{
	//native.theAbility;	
	@NULL
}

function PlayerAddAvailableHoldable(Holdable inHoldable)
{
	log('Inventory', 3, __NFUN_112__(__NFUN_112__("Player ADDED available holdable of class '", string(inHoldable.Class.Name)), "'"));
	// End:0xAA
	if(inHoldable.__NFUN_303__('Weapon'))
	{
		UIAddWeapon(Weapon(inHoldable));
		CheckToAddPlayerStats();
		LastWeapon = inHoldable;
		Equip(inHoldable);
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

// Export UShockPlayer::execCheckToAddPlayerStats(FFrame&, void* const)
native function CheckToAddPlayerStats();

function UIAddWeapon(Weapon Weapon)
{
	//native.Weapon;	
	@NULL
}

// Export UShockPlayer::execPCWeaponSelectionRefresh(FFrame&, void* const)
native function PCWeaponSelectionRefresh();

function PlayerRemoveAvailableHoldable(Holdable inHoldable)
{
	log('Inventory', 3, __NFUN_112__(__NFUN_112__("Player REMOVED available holdable of class '", string(inHoldable.Class.Name)), "'"));
	// End:0xA2
	if(inHoldable.__NFUN_303__('Weapon'))
	{
		UIRemoveWeapon(Weapon(inHoldable));
		Equip(none);
		return;
		@NULL
		Item
		Item
	}
	@NULL
}

function UIRemoveWeapon(Weapon Weapon)
{
	//native.Weapon;	
	@NULL
}

function Equip(Holdable theHoldable, optional bool forceSwitch)
{
	log('Weapons', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), " is trying to Equip '"), string(theHoldable)), "'"));
	DropObject();
	// End:0x84
	if(__NFUN_132__(__NFUN_119__(theHoldable, ActiveHoldable), forceSwitch))
	{
		PendingHoldable = theHoldable;
		goto J0x8F;
		PendingHoldable = none;
		// End:0xB6
		if(__NFUN_119__(PendingHoldable, none))
		{
			GetHands().EquipWeapon();
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xEE
		/*@Error*/
		UISelectWeapon(Weapon(theHoldable));
	}
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function PendingEquip(Holdable theHoldable)
{
	PendingHoldable = none;
	PlayerPendingEquipHook(theHoldable);
	return;
	@NULL
	Item
}

function PlayerEquipHook(Holdable theHoldable)
{
	log(,, "Equip hook called");
	// End:0x52
	if(theHoldable.__NFUN_303__('Weapon'))
	{
		UISelectWeapon(Weapon(theHoldable));
		return;
		@NULL
		Item
	}
	Item
}

function PlayerPendingEquipHook(Holdable theHoldable)
{
	// End:0x38
	if(theHoldable.__NFUN_303__('Weapon'))
	{
		UISetPendingWeapon(Weapon(theHoldable));
		return;
		@NULL
		Item
	}
	Item
}

// Export UShockPlayer::execResetUICurrentAmmo(FFrame&, void* const)
native function ResetUICurrentAmmo();

function UISelectWeapon(Weapon Weapon)
{
	//native.Weapon;	
	@NULL
}

function UIPCSelectWeapon(Weapon Weapon)
{
	//native.Weapon;	
	@NULL
}

function UISetPendingWeapon(Weapon Weapon)
{
	//native.Weapon;	
	@NULL
}

function BeginFiring(optional bool inAltFire)
{
	// End:0x42
	if(__NFUN_130__(__NFUN_130__(__NFUN_129__(ImmediateFireOfPendingWeaponEnabled), __NFUN_119__(GetHands(), none)), __NFUN_129__(GetHands().InWeaponsMode())))
	{
		return;
		// End:0x59
		if(IsInSanctuary())
		{
		}
		LeaveSanctuary();
		super.BeginFiring(inAltFire);
	}
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function UseActiveAbility()
{
	// End:0x28
	if(__NFUN_119__(GetHands(), none))
	{
		GetHands().UseActiveAbility();
	}
	return;
}

function UseActiveAbilityRelease()
{
	// End:0x28
	if(__NFUN_119__(GetHands(), none))
	{
		GetHands().UseActiveAbilityRelease();
	}
	return;
}

function OnUsingActiveAbilityStarted()
{
	log('Testing', 4, __NFUN_112__(string(self), "::OnUsingActiveAbilityStarted()"));
	SetBusy(true);
	return;
}

function OnUsingActiveAbilityFinished()
{
	log('Testing', 4, __NFUN_112__(string(self), "::OnUsingActiveAbilityFinished()"));
	SetBusy(false);
	ShockPlayerController(Controller).GetPlayerStatsManager().PlayerAbilityFired(self, GetActiveAbility());
	return;
	@NULL
	Item
}

function Notify(name GroupName, bool wasRemoved, name modName)
{
	local int i;

	log('Mods', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::notify( "), string(GroupName)), ", "), string(wasRemoved)), ", "), string(modName)), " )"));
	switch(GroupName)
	{
		// End:0x72
		case 'ActiveTrackSlots_Bonus':
			// End:0x7E
			case 'EcologyTrackSlots_Bonus':
				// End:0x8A
				case 'EngineeringTrackSlots_Bonus':
				// End:0x96
				case 'WeaponTrackSlots_Bonus':
				// End:0xAF
				case 'PhysicalTrackSlots_Bonus':
				UpdateMaxBioAmmo();
			// End:0x5FE
			break;
			// End:0xC8
			case 'MaxBioAmmo_Bonus':
				UpdateMaxBioAmmo();
			// End:0x5FE
			break;
			// End:0xE1
			case 'InventorySize_Bonus':
				UpdateInventorySize();
			// End:0x5FE
			break;
			// End:0xED
			case 'SpeedBoostInUse_Exists':
				// End:0x1BF
				case 'MeleeDamage_Bonus':
				// End:0x162
				if(__NFUN_129__(wasRemoved))
				{/* !MISMATCHING REMOVE, tried Case got Type:If Position:0x0E9! */
				Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodString("AddEffectInUse", string(GroupName));
				goto J0x1BC;
				Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodString("RemoveEffectInUse", string(GroupName));
			}/* !MISMATCHING REMOVE, tried If got Type:Case Position:0x0D1! */
			// End:0x5FE
			break;
			// End:0x1F3
			case 'Pistol_BulletAmmoAvailable_Exists':
				UpdateAmmoStatusForGroup(GroupName, 'Pistol', Class'ShockGame.Pistol_Bullet');
				J0x1BC:

				// End:0x5FE
				break;
			// End:0x227
			case 'Pistol_ArmorPiercingAmmoAvailable_Exists':
				UpdateAmmoStatusForGroup(GroupName, 'Pistol', Class'ShockGame.Pistol_ArmorPiercing');
				// End:0x5FE
				break;
				// End:0x25B
				case 'Pistol_AntiPersonnelAmmoAvailable_Exists':
				UpdateAmmoStatusForGroup(GroupName, 'Pistol', Class'ShockGame.Pistol_AntiPersonnel');
				// End:0x5FE
				break;
				// End:0x28F
				case 'Shotgun_00BuckAmmoAvailable_Exists':
					UpdateAmmoStatusForGroup(GroupName, 'Shotgun', Class'ShockGame.Shotgun_00Buck');
				// End:0x5FE
				break;
				// End:0x2C3
				case 'Shotgun_IonicBuckAmmoAvailable_Exists':
					UpdateAmmoStatusForGroup(GroupName, 'Shotgun', Class'ShockGame.Shotgun_IonicBuck');
				// End:0x5FE
				break;
				// End:0x2F7
				case 'Shotgun_HighExplosiveBuckAmmoAvailable_Exists':
					UpdateAmmoStatusForGroup(GroupName, 'Shotgun', Class'ShockGame.Shotgun_HighExplosiveBuck');
				// End:0x5FE
				break;
				// End:0x32B
				case 'Crossbow_BoltAmmoAvailable_Exists':
					UpdateAmmoStatusForGroup(GroupName, 'Crossbow', Class'ShockGame.Crossbow_Bolt');
				// End:0x5FE
				break;
				// End:0x35F
				case 'Crossbow_ArmorPiercingBoltAmmoAvailable_Exists':
					UpdateAmmoStatusForGroup(GroupName, 'Crossbow', Class'ShockGame.Crossbow_ArmorPiercingBolt');
					// End:0x5FE
					break;
					// End:0x393
					case 'Crossbow_TrapBoltAmmoAvailable_Exists':
					UpdateAmmoStatusForGroup(GroupName, 'Crossbow', Class'ShockGame.Crossbow_TrapBolt');
					// End:0x5FE
					break;
					// End:0x3C7
					case 'Crossbow_DiseaseBoltAmmoAvailable_Exists':
					UpdateAmmoStatusForGroup(GroupName, 'Crossbow', Class'ShockGame.Crossbow_DiseaseBolt');
					// End:0x5FE
					break;
					// End:0x3FB
					case 'GrenadeLauncher_FragGrenadeAmmoAvailable_Exists':
						UpdateAmmoStatusForGroup(GroupName, 'GrenadeLauncher', Class'ShockGame.GrenadeLauncher_FragGrenade');
					// End:0x5FE
					break;
					// End:0x42F
					case 'GrenadeLauncher_LiquidNitrogenAmmoAvailable_Exists':
						UpdateAmmoStatusForGroup(GroupName, 'GrenadeLauncher', Class'ShockGame.GrenadeLauncher_LiquidNitrogen');
					// End:0x5FE
					break;
					// End:0x463
					case 'GrenadeLauncher_StickyGrenadeAmmoAvailable_Exists':
						UpdateAmmoStatusForGroup(GroupName, 'GrenadeLauncher', Class'ShockGame.GrenadeLauncher_StickyGrenade');
					// End:0x5FE
					break;
					// End:0x497
					case 'ChemicalThrower_KeroseneAmmoAvailable_Exists':
						UpdateAmmoStatusForGroup(GroupName, 'ChemicalThrower', Class'ShockGame.ChemicalThrower_Kerosene');
						// End:0x5FE
						break;
					// End:0x4CB
					case 'ChemicalThrower_LiquidNitrogenAmmoAvailable_Exists':
						UpdateAmmoStatusForGroup(GroupName, 'ChemicalThrower', Class'ShockGame.ChemicalThrower_LiquidNitrogen');
						// End:0x5FE
						break;
						// End:0x4FF
						case 'ChemicalThrower_IonicGelAmmoAvailable_Exists':
						UpdateAmmoStatusForGroup(GroupName, 'ChemicalThrower', Class'ShockGame.ChemicalThrower_IonicGel');
						// End:0x5FE
						break;
						// End:0x533
						case 'MachineGun_BulletAmmoAvailable_Exists':
							UpdateAmmoStatusForGroup(GroupName, 'MachineGun', Class'ShockGame.MachineGun_Bullet');
						// End:0x5FE
						break;
						// End:0x567
						case 'MachineGun_RubberBulletAmmoAvailable_Exists':
							UpdateAmmoStatusForGroup(GroupName, 'MachineGun', Class'ShockGame.MachineGun_RubberBullet');
						// End:0x5FE
						break;
						// End:0x59B
						case 'MachineGun_FrozenBulletAmmoAvailable_Exists':
							UpdateAmmoStatusForGroup(GroupName, 'MachineGun', Class'ShockGame.MachineGun_FrozenBullet');
						// End:0x5FE
						break;
						// End:0x5E2
						case 'HypoMetabolizer_Exists':
							// End:0x5CC
							if(__NFUN_129__(wasRemoved))
							{
								AddPersistentContext('HypoMetabolizerEquipped');/* !MISMATCHING REMOVE, tried Case got Type:If Position:0x4E3! */
							// End:0x5DF
							break;
							RemovePersistentContext('HypoMetabolizerEquipped');
							// End:0x5FE
							break;
							// End:0x5FB
							case 'CeilingCrawlerOrganUsable_Exists':
								ConvertCeilingCrawlerOrgans();
								// End:0x5FE
								break;
							// End:0xFFFF
							default:
								super.Notify(GroupName, wasRemoved, modName);
								i = 0;
								/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
									
								*/

								// End:0x6CF
								/*@Error*/
								/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
									
								*/

								// End:0x6C1
								/*@Error*/
								break;/* Tried to find Switch scope, found Case instead */
						/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
							
						*/

						// End:0x6A2
						/*@Error*/
						RemoveAvailableAbilityClass(PossibleAbilities[i]);
					goto J0x6BF;
					AddAvailableAbilityClass(PossibleAbilities[i]);
					return;
					__NFUN_165__(i);
					goto J0x62F;
					return;
					@NULL
					Item
				}/* !MISMATCHING REMOVE, tried If got Type:Case Position:0x2C7! */
				Item
				@NULL
	// Failed to format remaining nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 724
	// 1 & Type:Switch Position:0x5FE
}

function Ability GetAbilityFromClass(Class<Ability> abilityClass)
{
	//native.abilityClass;	
	@NULL
}

function UpdateAmmoStatusForGroup(name GroupName, name WeaponName, Class<Ammunition> AmmoClass)
{
	local Weapon theWeapon;

	theWeapon = Weapon(GetHoldableByClassName(WeaponName));
	// End:0x5B
	if(HasMod(GroupName))
	{
		AddAvailableAmmo(theWeapon, AmmoClass);
		goto J0x77;
		RemoveAvailableAmmo(theWeapon, AmmoClass);
		return;
		@NULL
	}
	Item
	Item
	@NULL
}

function AddAvailableAmmo(Weapon theWeapon, Class<Ammunition> AmmoClass)
{
	// End:0x25
	if(theWeapon.HasAvailableAmmo(AmmoClass))
	{
		return;
		theWeapon.AddAvailableAmmo(AmmoClass);
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function RemoveAvailableAmmo(Weapon theWeapon, Class<Ammunition> AmmoClass)
{
	// End:0x27
	if(__NFUN_129__(theWeapon.HasAvailableAmmo(AmmoClass)))
	{
		return;
		theWeapon.RemoveAvailableAmmo(AmmoClass);
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function EnterSanctuary()
{
	log('Plasmids', 3, __NFUN_112__(string(self), " Entering Sanctuary..."));
	bIsInSanctuary = true;
	SanctuaryLocation = Location;
	// End:0xFD
	if(__NFUN_130__(__NFUN_255__(SanctuaryModelSocket, 'None'), __NFUN_119__(GetHands(), none)))
	{
		SanctuaryModel = __NFUN_278__(SanctuaryModelClass);
		assert(__NFUN_119__(SanctuaryModel, none));
		GetHands().AttachToBone(SanctuaryModel, SanctuaryModelSocket);
		SanctuaryModel.DrawPriority = 1;
		SanctuaryModel.TriggerEffectEvent('EnteredSanctuary');
		// End:0x12E
		if(__NFUN_119__(GetHands(), none))
		{
			GetHands().TriggerEffectEvent('EnteredSanctuary');
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x15D
			/*@Error*/
		}
		else
		{
			ActiveHoldable.TriggerEffectEvent('EnteredSanctuary');
			TriggerEffectEvent('EnteredSanctuary');
		}/* !MISMATCHING REMOVE, tried If got Type:Else Position:0x0FD! */
		return;
		@NULL
		Item
		Item
		@NULL
	}/* !MISMATCHING REMOVE, tried Else got Type:If Position:0x040! */
}

function LeaveSanctuary()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x16B
	/*@Error*/
	log('Plasmids', 3, __NFUN_112__(string(self), " Leaving Sanctuary..."));
	UnTriggerEffectEvent('EnteredSanctuary');
	TriggerEffectEvent('LeftSanctuary');
	// End:0xBE
	if(__NFUN_119__(SanctuaryModel, none))
	{
		SanctuaryModel.UnTriggerEffectEvent('EnteredSanctuary');
		SanctuaryModel.TriggerEffectEvent('LeftSanctuary');
		SanctuaryModel.__NFUN_279__();
		// End:0x110
		if(__NFUN_119__(GetHands(), none))
		{
			GetHands().UnTriggerEffectEvent('EnteredSanctuary');
		}
		GetHands().TriggerEffectEvent('LeftSanctuary');
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x15F
		/*@Error*/
		ActiveHoldable.UnTriggerEffectEvent('EnteredSanctuary');
	}
	ActiveHoldable.TriggerEffectEvent('LeftSanctuary');
	bIsInSanctuary = false;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function bool IsInSanctuary()
{
	return bIsInSanctuary;
	return;
	@NULL
}

// Export UShockPlayer::execConvertCeilingCrawlerOrgans(FFrame&, void* const)
native function ConvertCeilingCrawlerOrgans();

function Plasmid.ePlasmidTrack GetTrackForPlasmid(name PlasmidName)
{
	//native.PlasmidName;	
	@NULL
}

function int GetNumAvailablePlasmids()
{
	return PlasmidManager.GetNumAvailablePlasmids();
	return;
	@NULL
}

function name GetAvailablePlasmidNameByIndex(int Index)
{
	return PlasmidManager.GetAvailablePlasmidNameByIndex(Index);
	return;
	@NULL
	Item
}

function bool HasEmptyPlasmidSlot()
{
	return PlasmidManager.HasEmptyPlasmidSlot();
	return;
	@NULL
}

function bool IsNonDLCPlasmid(name PlasmidName)
{
	return PlasmidManager.IsNonDLCPlasmid(PlasmidName);
	return;
	@NULL
	Item
}

function int NumAvailablePlasmids(Plasmid.ePlasmidTrack Track)
{
	//native.Track;	
	@NULL
}

function int NumAvailableNonDLCPlasmids(Plasmid.ePlasmidTrack Track)
{
	//native.Track;	
	@NULL
}

function int NumEquippedPlasmids(Plasmid.ePlasmidTrack Track)
{
	//native.Track;	
	@NULL
}

function int NumUnlockedTrackSlots(Plasmid.ePlasmidTrack Track)
{
	//native.Track;	
	@NULL
}

function bool IsPlasmidAvailable(name PlasmidName)
{
	//native.PlasmidName;	
	@NULL
}

function AddAvailablePlasmid(name PlasmidName)
{
	//native.PlasmidName;	
	@NULL
}

function RemoveAvailablePlasmid(name PlasmidName)
{
	//native.PlasmidName;	
	@NULL
}

function bool IsPlasmidEquipped(name PlasmidName)
{
	//native.PlasmidName;	
	@NULL
}

function EquipPlasmid(name PlasmidName, int slotNumber)
{
	//native.PlasmidName;
	//native.slotNumber;	
	@NULL
	@NULL
}

function UnEquipPlasmid(name PlasmidName)
{
	//native.PlasmidName;	
	@NULL
}

function LaunchPlasmiNowScreen(name PlasmidName, int TrackNum)
{
	//native.PlasmidName;
	//native.TrackNum;	
	@NULL
	@NULL
}

// Export UShockPlayer::execClosePlasmiNowScreen(FFrame&, void* const)
native function ClosePlasmiNowScreen();

// Export UShockPlayer::execLaunchLogScreen(FFrame&, void* const)
native function LaunchLogScreen();

// Export UShockPlayer::execCloseLogScreen(FFrame&, void* const)
native function CloseLogScreen();

// Export UShockPlayer::execLaunchInGameManualScreen(FFrame&, void* const)
native function LaunchInGameManualScreen();

// Export UShockPlayer::execCloseInGameManualScreen(FFrame&, void* const)
native function CloseInGameManualScreen();

// Export UShockPlayer::execLaunchRadioMessagesScreen(FFrame&, void* const)
native function LaunchRadioMessagesScreen();

// Export UShockPlayer::execCloseRadioMessagesScreen(FFrame&, void* const)
native function CloseRadioMessagesScreen();

// Export UShockPlayer::execLaunchMapScreen(FFrame&, void* const)
native exec function LaunchMapScreen();

// Export UShockPlayer::execCloseMapScreen(FFrame&, void* const)
native function CloseMapScreen();

function AddTextToTraining(string TextToAdd)
{
	//native.TextToAdd;	
	@NULL
}

// Export UShockPlayer::execDismissTraining(FFrame&, void* const)
native function DismissTraining();

function AddTextToTrainingModal(string PromptTextToAdd, string HelpTextToAdd)
{
	//native.PromptTextToAdd;
	//native.HelpTextToAdd;	
	@NULL
	@NULL
}

// Export UShockPlayer::execDismissTrainingModal(FFrame&, void* const)
native function DismissTrainingModal();

function LaunchHackingScreen(HackInfo HackDetails, ICanBeHacked HackedObject)
{
	//native.HackDetails;
	//native.HackedObject;	
	@NULL
	@NULL
}

// Export UShockPlayer::execCloseHackingScreen(FFrame&, void* const)
native function CloseHackingScreen();

// Export UShockPlayer::execLaunchQuestsScreen(FFrame&, void* const)
native exec function LaunchQuestsScreen();

// Export UShockPlayer::execCloseQuestsScreen(FFrame&, void* const)
native function CloseQuestsScreen();

function UnlockTrackSlot(Plasmid.ePlasmidTrack Track)
{
	//native.Track;	
	@NULL
}

function LockTrackSlot(Plasmid.ePlasmidTrack Track)
{
	//native.Track;	
	@NULL
}

// Export UShockPlayer::execUnEquipAllPlasmids(FFrame&, void* const)
native function UnEquipAllPlasmids();

function int GetNumTrackSlots(Plasmid.ePlasmidTrack Track)
{
	//native.Track;	
	@NULL
}

function OnStartedInteractingWithMachine(ShockMachine TheStation)
{
	//native.TheStation;	
	@NULL
}

function OnFinishedInteractingWithMachine(ShockMachine TheStation)
{
	//native.TheStation;	
	@NULL
}

// Export UShockPlayer::execConfirmPlasmidSelection(FFrame&, void* const)
native function ConfirmPlasmidSelection();

// Export UShockPlayer::execCancelPlasmidSelection(FFrame&, void* const)
native function CancelPlasmidSelection();

// Export UShockPlayer::execBeginWeaponUpgradeInteraction(FFrame&, void* const)
native function BeginWeaponUpgradeInteraction();

// Export UShockPlayer::execConfirmWeaponUpgrade(FFrame&, void* const)
native function ConfirmWeaponUpgrade();

// Export UShockPlayer::execCancelWeaponUpgrade(FFrame&, void* const)
native function CancelWeaponUpgrade();

// Export UShockPlayer::execConfirmResearchInfo(FFrame&, void* const)
native function ConfirmResearchInfo();

// Export UShockPlayer::execCancelResearchInfo(FFrame&, void* const)
native function CancelResearchInfo();

function PlayDeveloperFilmSplash(name FilmName)
{
	//native.FilmName;	
	@NULL
}

function PlayDeveloperFilm(name FilmName)
{
	//native.FilmName;	
	@NULL
}

// Export UShockPlayer::execUnlockDeveloperFilmAll(FFrame&, void* const)
native function UnlockDeveloperFilmAll();

// Export UShockPlayer::execLockDeveloperFilmAll(FFrame&, void* const)
native function LockDeveloperFilmAll();

function DeveloperFilmTestSplash(name FilmName)
{
	PlayDeveloperFilmSplash(FilmName);
	return;
	@NULL
}

function DeveloperFilmTestMovie(name FilmName)
{
	PlayDeveloperFilm(FilmName);
	return;
	@NULL
}

exec function DeveloperFilmUnlockAll()
{
	UnlockDeveloperFilmAll();
	return;
}

exec function DeveloperFilmLockAll()
{
	LockDeveloperFilmAll();
	return;
}

function OpenContainer(Container Container, Material Material)
{
	InventoryManager.OpenContainer(Container);
	TriggerEffectEvent('OpenedContainer',, Material);
	return;
	@NULL
	Item
	Item
}

function Container GetCurrentContainer()
{
	return InventoryManager.GetCurrentContainer();
	return;
	@NULL
}

function FilterItem(Class<Item> ItemClass)
{
	// End:0x36
	if(__NFUN_129__(IsItemFiltered(ItemClass)))
	{
		ItemFiltrationList[ItemFiltrationList.Length] = ItemClass;
		return;
		@NULL
		Item
		Item
	}
	@NULL
}

function UnFilterItem(Class<Item> ItemClass)
{
	local int i;

	i = __NFUN_147__(ItemFiltrationList.Length, 1);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x69
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5B
	/*@Error*/
	ItemFiltrationList.Remove(i, 1);
	__NFUN_166__(i);
	// [Loop Continue]
	goto J0x17;
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool IsItemFiltered(Class<Item> ItemClass)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x55
	/*@Error*/
	// End:0x47
	if(__NFUN_258__(ItemClass, ItemFiltrationList[i]))
	{
		return true;
		__NFUN_165__(i);
		// [Loop Continue]
		goto J0x0B;
		return false;
		return;
		@NULL
		Item
	}
	stop;
	default.@NULL
}

function DumpFiltrationList()
{
	local int i;

	log(,, "-----------------------------------------------------------");
	log(,, "---------------Dumping Item Filtration List----------------");
	log(,, "-----------------------------------------------------------");
	log(,, "");
	i = 0;
	// End:0x122
	if(__NFUN_150__(i, ItemFiltrationList.Length))
	{
		log(,, string(ItemFiltrationList[i]));
		__NFUN_165__(i);
		// [Loop Continue]
		goto J0xE0;
		log(,, "");
		log(,, "-----------------------------------------------------------");
	}
	log(,, "-----------------------------------------------------------");
	log(,, "-----------------------------------------------------------");
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function float GetDamagePotential()
{
	local array<Holdable> Holdables;
	local Weapon Weapon;
	local float DamagePotential;
	local int i;

	Holdables = GetAvailableHoldables();
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xE9
	/*@Error*/
	Weapon = Weapon(Holdables[i]);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xDB
	/*@Error*/
	__NFUN_184__(DamagePotential, Weapon.GetDamagePotential(self));
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x1F;
	return DamagePotential;
	return;
	@NULL
	Item
	Item
	@NULL
}

function int GetAmmoCount(name WeaponName)
{
	local int i;
	local Weapon Weapon;
	local int AmmoCount;

	Weapon = Weapon(GetHoldableByClassName(WeaponName));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB2
	/*@Error*/
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA8
	/*@Error*/
	__NFUN_161__(AmmoCount, GetNumberOfItems(Weapon.AvailableAmmoTypes[i]));
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x40;
	return AmmoCount;
	return 0;
	return;
	@NULL
	Item
	Item
	@NULL
}

event float GetStackSizeModifier()
{
	return ModifyStat('MaximumStackSize_Modifier', 1.0000000);
	return;
}

function int FillWeaponClipWithAvailableAmmunition(Class<Ammunition> AmmoClass, int ClipSize)
{
	InventoryManager.LockItem(AmmoClass);
	return __NFUN_249__(ClipSize, GetNumberOfItems(AmmoClass));
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool HasAmmoRemaining(Class<Ammunition> AmmoClass)
{
	return __NFUN_151__(GetNumberOfItems(AmmoClass), 0);
	return;
	@NULL
}

function int GetNumberOfItems(Class<Item> ItemClass)
{
	return InventoryManager.GetNumberOfItems(ItemClass);
	return;
	@NULL
	Item
}

function GetInventoryClassesOfClass(Class<Item> ItemClass, out array< Class<Item> > InventoryClasses)
{
	InventoryManager.GetInventoryClassesOfClass(ItemClass, InventoryClasses);
	return;
	@NULL
	Item
	Item
}

function UseUpItem(Class<Item> ItemClass, int AmountUsed)
{
	// End:0x2E
	if(__NFUN_258__(ItemClass, Class'ShockGame.Credits'))
	{
		RemoveCredits(AmountUsed);
		goto J0x85;
		// End:0x5C
		if(__NFUN_258__(ItemClass, Class'ShockGame.ADAM'))
		{
		}
		RemoveADAM(AmountUsed);
		goto J0x85;
		InventoryManager.OnUsedInventoryItem(ItemClass, AmountUsed);
	}
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function UseUpAmmo(Class<Item> ItemClass, int AmountUsed)
{
	local Weapon theWeapon;
	local int i;
	local bool Found;

	// End:0xCA
	if(__NFUN_258__(ItemClass, Class'ShockGame.Ammunition'))
	{
		i = 0;
		// End:0xCA
		if(__NFUN_150__(i, GetNumHoldables()))
		{
			theWeapon = Weapon(GetHoldable(i));
			// End:0xBC
			if(__NFUN_119__(theWeapon, none))
			{
				// End:0xBC
				if(__NFUN_114__(theWeapon.GetCurrentAmmoSelection(), ItemClass))
				{
					theWeapon.SetCurrentAmmoSelection(none);
					Found = true;
					goto J0xCA;
					__NFUN_165__(i);
					// [Loop Continue]
					goto J0x23;
					UseUpItem(ItemClass, AmountUsed);
					/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
						
					*/

					// End:0x11C
					/*@Error*/
					theWeapon.SetCurrentAmmoSelection(Class<Ammunition>(ItemClass));
				}
			}
		}
	}
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function ReleaseAmmunition(Class<Ammunition> AmmoClass)
{
	InventoryManager.UnLockItem(AmmoClass);
	return;
	@NULL
	Item
}

function bool AddStackToInventory(ItemStack theStack)
{
	return InventoryManager.AddStackToInventory(theStack);
	return;
	@NULL
	Item
}

function OnPickedUpInventoryItem(Class<Item> ItemClass, int Amount)
{
	// End:0x11
	if(__NFUN_152__(Amount, 0))
	{
		return;
		log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__("OnPickedUpInventoryItem... itemClass = ", string(ItemClass)), ", amount = "), string(Amount)));
	}
	// End:0xFF
	if(__NFUN_130__(__NFUN_129__(InventoryManager.CanUseItem(ActiveUsableItem)), __NFUN_258__(ItemClass, Class'ShockGame.UsableItem')))
	{
		log(,, __NFUN_112__("setting ActiveUsableItem = ", string(Class<UsableItem>(ItemClass))));
		ActiveUsableItem = Class<UsableItem>(ItemClass);
		// End:0x1F2
		if(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_132__(__NFUN_258__(ItemClass, Class'ShockGame.Ammunition'), __NFUN_258__(ItemClass, Class'ShockGame.WeaponPickup')), GetHands().InWeaponsMode()), Weapon(ActiveHoldable).IsEmpty(false)), __NFUN_255__(GetHands().__NFUN_284__(), 'WeaponReloading')), __NFUN_255__(GetHands().__NFUN_284__(), 'ProceduralWeaponReloading')))
		{
		}
		Weapon(ActiveHoldable).SelectAmmo(Class<Ammunition>(ItemClass));
		ReloadWeapon();
		// End:0x278
		if(__NFUN_254__(Class<QuestLog>(ItemClass).default.LogType, 'Log'))
		{
			AwardAchievementsManager.PlayerPickedUpLog(Level.Outer.Name, Class<QuestLog>(ItemClass).default.EffectTag);
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x31B
		/*@Error*/
		// End:0x318
		if(__NFUN_130__(__NFUN_255__(Class<QuestLog>(ItemClass).default.LogType, 'Radio'), __NFUN_129__(__NFUN_258__(ItemClass, Class'ShockGame.CraftingFormula'))))
		{
			ShockPlayerController(Controller).ClientMessage(Class'ShockGame.FlashStrings'.default.CollectedQuestLog, 'Important');
			goto J0x3AA;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x3AA
			/*@Error*/
		}
		ShockPlayerController(Controller).ClientMessage(__NFUN_168__(Class'ShockGame.FlashStrings'.default.Collected, FormatTextString("%1 (%2)", ItemClass.default.FriendlyName, string(Amount))), 'ImportantAllowRepeat');
		dispatchMessage(Class'ShockGame.MessageReceivedInventory'.static.Allocate(self)., construct_ClassInt(ItemClass, Amount));
		return;
		@NULL
		Item
	}
	stop;
	default.@NULL
}

function OnStartHacking(HackInfo SetupInfo, ICanBeHacked HackedObject)
{
	local Actor HackedActor;

	// End:0xCE
	if(__NFUN_177__(float(SetupInfo.MinimumHackingLevel), ModifyStat('EngineeringTrackSlots_Bonus', 0.0000000)))
	{
		ShockPlayerController(Controller).ClientMessage(FormatTextString("Unable to hack %1: requires engineering skill of %2", HackedObject.GetFocusDisplayName(), string(SetupInfo.MinimumHackingLevel)), 'Warning');
		return;
		// End:0x187
		if(__NFUN_151__(SetupInfo.HackCost, Credits))
		{
			ShockPlayerController(Controller).ClientMessage(FormatTextString("Unable to hack %1: requires at least %2 Credits", HackedObject.GetFocusDisplayName(), string(SetupInfo.HackCost)), 'Warning');
		}
		return;
		HackedActor = Actor(HackedObject);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x1F9
		/*@Error*/
		HackedActor.dispatchMessage(Class'ShockGame.MessagePlayerStartedHacking'.static.Allocate(self)., construct_ICanBeHacked(HackedObject));
	}
	Level.GetFlashLiaison().RegisterForMovieEvent(self, 'HackResult');
	LaunchHackingScreen(SetupInfo, HackedObject);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function OnFinishedHacking(ICanBeHacked HackedObject, string HackResult)
{
	local Actor HackedActor;
	local ShockPawn Player;
	local Class<ShockPawn> BotClass;
	local HackInfo HackingGameSetupInfo;
	local float DamageToDeal;
	local int BotCount;
	local SecurityManagerBase SecuritySystem;

	DamageToDeal = -1.0000000;
	HackedActor = Actor(HackedObject);
	// End:0xE4
	if(__NFUN_119__(HackedActor, none))
	{
		HackedActor.dispatchMessage(Class'ShockGame.MessagePlayerFinishedHacking'.static.Allocate(self)., construct_ICanBeHackedBool(HackedObject, __NFUN_122__(HackResult, "Success")));
		ShockPlayerController(Level.GetLocalPlayerController()).GetPlayerStatsManager().FinishedHacking(self, HackedObject, HackResult);
		// End:0x177
		if(__NFUN_122__(HackResult, "Success"))
		{
			HackingGameSetupInfo = HackedObject.OnHackSucceeded(self, HackResult);
			AddHealth(ModifyStat('SuccessfulHackHealth_Bonus', 0.0000000));
		}
		AddBioAmmo(ModifyStat('SuccessfulHackBioAmmo_Bonus', 0.0000000));
		CloseHackingScreen();
		goto J0x654;
		HackingGameSetupInfo = HackedObject.OnHackFailed(self, HackResult);
		// End:0x3C4
		if(__NFUN_122__(HackResult, "Alarm"))
		{
			BotCount = HackingGameSetupInfo.AlarmBotCount;
			SecuritySystem = ShockGameInfo(Level.Game).GetSecurityManager();
		}
		// End:0x2BA
		if(__NFUN_130__(SecuritySystem.IsAlarmOn(), __NFUN_114__(SecuritySystem.GetAlarmTarget(), self)))
		{
			// End:0x2BA
			if(__NFUN_153__(SecuritySystem.GetNumberOfBotsForCurrentAlarm(), BotCount))
			{
				BotCount = __NFUN_146__(SecuritySystem.GetNumberOfBotsForCurrentAlarm(), 1);
				// End:0x2BA
				if(__NFUN_151__(BotCount, MaxBotsWhenHackFailsDuringAlarm))
				{
					BotCount = MaxBotsWhenHackFailsDuringAlarm;
					Level.GetFlashGUIController().GetPlayingMovie('Hacking').CallMethodString("ShowEndingMessage", HackingResultAlarmText);
					Player = ShockPawn(Level.GetLocalPlayerController().Pawn);
					BotClass = Class<ShockPawn>(DynamicLoadObject(HackingGameSetupInfo.AlarmBotType, Class'Core.Class'));
					SecuritySystem.StartAlarm(Player, Player, BotClass, BotCount, true);
				}
			}
		}
		goto J0x613;
		// End:0x487
		if(__NFUN_122__(HackResult, "Short"))
		{
			Level.GetFlashGUIController().GetPlayingMovie('Hacking').CallMethodString("ShowEndingMessage", HackingResultOverloadedText);
			HackedActor.TriggerEffectEvent('OverloadedTriggered');
			DamageToDeal = __NFUN_244__(HackingGameSetupInfo.DamageDealtOnOverload, __NFUN_175__(GetHealth(), 1.0000000));
			goto J0x613;
			// End:0x4F5
			if(__NFUN_122__(HackResult, "End"))
			{
				Level.GetFlashGUIController().GetPlayingMovie('Hacking').CallMethodString("ShowEndingMessage", HackingResultNoHackAttemptedText);
			}
			goto J0x613;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x568
			/*@Error*/
			Level.GetFlashGUIController().GetPlayingMovie('Hacking').CallMethodString("ShowEndingMessage", HackingResultShortCircuitText);
			goto J0x613;
			Level.GetFlashGUIController().GetPlayingMovie('Hacking').CallMethodString("ShowEndingMessage", HackingResultShortCircuitText);
		}
		HackedActor.TriggerEffectEvent('ShortCircuitTriggered');
		DamageToDeal = __NFUN_244__(HackingGameSetupInfo.DamageDealtOnShortCircuit, __NFUN_175__(GetHealth(), 1.0000000));
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x654
		/*@Error*/
		SetInvincible(false);
		TakeSimpleDamage(36, DamageToDeal, 1.0000000, HackedActor);
	}
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function float CalculateHackDifficultyForClass(name ClassName)
{
	//native.ClassName;	
	@NULL
}

function testCalculateHackDifficultyForClass(name ClassName)
{
	log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(ClassName), " will cost "), string(CalculateHackDifficultyForClass(ClassName))), " to hack"));
	return;
	@NULL
	Item
}

function NotifyWatchersPlayerIsBeingAttacked(ShockPawn Damager)
{
	local ShockPawn ShockPawnWatcher;
	local IWatchForPlayerBeingAttackedByProtector Watcher;

	// End:0x65
	foreach __NFUN_313__(Class'ShockGame.ShockPawn', ShockPawnWatcher)
	{
		Watcher = IWatchForPlayerBeingAttackedByProtector(ShockPawnWatcher);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x64
		/*@Error*/
		Watcher.OnPlayerAttacked(self, Damager);				
		return;
		@NULL
		Item
		ShockPawn
		@NULL
	}
}

function SetBusy(bool newBusy)
{
	super.SetBusy(newBusy);
	// End:0x2B
	if(newBusy)
	{
		BreakChameleonBlood();
		return;
		@NULL
		Item
	}
	DifficultyAdjustment
}

// Export UShockPlayer::execBreakChameleonBlood(FFrame&, void* const)
native function BreakChameleonBlood();

function EquipHoldableByClassName(name HoldableClassName)
{
	local Holdable theHoldable;

	theHoldable = GetHoldableByClassName(HoldableClassName);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x3F
	/*@Error*/
	Equip(theHoldable);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function PendingEquipHoldableByClassName(name HoldableClassName)
{
	local Holdable theHoldable;

	theHoldable = GetHoldableByClassName(HoldableClassName);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x3F
	/*@Error*/
	PendingEquip(theHoldable);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function EquipAmmoByClassName(name AmmoClassName)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x30
	/*@Error*/
	ReloadWeapon();
	return;
	@NULL
}

function EquipAbilityByClassName(name AbilityClassName)
{
	local Class<Ability> theAbility;

	theAbility = GetAbilityClassByClassName(AbilityClassName);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x40
	/*@Error*/
	SetActiveAbilityClass(theAbility, true);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function EquipHypoByClassName(name HypoClassName)
{
	local Class<UsableItem> UsableItemClass;

	UsableItemClass = Class<UsableItem>(DynamicFindObject(string(HypoClassName), Class'Core.Class'));
	AssertWithDescription(__NFUN_119__(UsableItemClass, none), __NFUN_112__(__NFUN_112__("The player attempted to equip a hypo of type '", string(HypoClassName)), "', but could not find the specified class."));
	ActiveUsableItem = UsableItemClass;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function bool UseHypoByClassName(name HypoClassName)
{
	local Class<UsableItem> UsableItemClass;
	local string HighlightString;

	UsableItemClass = Class<UsableItem>(DynamicFindObject(string(HypoClassName), Class'Core.Class'));
	AssertWithDescription(__NFUN_119__(UsableItemClass, none), __NFUN_112__(__NFUN_112__("The player attempted to use a hypo of type '", string(HypoClassName)), "', but could not find the specified class."));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x15C
	/*@Error*/
	InventoryManager.UseItem(UsableItemClass);
	HighlightString = __NFUN_112__("Highlight", string(HypoClassName));
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid(HighlightString);
	return true;
	return false;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function BeginInjectingEveHypo(BioAmmoHypoBase theHypo)
{
	CurrentHypo = theHypo;
	GetHands().UseBioAmmoHypo();
	return;
	@NULL
	Item
}

function UseActiveUsableItem()
{
	// End:0x52
	if(__NFUN_129__(IsBusy()))
	{
		// End:0x52
		if(InventoryManager.CanUseItem(ActiveUsableItem))
		{
			InventoryManager.UseItem(ActiveUsableItem);
			return;
			@NULL
			Item
			Item
		}
	}
	@NULL
}

function OnMovieEvent(name Event, MovieEventData Data)
{
	//native.Event;
	//native.Data;	
	@NULL
	@NULL
}

function string GetQuestFriendlyName(name QuestName)
{
	//native.QuestName;	
	@NULL
}

function bool InitiateQuest(name QuestName, bool PlayGivenQuestEffect)
{
	local bool initiatedQuest;

	// End:0x44
	if(__NFUN_119__(QuestManager, none))
	{
		initiatedQuest = QuestManager.InitiateQuest(QuestName, PlayGivenQuestEffect);
		DumpQuests();
		return initiatedQuest;
		return;
		@NULL
	}
	Item
	default.Item
	@NULL
}

function ReplaceQuest(name QuestName, name ReplacementName, bool CopyObjectivesCompleted, bool PlayGivenQuestEffect)
{
	// End:0x4C
	if(__NFUN_119__(QuestManager, none))
	{
		QuestManager.ReplaceQuest(QuestName, ReplacementName, CopyObjectivesCompleted, PlayGivenQuestEffect);
		DumpQuests();
		return;
		@NULL
		Item
		default.Item
	}
	@NULL
}

function SetQuestActive(name QuestName, bool Active)
{
	// End:0x39
	if(__NFUN_119__(QuestManager, none))
	{
		QuestManager.SetQuestActive(QuestName, Active);
		DumpQuests();
		return;
		@NULL
	}
	Item
	default.Item
	@NULL
}

function ToggleQuestVisibility(name QuestName)
{
	// End:0x2F
	if(__NFUN_119__(QuestManager, none))
	{
		QuestManager.ToggleQuestVisibility(QuestName);
		DumpQuests();
		return;
	}
	@NULL
	Item
	default.Item
}

function OnCompletedQuestObjective(name QuestName, int NumberCompleted, bool PlayGivenQuestEffect)
{
	// End:0x42
	if(__NFUN_119__(QuestManager, none))
	{
		QuestManager.OnCompletedQuestObjective(QuestName, NumberCompleted, PlayGivenQuestEffect);
		DumpQuests();
		return;
		@NULL
		Item
	}
	default.Item
	@NULL
}

function OnUnCompletedQuestObjective(name QuestName, bool PlayGivenQuestEffect)
{
	// End:0x39
	if(__NFUN_119__(QuestManager, none))
	{
		QuestManager.OnUnCompletedQuestObjective(QuestName, PlayGivenQuestEffect);
		DumpQuests();
		return;
		@NULL
	}
	Item
	default.Item
	@NULL
}

function CompleteQuest(name QuestName, bool PlayGivenQuestEffect)
{
	// End:0x39
	if(__NFUN_119__(QuestManager, none))
	{
		QuestManager.CompleteQuest(QuestName, PlayGivenQuestEffect);
		DumpQuests();
		return;
		@NULL
	}
	Item
	default.Item
	@NULL
}

function FailQuest(name QuestName, bool PlayGivenQuestEffect)
{
	// End:0x39
	if(__NFUN_119__(QuestManager, none))
	{
		QuestManager.FailQuest(QuestName, PlayGivenQuestEffect);
		DumpQuests();
		return;
		@NULL
	}
	Item
	default.Item
	@NULL
}

function Quest GetQuest(name QuestName)
{
	return QuestManager.GetQuest(QuestName);
	return;
	@NULL
	Item
}

function AddLogEntry(Class<QuestLog> newEntry)
{
	local QuestLog QuestEntry;
	local int i, logIndex;
	local JournalEntry JournalEntry;

	log(,, __NFUN_112__(__NFUN_112__(string(self), "::AddLogEntry()... newEntry = "), string(newEntry)));
	assert(__NFUN_119__(newEntry, none));
	// End:0x126
	if(__NFUN_258__(newEntry, Class'ShockGame.CraftingFormula'))
	{
		AssertWithDescription(__NFUN_151__(newEntry.default.Entry.Length, 0), __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("QuestLog ", string(newEntry)), " has not been configured.  Please add the Entry=<description> line under section ["), string(newEntry)), "] in Content/System/Crafting.ini"));
		goto J0x1EA;
		AssertWithDescription(__NFUN_151__(newEntry.default.Entry.Length, 0), __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("QuestLog ", string(newEntry)), " has not been configured.  Please add the Entry=<description> line under section ["), string(newEntry)), "] in Content/System/QuestLogs.ini"));
	}
	QuestEntry = QuestLog(ShockGameInfo(Level.Game).GetItemFromClass(newEntry));
	logIndex = 0;
	J0x1EA:

	// End:0x2E9
	if(__NFUN_150__(logIndex, JournalEntries.Length))
	{
		// End:0x2DB
		if(__NFUN_254__(QuestLog(ShockGameInfo(Level.Game).GetItemFromClass(JournalEntries[i].LogClass)).Name, QuestEntry.Name))
		{
			goto J0x2E9;
			__NFUN_163__(logIndex);
			// [Loop Continue]
			goto J0x23E;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x525
			/*@Error*/
			// End:0x3CC
			if(__NFUN_154__(logIndex, JournalEntries.Length))
			{
				JournalEntry.LogClass = newEntry;
				JournalEntries[JournalEntries.Length] = JournalEntry;
				// End:0x3CC
				if(__NFUN_129__(QuestEntry.AutoPlayWhenReceived))
				{
					UnplayedJournalEntryIndex = __NFUN_147__(JournalEntries.Length, 1);
					ShockPlayerController(Level.GetLocalPlayerController()).GetPlayerStatsManager().PickedUpUnplayedLog();
				}
			}
			// End:0x406
			if(QuestEntry.AutoPlayWhenReceived)
			{
				PlayLogEntry(JournalEntries[logIndex]);
				goto J0x525;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x475
				/*@Error*/
				Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodString("ShowUnreadLogsIndicator", "");
				goto J0x525;
				Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodString("ShowUnreadLogsIndicator", Level.GetFlashGUIController().SubstituteKeyMappingTags(" <Mapping=PlayOldestUnreadLog> ", "PlayOldestUnreadLog"));
			}
		}
	}
	DumpJournal();
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function int NumLogsPickedup()
{
	local int Count, i;

	Count = 0;
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x86
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x78
	/*@Error*/
	__NFUN_163__(Count);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x16;
	return Count;
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayLogEntryAtIndex(int EntryIndex)
{
	assert(__NFUN_119__(JournalEntries[EntryIndex].LogClass, none));
	PlayLogEntry(JournalEntries[EntryIndex]);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function PlayLogEntry(out JournalEntry Entry)
{
	local QuestLog QuestEntry;
	local EffectEventInfo Info;
	local int i;
	local bool InGameManual;

	// End:0x37
	if(__NFUN_254__(CurrentlyPlayingLogName, Entry.LogClass.default.EffectTag))
	{
		return;
		QuestEntry = QuestLog(ShockGameInfo(Level.Game).GetItemFromClass(Entry.LogClass));
	}
	InGameManual = __NFUN_254__(Level.GetFlashGUIController().GetTopPlayingMovie().Name, 'InGameManual');
	// End:0x1EA
	if(__NFUN_254__(CurrentlyPlayingLogType, 'Radio'))
	{
		// End:0x17D
		if(__NFUN_129__(InGameManual))
		{
			i = 0;
			// End:0x15A
			if(__NFUN_150__(i, QueuedJournalEntries.Length))
			{
				// End:0x14C
				if(QueuedJournalEntries[i] == Entry)
				{
					return;
					__NFUN_165__(i);
					goto J0x10A;
					QueuedJournalEntries[QueuedJournalEntries.Length] = Entry;
					return;
					goto J0x1EA;
					i = 0;
					// End:0x1EA
					if(__NFUN_150__(i, QueuedJournalEntries.Length))
					{
						// End:0x1DC
						if(QueuedJournalEntries[i] == Entry)
						{
							QueuedJournalEntries.Remove(i, 1);
							__NFUN_165__(i);
							goto J0x188;
							log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::PlayLogEntry() ... Entry.Played = "), string(Entry.Played)), ", Entry.LogClass = "), string(Entry.LogClass)));
						}
					}
				}
				// End:0x2E9
				if(__NFUN_129__(Entry.Played))
				{
					Entry.Played = true;
				}
				ShockPlayerController(Level.GetLocalPlayerController()).GetPlayerStatsManager().PlayedAllLogs();
			}
		}
		// End:0x3E9
		if(__NFUN_254__(QuestEntry.LogType, 'Log'))
		{
			Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodStringString("SetLogPhoto", string(QuestEntry.Creator), QuestEntry.CreatorFriendlyName);
			Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodString("SetPhotoString", QuestEntry.FriendlyName);
			goto J0x4E8;
			// End:0x4E8
			if(__NFUN_254__(QuestEntry.LogType, 'Radio'))
			{
			}
			Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodStringString("SetRadioPhoto", string(QuestEntry.Creator), QuestEntry.CreatorFriendlyName);
			Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodString("SetPhotoString", QuestEntry.FriendlyName);
			Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodInt("SetDialogSubtitles", int(Level.GetGameDriver().GetUserSettings().GetDialogSubtitlesSetting()));
		}
		Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("HideUnreadLogsIndicator");
		NotifyAudioSubsystemLogBegan();
		CurrentlyPlayingLogName = Entry.LogClass.default.EffectTag;
		CurrentlyPlayingLog = none;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x65E
		/*@Error*/
		CurrentlyPlayingLogType = 'Radio';
		goto J0x67E;
		CurrentlyPlayingLogType = QuestEntry.LogType;
	}
	Info = Class'Engine.EffectEventInfo'.static.Allocate(self, GetTransientPackage(),, 134217728).;
	Construct_Void();
	Info.SubtitleSpeaker = Entry.LogClass.default.CreatorFriendlyName;
	Info.SubtitleType = CurrentlyPlayingLogType;
	TriggerEffectEvent('LogPlayed',,,,,,, self, Entry.LogClass.default.EffectTag, Info);
	Info.__NFUN_200__();
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayMostRecentLogEntry()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x59
	/*@Error*/
	assert(__NFUN_130__(__NFUN_153__(UnplayedJournalEntryIndex, 0), __NFUN_150__(UnplayedJournalEntryIndex, JournalEntries.Length)));
	PlayLogEntry(JournalEntries[UnplayedJournalEntryIndex]);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function bool IsCriticalLogPlaying()
{
	local int logIndex;

	// End:0x19
	if(__NFUN_254__(CurrentlyPlayingLogName, 'None'))
	{
		return false;
		logIndex = 0;
	}
	// End:0xC6
	if(__NFUN_150__(logIndex, JournalEntries.Length))
	{
		// End:0xB8
		if(__NFUN_254__(JournalEntries[logIndex].LogClass.default.EffectTag, CurrentlyPlayingLogName))
		{
			return __NFUN_254__(JournalEntries[logIndex].LogClass.default.LogType, 'Radio');
			__NFUN_163__(logIndex);
			// [Loop Continue]
			goto J0x24;
			AssertWithDescription(false, __NFUN_112__(__NFUN_112__("Log '", string(CurrentlyPlayingLogName)), "' was playing but could not be found in the JournalEntries for the playeer."));
		}
	}
	return false;
	return;
	@NULL
	Item
	Item
	@NULL
}

function DumpJournal()
{
	local int i, j;

	// End:0x1C
	if(__NFUN_129__(ShouldLog('Inventory', 4)))
	{
		return;
		log('Testing', 3, "********************************************************");
	}
	log('Testing', 3, "*** Dumping Player Journal ***");
	i = __NFUN_147__(JournalEntries.Length, 1);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1EC
	/*@Error*/
	log('Testing', 3, "");
	log('Testing', 3, __NFUN_112__(__NFUN_112__("=== ", string(JournalEntries[i].LogClass)), " ==="));
	j = 0;
	// End:0x1AF
	if(__NFUN_150__(j, JournalEntries[i].LogClass.default.Entry.Length))
	{
		log(,, JournalEntries[i].LogClass.default.Entry[j]);
		__NFUN_165__(j);
		// [Loop Continue]
		goto J0x11F;
		log('Testing', 3, "=============================");
		__NFUN_166__(i);
		// [Loop Continue]
		goto J0xAD;
		log('Testing', 3, "********************************************************");
	}
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function TriggerDamageIndicatorsFromActor(Actor Damager)
{
	//native.Damager;	
	@NULL
}

function OnDamaged(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, bool bIsCriticalHit, optional name HitHighBone, optional name HitLowBone)
{
	local ShockPawn ShockPawnDamager;

	super.OnDamaged(DamageStimuli, TotalDamageDealt, Damager, HitLocation, HitNormal, HitImpulseDirection, EffectEventName, bIsCriticalHit, HitHighBone, HitLowBone);
	// End:0xB4
	if(__NFUN_132__(__NFUN_114__(DamageStimuli, none), __NFUN_130__(__NFUN_154__(DamageStimuli.Stimulus.Length, 1), DamageStimuli.HasDamageStimulusType(36))))
	{
		goto J0x1B0;
		// End:0x112
		if(IsInSanctuary())
		{
			// End:0x10F
			if(__NFUN_119__(SanctuaryModel, none))
			{
				SanctuaryModel.TriggerWeaponImpactedEvent(Damager, none, HitLocation, Rotator(HitNormal), 'None', false);
			}
			goto J0x1B0;
			// End:0x162
			if(__NFUN_119__(GetHands(), none))
			{
				GetHands().TriggerWeaponImpactedEvent(Damager, none, HitLocation, Rotator(HitNormal), 'None', false);
				// End:0x1B0
				if(__NFUN_119__(ActiveHoldable, none))
				{
				}
				ActiveHoldable.TriggerWeaponImpactedEvent(Damager, none, HitLocation, Rotator(HitNormal), 'None', false);
			}
			// End:0x1FF
			if(__NFUN_177__(TotalDamageDealt, 0.0000000))
			{
				InterruptGathererInteraction();
				ShockPlayerController(Controller).ReactToDamage(EffectEventName, Damager);
			}
			ShockPawnDamager = ShockPawn(Damager);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x2C3
			/*@Error*/
		}
	}
	NotifyWatchersPlayerIsBeingAttacked(ShockPawnDamager);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2FB
	/*@Error*/
	CurrentStation.FinishInteraction(false);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x321
	/*@Error*/
	TriggerDamageIndicatorsFromActor(Damager);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function OnKilled(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, bool bIsCriticalHit, optional name HitHighBone, optional name HitLowBone)
{
	super.OnKilled(DamageStimuli, TotalDamageDealt, Damager, HitLocation, HitNormal, HitImpulseDirection, EffectEventName, bIsCriticalHit, HitHighBone, HitLowBone);
	log('Log', 3, __NFUN_112__("Player was killed by ", string(Damager.Name)));
	Level.GetFlashGUIController().StopAllMovies();
	PlayerController(Controller).SetPause(false);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x131
	/*@Error*/
	ShockPlayerController(Controller).ReactToDamage(EffectEventName, Damager);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function OnDealtDamage(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damagee, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, bool bIsCriticalHit, optional name HitHighBone, optional name HitLowBone)
{
	local ShockPawn PawnDamagee;
	local int i;

	super.OnDealtDamage(DamageStimuli, TotalDamageDealt, Damagee, HitLocation, HitNormal, HitImpulseDirection, EffectEventName, bIsCriticalHit, HitHighBone, HitLowBone);
	PawnDamagee = ShockPawn(Damagee);
	// End:0x102
	if(__NFUN_130__(__NFUN_130__(Class'Engine.Pawn'.static.checkAlive(EscortedGatherer), Class'Engine.Pawn'.static.checkAlive(PawnDamagee)), __NFUN_119__(PawnDamagee, EscortedGatherer)))
	{
		EscortedGatherer.NotifyEscortIsAttacking(PawnDamagee);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x277
		/*@Error*/
	}
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x277
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x269
	/*@Error*/
	AddPersistentEffectsSystemContext('BloodLustActive');
	AddHealth(ModifyStat('BloodLustHealth_Bonus', 0.0000000));
	AddBioAmmo(ModifyStat('BloodLustBioAmmo_Bonus', 0.0000000));
	RemovePersistentEffectsSystemContext('BloodLustActive');
	goto J0x277;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x19B;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2AE
	/*@Error*/
	NotifyPlayerAttacksWatcherThatPlayerAttacked(PawnDamagee);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function OnDeathPrevented()
{
	dispatchMessage(Class'ShockGame.MessageDeathPrevented'.static.Allocate(self)., Construct_Void());
	return;
	@NULL
}

function SetLowHealthInvulnerabilityLevelTime(float newTime)
{
	LowHealthInvulnerabilityLevelTime = newTime;
	return;
	@NULL
	Item
}

function ShockMachine GetCurrentStation()
{
	return CurrentStation;
	return;
	@NULL
}

function OnUseFocusChanged(ICanBeUsed OldFocus, ICanBeUsed NewFocus)
{
	return;
}

function PrepareToDie()
{
	local Coords PlayerStartCoords;

	// End:0x28
	if(GetHands().InWeaponsMode())
	{
		CeaseFiring();		
	}
	else
	{
		UseActiveAbilityRelease();
	}
	ShockPlayerController(Controller).StopForcePlayerMove();
	ShockPlayerController(Controller).SetHeadbobContextState(2, false);
	UnTriggerEffectEvent('PlayerZoomed');
	PlayerController(Controller).DesiredFOV = PlayerController(Controller).DefaultFOV;
	PlayerController(Controller).ForegroundFovAngle = PlayerController(Controller).DefaultForegroundFOV;
	GamepadPlayerInput(ShockPlayerController(Controller).GetInput()).UpdateZoomedLookModifier(1.0000000);
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodString("WeaponZoomedOut", string(GetActiveHoldable().Class.Name));
	// End:0x1CF
	if(__NFUN_119__(GetCurrentContainer(), none))
	{
		CloseContainer();
		Level.SpawningManager.ResetAIAggressionTowards(self);
		ShockPlayerController(Controller).ForceUnPause();
		ShockPlayerController(Controller).bDisablePause = true;
		// End:0x298
		if(__NFUN_119__(Level.GetFlashGUIController().GetPlayingMovie('Pause'), none))
		{
		}
		Level.GetFlashGUIController().StopMovie('Pause');
		Controller.ConsoleCommand("PUSHINPUTCONTEXT NullInput");
		ShowHandsWhenResurrected = __NFUN_129__(GetHands().bHidden);
		GetHands().InterruptStateTransitionExecution();
		__NFUN_3970__(0);
		HavokQuitActor();
		ClosestResurrectionStation = Class'ShockGame.BaseResurrectionStation'.static.GetClosestStation(self);
	}
	PlayerStartCoords = ClosestResurrectionStation.GetPlayerStartCoords();
	TeleportBeaconLocation = PlayerStartCoords.Origin;
	TeleportBeaconRotation = OrthoRotation(PlayerStartCoords.XAxis, PlayerStartCoords.YAxis, PlayerStartCoords.ZAxis);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PrepareToResurrect()
{
	local float EveToRestore;

	ResetPawnDeathListenersNotification();
	HavokInitActor();
	__NFUN_3970__(2);
	ShouldNotTakeDamageOnNextLanding = true;
	// End:0xA7
	if(__NFUN_152__(GetNumberOfItems(Class'ShockGame.BioAmmoHypoBase'), 0))
	{
		EveToRestore = __NFUN_175__(__NFUN_171__(__NFUN_171__(EveBarPercentageToRestoreOnRessurection, ModifyStat('RessurectionEveGain_PercentBonus', 1.0000000)), GetMaxBioAmmo()), GetBioAmmo());
		// End:0xA7
		if(__NFUN_177__(EveToRestore, float(0)))
		{
			AddBioAmmo(EveToRestore);
			LowHealthInvulnerabilityLevelTime = 0.0000000;
			LowHealthInvulnerabilityLevelResetTime = 0.0000000;
			LowHealthInvulnerabilityLevelHealthNeededToReset = 0.0000000;
		}
	}
	ExtinguishPlayerFires();
	Level.SpawningManager.ResetAIAggressionTowards(self);
	ResetUIState();
	ResetCurrentHandMode();
	// End:0x13C
	if(ShowHandsWhenResurrected)
	{
		GetHands().Show();
		ShockPlayerController(Controller).bDisablePause = false;
		Controller.ConsoleCommand("POPINPUTCONTEXT NullInput");
	}
	ShockPlayerController(Controller).InitCameraAnims();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1D7
	/*@Error*/
	EscortedGatherer.UpdateEscortedGathererHealth();
	TeleportBeaconSet = true;
	ShockPlayerController(Controller).GetPlayerStatsManager().PlayerUsedVita(self);
	return;
	@NULL
	Item
	Item
	@NULL
}

// Export UShockPlayer::execResetPawnDeathListenersNotification(FFrame&, void* const)
native function ResetPawnDeathListenersNotification();

// Export UShockPlayer::execExtinguishPlayerFires(FFrame&, void* const)
native function ExtinguishPlayerFires();

function CloseAllResurrectionStationDoors()
{
	local BaseResurrectionStation Station;

	// End:0x30
	foreach __NFUN_304__(Class'ShockGame.BaseResurrectionStation', Station)
	{
		Station.SetDoorsClosed();				
		return;
		@NULL
		Item
	}
	Item
}

function TriggerDiedEffectEvent()
{
	local name DiedTag;

	// End:0x20
	if(bIsCrouched)
	{
		DiedTag = 'IsCrouched';
		TriggerEffectEvent('Died',,,,,,,, DiedTag);
	}
	return;
	@NULL
	Item
	ShockPawn
}

function SwitchToDLCEndMenu(bool bFailedLevel)
{
	//native.bFailedLevel;	
	@NULL
}

function bool RejectTrophies()
{
	return false;
	return;
}

// Export UShockPlayer::execGenerateTeleportPathNodeList(FFrame&, void* const)
native function GenerateTeleportPathNodeList();

function SmoothTeleportMovement(Vector NewLocation, int CurPathNodeIndex, bool SetRotation, bool UseBeaconRotation)
{
	//native.NewLocation;
	//native.CurPathNodeIndex;
	//native.SetRotation;
	//native.UseBeaconRotation;	
	@NULL
	@NULL
	return default.@NULL;
}

// Export UShockPlayer::execTeleport(FFrame&, void* const)
native function Teleport();

function UpdateInventorySize()
{
	local int newInventorySize, currentInventorySize;

	newInventorySize = int(ModifyStat('InventorySize_Bonus', float(BaseInventorySize)));
	currentInventorySize = InventoryManager.GetNumUnlockedSlots();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x8D
	/*@Error*/
	InventoryManager.UnlockSlots(__NFUN_147__(newInventorySize, currentInventorySize));
	return;
	@NULL
	Item
	Item
	@NULL
}

function TestAddAvailablePlasmid(name newPlasmid)
{
	local bool OldDisableInventoryWarnings;

	// End:0x95
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'TestAddAvailablePlasmid', but that command is disabled in the CENSORED version.");
		goto J0x13B;
		log('Testing', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::TestAddAvailablePlasmid( "), string(newPlasmid)), " )"));
	}
	OldDisableInventoryWarnings = disableInventoryWarnings;
	disableInventoryWarnings = true;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x126
	/*@Error*/
	AddAvailablePlasmid(newPlasmid);
	disableInventoryWarnings = OldDisableInventoryWarnings;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function TestRemoveAvailablePlasmid(name newPlasmid)
{
	log('Testing', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::TestRemoveAvailablePlasmid( "), string(newPlasmid)), " )"));
	// End:0x71
	if(IsPlasmidAvailable(newPlasmid))
	{
		RemoveAvailablePlasmid(newPlasmid);
		return;
		@NULL
		Item
	}
	default.Item
}

function TestEquipPlasmid(name newPlasmid, int Slot)
{
	local bool OldDisableInventoryWarnings;

	log('Testing', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::TestEquipPlasmid( "), string(newPlasmid)), ", "), string(Slot)), " )"));
	OldDisableInventoryWarnings = disableInventoryWarnings;
	disableInventoryWarnings = true;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA6
	/*@Error*/
	EquipPlasmid(newPlasmid, Slot);
	disableInventoryWarnings = OldDisableInventoryWarnings;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function TestUnEquipPlasmid(name newPlasmid)
{
	log('Testing', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::TestUnEquipPlasmid( "), string(newPlasmid)), " )"));
	// End:0x69
	if(IsPlasmidEquipped(newPlasmid))
	{
		UnEquipPlasmid(newPlasmid);
		return;
		@NULL
		Item
	}
	default.Item
}

function TestUnlockTrackSlot(int Track)
{
	// End:0x91
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'TestUnlockTrackSlot', but that command is disabled in the CENSORED version.");
		goto J0x103;
		log('Testing', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::TestUnlockTrackSlot( "), string(Track)), " )"));
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x103
	/*@Error*/
	UnlockTrackSlot(byte(Track));
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function TestLockTrackSlot(int Track)
{
	log('Testing', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::TestLockTrackSlot( "), string(Track)), " )"));
	LockTrackSlot(byte(Track));
	return;
	@NULL
	Item
}

exec function TestUnEquipAllPlasmids()
{
	log('Testing', 4, __NFUN_112__(string(self), "::TestUnEquipAllPlasmids()"));
	UnEquipAllPlasmids();
	return;
}

function DumpPlasmids()
{
	// End:0x1C
	if(__NFUN_129__(ShouldLog('Plasmids', 4)))
	{
		return;
		log('Testing', 4, __NFUN_112__(string(self), "::DumpPlasmids()"));
	}
	PlasmidManager.DumpPlasmids();
	return;
	@NULL
	Item
}

function bool CanUseContainer(Container theContainer)
{
	return __NFUN_130__(__NFUN_119__(theContainer, none), __NFUN_132__(__NFUN_132__(__NFUN_129__(theContainer.HasPlayerSearched()), __NFUN_129__(theContainer.IsEmpty())), __NFUN_130__(__NFUN_129__(theContainer.HasEverInteracted()), __NFUN_176__(float(theContainer.GetNumTimesRolled()), ModifyStat('ReRollContainer_Bonus', 1.0000000)))));
	return;
	@NULL
	Item
	Item
	@NULL
}

function ReRollContainer()
{
	log('Testing', 4, __NFUN_112__(string(self), "::ReRollContainer()"));
	// End:0xA4
	if(InventoryManager.CanReRoll())
	{
		log('Testing', 3, ".... Re-Rolling ...");
		InventoryManager.ReRollContainer();
		InventoryManager.DumpInventorySystem();
		DumpResources();
		goto J0xC9;
		log('Testing', 3, "... Cannot re-roll!");
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x105
	/*@Error*/
	ShockPlayerController(Controller).HideReRollText();
	return;
	@NULL
	Item
	default.Item
	@NULL
}

exec function ResetOptions()
{
	ResetOptionScreen();
	return;
}

// Export UShockPlayer::execResetOptionScreen(FFrame&, void* const)
native function ResetOptionScreen();

function OpenInventory()
{
	log('Testing', 4, __NFUN_112__(string(self), "::OpenInventory()"));
	InventoryManager.OpenInventory();
	InventoryManager.DumpInventorySystem();
	DumpResources();
	return;
	@NULL
	Item
}

function CloseInventory()
{
	log('Testing', 4, __NFUN_112__(string(self), "::CloseInventory()"));
	InventoryManager.CloseInventory();
	InventoryManager.DumpInventorySystem();
	DumpResources();
	return;
	@NULL
	Item
}

function ToggleInventory()
{
	log('Testing', 4, __NFUN_112__(string(self), "::ToggleInventory()"));
	// End:0x51
	if(InventoryManager.IsInventoryOpen())
	{
		CloseInventory();
		goto J0x5B;
		OpenInventory();
	}
	return;
	@NULL
}

function SwitchInventory()
{
	InventoryManager.SwitchInventory();
	return;
	@NULL
}

function DumpInventory()
{
	// End:0x1C
	if(__NFUN_129__(ShouldLog('Inventory', 4)))
	{
		return;
		log('Testing', 4, __NFUN_112__(string(self), "::DumpInventory()"));
	}
	InventoryManager.DumpInventorySystem();
	DumpResources();
	return;
	@NULL
	Item
}

function CloseContainer()
{
	InventoryManager.CloseContainer();
	return;
	@NULL
}

function UnlockInventorySlots(int Num)
{
	log('Testing', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::UnlockInventorySlots( "), string(Num)), " )"));
	InventoryManager.UnlockSlots(Num);
	DumpInventory();
	return;
	@NULL
	Item
	default.Item
}

function SelectSlot(int Slot)
{
	log('Testing', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::SelectSlot( "), string(Slot)), " )"));
	InventoryManager.SetSelectedSlot(Slot);
	DumpInventory();
	return;
	@NULL
	Item
	default.Item
}

function UseSelectedInventoryItem()
{
	log('Testing', 4, __NFUN_112__(string(self), "::UseSelectedInventoryItem()"));
	InventoryManager.UseSelectedInventoryItem();
	DumpInventory();
	return;
	@NULL
}

function RecycleOrDestroySelectedInventoryItem()
{
	log('Testing', 4, __NFUN_112__(string(self), "::RecycleOrDestroySelectedInventoryItem()"));
	InventoryManager.RecycleOrDestroySelectedInventoryItem();
	DumpInventory();
	return;
	@NULL
}

function RecycleOrDestroyContainerSlot(int Slot)
{
	log('Testing', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::RecycleOrDestroyContainerSlot( "), string(Slot)), " )"));
	InventoryManager.RecycleOrDestroyContainerSlot(Slot);
	DumpInventory();
	return;
	@NULL
	Item
	Item
}

function TakeSlot(int Slot)
{
	log('Testing', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::TakeSlot( "), string(Slot)), " )"));
	InventoryManager.SelectContainerSlot(Slot);
	return;
	@NULL
	Item
	Item
}

function TakeAll()
{
	log('Testing', 4, __NFUN_112__(string(self), "::TakeAll()"));
	TakeAllIndex = 0;
	TakeAllTimerDelegate();
	return;
	@NULL
}

function TakeAllTimerDelegate()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x118
	/*@Error*/
	J0x10:

	// End:0x64 [Loop If]
	if(__NFUN_130__(__NFUN_150__(TakeAllIndex, Class'ShockGame.Container'.3), __NFUN_114__(GetCurrentContainer().GetItem(TakeAllIndex), none)))
	{
		__NFUN_165__(TakeAllIndex);
		// [Loop Continue]
		goto J0x10;
		// End:0x8D
		if(__NFUN_153__(TakeAllIndex, Class'ShockGame.Container'.3))
		{
		}/* !MISMATCHING REMOVE, tried Loop got Type:If Position:0x054! */
		StopTakingAll();
		return;
		TakeSlot(TakeAllIndex);
		__NFUN_165__(TakeAllIndex);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x10B
		/*@Error*/
	}/* !MISMATCHING REMOVE, tried If got Type:Loop Position:0x010! */
	TakeAllTimer.StartTimer(TakeAllDelayTime);
	TakeAllTimer.__TimerDelegate__Delegate = TakeAllTimerDelegate;
	goto J0x115;
	StopTakingAll();
	goto J0x122;
	StopTakingAll();
	return;
	@NULL
	Item
	Item
	@NULL
}

function StopTakingAll()
{
	// End:0x1A
	if(__NFUN_119__(GetCurrentContainer(), none))
	{
		CloseContainer();
	}
	TakeAllTimer.StopTimer();
	TakeAllTimer.__TimerDelegate__Delegate = None;
	DumpInventory();
	return;
	@NULL
	Item
	ShockPawn
}

function GiveItemClass(int Amount, Class<Item> ItemClass)
{
	local ItemStack theStack;

	theStack = Class'ShockGame.ItemStack'.static.Allocate(self).;
	Construct_Void();
	theStack.__NFUN_199__();
	theStack.ItemClass = ItemClass;
	theStack.StackSize = Amount;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA2
	/*@Error*/
	AddStackToInventory(theStack);
	theStack.__NFUN_198__();
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function GiveItem(int Amount, string ItemName)
{
	local Class<Item> ItemClass;

	// End:0x86
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'GiveItem', but that command is disabled in the CENSORED version.");
		goto J0x173;
		log('Testing', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::GiveItem( "), ItemName), ", "), string(Amount)), " )"));
	}
	ItemClass = Class<Item>(DynamicLoadObject(ItemName, Class'Core.Class'));
	AssertWithDescription(__NFUN_119__(ItemClass, none), __NFUN_112__(__NFUN_112__("Could not give item '", ItemName), "' to the player: invalid class."));
	GiveItemClass(Amount, ItemClass);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

exec function DumpResources()
{
	log('Testing', 3, "********************************************************");
	log('Testing', 3, "*** Dumping Player Resources ***");
	log('Testing', 3, "");
	log('Testing', 3, __NFUN_112__("   Credits = ", string(GetCredits())));
	log('Testing', 3, __NFUN_112__("   ADAM = ", string(GetADAM())));
	log('Testing', 3, __NFUN_112__("   Health = ", string(GetHealth())));
	log('Testing', 3, __NFUN_112__("   MaxHealth = ", string(GetMaxHealth())));
	log('Testing', 3, __NFUN_112__("   BioAmmo = ", string(GetBioAmmo())));
	log('Testing', 3, __NFUN_112__("   MaxBioAmmo = ", string(GetMaxBioAmmo())));
	log('Testing', 3, "********************************************************");
	return;
}

function DebugBallistics()
{
	log('Testing', 4, __NFUN_112__(string(self), "::DebugBallistics()"));
	ShockGameInfo(Level.Game).DebugBallistics = __NFUN_129__(ShockGameInfo(Level.Game).DebugBallistics);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function DebugBotMotion()
{
	log('Testing', 4, __NFUN_112__(string(self), "::DebugBotMotion()"));
	ShockGameInfo(Level.Game).DebugBotMotion = __NFUN_129__(ShockGameInfo(Level.Game).DebugBotMotion);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function DebugCanHit()
{
	log('Testing', 4, __NFUN_112__(string(self), "::DebugCanHit()"));
	ShockGameInfo(Level.Game).DebugCanHit = __NFUN_129__(ShockGameInfo(Level.Game).DebugCanHit);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

exec function TestUseActiveAbility()
{
	log('Testing', 4, __NFUN_112__(string(self), "::TestUseActiveAbility()"));
	UseActiveAbility();
	return;
}

function DumpQuests(optional bool bShowHidden, optional bool bShowCompleted)
{
	// End:0x1C
	if(__NFUN_129__(ShouldLog('Quests', 4)))
	{
		return;
		log('Testing', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::DumpQuests( "), string(bShowHidden)), ", "), string(bShowCompleted)), " )"));
	}
	QuestManager.DumpQuests(bShowHidden, bShowCompleted);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function DumpManualTopics(optional bool bShowHidden, optional bool bShowCompleted)
{
	log('Testing', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::DumpManualTopics( "), string(bShowHidden)), ", "), string(bShowCompleted)), " )"));
	InGameManualManager.DumpManualTopics(bShowHidden, bShowCompleted);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function AddWeaponStatUpgrade(name WeaponName, name StatName)
{
	local Weapon theWeapon;

	theWeapon = Weapon(GetHoldableByClassName(WeaponName));
	log('Testing', 1, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::AddWeaponStatUpgrade( "), string(WeaponName)), ", "), string(StatName)), " ) .... theWeapon = "), string(theWeapon)));
	theWeapon.AddStatUpgrade(StatName);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function TestApplyWeaponMods()
{
	local Weapon theWeapon;
	local array< Class<Item> > InventoryWeaponMods;
	local int i;
	local WeaponMod currentWeaponMod;

	log('Testing', 1, __NFUN_112__(string(self), "::TestApplyWeaponMods()"));
	GetInventoryClassesOfClass(Class'ShockGame.WeaponMod', InventoryWeaponMods);
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x195
	/*@Error*/
	currentWeaponMod = WeaponMod(ShockGameInfo(Level.Game).GetItemFromClass(InventoryWeaponMods[i]));
	assert(__NFUN_119__(currentWeaponMod, none));
	theWeapon = Weapon(GetHoldableByClassName(currentWeaponMod.WeaponClassToMod.Name));
	assert(__NFUN_119__(theWeapon, none));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x152
	/*@Error*/
	theWeapon.GiveAltFireMod();
	goto J0x169;
	theWeapon.GiveStrictlySuperiorMod();
	UseUpItem(InventoryWeaponMods[i], 1);
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x55;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function ShowPos()
{
	ShowPlayerPosition = __NFUN_129__(ShowPlayerPosition);
	return;
	@NULL
	Item
}

function LaunchInfoPanel()
{
	LaunchMapScreen();
	return;
}

function ShockDisplayDebug(Canvas Canvas)
{
	local Font OriginalFont;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x119
	/*@Error*/
	OriginalFont = Canvas.Font;
	Canvas.Font = Canvas.MedFont;
	Canvas.SetPos(float(__NFUN_147__(Canvas.SizeX, 400)), float(__NFUN_147__(Canvas.SizeY, 80)));
	Canvas.SetDrawColor(byte(255), byte(255), byte(255));
	Canvas.__NFUN_465__(__NFUN_112__("Location: ", string(Location)), false);
	Canvas.Font = OriginalFont;
	return;
	@NULL
	Item
	Item
	@NULL
}

function EnableTrainingLogs(bool Enable)
{
	ShockGameDriver(Level.GetGameDriver()).GetTrainingMessageManager().EnableTrainingLogs = Enable;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function EnableAdaptiveMessages(bool Enable)
{
	ShockGameDriver(Level.GetGameDriver()).GetTrainingMessageManager().EnableAdaptiveMessages = Enable;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function TestGetNextTip()
{
	local array<string> Tips;

	ShockGameDriver(Level.GetGameDriver()).GetTrainingMessageManager().SelectNextTip();
	ShockGameDriver(Level.GetGameDriver()).GetTrainingMessageManager().GetTips(Tips);
	log(,, Tips[0]);
	log(,, Tips[1]);
	log(,, Tips[2]);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function DumpConcept(name ConceptName)
{
	local TrainingScript S;
	local int i;
	local bool showAll;

	showAll = __NFUN_254__(ConceptName, 'None');
	// End:0x145
	foreach __NFUN_313__(Class'ShockGame.TrainingScript', S)
	{
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x144
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x136
		/*@Error*/
		SLog(__NFUN_168__(__NFUN_168__(__NFUN_168__("Concept", string(S.Concepts[i].ConceptName)), "Knowledge ="), string(S.Concepts[i].GetKnowledge())));
		__NFUN_165__(i);
		// [Loop Continue]
		goto J0x42;				
		return;
		@NULL
		Item
		default.Item
		@NULL
	}
}

// Export UShockPlayer::execDestroyManagedPlayerObjects(FFrame&, void* const)
native function DestroyManagedPlayerObjects();

function Destroyed()
{
	DestroyManagedPlayerObjects();
	Level.GetFlashLiaison().UnRegisterForAllMovieEvents(self);
	// End:0x5F
	if(__NFUN_119__(TakeAllTimer, none))
	{
		TakeAllTimer.__TimerDelegate__Delegate = None;
		super.Destroyed();
		return;
		@NULL
		Item
	}
	stop;
	default.@NULL
}

function PreLevelSave()
{
	super(Actor).PreLevelSave();
	GatherPersistentTrainingInfo();
	return;
	@NULL
}

function PostLoadGame()
{
	ResetUIState();
	// End:0x6A
	if(HudElementsDisabled)
	{
		Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("HideAllExceptMessages");
		InventoryManager.CheckDups();
	}
	RestorePersistentTrainingInfo();
	super.PostLoadGame();
	log(,, __NFUN_112__(string(self), "::PostLoadGame()"));
	DumpJournal();
	// End:0x11F
	if(ShockUserSettings(Level.GetGameDriver().GetUserSettings()).HasPlasmidPack_1)
	{
		InGameManualManager.UnhideManualTopic('PlasmidPack_1');
		goto J0x13F;
		InGameManualManager.HideManualTopic('PlasmidPack_1');
		Level.GetFlashGUIController().LoadPCOptionsFromUserSettings();
	}
	// End:0x195
	if(Level.GetFlashGUIController().ForceSavingGamePlusData)
	{
		__NFUN_280__(0.0100000, false);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x204
		/*@Error*/
		ShockUserSettings(Level.GetGameDriver().GetUserSettings()).ArtSubtitles = true;
	}
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function ResetUIHyposAndAmmos()
{
	InventoryManager.ResetUIState();
	return;
	@NULL
}

function ResetUIState()
{
	local int i;

	log(,, __NFUN_112__(string(self), "::ResetUIState()"));
	Level.GetFlashGUIController().PlayMovie('HUD');
	RegisterForMovieEventNotification();
	i = 0;
	// End:0xD3
	if(__NFUN_150__(i, Holdables.Length))
	{
		// End:0xC5
		if(Holdables[i].__NFUN_303__('Weapon'))
		{
			UIAddWeapon(Weapon(Holdables[i]));
			__NFUN_165__(i);
			// [Loop Continue]
			goto J0x61;
			i = 0;
			// End:0x121
			if(__NFUN_150__(i, AvailableAbilities.Length))
			{
				UIAddAbilityClass(AvailableAbilities[i]);
			}
		}
		__NFUN_165__(i);
		goto J0xDE;
		// End:0x143
		if(__NFUN_119__(ActiveAbility, none))
		{
			UISelectAbilityClass(ActiveAbility);
			InventoryManager.ResetUIState();
			UpdateUIStats();
			// End:0x1AD
			if(__NFUN_130__(__NFUN_119__(ActiveHoldable, none), ActiveHoldable.__NFUN_303__('Weapon')))
			{
			}
			UISelectWeapon(Weapon(ActiveHoldable));
		}
		UpdateUIAmmoTotals();
		ShockGameInfo(Level.Game).GetSecurityManager().UpdateAlarmUIState();
		Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("ShowWatermark");
	}
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function LaunchPCWeaponSelection()
{
	local int i;

	// End:0x92
	if(__NFUN_119__(Level.GetFlashGUIController().GetPlayingMovie('PCWeaponSelection'), none))
	{
		Level.GetFlashGUIController().StopMovie('PCWeaponSelection');
		ShockPlayerController(Controller).GetPlayerStatsManager().ClosePCWeaponSelectionMenu();
		return;
		// End:0xB6
		if(__NFUN_130__(__NFUN_154__(Holdables.Length, 0), __NFUN_154__(AvailableAbilities.Length, 0)))
		{
		}
		return;
		// End:0xE0
		if(Level.GetFlashGUIController().GetUseXBoxController())
		{
		}
		return;
		Level.GetFlashGUIController().PlayMovie('PCWeaponSelection');
		RegisterForMovieEventNotification();
	}
	PCWeaponSelectionRefresh();
	// End:0x16B
	if(__NFUN_130__(__NFUN_119__(ActiveHoldable, none), ActiveHoldable.__NFUN_303__('Weapon')))
	{
		UIPCSelectWeapon(Weapon(ActiveHoldable));
		i = 0;
		// End:0x1B9
		if(__NFUN_150__(i, AvailableAbilities.Length))
		{
			PCWeaponSelectionAddAbilityClass(AvailableAbilities[i]);
			__NFUN_165__(i);
			goto J0x176;
			Level.GetFlashGUIController().GetPlayingMovie('PCWeaponSelection').CallMethodVoid("FinishedAddingWeapons");
		}
		ShockPlayerController(Controller).GetPlayerStatsManager().OpenPCWeaponSelectionMenu();
	}
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function ResetUIAbilities()
{
	local int i;

	log(,, __NFUN_112__(string(self), "::ResetUIPlasmids()"));
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("EmptyAbility");
	i = 0;
	// End:0xB9
	if(__NFUN_150__(i, AvailableAbilities.Length))
	{
		UIAddAbilityClass(AvailableAbilities[i]);
		__NFUN_165__(i);
		// [Loop Continue]
		goto J0x76;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xDB
		/*@Error*/
		UISelectAbilityClass(ActiveAbility);
		return;
		@NULL
	}
	Item
	Item
	@NULL
}

// Export UShockPlayer::execRegisterForMovieEventNotification(FFrame&, void* const)
native function RegisterForMovieEventNotification();

function SetEscortedGathererHealth(float gathererHealth)
{
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodInt("EscortedGathererHealth", int(gathererHealth));
	return;
	@NULL
	Item
	Item
}

function SetEscortedGathererDied()
{
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("EscortedGathererDied");
	return;
	@NULL
	Item
}

function OnEffectStarted(Actor inStartedEffect)
{
	// End:0x75
	if(__NFUN_119__(CurrentlyPlayingLog, none))
	{
		log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " OnEffectStarted: About to replace "), string(inStartedEffect)), ", which is currently playing"));
		log(,, __NFUN_112__(__NFUN_112__(string(Name), " OnEffectStarted: Setting CurrentlyPlayingLog to "), string(inStartedEffect)));
	}
	CurrentlyPlayingLog = inStartedEffect;
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnScreenEffectStarted(ReferenceCountedObject inStartedEffect)
{
	return;
}

function OnScreenEffectStopped(ReferenceCountedObject inStoppedEffect)
{
	return;
}

function OnEffectStopped(Actor inStoppedEffect, bool Completed)
{
	local int i;

	log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " OnEffectStopped - inStoppedEffect: "), string(inStoppedEffect)), " Completed: "), string(Completed)), " CurrentlyPlayingLog= "), string(CurrentlyPlayingLog)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x21D
	/*@Error*/
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("ClearLogPhoto");
	NotifyAudioSubsystemLogEnded();
	CurrentlyPlayingLog = none;
	CurrentlyPlayingLogName = 'None';
	CurrentlyPlayingLogType = 'None';
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x21D
	/*@Error*/
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1FC
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1EE
	/*@Error*/
	PlayLogEntry(QueuedJournalEntries[i]);
	QueuedJournalEntries.Remove(i, 1);
	return;
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x164;
	PlayLogEntry(QueuedJournalEntries[0]);
	QueuedJournalEntries.Remove(0, 1);
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnEffectInitialized(Actor inInitializedEffect)
{
	return;
}

function AdjustPlayerFootstepSoundVolume(Actor FootStepSoundInstance)
{
	local SoundInstance TheSoundInstance;
	local float SpeedAlpha;

	TheSoundInstance = SoundInstance(FootStepSoundInstance);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xDB
	/*@Error*/
	// End:0x7C
	if(__NFUN_155__(int(Physics), int(2)))
	{
		TheSoundInstance.SetVolumeMultiplier(0.0000000);
		goto J0xDB;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xDB
		/*@Error*/
		SpeedAlpha = __NFUN_246__(__NFUN_172__(__NFUN_225__(Velocity), default.GroundSpeed), 0.0000000, 1.0000000);
	}
	TheSoundInstance.SetVolumeMultiplier(SpeedAlpha);
	return;
	@NULL
	Item
	Item
	@NULL
}

simulated event Rotator ViewRotationOffset()
{
	return GetLeanRotationOffset();
	return;
}

simulated event Vector ViewLocationOffset(Rotator CameraRotation)
{
	return GetLeanPositionOffset();
	return;
}

function Lean(ShockPlayer.ELeanState inLeanState)
{
	//native.inLeanState;	
	@NULL
}

// Export UShockPlayer::execUnLean(FFrame&, void* const)
native function UnLean();

function float GetYawEdgeAlpha(int Pitch)
{
	//native.Pitch;	
	@NULL
}

function ShouldLeanLeft(bool Lean)
{
	bWantsToLeanLeft = Lean;
	return;
	@NULL
	Item
}

function ShouldLeanRight(bool Lean)
{
	bWantsToLeanRight = Lean;
	return;
	@NULL
	Item
}

function OnLeanStateChange()
{
	ShockPlayerController(Controller).GetPlayerStatsManager().PlayerLeaned();
	return;
	@NULL
	Item
}

function GetLeanYawRanges(out int LeftYawLimit, out int RightYawLimit)
{
	//native.LeftYawLimit;
	//native.RightYawLimit;	
	@NULL
	@NULL
}

function bool CanLean(ShockPlayer.ELeanState inLeanState, Vector testLocation, Rotator testRotation)
{
	//native.inLeanState;
	//native.testLocation;
	//native.testRotation;	
	@NULL
	@NULL
	return default.@NULL;
}

// Export UShockPlayer::execGetLeanPositionOffset(FFrame&, void* const)
native function Vector GetLeanPositionOffset();

// Export UShockPlayer::execGetLeanRotationOffset(FFrame&, void* const)
native function Rotator GetLeanRotationOffset();

// Export UShockPlayer::execTrainingInitialization(FFrame&, void* const)
native function TrainingInitialization();

function AttachTrainingScript(TrainingScript Script)
{
	local int i;

	i = 0;
	// End:0x54
	if(__NFUN_150__(i, TrainingScripts.Length))
	{
		// End:0x46
		if(__NFUN_114__(TrainingScripts[i], Script))
		{
			return;
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x0B;
			TrainingScripts[TrainingScripts.Length] = Script;
		}
		return;
		@NULL
		Item
	}
	Item
	@NULL
}

function GatherPersistentTrainingInfo()
{
	local ShockGameDriver ShockGameDriver;
	local FactDatabase FactDatabase;
	local DifficultyStatsManager DifficultyStatsManager;

	ShockGameDriver = ShockGameDriver(Level.GetGameDriver());
	GameplayTime = ShockGameDriver.GetPlayerStatsManager().GetGameplayTime();
	FactDatabase = ShockGameDriver.GetFactDatabase();
	FactDatabase.GetPersistentFacts(PersistentFacts);
	DifficultyStatsManager = ShockGameDriver.GetDifficultyManager().DifficultyStatsManager;
	DifficultyStatsManager.GatherPersistentStats(PersistentDifficultyStats);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function RestorePersistentTrainingInfo()
{
	local ShockGameDriver ShockGameDriver;
	local FactDatabase FactDatabase;
	local DifficultyStatsManager DifficultyStatsManager;

	ShockGameDriver = ShockGameDriver(Level.GetGameDriver());
	FactDatabase = ShockGameDriver.GetFactDatabase();
	FactDatabase.RestorePersistentFacts(PersistentFacts);
	ShockGameDriver.GetPlayerStatsManager().SetGameplayTime(GameplayTime);
	DifficultyStatsManager = ShockGameDriver.GetDifficultyManager().DifficultyStatsManager;
	DifficultyStatsManager.RestorePersistentStats(PersistentDifficultyStats);
	return;
	@NULL
	Item
	Item
	@NULL
}

function testAssertFact(name Slot_1, optional string Slot_2, optional string Slot_3)
{
	local FactDatabase FactDatabase;
	local FactPattern Pattern;

	FactDatabase = ShockGameDriver(Level.GetGameDriver()).GetFactDatabase();
	Pattern.Slot_1 = Slot_1;
	Pattern.Slot_2 = Slot_2;
	Pattern.Slot_3 = Slot_3;
	FactDatabase.AssertFact(Pattern, true, false);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function testRetractFact(name Slot_1, optional string Slot_2, optional string Slot_3)
{
	local FactDatabase FactDatabase;
	local FactPattern Pattern;

	FactDatabase = ShockGameDriver(Level.GetGameDriver()).GetFactDatabase();
	Pattern.Slot_1 = Slot_1;
	Pattern.Slot_2 = Slot_2;
	Pattern.Slot_3 = Slot_3;
	FactDatabase.RetractFact(Pattern, false);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function DumpFacts()
{
	local int i;
	local FactDatabase FactDatabase;

	FactDatabase = ShockGameDriver(Level.GetGameDriver()).GetFactDatabase();
	log(,, "-----------------------------------------------------------");
	log(,, "---------------Dumping Fact List----------------");
	log(,, "-----------------------------------------------------------");
	log(,, "");
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1EE
	/*@Error*/
	log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(FactDatabase.FactStore[i].Slot_1), " , "), FactDatabase.FactStore[i].Slot_2), " , "), FactDatabase.FactStore[i].Slot_3));
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x10D;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function bool CanHitMagicBulletTarget()
{
	local bool HasMagicBullet;
	local Weapon Weapon;
	local ShockPlayerController PlayerController;

	PlayerController = ShockPlayerController(Controller);
	HasMagicBullet = __NFUN_130__(__NFUN_119__(PlayerController.AimTarget, none), PlayerController.FoundMagicBullet);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xF9
	/*@Error*/
	Weapon = Weapon(GetActiveHoldable());
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xF9
	/*@Error*/
	return __NFUN_176__(PlayerController.MagicBulletDistanceSquared, __NFUN_171__(Weapon.EffectiveMagicBulletDistance, Weapon.EffectiveMagicBulletDistance));
	return HasMagicBullet;
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnAbilityEquippingFinished(Ability inAbility)
{
	LastAbility = inAbility.Class;
	return;
	@NULL
	Item
	Item
}

function OnEquippingFinished(Holdable theHoldable)
{
	local Weapon CurWeapon;

	super.OnEquippingFinished(theHoldable);
	CurWeapon = Weapon(theHoldable);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x76
	/*@Error*/
	ShockPlayerController(Controller).GetPlayerStatsManager().PlayerWeaponEquipped(self, CurWeapon);
	LastWeapon = theHoldable;
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnUnEquippingFinished(Holdable theHoldable)
{
	super.OnUnEquippingFinished(theHoldable);
	return;
	@NULL
	Item
}

function OnReloadingStarted(Weapon theWeapon)
{
	super.OnReloadingStarted(theWeapon);
	GamepadPlayerInput(PlayerController(Controller).GetInput()).LockOn(none);
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnReloadingFinished(Weapon theWeapon)
{
	super.OnReloadingFinished(theWeapon);
	ShockPlayerController(Controller).GetPlayerStatsManager().PlayerWeaponReloaded(self, theWeapon);
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnFiringFinished(Weapon theWeapon)
{
	super.OnFiringFinished(theWeapon);
	ShockPlayerController(Controller).GetPlayerStatsManager().PlayerWeaponFired(self, theWeapon);
	return;
	@NULL
	Item
	Item
	@NULL
}

function StartCrouch(float HeightAdjust)
{
	super(Pawn).StartCrouch(HeightAdjust);
	ShockPlayerController(Controller).GetPlayerStatsManager().PlayerCrouched(self);
	ShockPlayerController(Controller).SetHeadbobContextState(1, true);
	ShockPlayerController(Controller).SetCameraAnimationModifier_HeadbobContextController(1);
	TriggerEffectEvent('Crouched');
	ShockPlayerController(Controller).ClearCameraAnimationModifier_HeadbobContextController();
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function EndCrouch(float HeightAdjust)
{
	super(Pawn).EndCrouch(HeightAdjust);
	ShockPlayerController(Controller).GetPlayerStatsManager().PlayerUnCrouched(self);
	ShockPlayerController(Controller).SetHeadbobContextState(1, false);
	UnTriggerEffectEvent('Crouched');
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function bool WaterIsTooDeepToJump()
{
	local float lowerBound, WaterHeight;

	// End:0x20
	if(__NFUN_129__(PhysicsVolume.__NFUN_303__('FluidVolume')))
	{
		return false;
		// End:0x5F
		if(bIsCrouched)
		{
		}
		lowerBound = __NFUN_175__(Location.Z, CrouchHeight);
		goto J0x8E;
		lowerBound = __NFUN_175__(Location.Z, CollisionHeight);
		WaterHeight = FluidVolume(PhysicsVolume).GetHeight();
	}
	return __NFUN_177__(WaterHeight, __NFUN_174__(lowerBound, MaximumJumpingDepth));
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool WaterIsTooDeepToCrouch()
{
	local float lowerBound, WaterHeight;

	// End:0x20
	if(__NFUN_129__(PhysicsVolume.__NFUN_303__('FluidVolume')))
	{
		return false;
		// End:0x5F
		if(bIsCrouched)
		{
		}
		lowerBound = __NFUN_175__(Location.Z, CrouchHeight);
		goto J0x8E;
		lowerBound = __NFUN_175__(Location.Z, CollisionHeight);
		WaterHeight = FluidVolume(PhysicsVolume).GetHeight();
	}
	return __NFUN_177__(WaterHeight, __NFUN_174__(lowerBound, MaximumCrouchingDepth));
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool CanCrouch()
{
	return __NFUN_130__(super(Pawn).CanCrouch(), __NFUN_129__(WaterIsTooDeepToCrouch()));
	return;
	@NULL
}

function bool CanJump()
{
	return __NFUN_130__(super(Pawn).CanJump(), __NFUN_129__(WaterIsTooDeepToJump()));
	return;
	@NULL
}

function bool DoJump(bool bUpdating)
{
	// End:0x32
	if(super(Pawn).DoJump(bUpdating))
	{
		TriggerEffectEventWithMaterialTrace('Jumped', 128.0000000);
		goto J0x45;
		TriggerEffectEvent('FailedJump');
	}
	return true;
	return;
	@NULL
	Item
}

function OnPushed(name EffectEventName, Actor Pusher)
{
	//native.EffectEventName;
	//native.Pusher;	
	@NULL
	@NULL
}

function OnObjectPhotographed(IPhotographTarget theObject, int Score)
{
	Actor(theObject).dispatchMessage(Class'ShockGame.MessageObjectPhotographed'.static.Allocate(self)., construct_IPhotographTargetInt(theObject, Score));
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function Weapon GetWeaponFromDamageData(IProvideDamageData DamageData)
{
	local Ammunition Ammunition;
	local Weapon Weapon;
	local int i;

	Ammunition = Ammunition(DamageData);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xCB
	/*@Error*/
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xCB
	/*@Error*/
	Weapon = Weapon(Holdables[i]);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xBD
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xBD
	/*@Error*/
	return Weapon;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x36;
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function Weapon GetWeaponFromAmmoClass(Class<Ammunition> AmmoClass)
{
	local Weapon Weapon;
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x93
	/*@Error*/
	Weapon = Weapon(Holdables[i]);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x85
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x85
	/*@Error*/
	return Weapon;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function NotifyPlayerAttacksWatcherThatPlayerAttacked(ShockPawn Attackee)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x75
	/*@Error*/
	assert(__NFUN_119__(PlayerAttacksNotificationList[i], none));
	PlayerAttacksNotificationList[i].OnPlayerAttacks(self, Attackee);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	Item
	@NULL
}

function RegisterPlayerAttacksWatcher(IWatchForPlayerAttacks Watcher)
{
	local int i;

	assert(__NFUN_119__(Watcher, none));
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x7C
	/*@Error*/
	assert(__NFUN_119__(PlayerAttacksNotificationList[i], none));
	// End:0x6E
	if(__NFUN_114__(PlayerAttacksNotificationList[i], Watcher))
	{
		return;
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x1A;
		PlayerAttacksNotificationList[PlayerAttacksNotificationList.Length] = Watcher;
		return;
		@NULL
		Item
	}
	Item
	@NULL
}

function UnregisterPlayerAttacksWatcher(IWatchForPlayerAttacks Watcher)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x81
	/*@Error*/
	assert(__NFUN_119__(PlayerAttacksNotificationList[i], none));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x73
	/*@Error*/
	PlayerAttacksNotificationList.Remove(i, 1);
	return;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool DropObject()
{
	local Ability ActiveAbility;

	ActiveAbility = GetActiveAbility();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xAC
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xAC
	/*@Error*/
	dispatchMessage(Class'ShockGame.MessagePlayerDroppedTKedObject'.static.Allocate(self)., Construct_Void());
	return true;
	return false;
	return;
	@NULL
	Item
	Item
	@NULL
}

// Export UShockPlayer::execSaveGamePlusData(FFrame&, void* const)
native exec function SaveGamePlusData();

// Export UShockPlayer::execLoadGamePlusData(FFrame&, void* const)
native exec function LoadGamePlusData();

// Export UShockPlayer::execHasGamePlusData(FFrame&, void* const)
native function bool HasGamePlusData();

function TempSavePlayerInventory()
{
	ShockGameInfo(Level.Game).TempSavePlayerInventory();
	return;
	@NULL
	Item
	default.Item
}

function TempLoadPlayerInventory()
{
	ShockGameInfo(Level.Game).TempLoadPlayerInventory();
	return;
	@NULL
	Item
	default.Item
}

// Export UShockPlayer::execGetChallengeTimeInSeconds(FFrame&, void* const)
native function float GetChallengeTimeInSeconds();

function StartChallengeTimer()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x3B
	/*@Error*/
	bChallengeTimerIsStarted = true;
	ChallengeTimerLevelStartTime = Level.TimeSeconds;
	return;
	@NULL
	Item
	Item
	@NULL
}

function StopChallengeTimer()
{
	// End:0x2D
	if(bChallengeTimerIsStarted)
	{
		ChallengeTimerEndTime = GetChallengeTimeInSeconds();
		bChallengeTimerIsStarted = false;
		return;
		@NULL
		Item
	}
	Item
}

// Export UShockPlayer::execGetChallengeTimeSecondsPart(FFrame&, void* const)
native function int GetChallengeTimeSecondsPart();

// Export UShockPlayer::execGetChallengeTimeMilliSecondsPart(FFrame&, void* const)
native function int GetChallengeTimeMilliSecondsPart();

function bool GetUseGamePlusData()
{
	return UseGamePlusData;
	return;
	@NULL
}

state Dying
{
	ignores BeginState;
Begin:

	TriggerDiedEffectEvent();
	__NFUN_256__(ResurrectionDelay);
	CloseAllResurrectionStationDoors();
	PlayerController(Controller).RumbleManager.TurnOffRumble();
	PlayerController(Controller).RumbleManager.RemoveAllRumbleEffects();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x3DB
	/*@Error*/
	// End:0xC2
	if(__NFUN_130__(Level.bIsDLC1Level, __NFUN_114__(ClosestResurrectionStation, none)))
	{
		SwitchToDLCEndMenu(true);
		goto J0x3DB;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x3D0
		/*@Error*/
	}
	PlayerController(Controller).Player.Console.ConsoleCommand("SETINPUTCONTEXTSTACK Default");
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x387
	/*@Error*/
	// End:0x2D6
	if(__NFUN_155__(int(GetPlatform()), int(0)))
	{
		PlayerController(Controller).Player.Console.ConsoleCommand("PUSHINPUTCONTEXT BathysphereUIActive");
		UnTriggerEffectEvent('Died');
		ShockPlayerController(Controller).ForcePause();
		Level.GetFlashGUIController().PlayMovie('HUD');
		Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("ShowDeathScreen");
		goto J0x384;
		UnTriggerEffectEvent('Died');
		ShockPlayerController(Controller).ForcePause();
		Level.GetFlashGUIController().PlayMovie('Pause');
		Level.GetFlashGUIController().GetPlayingMovie('Pause').CallMethodVoid("ShowDeathScreen");
	}
	goto J0x3CD;
	PlayerController(Controller).Player.Console.ConsoleCommand("open entry");
	goto J0x3DB;
	__NFUN_113__('Teleporting');
	stop;				
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// BadToken (0x03)
	/*@Error*/
}

state Dead
{Begin:

	// End:0xC4
	if(__NFUN_129__(Class'ShockGame.BaseResurrectionStation'.static.ResurrectShockPlayer(self, ClosestResurrectionStation)))
	{
		PlayerController(Controller).Player.Console.ConsoleCommand("SETINPUTCONTEXTSTACK Default");
		PlayerController(Controller).Player.Console.ConsoleCommand("open entry");
		__NFUN_113__('None');
		stop;								
	}
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

state Teleporting
{
	ignores TeleportPlayer;
Begin:

	LastTimeTeleported = Level.TimeSeconds;
	TeleportPlayer();
	stop;	
	@NULL
	@NULL
	@NULL
}

defaultproperties
{
	BasePlasmidSlots=2
	CollisionDamageRatio=1.0000000
	HackingCostModifierF=10.0000000
	HackingCostModifierG=1.0000000
	HackingCostModifierA=1.0000000
	HackingCostModifierS=1.0000000
	HackingCostModifierC=1.0000000
	HackingCostModifierL=1.0000000
	HackingCostModifierR=-0.5000000
	HackingCostModifierK=8.0000000
	PCFlowSpeedModifier=1.0000000
	PCInitialFlowSpeedModifier=1.5000000
	MaxBotsWhenHackFailsDuringAlarm=4
	PreloadClasses[0]=Class'ShockGame.Wrench'
	PreloadClasses[1]=Class'ShockGame.Pistol'
	PreloadClasses[2]=Class'ShockGame.Shotgun'
	PreloadClasses[3]=Class'ShockGame.Crossbow'
	PreloadClasses[4]=Class'ShockGame.GrenadeLauncher'
	PreloadClasses[5]=Class'ShockGame.ChemicalThrower'
	PreloadClasses[6]=Class'ShockGame.MachineGun'
	PreloadClasses[7]=Class'ShockGame.ShockDesignerClasses.BioAmmoHypo'
	SanctuaryModelSocket="bip01_headnub"
	SanctuaryModelClass=Class'ShockGame.FXClass.SanctuaryShell'
	MaximumSanctuaryMoveDistance=25.0000000
	ChameleonBloodAvoidDetectionTime=1.2500000
	ChargedBurstChargeTime=0.2500000
	ChargedBurstDamageStimuliSetName="ChargedBurstStimuliSet"
	ChargedBurstInnerAttenuationRadius=500.0000000
	ChargedBurstOuterAttenuationRadius=500.0000000
	TeleportEffectTime=2.2500000
	TeleportFlyMaxDistance=2000.0000000
	TeleportViewMaxVel=180000.0000000
	TeleportViewSmoothTime=0.1000000
	TimeToConsiderHiddenAfterTeleporting=0.5000000
	EveBarPercentageToRestoreOnRessurection=0.7500000
	GPSOffsetWidescreenPC=(X=26.5000000,Y=0.0000000,Z=7.5000000)
	GPSOffsetPC=(X=20.5000000,Y=0.0000000,Z=7.5000000)
	GPSArrowMaxVel=100000.0000000
	GPSArrowSmoothTime=0.2000000
	GPSOffsetWidescreen=(X=28.5000000,Y=0.0000000,Z=7.5000000)
	GPSOffset=(X=22.0000000,Y=0.0000000,Z=7.5000000)
	GPSDestinationArrivedMessage="Arrived at goal destination."
	GPSNoDestinationMessage="No location information is available for this goal."
	GPSNotInLevelMessage="This goal's location is on a different level."
	GPSRePathFindInterval=1.0000000
	GPSCheckOnPathInterval=0.5000000
	MaxCredits=500
	BioAmmo=35.0000000
	MaxBioAmmo=35.0000000
	BaseInventorySize=6
	FrozenFlowSpeedPercentBonus=-0.2500000
	NearDeathHealthThreshold=40.0000000
	IneffectivePlasmidEffectTime=3.0000000
	MaxAllowCrouchAcceleration=700.0000000
	LowHealthInvulnerabilityTime=3.0000000
	LowHealthInvulnerabilityResetTime=60.0000000
	LowHealthInvulnerabilityHealthNeededToReset=10.0000000
	LowHealthRestorationTimeout=1.0000000
	UnplayedJournalEntryIndex=-1
	RadioCountDisplayMax=10
	NewPlasmidActiveTrackMessage="You have run out of SLOTS and will have to replace a PLASMID.\\n\\nYou can buy more slots at a GATHERER'S GARDEN.\\n\\nReplaced plasmids can be re-equipped at a GENE BANK."
	NewPlasmidPhysicalTrackMessage="You have picked up your first PHYSICAL TONIC!\\n\\nPhysical tonics make you stronger or more powerful. They are equipped separately from Plasmids and other types of Tonics."
	NewPlasmidEngineeringTrackMessage="You have picked up your first ENGINEERING TONIC!\\n\\nEngineering tonics make you better at hacking or using machines. They are equipped separately from Plasmids and other types of Tonics."
	NewPlasmidCombatTrackMessage="You have picked up a COMBAT TONIC!\\n\\nCombat tonics make you better at dealing and resisting damage. They are equipped separately from Plasmids and other types of Tonics."
	NewSlotActiveTrackMessage="Select a Plasmid to place in your new unlocked slot."
	NewSlotPhysicalTrackMessage="Select a Physical Tonic to place in your new unlocked slot."
	NewSlotEngineeringTrackMessage="Select an Engineering Tonic to place in your new unlocked slot."
	NewSlotCombatTrackMessage="Select a Combat Tonic to place in your new unlocked slot."
	ComfirmActionNewPlasmidMessage="REPLACE"
	ComfirmActionEmptySlotMessage="PLACE IN SLOT"
	ComfirmActionNoPlasmidsMessage="OK"
	PlasmiNowUIHighlightNewPlasmidMessage="SELECT PLASMID TO REPLACE"
	PlasmiNowUIHighlightNewSlotMessage="SELECT PLASMID FROM GENE BANK"
	PlasmiNowUIHighlightNewTonicMessage="SELECT TONIC TO REPLACE"
	PlasmiNowUIHighlightNewTonicSlotMessage="SELECT TONIC FROM GENE BANK"
	ReplacedActivePlasmidMessage="Replaced %s with %s."
	HackingResultOverloadedText="The machine has OVERLOADED."
	HackingResultShortCircuitText="The machine has short circuited."
	HackingResultAlarmText=" Bots released due to security alarm being activated."
	HackingResultNoHackAttemptedText="No hack attempted."
	HackingResultSuccessText="Hack successful!"
	GoldMedalInChallengeRoomSuccessText="Your speed is bioShocking! CHANGE MY TEXT in ShockPawn.ini"
	GoldMedalInChallengeRoomFailureText="A little sister can go faster than you! CHANGE MY TEXT in ShockPawn.ini"
	ResurrectionDelay=4.8000002
	LeanTransitionDuration=0.3000000
	LeanHorizontalDistance=60.0000000
	LeanVerticalDistance=-16.0000000
	LeanRollDegrees=8.0000000
	LeanBezierPt1X=0.4000000
	LeanBezierPt2X=0.6000000
	LeanBezierPt2Y=1.0000000
	TestDisplayPhotoIndex=-1
	PhotoScoreToGradeMapping[0]=(Grade=0,Score=0)
	PhotoScoreToGradeMapping[1]=(Grade=2,Score=34)
	PhotoScoreToGradeMapping[2]=(Grade=3,Score=70)
	PhotoScoreToGradeMapping[3]=(Grade=4,Score=85)
	NoPhotoSubjectOnScreenMessage="No Subject in view. Photo not taken."
	NoPhotoSubjectInFrameMessage="Subject was mostly out of frame. Photo not taken."
	NoEnemyPhotoSubjectMessage="Subject is friendly. Photo not taken."
	LowScoreMessage="Score too low. Photo not taken."
	ResearchCompleteMessage="Subject research complete. Photo not taken"
	ResearchTrackData[0]=(ResearchName="MeleeThug",FriendlyName="Thuggish Splicer",MaxScore=1750)
	ResearchTrackData[1]=(ResearchName="RangedAggressor",FriendlyName="Leadhead Splicer",MaxScore=1750)
	ResearchTrackData[2]=(ResearchName="Grenadier",FriendlyName="Nitro Splicer",MaxScore=1750)
	ResearchTrackData[3]=(ResearchName="CeilingCrawler",FriendlyName="Spider Splicer",MaxScore=1750)
	ResearchTrackData[4]=(ResearchName="Assassin",FriendlyName="Houdini Splicer",MaxScore=1750)
	ResearchTrackData[5]=(ResearchName="Bouncer",FriendlyName="Bouncer",MaxScore=2000)
	ResearchTrackData[6]=(ResearchName="Rosie",FriendlyName="Rosie",MaxScore=2000)
	ResearchTrackData[7]=(ResearchName="SecurityBot",FriendlyName="Security Bot",MaxScore=1750)
	ResearchTrackData[8]=(ResearchName="Gatherer",FriendlyName="Little Sister",MaxScore=2000)
	ResearchTrackData[9]=(ResearchName="Turret",FriendlyName="Turret",MaxScore=1750)
	ResearchTrackData[10]=(ResearchName="SecurityCamera",FriendlyName="Security Camera",MaxScore=1750)
	ResearchLevels[0]=(ResearchName="MeleeThug",LevelNumber=1,ScoreRequired=25,Text="THUGGISH SPLICER Research Bonus:\\n\\nIncreased Damage +\\n\\nThuggish Splicers vulnerable to antipersonnel rounds.",ExtendedText="Melee Aggressor ExtendedText for Level 1",AwardItemClass=none,AwardResistanceInfo=true)
	ResearchLevels[1]=(ResearchName="MeleeThug",LevelNumber=2,ScoreRequired=300,Text="THUGGISH SPLICER Research Bonus:\\n\\nAcquired Combat Tonic: SportBoost.",ExtendedText="Melee Aggressor ExtendedText for Level 2",AwardItemClass=Class'ShockGame.FastTwitch',AwardResistanceInfo=false)
	ResearchLevels[2]=(ResearchName="MeleeThug",LevelNumber=3,ScoreRequired=600,Text="THUGGISH SPLICER Research Bonus:\\n\\nIncreased Damage ++",ExtendedText="Melee Aggressor ExtendedText for Level 3",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[3]=(ResearchName="MeleeThug",LevelNumber=4,ScoreRequired=1000,Text="THUGGISH SPLICER Research Bonus:\\n\\nAcquired Combat Tonic: SportBoost 2.",ExtendedText="Melee Aggressor ExtendedText for Level 4",AwardItemClass=Class'ShockGame.ShockDesignerClasses.FastTwitchTwo',AwardResistanceInfo=false)
	ResearchLevels[4]=(ResearchName="MeleeThug",LevelNumber=5,ScoreRequired=1750,Text="THUGGISH SPLICER Research Bonus:\\n\\nIncreased Damage +++",ExtendedText="Melee Aggressor ExtendedText for Level 5",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[5]=(ResearchName="RangedAggressor",LevelNumber=1,ScoreRequired=25,Text="LEADHEAD SPLICER Research Bonus\\n\\nIncreased Damage +\\n\\nLeadhead Splicers are vulnerable to antipersonnel rounds.",ExtendedText="Machine Gun Mutant ExtendedText for Level 1",AwardItemClass=none,AwardResistanceInfo=true)
	ResearchLevels[6]=(ResearchName="RangedAggressor",LevelNumber=2,ScoreRequired=300,Text="LEADHEAD SPLICER Research Bonus:\\n\\n¬quired Physical Tonic: Scrounger",ExtendedText="Melee Aggressor ExtendedText for Level 2",AwardItemClass=Class'ShockGame.ThoroughScavenger',AwardResistanceInfo=false)
	ResearchLevels[7]=(ResearchName="RangedAggressor",LevelNumber=3,ScoreRequired=600,Text="LEADHEAD SPLICER Research Bonus\\n\\nIncreased Damage ++",ExtendedText="Machine Gun Mutant ExtendedText for Level 3",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[8]=(ResearchName="RangedAggressor",LevelNumber=4,ScoreRequired=1000,Text="LEADHEAD SPLICER Research Bonus:\\n\\nAcquired Combat Tonic: Charged Bursts 2",ExtendedText="Machine Gun Mutant ExtendedText for Level 4",AwardItemClass=Class'ShockGame.ShockDesignerClasses.ChargedBurstsTwo',AwardResistanceInfo=false)
	ResearchLevels[9]=(ResearchName="RangedAggressor",LevelNumber=5,ScoreRequired=1750,Text="LEADHEAD SPLICER Research Bonus:\\n\\nIncreased Damage +++",ExtendedText="Machine Gun Mutant ExtendedText for Level 5",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[10]=(ResearchName="Grenadier",LevelNumber=1,ScoreRequired=25,Text="NITRO SPLICER Research Bonus:\\n\\nIncreased Damage +\\n\\nNitro Splicers are vulnerable to antipersonnel rounds.",ExtendedText="Grenadier ExtendedText for Level 1",AwardItemClass=none,AwardResistanceInfo=true)
	ResearchLevels[11]=(ResearchName="Grenadier",LevelNumber=2,ScoreRequired=300,Text="NITRO SPLICER Research Bonus:\\n\\nPermanent 15% chance that any enemy grenade will be a dud.",ExtendedText="Grenadier ExtendedText for Level 2",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[12]=(ResearchName="Grenadier",LevelNumber=3,ScoreRequired=600,Text="NITRO SPLICER Research Bonus:\\n\\nIncreased Damage ++",ExtendedText="Grenadier ExtendedText for Level 3",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[13]=(ResearchName="Grenadier",LevelNumber=4,ScoreRequired=1000,Text="NITRO SPLICER Research Bonus:\\n\\nPermanent 35% chance that any enemy grenade will be a dud.",ExtendedText="Grenadier ExtendedText for Level 4",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[14]=(ResearchName="Grenadier",LevelNumber=5,ScoreRequired=1750,Text="NITRO SPLICER Research Bonus:\\n\\nIncreased Damage +++",ExtendedText="Grenadier ExtendedText for Level 5",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[15]=(ResearchName="CeilingCrawler",LevelNumber=1,ScoreRequired=25,Text="SPIDER SPLICER Research Bonus:\\n\\nIncreased Damage +\\n\\nSpider Splicers are vulnerable to antipersonnel rounds.",ExtendedText="Ceiling Crawler ExtendedText for Level 1",AwardItemClass=none,AwardResistanceInfo=true)
	ResearchLevels[16]=(ResearchName="CeilingCrawler",LevelNumber=2,ScoreRequired=300,Text="SPIDER SPLICER Research Bonus:\\n\\nSpider Splicer Organs can be used like first aid kits",ExtendedText="Ceiling Crawler ExtendedText for Level 2",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[17]=(ResearchName="CeilingCrawler",LevelNumber=3,ScoreRequired=600,Text="SPIDER SPLICER Research Bonus:\\n\\nIncreased Damage ++",ExtendedText="Ceiling Crawler ExtendedText for Level 3",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[18]=(ResearchName="CeilingCrawler",LevelNumber=4,ScoreRequired=1000,Text="SPIDER SPLICER Research Bonus:\\n\\nAcquired Plasmid: Extra Nutrition 3",ExtendedText="Ceiling Crawler ExtendedText for Level 4",AwardItemClass=Class'ShockGame.ShockDesignerClasses.HealthyConsumerThree',AwardResistanceInfo=false)
	ResearchLevels[19]=(ResearchName="CeilingCrawler",LevelNumber=5,ScoreRequired=1750,Text="SPIDER SPLICER Research Bonus:\\n\\nIncreased Damage +++",ExtendedText="Ceiling Crawler ExtendedText for Level 5",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[20]=(ResearchName="Assassin",LevelNumber=1,ScoreRequired=25,Text="HOUDINI SPLICER Research Bonus:\\n\\nIncreased Damage +\\n\\nHoudini Splicers are vulnerable to antipersonnel rounds",ExtendedText="Assassin ExtendedText for Level 1",AwardItemClass=none,AwardResistanceInfo=true)
	ResearchLevels[21]=(ResearchName="Assassin",LevelNumber=2,ScoreRequired=300,Text="HOUDINI SPLICER Research Bonus:\\n\\nAcquired Physical Tonic: Natural Camouflage",ExtendedText="Assassin ExtendedText for Level 2",AwardItemClass=Class'ShockGame.ChameleonBlood',AwardResistanceInfo=false)
	ResearchLevels[22]=(ResearchName="Assassin",LevelNumber=3,ScoreRequired=600,Text="HOUDINI SPLICER Research Bonus:\\n\\nIncreased Damage ++",ExtendedText="Assassin ExtendedText for Level 3",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[23]=(ResearchName="Assassin",LevelNumber=4,ScoreRequired=1000,Text="HOUDINI SPLICER Research Bonus:\\n\\nEasier to predict Houdini Splicers' teleportation destination.",ExtendedText="Assassin ExtendedText for Level 4",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[24]=(ResearchName="Assassin",LevelNumber=5,ScoreRequired=1750,Text="HOUDINI SPLICER Research Bonus:\\n\\nIncreased Damage +++",ExtendedText="Assassin ExtendedText for Level 5",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[25]=(ResearchName="Bouncer",LevelNumber=1,ScoreRequired=25,Text="BOUNCER Research Bonus:\\n\\nIncreased Damage +\\n\\nBouncers are vulnerable to armor-piercing rounds",ExtendedText="Bouncer ExtendedText for Level 1",AwardItemClass=none,AwardResistanceInfo=true)
	ResearchLevels[26]=(ResearchName="Bouncer",LevelNumber=2,ScoreRequired=400,Text="BOUNCER Research Bonus:\\n\\nAcquired Combat Tonic: Wrench Jockey 2",ExtendedText="Bouncer ExtendedText for Level 2",AwardItemClass=Class'ShockGame.ShockDesignerClasses.MeleeMasterTwo',AwardResistanceInfo=false)
	ResearchLevels[27]=(ResearchName="Bouncer",LevelNumber=3,ScoreRequired=800,Text="BOUNCER Research Bonus:\\n\\nIncreased Damage ++",ExtendedText="Bouncer ExtendedText for Level 3",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[28]=(ResearchName="Bouncer",LevelNumber=4,ScoreRequired=1200,Text="BOUNCER Research Bonus:\\n\\nPermanent 50% increase to all wrench damage",ExtendedText="Bouncer ExtendedText for Level 4",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[29]=(ResearchName="Bouncer",LevelNumber=5,ScoreRequired=2000,Text="BOUNCER Research Bonus:\\n\\nIncreased Damage +++",ExtendedText="Bouncer ExtendedText for Level 5",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[30]=(ResearchName="Rosie",LevelNumber=1,ScoreRequired=25,Text="ROSIE Research Bonus:\\n\\nIncreased Damage +\\n\\nRosies are vulnerable to armor-piercing rounds",ExtendedText="Rosie ExtendedText for Level 1",AwardItemClass=none,AwardResistanceInfo=true)
	ResearchLevels[31]=(ResearchName="Rosie",LevelNumber=2,ScoreRequired=400,Text="ROSIE Research Bonus:\\n\\nAcquired Combat Tonic: Photographer's Eye 2",ExtendedText="Rosie ExtendedText for Level 2",AwardItemClass=Class'ShockGame.ShockDesignerClasses.EyeForDetailTwo',AwardResistanceInfo=false)
	ResearchLevels[32]=(ResearchName="Rosie",LevelNumber=3,ScoreRequired=800,Text="ROSIE Research Bonus:\\n\\nIncreased Damage ++",ExtendedText="Rosie ExtendedText for Level 3",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[33]=(ResearchName="Rosie",LevelNumber=4,ScoreRequired=1200,Text="ROSIE Research Bonus:\\n\\nRosie Loot almost always contains rare Invention materials",ExtendedText="Rosie ExtendedText for Level 4",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[34]=(ResearchName="Rosie",LevelNumber=5,ScoreRequired=2000,Text="ROSIE Research Bonus:\\n\\nIncreased Damage +++",ExtendedText="Rosie ExtendedText for Level 5",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[35]=(ResearchName="SecurityBot",LevelNumber=1,ScoreRequired=25,Text="SECURITY BOT Research Bonus:\\n\\nIncreased Damage +\\n\\nSecurity Bots are vulnerable to armor-piercing rounds and electricity",ExtendedText="SecurityBot ExtendedText for Level 1",AwardItemClass=none,AwardResistanceInfo=true)
	ResearchLevels[36]=(ResearchName="SecurityBot",LevelNumber=2,ScoreRequired=300,Text="SECURITY BOT Research Bonus:\\n\\nAcquired Engineering Tonic: Security Expert 2",ExtendedText="SecurityBot ExtendedText for Level 2",AwardItemClass=Class'ShockGame.ShockDesignerClasses.SecuritySystemsExpertTwo',AwardResistanceInfo=false)
	ResearchLevels[37]=(ResearchName="SecurityBot",LevelNumber=3,ScoreRequired=600,Text="SECURITY BOT Research Bonus:\\n\\nIncreased Damage ++",ExtendedText="SecurityBot ExtendedText for Level 3",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[38]=(ResearchName="SecurityBot",LevelNumber=4,ScoreRequired=1000,Text="SECURITY BOT Research Bonus:\\n\\nHacking Security Bots automatically succeeds",ExtendedText="SecurityBot ExtendedText for Level 4",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[39]=(ResearchName="SecurityBot",LevelNumber=5,ScoreRequired=1750,Text="SECURITY BOT Research Bonus:\\n\\nIncreased Damage +++",ExtendedText="SecurityBot ExtendedText for Level 5",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[40]=(ResearchName="Gatherer",LevelNumber=1,ScoreRequired=25,Text="LITTLE SISTER Research Bonus:\\n\\nSmall increases to max Health and EVE",ExtendedText="Gatherer ExtendedText for Level 1",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[41]=(ResearchName="Gatherer",LevelNumber=2,ScoreRequired=400,Text="LITTLE SISTER Research Bonus:\\n\\nSmall increases to max Health and EVE",ExtendedText="Gatherer ExtendedText for Level 2",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[42]=(ResearchName="Gatherer",LevelNumber=3,ScoreRequired=800,Text="LITTLE SISTER Research Bonus:\\n\\nSmall increases to max Health and EVE",ExtendedText="Gatherer ExtendedText for Level 3",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[43]=(ResearchName="Gatherer",LevelNumber=4,ScoreRequired=1200,Text="LITTLE SISTER Research Bonus:\\n\\nSmall increases to max Health and EVE",ExtendedText="Gatherer ExtendedText for Level 4",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[44]=(ResearchName="Gatherer",LevelNumber=5,ScoreRequired=2000,Text="LITTLE SISTER Research Bonus:\\n\\nSmall increases to max Health and EVE",ExtendedText="Gatherer ExtendedText for Level 5",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[45]=(ResearchName="Turret",LevelNumber=1,ScoreRequired=25,Text="TURRET Research Bonus:\\n\\nIncreased Damage +\\n\\nTurrets are vulnerable to armor-piercing rounds and electricity",ExtendedText="Turret ExtendedText for Level 1",AwardItemClass=none,AwardResistanceInfo=true)
	ResearchLevels[46]=(ResearchName="Turret",LevelNumber=2,ScoreRequired=300,Text="TURRET Research Bonus:\\n\\nYou find twice the ammunition on destroyed Turrets",ExtendedText="Turret ExtendedText for Level 2",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[47]=(ResearchName="Turret",LevelNumber=3,ScoreRequired=600,Text="TURRET Research Bonus:\\n\\nIncreased Damage ++",ExtendedText="Turret ExtendedText for Level 3",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[48]=(ResearchName="Turret",LevelNumber=4,ScoreRequired=1000,Text="TURRET Research Bonus:\\n\\nHacking Turrets automatically succeeds",ExtendedText="Turret ExtendedText for Level 4",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[49]=(ResearchName="Turret",LevelNumber=5,ScoreRequired=1750,Text="TURRET Research Bonus:\\n\\nIncreased Damage +++",ExtendedText="Turret ExtendedText for Level 5",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[50]=(ResearchName="SecurityCamera",LevelNumber=1,ScoreRequired=25,Text="SECURITY CAMERA Research Bonus:\\n\\nIncreased Damage +\\n\\nSecurity Cameras are vulnerable to armor-piercing rounds and electricity",ExtendedText="Security Camera ExtendedText for Level 1",AwardItemClass=none,AwardResistanceInfo=true)
	ResearchLevels[51]=(ResearchName="SecurityCamera",LevelNumber=2,ScoreRequired=300,Text="SECURITY CAMERA Research Bonus:\\n\\nYou find twice the film on destroyed Security Cameras",ExtendedText="Security Cameras ExtendedText for Level 2",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[52]=(ResearchName="SecurityCamera",LevelNumber=3,ScoreRequired=600,Text="SECURITY CAMERA Research Bonus:\\n\\nIncreased Damage ++",ExtendedText="Security Camera ExtendedText for Level 3",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[53]=(ResearchName="SecurityCamera",LevelNumber=4,ScoreRequired=1000,Text="SECURITY CAMERA Research Bonus:\\n\\nFlow Speed reduced when hacking any Security Camera",ExtendedText="Security Camera ExtendedText for Level 4",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchLevels[54]=(ResearchName="SecurityCamera",LevelNumber=5,ScoreRequired=1750,Text="SECURITY CAMERA Research Bonus:\\n\\nIncreased Damage +++",ExtendedText="Security Camera ExtendedText for Level 5",AwardItemClass=none,AwardResistanceInfo=false)
	ResearchDamageTypes[0]=(Type=21,FriendlyName="Bludgeoning")
	ResearchDamageTypes[1]=(Type=22,FriendlyName="Heat")
	ResearchDamageTypes[2]=(Type=23,FriendlyName="Cold")
	ResearchDamageTypes[3]=(Type=24,FriendlyName="Electric")
	ResearchResistanceToString="Resistance To: "
	ResearchVulnerableToString="Enemy weakness information obtained.\\nVulnerable To: "
	TakeAllDelayTime=0.3000000
	CollisionLatency=1.0000000
	MaximumCrouchingDepth=70.0000000
	MaximumJumpingDepth=80.0000000
	MaximumLeaningDepth=80.0000000
	BathysphereManagerNames[0]="BioshockBathyspheres"
	DownloadContentBathysphereHubMapName="DownloadHub"
	LastInfoPanelTab="goals"
	PossibleAbilities[0]=Class'ShockGame.IncinerationAbility'
	PossibleAbilities[1]=Class'ShockGame.ShockDesignerClasses.IncinerationTwoAbility'
	PossibleAbilities[2]=Class'ShockGame.ShockDesignerClasses.IncinerationThreeAbility'
	PossibleAbilities[3]=Class'ShockGame.ShockDesignerClasses.IncinerationZeroAbility'
	PossibleAbilities[4]=none
	PossibleAbilities[5]=Class'ShockGame.SecurityBeaconAbility'
	PossibleAbilities[6]=Class'ShockGame.BerserkRageAbility'
	PossibleAbilities[7]=Class'ShockGame.ElectricBoltAbility'
	PossibleAbilities[8]=Class'ShockGame.ShockDesignerClasses.ElectricBoltTwoAbility'
	PossibleAbilities[9]=Class'ShockGame.ShockDesignerClasses.ElectricBoltThreeAbility'
	PossibleAbilities[10]=Class'ShockGame.ShockDesignerClasses.ElectricBoltZeroAbility'
	PossibleAbilities[11]=none
	PossibleAbilities[12]=Class'ShockGame.AirBlastAbility'
	PossibleAbilities[13]=Class'ShockGame.ShockDesignerClasses.AirBlastTwoAbility'
	PossibleAbilities[14]=none
	PossibleAbilities[15]=Class'ShockGame.IcicleAssaultAbility'
	PossibleAbilities[16]=Class'ShockGame.ShockDesignerClasses.IcicleAssaultTwoAbility'
	PossibleAbilities[17]=Class'ShockGame.ShockDesignerClasses.IcicleAssaultThreeAbility'
	PossibleAbilities[18]=none
	PossibleAbilities[19]=Class'ShockGame.DecoyHumanAbility'
	PossibleAbilities[20]=Class'ShockGame.SpringBoardTrapAbility'
	PossibleAbilities[21]=Class'ShockGame.ShockDesignerClasses.SpringBoardTrapTwoAbility'
	PossibleAbilities[22]=none
	PossibleAbilities[23]=Class'ShockGame.TelekinesisAbility'
	PossibleAbilities[24]=Class'ShockGame.ShockDesignerClasses.TelekinesisTwoAbility'
	PossibleAbilities[25]=Class'ShockGame.SummonProtectorAbility'
	PossibleAbilities[26]=Class'ShockGame.ShockDesignerClasses.SummonProtectorTwoAbility'
	PossibleAbilities[27]=Class'ShockGame.InsectSwarmAbility'
	PossibleAbilities[28]=Class'ShockGame.ShockDesignerClasses.InsectSwarmTwoAbility'
	PossibleAbilities[29]=Class'ShockGame.ShockDesignerClasses.InsectSwarmThreeAbility'
	PossibleAbilities[30]=none
	HandsClassString="FirstPersonHands.PlayerHands"
	DamageResistanceSetName="PlayerResistanceSet"
	BaseCriticalHitChanceModifier=0.0000000
	BaseCriticalHitAmountModifier=0.0000000
	AllPossibleWeaponClasses[0]=Class'ShockGame.Wrench'
	AllPossibleWeaponClasses[1]=Class'ShockGame.Pistol'
	AllPossibleWeaponClasses[2]=Class'ShockGame.Shotgun'
	AllPossibleWeaponClasses[3]=Class'ShockGame.Crossbow'
	AllPossibleWeaponClasses[4]=Class'ShockGame.GrenadeLauncher'
	AllPossibleWeaponClasses[5]=Class'ShockGame.MachineGun'
	AllPossibleWeaponClasses[6]=Class'ShockGame.ChemicalThrower'
	AllPossibleWeaponClasses[7]=Class'ShockGame.ResearchCamera'
	CollisionAvoidancePushStrength=25.0000000
	bUseHavokRigidBodyCapsuleCollisions=true
	CrouchHeight=40.0000000
	CrouchRadius=34.0000000
	VisionRadiusMultiplier=0.5000000
	VisionHeightMultiplier=0.7500000
	ControllerClass=none
	bNeedProtectedTick=true
	CollisionRadius=34.0000000
}