class SecurityCamera extends SecurityElement implements ICanBeHacked, IWatchForPlayerBeingAttackedByProtector
	abstract
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

var private config name PitchBoneName;
var private config name YawBoneName;
var private config name LensDamageMultiplierBone;
var private config float LensDamageMultiplier;
var private config int SearchingPitchSpeed;
var private config int SearchingYawSpeed;
var private config int AlertedPitchSpeed;
var private config int AlertedYawSpeed;
var private config int DormantPitch;
var private config float SearchLimitPauseTime;
var private config float PlayerBaseInspectionTimerAmount;
var private config float AIBaseInspectionTimerAmount;
var private config float SecurityBeaconInspectionTimerAmount;
var private config float LostContactTimerAmount;
var private config float SearchingInspectionPauseTime;
var private config float AlertedTargetLostPauseTime;
var private config float SearchingInspectionPanOvershootTime;
var config Class<SecurityBot> SecurityBotClass;
var config int NumSecurityBotsSpawned;
var private config Class<SecurityCameraDeadBody> DeadBodyClass;
var private config name DeadBodyAttachBone;
var private config float DeadBodyExplosionForce;
var private config float EventNotificationCylinderRadius;
var private config float EventNotificationCylinderHeight;
var private config float ShockedDormantDelay;
var private config float FrozenTransitionTime;
var private config float InspectLostTargetTestPeriod;
var private config float InspectLostTargetDuration;
var const config float AlertedReturnToCannotSeeStateWhenDamaged;
var private config bool DoNotTrackInspectTargetWhenOutsideOfMaximumYawRange;
var private config Color HackedSearchingSpotlightColor;
var private config Color NotHackedSearchingSpotlightColor;
var private config float HackedSearchingSpotlightBrightness;
var private config float NotHackedSearchingSpotlightBrightness;
var private int LeftYawLimit;
var private int RightYawLimit;
var private int PanningLeftYawLimit;
var private int PanningRightYawLimit;
var private int UpperPitchLimit;
var private int LowerPitchLimit;
var private int DefaultPitch;
var config Class<SecurityCameraLight> SpotlightClass;
var private Light Spotlight;
var private bool bIsHacked;
var bool CanBeHacked;
var private name HackInfoName;
var private transient HackInfo HackingGameSetupInfo;
var private config localized string HackingSuccessFeedbackText;
var private Rotator CameraRotation;
var private transient pointer CustomPoseModifier;
var private SecurityManager mSecurityManager;
var private bool CurrentlyPanningLeft;
var private ShockPawn SpecificTarget;
var private float SpecificTargetResetTime;
var private bool SpecificTargetIgnoreResetTime;
var private bool InspectionTargetVisibleOn;
var private bool InspectionTargetNotVisibleOn;

