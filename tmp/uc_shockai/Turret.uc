class Turret extends SecurityElement implements ICanBeHacked, IWatchForPlayerBeingAttackedByProtector, IWatchForPlayerAttacks
	abstract
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

enum TurretMovementDirection
{
	TurretMovingClockwise,          // 0
	TurretMovingCounterclockwise,   // 1
	TurretNotMoving                 // 2
};

var private config Class<TurretDeadBody> DeadBodyClass;
var private config name DeadBodyAttachBone;
var private config name PitchBoneName;
var private config name YawBoneName;
var private config name WheelBoneName;
var private config name GearBoneName;
var private config float WheelRadius;
var private config float WheelShaftLength;
var private config int PitchSpeed;
var private config int YawSpeed;
var private config int DormantPitch;
var private config Class<AIWeapon> weaponClass;
var private config int TargetDeadZone;
var private config float MaximumBurstTime;
var private config float CoolOffTime;
var const config float LostTargetBurstTime;
var private config float LostContactDurationPlayer;
var private config float LostContactDurationAI;
var private config float NewTargetAcquisitionDelay;
var private config float StandbyLightDelay;
var private config float EngineStartupDelay;
var private config float AttackDelay;
var private config Vector TargetTrackingOffset;
var private config name EngineAnimationName;
var private config float EngineAnimationEaseOutTime;
var private config name FireAnimationName;
var private config Material LightOnSkin;
var private config Material LightOffSkin;
var private config float ShockedDormantDelay;
var private config Range ShockedFlickerDelay;
var private config float FrozenTransitionTime;
var private config float StandbyFOV;
var private config float HackedDamageMultiplier;
var private config float TurretDestroyedExplosionInnerRadius;
var private config float TurretDestroyedExplosionOuterRadius;
var private config float EventNotificationCylinderRadius;
var private config float EventNotificationCylinderHeight;
var private int UpperPitchLimit;
var private int LowerPitchLimit;
var private int DefaultPitch;
var bool ShouldAttackPlayerEscortedGatherers;
var private bool bIsHacked;
var private bool CanBeHacked;
var private name HackInfoName;
var private transient HackInfo HackingGameSetupInfo;
var private ShockPlayer MyHacker;
var private config localized string HackingSuccessFeedbackText;
var private Rotator TurretRotation;
var private transient pointer CustomPoseModifier;
var private AIWeapon theWeapon;
var private bool EngineIsRunning;
var private int EngineAnimationHandle;
var private bool LightsAreOn;
var private bool bCantBeTargeted;
var private int StandbyYaw;
var private Turret.TurretMovementDirection CurrentMovementDirection;

