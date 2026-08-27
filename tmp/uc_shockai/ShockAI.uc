class ShockAI extends BaseShockAI implements ICanBeHarvested, IEffectObserver, IBooty, IPhotographTarget, ILocomotionListener
	abstract
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

const DISPLACEMENT_MIN_DIST_TO_DEST = 120.0f;
const kAnimationKeywordRequired = 0;
const kAnimationKeywordDisallowed = -1;
const kGoodLookDirectionTraceDistance = 500.0;

enum EMovementRate
{
	Walk,                           // 0
	Run,                            // 1
	kNumMovementRates               // 2
};

enum EAIState
{
	kNoAIState,                     // 0
	Passive,                        // 1
	Agg,                            // 2
	kNumAIStates                    // 3
};

enum EVisionState
{
	Normal,                         // 0
	Searching,                      // 1
	Attacking,                      // 2
	Ceiling,                        // 3
	Mimic,                          // 4
	Berserk,                        // 5
	Patrol                          // 6
};

enum EDirection
{
	kFront,                         // 0
	kBack,                          // 1
	kLeft,                          // 2
	kRight                          // 3
};

enum ETeleportState
{
	TELE_SOLID,                     // 0
	TELE_IN_TELEGRAPHING,           // 1
	TELE_IN_TRANSITIONING,          // 2
	TELE_OUT_TELEGRAPHING,          // 3
	TELE_OUT_TRANSITIONING,         // 4
	TELE_ETHER                      // 5
};

enum EAIEventReactionType
{
	AIReaction_None,                // 0
	AIReaction_LookAt,              // 1
	AIReaction_TurnTowards,         // 2
	AIReaction_Search               // 3
};

