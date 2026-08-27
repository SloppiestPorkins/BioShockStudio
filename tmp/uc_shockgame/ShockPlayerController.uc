class ShockPlayerController extends PlayerController implements IInterestedActorDestroyed
	native
	config(ShockGame)
	hidecategories(DrawScale3D,DisplayAdvanced);

enum EHeadbobContext
{
	kHC_Default,                    // 0
	kHC_Crouching,                  // 1
	kHC_Zooming                     // 2
};

var private int HeadbobContextStates[3];
var private config float HeadbobSpeedControlPt_1;
var private config float HeadbobSpeedControlPt_2;
var private config float HeadbobSpeedControlPt_3;
var private config float HeadbobSpeedControlPt_4;
var config float FocusTestDistance;
var config float UseFocusTestDistance;
var config float HackFocusTestDistance;
var config float ArtSubtitleTestDistance;
var config float FocusTestInterval;
var private Timer FocusPollTimer;
var private bool bWasInGatherChoice;
var config Range RandomAmbientSoundInterval;
var config Range DistanceToRandomAmbientSound;
var config float RandomAmbientAngle;
var private Timer RandomAmbientSoundTimer;
var private Material CurrentMaterialFocus;
var bool bHighlightFocussedItems;
var bool bDisablePause;
var bool bDontProcessAnyMoreInputThisFrame;
var private transient bool bHadACurrentFocusDuringLastCheck;
var float KickbackAlpha;
var private transient ICanBeUsed CurrentUseFocus;
var private transient float LastUseFocusChangedTime;
var private ICanBeUsed LastUsedObject;
var private ICanBeUsed LastUsedObjectNotCleared;
var private transient ICanBeHacked CurrentHackFocus;
var private transient ICanBeFocused CurrentFocus;
var array<IObserveUseFocus> UseFocusObservers;
var private string LastPlayerInputContext;
var private transient ShockPawn CurrentEnemy;
var private ICanBeUsed UsedObjectPendingPlacement;
var private config float ForceMoveLocationDeltaPerSecond;
var private config float ForceMoveRotationDeltaPerSecond;
var private bool bIsForcingPlayerMove;
var private Vector ForcePlayerMoveTargetLocation;
var private Rotator ForcePlayerMoveTargetRotation;
var private float ForcePlayerMoveDeltaLocationVelocityX;
var private float ForcePlayerMoveDeltaLocationVelocityY;
var private float ForcePlayerMoveDeltaLocationVelocityPitch;
var private float ForcePlayerMoveDeltaLocationVelocityYaw;
var private ICanBeFocused CurrentHighlightedFocus;
var private name CurrentTrainingHelpTag;
var bool SuppressTrainingMessages;
var input byte bLeanLeft;
var input byte bLeanRight;
var input byte bProcessLean;
var float Lean;
var bool bIsInPCLeaningMode;
var float pcLean;
var float OldLean;
var float LeanVel;
var config float LeanMaxVel;
var config float LeanAccel;
var config bool bUseRadiusBasedUseFocus;
var config bool bUseStickyBasedFocus;
var config bool bRadiusUseFocusOverridesNonUseFocus;
var bool LevelSwitchingDisabled;
var private int SaveGameOptionDisabled;
var private float LastQuickSaveTime;
var bool DontUpdateFocus;
var float TimeCrouchButtonLastPressed;
var config float CrouchTapTime;
var float TimeLogsPlaybackButtonLastPressed;
var config float LogsPlaybackHoldTime;
var float TimeHintButtonLastPressed;
var config float HintHoldTime;
var config localized string PacifyText;
var config localized string SaveText;
var config localized string ReRollText;
var config localized string WhatIsThisText;
var config localized string PCWhatIsThisText;
var config localized string LocalizedHackText;
var config localized string CollectText;
var bool bRadialNotified_RX;
var bool bRadialNotified_RY;
var bool bRadialNotified_LX;
var bool bRadialNotified_LY;
var bool bLeftStickChanging;
var bool bRightStickChanging;
var bool bSuppressHUDMessages;

function PostBeginPlay()
{
	super.PostBeginPlay();
	FocusPollTimer = __NFUN_278__(Class'Engine.Timer');
	assert(__NFUN_119__(FocusPollTimer, none));
	FocusPollTimer.__TimerDelegate__Delegate = UpdateFocus;
	FocusPollTimer.StartTimer(FocusTestInterval, true);
	RandomAmbientSoundTimer = __NFUN_278__(Class'Engine.Timer');
	assert(__NFUN_119__(RandomAmbientSoundTimer, none));
	RandomAmbientSoundTimer.__TimerDelegate__Delegate = PlayRandomAmbientSound;
	RandomAmbientSoundTimer.StartTimer(__NFUN_172__(__NFUN_174__(RandomAmbientSoundInterval.Min, RandomAmbientSoundInterval.Max), 2.0000000));
	// End:0x16B
	if(__NFUN_119__(RumbleManager, none))
	{
		RumbleManager.EnableRumble(ShockUserSettings(Level.GetGameDriver().GetUserSettings()).Vibration);
		InitAudioVolumeToUserSettings();
		ShockGameDriver(Level.GetGameDriver()).GetTrainingMessageManager().EnableAdaptiveMessages = ShockUserSettings(Level.GetGameDriver().GetUserSettings()).AdaptiveTraining;
	}
	Level.RegisterNotifyActorDestroyed(self);
	return;
	@NULL
	Item
	Item
	@NULL
}

// Export UShockPlayerController::execInitAudioVolumeToUserSettings(FFrame&, void* const)
native function InitAudioVolumeToUserSettings();

function InitInputSystem()
{
	super.InitInputSystem();
	GamepadPlayerInput(GetInput()).IsInverted = ShockGameDriver(Level.GetGameDriver()).GetUserSettings().InvertYAxis;
	GamepadPlayerInput(GetInput()).AutoAim = ShockGameDriver(Level.GetGameDriver()).GetUserSettings().AutoAim;
	GamepadPlayerInput(GetInput()).UpdateSensitivityScale(ShockUserSettings(Level.GetGameDriver().GetUserSettings()).Sensitivity);
	GamepadPlayerInput(GetInput()).MouseSensitivity = ShockGameDriver(Level.GetGameDriver()).GetUserSettings().MouseSensitivity;
	GamepadPlayerInput(GetInput()).SoftLockOn = ShouldUseController();
	return;
	@NULL
	Item
	Item
	@NULL
}

function PostLoadGame()
{
	// End:0x62
	if(__NFUN_119__(RumbleManager, none))
	{
		RumbleManager.EnableRumble(ShockUserSettings(Level.GetGameDriver().GetUserSettings()).Vibration);
		InitAudioVolumeToUserSettings();
		ShockGameDriver(Level.GetGameDriver()).GetTrainingMessageManager().EnableAdaptiveMessages = ShockUserSettings(Level.GetGameDriver().GetUserSettings()).AdaptiveTraining;
	}
	// End:0x15A
	if(__NFUN_114__(FocusPollTimer, none))
	{
		FocusPollTimer = __NFUN_278__(Class'Engine.Timer');
		assert(__NFUN_119__(FocusPollTimer, none));
		FocusPollTimer.__TimerDelegate__Delegate = UpdateFocus;
		FocusPollTimer.StartTimer(FocusTestInterval, true);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x202
		/*@Error*/
		RandomAmbientSoundTimer = __NFUN_278__(Class'Engine.Timer');
		assert(__NFUN_119__(RandomAmbientSoundTimer, none));
		RandomAmbientSoundTimer.__TimerDelegate__Delegate = PlayRandomAmbientSound;
		RandomAmbientSoundTimer.StartTimer(__NFUN_172__(__NFUN_174__(RandomAmbientSoundInterval.Min, RandomAmbientSoundInterval.Max), 2.0000000));
	}
	super.PostLoadGame();
	return;
	@NULL
	Item
	Item
	@NULL
}

function Destroyed()
{
	FocusPollTimer.__TimerDelegate__Delegate = None;
	RandomAmbientSoundTimer.__TimerDelegate__Delegate = None;
	// End:0x65
	if(__NFUN_151__(UseFocusObservers.Length, 0))
	{
		UseFocusObservers.Remove(0, UseFocusObservers.Length);
		Level.UnRegisterNotifyActorDestroyed(self);
		super.Destroyed();
		return;
		@NULL
	}
	Item
	stop;
	default.@NULL
}

