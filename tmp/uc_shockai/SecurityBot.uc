class SecurityBot extends SecurityElement implements ICanBeUsed, ICanBeHacked, ICanBeControlled, IEffectObserver
	abstract
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

enum BotMotionType
{
	kMotionNavigating,              // 0
	kMotionAttacking,               // 1
	kMotionProtecting,              // 2
	kMotionSearching,               // 3
	kMotionGoingHome,               // 4
	kMotionLiftingOffGround         // 5
};

var private config float MinimumRemovalDistance;
var private config float MinimumRemovalOffscreenTime;
var private config Range SillyActionDeltaRange;
var const config float VerticalSwayPeriod;
var const config float VerticalSwayDistance;
var const config float VerticalSwayThrust;
var const config float VerticalSwayDelay;
var private config float DetectRadius;
var config Class<AIWeapon> weaponClass;
var config array<Material> LightsOnSkins;
var config array<Material> LightsOffSkins;
var private const config localized string DormantString;
var private const config localized string DeactivatedString;
var private const config localized string DeactivateUseVerbString;
var private const config localized string ActivateUseVerbString;
var private config Range DesiredRangeWhileAttacking;
var private config Range DesiredHeightWhileAttacking;
var private config Range DesiredRangeWhileProtecting;
var private config Range DesiredHeightWhileProtecting;
var private config float MaximumAttackRange;
var config Range MoveWhileAttackingAngleRange;
var const config Range AttackingHoverPointWaitTimeRangePlayer;
var const config Range AttackingHoverPointWaitTimeRangeAI;
var private config int NumTimesToFindUsablePoint;
var const config float OnBumpedBotNewPointChance;
var private config float RandomPointDistance;
var private config float MinRandomPointDistanceFromTarget;
var private config Range BurstIntervalRange;
var private config float DormantDuration;
var const config float BotLifeSpanAfterDeath;
var const config float BotLifeSpawnAfterFailedHack;
var private config float LightSwitchTimeMultiplier;
var private config float InnerExplosionAttenuationRadius;
var private config float OuterExplosionAttenuationRadius;
var private config name ExplosionDamageStimuliSetName;
var private config float WeaponUpperPitchLimit;
var private config float WeaponLowerPitchLimit;
var private config float WeaponYawLimit;
var private config bool WeaponIsFixed;
var private config bool ExplodeOnFailedHack;
var private config bool HackPurchaseOptionEnabled;
var private config float HitTorqueModifier;
var private config float HackedStartUpDelay;
var private config float HackedRotorStartDelay;
var private config float HackedMovementStartDelay;
var private config Range SecuritySystemShutdownDormantDelay;
var private config float PreExplodeNoiseTime;
var private config float FrozenMovementStopDelay;
var private config bool AllowFriendlyBotsToBeDeactivated;
var private config float HackedDamageMultiplier;
var private config float TooCloseToFloorDistance;
var private config float BotDustEffectDistance;
var private config name BotPropellerRagdollBoneName;
var private config name BotBodyRagdollBoneName;
var const config Vector BodyCenterOfMassWhileFlying;
var const config float MeanAlternateDamagerTimeout;
var const config float FriendlyAlternateDamagerTimeout;
var const config float AlternateDamagerMinDamage;
var const config float AlternateDamagerCheckTime;
var const config float MinFriendlyAttackTargetSwitchTime;
var const config float FriendlyLookAtAttackTargetDistance;
var const config float MeanLookAtAttackTargetDistance;
var const config int AlignmentAllowedDeltaYaw;
var const config float DamageToFriendlyBotAggroWeight;
var const config float DamageToProtectTargetAggroWeight;
var const config float DamageFromProtectTargetAggroWeight;
var const config Range BotPropellerCollidedEventPeriod;
var private bool EnableVerticalSway;
var AIWeapon theWeapon;
var private int HoverAnimHandle;
var private int BladesAnimHandle;
var private SecurityManager mSecurityManager;
var private float DyingStateTime;
var private float DeathTime;
var private bool bLightsOn;
var private float NextLightSwitchTime;
var private float WeaponPitch;
var private float WeaponYaw;
var private int CurrentSector;
var float AntiGravityForcePercentage;
var float ThrustPercentage;
var bool HasSentDeathMessage;
var bool WeaponIsFrozen;
var bool StartDormant;
var bool StartRagdollFrozen;
var private bool StartEngineState;
var private bool StartAnimationsState;
var bool PlayStartupSequenceWhenRisingOffGround;
var ShockPawn StartOwnerPawn;
var bool StartPreHacked;
var transient pointer GroundDetectionPhantom;
var transient pointer MovementCastPhantom;
var Vector NextDestinationHeading;
var transient Vector DefaultBodyCenterOfMass;
var private float StayLowEndTime;
var private float StayLowHeight;
var ShockPawn ScriptedFriendlyAttackTarget;
var private float NextBotPropellerCollidedEventTime;
var private bool WasHackedByPlayerWhenKilled;
var name HackInfoName;
var private transient HackInfo HackingGameSetupInfo;
var private config localized string HackingSuccessFeedbackText;
var private ShockPawn CurrentOwner;
var bool DisallowHacking;
var private transient bool HavokInitialized;
var private Vector HavokPreviousLocation;
var private Rotator HavokDesiredRotation;
var private Rotator HavokPreviousRotation;
var private bool MotorsEnabled;
var private bool MotorsFrozen;
var transient SoundInstance Instance;
var Vector LocationLastTick;
var private config name NavigatingMotionParametersName;
var private config name AttackingMotionParametersName;
var private config name SearchingMotionParametersName;
var private config name GoingHomeMotionParametersName;
var private config name GettingUpMotionParametersName;
var private HavokFlyingMotionParameters NavigatingMotionParameters;
var private HavokFlyingMotionParameters AttackingMotionParameters;
var private HavokFlyingMotionParameters SearchingMotionParameters;
var private HavokFlyingMotionParameters GoingHomeMotionParameters;
var private HavokFlyingMotionParameters GettingUpMotionParameters;
var private HavokFlyingMotionParameters CurrentMotionParameters;
var private transient pointer CustomPoseModifier;

function SwitchToMotion(SecurityBot.BotMotionType NewType)
{
	//native.NewType;	
	@NULL
}

// Export USecurityBot::execGetBotRotationFromRagdoll(FFrame&, void* const)
native final function Rotator GetBotRotationFromRagdoll();