struct native atomic VisionCone
{
	var config float NearGainTime;
	var config float FarGainTime;
	var config float FOV;
	var config float NearDistance;
	var config float FarDistance;
	var config bool bIsDoubtCone;
	var float PeripheralVision;
	var config Rotator ViewDirectionOffset;
	var config Class<ShockPawn> PawnType;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic TaggedSpeechName
{
	var name SpeechName;
	var float NextTimeCanBePlayed;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic EventReactionSpecifier
{
	var config ShockAI.EAIEventReactionType ReactionType;
	var config Range Duration;
	var config Range Delay;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic EventReactionEntry
{
	var config AIEventNotification.EAIEventNotificationType Event;
	var config EventReactionSpecifier Reaction;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic SkeletalRegionHitReactionEntry
{
	var config Actor.ESkeletalRegion SkeletalRegion;
	var config name HitReactionAnimation;

	structdefaultproperties
	{
		CheckpointTypePadding=7209061
	}
};

var config localized string FriendlyName;
var config localized string UseVerbText;
var config localized string CollectCrossbowsVerbText;
var const config localized string CorpseString;
var private config name ResearchTrack;
var private config name DeadPhotoLabel;
var int PhotoTakenCount;
var private int CurrentAnimationPhotoScore;
var private CommanderGoal Commander;
var private AIArchetype OurAIArchetype;
var private config float AirBlastReactionMultiplier;
var const bool bIsRepopulationAI;
var private config float FOV;
var private config float ViewDistance;
var private bool bUsingComplexVision;
var private ShockAI.EVisionState VisionState;
var private bool bAlwaysSeePlayer;
var config float NormalVisionDecayTime;
var config float SearchingVisionDecayTime;
var config float AttackingVisionDecayTime;
var config float CeilingVisionDecayTime;
var config float MimicVisionDecayTime;
var config float BerserkVisionDecayTime;
var config float PatrolVisionDecayTime;
var config float MinDistanceFromLastKnownLocationToLoseTarget;
var config array<VisionCone> NormalVisionCones;
var config array<VisionCone> SearchingVisionCones;
var config array<VisionCone> AttackingVisionCones;
var config array<VisionCone> CeilingVisionCones;
var config array<VisionCone> MimicVisionCones;
var config array<VisionCone> BerserkVisionCones;
var config array<VisionCone> PatrolVisionCones;
var config float QuickHeadTurnAcceleration;
var config float CasualHeadTurnAcceleration;
var config float LimitAngle;
var config float SpotEnemyTurnDelay;
var private int CeilingVisionDesiredCount;
var private int AttackingVisionDesiredCount;
var private int SearchingVisionDesiredCount;
var private int MimicVisionDesiredCount;
var private int BerserkVisionDesiredCount;
var private int PatrolVisionDesiredCount;
var private float LastBerserkStartTime;
var private bool bIsVulnerable;
var private bool bCannotDie;
var private float LastTimeIntentionallyDamaged;
var config Range DelayOnGroundRange;
var config array<name> HitFrontAnimations;
var config array<name> HitLeftAnimations;
var config array<name> HitRightAnimations;
var config array<name> HitBackAnimations;
var config array<name> CeilingHitFrontAnimations;
var config array<name> CeilingHitLeftAnimations;
var config array<name> CeilingHitRightAnimations;
var config array<name> CeilingHitBackAnimations;
var config array<SkeletalRegionHitReactionEntry> SkeletalRegionHitReactions;
var config array<name> HitFrontDeathAnimations;
var config array<name> HitLeftDeathAnimations;
var config array<name> HitRightDeathAnimations;
var config array<name> HitBackDeathAnimations;
var config array<SkeletalRegionHitReactionEntry> SkeletalRegionDeathReactions;
var private config Range ShockedInWaterDeathAnimationDurationRange;
var config array<name> FlailingAnimations;
var config array<name> JumpInWaterAnimations;
var private config Range TimeRangeBetweenFullBodyHitReactions;
var private float NextFullBodyHitReactionTime;
var array<Object> FullBodyHitReactionPreventionRequesters;
var array<Object> FallDownHitReactionPreventionRequesters;
var array<Object> QuickHitReactionPreventionRequesters;
var array<Object> EventReactionPreventionRequesters;
var private bool bScriptedFullBodyReactionPrevention;
var private bool bScriptedFallDownReactionPrevention;
var private bool bScriptedQuickHitReactionPrevention;
var private bool bScriptedEventReactionPrevention;
var config array<name> HitFrontAdditiveAnimations;
var config array<name> HitLeftAdditiveAnimations;
var config array<name> HitRightAdditiveAnimations;
var config array<name> HitBackAdditiveAnimations;
var config array<name> ShockedAnimations;
var private config Range BurningTimeRange;
var config bool bDoNotDoBurningBehavior;
var config bool bDoNotDoBurningAnimations;
var config array<name> PostShatteredAnimations;
var private config Range SwarmReactionTimeRange;
var config bool bDoNotDoInsectSwarmAnimations;
var config bool bDoNotDoInsectSwarmBehavior;
var private config name LipSynchAnimation;
var private config float LipSynchFrequency;
var private config int LipSynchChannel;
var private int hLipSynch;
var private transient pointer Perlin;
var config array<EventReactionEntry> DefaultEventReactions;
var config array<EventReactionEntry> EventReactionOverrides;
var config name EyeBoneName;
var config bool bUsesEyeBoneLocation;
var config bool bUsesEyeHeight;
var bool bAlwaysUseExpensiveVision;
var private float LastViewUpdateTime;
var private Vector CurrentViewOrigin;
var private Vector CurrentViewDirection;
var private Vector SimpleViewOrigin;
var private Vector SimpleViewDirection;
var private bool bShouldSeePlayer;
var private Container LootContainer;
var private bool bShouldBeHarvested;
var private float CurrentHarvestAmount;
var private float MaxHarvestAmount;
var config bool bShouldUseLocomotion;
var config bool bOptimizeAIPhysicsAtLowDetail;
var config float OptimizedPhysicsWalkSpeed;
var config float OptimizedPhysicsRunSpeed;
var config bool bShouldUseFootIKTracker;
var config bool bShouldUseQuickHitReaction;
var array<int> ScriptedLoopingAnimationHandles;
var config bool bConsiderAsBootyForGatherersWhenDead;
var private BootyImpl BootyImpl;
var config bool bCanTeleport;
var name VoiceType;
var array<SpeechEvent> SpeechQueue;
var /*0x00000000-0x01000000*/ private SoundInstance CurrentSound;
var /*0x00000000-0x01000000*/ private SpeechEvent CurrentSpeechEvent;
var private const name SavedSpeechEventName;
var private const int SavedSpeechEventTime;
var private const string SavedSpeechSoundName;
var private float NextTimeCanPlayQueuedSpeech;
var array<TaggedSpeechName> FrequencyLimitedEvents;
var private bool bIsMute;
var private transient bool bIsSpeaking;
var private transient bool bRestartSavedSpeech;
var private transient bool bIsStartingSavedSpeech;
var const int SpeechPriorityRestriction;
var private ShockAI.EAIState AIState;
var private config bool bCanUseAimPoses;
var private name CurrentAimPoseSetup;
var private config name WeaponAimPoseSetupName;
var private config float AimPoseAngleEpsilonDegrees;
var config bool bHasRangedAttack;
var config bool bPrefersRangedAttack;
var private bool bSendMessageOnNextWeaponFire;
var private name WeaponFireMessageWeaponLabel;
var private Class<AIWeapon> WeaponFireMessageWeaponClass;
var config float PlayerUsingTelekinesisReadyToUseMultiplier;
var config Vector MeleeWeaponOffset;
var config bool bShouldUseContinuousRagdoll;
var config bool bShouldGoRagdollOnDeath;
var private name CurrentIdleAnimation;
var private float NextChangeIdleAnimationTime;
var private config float LocomotionTranslationScaleAgainstPlayer;
var private ShockAI.EMovementRate MovementRate;
var config float MinZDifferenceForUsingUnevenSurface;
var const array<NavigationPoint> PointCollection;
var const Vector LastPathfindingOrigin;
var const Actor LastPathfindingActor;
var const Vector LastPathfindingLocation;
var const float LastPathfindingTime;
var const float LastPathfindingFailedTime;
var const float LastPathfindingResult;
var config float CeilingAIExtraCostMultiplierOnWalkNodes;
var config float FlyingAIExtraCostMultiplierOnWalkNodes;
var config float FlyingAIExtraCostMultiplierOnVerticalPaths;
var config float CeilingAIExtraCostMuliplierForPointAboveAttackTarget;
var config float CeilingAIAboveTargetRadius;
var config bool bUseCollisionAvoidance;
var config bool bAvoidFuturePawnCollisions;
var config bool bShouldApplyDisplacement;
var config float CollisionAvoidanceAttackingPushDistance;
var bool bIsAvoiding;
var bool bIsAvoidingToLeft;
var bool bLastAvoidingToLeft;
var Vector AvoidancePoint;
var ShockPawn AvoidingPawn;
var ShockPawn LastAvoidingPawn;
var float AvoidanceStartDistance;
var Vector CurrentDestination;
var const Actor CurrentDestinationActor;
var const Vector FinalDestination;
var Vector WaypointDestination;
var const array<ShockAI> NearbyAIs;
var const float LastTimeNearbyAIsUpdated;
var config float NearbyAIMaxDistance;
var config bool bAvoidNearbyAIsWhilePathing;
var config float MaxDistanceTraveledToAvoidNearbyAIs;
var config bool bCanRunAway;
var const bool bPickRandomPoint;
var const bool bPickPointThatCanAttackTarget;
var private ShockPawn AvoidTarget;
var const float MinDistanceToTarget;
var const float MaxDistanceToTarget;
var const float MinDesiredDistanceToMove;
var const float MaxDesiredDistanceToMove;
var const AIWeapon DesiredWeaponToAttackWith;
var private float MinDistanceToApproachTarget;
var const bool bAvoidDoors;
var const bool bPreferNotVisiblePoints;
var const bool bAvoidSurfaceTransitions;
var const array<Actor> LastPathList;
var bool bAvoidLastPath;
var config float LastPathMultiplier;
var config float MinDistanceToStopNearPlayer;
var ShockPawn MovementAttackTarget;
var private config float TargetBumpDetectionTime;
var config array<name> DodgeAnimations;
var config array<name> MeleeDodgeAnimations;
var config array<name> NonMeleeDodgeAnimations;
var float LastTauntTime;
var float LastResponseTime;
var array<float> BlastTimes;
var array<Vector> BlastForces;
var config bool bPlayAnimationInsteadOfRagdollFall;
var const float LastRagdollCollisionTime;
var private config Range LODRange;
var private Range LODRangeSqr;
var private config float LastRenderedForNormalLODDeltaTime;
var private float NormalAILODOverrideTime;
var private config float DeadRagdollMotorsEaseOutTime;
var private config float DeadAnimationsEaseOutTime;
var private float RagdollDeathSleepTime;
var config Material IncinerateMaterial;
var ShockAI.ETeleportState TeleportState;
var Material TeleportOutTransitionShader;
var Material TeleportInTelegraphShader;
var Material TeleportInTransitionShader;
var config Material TeleportInTelegraphShaderFire;
var config Material TeleportInTransitionShaderFire;
var config Material TeleportOutTransitionShaderFire;
var config Material TeleportInTelegraphShaderIce;
var config Material TeleportInTransitionShaderIce;
var config Material TeleportOutTransitionShaderIce;
var config Material TeleportInTelegraphShaderLightning;
var config Material TeleportInTransitionShaderLightning;
var config Material TeleportOutTransitionShaderLightning;
var config Material AtlasSkinFire;
var config Material AtlasSkinIce;
var config Material AtlasSkinLightning;
var config float DroppedAttachmentLifeSpan;
var config float DroppedAttachmentFadeOutDuration;

function PreLevelSave()
{
	super(Actor).PreLevelSave();
	SaveSpeechInfo();
	return;
	@NULL
	CommanderAction
}

function PostLoadGame()
{
	super(ShockPawn).PostLoadGame();
	bRestartSavedSpeech = true;
	RegisterPhotographTarget();
	return;
	@NULL
	CommanderAction
}

function PreLevelTravel()
{
	super(Actor).PreLevelTravel();
	// End:0x53
	if(IsAlive())
	{
		ClearShocked();
		ClearBurning();
		ClearFrozen();
		ClearBerserk();
		ClearSecurityBeacon();
		RemoveAllOverlays();
		StopSpeechForTravel();
	}
	return;
	@NULL
	CommanderAction
}

function PreBeginPlay()
{
	super(ShockPawn).PreBeginPlay();
	// End:0x31
	if(__NFUN_119__(LootContainer, none))
	{
		LootContainer.SetOwner(self);
		LODRangeSqr.Min = __NFUN_171__(LODRange.Min, LODRange.Min);
	}
	LODRangeSqr.Max = __NFUN_171__(LODRange.Max, LODRange.Max);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function PostBeginPlay()
{
	super.PostBeginPlay();
	Level.SpawningManager.NotifyAISpawned(self);
	dispatchMessage(Class'ShockAI.MessageAISpawned'.static.Allocate(self)., construct_ShockAI(self));
	RegisterPhotographTarget();
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function FellOutOfWorld(Actor.eKillZType KillType)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x82
	/*@Error*/
	super(Pawn).FellOutOfWorld(KillType);
	log('AI', 2, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " fell out of world at "), string(Location)), ", AI will be destroyed!"));
	__NFUN_279__();
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

event OnArchetypeApplied()
{
	return;
}

event AddInitialKeywords()
{
	AddLocomotionKeyword('Locomotion', 0);
	AddRequiredFidgetKeyword('Fidget');
	AddLocomotionKeyword('Ceiling', -1);
	AddLocomotionKeyword('Burning', -1);
	AddLocomotionKeyword('AimingWeapon', -1);
	AddLocomotionKeyword('ReactToEvent', -1);
	AddLocomotionKeyword('ReactToAttack', -1);
	return;
}

function int GetDesiredAnimationCapabilities()
{
	local int capabilities;

	capabilities = __NFUN_158__(4, 256);
	// End:0x36
	if(bShouldUseLocomotion)
	{
		capabilities = __NFUN_158__(capabilities, 1);
		// End:0x5A
		if(bCanUseAimPoses)
		{
			capabilities = __NFUN_158__(capabilities, 2);
		}
		// End:0x7E
		if(bShouldUseFootIKTracker)
		{
			capabilities = __NFUN_158__(capabilities, 128);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0xA2
			/*@Error*/
		}
		capabilities = __NFUN_158__(capabilities, 32);
		return capabilities;
		return;
		@NULL
		CommanderAction
	}
	stop;
	default.@NULL
}

function bool CanRiseFromRagdoll()
{
	return __NFUN_155__(__NFUN_156__(GetDesiredAnimationCapabilities(), 64), 0);
	return;
}

function SetLODRange(float Min, float Max)
{
	assert(__NFUN_176__(Min, Max));
	LODRange.Min = Min;
	LODRange.Max = Max;
	LODRangeSqr.Min = __NFUN_171__(Min, Min);
	LODRangeSqr.Max = __NFUN_171__(Max, Max);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function SetNormalAILODOverrideTime(float inNormalAILODOverrideTime)
{
	NormalAILODOverrideTime = inNormalAILODOverrideTime;
	return;
	@NULL
	CommanderAction
}

function Destroyed()
{
	log('AI', 3, __NFUN_112__(string(Name), " is being destroyed."));
	DestroyCommander();
	UnregisterPhotographTarget();
	super(ShockPawn).Destroyed();
	// End:0x8C
	if(bConsiderAsBootyForGatherersWhenDead)
	{
		SpawningManager(Level.SpawningManager).RemoveBooty(self);
		DestroyWeapons();
		DestroyAttachments();
		DestroyManagedAIObjects();
	}
	StopAllSpeech();
	Class'ShockGame.CrossbowProjectile'.static.DetachAnyCrossbowBoltsFromActor(self);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function ZoneChange(ZoneInfo NewZone)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x44
	/*@Error*/
	SpawningManager(Level.SpawningManager).UpdateBootyZone(self, NewZone);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

// Export UShockAI::execDestroyManagedAIObjects(FFrame&, void* const)
native function DestroyManagedAIObjects();

function DestroyAttachments()
{
	local int i;
	local AIAttachment Attachment;

	i = __NFUN_147__(Attached.Length, 1);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x79
	/*@Error*/
	Attachment = AIAttachment(Attached[i]);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6B
	/*@Error*/
	Attachment.__NFUN_279__();
	__NFUN_164__(i);
	// [Loop Continue]
	goto J0x17;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function DestroyWeapons()
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4B
	/*@Error*/
	Holdables[i].__NFUN_279__();
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function DestroyCommander()
{
	// End:0x41
	if(__NFUN_119__(Commander, none))
	{
		Commander.unPostGoal(none);
		Commander.__NFUN_198__();
		Commander = none;
		return;
		@NULL
		CommanderAction
		EcologyFighterCommanderAction
	}
	@NULL
}

function Touch(Actor Other)
{
	local ShockAI OtherAI;

	super(Actor).Touch(Other);
	OtherAI = ShockAI(Other);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x8D
	/*@Error*/
	LastBumpedPawn = OtherAI;
	LastBumpedTime = Level.TimeSeconds;
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function bool EncroachingOn(Actor Other)
{
	// End:0x1D
	if(__NFUN_119__(ShockAI(Other), none))
	{
		return false;
		goto J0x31;
		return super(Pawn).EncroachingOn(Other);
	}
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function HandleAIEventNotification(AIEventNotification Event)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x52
	/*@Error*/
	CommanderAction(Commander.achievingAction).HandleAIEventNotification(Event);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function HandleAIAttackNotification(Actor Attacker, float InitiateDamageDelay, DamageStimuliSet.EDamageType DamageType)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x64
	/*@Error*/
	CommanderAction(Commander.achievingAction).HandleAIAttackNotification(Attacker, InitiateDamageDelay, DamageType);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function CharacterAICreated()
{
	super(VPawn).CharacterAICreated();
	CharacterAI.addAbility_Class(Class'ShockAI.WaitAction');
	CharacterAI.addAbility_Class(Class'ShockAI.DodgeAction');
	// End:0x77
	if(CanRiseFromRagdoll())
	{
		CharacterAI.addAbility_Class(Class'ShockAI.FallDownReactionAction');
		CharacterAI.addSensorActionClass(Class'ShockAI.DistanceTraveledSensorAction');
		CharacterAI.addAbility_Class(Class'ShockAI.EscapeFromRepellantAction');
	}
	SetupCommanderGoal();
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function SetupCommanderGoal()
{
	AddCommanderAbility();
	Commander = Class'ShockAI.CommanderGoal'.static.Allocate(self).;
	construct_AI_Resource(CharacterAI);
	assert(__NFUN_119__(Commander, none));
	Commander.__NFUN_199__();
	Commander.postGoal(none);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

protected function AddCommanderAbility()
{
	return;
}

function MovementAICreated()
{
	super(VPawn).MovementAICreated();
	MovementAI.addAbility_Class(Class'VengeanceShared.AI_DummyMovement');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function WeaponAICreated()
{
	super(VPawn).WeaponAICreated();
	WeaponAI.addAbility_Class(Class'VengeanceShared.AI_DummyWeapon');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function PostEscapeFromRepellantGoal()
{
	local EscapeFromRepellantGoal escapeGoal;

	escapeGoal = Class'ShockAI.EscapeFromRepellantGoal'.static.Allocate(self).;
	construct_AI_Resource(CharacterAI);
	escapeGoal.postGoal(Commander.achievingAction);
	return;
	@NULL
	CommanderAction
	stop;
	stop;
	@NULL
}

// Export UShockAI::execToggleOptimizedPhysics(FFrame&, void* const)
native function ToggleOptimizedPhysics();

// Export UShockAI::execEnableAI(FFrame&, void* const)
native function EnableAI();

// Export UShockAI::execDisableAI(FFrame&, void* const)
native function DisableAI();

function ScriptedAttackTarget(ShockPawn Target)
{
	AssertWithDescription(__NFUN_119__(Target, none), "ShockAI::ScriptedAttackTarget - Target passed in is none!");
	// End:0x92
	if(__NFUN_130__(IsAlive(), __NFUN_119__(Commander, none)))
	{
		Commander.ScriptedAttackTarget(Target);
		goto J0x122;
		log('AI', 2, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " ScriptedAttackTarget - told to attack "), string(Target.Name)), ", but we are dead or don't have a commander!"));
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function AddTargetToAttackOnSight(name TargetLabel)
{
	log('AI', 2, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " AddTargetToAttackOnSight - not implemented for this AI, and won't attack "), string(TargetLabel)), " on sight."));
	return;
	@NULL
	CommanderAction
}

function ScriptedWait()
{
	// End:0x38
	if(__NFUN_130__(IsAlive(), __NFUN_119__(Commander, none)))
	{
		Commander.ScriptedWait();
		goto J0xA7;
		log('AI', 2, __NFUN_112__(string(Name), " ScriptedAttackTarget - told to wait, but we are dead or don't have a commander!"));
	}
	return;
	@NULL
	CommanderAction
	J0xA7:

	CommanderAction
}

function ScriptedContinue()
{
	// End:0x38
	if(__NFUN_130__(IsAlive(), __NFUN_119__(Commander, none)))
	{
		Commander.ScriptedContinue();
		goto J0xAB;
		log('AI', 2, __NFUN_112__(string(Name), " ScriptedAttackTarget - told to continue, but we are dead or don't have a commander!"));
	}
	return;
	@NULL
	CommanderAction
	J0xAB:

	CommanderAction
}

function FadeOutAndDestroy(float TimeToFadeOut)
{
	local AIAttachment Attachment;
	local int i;

	FadeOutDuration = TimeToFadeOut;
	LifeSpan = TimeToFadeOut;
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xAC
	/*@Error*/
	Attachment = AIAttachment(Attached[i]);
	// End:0x9E
	if(__NFUN_119__(Attachment, none))
	{
		Attachment.FadeOutDuration = TimeToFadeOut;
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x31;
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xF0
		/*@Error*/
		FadeOutDuration = TimeToFadeOut;
		__NFUN_163__(i);
		goto J0xB7;
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

function PlaySpeech(name SpeechEventName)
{
	//native.SpeechEventName;	
	@NULL
}

function StopSpeech(name SpeechEventName, optional bool bOnlyStopSpeechIfItsNotPlaying, optional bool bRemoveFromQueue)
{
	//native.SpeechEventName;
	//native.bOnlyStopSpeechIfItsNotPlaying;
	//native.bRemoveFromQueue;	
	@NULL
	@NULL
	return default.@NULL;
}

// Export UShockAI::execStopAllSpeech(FFrame&, void* const)
native function StopAllSpeech();

function SetSpeechPriorityRestriction(int inSpeechPriorityRestriction)
{
	//native.inSpeechPriorityRestriction;	
	@NULL
}

function MuteAI(bool bShouldMuteAI, optional bool bDontStopCurrentSpeech)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x5E
	/*@Error*/
	bIsMute = true;
	// End:0x5B
	if(__NFUN_130__(__NFUN_129__(bDontStopCurrentSpeech), __NFUN_119__(CurrentSound, none)))
	{
		CurrentSound.Stop();
		CurrentSound = none;
		goto J0x6A;
		bIsMute = false;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

private final function float HealthPercentage()
{
	return __NFUN_172__(GetHealth(), GetMaxHealth());
	return;
}

// Export UShockAI::execSaveSpeechInfo(FFrame&, void* const)
native final function SaveSpeechInfo();

// Export UShockAI::execStopSpeechForTravel(FFrame&, void* const)
native final function StopSpeechForTravel();

// Export UShockAI::execRestartSpeechFromSave(FFrame&, void* const)
native final function RestartSpeechFromSave();

function OnEffectStarted(Actor inStartedEffect)
{
	//native.inStartedEffect;	
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
	//native.inStoppedEffect;
	//native.Completed;	
	@NULL
	@NULL
}

function OnEffectInitialized(Actor inInitializedEffect)
{
	//native.inInitializedEffect;	
	@NULL
}

function SetupVisionCones()
{
	local int i;

	// End:0xB3
	if(__NFUN_154__(NormalVisionCones.Length, 0))
	{
		PeripheralVision = __NFUN_188__(__NFUN_171__(0.0174533, FOV));
		SightRadius = ViewDistance;
		log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " SetupVisionCone - Peripheral Vision: "), string(PeripheralVision)), " SightRadius: "), string(SightRadius)));
		goto J0x485;
		bUsingComplexVision = true;
		i = 0;
		// End:0x149
		if(__NFUN_150__(i, NormalVisionCones.Length))
		{
			NormalVisionCones[i].PeripheralVision = __NFUN_188__(__NFUN_172__(__NFUN_171__(0.0174533, NormalVisionCones[i].FOV), 2.0000000));
		}
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0xCA;
		i = 0;
		// End:0x1D3
		if(__NFUN_150__(i, SearchingVisionCones.Length))
		{
			SearchingVisionCones[i].PeripheralVision = __NFUN_188__(__NFUN_172__(__NFUN_171__(0.0174533, SearchingVisionCones[i].FOV), 2.0000000));
			__NFUN_163__(i);
		}
		goto J0x154;
		i = 0;
		// End:0x25D
		if(__NFUN_150__(i, AttackingVisionCones.Length))
		{
			AttackingVisionCones[i].PeripheralVision = __NFUN_188__(__NFUN_172__(__NFUN_171__(0.0174533, AttackingVisionCones[i].FOV), 2.0000000));
			__NFUN_163__(i);
			goto J0x1DE;
			i = 0;
			// End:0x2E7
			if(__NFUN_150__(i, CeilingVisionCones.Length))
			{
				CeilingVisionCones[i].PeripheralVision = __NFUN_188__(__NFUN_172__(__NFUN_171__(0.0174533, CeilingVisionCones[i].FOV), 2.0000000));
			}
			__NFUN_163__(i);
			goto J0x268;
			i = 0;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x371
			/*@Error*/
			MimicVisionCones[i].PeripheralVision = __NFUN_188__(__NFUN_172__(__NFUN_171__(0.0174533, MimicVisionCones[i].FOV), 2.0000000));
			__NFUN_163__(i);
			// [Explicit Continue]
			goto J0x2F2;
		}
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x3FB
		/*@Error*/
		BerserkVisionCones[i].PeripheralVision = __NFUN_188__(__NFUN_172__(__NFUN_171__(0.0174533, BerserkVisionCones[i].FOV), 2.0000000));
		__NFUN_163__(i);
		goto J0x37C;
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x485
		/*@Error*/
		PatrolVisionCones[i].PeripheralVision = __NFUN_188__(__NFUN_172__(__NFUN_171__(0.0174533, PatrolVisionCones[i].FOV), 2.0000000));
	}
	__NFUN_163__(i);
	goto J0x406;
	return;
	@NULL
	CommanderAction
	stop;
	return @NULL;
}

function NotifyCeilingVisionDesired()
{
	__NFUN_163__(CeilingVisionDesiredCount);
	OnVisionContextChanged();
	return;
	@NULL
}

function NotifyCeilingVisionNoLongerDesired()
{
	__NFUN_164__(CeilingVisionDesiredCount);
	CeilingVisionDesiredCount = __NFUN_250__(CeilingVisionDesiredCount, 0);
	OnVisionContextChanged();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function NotifyAttackingVisionDesired()
{
	__NFUN_163__(AttackingVisionDesiredCount);
	OnVisionContextChanged();
	return;
	@NULL
}

function NotifyAttackingVisionNoLongerDesired()
{
	__NFUN_164__(AttackingVisionDesiredCount);
	AttackingVisionDesiredCount = __NFUN_250__(AttackingVisionDesiredCount, 0);
	OnVisionContextChanged();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function NotifySearchingVisionDesired()
{
	__NFUN_163__(SearchingVisionDesiredCount);
	OnVisionContextChanged();
	return;
	@NULL
}

function NotifySearchingVisionNoLongerDesired()
{
	__NFUN_164__(SearchingVisionDesiredCount);
	SearchingVisionDesiredCount = __NFUN_250__(SearchingVisionDesiredCount, 0);
	OnVisionContextChanged();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function NotifyMimicVisionDesired()
{
	__NFUN_163__(MimicVisionDesiredCount);
	OnVisionContextChanged();
	return;
	@NULL
}

function NotifyMimicVisionNoLongerDesired()
{
	__NFUN_164__(MimicVisionDesiredCount);
	MimicVisionDesiredCount = __NFUN_250__(MimicVisionDesiredCount, 0);
	OnVisionContextChanged();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function NotifyBerserkVisionDesired()
{
	__NFUN_163__(BerserkVisionDesiredCount);
	OnVisionContextChanged();
	return;
	@NULL
}

function NotifyBerserkVisionNoLongerDesired()
{
	__NFUN_164__(BerserkVisionDesiredCount);
	BerserkVisionDesiredCount = __NFUN_250__(BerserkVisionDesiredCount, 0);
	OnVisionContextChanged();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function NotifyPatrolVisionDesired()
{
	__NFUN_163__(PatrolVisionDesiredCount);
	OnVisionContextChanged();
	return;
	@NULL
}

function NotifyPatrolVisionNoLongerDesired()
{
	__NFUN_164__(PatrolVisionDesiredCount);
	PatrolVisionDesiredCount = __NFUN_250__(BerserkVisionDesiredCount, 0);
	OnVisionContextChanged();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function OnVisionContextChanged()
{
	log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " OnVisionContextChanged - CeilingVisionDesiredCount: "), string(CeilingVisionDesiredCount)), " AttackingVisionDesiredCount: "), string(AttackingVisionDesiredCount)), " SearchingVisionDesiredCount: "), string(SearchingVisionDesiredCount)), " MimicVisionDesiredCount: "), string(MimicVisionDesiredCount)), " BerserkVisionDesiredCount: "), string(BerserkVisionDesiredCount)));
	// End:0x135
	if(__NFUN_151__(BerserkVisionDesiredCount, 0))
	{
		VisionState = 5;
		goto J0x1D7;
		// End:0x153
		if(__NFUN_151__(CeilingVisionDesiredCount, 0))
		{
			VisionState = 3;
			goto J0x1D7;
			// End:0x171
			if(__NFUN_151__(AttackingVisionDesiredCount, 0))
			{
			}
			VisionState = 2;
			goto J0x1D7;
			// End:0x18F
			if(__NFUN_151__(SearchingVisionDesiredCount, 0))
			{
				VisionState = 1;
			}
			goto J0x1D7;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x1AD
			/*@Error*/
			VisionState = 4;
			goto J0x1D7;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x1CB
			/*@Error*/
		}
		VisionState = 6;
		goto J0x1D7;
		VisionState = 0;
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

function SetPlayerVisionState(bool inShouldSeePlayer)
{
	log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " SetPlayerVisionState - bShouldSeePlayer: "), string(bShouldSeePlayer)), " inShouldSeePlayer: "), string(inShouldSeePlayer)));
	bShouldSeePlayer = inShouldSeePlayer;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function SetAlwaysSeePlayer(bool inAlwaysSeePlayer)
{
	log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " SetAlwaysSeePlayer - bAlwaysSeePlayer: "), string(bAlwaysSeePlayer)), " inAlwaysSeePlayer: "), string(inAlwaysSeePlayer)));
	bAlwaysSeePlayer = inAlwaysSeePlayer;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool ShouldSeePawn(Pawn Target)
{
	//native.Target;	
	@NULL
}