function PlayerTick(float DeltaTime)
{
	local int EyeHeightOffset;

	bDontProcessAnyMoreInputThisFrame = false;
	EyeHeightOffset = int(__NFUN_171__(xUp, float(40)));
	// End:0x43
	if(__NFUN_151__(EyeHeightOffset, 10))
	{
		EyeHeightOffset = 10;
		// End:0x75
		if(__NFUN_155__(int(bProcessLean), 0))
		{
			xStrafe = 0.0000000;
		}
		xForward = 0.0000000;
		goto J0x84;
		xUp = 0.0000000;
		OldLean = Lean;
		// End:0x1A8
		if(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_155__(int(bLeanLeft), 0), __NFUN_154__(int(bLeanRight), 0)), __NFUN_130__(__NFUN_180__(aBaseY, 0.0000000), __NFUN_180__(aStrafe, 0.0000000))), __NFUN_130__(__NFUN_180__(xForward, 0.0000000), __NFUN_180__(xStrafe, 0.0000000))))
		{
		}
		bIsInPCLeaningMode = true;
		__NFUN_184__(LeanVel, __NFUN_171__(LeanAccel, DeltaTime));
		// End:0x164
		if(__NFUN_177__(LeanVel, LeanMaxVel))
		{
			LeanVel = LeanMaxVel;
			__NFUN_185__(Lean, __NFUN_171__(LeanVel, DeltaTime));
			// End:0x1A5
			if(__NFUN_176__(Lean, -1.0000000))
			{
				Lean = -1.0000000;
				goto J0x354;
				// End:0x2B9
				if(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_155__(int(bLeanRight), 0), __NFUN_154__(int(bLeanLeft), 0)), __NFUN_130__(__NFUN_180__(aBaseY, 0.0000000), __NFUN_180__(aStrafe, 0.0000000))), __NFUN_130__(__NFUN_180__(xForward, 0.0000000), __NFUN_180__(xStrafe, 0.0000000))))
				{
				}
				bIsInPCLeaningMode = true;
				__NFUN_184__(LeanVel, __NFUN_171__(LeanAccel, DeltaTime));
			}
		}
		// End:0x275
		if(__NFUN_177__(LeanVel, LeanMaxVel))
		{
			LeanVel = LeanMaxVel;
			__NFUN_184__(Lean, __NFUN_171__(LeanVel, DeltaTime));
			// End:0x2B6
			if(__NFUN_177__(Lean, 1.0000000))
			{
				Lean = 1.0000000;
				goto J0x354;
				// End:0x338
				if(__NFUN_132__(__NFUN_132__(__NFUN_181__(aBaseY, 0.0000000), __NFUN_181__(aStrafe, 0.0000000)), __NFUN_132__(__NFUN_181__(xForward, 0.0000000), __NFUN_181__(xStrafe, 0.0000000))))
				{
					bIsInPCLeaningMode = false;
					Lean = 0.0000000;
					LeanVel = 0.0000000;
					goto J0x354;
					// End:0x354
					if(bIsInPCLeaningMode)
					{
						LeanVel = 0.0000000;
						// End:0x387
						if(__NFUN_155__(int(bProcessLean), 0))
						{
						}
						bIsInPCLeaningMode = false;
						Lean = xLean;
						goto J0x3B8;
						/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
							
						*/

						// End:0x3B8
						/*@Error*/
						Lean = 0.0000000;
						/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
							
						*/

						// End:0x3D4
						/*@Error*/
					}
				}
				Lean = 0.0000000;
				super.PlayerTick(DeltaTime);
				GetPlayerStatsManager().PlayerMovement(aForward, aStrafe);
				GetPlayerStatsManager().PlayerView(__NFUN_174__(xTurn, aTurn), __NFUN_174__(xLookup, aLookUp));
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x4B5
				/*@Error*/
			}
			ConsoleCommand("POPINPUTCONTEXT NullInput");
		}
		DispatchOnUsedEvents(UsedObjectPendingPlacement);
		UsedObjectPendingPlacement = none;
		return;
		@NULL
		Item
	}
	stop;
	default.@NULL
}

// Export UShockPlayerController::execInitCameraAnims(FFrame&, void* const)
native function InitCameraAnims();

function SetHeadbobContextState(ShockPlayerController.EHeadbobContext Context, bool State)
{
	//native.Context;
	//native.State;	
	@NULL
	@NULL
}

// Export UShockPlayerController::execGetDominantHeadbobContext(FFrame&, void* const)
native function ShockPlayerController.EHeadbobContext GetDominantHeadbobContext();

// Export UShockPlayerController::execGetPlayerStatsManager(FFrame&, void* const)
native event PlayerStatsManager GetPlayerStatsManager();

// Export UShockPlayerController::execGetTrainingMessageManager(FFrame&, void* const)
native event TrainingMessageManager GetTrainingMessageManager();

function EnableSaveGameOption()
{
	__NFUN_166__(SaveGameOptionDisabled);
	return;
	@NULL
}

function DisableSaveGameOption()
{
	__NFUN_165__(SaveGameOptionDisabled);
	return;
	@NULL
}

function QuickSave()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x93
	/*@Error*/
	LastQuickSaveTime = Level.TimeSeconds;
	super.QuickSave();
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function RegisterNotifyUseFocus(IObserveUseFocus Observer)
{
	local int i;

	assert(__NFUN_119__(Observer, none));
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB6
	/*@Error*/
	// End:0xA8
	if(__NFUN_114__(UseFocusObservers[i], Observer))
	{
		AssertWithDescription(false, __NFUN_112__(string(Observer.Name), " is registering use focus notification twice"));
		return;
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x1A;
		UseFocusObservers[UseFocusObservers.Length] = Observer;
		return;
		@NULL
		Item
	}
	stop;
	default.@NULL
}