function ResetHavokLocationAndRotation()
{
	HavokPreviousLocation = Location;
	HavokPreviousRotation = Rotation;
	return;
	@NULL
	EcologyCommanderAction
	CommanderAction
	@NULL
}

function LimitNumberOfDormantSecurityBots(SecurityBot newDormantBot)
{
	//native.newDormantBot;	
	@NULL
}

function bool LootSlotLocked()
{
	return __NFUN_129__(ShockPawn(Level.GetLocalPlayerController().Pawn).HasMod('SecurityBotLootSlotUnlocked_Exists'));
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function int GetDesiredAnimationCapabilities()
{
	return __NFUN_158__(super(ShockAI).GetDesiredAnimationCapabilities(), 256);
	return;
	@NULL
}

singular event BaseChange()
{
	return;
}

function bool ShouldDropWeaponsOnDeath()
{
	return false;
	return;
}

function PreBeginPlay()
{
	local SpawningManager SpawningManager;

	super(ShockAI).PreBeginPlay();
	SpawningManager = SpawningManager(Level.SpawningManager);
	// End:0x6A
	if(self.__NFUN_303__('MinimumSecurityBot'))
	{
		HackInfoName = SpawningManager.MinimumSecurityBotHackInfoName;
		goto J0x133;
		// End:0xA1
		if(self.__NFUN_303__('MediumSecurityBot'))
		{
			HackInfoName = SpawningManager.MediumSecurityBotHackInfoName;
		}
		goto J0x133;
		// End:0xD8
		if(self.__NFUN_303__('MaximumSecurityBot'))
		{
			HackInfoName = SpawningManager.MaximumSecurityBotHackInfoName;
			goto J0x133;
			AssertWithDescription(false, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Unknown security bot class ", string(self.Class)), " specified for bot "), string(self)), "."));
		}
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function PostBeginPlay()
{
	SetLabel(Class'ShockAI.SecurityBot'.default.Label);
	super(ShockAI).PostBeginPlay();
	SaveDefaultCenterOfMass();
	NavigatingMotionParameters = Class'ShockAI.HavokFlyingMotionParameters'.static.Allocate(self,, string(NavigatingMotionParametersName)).;
	Construct_Void();
	AssertWithDescription(__NFUN_119__(NavigatingMotionParameters, none), __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), " could not create motion parameters for name: "), string(NavigatingMotionParametersName)), ". Using defaults."));
	// End:0x11E
	if(__NFUN_114__(NavigatingMotionParameters, none))
	{
		NavigatingMotionParameters = Class'ShockAI.HavokFlyingMotionParameters'.static.Allocate(self).;
		Construct_Void();
		AttackingMotionParameters = Class'ShockAI.HavokFlyingMotionParameters'.static.Allocate(self,, string(AttackingMotionParametersName)).;
		Construct_Void();
		AssertWithDescription(__NFUN_119__(AttackingMotionParameters, none), __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), " could not create motion parameters for name: "), string(AttackingMotionParametersName)), ". Using defaults."));
	}
	// End:0x208
	if(__NFUN_114__(AttackingMotionParameters, none))
	{
		AttackingMotionParameters = Class'ShockAI.HavokFlyingMotionParameters'.static.Allocate(self).;
		Construct_Void();
		SearchingMotionParameters = Class'ShockAI.HavokFlyingMotionParameters'.static.Allocate(self,, string(SearchingMotionParametersName)).;
		Construct_Void();
		AssertWithDescription(__NFUN_119__(SearchingMotionParameters, none), __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), " could not create motion parameters for name: "), string(SearchingMotionParametersName)), ". Using defaults."));
	}
	// End:0x2F2
	if(__NFUN_114__(SearchingMotionParameters, none))
	{
		SearchingMotionParameters = Class'ShockAI.HavokFlyingMotionParameters'.static.Allocate(self).;
		Construct_Void();
		GoingHomeMotionParameters = Class'ShockAI.HavokFlyingMotionParameters'.static.Allocate(self,, string(GoingHomeMotionParametersName)).;
		Construct_Void();
		AssertWithDescription(__NFUN_119__(GoingHomeMotionParameters, none), __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), " could not create motion parameters for name: "), string(GoingHomeMotionParametersName)), ". Using defaults."));
	}
	// End:0x3DC
	if(__NFUN_114__(GoingHomeMotionParameters, none))
	{
		GoingHomeMotionParameters = Class'ShockAI.HavokFlyingMotionParameters'.static.Allocate(self).;
		Construct_Void();
		GettingUpMotionParameters = Class'ShockAI.HavokFlyingMotionParameters'.static.Allocate(self,, string(GettingUpMotionParametersName)).;
		Construct_Void();
		AssertWithDescription(__NFUN_119__(GettingUpMotionParameters, none), __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), " could not create motion parameters for name: "), string(GettingUpMotionParametersName)), ". Using defaults."));
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x4C6
		/*@Error*/
		GettingUpMotionParameters = Class'ShockAI.HavokFlyingMotionParameters'.static.Allocate(self).;
	}
	Construct_Void();
	SwitchToMotion(0);
	TurnLightsOff();
	DisableMovement();
	SetHackedEffectEvent();
	StripUnwantedMotors();
	mSecurityManager = SecurityManager(ShockGameInfo(Level.Game).GetSecurityManager());
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function AddCommanderAbility()
{
	assert(__NFUN_119__(CharacterAI, none));
	CharacterAI.addAbility_Class(Class'ShockAI.BotCommanderAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function CharacterAICreated()
{
	super(ShockAI).CharacterAICreated();
	CharacterAI.addAbility_Class(Class'ShockAI.BotBeMeanAction');
	CharacterAI.addAbility_Class(Class'ShockAI.BotBeDormantAction');
	CharacterAI.addAbility_Class(Class'ShockAI.BotBeFriendlyAction');
	CharacterAI.addAbility_Class(Class'ShockAI.BotReturnHomeAction');
	CharacterAI.addAbility_Class(Class'ShockAI.BotMovementTestAction');
	CharacterAI.addAbility_Class(Class'ShockAI.BotAttackTargetAction');
	CharacterAI.addAbility_Class(Class'ShockAI.BotGoToAlarmTargetAction');
	CharacterAI.addAbility_Class(Class'ShockAI.BotSearchForAlarmTargetAction');
	CharacterAI.addAbility_Class(Class'ShockAI.BotGoToActorAction');
	CharacterAI.addAbility_Class(Class'ShockAI.BotProtectTargetAction');
	CharacterAI.addAbility_Class(Class'ShockAI.BotNavigateToActorLocationMovementAction');
	CharacterAI.addAbility_Class(Class'ShockAI.BotNavigateToPointLocationMovementAction');
	CharacterAI.addAbility_Class(Class'ShockAI.BotNavigateToAlarmTargetLocationMovementAction');
	CharacterAI.addAbility_Class(Class'ShockAI.BotAttackTargetMovementAction');
	CharacterAI.addAbility_Class(Class'ShockAI.BotProtectTargetMovementAction');
	CharacterAI.addAbility_Class(Class'ShockAI.SearchAction');
	CharacterAI.addAbility_Class(Class'ShockAI.BotSearchForAlarmTargetMovementAction');
	CharacterAI.addAbility_Class(Class'ShockAI.BotRiseOffGroundAction');
	CharacterAI.addAbility_Class(Class'ShockAI.BotFrozenAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function MovementAICreated()
{
	super(ShockAI).MovementAICreated();
	MovementAI.addAbility_Class(Class'ShockAI.MoveToAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function Destroyed()
{
	log('AI_Security', 4, __NFUN_112__("Security bot destroyed: ", string(self)));
	ShutdownEverything();
	// End:0x83
	if(__NFUN_119__(theWeapon, none))
	{
		theWeapon.UnTriggerEffectEvent('BotFiring');
		theWeapon.__NFUN_279__();
		theWeapon = none;
		Class'ShockGame.CrossbowProjectile'.static.DestroyAnyCrossbowBoltsOnActor(self);
	}
	super(ShockAI).Destroyed();
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function Tick(float DeltaSeconds)
{
	local float VelocityInUnrealUnits;

	super(Actor).Tick(DeltaSeconds);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x80
	/*@Error*/
	VelocityInUnrealUnits = __NFUN_172__(__NFUN_225__(__NFUN_216__(Location, LocationLastTick)), DeltaSeconds);
	Instance.SetDynamicPitchInput(VelocityInUnrealUnits);
	LocationLastTick = Location;
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function BotCommanderAction GetBotCommanderAction()
{
	return BotCommanderAction(Commander.achievingAction);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function CreateWeapons()
{
	AssertWithDescription(__NFUN_119__(weaponClass, none), __NFUN_112__(__NFUN_112__("The WeaponClass was not specified for class ", string(Class)), "."));
	theWeapon = CreateAIWeapon(weaponClass);
	AssertWithDescription(__NFUN_119__(theWeapon, none), __NFUN_112__("The Weapon was not created for ", string(self)));
	AddAvailableHoldable(theWeapon);
	AttachToBone(theWeapon, theWeapon.GetAttachBone(self));
	Equip(theWeapon);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function SetWeaponFrozen(bool bFrozen, optional bool StopFiringImmediately)
{
	WeaponIsFrozen = bFrozen;
	// End:0x2E
	if(StopFiringImmediately)
	{
		CeaseFiring(, true);
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function FireWeapon()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x27
	/*@Error*/
	GetWeapon().FireWeapon();
	return;
	@NULL
}

latent function StartCharging()
{
	GetWeapon().StartCharging();
	return;
}

function BotBaseGun GetWeapon()
{
	return BotBaseGun(theWeapon);
	return;
	@NULL
	CommanderAction
}

// Export USecurityBot::execSaveDefaultCenterOfMass(FFrame&, void* const)
native function SaveDefaultCenterOfMass();

function SetBodyCenterOfMass(Vector newCenterOfMass)
{
	//native.newCenterOfMass;	
	@NULL
}

function TellToStayLow(float TimeToStayLow, float inStayLowHeight)
{
	StayLowEndTime = __NFUN_174__(TimeToStayLow, Level.TimeSeconds);
	StayLowHeight = inStayLowHeight;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function StartEverything()
{
	StartEngine();
	StartAnimations();
	StiffenPropeller();
	EnableMovement();
	SetHackedEffectEvent();
	TurnLightsOn();
	return;
}

function ShutdownEverything()
{
	StopEngine();
	StopAnimations();
	UnstiffenPropeller();
	DisableMovement();
	SetHackedEffectEvent();
	TurnLightsOff();
	return;
}

function StartAnimations()
{
	local array<name> BladesAnimationArray;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x103
	/*@Error*/
	TriggerEffectEvent('PropellerOperating');
	BladesAnimationArray[BladesAnimationArray.Length] = 'SpinUp';
	BladesAnimationArray[BladesAnimationArray.Length] = 'BladesTurning';
	BladesAnimationArray[BladesAnimationArray.Length] = 'SpinDown';
	BladesAnimHandle = PlayAnimationChainOnChannel(0, BladesAnimationArray, 2);
	assert(__NFUN_154__(GetNumberOfAnimationsInChain(BladesAnimHandle), 3));
	SetAnimationChainControlFlags(BladesAnimHandle, 0, 0);
	SetAnimationChainControlFlags(BladesAnimHandle, 1, 2);
	SetAnimationChainControlFlags(BladesAnimHandle, 2, 0);
	StartAnimationsState = true;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function StopAnimations()
{
	// End:0x41
	if(StartAnimationsState)
	{
		UnTriggerEffectEvent('PropellerOperating');
		SetAnimationChainControlFlags(BladesAnimHandle, 1, 0);
		StartAnimationsState = false;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

// Export USecurityBot::execStripUnwantedMotors(FFrame&, void* const)
native function StripUnwantedMotors();

function StiffenPropeller()
{
	GetRagdoll().SetMotorsEnabled(true, 0.0000000);
	return;
}

function UnstiffenPropeller()
{
	GetRagdoll().SetMotorsEnabled(false, 0.0000000);
	return;
}

function StartEngine(optional bool bForceStartEngine)
{
	// End:0x44
	if(__NFUN_132__(__NFUN_129__(StartEngineState), bForceStartEngine))
	{
		TriggerEffectEvent('EngineOperating',,,,,,, self);
		StartEngineState = true;
		return;
		@NULL
		CommanderAction
	}
	stop;
	default.@NULL
}

function StopEngine()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x2C
	/*@Error*/
	UnTriggerEffectEvent('EngineOperating');
	StartEngineState = false;
	return;
	@NULL
	CommanderAction
}

function int GetAnimationChannelForWeapon(Weapon inWeapon)
{
	return 3;
	return;
}

function TurnLightsOff()
{
	local int i;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xB1
	/*@Error*/
	bLightsOn = false;
	UnTriggerEffectEvent('LightsOn');
	TriggerEffectEvent('LightsOff');
	// End:0x59
	if(__NFUN_154__(Skins.Length, 0))
	{
		CopyMaterialsToSkins();
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xB1
		/*@Error*/
	}
	Skins[i] = LightsOffSkins[i];
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x64;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function TurnLightsOn()
{
	local int i;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xB3
	/*@Error*/
	bLightsOn = true;
	UnTriggerEffectEvent('LightsOff');
	TriggerEffectEvent('LightsOn');
	// End:0x5B
	if(__NFUN_154__(Skins.Length, 0))
	{
		CopyMaterialsToSkins();
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xB3
		/*@Error*/
	}
	Skins[i] = LightsOnSkins[i];
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x66;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ResetHackedEffectEvents()
{
	UnTriggerEffectEvent('BotNotHackedNeutral');
	UnTriggerEffectEvent('BotNotHacked');
	UnTriggerEffectEvent('BotHacked');
	return;
}

function SetHackedEffectEvent()
{
	ResetHackedEffectEvents();
	// End:0xEF
	if(__NFUN_129__(IsDormant()))
	{
		// End:0x7A
		if(__NFUN_132__(WasHackedByPlayerWhenKilled, __NFUN_130__(__NFUN_130__(IsHacked(), __NFUN_119__(CurrentOwner, none)), CurrentOwner.__NFUN_303__('ShockPlayer'))))
		{
			TriggerEffectEvent('BotHacked');
			goto J0xEF;
			// End:0xDC
			if(__NFUN_132__(IsMean(), IsReturningHome()))
			{
			}
			// End:0xC6
			if(mSecurityManager.LastAlarmTargetWasPlayer())
			{
				TriggerEffectEvent('BotNotHacked');
				goto J0xD9;
				TriggerEffectEvent('BotNotHackedNeutral');
			}
			goto J0xEF;
			TriggerEffectEvent('BotNotHacked');
		}
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function SetCurrentOwner(ShockPawn NewOwner)
{
	assert(__NFUN_132__(__NFUN_114__(CurrentOwner, none), __NFUN_129__(CurrentOwner.OwnsControllable(self))));
	CurrentOwner = NewOwner;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function RegisterBotControllable(ShockPawn NewController)
{
	local ShockPawn TestPawn;

	// End:0x36
	foreach __NFUN_313__(Class'ShockGame.ShockPawn', TestPawn)
	{
		assert(__NFUN_129__(TestPawn.OwnsControllable(self)));				
		assert(__NFUN_114__(NewController, CurrentOwner));
	}
	CurrentOwner.RegisterControllable(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function UnregisterBotControllable()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x27
	/*@Error*/
	CurrentOwner.UnregisterControllable(self);
	return;
	@NULL
	CommanderAction
}

function Hack(ShockPawn Hacker)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x31
	/*@Error*/
	GetBotCommanderAction().OnHacked(Hacker);
	return;
	@NULL
}

function Use(ShockPawn User)
{
	assert(__NFUN_119__(User, none));
	// End:0x9A
	if(CanChangeActivationState())
	{
		// End:0x67
		if(IsDormant())
		{
			// End:0x64
			if(User.CanHaveMoreBotControllables())
			{
				GetBotCommanderAction().Reactivate(User);
				goto J0x9A;
				assert(User.OwnsControllable(self));
			}
		}
		GetBotCommanderAction().Deactivate();
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function string GetHackVerbText()
{
	return "HACK";
	return;
}

function bool CanBeHackedNow(ShockPlayer Player)
{
	// End:0x27
	if(__NFUN_130__(IsHackedBy(Player), AllowFriendlyBotsToBeDeactivated))
	{
		return false;
		return __NFUN_130__(__NFUN_130__(__NFUN_129__(DisallowHacking), __NFUN_132__(__NFUN_132__(IsDormant(), IsFrozen()), IsShocked())), Player.CanHaveMoreBotControllables());
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnHackAttempted(ShockPlayer Player)
{
	// End:0x1A
	if(__NFUN_129__(CanBeHackedNow(Player)))
	{
		return;
		// End:0x38
		if(__NFUN_129__(Player.CanHaveMoreBotControllables()))
		{
		}
		return;
		// End:0xA4
		if(Player.HasMod('SecurityBotAutoHack_Exists'))
		{
		}
		Hack(Player);
		dispatchMessage(Class'ShockGame.MessagePlayerFinishedHacking'.static.Allocate(self)., construct_ICanBeHackedBool(self, true));
		goto J0x11F;
		Player.OnStartHacking(GetHackInfo(), self);
	}
	Level.GetFlashGUIController().GetPlayingMovie('Hacking').CallMethodString("SetHackDescription", HackingSuccessFeedbackText);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool IsHackedBy(ShockPawn Hacker)
{
	return __NFUN_130__(__NFUN_119__(CurrentOwner, none), __NFUN_114__(CurrentOwner, Hacker));
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function bool IsHackedByPlayer()
{
	return __NFUN_130__(__NFUN_119__(CurrentOwner, none), __NFUN_114__(CurrentOwner, ShockPlayer(Level.GetLocalPlayerController().Pawn)));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool IsHacked()
{
	return __NFUN_119__(CurrentOwner, none);
	return;
	@NULL
}

function HackInfo OnHackSucceeded(ShockPlayer Player, string HackResult)
{
	Hack(Player);
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
	// End:0x4C
	if(__NFUN_130__(ExplodeOnFailedHack, __NFUN_123__(HackResult, "End")))
	{
		DisallowHacking = true;
		SetDyingStateTime(BotLifeSpawnAfterFailedHack);
		__NFUN_113__('Dying');
		return GetHackInfo();
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

function HackInfo GetHackInfo()
{
	// End:0x5B
	if(__NFUN_114__(HackingGameSetupInfo, none))
	{
		HackingGameSetupInfo = Class'ShockGame.HackInfo'.static.Allocate(self,, string(HackInfoName)).;
		Construct_Void();
		assert(__NFUN_119__(HackingGameSetupInfo, none));
		HackingGameSetupInfo.HackPurchaseOptionEnabled = HackPurchaseOptionEnabled;
	}
	return HackingGameSetupInfo;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool CanBeSearchedNow()
{
	local ShockPlayer Player;

	Player = ShockPlayer(Level.GetLocalPlayerController().Pawn);
	return __NFUN_130__(__NFUN_130__(__NFUN_114__(CurrentOwner, none), Player.CanUseContainer(LootContainer)), IsDormant());
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool CanChangeActivationState()
{
	return __NFUN_130__(__NFUN_130__(AllowFriendlyBotsToBeDeactivated, __NFUN_119__(CurrentOwner, none)), __NFUN_114__(Level.GetLocalPlayerController().Pawn, CurrentOwner));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool CanBeUsedNow()
{
	local ShockPlayer Player;

	// End:0x6D
	if(CanChangeActivationState())
	{
		Player = ShockPlayer(Level.GetLocalPlayerController().Pawn);
		return __NFUN_132__(__NFUN_129__(IsDormant()), Player.CanHaveMoreBotControllables());
		return CanBeSearchedNow();
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function OnUsed(Pawn Pawn)
{
	local ShockPawn UseShockPawn;

	// End:0x11
	if(__NFUN_129__(CanBeUsedNow()))
	{
		return;
	}
	UseShockPawn = ShockPawn(Pawn);
	assert(__NFUN_119__(UseShockPawn, none));
	Use(UseShockPawn);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6F
	/*@Error*/
	super(ShockAI).OnUsed(Pawn);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function string GetUseVerbText()
{
	// End:0x34
	if(CanChangeActivationState())
	{
		// End:0x27
		if(IsDormant())
		{
			return ActivateUseVerbString;
			goto J0x31;
			return DeactivateUseVerbString;
		}
		goto J0x3F;
		return super(ShockAI).GetUseVerbText();
		return;
	}
	@NULL
	CommanderAction
	J0x3F:

	CommanderAction
}

function bool ApplyDeadPenalty()
{
	return __NFUN_130__(__NFUN_132__(super(ShockAI).ApplyDeadPenalty(), IsDormant()), __NFUN_254__(DeadPhotoLabel, 'None'));
	return;
	@NULL
	CommanderAction
}

function bool CanBeFocusedNow()
{
	return true;
	return;
}

function OnFocusStarted()
{
	super(ShockAI).OnFocusStarted();
	theWeapon.TriggerEffectEvent('BecameUseFocus');
	return;
	@NULL
	CommanderAction
}

function OnFocusStopped()
{
	super(ShockAI).OnFocusStopped();
	theWeapon.UnTriggerEffectEvent('BecameUseFocus');
	return;
	@NULL
	CommanderAction
}

function IPotentialAimOrActionTarget.TargetType GetTargetType()
{
	local Actor Target, Player;
	local bool IsAction;

	Target = GetAttackTarget();
	Player = Level.GetLocalPlayerController().Pawn;
	// End:0x7C
	if(__NFUN_132__(CanBeUsedNow(), CanBeHackedNow(ShockPlayer(Player))))
	{
		IsAction = true;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xAC
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xA6
		/*@Error*/
		return 3;
		goto J0xA9;
		return 2;
	}
	goto J0xC2;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xBF
	/*@Error*/
	return 1;
	goto J0xC2;
	return 0;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function string GetFocusDisplayName()
{
	// End:0x34
	if(IsDormant())
	{
		// End:0x27
		if(CanChangeActivationState())
		{
			return DeactivatedString;
			goto J0x31;
			return DormantString;
		}
		goto J0x3F;
		return super(ShockAI).GetFocusDisplayName();
		return;
	}
	@NULL
	CommanderAction
	J0x3F:

	CommanderAction
}

function string GetHUDMessageForFocusAttained()
{
	return GetFocusDisplayName();
	return;
}

function OnRegistered(ShockPawn Registerer)
{
	return;
}

function OnUnregistered(ShockPawn Registerer)
{
	return;
}

function OnControllerKilled(ShockPawn Controller)
{
	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), " notified that its controller "), string(Controller)), " has been killed."));
	GetBotCommanderAction().OnControllerKilled(Controller);
	return;
	@NULL
	CommanderAction
}

function OnControllerDestroyed(ShockPawn Controller)
{
	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), " notified that its controller "), string(Controller)), " has been destroyed."));
	GetBotCommanderAction().OnControllerDestroyed(Controller);
	return;
	@NULL
	CommanderAction
}

function OnControllerDamaged(ShockPawn Damager, float TotalDamageDealt)
{
	GetBotCommanderAction().OnControllerDamaged(Damager, TotalDamageDealt);
	return;
	@NULL
	CommanderAction
}

function OnControllerDealtDamage(ShockPawn Damagee, float TotalDamageDealt)
{
	GetBotCommanderAction().OnControllerDealtDamage(Damagee, TotalDamageDealt);
	return;
	@NULL
	CommanderAction
}

function AttackSpecifiedTarget(ShockPawn Target, bool ForceNewTarget)
{
	log(,, __NFUN_112__(__NFUN_112__("SecurityBot::AttackSpecifiedTarget( ", string(Target)), " );"));
	ScriptedFriendlyAttackTarget = Target;
	GetBotCommanderAction().AttackSpecifiedTarget(Target, ForceNewTarget);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function SetSector(int Sector)
{
	CurrentSector = Sector;
	return;
	@NULL
	CommanderAction
}

function int GetSector()
{
	return CurrentSector;
	return;
	@NULL
}

function OnEffectInitialized(Actor inInitializedEffect)
{
	local SoundInstance InitializedSoundInstance;

	InitializedSoundInstance = SoundInstance(inInitializedEffect);
	// End:0x51
	if(__NFUN_119__(InitializedSoundInstance, none))
	{
		// End:0x51
		if(__NFUN_254__(InitializedSoundInstance.EffectEvent, 'EngineOperating'))
		{
			return;
			super(ShockAI).OnEffectInitialized(inInitializedEffect);
			return;
			@NULL
			CommanderAction
			CommanderAction
		}
	}
	@NULL
}

function OnEffectStarted(Actor inStartedEffect)
{
	local SoundInstance StartedSoundInstance;

	StartedSoundInstance = SoundInstance(inStartedEffect);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x64
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x64
	/*@Error*/
	Instance = StartedSoundInstance;
	return;
	super(ShockAI).OnEffectStarted(inStartedEffect);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnEffectStopped(Actor inStoppedEffect, bool inCompleted)
{
	local SoundInstance StoppedSoundInstance;

	StoppedSoundInstance = SoundInstance(inStoppedEffect);
	// End:0x5C
	if(__NFUN_119__(StoppedSoundInstance, none))
	{
		// End:0x5C
		if(__NFUN_254__(StoppedSoundInstance.EffectEvent, 'EngineOperating'))
		{
			Instance = none;
			return;
			super(ShockAI).OnEffectStopped(inStoppedEffect, inCompleted);
			return;
			@NULL
			CommanderAction
		}
	}
	CommanderAction
	@NULL
}

event OnSecuritySystemInactive()
{
	GetBotCommanderAction().OnSecuritySystemDeactivated();
	return;
}

function OnSecurityAlarmOff(bool TurnedOffBySecurityStation, optional bool CleanupSecurityImmediately)
{
	GetBotCommanderAction().OnSecurityAlarmEnded(TurnedOffBySecurityStation, CleanupSecurityImmediately);
	return;
	@NULL
	CommanderAction
}

function OnSecurityBeaconApplied(Actor Damager, ShockPawn SecurityBeaconTarget)
{
	GetBotCommanderAction().OnSecurityBeaconApplied(Damager, SecurityBeaconTarget);
	return;
	@NULL
	CommanderAction
}

function OnAlarmTargetChanged(ShockPawn NewTarget)
{
	GetBotCommanderAction().OnAlarmTargetChanged(NewTarget);
	return;
	@NULL
}

event OnSecurityAlarmReactivated()
{
	GetBotCommanderAction().OnSecurityAlarmReactivated();
	return;
}

function HitByAirBlast(Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, float HitMomentumImparted, name HitLowBone, name HitHighBone, DamageStimuliSet DamageStimuli)
{
	Class'ShockAI.FallDownReactionAction'.static.ApplyDeferredMomentum(self, DamageStimuli.GetState(), HitImpulseDirection, HitLocation, HitLowBone);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ApplyHitMomentum(Vector Impulse, Vector HitLocation, name HitLowBone)
{
	//native.Impulse;
	//native.HitLocation;
	//native.HitLowBone;	
	@NULL
	@NULL
	return return @NULL;
}

function OnDamaged(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, bool bIsCriticalHit, optional name HitHighBone, optional name HitLowBone)
{
	local float MomentumImparted;
	local ShockPawn ShockDamager;

	super(ShockAI).OnDamaged(DamageStimuli, TotalDamageDealt, Damager, HitLocation, HitNormal, HitImpulseDirection, EffectEventName, bIsCriticalHit, HitHighBone, HitLowBone);
	ShockDamager = ShockPawn(Damager);
	// End:0xDB
	if(__NFUN_130__(__NFUN_119__(ShockDamager, none), ShouldTreatAsIntentionalDamage(Damager, DamageStimuli)))
	{
		GetBotCommanderAction().OnIntentionallyDamaged(ShockDamager, TotalDamageDealt);
		MomentumImparted = DamageStimuli.GetMomentumImparted(self, HitLowBone);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x149
		/*@Error*/
		ApplyHitMomentum(__NFUN_212__(HitImpulseDirection, MomentumImparted), HitLocation, HitLowBone);
	}
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function OnKilled(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, bool bIsCriticalHit, optional name HitHighBone, optional name HitLowBone)
{
	UnregisterBotControllable();
	// End:0x41
	if(__NFUN_130__(__NFUN_119__(CurrentOwner, none), CurrentOwner.IsPlayer()))
	{
		WasHackedByPlayerWhenKilled = true;
		SetCurrentOwner(none);
		ShutdownHackingScreenIfOpenedOnSelf();
	}
	SetVisionState(false);
	SetHackedEffectEvent();
	SetDyingStateTime(BotLifeSpanAfterDeath);
	super(ShockAI).OnKilled(DamageStimuli, TotalDamageDealt, Damager, HitLocation, HitNormal, HitImpulseDirection, EffectEventName, bIsCriticalHit, HitHighBone, HitLowBone);
	DisableMovement();
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function SetDyingStateTime(float inDyingStateTime)
{
	assert(__NFUN_179__(inDyingStateTime, 0.0000000));
	DyingStateTime = inDyingStateTime;
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function CancelDyingTimer()
{
	__NFUN_113__('None');
	return;
}

function OnKilledOtherPawn(ShockPawn Killee)
{
	log('AI_Security', 5, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " killed the pawn "), string(Killee)), ".  AttackTarget = "), string(GetAttackTarget())), "."));
	// End:0x91
	if(__NFUN_114__(Killee, GetAttackTarget()))
	{
		PlaySpeech('KilledTarget');
		GetBotCommanderAction().OnKilledOtherPawn(Killee);
	}
	super(ShockPawn).OnKilledOtherPawn(Killee);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function EnableMovement()
{
	log('AI_Security', 4, __NFUN_112__(string(Name), "'s motors and weapons are being enabled."));
	HavokSetLinearDamping(0.0000000);
	HavokSetAngularDamping(1.0000000);
	ResetHavokLocationAndRotation();
	GetRagdoll().Unfreeze();
	MotorsEnabled = true;
	SetBodyCenterOfMass(BodyCenterOfMassWhileFlying);
	__NFUN_262__(, true, true);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function DisableMovement()
{
	log('AI_Security', 4, __NFUN_112__(string(Name), "'s motors and weapons are being disabled."));
	MotorsEnabled = false;
	SetBodyCenterOfMass(DefaultBodyCenterOfMass);
	HavokSetLinearDamping(0.0000000);
	HavokSetAngularDamping(0.0000000);
	CeaseFiring();
	__NFUN_262__(, false, false);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function FreezeMotors()
{
	MotorsFrozen = true;
	return;
	@NULL
}

function UnfreezeMotors()
{
	MotorsFrozen = false;
	return;
	@NULL
}

// Export USecurityBot::execStiffenRotor(FFrame&, void* const)
native function StiffenRotor();

// Export USecurityBot::execUnstiffenRotor(FFrame&, void* const)
native function UnstiffenRotor();

function Explode()
{
	log('AI_Security', 4, __NFUN_112__(string(Name), " is about to explode!"));
	Class'ShockGame.CrossbowProjectile'.static.DetachAnyCrossbowBoltsFromActor(self);
	TriggerEffectEvent('Exploded',,,, GetBotRotationFromRagdoll());
	Class'ShockGame.DamageFactory'.static.DealRadiusDamage_ActorVectorFloatFloatNameFloat(self, self.Location, InnerExplosionAttenuationRadius, OuterExplosionAttenuationRadius, ExplosionDamageStimuliSetName, 0.0000000);
	DisallowHacking = true;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool IsFiringWeapon()
{
	return theWeapon.__NFUN_281__('Firing');
	return;
	@NULL
}

function bool IsSuspectingAttackFrom(ShockPawn Target)
{
	return __NFUN_130__(__NFUN_130__(IsAlive(), IsMean()), __NFUN_114__(Target, GetAttackTarget()));
	return;
	@NULL
}

function OnBumpedOtherBot(SecurityBot OtherBot)
{
	GetBotCommanderAction().OnBumpedOtherBot(OtherBot);
	return;
	@NULL
}

function bool CanHit(ShockPawn Target)
{
	return __NFUN_130__(__NFUN_176__(__NFUN_225__(__NFUN_216__(Target.Location, Location)), GetMaximumAttackRange()), theWeapon.CanHitTarget(Target, true, false));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool CanDetectProtectTarget(ShockPawn Target)
{
	return CanDetectActor(Target);
	return;
	@NULL
}

function bool CanDetectActor(Actor Target)
{
	//native.Target;	
	@NULL
}

function SetEnableVerticalSway(bool SwayEnabled)
{
	EnableVerticalSway = SwayEnabled;
	return;
	@NULL
	CommanderAction
}

function ResetVisionCone()
{
	PeripheralVision = __NFUN_188__(__NFUN_171__(0.0174533, FOV));
	return;
	@NULL
	CommanderAction
}

function float GetRandomSillyActionDelta()
{
	return RandRange(SillyActionDeltaRange.Min, SillyActionDeltaRange.Max);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function float GetDormantDuration()
{
	return DormantDuration;
	return;
	@NULL
}

function float GetRandomBurstInterval()
{
	return RandRange(BurstIntervalRange.Min, BurstIntervalRange.Max);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function float GetDetectRadius()
{
	return DetectRadius;
	return;
	@NULL
}

function float GetRandomDesiredHeightWhileAttacking()
{
	return RandRange(DesiredHeightWhileAttacking.Min, DesiredHeightWhileAttacking.Max);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function float GetRandomDesiredDistanceWhileProtecting()
{
	return RandRange(DesiredRangeWhileProtecting.Min, DesiredRangeWhileProtecting.Max);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function float GetRandomDesiredHeightWhileProtecting()
{
	return RandRange(DesiredHeightWhileProtecting.Min, DesiredHeightWhileProtecting.Max);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Range GetDesiredRangeWhileProtecting()
{
	return DesiredRangeWhileProtecting;
	return;
	@NULL
}

function float GetMaximumAttackRange()
{
	return MaximumAttackRange;
	return;
	@NULL
}

function Range GetMoveWhileAttackingAngleRange()
{
	return MoveWhileAttackingAngleRange;
	return;
	@NULL
}

function int GetNumTimesToFindUsablePoint()
{
	return NumTimesToFindUsablePoint;
	return;
	@NULL
}

function float GetRandomPointDistance()
{
	return RandomPointDistance;
	return;
	@NULL
}

function float GetMinRandomPointDistanceFromTarget()
{
	return MinRandomPointDistanceFromTarget;
	return;
	@NULL
}

function float GetHackedStartUpDelay()
{
	return HackedStartUpDelay;
	return;
	@NULL
}

function float GetHackedRotorStartDelay()
{
	return HackedRotorStartDelay;
	return;
	@NULL
}

function float GetHackedMovementStartDelay()
{
	return HackedMovementStartDelay;
	return;
	@NULL
}

function float GetRandomSecuritySystemShutdownDormantDelay()
{
	return RandRange(SecuritySystemShutdownDormantDelay.Min, SecuritySystemShutdownDormantDelay.Max);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function float GetFrozenMovementStopDelay()
{
	return FrozenMovementStopDelay;
	return;
	@NULL
}

// Export USecurityBot::execIsInitializing(FFrame&, void* const)
native function bool IsInitializing();

// Export USecurityBot::execIsMean(FFrame&, void* const)
native function bool IsMean();

// Export USecurityBot::execIsDormant(FFrame&, void* const)
native function bool IsDormant();

// Export USecurityBot::execIsFriendly(FFrame&, void* const)
native function bool IsFriendly();

// Export USecurityBot::execIsReturningHome(FFrame&, void* const)
native function bool IsReturningHome();

// Export USecurityBot::execGetProtectTarget(FFrame&, void* const)
native function ShockPawn GetProtectTarget();

// Export USecurityBot::execMotorsAreEnabled(FFrame&, void* const)
native function bool MotorsAreEnabled();

function bool PawnIsFriendly(ShockPawn TestPawn)
{
	//native.TestPawn;	
	@NULL
}

// Export USecurityBot::execGetCurrentOwner(FFrame&, void* const)
native function ShockPawn GetCurrentOwner();

function EnterTestMode()
{
	GetBotCommanderAction().EnterTestMode();
	return;
}

function TestGoToLocation(Vector testLocation)
{
	GetBotCommanderAction().TestGoToLocation(testLocation);
	return;
	@NULL
}

function FakeAttackPawn(ShockPawn targetPawn)
{
	GetBotCommanderAction().FakeAttackPawn(targetPawn);
	return;
	@NULL
}

state Dying
{
	ignores EndState;
Begin:

	DeathTime = __NFUN_174__(Level.TimeSeconds, DyingStateTime);
	// End:0x151
	if(__NFUN_176__(Level.TimeSeconds, DeathTime))
	{
		// End:0xE7
		if(__NFUN_177__(Level.TimeSeconds, NextLightSwitchTime))
		{
			// End:0x8D
			if(bLightsOn)
			{
				TurnLightsOff();
				goto J0x97;
				TurnLightsOn();
				NextLightSwitchTime = __NFUN_174__(Level.TimeSeconds, __NFUN_171__(__NFUN_193__(__NFUN_175__(DeathTime, Level.TimeSeconds)), LightSwitchTimeMultiplier));
			}
			// End:0x146
			if(__NFUN_130__(__NFUN_129__(HasSentDeathMessage), __NFUN_176__(__NFUN_175__(DeathTime, Level.TimeSeconds), PreExplodeNoiseTime)))
			{
				TriggerEffectEvent('ExplodeWarning');
				HasSentDeathMessage = true;
				__NFUN_256__(0.0000000);
			}
			// [Loop Continue]
			goto J0x2B;
			TurnLightsOff();
			Explode();
			__NFUN_113__('Dead');
			stop;									
			@NULL
			default.@NULL
			@NULL
			@NULL
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			/*@Error*/
			// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.get_CurrentToken() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 40
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 845
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
			// 2 & Type:If Position:0x146
		}
	}
}

state Dead
{Begin:

	__NFUN_279__();
	stop;				
}

defaultproperties
{
	MinimumRemovalDistance=1000.0000000
	MinimumRemovalOffscreenTime=1.5000000
	SillyActionDeltaRange=(Min=15.0000000,Max=20.0000000)
	VerticalSwayPeriod=3.0000000
	VerticalSwayDistance=0.5000000
	VerticalSwayThrust=2.0000000
	VerticalSwayDelay=0.5000000
	DetectRadius=2000.0000000
	DormantString="Set in AI.ini Security Bot (Dormant)"
	DeactivatedString="Set in AI.ini Security Bot (Deactivated)"
	DeactivateUseVerbString="Deactivate"
	ActivateUseVerbString="Reactivate"
	DesiredRangeWhileProtecting=(Min=250.0000000,Max=450.0000000)
	DesiredHeightWhileProtecting=(Min=50.0000000,Max=300.0000000)
	MaximumAttackRange=800.0000000
	MoveWhileAttackingAngleRange=(Min=20.0000000,Max=20.0000000)
	AttackingHoverPointWaitTimeRangePlayer=(Min=0.3000000,Max=0.7000000)
	AttackingHoverPointWaitTimeRangeAI=(Min=0.0000000,Max=0.2000000)
	NumTimesToFindUsablePoint=10
	OnBumpedBotNewPointChance=0.5000000
	RandomPointDistance=300.0000000
	BurstIntervalRange=(Min=3.0000000,Max=3.0000000)
	DormantDuration=10.0000000
	BotLifeSpanAfterDeath=5.0000000
	BotLifeSpawnAfterFailedHack=0.5000000
	LightSwitchTimeMultiplier=0.1000000
	InnerExplosionAttenuationRadius=300.0000000
	OuterExplosionAttenuationRadius=500.0000000
	ExplosionDamageStimuliSetName="SecurityBotExplosionStimuliSet"
	WeaponUpperPitchLimit=30.0000000
	WeaponLowerPitchLimit=-30.0000000
	WeaponYawLimit=20.0000000
	ExplodeOnFailedHack=true
	HackPurchaseOptionEnabled=true
	HitTorqueModifier=0.9500000
	HackedStartUpDelay=0.5000000
	HackedRotorStartDelay=1.0000000
	HackedMovementStartDelay=0.7500000
	SecuritySystemShutdownDormantDelay=(Min=0.0000000,Max=0.5000000)
	PreExplodeNoiseTime=0.1000000
	FrozenMovementStopDelay=0.7000000
	AllowFriendlyBotsToBeDeactivated=true
	HackedDamageMultiplier=0.5000000
	TooCloseToFloorDistance=90.0000000
	BotPropellerRagdollBoneName="Ragdoll_sec_bot_top"
	BotBodyRagdollBoneName="Ragdoll_Sec_Bot"
	BodyCenterOfMassWhileFlying=(X=0.0000000,Y=0.0000000,Z=-0.3500000)
	MeanAlternateDamagerTimeout=10.0000000
	FriendlyAlternateDamagerTimeout=15.0000000
	AlternateDamagerMinDamage=5.0000000
	AlternateDamagerCheckTime=1.0000000
	MinFriendlyAttackTargetSwitchTime=4.0000000
	FriendlyLookAtAttackTargetDistance=750.0000000
	MeanLookAtAttackTargetDistance=700.0000000
	AlignmentAllowedDeltaYaw=16384
	DamageToFriendlyBotAggroWeight=0.5000000
	DamageToProtectTargetAggroWeight=1.0000000
	DamageFromProtectTargetAggroWeight=0.3300000
	BotPropellerCollidedEventPeriod=(Min=0.3000000,Max=0.8000000)
	AntiGravityForcePercentage=1.0000000
	ThrustPercentage=1.0000000
	PlayStartupSequenceWhenRisingOffGround=true
	HackInfoName="SecurityBotDefault"
	HackingSuccessFeedbackText="Hacked Security Bots are friendly and will attack your enemies."
	NavigatingMotionParametersName="StandardNavigatingBotMotionParams"
	AttackingMotionParametersName="StandardAttackingBotMotionParams"
	SearchingMotionParametersName="StandardNavigatingBotMotionParams"
	GoingHomeMotionParametersName="StandardGoingHomeBotMotionParams"
	GettingUpMotionParametersName="StandardGettingUpBotMotionParams"
	CorpseString="Destroyed Bot"
	ResearchTrack="SecurityBot"
	AirBlastReactionMultiplier=4.0000000
	ViewDistance=1500.0000000
	EyeBoneName="sec_bot"
	bUseCollisionAvoidance=false
	bDropToGroundUponSpawning=false
	LockedSlotLootTableName="SecurityBotResearched"
	HealthBarNormalOffset=(X=0.0000000,Y=0.0000000,Z=32.0000000)
	CriticalDamageEffectInfos=/* Array type was not detected. */
	LowLODTyrionTickUpdateRange=(Min=0.1000000,Max=0.2000000)
	bVisionEnabled=true
	bUseQuickVision=true
	bCanWalk=false
	bCanFly=true
	bUseHavokPhantomCollisions=false
	bUseHavokFlying=true
	AirSpeed=400.0000000
	Physics=6
	CollisionRadius=54.0000000
	CollisionHeight=64.0000000
	HavokCollisionFXMinHitVelocity=0.2500000
	HavokCollisionFXMinTimeBetweenFX=0.3000000
	HavokCollisionFXLODRadius=4000.0000000
	HavokInteractionSet=0
	Label="SecurityBot"
}