function Notify(name GroupName, bool wasRemoved, name modName)
{
	super(ShockPawn).Notify(GroupName, wasRemoved, modName);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool IsUsableAsBooty(Gatherer TestGatherer)
{
	return __NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_130__(bConsiderAsBootyForGatherersWhenDead, __NFUN_129__(IsAlive())), __NFUN_119__(BootyImpl, none)), BootyImpl.IsCurrentlyUsable(TestGatherer)), __NFUN_180__(LifeSpan, 0.0000000));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NavigationPoint GetClosestNavigationPoint()
{
	return GetAnchor();
	return;
}

function bool GetBestGatherPoint(out Vector BestGatherPoint, out Vector BestGatherPointRigidBodyLocation, out int RigidBodyIndex)
{
	assert(__NFUN_119__(BootyImpl, none));
	return BootyImpl.GetBestGatherPoint(BestGatherPoint, BestGatherPointRigidBodyLocation, RigidBodyIndex);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Vector GetUpdatedRigidBodyLocation(int RigidBodyIndex)
{
	assert(__NFUN_119__(BootyImpl, none));
	return BootyImpl.GetUpdatedRigidBodyLocation(RigidBodyIndex);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function Vector GetUpdatedGatherPointLocation(int RigidBodyIndex)
{
	assert(__NFUN_119__(BootyImpl, none));
	return BootyImpl.GetUpdatedGatherPointLocation(RigidBodyIndex);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function ClaimBooty(Gatherer inGatherer)
{
	assert(__NFUN_119__(BootyImpl, none));
	__NFUN_163__(DelayCorpseRemoval);
	assert(__NFUN_180__(LifeSpan, 0.0000000));
	BootyImpl.ClaimBooty(inGatherer);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function RelinquishBooty(Gatherer inGatherer)
{
	__NFUN_164__(DelayCorpseRemoval);
	// End:0x3D
	if(__NFUN_119__(BootyImpl, none))
	{
		BootyImpl.RelinquishBooty(inGatherer);
		goto J0xC6;
		AssertWithDescription(__NFUN_242__(bDeleteMe, true), __NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " RelinquishBooty from "), string(inGatherer)), " was called but no BootyImpl exists.  Ask crombie about this"));
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyBeganGathering()
{
	assert(__NFUN_119__(BootyImpl, none));
	BootyImpl.NotifyBeganGathering();
	return;
	@NULL
	CommanderAction
}

function NotifyEndedGathering()
{
	assert(__NFUN_119__(BootyImpl, none));
	BootyImpl.NotifyEndedGathering();
	return;
	@NULL
	CommanderAction
}

protected event CreateWeapons()
{
	return;
}

function AIWeapon CreateAIWeapon(Class<AIWeapon> weaponClass)
{
	local AIWeapon Weapon;
	local name WeaponLabel;
	local int i;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x183
	/*@Error*/
	WeaponLabel = string(__NFUN_112__(string(Label), string(weaponClass.Name)));
	log('AI', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("WeaponLabel for ", string(Name)), "'s "), string(weaponClass.Name)), " is: "), string(WeaponLabel)));
	Weapon = __NFUN_278__(weaponClass, self,,,,, WeaponLabel);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x183
	/*@Error*/
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x183
	/*@Error*/
	AddLocomotionKeyword(Weapon.WeaponHolderAnimationKeywords[i].keyword, Weapon.WeaponHolderAnimationKeywords[i].KeywordPriority);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0xE4;
	return Weapon;
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function OnWeaponsCreated()
{
	local int i;
	local AIWeapon WeaponIter;

	SetupWeaponAimPoses();
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x87
	/*@Error*/
	WeaponIter = AIWeapon(Holdables[i]);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x79
	/*@Error*/
	WeaponIter.SetupAttackInfos();
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x15;
	return;
	@NULL
	EcologyCommanderAction
	stop;
	return @NULL;
}