function PreBeginPlay()
{
	super(ShockAI).PreBeginPlay();
	TurretRotation = Rotation;
	StandbyYaw = Rotation.Yaw;
	SetLODRange(SightRadius, __NFUN_174__(SightRadius, float(500)));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function AddCommanderAbility()
{
	assert(__NFUN_119__(CharacterAI, none));
	CharacterAI.addAbility_Class(Class'ShockAI.TurretCommanderAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function CharacterAICreated()
{
	super(ShockAI).CharacterAICreated();
	assert(__NFUN_119__(CharacterAI, none));
	CharacterAI.addAbility_Class(Class'ShockAI.TurretStandbyAction');
	CharacterAI.addAbility_Class(Class'ShockAI.TurretAttackAction');
	CharacterAI.addAbility_Class(Class'ShockAI.TurretDormantAction');
	CharacterAI.addAbility_Class(Class'ShockAI.TurretMovementAction');
	CharacterAI.addAbility_Class(Class'ShockAI.TurretGoToLocationMovementAction');
	CharacterAI.addAbility_Class(Class'ShockAI.TurretTrackTargetMovementAction');
	CharacterAI.addAbility_Class(Class'ShockAI.TurretShockedAction');
	CharacterAI.addAbility_Class(Class'ShockAI.TurretFrozenAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function TurretCommanderAction GetTurretCommanderAction()
{
	return TurretCommanderAction(Commander.achievingAction);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
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
	return SecurityManager(ShockGameInfo(Level.Game).GetSecurityManager());
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool IsHacked()
{
	return bIsHacked;
	return;
	@NULL
}

function bool IsHackedByPlayer()
{
	return __NFUN_130__(__NFUN_119__(MyHacker, none), __NFUN_114__(MyHacker, ShockPlayer(Level.GetLocalPlayerController().Pawn)));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Rotator GetCurrentRotation()
{
	return TurretRotation;
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

function int GetDefaultPitch()
{
	return DefaultPitch;
	return;
	@NULL
}

function int GetPitchSpeed()
{
	return __NFUN_145__(__NFUN_144__(PitchSpeed, 65536), 360);
	return;
	@NULL
}

function int GetYawSpeed()
{
	return __NFUN_145__(__NFUN_144__(YawSpeed, 65536), 360);
	return;
	@NULL
}

function int GetDormantPitch()
{
	return __NFUN_145__(__NFUN_144__(DormantPitch, 65536), 360);
	return;
	@NULL
}

function int GetTargetDeadZone()
{
	return __NFUN_145__(__NFUN_144__(TargetDeadZone, 65536), 360);
	return;
	@NULL
}

function int GetStandbyYaw()
{
	return __NFUN_147__(StandbyYaw, Rotation.Yaw);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function float GetMaximumBurstTime()
{
	return MaximumBurstTime;
	return;
	@NULL
}

function float GetCoolOffTime()
{
	return CoolOffTime;
	return;
	@NULL
}

function float GetLostContactDuration(ShockPawn Target)
{
	// End:0x38
	if(__NFUN_130__(__NFUN_119__(Target, none), Target.IsPlayer()))
	{
		return LostContactDurationPlayer;
		goto J0x42;
		return LostContactDurationAI;
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

function float GetNewTargetAcquisitionDelay()
{
	return NewTargetAcquisitionDelay;
	return;
	@NULL
}

function float GetStandbyLightDelay()
{
	return StandbyLightDelay;
	return;
	@NULL
}

function float GetAttackDelay()
{
	return AttackDelay;
	return;
	@NULL
}

function float GetShockedDormantDelay()
{
	return ShockedDormantDelay;
	return;
	@NULL
}

function float GetRandomShockedFlickerDelay()
{
	return RandRange(ShockedFlickerDelay.Min, ShockedFlickerDelay.Max);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function float GetFrozenTransitionTime()
{
	return FrozenTransitionTime;
	return;
	@NULL
}

function Rotator GetRotation()
{
	return TurretRotation;
	return;
	@NULL
}

function Turret.TurretMovementDirection GetCurrentMovementDirection()
{
	return CurrentMovementDirection;
	return;
	@NULL
}

function float GetEngineStartupDelay(ShockPawn Target)
{
	// End:0x39
	if(__NFUN_119__(Target, none))
	{
		return Target.ModifyStat('TurretStartupDelay_Bonus', EngineStartupDelay);
		return EngineStartupDelay;
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

function bool PawnIsFriendly(ShockPawn TestPawn)
{
	//native.TestPawn;	
	@NULL
}

private function UntriggerStateEffectEvents()
{
	UnTriggerEffectEvent('Attacking');
	UnTriggerEffectEvent('Standby');
	return;
}

function SetStandbyRotation(int inStandbyYaw)
{
	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), " changing standby yaw to "), string(inStandbyYaw)), "."));
	StandbyYaw = inStandbyYaw;
	GetTurretCommanderAction().OnStandbyPositionChanged();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function SetStandby()
{
	PeripheralVision = __NFUN_188__(__NFUN_171__(__NFUN_171__(StandbyFOV, 0.0174533), 0.5000000));
	UntriggerStateEffectEvents();
	SetHackedEffectEvent();
	TriggerEffectEvent('Standby');
	StopEngine(EngineAnimationEaseOutTime);
	TurnLightsOff();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function SetAttacking()
{
	PeripheralVision = -1.0000000;
	UntriggerStateEffectEvents();
	SetHackedEffectEvent();
	TriggerEffectEvent('Attacking');
	return;
	@NULL
}

function SetDormant()
{
	UntriggerStateEffectEvents();
	ResetHackedEffectEvents();
	StopEngine(EngineAnimationEaseOutTime);
	TurnLightsOff();
	return;
	@NULL
}

function PostTurretAttackingNotification(Vector AttackingLocation)
{
	local AIEventNotification Event;

	Event = Class'Engine.AIEventNotification'.static.CreateAIEventNotification(Level);
	Event.NotificationType = 3;
	Event.SetLocation(Location, AttackingLocation, true);
	Event.Radius = EventNotificationCylinderRadius;
	Event.Height = EventNotificationCylinderHeight;
	Event.SourceActor = self;
	Level.SpawningManager.PostAIEventNotification(Event);
	Event.__NFUN_200__();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function StartEngine()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x61
	/*@Error*/
	EngineIsRunning = true;
	EngineAnimationHandle = PlayAnimationOnChannel(0, EngineAnimationName, 8);
	TriggerEffectEvent('MotorStarted');
	TriggerEffectEvent('MotorRunning');
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function StopEngine(float EaseOutTime)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x5B
	/*@Error*/
	EngineIsRunning = false;
	FlatEaseOutAnimation(EngineAnimationHandle, EaseOutTime);
	UnTriggerEffectEvent('MotorRunning');
	TriggerEffectEvent('MotorStopped');
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function TurnLightsOn()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x75
	/*@Error*/
	LightsAreOn = true;
	Skins[1] = LightOnSkin;
	TriggerEffectEvent('LightsOn');
	dispatchMessage(Class'ShockAI.MessageTurretBecameActive'.static.Allocate(self)., construct_Turret(self));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function TurnLightsOff()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x86
	/*@Error*/
	LightsAreOn = false;
	Skins[1] = LightOffSkin;
	TriggerEffectEvent('LightsOff');
	UnTriggerEffectEvent('LightsOn');
	dispatchMessage(Class'ShockAI.MessageTurretBecameInActive'.static.Allocate(self)., construct_Turret(self));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ToggleLights()
{
	// End:0x1A
	if(LightsAreOn)
	{
		TurnLightsOff();
		goto J0x24;
		TurnLightsOn();
	}
	return;
	@NULL
}

function SetCurrentMovementDirection(Turret.TurretMovementDirection NewMovementDirection)
{
	CurrentMovementDirection = NewMovementDirection;
	return;
	@NULL
	CommanderAction
}

function ResetHackedEffectEvents()
{
	UnTriggerEffectEvent('TurretNotHacked');
	UnTriggerEffectEvent('TurretHacked');
	return;
}

function SetHackedEffectEvent()
{
	ResetHackedEffectEvents();
	// End:0x2D
	if(IsHacked())
	{
		TriggerEffectEvent('TurretHacked');		
	}
	else
	{
		TriggerEffectEvent('TurretNotHacked');
	}
	return;
}

function int GetTargetPriority(ShockPawn PotentialTarget)
{
	//native.PotentialTarget;	
	@NULL
}

function ScriptedAttackTarget(ShockPawn Target)
{
	GetTurretCommanderAction().ForceAttackTarget(Target);
	return;
	@NULL
}

function StartFiringWeapon()
{
	log('AI_Security', 4, __NFUN_112__(string(self), " began firing weapon."));
	PlayAnimationOnChannel(1, FireAnimationName, 2);
	BeginFiring();
	return;
	@NULL
	CommanderAction
}

function StopFiringWeapon()
{
	log('AI_Security', 4, __NFUN_112__(string(self), " stopped firing weapon."));
	CeaseFiring();
	return;
}

function bool IsFiringWeapon()
{
	return theWeapon.__NFUN_281__('Firing');
	return;
	@NULL
}

function AIWeapon GetWeapon()
{
	return theWeapon;
	return;
	@NULL
}

function OnPlayerAttacked(ShockPlayer Player, ShockPawn Attacker)
{
	// End:0x81
	if(__NFUN_130__(__NFUN_130__(__NFUN_130__(IsHacked(), __NFUN_129__(GetTurretCommanderAction().AttackTargetIsVisible())), Attacker.IsAlive()), CanSee(Attacker)))
	{
		GetTurretCommanderAction().ForceAttackTarget(Attacker);
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function OnPlayerAttacks(ShockPlayer Player, ShockPawn Attacked)
{
	// End:0x81
	if(__NFUN_130__(__NFUN_130__(__NFUN_130__(IsHacked(), __NFUN_129__(GetTurretCommanderAction().AttackTargetIsVisible())), Attacked.IsAlive()), CanSee(Attacked)))
	{
		GetTurretCommanderAction().ForceAttackTarget(Attacked);
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function SetHacked(ShockPlayer Player)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x72
	/*@Error*/
	bIsHacked = true;
	MyHacker = Player;
	GetTurretCommanderAction().OnHackSucceeded(Player);
	Player.RegisterPlayerAttacksWatcher(self);
	SetHackedEffectEvent();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function SetNotHacked()
{
	// End:0x11
	if(__NFUN_129__(IsHacked()))
	{
		return;
	}
	MyHacker.UnregisterPlayerAttacksWatcher(self);
	bIsHacked = false;
	MyHacker = none;
	GetTurretCommanderAction().OnSetUnhacked();
	SetHackedEffectEvent();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function string GetHackVerbText()
{
	return "HACK";
	return;
}

function bool CanBeHackedNow(ShockPlayer Player)
{
	return __NFUN_130__(__NFUN_130__(__NFUN_130__(CanBeHacked, IsAlive()), __NFUN_129__(IsHacked())), __NFUN_132__(__NFUN_132__(__NFUN_130__(__NFUN_119__(GetTurretCommanderAction(), none), __NFUN_119__(GetTurretCommanderAction().GetAttackTarget(), Player)), IsShocked()), IsFrozen()));
	return;
	@NULL
	CommanderAction
}

function OnHackAttempted(ShockPlayer Player)
{
	assert(__NFUN_119__(GetTurretCommanderAction(), none));
	log('AI_Security', 3, __NFUN_112__(__NFUN_112__("Player attempted to hack ", string(self)), "."));
	// End:0xC4
	if(Player.HasMod('TurretAutoHack_Exists'))
	{
		TriggerEffectEvent('HackSucceeded');
		SetHacked(Player);
		dispatchMessage(Class'ShockGame.MessagePlayerFinishedHacking'.static.Allocate(self)., construct_ICanBeHackedBool(self, true));
		goto J0x13F;
		Player.OnStartHacking(GetHackInfo(), self);
	}
	Level.GetFlashGUIController().GetPlayingMovie('Hacking').CallMethodString("SetHackDescription", HackingSuccessFeedbackText);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function HackInfo OnHackSucceeded(ShockPlayer Player, string HackResult)
{
	TriggerEffectEvent('HackSucceeded');
	SetHacked(Player);
	Level.GetLocalPlayerController().ClientMessage(HackingSuccessFeedbackText, 'HackingSuccess');
	return GetHackInfo();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function HackInfo OnHackFailed(ShockPlayer Player, string HackResult)
{
	assert(__NFUN_119__(GetTurretCommanderAction(), none));
	TriggerEffectEvent('HackFailed');
	GetTurretCommanderAction().OnHackFailed(Player);
	return GetHackInfo();
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

function bool ShouldHighlightWhenFocused()
{
	return false;
	return;
}

function IPotentialAimOrActionTarget.TargetType GetTargetType()
{
	local Actor Player;

	Player = Level.GetLocalPlayerController().Pawn;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x88
	/*@Error*/
	// End:0x5D
	if(__NFUN_132__(IsHacked(), bCantBeTargeted))
	{
		return 0;
		goto J0x85;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x82
		/*@Error*/
	}
	return 3;
	goto J0x85;
	return 2;
	goto J0x8B;
	return 0;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function int GetAnimationChannelForWeapon(Weapon inWeapon)
{
	return 3;
	return;
}

function OnSecuritySystemActive()
{
	log('AI_Security', 4, __NFUN_112__("NotifySecuritySystemActive() called on ", string(self)));
	TurretCommanderAction(Commander.achievingAction).OnNotifySecuritySystemActive();
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function OnSecuritySystemInactive()
{
	log('AI_Security', 4, __NFUN_112__("OnNotifySecuritySystemInactive() called on ", string(self)));
	TurretCommanderAction(Commander.achievingAction).OnNotifySecuritySystemInactive();
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function OnSecurityBeaconApplied(Actor Damager, ShockPawn SecurityBeaconTarget)
{
	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__("OnNotifySecurityBeaconApplied( ", string(SecurityBeaconTarget)), " ) called on "), string(self)));
	TurretCommanderAction(Commander.achievingAction).OnNotifySecurityBeaconApplied(Damager, SecurityBeaconTarget);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function CreateWeapons()
{
	AssertWithDescription(__NFUN_119__(weaponClass, none), __NFUN_112__(__NFUN_112__("The WeaponClass was not specified for class ", string(Class)), "."));
	theWeapon = CreateAIWeapon(weaponClass);
	AssertWithDescription(__NFUN_119__(theWeapon, none), __NFUN_112__("The Weapon was not created for ", string(self)));
	AddAvailableHoldable(theWeapon);
	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), " attaching "), string(theWeapon)), " to socket "), string(theWeapon.GetAttachBone(self))));
	AttachToBone(theWeapon, theWeapon.GetAttachBone(self));
	Equip(theWeapon);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function Destroyed()
{
	UntriggerStateEffectEvents();
	ResetHackedEffectEvents();
	super(ShockAI).Destroyed();
	return;
	@NULL
}

// Export UTurret::execDetachAnyCrossbowBolts(FFrame&, void* const)
private native function DetachAnyCrossbowBolts();

function Explode()
{
	Class'ShockGame.DamageFactory'.static.DealRadiusDamage_ActorVectorFloatFloatNameFloat(self, Location, TurretDestroyedExplosionInnerRadius, TurretDestroyedExplosionOuterRadius, 'TurretExplosionStimuliSet');
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function OnDamaged(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, bool bIsCriticalHit, optional name HitHighBone, optional name HitLowBone)
{
	local ShockPawn ShockDamager;

	super(ShockAI).OnDamaged(DamageStimuli, TotalDamageDealt, Damager, HitLocation, HitNormal, HitImpulseDirection, EffectEventName, bIsCriticalHit, HitHighBone, HitLowBone);
	ShockDamager = ShockPawn(Damager);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xD2
	/*@Error*/
	GetTurretCommanderAction().OnIntentionallyDamaged(ShockDamager);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function OnKilled(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, bool bIsCriticalHit, optional name HitHighBone, optional name HitLowBone)
{
	super(ShockAI).OnKilled(DamageStimuli, TotalDamageDealt, Damager, HitLocation, HitNormal, HitImpulseDirection, EffectEventName, bIsCriticalHit, HitHighBone, HitLowBone);
	ShutdownHackingScreenIfOpenedOnSelf();
	DetachAnyCrossbowBolts();
	// End:0x9E
	if(IsHacked())
	{
		MyHacker.UnregisterPlayerAttacksWatcher(self);
		TurnLightsOff();
		StopEngine(EngineAnimationEaseOutTime);
		UntriggerStateEffectEvents();
		ResetHackedEffectEvents();
		TriggerEffectEvent('Died');
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x18D
	/*@Error*/
	assert(__NFUN_119__(ShockPlayer(Level.GetLocalPlayerController().Pawn), none));
	ShockPlayer(Level.GetLocalPlayerController().Pawn).AwardAchievementsManager.SpawnedDLCMinimumSecurityTurretWasDestroyedInDLC1Level();
	Explode();
	SpawnDeadBody();
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function SpawnDeadBody()
{
	local TurretDeadBody DeadBody;
	local Coords DeadBodyCoords;

	DeadBody = __NFUN_278__(DeadBodyClass, self);
	AssertWithDescription(__NFUN_119__(DeadBody, none), __NFUN_112__(__NFUN_112__(string(self), " was killed, but could not spawn dead body of class: "), string(DeadBodyClass)));
	DeadBody.InitializeDeadBody(LootContainer, GetUseVerbText(), GetFocusDisplayName(), GetHUDMessageForFocusAttained());
	LootContainer = none;
	DeadBodyCoords = GetBoneCoords(DeadBodyAttachBone, true);
	__NFUN_267__(DeadBodyCoords.Origin, true);
	__NFUN_299__(OrthoRotation(DeadBodyCoords.XAxis, DeadBodyCoords.YAxis, DeadBodyCoords.ZAxis));
	__NFUN_279__();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
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
	__NFUN_159__(ItemStack.StackSize, ShockPawn(Level.GetLocalPlayerController().Pawn).ModifyStat('TurretAmmo_PercentBonus', 1.0000000));
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
	DeadBodyClass=Class'ShockAI.ShockAIClasses.SpawnedTurretDeadBody'
	DeadBodyAttachBone="Destroyed"
	PitchBoneName="Pitch"
	YawBoneName="Yaw"
	WheelBoneName="Wheel"
	GearBoneName="GearWheel"
	WheelRadius=15.8750000
	WheelShaftLength=63.5000000
	PitchSpeed=60
	YawSpeed=90
	DormantPitch=-30
	TargetDeadZone=10
	MaximumBurstTime=5.0000000
	CoolOffTime=1.0000000
	LostTargetBurstTime=2.0000000
	LostContactDurationPlayer=60.0000000
	LostContactDurationAI=10.0000000
	NewTargetAcquisitionDelay=3.0000000
	EngineStartupDelay=0.3000000
	AttackDelay=1.7000000
	TargetTrackingOffset=(X=0.0000000,Y=0.0000000,Z=50.0000000)
	EngineAnimationName="EngineOn"
	EngineAnimationEaseOutTime=4.0000000
	FireAnimationName="Fire"
	ShockedDormantDelay=0.5000000
	ShockedFlickerDelay=(Min=0.0500000,Max=0.1000000)
	FrozenTransitionTime=1.0000000
	StandbyFOV=360.0000000
	HackedDamageMultiplier=1.0000000
	TurretDestroyedExplosionInnerRadius=300.0000000
	TurretDestroyedExplosionOuterRadius=500.0000000
	EventNotificationCylinderRadius=1000.0000000
	EventNotificationCylinderHeight=300.0000000
	HackInfoName="TurretDefault"
	HackingSuccessFeedbackText="Hacked turrets are friendly and will attack your enemies."
	CorpseString="Destroyed Turret"
	ResearchTrack="Turret"
	bDropToGroundUponSpawning=false
	CriticalDamageEffectInfos=/* Array type was not detected. */
	NormalLODTyrionTickUpdateRange=(Min=0.0000000,Max=0.0000000)
	bVisionEnabled=true
	bUseQuickVision=true
	bCanWalk=false
	bCanBeBaseForPawns=true
	CollisionRadius=54.0000000
	CollisionHeight=64.0000000
	bCollideWorld=false
	bBlockActors=true
}