function AddCommanderAbility()
{
	assert(__NFUN_119__(CharacterAI, none));
	CharacterAI.addAbility_Class(Class'ShockAI.CameraCommanderAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function CharacterAICreated()
{
	super(ShockAI).CharacterAICreated();
	assert(__NFUN_119__(CharacterAI, none));
	CharacterAI.addAbility_Class(Class'ShockAI.CameraSearchAction');
	CharacterAI.addAbility_Class(Class'ShockAI.CameraDormantAction');
	CharacterAI.addAbility_Class(Class'ShockAI.CameraAlertedAction');
	CharacterAI.addAbility_Class(Class'ShockAI.CameraInspectAction');
	CharacterAI.addAbility_Class(Class'ShockAI.CameraMovementAction');
	CharacterAI.addAbility_Class(Class'ShockAI.CameraPanMovementAction');
	CharacterAI.addAbility_Class(Class'ShockAI.CameraTrackPawnMovementAction');
	CharacterAI.addAbility_Class(Class'ShockAI.CameraInspectPawnMovementAction');
	CharacterAI.addAbility_Class(Class'ShockAI.CameraDormantMovementAction');
	CharacterAI.addAbility_Class(Class'ShockAI.CameraShockedAction');
	CharacterAI.addAbility_Class(Class'ShockAI.CameraFrozenAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function CameraCommanderAction GetCameraCommanderAction()
{
	return CameraCommanderAction(Commander.achievingAction);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function int GetTargetPriority(ShockPawn PotentialTarget)
{
	//native.PotentialTarget;	
	@NULL
}

function HackInfo GetHackInfo()
{
	// End:0x4C
	if(__NFUN_114__(HackingGameSetupInfo, none))
	{
		HackingGameSetupInfo = Class'ShockGame.HackInfo'.static.Allocate(self,, string(HackInfoName)).;
		Construct_Void();
		return HackingGameSetupInfo;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
	@NULL
}

function SecurityManager GetSecurityManager()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x5E
	/*@Error*/
	mSecurityManager = SecurityManager(ShockGameInfo(Level.Game).GetSecurityManager());
	assert(__NFUN_119__(mSecurityManager, none));
	return mSecurityManager;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

protected function ShockPawn GetAlarmTarget()
{
	return GetSecurityManager().GetAlarmTarget();
	return;
}

function Rotator GetCurrentRotation()
{
	return CameraRotation;
	return;
	@NULL
}

function int GetLeftYawLimit()
{
	return LeftYawLimit;
	return;
	@NULL
}

function int GetRightYawLimit()
{
	return RightYawLimit;
	return;
	@NULL
}

function int GetUpperPitchLimit()
{
	return UpperPitchLimit;
	return;
	@NULL
}

function int GetLowerPitchLimit()
{
	return LowerPitchLimit;
	return;
	@NULL
}

function Rotator GetLeftmostSearchRotation()
{
	local Rotator TempRotator;

	TempRotator.Pitch = DefaultPitch;
	TempRotator.Yaw = PanningLeftYawLimit;
	return TempRotator;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Rotator GetRightmostSearchRotation()
{
	local Rotator TempRotator;

	TempRotator.Pitch = DefaultPitch;
	TempRotator.Yaw = PanningRightYawLimit;
	return TempRotator;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool RotatorIsClose(Rotator AngleA, Rotator AngleB)
{
	return __NFUN_130__(__NFUN_130__(__NFUN_176__(__NFUN_186__(float(__NFUN_147__(AngleA.Pitch, AngleB.Pitch))), float(50)), __NFUN_176__(__NFUN_186__(float(__NFUN_147__(AngleA.Yaw, AngleB.Yaw))), float(50))), __NFUN_176__(__NFUN_186__(float(__NFUN_147__(AngleA.Roll, AngleB.Roll))), float(50)));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function Rotator GetNextPanRotation()
{
	// End:0x30
	if(RotatorIsClose(GetCurrentRotation(), GetLeftmostSearchRotation()))
	{
		CurrentlyPanningLeft = false;
		goto J0x5D;
		// End:0x5D
		if(RotatorIsClose(GetCurrentRotation(), GetRightmostSearchRotation()))
		{
		}
		CurrentlyPanningLeft = true;
		// End:0x78
		if(CurrentlyPanningLeft)
		{
		}
		return GetLeftmostSearchRotation();
		goto J0x83;
		return GetRightmostSearchRotation();
		return;
	}
	@NULL
	CommanderAction
	J0x83:

	CommanderAction
}

function bool IsCurrentlyPanningLeft()
{
	return CurrentlyPanningLeft;
	return;
	@NULL
}

function float GetInspectionDuration(ShockPawn Target)
{
	assert(__NFUN_119__(Target, none));
	// End:0x56
	if(Target.ShouldPerceiveAsPlayer())
	{
		return Target.ModifyStat('CameraInspectionDuration_Bonus', PlayerBaseInspectionTimerAmount);
		goto J0xC7;
		// End:0x9D
		if(Target.IsSecurityBeaconed())
		{
		}
		return Target.ModifyStat('CameraInspectionDuration_Bonus', SecurityBeaconInspectionTimerAmount);
		goto J0xC7;
		return Target.ModifyStat('CameraInspectionDuration_Bonus', AIBaseInspectionTimerAmount);
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool IsPossibleToSeeTarget(Actor Target)
{
	//native.Target;	
	@NULL
}

function float GetSearchLimitPauseTime()
{
	return SearchLimitPauseTime;
	return;
	@NULL
}

function float GetLostContactDuration(ShockPawn Target)
{
	return LostContactTimerAmount;
	return;
	@NULL
}

function float GetSearchingInspectionPauseTime()
{
	return SearchingInspectionPauseTime;
	return;
	@NULL
}

function float GetAlertedTargetLostPauseTime()
{
	return AlertedTargetLostPauseTime;
	return;
	@NULL
}

function float GetSearchingInspectionPanOvershootTime()
{
	return SearchingInspectionPanOvershootTime;
	return;
	@NULL
}

function int GetDormantPitch()
{
	return __NFUN_145__(__NFUN_144__(DormantPitch, 65536), 360);
	return;
	@NULL
}

function float GetEventNotificationCylinderRadius()
{
	return EventNotificationCylinderRadius;
	return;
	@NULL
}

function float GetEventNotificationCylinderHeight()
{
	return EventNotificationCylinderHeight;
	return;
	@NULL
}

function float GetShockedDormantDelay()
{
	return ShockedDormantDelay;
	return;
	@NULL
}

function float GetFrozenTransitionTime()
{
	return FrozenTransitionTime;
	return;
	@NULL
}

function float GetInspectLostTargetTestPeriod()
{
	return InspectLostTargetTestPeriod;
	return;
	@NULL
}

function float GetInspectLostTargetDuration()
{
	return InspectLostTargetDuration;
	return;
	@NULL
}

// Export USecurityCamera::execGetSearchingPitchSpeed(FFrame&, void* const)
native function int GetSearchingPitchSpeed();

// Export USecurityCamera::execGetSearchingYawSpeed(FFrame&, void* const)
native function int GetSearchingYawSpeed();

// Export USecurityCamera::execGetAlertedPitchSpeed(FFrame&, void* const)
native function int GetAlertedPitchSpeed();

// Export USecurityCamera::execGetAlertedYawSpeed(FFrame&, void* const)
native function int GetAlertedYawSpeed();

// Export USecurityCamera::execIsHacked(FFrame&, void* const)
native function bool IsHacked();

function bool IsHackedByPlayer()
{
	return IsHacked();
	return;
}

function string GetHackVerbText()
{
	return "HACK";
	return;
}

function bool CanBeHackedNow(ShockPlayer Player)
{
	return __NFUN_130__(__NFUN_130__(__NFUN_130__(CanBeHacked, __NFUN_129__(IsHacked())), IsAlive()), __NFUN_132__(__NFUN_129__(GetSecurityManager().IsAlarmOn()), __NFUN_119__(GetSecurityManager().GetAlarmTarget(), Player)));
	return;
	@NULL
	CommanderAction
}

function OnHackAttempted(ShockPlayer Player)
{
	log('AI_Security', 3, __NFUN_112__(__NFUN_112__("Player attempted to hack ", string(self)), "."));
	Player.OnStartHacking(GetHackInfo(), self);
	Level.GetFlashGUIController().GetPlayingMovie('Hacking').CallMethodString("SetHackDescription", HackingSuccessFeedbackText);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function HackInfo OnHackSucceeded(ShockPlayer Player, string HackResult)
{
	// End:0x50
	if(__NFUN_119__(GetCameraCommanderAction(), none))
	{
		TriggerEffectEvent('HackSucceeded');
		bIsHacked = true;
		GetCameraCommanderAction().OnHackSucceeded(Player);
		Level.GetLocalPlayerController().ClientMessage(HackingSuccessFeedbackText, 'HackingSuccess');
	}
	return GetHackInfo();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function HackInfo OnHackFailed(ShockPlayer Player)
{
	TriggerEffectEvent('HackFailed');
	return GetHackInfo();
	return;
}

function OnPlayerAttacked(ShockPlayer Player, ShockPawn Attacker)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x83
	/*@Error*/
	SetSpecificTarget(Attacker, __NFUN_174__(GetSearchingInspectionPanOvershootTime(), 0.4000000));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function SetSpecificTarget(ShockPawn Target, float TargetDuration)
{
	//native.Target;
	//native.TargetDuration;	
	@NULL
	@NULL
}

function SetSpecificTargetIgnoreResetTime(bool newIgnoreResetTime)
{
	//native.newIgnoreResetTime;	
	@NULL
}

// Export USecurityCamera::execClearSpecificTarget(FFrame&, void* const)
native function ClearSpecificTarget();

function ShockPawn GetSpecificTarget()
{
	return SpecificTarget;
	return;
	@NULL
}

function bool isVisible(ShockPawn Target)
{
	assert(__NFUN_119__(GetCameraCommanderAction(), none));
	return GetCameraCommanderAction().isVisible(Target);
	return;
	@NULL
}

function bool CanOpenDoors()
{
	return false;
	return;
}

function bool CanBeUsedNow()
{
	return false;
	return;
}

function bool CanBeFocusedNow()
{
	return true;
	return;
}

function IPotentialAimOrActionTarget.TargetType GetTargetType()
{
	local Actor Player;

	Player = Level.GetLocalPlayerController().Pawn;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x79
	/*@Error*/
	// End:0x4E
	if(IsHacked())
	{
		return 0;
		goto J0x76;
		// End:0x73
		if(CanBeHackedNow(ShockPlayer(Player)))
		{
		}
		return 3;
		goto J0x76;
		return 2;
		goto J0x7C;
		return 0;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function bool ShouldHighlightWhenFocused()
{
	return IsAlive();
	return;
}

function PreBeginPlay()
{
	super(ShockAI).PreBeginPlay();
	CameraRotation = Rotation;
	SetLODRange(SightRadius, __NFUN_174__(SightRadius, float(500)));
	// End:0x73
	if(__NFUN_176__(HackedSearchingSpotlightBrightness, float(0)))
	{
		HackedSearchingSpotlightBrightness = SpotlightClass.default.LightBrightness;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xA4
		/*@Error*/
		NotHackedSearchingSpotlightBrightness = SpotlightClass.default.LightBrightness;
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

function Destroyed()
{
	UntriggerStateEffectEvents();
	ResetHackedEffectEvents();
	SetSpotlightState(false);
	UnTriggerEffectEvent('AlarmOn');
	super(ShockAI).Destroyed();
	return;
	@NULL
}

// Export USecurityCamera::execDetachAnyCrossbowBolts(FFrame&, void* const)
private native function DetachAnyCrossbowBolts();

function OnDamaged(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, bool bIsCriticalHit, optional name HitHighBone, optional name HitLowBone)
{
	local ShockPawn ShockDamager;

	super(ShockAI).OnDamaged(DamageStimuli, TotalDamageDealt, Damager, HitLocation, HitNormal, HitImpulseDirection, EffectEventName, bIsCriticalHit, HitHighBone, HitLowBone);
	ShockDamager = ShockPawn(Damager);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xD2
	/*@Error*/
	GetCameraCommanderAction().OnIntentionallyDamaged(ShockDamager);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function OnKilled(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, bool bIsCriticalHit, optional name HitHighBone, optional name HitLowBone)
{
	local SecurityCameraDeadBody DeadBody;
	local NonPhysicalReactiveActor CameraBase;
	local Coords DeadBodyCoords;

	ShutdownHackingScreenIfOpenedOnSelf();
	SetVisionState(false);
	assert(__NFUN_119__(GetCameraCommanderAction(), none));
	GetCameraCommanderAction().OnKilled();
	UntriggerStateEffectEvents();
	ResetHackedEffectEvents();
	SetSpotlightState(false);
	DetachAnyCrossbowBolts();
	CameraBase = __NFUN_278__(Class'ShockGame.NonPhysicalReactiveActor',,, Location, Rotation, true);
	CameraBase.SetStaticMesh(StaticMesh);
	CameraBase.bShowHudElements = false;
	bCastSimpleShadow = false;
	HavokQuitActor();
	DeadBody = __NFUN_278__(DeadBodyClass, self);
	AssertWithDescription(__NFUN_119__(DeadBody, none), __NFUN_112__(__NFUN_112__(string(self), " was killed, but could not spawn dead body of class: "), string(DeadBodyClass)));
	DeadBody.InitializeFromLiveBody(LootContainer);
	LootContainer = none;
	DeadBodyCoords = GetBoneCoords(DeadBodyAttachBone, true);
	__NFUN_267__(DeadBodyCoords.Origin, true);
	__NFUN_299__(OrthoRotation(DeadBodyCoords.XAxis, DeadBodyCoords.YAxis, DeadBodyCoords.ZAxis));
	DeadBody.__NFUN_3970__(1);
	DeadBody.HavokImpartCOMImpulse(__NFUN_212__(HitImpulseDirection, DeadBodyExplosionForce));
	ClearBurning();
	ClearFrozen();
	ClearShocked();
	TriggerEffectEvent('Died');
	super(ShockAI).OnKilled(DamageStimuli, TotalDamageDealt, Damager, HitLocation, HitNormal, HitImpulseDirection, EffectEventName, bIsCriticalHit, HitHighBone, HitLowBone);
	__NFUN_279__();
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

event OnSecuritySystemActive()
{
	log('AI_Security', 4, __NFUN_112__("NotifySecuritySystemActive() called on ", string(self)));
	GetCameraCommanderAction().OnNotifySecuritySystemActive();
	return;
}

event OnSecuritySystemInactive()
{
	log('AI_Security', 4, __NFUN_112__("OnNotifySecuritySystemInactive() called on ", string(self)));
	GetCameraCommanderAction().OnNotifySecuritySystemInactive();
	return;
}

function OnSecurityAlarmOn(ShockPawn inAlarmTarget)
{
	local ShockPawn AlarmTarget;

	log('AI_Security', 4, __NFUN_112__("OnNotifySecurityAlarmOn() called on ", string(self)));
	GetCameraCommanderAction().OnNotifySecurityAlarmOn(inAlarmTarget);
	// End:0x9D
	if(__NFUN_130__(__NFUN_119__(AlarmTarget, none), AlarmTarget.IsPlayer()))
	{
		AddContextForNextEffectEvent('Player');
		goto J0xE1;
		// End:0xCE
		if(GetSecurityManager().TargetWasSecurityBeaconed)
		{
		}
		AddContextForNextEffectEvent('AISecurityBeaconed');
		goto J0xE1;
		AddContextForNextEffectEvent('AI');
	}
	TriggerEffectEvent('AlarmOn');
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function OnSecurityAlarmOff(bool TurnedOffBySecurityStation, optional bool CleanupSecurityImmediately)
{
	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__("OnNotifySecurityAlarmOff( ", string(TurnedOffBySecurityStation)), " ) called on "), string(self)));
	GetCameraCommanderAction().OnNotifySecurityAlarmOff(TurnedOffBySecurityStation);
	UnTriggerEffectEvent('AlarmOn');
	return;
	@NULL
	CommanderAction
}

function OnSecurityBeaconApplied(Actor Damager, ShockPawn SecurityBeaconTarget)
{
	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__("OnNotifySecurityBeaconApplied( ", string(SecurityBeaconTarget)), " ) called on "), string(self)));
	GetCameraCommanderAction().OnNotifySecurityBeaconApplied(Damager, SecurityBeaconTarget);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function OnAlarmTargetChanged(ShockPawn NewTarget)
{
	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__("OnNotifyAlarmTargetChanged( ", string(NewTarget)), " ) called on "), string(self)));
	GetCameraCommanderAction().OnNotifyAlarmTargetChanged(NewTarget);
	return;
	@NULL
	CommanderAction
}

function SetSpotlightState(bool SpotlightOn)
{
	// End:0x11
	if(__NFUN_114__(Spotlight, none))
	{
		return;
		// End:0x4E
		if(SpotlightOn)
		{
		}
		Spotlight.SetLightType(SpotlightClass.default.LightType);
		goto J0x67;
		Spotlight.SetLightType(0);
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

function SetSpotlightColor(Color NewColor, float NewBrightness)
{
	// End:0x11
	if(__NFUN_114__(Spotlight, none))
	{
		return;
		Spotlight.LightColor = NewColor;
	}
	Spotlight.LightBrightness = NewBrightness;
	Spotlight.UpdateRenderRevision();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

private function UntriggerStateEffectEvents()
{
	UnTriggerEffectEvent('Searching');
	UnTriggerEffectEvent('Inspecting');
	UnTriggerEffectEvent('Alerted');
	return;
}

function SetSearching()
{
	UntriggerStateEffectEvents();
	TriggerEffectEvent('Searching');
	SetHackedEffectEvent();
	SetVisionState(true);
	// End:0x5E
	if(bIsHacked)
	{
		SetSpotlightColor(HackedSearchingSpotlightColor, HackedSearchingSpotlightBrightness);
		goto J0x7A;
		SetSpotlightColor(NotHackedSearchingSpotlightColor, NotHackedSearchingSpotlightBrightness);
	}
	SetSpotlightState(true);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function SetInspecting()
{
	UntriggerStateEffectEvents();
	TriggerEffectEvent('Inspecting');
	SetHackedEffectEvent();
	SetVisionState(true);
	SetSpotlightState(true);
	SetSpotlightColor(SpotlightClass.default.LightColor, SpotlightClass.default.LightBrightness);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function SetAlerted()
{
	local ShockPawn AlarmTarget;

	AlarmTarget = GetSecurityManager().GetAlarmTarget();
	UntriggerStateEffectEvents();
	// End:0x6D
	if(__NFUN_130__(__NFUN_119__(AlarmTarget, none), AlarmTarget.IsPlayer()))
	{
		AddContextForNextEffectEvent('Player');
		goto J0xB1;
		// End:0x9E
		if(GetSecurityManager().TargetWasSecurityBeaconed)
		{
		}
		AddContextForNextEffectEvent('AISecurityBeaconed');
		goto J0xB1;
		AddContextForNextEffectEvent('AI');
	}
	TriggerEffectEvent('Alerted');
	SetHackedEffectEvent();
	SetVisionState(true);
	SetSpotlightState(true);
	SetSpotlightColor(SpotlightClass.default.LightColor, SpotlightClass.default.LightBrightness);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function SetDormant()
{
	UntriggerStateEffectEvents();
	ResetHackedEffectEvents();
	SetVisionState(false);
	SetSpotlightState(false);
	return;
}

function ResetHackedEffectEvents()
{
	UnTriggerEffectEvent('CameraNotHacked');
	UnTriggerEffectEvent('CameraHacked');
	return;
}

function SetHackedEffectEvent()
{
	ResetHackedEffectEvents();
	// End:0x2D
	if(bIsHacked)
	{
		TriggerEffectEvent('CameraHacked');
		goto J0x40;
		TriggerEffectEvent('CameraNotHacked');
	}
	return;
	@NULL
}

function InspectionTargetVisibleStart()
{
	TriggerEffectEvent('InspectionTargetVisible');
	InspectionTargetVisibleOn = true;
	return;
	@NULL
}

function InspectionTargetVisibleStop()
{
	UnTriggerEffectEvent('InspectionTargetVisible');
	InspectionTargetVisibleOn = false;
	return;
	@NULL
}

function InspectionTargetNotVisibleStart()
{
	TriggerEffectEvent('InspectionTargetNotVisible');
	InspectionTargetNotVisibleOn = true;
	return;
	@NULL
}

function InspectionTargetNotVisibleStop()
{
	UnTriggerEffectEvent('InspectionTargetNotVisible');
	InspectionTargetNotVisibleOn = false;
	return;
	@NULL
}

function RollLoot(int slotNumber, LootSlot LootSlot, Object InOuter)
{
	local ItemStack ItemStack;

	super(BaseShockAI).RollLoot(slotNumber, LootSlot, InOuter);
	ItemStack = LootSlot.GetLoot();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xDD
	/*@Error*/
	__NFUN_159__(ItemStack.StackSize, ShockPawn(Level.GetLocalPlayerController().Pawn).ModifyStat('SecurityCameraFilm_PercentBonus', 1.0000000));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Actor GetAffectedActor()
{
	return none;
	return;
}

defaultproperties
{
	PitchBoneName="Pitch"
	YawBoneName="Yaw"
	LensDamageMultiplierBone="fxLens"
	LensDamageMultiplier=3.0000000
	SearchingPitchSpeed=30
	SearchingYawSpeed=30
	AlertedPitchSpeed=50
	AlertedYawSpeed=50
	DormantPitch=-40
	SearchLimitPauseTime=0.7500000
	PlayerBaseInspectionTimerAmount=4.0000000
	AIBaseInspectionTimerAmount=2.0000000
	LostContactTimerAmount=8.0000000
	SearchingInspectionPauseTime=0.3000000
	AlertedTargetLostPauseTime=0.4000000
	SearchingInspectionPanOvershootTime=0.9000000
	NumSecurityBotsSpawned=1
	DeadBodyClass=Class'ShockAI.SecurityCameraDeadBody'
	DeadBodyAttachBone="Pitch"
	DeadBodyExplosionForce=1500.0000000
	EventNotificationCylinderRadius=1000.0000000
	EventNotificationCylinderHeight=300.0000000
	ShockedDormantDelay=0.5000000
	FrozenTransitionTime=1.0000000
	InspectLostTargetTestPeriod=0.1000000
	InspectLostTargetDuration=1.5000000
	AlertedReturnToCannotSeeStateWhenDamaged=5.0000000
	DoNotTrackInspectTargetWhenOutsideOfMaximumYawRange=true
	HackedSearchingSpotlightColor=(R=255,G=255,B=255,A=255)
	NotHackedSearchingSpotlightColor=(R=255,G=255,B=255,A=255)
	HackedSearchingSpotlightBrightness=-1.0000000
	NotHackedSearchingSpotlightBrightness=-1.0000000
	SpotlightClass=Class'ShockAI.SecurityCameraLight'
	EyeBoneName="Lens"
	bAlwaysUseExpensiveVision=true
	bShouldGoRagdollOnDeath=false
	bDropToGroundUponSpawning=false
	bVisionEnabled=true
	bUseQuickVision=true
	bCanWalk=false
	bCollideWorld=false
	bUseCylinderCollision=false
}