// Export UShockAI::execHasRangedAttack(FFrame&, void* const)
native function bool HasRangedAttack();

// Export UShockAI::execPrefersRangedAttack(FFrame&, void* const)
native function bool PrefersRangedAttack();

function Vector GetSocketOffsetInAnimation(name SocketName, name AnimationName, name BaseAnimationName, float TimeInAnimation)
{
	//native.SocketName;
	//native.AnimationName;
	//native.BaseAnimationName;
	//native.TimeInAnimation;	
	@NULL
	@NULL
	return default.@NULL;
}

function BeginFiring(optional bool inAltFire)
{
	local Weapon Weapon;

	log('Weapons', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), " is trying to Begin Firing "), string(ActiveHoldable)), " IsBusy: "), string(IsBusy())));
	Weapon = Weapon(ActiveHoldable);
	// End:0x9C
	if(__NFUN_119__(Weapon, none))
	{
		Weapon.BeginFiring();
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x165
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x165
		/*@Error*/
	}
	dispatchMessage(Class'ShockAI.MessageAIWeaponFired'.static.Allocate(self)., construct_ShockAIWeapon(self, Weapon));
	bSendMessageOnNextWeaponFire = false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function StopAnyWeaponAction()
{
	local Weapon CurrentWeapon;

	CurrentWeapon = Weapon(GetActiveHoldable());
	// End:0x43
	if(__NFUN_119__(CurrentWeapon, none))
	{
		CurrentWeapon.InterruptCurrentAction();
		StopWeaponFire();
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

function StopWeaponFire()
{
	CeaseFiring(false, true);
	return;
}

function SetWeaponFireMessage(name inWeaponFireMessageWeaponLabel, Class<AIWeapon> inWeaponFireMessageWeaponClass)
{
	bSendMessageOnNextWeaponFire = true;
	WeaponFireMessageWeaponLabel = inWeaponFireMessageWeaponLabel;
	WeaponFireMessageWeaponClass = inWeaponFireMessageWeaponClass;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Vector GetWeaponAimPoseOriginOffset()
{
	local AimPoseTargetTracker AimPoseTargetTracker;

	AimPoseTargetTracker = GetAimPoseTargetTracker();
	assert(__NFUN_119__(AimPoseTargetTracker, none));
	return AimPoseTargetTracker.GetOwnerOriginOffset();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

// Export UShockAI::execCanAimWeapon(FFrame&, void* const)
native function bool CanAimWeapon();

function AimWeaponAtTarget(Actor Target)
{
	//native.Target;	
	@NULL
}

// Export UShockAI::execStopAimingWeapon(FFrame&, void* const)
native function StopAimingWeapon();

// Export UShockAI::execIsWeaponLockedOnTarget(FFrame&, void* const)
native function bool IsWeaponLockedOnTarget();

function bool IsWeaponTargetWithinTrackingArea(Actor Target)
{
	//native.Target;	
	@NULL
}

// Export UShockAI::execIsAimingWeapon(FFrame&, void* const)
native function bool IsAimingWeapon();

function SetupWeaponAimPoses()
{
	local AimPoseTargetTracker AimPoseTargetTracker;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x63
	/*@Error*/
	AimPoseTargetTracker = GetAimPoseTargetTracker();
	assert(__NFUN_119__(AimPoseTargetTracker, none));
	AimPoseTargetTracker.ApplyAimPoseSetup(WeaponAimPoseSetupName);
	CurrentAimPoseSetup = WeaponAimPoseSetupName;
	return;
	@NULL
	CommanderAction
	stop;
	return @NULL;
}

function bool IsHeadTrackingTargetWithinTrackingArea(Actor Target)
{
	local HeadTargetTracker HeadTargetTracker;

	HeadTargetTracker = GetHeadTargetTracker();
	assert(__NFUN_119__(HeadTargetTracker, none));
	return HeadTargetTracker.IsTargetWithinTrackingAreaWS(Target);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function FreezeAiming()
{
	local AimPoseTargetTracker AimPoseTargetTracker;

	AimPoseTargetTracker = GetAimPoseTargetTracker();
	// End:0x3A
	if(__NFUN_119__(AimPoseTargetTracker, none))
	{
		AimPoseTargetTracker.Freeze();
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function UnfreezeAiming()
{
	local AimPoseTargetTracker AimPoseTargetTracker;

	AimPoseTargetTracker = GetAimPoseTargetTracker();
	// End:0x3A
	if(__NFUN_119__(AimPoseTargetTracker, none))
	{
		AimPoseTargetTracker.Unfreeze();
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function FreezeHeadTracking()
{
	local HeadTargetTracker HeadTargetTracker;

	HeadTargetTracker = GetHeadTargetTracker();
	// End:0x3A
	if(__NFUN_119__(HeadTargetTracker, none))
	{
		HeadTargetTracker.Freeze();
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function UnfreezeHeadTracking()
{
	local HeadTargetTracker HeadTargetTracker;

	HeadTargetTracker = GetHeadTargetTracker();
	// End:0x3A
	if(__NFUN_119__(HeadTargetTracker, none))
	{
		HeadTargetTracker.Unfreeze();
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function Rotator GetAimPoseRangeCenterToTarget(Actor Target)
{
	//native.Target;	
	@NULL
}

function QuickLook(Actor Target, optional float Duration, optional Vector Offset)
{
	CommanderAction(Commander.achievingAction).QuickLook(Target, Duration, Offset);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function CasualLook(Actor Target, optional float Duration, optional Vector Offset)
{
	CommanderAction(Commander.achievingAction).CasualLook(Target, Duration, Offset);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function StopTracking()
{
	CommanderAction(Commander.achievingAction).StopTracking();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function bool IsTracking()
{
	return CommanderAction(Commander.achievingAction).IsTracking();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function bool DisallowHeadTracking()
{
	return __NFUN_155__(int(Physics), int(2));
	return;
	@NULL
}

function bool GetDefaultEventReactionSpecifier(out EventReactionSpecifier Specifier, AIEventNotification.EAIEventNotificationType EventType)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x97
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x89
	/*@Error*/
	Specifier = DefaultEventReactions[i].Reaction;
	return true;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool GetEventReactionOverrideSpecifier(out EventReactionSpecifier Specifier, AIEventNotification.EAIEventNotificationType EventType)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x97
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x89
	/*@Error*/
	Specifier = EventReactionOverrides[i].Reaction;
	return true;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return false;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function EventReactionSpecifier GetEventReactionSpecifier(AIEventNotification.EAIEventNotificationType EventType)
{
	local EventReactionSpecifier Specifier;

	// End:0x3D
	if(__NFUN_129__(GetEventReactionOverrideSpecifier(Specifier, EventType)))
	{
		GetDefaultEventReactionSpecifier(Specifier, EventType);
		return Specifier;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
	@NULL
}

// Export UShockAI::execIsTeleporting(FFrame&, void* const)
native function bool IsTeleporting();

// Export UShockAI::execIsIntangible(FFrame&, void* const)
native function bool IsIntangible();

// Export UShockAI::execIsTeleportingIn(FFrame&, void* const)
native function bool IsTeleportingIn();

// Export UShockAI::execIsTeleportingOut(FFrame&, void* const)
native function bool IsTeleportingOut();

function SetInitialAIState()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x1E
	/*@Error*/
	BecomePassive();
	return;
	@NULL
}

// Export UShockAI::execIsAggressive(FFrame&, void* const)
native function bool IsAggressive();

function BecomeAggressive()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xEA
	/*@Error*/
	log('AI', 3, __NFUN_112__(__NFUN_112__(string(Name), " will become aggressive - former state: "), string(GetEnum(Enum'ShockAI.ShockAI.EAIState', int(AIState)))));
	AIState = 2;
	RemoveLocomotionKeyword('Passive');
	AddLocomotionKeyword('Aggressive', 0);
	ResetIdling();
	OnBecameAggressive();
	UnTriggerEffectEvent('Passive');
	TriggerEffectEvent('Aggressive');
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnBecameAggressive()
{
	return;
}

// Export UShockAI::execIsPassive(FFrame&, void* const)
native function bool IsPassive();

function BecomePassive()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xE7
	/*@Error*/
	log('AI', 3, __NFUN_112__(__NFUN_112__(string(Name), " will become passive - former state: "), string(GetEnum(Enum'ShockAI.ShockAI.EAIState', int(AIState)))));
	AIState = 1;
	RemoveLocomotionKeyword('Aggressive');
	AddLocomotionKeyword('Passive', 0);
	ResetIdling();
	OnBecamePassive();
	UnTriggerEffectEvent('Aggressive');
	TriggerEffectEvent('Passive');
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnBecamePassive()
{
	return;
}

function StartAttackedByInsectSwarmBehavior()
{
	CommanderAction(Commander.achievingAction).StartAttackedByInsectSwarmBehavior();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function StopAttackedByInsectSwarmBehavior()
{
	CommanderAction(Commander.achievingAction).StopAttackedByInsectSwarmBehavior();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function bool IsBeingAttackedByInsectSwarm()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x5B
	/*@Error*/
	return CommanderAction(Commander.achievingAction).IsBeingAttackedByInsectSwarm();
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ResetIdling()
{
	NextChangeIdleAnimationTime = Level.TimeSeconds;
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function AddLocomotionKeyword(name keyword, int KeywordPriority)
{
	//native.keyword;
	//native.KeywordPriority;	
	@NULL
	@NULL
}

function RemoveLocomotionKeyword(name keyword)
{
	//native.keyword;	
	@NULL
}

function AddRequiredFidgetKeyword(name keyword)
{
	//native.keyword;	
	@NULL
}

function bool KeywordSearchOnBone(int BoneIdx, name keyword, float InfluenceThreshold)
{
	//native.BoneIdx;
	//native.keyword;
	//native.InfluenceThreshold;	
	@NULL
	@NULL
	return default.@NULL;
}

function SetLocomotionResumeAlignmentThreshold(float Threshold)
{
	//native.Threshold;	
	@NULL
}

// Export UShockAI::execGetLocomotionResumeAlignmentThreshold(FFrame&, void* const)
native function float GetLocomotionResumeAlignmentThreshold();

// Export UShockAI::execGetDefaultLocomotionResumeAlignmentThreshold(FFrame&, void* const)
native function float GetDefaultLocomotionResumeAlignmentThreshold();

function NotifyPlayingScriptedLoopingAnimation(int LoopingAnimationHandle)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x34
	/*@Error*/
	ScriptedLoopingAnimationHandles[ScriptedLoopingAnimationHandles.Length] = LoopingAnimationHandle;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function StopAnyScriptedLoopingAnimations()
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6E
	/*@Error*/
	// End:0x60
	if(IsAnimationHandleValid(ScriptedLoopingAnimationHandles[i]))
	{
		SmartPerTrackEaseOutAnimation(ScriptedLoopingAnimationHandles[i]);
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x0B;
		ScriptedLoopingAnimationHandles.Remove(0, ScriptedLoopingAnimationHandles.Length);
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function SetMotionModifier_MeleeAttack(int Handle, int EndYawTwoByteWS)
{
	//native.Handle;
	//native.EndYawTwoByteWS;	
	@NULL
	@NULL
}

function OnSpecialPushPlayer(ShockPlayer Player)
{
	return;
}

// Export UShockAI::execIsUsingLowDetailMovement(FFrame&, void* const)
native function bool IsUsingLowDetailMovement();

// Export UShockAI::execSetShouldRun(FFrame&, void* const)
native function SetShouldRun();

// Export UShockAI::execSetShouldWalk(FFrame&, void* const)
native function SetShouldWalk();

function bool CanTeleport()
{
	return bCanTeleport;
	return;
	@NULL
}

// Export UShockAI::execIsOnSlope(FFrame&, void* const)
native function bool IsOnSlope();

function bool AreAIsOnLevelSurface(Pawn A, Pawn B, Vector ATestStartLocation, Vector BTestStartLocation)
{
	//native.A;
	//native.B;
	//native.ATestStartLocation;
	//native.BTestStartLocation;	
	@NULL
	@NULL
	2
	@NULL
}

function bool GetPointToApproachTarget(out Vector Point, Actor Target, float DesiredDistance)
{
	//native.Point;
	//native.Target;
	//native.DesiredDistance;	
	@NULL
	@NULL
	return default.@NULL;
}

function bool ApplyDeadPenalty()
{
	return __NFUN_130__(__NFUN_129__(IsAlive()), __NFUN_254__(DeadPhotoLabel, 'None'));
	return;
	@NULL
}

function name GetPhotographLabel()
{
	// End:0x35
	if(__NFUN_130__(__NFUN_129__(IsAlive()), __NFUN_255__(DeadPhotoLabel, 'None')))
	{
		return DeadPhotoLabel;
		goto J0x3F;
		return ResearchTrack;
		return;
	}
	@NULL
	CommanderAction
	J0x3F:

	CommanderAction
}

function SetAnimationPhotoScore(int Score)
{
	CurrentAnimationPhotoScore = Score;
	return;
	@NULL
	CommanderAction
}

function int GetAnimationPhotoScore()
{
	return CurrentAnimationPhotoScore;
	return;
	@NULL
}

function int PhotographedCount()
{
	return PhotoTakenCount;
	return;
	@NULL
}

function OnPhotoTaken()
{
	__NFUN_163__(PhotoTakenCount);
	return;
	@NULL
}

function RegisterPhotographTarget()
{
	log(,, __NFUN_112__("Registering photograph target with name ", string(self.Name)));
	ShockGameInfo(Level.Game).RegisterPhotographTarget(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function UnregisterPhotographTarget()
{
	log(,, __NFUN_112__("Unregistering photograph target with name ", string(self.Name)));
	ShockGameInfo(Level.Game).UnregisterPhotographTarget(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Container GetContainer()
{
	return LootContainer;
	return;
	@NULL
}

function IPotentialAimOrActionTarget.TargetType GetTargetType()
{
	// End:0x13
	if(IsAlive())
	{
		return 2;		
	}
	else
	{
		// End:0x26
		if(CanBeUsedNow())
		{
			return 1;			
		}
		else
		{
			return 0;
		}
	}
	return;
}

function bool ShouldBeHarvested()
{
	return bShouldBeHarvested;
	return;
	@NULL
}

function bool CanBeUsedNow()
{
	local ShockPlayer thePlayer;

	thePlayer = ShockPlayer(Level.GetLocalPlayerController().Pawn);
	return __NFUN_130__(__NFUN_129__(IsAlive()), __NFUN_132__(ShouldPlayerCollectCrossbowBolts(), __NFUN_130__(thePlayer.CanUseContainer(LootContainer), __NFUN_132__(__NFUN_129__(ShouldBeHarvested()), __NFUN_130__(thePlayer.CanHarvestAdam(), __NFUN_176__(GetCurrentHarvestAmount(none), GetMaxHarvestAmount(none)))))));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool GetRequiredPlacementForUse(out Vector WorldSpaceLocation, out Rotator WorldSpaceRotation)
{
	return false;
	return;
}

function OnUsed(Pawn Pawn)
{
	AssertWithDescription(Pawn.__NFUN_303__('ShockPlayer'), __NFUN_112__(string(Class.Name), " was used by someone other than a ShockPlayer."));
	// End:0xB4
	if(ShouldPlayerCollectCrossbowBolts())
	{
		CollectAllPossibleCrossbowBolts();
		ShockPlayerController(Pawn.Controller).ResetFocii();
		goto J0x119;
		// End:0xE5
		if(ShouldBeHarvested())
		{
			ShockPlayer(Pawn).BeginHarvestingAdam(self);
		}
		goto J0x119;
		ShockPlayer(Pawn).OpenContainer(GetContainer(), GetCurrentMaterial());
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnUseStopped(Pawn Pawn)
{
	return;
}

function string GetUseVerbText()
{
	// End:0x17
	if(ShouldPlayerCollectCrossbowBolts())
	{
		return CollectCrossbowsVerbText;
		return UseVerbText;
	}
	return;
	@NULL
	CommanderAction
}

function bool ShouldPlayerCollectCrossbowBolts()
{
	local int i;
	local Class<Item> ItemClass;
	local ShockPlayer thePlayer;

	thePlayer = ShockPlayer(Level.GetLocalPlayerController().Pawn);
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x129
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x11B
	/*@Error*/
	ItemClass = CrossbowProjectile(Attached[i]).GetItemStack().ItemClass;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x11B
	/*@Error*/
	return true;
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x42;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function CollectAllPossibleCrossbowBolts()
{
	local int i;
	local Class<Item> ItemClass;
	local ShockPlayer thePlayer;

	thePlayer = ShockPlayer(Level.GetLocalPlayerController().Pawn);
	i = __NFUN_147__(Attached.Length, 1);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x185
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x177
	/*@Error*/
	ItemClass = CrossbowProjectile(Attached[i]).GetItemStack().ItemClass;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x177
	/*@Error*/
	thePlayer.AddStackToInventory(CrossbowProjectile(Attached[i]).GetItemStack());
	Attached[i].__NFUN_279__();
	__NFUN_166__(i);
	// [Loop Continue]
	goto J0x4E;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnNeedleInserted(Hands Hands)
{
	return;
}

function OnNeedleRemoved(Hands Hands)
{
	return;
}

function OnHarvestingStarted(Hands Hands)
{
	return;
}

function OnHarvestingFinished(Hands Hands)
{
	return;
}

function float GetHarvestingTime(Hands Hands)
{
	return Hands.HarvestingAdamCollectionTime;
	return;
	@NULL
	CommanderAction
}

function float GetCurrentHarvestAmount(Hands Hands)
{
	return CurrentHarvestAmount;
	return;
	@NULL
}

function float GetMaxHarvestAmount(Hands Hands)
{
	local ItemStack theStack;

	// End:0x1B
	if(__NFUN_177__(MaxHarvestAmount, float(0)))
	{
		return MaxHarvestAmount;
		// End:0x57
		if(__NFUN_129__(LootContainer.HasEverBeenRolled()))
		{
		}
		LootContainer.RollLoot(Level);
		theStack = LootContainer.GetItem(0);
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xD0
	/*@Error*/
	MaxHarvestAmount = float(theStack.StackSize);
	return MaxHarvestAmount;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnHarvestedAmount(float AmountHarvested)
{
	__NFUN_184__(CurrentHarvestAmount, AmountHarvested);
	__NFUN_162__(LootContainer.GetItem(0).StackSize, int(AmountHarvested));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function name GetHandEquippingAnimationName(Hands Hands)
{
	return Hands.UsingGathererToolEquipAnimationName;
	return;
	@NULL
	CommanderAction
}

function name GetHandLoopingAnimationName(Hands Hands)
{
	return Hands.UsingGathererToolLoopAnimationName;
	return;
	@NULL
	CommanderAction
}

function name GetHandUnequippingAnimationName(Hands Hands)
{
	return Hands.UsingGathererToolUnEquipAnimationName;
	return;
	@NULL
	CommanderAction
}

function bool ShouldPushHarvestingContext()
{
	return true;
	return;
}

function bool CanBeFocusedNow()
{
	return __NFUN_129__(bHidden);
	return;
	@NULL
}

function string GetFriendlyName()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xBC
	/*@Error*/
	// End:0x47
	if(__NFUN_151__(__NFUN_125__(OurAIArchetype.FriendlyName), 0))
	{
		return OurAIArchetype.FriendlyName;
		goto J0xBC;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xBC
		/*@Error*/
	}
	return OurAIArchetype.AIType.default.FriendlyName;
	return FriendlyName;
	return;
	@NULL
	EcologyCommanderAction
	CommanderAction
	@NULL
}

function string GetFocusDisplayName()
{
	// End:0x14
	if(IsAlive())
	{
		return " ";		
	}
	else
	{
		return GetFriendlyName();
		return;
		@NULL
	}
}

function string GetHUDMessageForFocusAttained()
{
	local string feedbackString;

	feedbackString = GetFocusDisplayName();
	// End:0x41
	if(CanBeUsedNow())
	{
		LootContainer.ModifyHudMessage(feedbackString);
		return feedbackString;
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

function bool ShouldHighlightWhenFocused()
{
	// End:0x12
	if(IsAlive())
	{
		return false;		
	}
	else
	{
		return true;
	}
	return;
}

function bool ShouldShowHelpTagWhenFocused()
{
	return true;
	return;
}

function OnFocusStarted()
{
	TriggerEffectEvent('BecameUseFocus');
	return;
}

function OnFocusStopped()
{
	UnTriggerEffectEvent('BecameUseFocus');
	return;
}

function OnLocomotionMovementRequestCompleted(Vector RequestLocationWorldSpace)
{
	return;
}

function OnWalkCycleLooped()
{
	return;
}

function SetVulnerable(bool inVulnerable)
{
	bIsVulnerable = inVulnerable;
	return;
	@NULL
	CommanderAction
}

function SetCannotDie(bool inCannotDie)
{
	bCannotDie = inCannotDie;
	return;
	@NULL
	CommanderAction
}

function OnDamaged(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, bool bIsCriticalHit, optional name HitHighBone, optional name HitLowBone)
{
	local array<ShockPawn.EDamageEvent> DamageEvents;
	local float VelocityImparted;

	super(ShockPawn).OnDamaged(DamageStimuli, TotalDamageDealt, Damager, HitLocation, HitNormal, HitImpulseDirection, EffectEventName, bIsCriticalHit, HitHighBone, HitLowBone);
	DamageEvents[0] = GetDamageEvent(DamageStimuli, Damager, TotalDamageDealt, HitLowBone, bIsCriticalHit);
	// End:0x236
	if(IsAlive())
	{
		// End:0x1D4
		if(ShouldTreatAsIntentionalDamage(Damager, DamageStimuli))
		{
			OnAIIntentionallyDamaged(Damager);
			// End:0x10B
			if(bIsCriticalHit)
			{
				PlaySpeech('DamagedCritical');
				goto J0x11E;
				PlaySpeech('Damaged');
				PlaySpeech('NearDeath');
				UpdateIntentionalDamage(Damager, DamageStimuli, TotalDamageDealt);
				CommanderAction(Commander.achievingAction).super(CommanderAction).OnDamaged(DamageStimuli, TotalDamageDealt, Damager, HitLocation, HitNormal, HitImpulseDirection, HitLowBone, HitHighBone, DamageEvents);
			}
			log('Damage', 4, __NFUN_112__(string(Name), "::OnDamaged() IGNORING damage momentum because AI is still alive"));
			goto J0x30A;
			log('Damage', 4, __NFUN_112__(string(Name), "::OnDamaged() applying damage momentum"));
		}
		VelocityImparted = Class'Engine.DamageStimuliSet'.static.StaticGetVelocityImparted(self, DamageStimuli.MomentumScale);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x30A
		/*@Error*/
		TakeImpulse(DamageStimuli, HitLocation, HitImpulseDirection);
	}
	DropDamagedAttachments(HitHighBone, HitImpulseDirection);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

protected event OnAIIntentionallyDamaged(Actor Damager)
{
	return;
}

function UpdateIntentionalDamage(Actor Damager, DamageStimuliSet DamageStimuli, float TotalDamageDealt)
{
	LastTimeIntentionallyDamaged = Level.TimeSeconds;
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function OnDealtDamage(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damagee, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, bool bIsCriticalHit, optional name HitHighBone, optional name HitLowBone)
{
	super(ShockPawn).OnDealtDamage(DamageStimuli, TotalDamageDealt, Damagee, HitLocation, HitNormal, HitImpulseDirection, EffectEventName, bIsCriticalHit, HitHighBone, HitLowBone);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA8
	/*@Error*/
	CommanderAction(Commander.achievingAction).OnDealtDamage(Damagee);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function name GetDeathHitAnimation(Vector HitNormal, float HitFrontOrBackDegrees, name HitHighBone)
{
	//native.HitNormal;
	//native.HitFrontOrBackDegrees;
	//native.HitHighBone;	
	@NULL
	@NULL
	return default.@NULL;
}

function name GetFullBodyHitAnimation(Vector HitNormal, float HitFrontOrBackDegrees, name HitHighBone)
{
	//native.HitNormal;
	//native.HitFrontOrBackDegrees;
	//native.HitHighBone;	
	@NULL
	@NULL
	return default.@NULL;
}

function GetHitFrontAdditiveAnimations(out array<name> outHitFrontAdditiveAnimations)
{
	outHitFrontAdditiveAnimations = HitFrontAdditiveAnimations;
	return;
	@NULL
	CommanderAction
}

function GetHitLeftAdditiveAnimations(out array<name> outHitLeftAdditiveAnimations)
{
	outHitLeftAdditiveAnimations = HitLeftAdditiveAnimations;
	return;
	@NULL
	CommanderAction
}

function GetHitRightAdditiveAnimations(out array<name> outHitRightAdditiveAnimations)
{
	outHitRightAdditiveAnimations = HitRightAdditiveAnimations;
	return;
	@NULL
	CommanderAction
}

function GetHitBackAdditiveAnimations(out array<name> outHitBackAdditiveAnimations)
{
	outHitBackAdditiveAnimations = HitBackAdditiveAnimations;
	return;
	@NULL
	CommanderAction
}

function PlayAdditiveHitReaction(Vector HitNormal)
{
	local ShockAI.EDirection HitDirection;
	local array<name> HitAnimationNames;
	local name HitAnimation;

	HitDirection = GetDirectionForPoint(Rotation, HitNormal, Class'ShockAI.FullBodyReactionAction'.default.HitFrontOrBackDegrees);
	switch(HitDirection)
	{
		// End:0x62
		case 1:
			HitAnimationNames = HitBackAdditiveAnimations;
			// End:0xB6
			break;
			// End:0x7D
			case 2:
				HitAnimationNames = HitLeftAdditiveAnimations;
				// End:0xB6
				break;
				// End:0x98
				case 3:
					HitAnimationNames = HitRightAdditiveAnimations;
				// End:0xB6
				break;
				// End:0x9D
				case 0:
					// End:0xFFFF
					default:
						HitAnimationNames = HitFrontAdditiveAnimations;
						// End:0xB6
						break;
						break;
				}/* !MISMATCHING REMOVE, tried Switch got Type:Case Position:0x068! */
			// End:0xE6
			if(__NFUN_151__(HitAnimationNames.Length, 0))
			{
				HitAnimation = HitAnimationNames[__NFUN_167__(HitAnimationNames.Length)];/* !MISMATCHING REMOVE, tried Case got Type:If Position:0x07E! */
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x151
		/*@Error*/
		log('AI', 4, __NFUN_112__("Playing additive hit animation: ", string(HitAnimation)));
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:Switch Position:0x0B6
	PlayAnimationOnChannel(5, HitAnimation);
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:Switch Position:0x0B6
	return;
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:Switch Position:0x0B6
	@NULL
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:Switch Position:0x0B6
	CommanderAction
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:Switch Position:0x0B6
	CommanderAction
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:Switch Position:0x0B6
	@NULL
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:Switch Position:0x0B6
	// Failed to format remaining nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 724
	// 1 & Type:Switch Position:0x0B6
}

function SetScriptedUseFullBodyHitReactions(bool inShouldUseFullBodyHitReactions)
{
	bScriptedFullBodyReactionPrevention = __NFUN_129__(inShouldUseFullBodyHitReactions);
	return;
	@NULL
	CommanderAction
}

function SetScriptedUseQuickHitReactions(bool inShouldUseQuickHitReactions)
{
	bScriptedQuickHitReactionPrevention = __NFUN_129__(inShouldUseQuickHitReactions);
	return;
	@NULL
	CommanderAction
}

function SetScriptedUseFallDownHitReactions(bool inShouldUseFallDownHitReactions)
{
	bScriptedFallDownReactionPrevention = __NFUN_129__(inShouldUseFallDownHitReactions);
	return;
	@NULL
	CommanderAction
}

function SetScriptedUseEventReactions(bool inShouldUseEventReactions)
{
	bScriptedEventReactionPrevention = __NFUN_129__(inShouldUseEventReactions);
	return;
	@NULL
	CommanderAction
}

function NotifyFinishedFullBodyHitReaction()
{
	NextFullBodyHitReactionTime = __NFUN_174__(Level.TimeSeconds, RandRange(TimeRangeBetweenFullBodyHitReactions.Min, TimeRangeBetweenFullBodyHitReactions.Max));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool CanPlayFullBodyHitReaction()
{
	// End:0x31
	if(__NFUN_179__(Level.TimeSeconds, NextFullBodyHitReactionTime))
	{
		return __NFUN_129__(IsFullBodyHitReactionPreventionDesired());
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function bool IsFullBodyHitReactionPreventionDesired()
{
	return __NFUN_132__(bScriptedFullBodyReactionPrevention, __NFUN_151__(FullBodyHitReactionPreventionRequesters.Length, 0));
	return;
	@NULL
	CommanderAction
}

function bool IsFullBodyHitReactionRequester(Object Requester)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x54
	/*@Error*/
	// End:0x46
	if(__NFUN_114__(FullBodyHitReactionPreventionRequesters[i], Requester))
	{
		return true;
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x0B;
		return false;
		return;
		@NULL
		CommanderAction
	}
	EcologyFighterCommanderAction
	@NULL
}

function NotifyFullBodyHitReactionPreventionDesired(Object Requester)
{
	// End:0x36
	if(__NFUN_129__(IsFullBodyHitReactionRequester(Requester)))
	{
		FullBodyHitReactionPreventionRequesters[FullBodyHitReactionPreventionRequesters.Length] = Requester;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function NotifyFullBodyHitReactionPreventionNoLongerDesired(Object Requester)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x69
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5B
	/*@Error*/
	FullBodyHitReactionPreventionRequesters.Remove(i, 1);
	goto J0x69;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool CanPlayFallDownHitReaction()
{
	return __NFUN_130__(__NFUN_129__(bScriptedFallDownReactionPrevention), __NFUN_154__(FallDownHitReactionPreventionRequesters.Length, 0));
	return;
	@NULL
	CommanderAction
}

function bool IsFallDownHitReactionRequester(Object Requester)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x54
	/*@Error*/
	// End:0x46
	if(__NFUN_114__(FallDownHitReactionPreventionRequesters[i], Requester))
	{
		return true;
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x0B;
		return false;
		return;
		@NULL
		CommanderAction
	}
	EcologyFighterCommanderAction
	@NULL
}

function NotifyFallDownHitReactionPreventionDesired(Object Requester)
{
	// End:0x36
	if(__NFUN_129__(IsFallDownHitReactionRequester(Requester)))
	{
		FallDownHitReactionPreventionRequesters[FallDownHitReactionPreventionRequesters.Length] = Requester;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function NotifyFallDownHitReactionPreventionNoLongerDesired(Object Requester)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x69
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5B
	/*@Error*/
	FallDownHitReactionPreventionRequesters.Remove(i, 1);
	goto J0x69;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool CanPlayQuickHitReaction()
{
	return __NFUN_130__(__NFUN_129__(bScriptedQuickHitReactionPrevention), __NFUN_154__(QuickHitReactionPreventionRequesters.Length, 0));
	return;
	@NULL
	CommanderAction
}

function bool IsQuickHitReactionRequester(Object Requester)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x54
	/*@Error*/
	// End:0x46
	if(__NFUN_114__(QuickHitReactionPreventionRequesters[i], Requester))
	{
		return true;
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x0B;
		return false;
		return;
		@NULL
		CommanderAction
	}
	EcologyFighterCommanderAction
	@NULL
}

function NotifyQuickHitReactionPreventionDesired(Object Requester)
{
	// End:0x36
	if(__NFUN_129__(IsQuickHitReactionRequester(Requester)))
	{
		QuickHitReactionPreventionRequesters[QuickHitReactionPreventionRequesters.Length] = Requester;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function NotifyQuickHitReactionPreventionNoLongerDesired(Object Requester)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x69
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5B
	/*@Error*/
	QuickHitReactionPreventionRequesters.Remove(i, 1);
	goto J0x69;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool CanPlayEventReaction()
{
	return __NFUN_130__(__NFUN_130__(__NFUN_129__(bScriptedEventReactionPrevention), __NFUN_154__(EventReactionPreventionRequesters.Length, 0)), __NFUN_129__(IsOnCeiling()));
	return;
	@NULL
	CommanderAction
}

function bool IsEventReactionRequester(Object Requester)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x54
	/*@Error*/
	// End:0x46
	if(__NFUN_114__(EventReactionPreventionRequesters[i], Requester))
	{
		return true;
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x0B;
		return false;
		return;
		@NULL
		CommanderAction
	}
	EcologyFighterCommanderAction
	@NULL
}

function NotifyEventReactionPreventionDesired(Object Requester)
{
	// End:0x36
	if(__NFUN_129__(IsEventReactionRequester(Requester)))
	{
		EventReactionPreventionRequesters[EventReactionPreventionRequesters.Length] = Requester;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function NotifyEventReactionPreventionNoLongerDesired(Object Requester)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x69
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5B
	/*@Error*/
	EventReactionPreventionRequesters.Remove(i, 1);
	goto J0x69;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function name GetFlailingAnimation()
{
	return FlailingAnimations[__NFUN_167__(FlailingAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function bool HasFlailingAnimation()
{
	return __NFUN_151__(FlailingAnimations.Length, 0);
	return;
	@NULL
}

function name GetJumpInWaterAnimation()
{
	return JumpInWaterAnimations[__NFUN_167__(JumpInWaterAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function bool HasJumpInWaterAnimation()
{
	return __NFUN_151__(JumpInWaterAnimations.Length, 0);
	return;
	@NULL
}

function name GetShockedAnimation()
{
	return ShockedAnimations[__NFUN_167__(ShockedAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function name GetPostShatteredAnimation()
{
	return PostShatteredAnimations[__NFUN_167__(PostShatteredAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function float GetBurnBehaviorTime()
{
	return RandRange(BurningTimeRange.Min, BurningTimeRange.Max);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function SetShouldUseBurningAnimations(bool inShouldUseBurningAnimations)
{
	bDoNotDoBurningAnimations = __NFUN_129__(inShouldUseBurningAnimations);
	return;
	@NULL
	CommanderAction
}

function SetShouldDoBurningBehavior(bool inShouldUseBurningBehavior)
{
	bDoNotDoBurningBehavior = __NFUN_129__(inShouldUseBurningBehavior);
	return;
	@NULL
	CommanderAction
}

function SetShouldUseInsectSwarmAnimations(bool inShouldUseInsectSwarmAnimations)
{
	bDoNotDoInsectSwarmAnimations = __NFUN_129__(inShouldUseInsectSwarmAnimations);
	return;
	@NULL
	CommanderAction
}

function SetShouldUseInsectSwarmBehavior(bool inShouldUseInsectSwarmBehavior)
{
	bDoNotDoInsectSwarmBehavior = __NFUN_129__(inShouldUseInsectSwarmBehavior);
	return;
	@NULL
	CommanderAction
}

function float GetSwarmReactionBehaviorTime()
{
	return RandRange(SwarmReactionTimeRange.Min, SwarmReactionTimeRange.Max);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool CanReactToAttack()
{
	return CommanderAction(Commander.achievingAction).CanReactToAttack();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function bool ReactToDeath(DamageStimuliSet DamageStimuli, Vector HitNormal, name HitHighBone)
{
	local name DeathAnimationName;
	local float DeathAnimationLength;
	local int DeathAnimationEndBehavior;
	local bool AllowDamageMomentum;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x2CC
	/*@Error*/
	AllowDamageMomentum = true;
	// End:0x12A
	if(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_154__(int(Physics), int(2)), __NFUN_129__(IsFullBodyHitReactionPreventionDesired())), __NFUN_129__(DamageStimuli.ShouldCauseInstantRagdollsToAIs())), __NFUN_129__(IsOnCeiling())))
	{
		// End:0xF4
		if(DamageStimuli.HasDamageStimulusType(1))
		{
			DeathAnimationName = GetShockedAnimation();
			DeathAnimationEndBehavior = 8;
			RagdollDeathSleepTime = RandRange(ShockedInWaterDeathAnimationDurationRange.Min, ShockedInWaterDeathAnimationDurationRange.Max);
			goto J0x12A;
			DeathAnimationName = GetDeathHitAnimation(HitNormal, 45.0000000, HitHighBone);
			DeathAnimationEndBehavior = 1;
			EaseOutAllAnimations(DeadAnimationsEaseOutTime);
			// End:0x25D
			if(__NFUN_255__(DeathAnimationName, 'None'))
			{
			}
			// End:0x1C3
			if(__NFUN_180__(RagdollDeathSleepTime, 0.0000000))
			{
				DeathAnimationLength = GetAnimationLength(DeathAnimationName);
				RagdollDeathSleepTime = RandRange(__NFUN_172__(DeathAnimationLength, 4.0000000), __NFUN_175__(DeathAnimationLength, __NFUN_172__(DeathAnimationLength, 4.0000000)));
			}
			PlayAnimationOnChannel(0, DeathAnimationName, DeathAnimationEndBehavior);
			AllowDamageMomentum = false;
			log('Damage', 4, __NFUN_112__(string(Name), "::OnKilled() IGNORING damage momentum because playing a special death animation"));
		}
		goto J0x2C9;
		GetRagdoll().SetRisePoseMatchingEnabled(false);
		GetRagdoll().SetMotorsEnabled(true);
		GetRagdoll().SetMotorsEnabled(false, DeadRagdollMotorsEaseOutTime);
		GetRagdoll().Fall();
		goto J0x344;
		AllowDamageMomentum = false;
		log('Damage', 4, __NFUN_112__(string(Name), "::OnKilled() IGNORING damage momentum because bShouldGoRagdollOnDeath = False"));
	}
	return AllowDamageMomentum;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function OnKilled(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, bool bIsCriticalHit, optional name HitHighBone, optional name HitLowBone)
{
	local bool AllowDamageMomentum;
	local float VelocityImparted;

	super(ShockPawn).OnKilled(DamageStimuli, TotalDamageDealt, Damager, HitLocation, HitNormal, HitImpulseDirection, EffectEventName, bIsCriticalHit, HitHighBone, HitLowBone);
	// End:0x97
	if(ShouldTreatAsIntentionalDamage(Damager, DamageStimuli))
	{
		OnAIIntentionallyDamaged(Damager);
		AllowDamageMomentum = ReactToDeath(DamageStimuli, HitNormal, HitHighBone);
		DestroyCommander();
		CleanupAI();
		StopAllSpeech();
	}
	PlaySpeech('Died');
	MuteAI(true, true);
	StopAnyWeaponAction();
	__NFUN_262__(true, false, false);
	bUseCylinderCollision = false;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x23C
	/*@Error*/
	log('Damage', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), "::OnKilled() applying damage momentum at HitLocation: "), string(HitLocation)), " On LowBone: "), string(HitLowBone)));
	VelocityImparted = Class'Engine.DamageStimuliSet'.static.StaticGetVelocityImparted(self, DamageStimuli.MomentumScale);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x23C
	/*@Error*/
	TakeImpulse(DamageStimuli, HitLocation, HitImpulseDirection);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x253
	/*@Error*/
	DropWeapons();
	DropOnKilledAttachments();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2CA
	/*@Error*/
	SpawningManager(Level.SpawningManager).AddBooty(self);
	BootyImpl = Class'ShockAI.BootyImpl'.static.Allocate(self).;
	construct_Actor(self);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function bool ShouldDropWeaponsOnDeath()
{
	return true;
	return;
}

// Export UShockAI::execDropWeapons(FFrame&, void* const)
native function DropWeapons();

function DropAttachment(AIAttachment Attachment, optional Vector Impulse, optional Vector InitialVelocity)
{
	//native.Attachment;
	//native.Impulse;
	//native.InitialVelocity;	
	@NULL
	@NULL
	return default.@NULL;
}

function DropAttachmentsByCategory(name AttachmentCategory, optional Vector InitialVelocity)
{
	//native.AttachmentCategory;
	//native.InitialVelocity;	
	@NULL
	@NULL
}

function ToggleAttachmentsVisibility(name AttachmentCategory, bool bHideAttachments)
{
	//native.AttachmentCategory;
	//native.bHideAttachments;	
	@NULL
	@NULL
}

function OnAttachmentWasRemovedByTelekinesis(AIAttachment AttachmentThatWasTornOff)
{
	local EcologyFighter EF;
	local Pawn Player;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xD9
	/*@Error*/
	EF = EcologyFighter(self);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xD9
	/*@Error*/
	Player = Level.GetLocalPlayerController().Pawn;
	PlaySpeech('AttachmentWasStolen');
	EF.Investigate(Player.Location, __NFUN_216__(Player.Location, EF.Location));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function DropOnKilledAttachments()
{
	local int i;
	local AIAttachment Attachment;
	local array<AIAttachment> AttachmentList;

	i = 0;
	// End:0xA0
	if(__NFUN_150__(i, Attached.Length))
	{
		Attachment = AIAttachment(Attached[i]);
		// End:0x92
		if(__NFUN_130__(__NFUN_119__(Attachment, none), Attachment.FallOffWhenKilled))
		{
			AttachmentList[AttachmentList.Length] = Attachment;
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x0B;
			i = 0;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x131
			/*@Error*/
			DropAttachment(AttachmentList[i],, __NFUN_212__(AttachmentList[i].Velocity, AttachmentList[i].DroppedVelocityModifier));
		}
	}
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0xAB;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function DropDamagedAttachments(name DamagedBone, optional Vector ImpulseDirection)
{
	//native.DamagedBone;
	//native.ImpulseDirection;	
	@NULL
	@NULL
}

function HideAIAttachments()
{
	local int i;
	local AIAttachment Attachment;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x7E
	/*@Error*/
	Attachment = AIAttachment(Attached[i]);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x70
	/*@Error*/
	Attachment.SetHidden(true);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ShowAIAttachments()
{
	local int i;
	local AIAttachment Attachment;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x7E
	/*@Error*/
	Attachment = AIAttachment(Attached[i]);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x70
	/*@Error*/
	Attachment.SetHidden(false);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function float GetLastTimeIntentionallyDamaged()
{
	return LastTimeIntentionallyDamaged;
	return;
	@NULL
}

function float GetDelayOnGroundTime()
{
	return RandRange(DelayOnGroundRange.Min, DelayOnGroundRange.Max);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Fall(Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, float HitMomentumImparted, name HitLowBone, name HitHighBone, optional DamageStimuliSet DamageStimuli)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xAE
	/*@Error*/
	PlaySpeech('Damaged');
	CommanderAction(Commander.achievingAction).NotifyReactToDamage(1, HitLocation, HitNormal, HitImpulseDirection, HitLowBone, HitHighBone, HitMomentumImparted, DamageStimuli);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function HitByAirBlast(Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, float HitMomentumImparted, name HitLowBone, name HitHighBone, DamageStimuliSet DamageStimuli)
{
	TriggerEffectEvent('HitByAirBlast');
	OnHitByAirBlast();
	Fall(HitLocation, HitNormal, HitImpulseDirection, HitMomentumImparted, HitLowBone, HitHighBone, DamageStimuli);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function HitBySpringBoardTrap(Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, float HitMomentumImparted, name HitLowBone, name HitHighBone, DamageStimuliSet DamageStimuli)
{
	TriggerEffectEvent('HitBySpringBoardTrap');
	OnHitBySpringboardTrap();
	Fall(HitLocation, HitNormal, HitImpulseDirection, HitMomentumImparted, HitLowBone, HitHighBone, DamageStimuli);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function OnHitByAirBlast()
{
	return;
}

function OnHitBySpringboardTrap()
{
	return;
}

function ApplyAirBlastMomentum(Vector direction, float MomentumScale, float MomentumDuration)
{
	//native.direction;
	//native.MomentumScale;
	//native.MomentumDuration;	
	@NULL
	@NULL
	return default.@NULL;
}

function ApplySpringBoardMomentum(Vector direction, float MomentumScale, float MomentumDuration)
{
	//native.direction;
	//native.MomentumScale;
	//native.MomentumDuration;	
	@NULL
	@NULL
	return default.@NULL;
}

function ApplyProtectorPushMomentum(Vector direction, float MomentumScale, float MomentumDuration)
{
	//native.direction;
	//native.MomentumScale;
	//native.MomentumDuration;	
	@NULL
	@NULL
	return default.@NULL;
}

function ApplyDamageMomentum(name DamageStimuliSetName, Vector HitLocation, Vector HitDirection)
{
	//native.DamageStimuliSetName;
	//native.HitLocation;
	//native.HitDirection;	
	@NULL
	@NULL
	return default.@NULL;
}

function bool IsEnemy(ShockPawn Target)
{
	//native.Target;	
	@NULL
}

function bool CanDetectPlayer(ShockPawn Player)
{
	//native.Player;	
	@NULL
}

// Export UShockAI::execGetAttackTarget(FFrame&, void* const)
native function ShockPawn GetAttackTarget();

function bool IsAttacking(optional ShockPawn Target)
{
	//native.Target;	
	@NULL
}

function bool IsAbleToAttackTarget(ShockPawn Target)
{
	//native.Target;	
	@NULL
}

function bool FindLocalPointToAttackTarget(ShockPawn Target, out Vector LocalPoint, float inMinDesiredDistanceToMove, float inMaxDesiredDistanceToMove, optional float inMinDistanceToApproachTarget)
{
	//native.Target;
	//native.LocalPoint;
	//native.inMinDesiredDistanceToMove;
	//native.inMaxDesiredDistanceToMove;
	//native.inMinDistanceToApproachTarget;	
	@NULL
	@NULL
	return default.@NULL;
}

function bool FindPointToAttackTarget(ShockPawn Target, out Actor PointToAttackTarget, optional float inMinDistanceToTarget, optional float inMaxDistanceToTarget, optional float inMinDesiredDistanceToMove, optional float inMaxDesiredDistanceToMove, optional bool inFindRandomPoint, optional float inMinDistanceToApproachTarget, optional AIWeapon DesiredWeaponToAttackWith, optional bool inAvoidSurfaceTransitions)
{
	//native.Target;
	//native.PointToAttackTarget;
	//native.inMinDistanceToTarget;
	//native.inMaxDistanceToTarget;
	//native.inMinDesiredDistanceToMove;
	//native.inMaxDesiredDistanceToMove;
	//native.inFindRandomPoint;
	//native.inMinDistanceToApproachTarget;
	//native.DesiredWeaponToAttackWith;
	//native.inAvoidSurfaceTransitions;	
	@NULL
	@NULL
	return default.@NULL;
}

function bool FindPointToAvoidTarget(ShockPawn Target, out Actor PointToAvoidTarget, bool inPreferNotVisiblePoints, optional float inMinDistanceToTarget, optional float inMaxDistanceToTarget, optional float inMinDesiredDistanceToMove, optional float inMaxDesiredDistanceToMove, optional bool inFindRandomPoint, optional float inMinDistanceToApproachTarget, optional bool inAvoidDoors, optional bool inAvoidSurfaceTransitions)
{
	//native.Target;
	//native.PointToAvoidTarget;
	//native.inPreferNotVisiblePoints;
	//native.inMinDistanceToTarget;
	//native.inMaxDistanceToTarget;
	//native.inMinDesiredDistanceToMove;
	//native.inMaxDesiredDistanceToMove;
	//native.inFindRandomPoint;
	//native.inMinDistanceToApproachTarget;
	//native.inAvoidDoors;
	//native.inAvoidSurfaceTransitions;	
	@NULL
	@NULL
	return default.@NULL;
}

function SetAvoidTarget(ShockPawn inAvoidTarget, optional float inMinDistanceToApproachTarget)
{
	//native.inAvoidTarget;
	//native.inMinDistanceToApproachTarget;	
	@NULL
	@NULL
}

function bool CanAttackTargetAtPoint(ShockPawn Target, Vector Point)
{
	//native.Target;
	//native.Point;	
	@NULL
	@NULL
}

function GetDodgeAnimations(out array<name> outDodgeAnimations, bool bIsMeleeDodge)
{
	local int i;

	outDodgeAnimations = DodgeAnimations;
	// End:0x7C
	if(bIsMeleeDodge)
	{
		i = 0;
		// End:0x79
		if(__NFUN_150__(i, MeleeDodgeAnimations.Length))
		{
			J0x2B:

			outDodgeAnimations[outDodgeAnimations.Length] = MeleeDodgeAnimations[i];
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x2B;
			goto J0xD5;
			i = 0;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0xD5
			/*@Error*/
			outDodgeAnimations[outDodgeAnimations.Length] = NonMeleeDodgeAnimations[i];
		}
	}
	__NFUN_163__(i);
	goto J0x87;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NavigationPoint FindUsablePointClosestTo(Vector Point)
{
	//native.Point;	
	@NULL
}

function NavigationPoint FindPointInWater(optional ShockPawn AvoidTarget, optional float MinDistanceToApproachTarget, optional float MinDistanceToTarget, optional float MinDesiredDistanceToMove, optional float MaxDesiredDistanceToMove)
{
	//native.AvoidTarget;
	//native.MinDistanceToApproachTarget;
	//native.MinDistanceToTarget;
	//native.MinDesiredDistanceToMove;
	//native.MaxDesiredDistanceToMove;	
	@NULL
	@NULL
	return default.@NULL;
}

function OnAcquiredState(name StateName, Actor Instigator)
{
	local bool StillAlive;
	local int i;
	local AIAttachment Attachment;

	super(ShockPawn).OnAcquiredState(StateName, Instigator);
	StillAlive = IsAlive();
	// End:0xAF
	if(__NFUN_130__(__NFUN_130__(StillAlive, __NFUN_119__(Commander, none)), __NFUN_119__(Commander.achievingAction, none)))
	{
		CommanderAction(Commander.achievingAction).OnAcquiredState(StateName, Instigator);
		goto J0x12F;
		log('AI', 3, __NFUN_112__(string(Name), " OnAcquiredState - we are dead or have no running commander, no behavioral response will be done."));
	}
	// End:0x181
	if(__NFUN_130__(__NFUN_130__(__NFUN_129__(StillAlive), __NFUN_254__(StateName, 'Frozen')), __NFUN_119__(GetRagdoll(), none)))
	{
		GetRagdoll().Freeze();
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x282
		/*@Error*/
		i = __NFUN_147__(Attached.Length, 1);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x27F
		/*@Error*/
		Attachment = AIAttachment(Attached[i]);
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x271
	/*@Error*/
	Attachment.LifeSpan = __NFUN_245__(0.1000000, __NFUN_171__(__NFUN_175__(Level.TimeSeconds, BurningUntil), 0.7500000));
	Attachment.FadeOutDuration = 1.0000000;
	__NFUN_164__(i);
	// [Loop Continue]
	goto J0x1AF;
	goto J0x2B9;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2B9
	/*@Error*/
	LastBerserkStartTime = Level.TimeSeconds;
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function OnUnAcquiredState(name StateName)
{
	local bool StillAlive;

	super(ShockPawn).OnUnAcquiredState(StateName);
	StillAlive = IsAlive();
	// End:0x9D
	if(__NFUN_130__(__NFUN_130__(StillAlive, __NFUN_119__(Commander, none)), __NFUN_119__(Commander.achievingAction, none)))
	{
		CommanderAction(Commander.achievingAction).OnUnAcquiredState(StateName);
		goto J0x11D;
		log('AI', 3, __NFUN_112__(string(Name), " OnAcquiredState - we are dead or have no running commander, no behavioral response will be done."));
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x16F
	/*@Error*/
	GetRagdoll().Unfreeze();
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function AddFrozenResistance()
{
	TriggerEffectEvent('BecameImmuneToFrozenState');
	return;
}

function RemoveFrozenResistance()
{
	UnTriggerEffectEvent('BecameImmuneToFrozenState');
	return;
}

function AddColdResistance()
{
	TriggerEffectEvent('BecameImmuneToColdDamage');
	return;
}

function RemoveColdResistance()
{
	UnTriggerEffectEvent('BecameImmuneToColdDamage');
	return;
}

function ShockAI.EDirection GetDirectionForPoint(Rotator sourceRotation, Vector TestNormal, float FrontOrBackAngleDegrees)
{
	//native.sourceRotation;
	//native.TestNormal;
	//native.FrontOrBackAngleDegrees;	
	@NULL
	@NULL
	2
}

function Rotator GetGoodDirectionToLookIn(Rotator StartRotation)
{
	local int i, YawDelta;
	local Rotator testRotation;
	local array<Rotator> UsableRotations;
	local Vector TraceStartLocation, TraceEndLocation;

	TraceStartLocation = Location;
	__NFUN_184__(TraceStartLocation.Z, BaseEyeHeight);
	i = 1;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1B7
	/*@Error*/
	YawDelta = __NFUN_144__(8192, i);
	testRotation = StartRotation;
	__NFUN_161__(testRotation.Yaw, YawDelta);
	TraceEndLocation = __NFUN_215__(TraceStartLocation, __NFUN_212__(Vector(testRotation), 500.0000000));
	// End:0x114
	if(__NFUN_548__(TraceEndLocation, TraceStartLocation))
	{
		UsableRotations[UsableRotations.Length] = testRotation;
		testRotation = StartRotation;
		__NFUN_162__(testRotation.Yaw, YawDelta);
		TraceEndLocation = __NFUN_215__(TraceStartLocation, __NFUN_212__(Vector(testRotation), 500.0000000));
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x1A9
		/*@Error*/
		UsableRotations[UsableRotations.Length] = testRotation;
		__NFUN_163__(i);
	}
	// [Loop Continue]
	goto J0x43;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1E1
	/*@Error*/
	return UsableRotations[__NFUN_167__(UsableRotations.Length)];
	goto J0x1EB;
	return StartRotation;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool IsEnrageFailure(ShockPawn Target)
{
	return __NFUN_130__(__NFUN_130__(IsBerserk(), __NFUN_176__(__NFUN_175__(Level.TimeSeconds, LastBerserkStartTime), ShockGameDriver(Level.GetGameDriver()).GetTrainingMessageManager().TimeToConsiderEnrageFailure)), Target.__NFUN_303__('ShockPlayer'));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

state Dying
{Begin:

	// End:0xD7
	if(__NFUN_130__(bShouldGoRagdollOnDeath, __NFUN_177__(RagdollDeathSleepTime, 0.0000000)))
	{
		__NFUN_256__(RagdollDeathSleepTime);
		GetRagdoll().SetRisePoseMatchingEnabled(false);
		GetRagdoll().SetMotorsEnabled(true);
		GetRagdoll().SetMotorsEnabled(false, DeadRagdollMotorsEaseOutTime);
		GetRagdoll().Fall();
		// End:0xC8
		if(__NFUN_155__(int(GetRagdoll().GetRagdollState()), int(2)))
		{
			__NFUN_256__(0.0000000);
			// [Loop Continue]
			goto J0x9A;
			EaseOutAllAnimations(0.2000000);
			AddPersistentEffectsSystemContext('IsDead');
		}
		// End:0x118
		if(IsCensoredContent())
		{
		}
		__NFUN_256__(1.5100000);
		ClearBurning();
		BurningTimeout = 1.5100000;
		__NFUN_113__('Dead');
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

defaultproperties
{
	FriendlyName="FriendlyName not configured in AI.ini for this AI"
	UseVerbText="SEARCH"
	CollectCrossbowsVerbText="GATHER BOLTS"
	CorpseString="Corpse"
	AirBlastReactionMultiplier=1.0000000
	FOV=45.0000000
	ViewDistance=3000.0000000
	QuickHeadTurnAcceleration=250000.0000000
	CasualHeadTurnAcceleration=50000.0000000
	LimitAngle=1.5000000
	SpotEnemyTurnDelay=0.2500000
	bIsVulnerable=true
	ShockedInWaterDeathAnimationDurationRange=(Min=2.0000000,Max=4.0000000)
	BurningTimeRange=(Min=2.0000000,Max=4.0000000)
	SwarmReactionTimeRange=(Min=3.0000000,Max=5.0000000)
	LipSynchAnimation="LipFlap"
	LipSynchFrequency=4.0000000
	LipSynchChannel=7
	hLipSynch=-1
	DefaultEventReactions[0]=(Event=0,Reaction=(ReactionType=1,Duration=(Min=1.5000000,Max=2.0000000),Delay=(Min=0.0000000,Max=0.3000000)))
	DefaultEventReactions[1]=(Event=1,Reaction=(ReactionType=2,Duration=(Min=0.0000000,Max=0.0000000),Delay=(Min=0.0000000,Max=0.3000000)))
	DefaultEventReactions[2]=(Event=2,Reaction=(ReactionType=3,Duration=(Min=1.5000000,Max=2.0000000),Delay=(Min=0.0000000,Max=0.3000000)))
	DefaultEventReactions[3]=(Event=3,Reaction=(ReactionType=0,Duration=(Min=0.0000000,Max=0.0000000),Delay=(Min=0.0000000,Max=0.0000000)))
	bUsesEyeBoneLocation=true
	bUsesEyeHeight=true
	bShouldSeePlayer=true
	SpeechPriorityRestriction=-1
	AimPoseAngleEpsilonDegrees=5.0000000
	bShouldGoRagdollOnDeath=true
	LocomotionTranslationScaleAgainstPlayer=1.0000000
	MinZDifferenceForUsingUnevenSurface=4.0000000
	CeilingAIExtraCostMultiplierOnWalkNodes=2.0000000
	FlyingAIExtraCostMultiplierOnWalkNodes=1.2000000
	FlyingAIExtraCostMultiplierOnVerticalPaths=3.0000000
	CeilingAIExtraCostMuliplierForPointAboveAttackTarget=5.0000000
	CeilingAIAboveTargetRadius=300.0000000
	bUseCollisionAvoidance=true
	bAvoidFuturePawnCollisions=true
	bShouldApplyDisplacement=true
	CollisionAvoidanceAttackingPushDistance=25.0000000
	NearbyAIMaxDistance=3000.0000000
	MaxDistanceTraveledToAvoidNearbyAIs=2000.0000000
	bCanRunAway=true
	LastPathMultiplier=5.0000000
	MinDistanceToStopNearPlayer=700.0000000
	LastRenderedForNormalLODDeltaTime=1.0000000
	DeadRagdollMotorsEaseOutTime=1.2000000
	DeadAnimationsEaseOutTime=4.0000000
	DroppedAttachmentLifeSpan=300.0000000
	DroppedAttachmentFadeOutDuration=4.0000000
	bDropToGroundUponSpawning=true
	TimeInWaterToStopBurning=0.2500000
	bUsesTyrion=true
	NormalLODTyrionTickUpdateRange=(Min=0.0100000,Max=0.0200000)
	NormalLODVisionTickUpdateRange=(Min=0.2500000,Max=0.2500000)
	LowLODTyrionTickUpdateRange=(Min=1.0000000,Max=2.0000000)
	LowLODVisionTickUpdateRange=(Min=1.0000000,Max=1.0000000)
	bHearingDisabledPermanently=true
	bCanCrouch=false
	bJumpCapable=false
	bCanJump=false
	bCanWalkOffLedges=true
	VisionRadiusMultiplier=1.0000000
	VisionHeightMultiplier=1.0000000
	ControllerClass=Class'ShockGame.BioshockAIController'
	bPhysicsAnimUpdate=false
	bStasis=false
	bBlockActors=false
}