function UnRegisterNotifyUseFocus(IObserveUseFocus Observer)
{
	local int i, numFound;

	numFound = 0;
	// End:0x8F
	if(__NFUN_151__(UseFocusObservers.Length, 0))
	{
		i = __NFUN_147__(UseFocusObservers.Length, 1);
		// End:0x8F
		if(__NFUN_153__(i, 0))
		{
			// End:0x81
			if(__NFUN_114__(UseFocusObservers[i], Observer))
			{
				UseFocusObservers.Remove(i, 1);
				__NFUN_163__(numFound);
				__NFUN_164__(i);
				// [Loop Continue]
				goto J0x32;
				AssertWithDescription(__NFUN_152__(numFound, 1), __NFUN_112__(string(Observer.Name), " registered use focus notification twice"));
			}
		}
	}
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function ICanBeFocused GetCurrentHighlightedFocus()
{
	return CurrentFocus;
	return;
	@NULL
}

function ICanBeFocused GetCurrentUseFocus()
{
	return CurrentUseFocus;
	return;
	@NULL
}

// Export UShockPlayerController::execResetFocii(FFrame&, void* const)
native event ResetFocii();

// Export UShockPlayerController::execUpdateFocus(FFrame&, void* const)
native function UpdateFocus();

// Export UShockPlayerController::execShouldUseController(FFrame&, void* const)
native function bool ShouldUseController();

function float GetMagicBulletRadius()
{
	local ShockPlayer Player;
	local Weapon Weapon;
	local AttackAbility Ability;

	Player = ShockPlayer(Pawn);
	// End:0xC7
	if(Player.GetHands().InWeaponsMode())
	{
		Weapon = Weapon(Player.GetActiveHoldable());
		// End:0xBE
		if(__NFUN_119__(Weapon, none))
		{
			// End:0xA4
			if(ShouldUseController())
			{
				return Weapon.MagicBulletRadius;
				goto J0xBB;
				return Weapon.MouseMagicBulletRadius;
				goto J0xC4;
				return 0.0000000;
				goto J0x147;
				Ability = AttackAbility(Player.GetActiveAbility());
			}
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x141
			/*@Error*/
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x127
		/*@Error*/
	}
	return Ability.MagicBulletRadius;
	goto J0x13E;
	return Ability.MouseMagicBulletRadius;
	goto J0x147;
	return 0.0000000;
	return;
	@NULL
	Item
	Item
	@NULL
}

function UseFocusClientMessage()
{
	local string KeyBindingString, UseFocusMessage;

	// End:0x75
	if(__NFUN_122__(Level.GetLocalPlayerController().ConsoleCommand("GETINPUTCONTEXT"), "MovementOnly"))
	{
		ClientMessage(CurrentUseFocus.GetFocusDisplayName(), 'FocusNoUse');
		return;
		UseFocusMessage = CurrentUseFocus.GetHUDMessageForUseFocusAttained(CurrentUseFocus);
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x11F
	/*@Error*/
	KeyBindingString = Level.GetFlashGUIController().SubstituteKeyMappingTags("<Mapping=Use> ", "Use");
	ClientMessage(__NFUN_112__(KeyBindingString, UseFocusMessage), 'UseFocus');
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function HackFocusClientMessage()
{
	local string KeyBindingString, HackFocusMessage;

	HackFocusMessage = CurrentHackFocus.GetHUDMessageForHackFocusAttained(CurrentHackFocus);
	// End:0x51
	if(__NFUN_124__(HackFocusMessage, "HACK"))
	{
		HackFocusMessage = LocalizedHackText;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xD3
		/*@Error*/
	}
	KeyBindingString = Level.GetFlashGUIController().SubstituteKeyMappingTags("<Mapping=Hack> ", "Hack");
	ClientMessage(__NFUN_112__(KeyBindingString, HackFocusMessage), 'HackFocus');
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function ShowReRollText()
{
	local string KeyBindingString;

	// End:0x88
	if(__NFUN_129__(Level.GetFlashGUIController().GetUseXBoxController()))
	{
		KeyBindingString = Level.GetFlashGUIController().SubstituteKeyMappingTags("<Mapping=ReRollContainer> ", "Re-Roll Container");
		ClientMessage(__NFUN_112__(KeyBindingString, ReRollText), 'ReRollFocus');
	}
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

event HideReRollText()
{
	ClientMessage("", 'ReRollFocus');
	return;
}

function SubtitleMessage(string S, float Duration, name Type, string Speaker)
{
	// End:0x34
	if(__NFUN_123__(Speaker, ""))
	{
		S = __NFUN_112__(__NFUN_112__(Speaker, ": "), S);
		ClientMessage(S, Type);
	}
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function TestSubtitle(name SubtitleName, name SubtitleType)
{
	ShockGameDriver(Level.GetGameDriver()).GetSubtitleManager().ShowSubtitle(SubtitleName, "Testing", SubtitleType, 10.0000000);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function ToggleWalk()
{
	// End:0x31
	if(GamepadPlayerInput(GetInput()).bWalkModifierOn)
	{
		WalkModifierOff();
		goto J0x3B;
		WalkModifierOn();
	}
	return;
	@NULL
	Item
}

function WalkModifierOn()
{
	GamepadPlayerInput(GetInput()).bWalkModifierOn = true;
	return;
	@NULL
	Item
}

function WalkModifierOff()
{
	GamepadPlayerInput(GetInput()).bWalkModifierOn = false;
	return;
	@NULL
	Item
}

function DuckKeyPressed()
{
	local GamepadPlayerInput Input;

	Input = GamepadPlayerInput(GetInput());
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x66
	/*@Error*/
	// End:0x57
	if(__NFUN_154__(int(bDuck), 1))
	{
		bDuck = 0;
		goto J0x63;
		bDuck = 1;
		goto J0x72;
		bDuck = 1;
		return;
		@NULL
	}
	Item
	default.Item
	J0x63:

	@NULL
}

function DuckKeyReleased()
{
	local GamepadPlayerInput Input;

	Input = GamepadPlayerInput(GetInput());
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x45
	/*@Error*/
	bDuck = 0;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function LogsPlaybackButtonPressed()
{
	// End:0x2F
	if(__NFUN_114__(CurrentUseFocus, none))
	{
		TimeLogsPlaybackButtonLastPressed = Level.TimeSeconds;
		return;
		@NULL
		Item
		default.Item
	}
	@NULL
}

function LogsPlaybackButtonReleased()
{
	TimeLogsPlaybackButtonLastPressed = 0.0000000;
	return;
	@NULL
}

function LogsPlaybackButtonHeld()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x6C
	/*@Error*/
	TimeLogsPlaybackButtonLastPressed = 0.0000000;
	PlayOldestUnreadLog();
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function HintButtonPressed()
{
	local name CurrentMovieName;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xE1
	/*@Error*/
	ShockPlayer(Pawn).LaunchMapScreen();
	CurrentMovieName = Level.GetFlashGUIController().GetTopPlayingMovie().Name;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xDE
	/*@Error*/
	Level.GetFlashGUIController().GetTopPlayingMovie().CallMethodVoid("ShowHideHint");
	goto J0x101;
	TimeHintButtonLastPressed = Level.TimeSeconds;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function HintButtonReleased()
{
	TimeHintButtonLastPressed = 0.0000000;
	return;
	@NULL
}

function HintButtonHeld()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xB2
	/*@Error*/
	TimeHintButtonLastPressed = 0.0000000;
	ShockPlayer(Pawn).LaunchMapScreen();
	Level.GetFlashGUIController().GetTopPlayingMovie().CallMethodVoid("ShowHideHint");
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function CrouchButtonPressed()
{
	TimeCrouchButtonLastPressed = Level.TimeSeconds;
	return;
	@NULL
	Item
	default.Item
}

function CrouchButtonReleased()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x77
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6B
	/*@Error*/
	bDuck = 0;
	goto J0x77;
	bDuck = 1;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function UpdateRadialMenu_LX()
{
	bRadialNotified_LX = true;
	UpdateRadialMenu();
	return;
	@NULL
}

function UpdateRadialMenu_LY()
{
	bRadialNotified_LY = true;
	UpdateRadialMenu();
	return;
	@NULL
}

function UpdateRadialMenu_RX()
{
	bRadialNotified_RX = true;
	UpdateRadialMenu();
	return;
	@NULL
}

function UpdateRadialMenu_RY()
{
	bRadialNotified_RY = true;
	UpdateRadialMenu();
	return;
	@NULL
}

function UpdateRadialMenu()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x218
	/*@Error*/
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodFloatFloat("CheckForRightRadialChange", xRadialRight, yRadialRight);
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodFloatFloat("CheckForLeftRadialChange", xRadialLeft, yRadialLeft);
	// End:0x17B
	if(bRightStickChanging)
	{
		Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodFloatFloat("UpdateRadialAxis", xRadialRight, yRadialRight);
		goto J0x1E8;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x1E8
		/*@Error*/
		Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodFloatFloat("UpdateRadialAxis", xRadialLeft, yRadialLeft);
	}
	bRadialNotified_LX = false;
	bRadialNotified_LY = false;
	bRadialNotified_RX = false;
	bRadialNotified_RY = false;
	return;
	@NULL
	Item
	Item
	@NULL
}

function LeftStickChanging(bool bChanging)
{
	bLeftStickChanging = bChanging;
	return;
	@NULL
	Item
}

function RightStickChanging(bool bChanging)
{
	bRightStickChanging = bChanging;
	return;
	@NULL
	Item
}

function UpdateAnalogControl()
{
	Level.GetFlashGUIController().GetTopPlayingMovie().CallMethodFloatFloat("UpdateRadialAxis", xRadialRight, yRadialRight);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function FadeOut()
{
	Level.GetFlashGUIController().PlayMovie('FadeOut');
	return;
	@NULL
	Item
}

function FadeIn()
{
	Level.GetFlashGUIController().StopMovie('FadeOut');
	Level.GetFlashGUIController().PlayMovie('FadeIn');
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function HideWidescreenBars()
{
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("HideWidescreenBars");
	SuppressTrainingMessages = false;
	return;
	@NULL
	Item
	default.Item
}

function ShowWidescreenBars()
{
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("ShowWidescreenBars");
	SuppressTrainingMessages = true;
	return;
	@NULL
	Item
	default.Item
}

function ClientMessage(coerce string S, optional name Type)
{
	switch(Type)
	{
		// End:0x17
		case 'UseFocus':
			// End:0x42
			case 'HackFocus':
			HUDMessage(S, Type);
			// End:0xF0
			break;
			// End:0x4E
			case 'Warning':
				// End:0x5A
				case 'ResearchLevelUp':
				// End:0x66
				case 'PlasmidReplacement':
				// End:0x72
				case 'HealthBarIncreased':
				// End:0x7E
				case 'EveBarIncreased':
				// End:0xCE
				case 'HackingSuccess':
				// End:0xCB
				if(__NFUN_129__(ShockPlayer(Pawn).disableInventoryWarnings))
				{/* !MISMATCHING REMOVE, tried Case got Type:If Position:0x07A! */
				WarningMessageBox(S, Type);
				// End:0xF0
				break;
				// End:0xFFFF
				default:
					HUDMessage(S, Type);
					// End:0xF0
					break;
					break;
			}/* !MISMATCHING REMOVE, tried Switch got Type:Case Position:0x032! */
			return;
			@NULL
			SetLabel
			default.@NULL
		}/* !MISMATCHING REMOVE, tried If got Type:Case Position:0x007! */
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		/*@Error*/
		// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.get_CurrentToken() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 40
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 845
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
		// 2 & Type:Case Position:0x0CE
	// Failed to format remaining nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 724
	// 1 & Type:Switch Position:0x0F0
}

function HUDMessage(string msg, name Type)
{
	log('HUD', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("CLIENTMESSAGE TYPE = [", string(Type)), "] MSG=["), msg), "]"));
	// End:0x5F
	if(bSuppressHUDMessages)
	{
		return;
		// End:0x196
		if(__NFUN_132__(__NFUN_132__(__NFUN_132__(__NFUN_254__(Type, 'None'), __NFUN_254__(Type, 'None')), __NFUN_254__(Type, 'Debug')), __NFUN_254__(Type, 'Event')))
		{
		}
		// End:0x172
		if(__NFUN_242__(Level.GetEngine().EnableDevTools, false))
		{
			log('HUD', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("*** IGNORING HUDMESSAGE TYPE = [", string(Type)), "] MSG=["), msg), "] BECAUSE ENGINE.ENABLEDEVTOOLS IS FALSE"));
			return;
			goto J0x196;
			msg = __NFUN_112__(__NFUN_112__("[DEBUG: ", msg), "]");
			log('HUD', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__("Sending Message of type '", string(Type)), "' to the HUD: "), msg));
		}
	}
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodStringString("HUDMessage", string(Type), msg);
	return;
	@NULL
	Freebie
	ShockPawn
	@NULL
}

function WarningMessageBox(string msg, name Type)
{
	// End:0x26
	if(__NFUN_114__(Level.Pauser, none))
	{
		Pause();
		Level.GetFlashGUIController().WarningMessageBox(msg, Type);
	}
	return;
	@NULL
	Freebie
	ShockPawn
	@NULL
}

function Rotator GetViewRotation()
{
	// End:0x35
	if(__NFUN_130__(bBehindView, __NFUN_119__(Pawn, none)))
	{
		return Pawn.Rotation;
		return __NFUN_316__(__NFUN_316__(Rotation, ShockPlayer(Pawn).ViewRotationOffset()), GetCameraAnimationOffsetRotation());
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function ClampPitchOfViewRotation(out Rotator inViewRotation)
{
	local float Pitch, UpperBounds, LowerBounds;

	Pitch = WrapAngleNegPiToPi(float(inViewRotation.Pitch));
	UpperBounds = WrapAngleNegPiToPi(18000.0000000);
	LowerBounds = WrapAngleNegPiToPi(49152.0000000);
	Pitch = __NFUN_246__(Pitch, LowerBounds, UpperBounds);
	inViewRotation.Pitch = int(WrapAngle0To2Pi(Pitch));
	return;
	@NULL
	Item
	Item
	@NULL
}

function ClampYawOfViewRotation(out Rotator inViewRotation)
{
	local int LeftYawLimit, RightYawLimit, ViewYawRelativeToLockedYaw;
	local float YawEdgeAlpha;
	local ShockPlayer thePlayer;

	thePlayer = ShockPlayer(Pawn);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x22E
	/*@Error*/
	ViewYawRelativeToLockedYaw = int(WrapAngle0To2Pi(float(__NFUN_147__(inViewRotation.Yaw, thePlayer.LeanLockedYaw))));
	YawEdgeAlpha = thePlayer.GetYawEdgeAlpha(inViewRotation.Pitch);
	thePlayer.GetLeanYawRanges(LeftYawLimit, RightYawLimit);
	LeftYawLimit = int(WrapAngle0To2Pi(__NFUN_175__(65536.0000000, __NFUN_171__(float(LeftYawLimit), YawEdgeAlpha))));
	RightYawLimit = int(WrapAngle0To2Pi(__NFUN_171__(float(RightYawLimit), YawEdgeAlpha)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1C6
	/*@Error*/
	inViewRotation.Yaw = __NFUN_146__(thePlayer.LeanLockedYaw, RightYawLimit);
	goto J0x22E;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x22E
	/*@Error*/
	inViewRotation.Yaw = __NFUN_146__(thePlayer.LeanLockedYaw, LeftYawLimit);
	return;
	@NULL
	Item
	Item
	@NULL
}

function ClampViewRotation(out Rotator inViewRotation)
{
	ClampPitchOfViewRotation(inViewRotation);
	ClampYawOfViewRotation(inViewRotation);
	return;
	@NULL
	Item
}

function CalcFirstPersonView(out Vector CameraLocation, out Rotator CameraRotation)
{
	CameraRotation = GetViewRotation();
	CameraLocation = __NFUN_215__(__NFUN_215__(__NFUN_215__(__NFUN_215__(CameraLocation, Pawn.EyePosition()), ShakeOffset), ShockPlayer(Pawn).ViewLocationOffset(CameraRotation)), GetCameraAnimationOffsetTranslation());
	return;
	@NULL
	Item
	Item
	@NULL
}

function ReactToDamage(name EffectEventName, Actor Damager)
{
	//native.EffectEventName;
	//native.Damager;	
	@NULL
	@NULL
}

function PlayRandomAmbientSound()
{
	local float DistanceToSound, Angle;
	local Vector ToSourcePlayerRelative, ToSource;
	local float NextInterval;

	log('Audio', 4, "Playing random ambient sound.");
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1EF
	/*@Error*/
	DistanceToSound = RandRange(DistanceToRandomAmbientSound.Min, DistanceToRandomAmbientSound.Max);
	RandomAmbientAngle = __NFUN_246__(RandomAmbientAngle, 1.0000000, 89.0000000);
	Angle = __NFUN_171__(__NFUN_172__(3.1415927, 180.0000000), RandRange(RandomAmbientAngle, __NFUN_175__(360.0000000, RandomAmbientAngle)));
	ToSourcePlayerRelative.X = __NFUN_171__(__NFUN_188__(Angle), DistanceToSound);
	ToSourcePlayerRelative.Y = __NFUN_171__(__NFUN_187__(Angle), DistanceToSound);
	ToSource = __NFUN_276__(ToSourcePlayerRelative, Pawn.Rotation);
	TriggerEffectEvent('PlayedRandomAmbientSound',,, __NFUN_215__(Pawn.Location, ToSource));
	log('Audio', 4, __NFUN_112__("...Playing sound at=", string(__NFUN_215__(Pawn.Location, ToSource))));
	NextInterval = RandRange(RandomAmbientSoundInterval.Min, RandomAmbientSoundInterval.Max);
	log('Audio', 4, __NFUN_112__("...NextInterval=", string(NextInterval)));
	RandomAmbientSoundTimer.StartTimer(NextInterval);
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool SetPause(bool bPause)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x76
	/*@Error*/
	return super.SetPause(bPause);
	return false;
	return;
	@NULL
	Engine
	default.@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

exec function ForcePause()
{
	SetPause(true);
	return;
}

exec event ForceUnPause()
{
	SetPause(false);
	return;
}

function bool DropObject()
{
	return ShockPlayer(Pawn).DropObject();
	return;
	@NULL
	Item
}

function ZoomCycle()
{
	ShockPlayer(Pawn).ZoomCycle();
	return;
	@NULL
	Item
}

function LeftMousePressed()
{
	local GamepadPlayerInput Input;

	Input = GamepadPlayerInput(GetInput());
	// End:0x82
	if(Input.bRightClickSwitchModeOn)
	{
		// End:0x75
		if(ShockPlayer(Pawn).GetHands().InWeaponsMode())
		{
			BeginFiring();
			goto J0x7F;
			UseActiveAbility();
			goto J0xE2;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0xD8
			/*@Error*/
		}
	}
	ShockPlayer(Pawn).SwitchHandModes();
	goto J0xE2;
	BeginFiring();
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function LeftMouseReleased()
{
	local GamepadPlayerInput Input;

	Input = GamepadPlayerInput(GetInput());
	// End:0x82
	if(Input.bRightClickSwitchModeOn)
	{
		// End:0x75
		if(ShockPlayer(Pawn).GetHands().InWeaponsMode())
		{
			CeaseFiring();
			goto J0x7F;
			UseActiveAbilityRelease();
			goto J0x8C;
			CeaseFiring();
			return;
		}
		@NULL
		Item
		default.Item
	}
	@NULL
}

function RightMousePressed()
{
	local GamepadPlayerInput Input;

	Input = GamepadPlayerInput(GetInput());
	// End:0x5A
	if(Input.bRightClickSwitchModeOn)
	{
		ShockPlayer(Pawn).SwitchHandModes();
		goto J0xB8;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xAE
		/*@Error*/
	}
	ShockPlayer(Pawn).SwitchHandModes();
	goto J0xB8;
	UseActiveAbility();
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function RightMouseReleased()
{
	local GamepadPlayerInput Input;

	Input = GamepadPlayerInput(GetInput());
	// End:0x43
	if(__NFUN_129__(Input.bRightClickSwitchModeOn))
	{
		UseActiveAbilityRelease();
		return;
		@NULL
		Item
		default.Item
	}
	@NULL
}

exec function OpenWeaponMenu()
{
	GetPlayerStatsManager().OpenWeaponMenu();
	CallHUDFunction('OpenWeaponMenu');
	ConsoleCommand("PUSHINPUTCONTEXT RADIALACTIVE");
	return;
}

exec function CloseWeaponMenu()
{
	GetPlayerStatsManager().CloseWeaponMenu();
	CallHUDFunction('RBReleased');
	ConsoleCommand("POPINPUTCONTEXT RADIALACTIVE");
	return;
}

function OpenAbilityMenu()
{
	GetPlayerStatsManager().OpenAbilityMenu(ShockPlayer(Pawn));
	CallHUDFunction('OpenAbilityMenu');
	ConsoleCommand("PUSHINPUTCONTEXT RADIALACTIVE");
	return;
	@NULL
	Item
}

exec function CloseAbilityMenu()
{
	GetPlayerStatsManager().CloseAbilityMenu();
	CallHUDFunction('LBReleased');
	ConsoleCommand("POPINPUTCONTEXT RADIALACTIVE");
	return;
}

function MouseWheelDownPressed()
{
	local int CurrentWeaponIndex;

	// End:0x146
	if(ShockPlayer(Pawn).GetHands().InWeaponsMode())
	{
		// End:0xA4
		if(__NFUN_119__(ShockPlayer(Pawn).GetActiveHoldable(), none))
		{
			CurrentWeaponIndex = ShockPlayer(Pawn).GetHoldableIndex(ShockPlayer(Pawn).GetActiveHoldable());
			goto J0xEE;
			CurrentWeaponIndex = ShockPlayer(Pawn).GetHoldableIndex(ShockPlayer(Pawn).GetPendingHoldable());
		}
		// End:0x12D
		if(__NFUN_152__(CurrentWeaponIndex, 0))
		{
			NumKeyPressed(__NFUN_147__(ShockPlayer(Pawn).GetNumHoldables(), 1));
			goto J0x143;
			NumKeyPressed(__NFUN_147__(CurrentWeaponIndex, 1));
			goto J0x1CA;
			SelectAbility(false);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x1CA
			/*@Error*/
			Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("ShowPCAbilitySelector");
		}
	}
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function MouseWheelUpPressed()
{
	local int CurrentWeaponIndex;

	// End:0x146
	if(ShockPlayer(Pawn).GetHands().InWeaponsMode())
	{
		// End:0xA4
		if(__NFUN_119__(ShockPlayer(Pawn).GetActiveHoldable(), none))
		{
			CurrentWeaponIndex = ShockPlayer(Pawn).GetHoldableIndex(ShockPlayer(Pawn).GetActiveHoldable());
			goto J0xEE;
			CurrentWeaponIndex = ShockPlayer(Pawn).GetHoldableIndex(ShockPlayer(Pawn).GetPendingHoldable());
		}
		// End:0x12D
		if(__NFUN_153__(CurrentWeaponIndex, __NFUN_147__(ShockPlayer(Pawn).GetNumHoldables(), 1)))
		{
			NumKeyPressed(0);
			goto J0x143;
			NumKeyPressed(__NFUN_146__(CurrentWeaponIndex, 1));
			goto J0x1CA;
			SelectAbility(true);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x1CA
			/*@Error*/
			Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("ShowPCAbilitySelector");
		}
	}
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function ActivatePausePCSelector()
{
	// End:0x86
	if(ShockPlayer(Pawn).GetHands().InWeaponsMode())
	{
		Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("ShowPCWeaponSelector");
		goto J0xD9;
		Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("ShowPCAbilitySelector");
	}
	Pause();
	return;
	@NULL
	Item
	default.Item
	@NULL
}

exec function DeactivatePausePCSelector()
{
	Pause();
	return;
}

function SelectAbility(bool Next)
{
	local int AbilityIndex;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x26A
	/*@Error*/
	AbilityIndex = 0;
	// End:0xD8
	if(__NFUN_150__(AbilityIndex, ShockPlayer(Pawn).AvailableAbilities.Length))
	{
		// End:0xCA
		if(__NFUN_254__(ShockPlayer(Pawn).GetActiveAbilityClass().Name, ShockPlayer(Pawn).AvailableAbilities[AbilityIndex].Name))
		{
			goto J0xD8;
			__NFUN_165__(AbilityIndex);
			// [Loop Continue]
			goto J0x31;
			// End:0x1A9
			if(Next)
			{
				// End:0x15A
				if(__NFUN_154__(AbilityIndex, __NFUN_147__(ShockPlayer(Pawn).AvailableAbilities.Length, 1)))
				{
					ShockPlayer(Pawn).SetActiveAbilityClass(ShockPlayer(Pawn).AvailableAbilities[0]);
				}
			}
			goto J0x1A6;
			ShockPlayer(Pawn).SetActiveAbilityClass(ShockPlayer(Pawn).AvailableAbilities[__NFUN_146__(AbilityIndex, 1)]);
			goto J0x26A;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x21E
			/*@Error*/
			ShockPlayer(Pawn).SetActiveAbilityClass(ShockPlayer(Pawn).AvailableAbilities[__NFUN_147__(ShockPlayer(Pawn).AvailableAbilities.Length, 1)]);
		}
		goto J0x26A;
		ShockPlayer(Pawn).SetActiveAbilityClass(ShockPlayer(Pawn).AvailableAbilities[__NFUN_147__(AbilityIndex, 1)]);
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function FKeyPressed(int Index)
{
	local Ability newAbility;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x19E
	/*@Error*/
	newAbility = ShockPlayer(Pawn).GetAbilityFromClass(ShockPlayer(Pawn).AvailableAbilities[Index]);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x19E
	/*@Error*/
	ShockPlayer(Pawn).SetActiveAbilityClass(ShockPlayer(Pawn).AvailableAbilities[Index], true);
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("ShowPCAbilitySelector");
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function NumKeyPressed(int Index)
{
	local Holdable theWeapon;

	theWeapon = ShockPlayer(Pawn).GetHoldable(Index);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x294
	/*@Error*/
	ShockPlayer(Pawn).Equip(theWeapon, true);
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("ShowPCWeaponSelector");
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodString("SelectAmmo", string(Weapon(theWeapon).GetCurrentAmmoSelection().Name));
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function BeginFiring(optional bool inAltFire)
{
	bDontProcessAnyMoreInputThisFrame = __NFUN_132__(bDontProcessAnyMoreInputThisFrame, DropObject());
	// End:0x33
	if(bDontProcessAnyMoreInputThisFrame)
	{
		return;
		ShockPlayer(Pawn).BeginFiring(inAltFire);
	}
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function CeaseFiring(optional bool inAltFire)
{
	ShockPlayer(Pawn).CeaseFiring(inAltFire);
	return;
	@NULL
	Item
	default.Item
}

function UseActiveAbility()
{
	ShockPlayer(Pawn).UseActiveAbility();
	return;
	@NULL
	Item
}

function UseActiveAbilityRelease()
{
	ShockPlayer(Pawn).UseActiveAbilityRelease();
	return;
	@NULL
	Item
}

function HandleReloadAndBioAmmo()
{
	// End:0x20
	if(__NFUN_130__(ShouldUseController(), __NFUN_119__(CurrentHackFocus, none)))
	{
		return;
		// End:0x5E
		if(ShockPlayer(Pawn).GetHands().InWeaponsMode())
		{
		}
		Reload();
		goto J0xA4;
		bDontProcessAnyMoreInputThisFrame = __NFUN_132__(bDontProcessAnyMoreInputThisFrame, DropObject());
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA4
	/*@Error*/
	UseHypoOfType('BioAmmoHypo');
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function UseHypoOfType(name HypoType)
{
	ShockPlayer(Pawn).UseHypoByClassName(HypoType);
	return;
	@NULL
	Item
	default.Item
}

function InjectBioAmmo()
{
	bDontProcessAnyMoreInputThisFrame = __NFUN_132__(bDontProcessAnyMoreInputThisFrame, DropObject());
	// End:0x33
	if(bDontProcessAnyMoreInputThisFrame)
	{
		return;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xAC
		/*@Error*/
	}
	ShockPlayer(Pawn).UseHypoByClassName('BioAmmoHypo');
	bDontProcessAnyMoreInputThisFrame = true;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function UseActiveHypo()
{
	CallHUDFunction('HighlightHypo');
	// End:0x24
	if(__NFUN_119__(CurrentHackFocus, none))
	{
		return;
		ShockPlayer(Pawn).UseActiveUsableItem();
	}
	return;
	@NULL
	Item
	default.Item
}

function Reload()
{
	local name handsState;

	// End:0x1E
	if(__NFUN_119__(Level.Pauser, none))
	{
		return;
		bDontProcessAnyMoreInputThisFrame = __NFUN_132__(bDontProcessAnyMoreInputThisFrame, DropObject());
	}
	// End:0x51
	if(bDontProcessAnyMoreInputThisFrame)
	{
		return;
		handsState = ShockPlayer(Pawn).GetHands().__NFUN_284__();
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xEB
	/*@Error*/
	ShockPlayer(Pawn).ReloadWeapon();
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function QuickEquipUp()
{
	bDontProcessAnyMoreInputThisFrame = __NFUN_132__(bDontProcessAnyMoreInputThisFrame, DropObject());
	// End:0x33
	if(bDontProcessAnyMoreInputThisFrame)
	{
		return;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xB5
		/*@Error*/
	}
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("QuickEquipUp");
	TriggerEffectEvent('UIHighlightMoved');
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function QuickEquipDown()
{
	bDontProcessAnyMoreInputThisFrame = __NFUN_132__(bDontProcessAnyMoreInputThisFrame, DropObject());
	// End:0x33
	if(bDontProcessAnyMoreInputThisFrame)
	{
		return;
		Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("QuickEquipDown");
	}
	TriggerEffectEvent('UIHighlightMoved');
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function QuickEquipLeft()
{
	bDontProcessAnyMoreInputThisFrame = __NFUN_132__(bDontProcessAnyMoreInputThisFrame, DropObject());
	// End:0x33
	if(bDontProcessAnyMoreInputThisFrame)
	{
		return;
		Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("QuickEquipLeft");
	}
	TriggerEffectEvent('UIHighlightMoved');
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function QuickEquipRight()
{
	bDontProcessAnyMoreInputThisFrame = __NFUN_132__(bDontProcessAnyMoreInputThisFrame, DropObject());
	// End:0x33
	if(bDontProcessAnyMoreInputThisFrame)
	{
		return;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xB8
		/*@Error*/
	}
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("QuickEquipRight");
	TriggerEffectEvent('UIHighlightMoved');
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function CallHUDFunction(name FunctionName)
{
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid(string(FunctionName));
	TriggerEffectEvent(FunctionName);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function ShowEnemyInfoHud(ShockPawn Pawn)
{
	//native.Pawn;	
	@NULL
}

function TakePhoto()
{
	local ResearchCamera Camera;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x8D
	/*@Error*/
	Camera = ResearchCamera(ShockPawn(Pawn).GetActiveHoldable());
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x8D
	/*@Error*/
	Camera.InitiateDamage('None');
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function PauseGame()
{
	DropObject();
	CeaseFiring();
	// End:0x14D
	if(__NFUN_119__(Level.GetFlashGUIController().GetPlayingMovie('Pause'), none))
	{
		SetPause(false);
		// End:0xEE
		if(__NFUN_119__(Level.GetFlashGUIController().GetPlayingMovie('Hacking'), none))
		{
			Level.GetFlashGUIController().GetPlayingMovie('Hacking').CallMethodVoid("UnpauseHackingGame");
			Level.StartHackingTimer();
			Level.GetFlashGUIController().StopMovie('Pause');
		}
		Level.GetFlashGUIController().UnhideMovie('HUD');
		goto J0x68D;
		// End:0x15C
		if(bDisablePause)
		{
			return;
			// End:0x1F5
			if(__NFUN_119__(Level.GetFlashGUIController().GetPlayingMovie('Hacking'), none))
			{
			}
			Level.GetFlashGUIController().GetPlayingMovie('Hacking').CallMethodVoid("PauseHackingGame");
		}
		Level.StopHackingTimer();
		Level.GetFlashGUIController().PlayMovie('Pause');
		// End:0x32C
		if(Level.bIsDLC1Level)
		{
			// End:0x2D6
			if(__NFUN_124__(string(Level.Outer.Name), "ChallengeRoomCombat"))
			{
			}
			Level.GetFlashGUIController().GetPlayingMovie('Pause').CallMethodString("UseDLC1PauseScreen", "false");
			goto J0x32C;
			Level.GetFlashGUIController().GetPlayingMovie('Pause').CallMethodString("UseDLC1PauseScreen", "true");
			Level.GetFlashGUIController().GetPlayingMovie('Pause').CallMethodVoid("SwitchToPauseScreen");
		}
		// End:0x3DA
		if(__NFUN_151__(SaveGameOptionDisabled, 0))
		{
			Level.GetFlashGUIController().GetPlayingMovie('Pause').CallMethodVoid("SaveGameDisabled");
		}
		Level.GetFlashGUIController().GetPlayingMovie('Pause').CallMethodInt("ShowCreditsCount", ShockPlayer(Pawn).GetCredits());
		Level.GetFlashGUIController().GetPlayingMovie('Pause').CallMethodInt("ShowAdamCount", ShockPlayer(Pawn).GetADAM());
	}
	Level.GetFlashGUIController().GetPlayingMovie('Pause').CallMethodInt("ShowNumSavedGatherersThisLevel", ShockGameInfo(Level.Game).GetNumSavedGatherersThisLevel());
	Level.GetFlashGUIController().GetPlayingMovie('Pause').CallMethodInt("ShowNumHarvestedGatherersThisLevel", ShockGameInfo(Level.Game).GetNumHarvestedGatherersThisLevel());
	Level.GetFlashGUIController().GetPlayingMovie('Pause').CallMethodInt("ShowNumRoamingGatherersThisLevel", ShockGameInfo(Level.Game).GetNumRoamingGatherersThisLevel());
	SetPause(true);
	Level.GetFlashGUIController().HideMovie('HUD');
	return;
	@NULL
	Item
	default.Item
	@NULL
}

// Export UShockPlayerController::execSaveOutPlayerStats(FFrame&, void* const)
native exec function SaveOutPlayerStats();

event SavePlayer()
{
	SaveOutPlayerStats();
	return;
}

function OpenInventory()
{
	// End:0x11
	if(__NFUN_119__(CurrentHackFocus, none))
	{
		return;
		ShockPlayer(Pawn).OpenInventory();
	}
	return;
	@NULL
	Item
	default.Item
}

function PlayOldestUnreadLog()
{
	ShockPlayer(Pawn).PlayMostRecentLogEntry();
	return;
	@NULL
	Item
}

exec function HarvestGathererExec()
{
	Hack();
	return;
}

exec function SaveGathererExec()
{
	Use();
	return;
}

function Use()
{
	local Vector UsedObjectRequiredWorldSpaceLocation;
	local Rotator UsedObjectRequiredWorldSpaceRotation;

	// End:0x48
	if(__NFUN_119__(ShockPlayer(Pawn).GetCurrentContainer(), none))
	{
		ShockPlayer(Pawn).TakeAll();
		return;
		// End:0xB1
		if(__NFUN_114__(CurrentUseFocus, none))
		{
			log('Use', 4, "No CurrentUseFocus to use. Switch to camera or back");
		}
		CallHUDFunction('UseAttempted');
		return;
		// End:0x15E
		if(__NFUN_129__(CurrentUseFocus.CanBeUsedNow()))
		{
		}
		log('Use', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("CurrentUseFocus can't be used now. Focus=(", string(CurrentUseFocus.Name)), " of type "), string(CurrentUseFocus.Class.Name)), ")"));
		return;
		// End:0x16D
		if(bDontProcessAnyMoreInputThisFrame)
		{
			return;
			// End:0x1AF
			if(__NFUN_129__(CurrentUseFocus.__NFUN_303__('IAffectedByTelekinesis')))
			{
				bDontProcessAnyMoreInputThisFrame = __NFUN_132__(bDontProcessAnyMoreInputThisFrame, DropObject());
			}
		}
		bDontProcessAnyMoreInputThisFrame = true;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x2ED
		/*@Error*/
		log('Use', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Adjusting player position before using: Focus=(", string(CurrentUseFocus.Name)), " of type "), string(CurrentUseFocus.Class.Name)), ")"));
	}
	UsedObjectPendingPlacement = CurrentUseFocus;
	ConsoleCommand("PUSHINPUTCONTEXT NullInput");
	StartForcePlayerMove(UsedObjectRequiredWorldSpaceLocation, UsedObjectRequiredWorldSpaceRotation);
	goto J0x347;
	LastUsedObject = CurrentUseFocus;
	LastUsedObjectNotCleared = CurrentUseFocus;
	__NFUN_163__(Actor(LastUsedObject).SendDestructionNotification);
	DispatchOnUsedEvents(CurrentUseFocus);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function DispatchOnUsedEvents(ICanBeUsed UsableObject)
{
	log('Use', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Using: Focus=(", string(UsableObject.Name)), " of type "), string(UsableObject.Class.Name)), ")"));
	UsableObject.OnUsed(Pawn);
	GetPlayerStatsManager().PlayerUse(UsableObject);
	Actor(UsableObject).dispatchMessage(Class'ShockGame.MessagePlayerUsedObject'.static.Allocate(self)., construct_ICanBeUsed(UsableObject));
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function UseStopped()
{
	// End:0x5B
	if(__NFUN_114__(LastUsedObject, none))
	{
		log('Use', 4, "UseStopped: No object is in use (LastUsedObject = None).");
		return;
		DispatchOnUsedStoppedEvents(LastUsedObject);
	}
	__NFUN_164__(Actor(LastUsedObject).SendDestructionNotification);
	LastUsedObject = none;
	return;
	@NULL
	Item
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x02
	/*@Error*/
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.get_CurrentToken() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 40
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 834
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 2 & Type:Case Position:0x002
	// Failed to format remaining nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.get_CurrentToken() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 40
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 834
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 724
	// 2 & Type:Case Position:0x002
}

function ICanBeUsed GetCurrentUsedObject()
{
	return LastUsedObjectNotCleared;
	return;
	@NULL
}

function OnOtherActorDestroyed(Actor ActorBeingDestroyed)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xBF
	/*@Error*/
	log('Use', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Object in use was destroyed before use stopped (LastUsedObject = ", string(LastUsedObject)), ", ActorBeingDestroyed="), string(ActorBeingDestroyed)), ")."));
	UseStopped();
	return;
	@NULL
	Item
	Item
	@NULL
}

function DispatchOnUsedStoppedEvents(ICanBeUsed UsableObject)
{
	log('Use', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Using Stopped: LastUsedObject=(", string(LastUsedObject.Name)), " of type "), string(LastUsedObject.Class.Name)), ")"));
	LastUsedObject.OnUseStopped(Pawn);
	Actor(LastUsedObject).dispatchMessage(Class'ShockGame.MessagePlayerFinishedUsingObject'.static.Allocate(self)., construct_ICanBeUsed(LastUsedObject));
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function OnInputContextChanged(name ContextName)
{
	switch(ContextName)
	{
		// End:0x17
		case 'Default':
			// End:0x23
			case 'RadialActive':
			// End:0x2F
			case 'GathererChoice':
			// End:0x3B
			case 'InventoryUIActive':
			// End:0x47
			case 'ContainerUIActive':
			// End:0x53
			case 'WarningUIActive':
			// End:0x62
			case 'PhotoGradingUIActive':
			// End:0x74
			break;
			// End:0xFFFF
			default:
				bProcessLean = 0;
				break;/* Tried to find Switch scope, found Case instead */
		goto J0x74;
		return;
		@NULL
		Item
	}
}

function Actor GetCameraFocusTarget()
{
	local ShockPlayer Player;

	Player = ShockPlayer(Pawn);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x69
	/*@Error*/
	return Actor(Player.CurrentPhotoSubject);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function StartForcePlayerMove(Vector TargetLocation, Rotator TargetRotation, optional float LocationDeltaPerSecond, optional float RotationDeltaPerSecond)
{
	bIsForcingPlayerMove = true;
	ForcePlayerMoveTargetLocation = TargetLocation;
	ForcePlayerMoveTargetRotation = TargetRotation;
	ForceMoveLocationDeltaPerSecond = LocationDeltaPerSecond;
	ForceMoveRotationDeltaPerSecond = RotationDeltaPerSecond;
	// End:0x91
	if(__NFUN_178__(ForceMoveLocationDeltaPerSecond, 0.0000000))
	{
		ForceMoveLocationDeltaPerSecond = default.ForceMoveLocationDeltaPerSecond;
		assert(__NFUN_177__(ForceMoveLocationDeltaPerSecond, 0.0000000));
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xCA
		/*@Error*/
		ForceMoveRotationDeltaPerSecond = default.ForceMoveRotationDeltaPerSecond;
		assert(__NFUN_177__(ForceMoveRotationDeltaPerSecond, 0.0000000));
		return;
		@NULL
		Item
	}
	Item
	@NULL
}

function StopForcePlayerMove()
{
	bIsForcingPlayerMove = false;
	return;
	@NULL
}

function bool IsForcingPlayerMove()
{
	return bIsForcingPlayerMove;
	return;
	@NULL
}

function LatentForcePlayerMove(Vector TargetLocation, Rotator TargetRotation, optional float TimeOut, optional float LocationDeltaPerSecond, optional float RotationDeltaPerSecond)
{
	local float StartExecutionTime;

	StartExecutionTime = Level.TimeSeconds;
	StartForcePlayerMove(TargetLocation, TargetRotation, LocationDeltaPerSecond, RotationDeltaPerSecond);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xAD
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA2
	/*@Error*/
	goto J0xAD;
	__NFUN_256__(0.0000000);
	// [Loop Continue]
	goto J0x4E;
	StopForcePlayerMove();
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function Hack()
{
	log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::Hack() .... Level.GetFlashGUIController().IsPausedInterfaceActive() = "), string(Level.GetFlashGUIController().IsPausedInterfaceActive())), ", CurrentHackFocus = "), string(CurrentHackFocus)), ", CurrentHackFocus.CanBeHackedNow(ShockPlayer(Pawn)) = "), string(CurrentHackFocus.CanBeHackedNow(ShockPlayer(Pawn)))));
	bDontProcessAnyMoreInputThisFrame = __NFUN_132__(bDontProcessAnyMoreInputThisFrame, DropObject());
	// End:0x16C
	if(__NFUN_130__(__NFUN_129__(Level.GetFlashGUIController().IsPausedInterfaceActive()), bDontProcessAnyMoreInputThisFrame))
	{
		return;
		// End:0x1AB
		if(__NFUN_114__(CurrentHackFocus, none))
		{
			log('Hack', 4, "No CurrentHackFocus to hack.");
		}
		return;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x26B
		/*@Error*/
		log('Hack', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("CurrentHackFocus can't be used now. Focus=(", string(CurrentHackFocus.Name)), " of type "), string(CurrentHackFocus.Class.Name)), ")"));
	}
	return;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2BA
	/*@Error*/
	CurrentHackFocus.OnHackAttempted(ShockPlayer(Pawn));
	bDontProcessAnyMoreInputThisFrame = true;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function ICanBeHacked GetCurrentHackFocus()
{
	return CurrentHackFocus;
	return;
	@NULL
}

function SetLeanAccel(float Accel)
{
	LeanAccel = Accel;
	return;
	@NULL
	Item
}

function SetLeanMaxVel(float MaxVel)
{
	LeanMaxVel = MaxVel;
	return;
	@NULL
	Item
}

function InventoryUp()
{
	Level.GetFlashGUIController().GetPlayingMovie('Inventory').CallMethodVoid("InventoryUp");
	TriggerEffectEvent('UIHighlightMoved');
	return;
	@NULL
	Item
}

function InventoryDown()
{
	Level.GetFlashGUIController().GetPlayingMovie('Inventory').CallMethodVoid("InventoryDown");
	TriggerEffectEvent('UIHighlightMoved');
	return;
	@NULL
	Item
}

function InventoryLeft()
{
	Level.GetFlashGUIController().GetPlayingMovie('Inventory').CallMethodVoid("InventoryLeft");
	TriggerEffectEvent('UIHighlightMoved');
	return;
	@NULL
	Item
}

function InventoryRight()
{
	Level.GetFlashGUIController().GetPlayingMovie('Inventory').CallMethodVoid("InventoryRight");
	TriggerEffectEvent('UIHighlightMoved');
	return;
	@NULL
	Item
}

function UseItemFromInventory()
{
	ShockPlayer(Pawn).UseSelectedInventoryItem();
	return;
	@NULL
	Item
}

function RecycleOrDestroyInventoryItem()
{
	ShockPlayer(Pawn).RecycleOrDestroySelectedInventoryItem();
	TriggerEffectEvent('UIRecycledInventoryItem');
	return;
	@NULL
	Item
}

function ToggleInventories()
{
	ShockPlayer(Pawn).SwitchInventory();
	return;
	@NULL
	Item
}

function AddTextToTraining(string TextToAdd)
{
	ShockPlayer(Pawn).AddTextToTraining(TextToAdd);
	return;
	@NULL
	Item
	default.Item
}

function DismissTraining()
{
	ShockPlayer(Pawn).DismissTraining();
	return;
	@NULL
	Item
}

function ShowTrainingHelp()
{
	// End:0x33
	if(__NFUN_254__(Level.Outer.Name, 'Museum'))
	{
		return;
		// End:0xD1
		if(__NFUN_255__(CurrentTrainingHelpTag, 'None'))
		{
		}
		ForcePause();
		ShockPlayer(Pawn).LaunchInGameManualScreen();
		Level.GetFlashGUIController().GetPlayingMovie('InGameManual').CallMethodString("SelectTopicByName", string(CurrentTrainingHelpTag));
		goto J0xFB;
		ForcePause();
		ShockPlayer(Pawn).LaunchInfoPanel();
		return;
	}
	@NULL
	Item
	default.Item
	@NULL
}

function ShowContextHelp()
{
	local name CurrentMovieName;

	// End:0x33
	if(__NFUN_254__(Level.Outer.Name, 'Museum'))
	{
		return;
		CurrentMovieName = Level.GetFlashGUIController().GetTopPlayingMovie().Name;
	}
	// End:0xEE
	if(__NFUN_130__(__NFUN_132__(__NFUN_254__(CurrentMovieName, 'Maps'), __NFUN_254__(CurrentMovieName, 'InGameManual')), __NFUN_129__(Level.GetFlashGUIController().GetUseXBoxController())))
	{
		ShockPlayer(Pawn).LaunchMapScreen();
		goto J0x275;
		// End:0x14E
		if(__NFUN_255__(CurrentMovieName, 'HUD'))
		{
			Level.GetFlashGUIController().GetPlayingMovie(CurrentMovieName).CallMethodVoid("ShowHelp");
		}
		goto J0x275;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x21E
		/*@Error*/
		ShockPlayer(Pawn).LaunchInGameManualScreen();
	}
	Level.GetFlashGUIController().GetPlayingMovie('InGameManual').CallMethodString("SelectTopicByName", string(Actor(CurrentFocus).HelpTag));
	return;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x26B
	/*@Error*/
	ShockPlayer(Pawn).LaunchMapScreen();
	goto J0x275;
	ShowTrainingHelp();
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function CloseHacking()
{
	ShockPlayer(Pawn).CloseHackingScreen();
	return;
	@NULL
	Item
}

function CloseInventory()
{
	ShockPlayer(Pawn).CloseInventory();
	return;
	@NULL
	Item
}

function CloseLogs()
{
	ShockPlayer(Pawn).CloseRadioMessagesScreen();
	ShockPlayer(Pawn).CloseLogScreen();
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function CloseInGameManual()
{
	ShockPlayer(Pawn).CloseInGameManualScreen();
	return;
	@NULL
	Item
}

function CloseRadioMessages()
{
	ShockPlayer(Pawn).CloseRadioMessagesScreen();
	return;
	@NULL
	Item
}

function ClosePlasmiNow()
{
	ShockPlayer(Pawn).ClosePlasmiNowScreen();
	return;
	@NULL
	Item
}

function CloseMaps()
{
	ShockPlayer(Pawn).CloseMapScreen();
	return;
	@NULL
	Item
}

function CloseQuests()
{
	ShockPlayer(Pawn).CloseQuestsScreen();
	return;
	@NULL
	Item
}

function RecycleOrDestroyContainerSlot(int slotNum)
{
	ShockPlayer(Pawn).RecycleOrDestroyContainerSlot(slotNum);
	return;
	@NULL
	Item
	default.Item
}

function CollectContainerItemInSlot(int slotNum)
{
	ShockPlayer(Pawn).TakeSlot(slotNum);
	return;
	@NULL
	Item
	default.Item
}

function CollectAllContainerItems()
{
	ShockPlayer(Pawn).TakeAll();
	return;
	@NULL
	Item
}

function CloseContainer()
{
	ShockPlayer(Pawn).CloseContainer();
	return;
	@NULL
	Item
}

function ChangeHandTile()
{
	Level.GetFlashGUIController().GetTopPlayingMovie().CallMethodVoid("ChangeHandTile");
	return;
	@NULL
	Item
}

function AutoHack()
{
	Level.GetFlashGUIController().GetTopPlayingMovie().CallMethodVoid("AutoHack");
	return;
	@NULL
	Item
}

function AttemptCreditsOverride()
{
	Level.GetFlashGUIController().GetTopPlayingMovie().CallMethodVoid("CreditsOverride");
	return;
	@NULL
	Item
}

function HackThroughUI()
{
	Level.GetFlashGUIController().GetTopPlayingMovie().CallMethodVoid("HackThroughUI");
	return;
	@NULL
	Item
}

function MapZoomIn()
{
	Level.GetFlashGUIController().GetTopPlayingMovie().CallMethodVoid("MapZoomIn");
	TriggerEffectEvent('UIHighlightMoved');
	return;
	@NULL
	Item
}

function MapZoomOut()
{
	Level.GetFlashGUIController().GetTopPlayingMovie().CallMethodVoid("MapZoomOut");
	TriggerEffectEvent('UIHighlightMoved');
	return;
	@NULL
	Item
}

function ConfirmAndExit()
{
	Level.GetFlashGUIController().GetPlayingMovie('PlasmidEquip').CallMethodVoid("ConfirmAndExit");
	ShockPlayer(Pawn).ResetUIState();
	TriggerEffectEvent('UIConfirmAndExit');
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function BackToCharacterScreen()
{
	Level.GetFlashGUIController().GetPlayingMovie('PlasmidEquip').CallMethodVoid("BackToCharacterScreen");
	TriggerEffectEvent('UIConfirmAndExit');
	return;
	@NULL
	Item
}

function UndoLastChange()
{
	Level.GetFlashGUIController().GetPlayingMovie('PlasmidEquip').CallMethodVoid("UndoLastChange");
	return;
	@NULL
	Item
}

function SelectNextTrack()
{
	Level.GetFlashGUIController().GetPlayingMovie('PlasmidEquip').CallMethodVoid("InventoryRight");
	return;
	@NULL
	Item
}

function SelectPreviousTrack()
{
	Level.GetFlashGUIController().GetPlayingMovie('PlasmidEquip').CallMethodVoid("InventoryRight");
	return;
	@NULL
	Item
}

function HACK_TriggerEffectEvent(string EffectEvent)
{
	TriggerEffectEvent(string(EffectEvent));
	return;
	@NULL
}

function HACK_UnTriggerEffectEvent(string EffectEvent)
{
	UnTriggerEffectEvent(string(EffectEvent));
	return;
	@NULL
}

function NextScreen()
{
	log('something', 1, "calling NextScreen");
	Level.GetFlashGUIController().GetPlayingMovie('SplashScreen').CallMethodVoid("NextScreen");
	return;
	@NULL
	Item
}

function bool IsLevelSwitchingEnabled()
{
	return __NFUN_130__(__NFUN_129__(LevelSwitchingDisabled), __NFUN_129__(ShockPlayer(Pawn).IsCriticalLogPlaying()));
	return;
	@NULL
	Item
	Item
}

function SetCameraAnimationRateChangeModifier(float NewRate)
{
	//native.NewRate;	
	@NULL
}

// Export UShockPlayerController::execClearCameraAnimationRateChangeModifier(FFrame&, void* const)
native function ClearCameraAnimationRateChangeModifier();

function SetCameraAnimationModifier_HeadbobContextController(ShockPlayerController.EHeadbobContext Context)
{
	//native.Context;	
	@NULL
}

// Export UShockPlayerController::execClearCameraAnimationModifier_HeadbobContextController(FFrame&, void* const)
native function ClearCameraAnimationModifier_HeadbobContextController();

state PlayerWalking
{	stop;
}

defaultproperties
{
	HeadbobSpeedControlPt_2=0.3300000
	HeadbobSpeedControlPt_3=0.6600000
	HeadbobSpeedControlPt_4=1.2000000
	FocusTestDistance=256.0000000
	UseFocusTestDistance=256.0000000
	HackFocusTestDistance=256.0000000
	ArtSubtitleTestDistance=2000.0000000
	FocusTestInterval=0.1250000
	RandomAmbientSoundInterval=(Min=3.0000000,Max=12.0000000)
	DistanceToRandomAmbientSound=(Min=1000.0000000,Max=2000.0000000)
	RandomAmbientAngle=60.0000000
	ForceMoveLocationDeltaPerSecond=500.0000000
	ForceMoveRotationDeltaPerSecond=65536.0000000
	LeanMaxVel=5.0000000
	LeanAccel=15.0000000
	bUseStickyBasedFocus=true
	CrouchTapTime=0.5000000
	LogsPlaybackHoldTime=0.8000000
	HintHoldTime=0.5000000
	PacifyText="HARVEST"
	SaveText="RESCUE"
	ReRollText="Search Again"
	WhatIsThisText="WHAT IS THIS?"
	PCWhatIsThisText="<Mapping=ShowContextHelp> WHAT IS THIS?"
	LocalizedHackText="HACK"
	CollectText="Rescue"
	CheatClass=Class'ShockGame.ShockCheatManager'
	CameraAnimationPackageName="PlayerCameraAnim"
	CameraAnimationBoneName="CameraDummy"
}