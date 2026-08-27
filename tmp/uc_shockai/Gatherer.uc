class Gatherer extends EcologyAI implements ICanBeHacked
	abstract
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

enum GathererVulnerableState
{
	AlwaysVulnerable,               // 0
	InVulnerableUntilSaved,         // 1
	NeverVulnerable                 // 2
};

var private bool bIsFullOfResource;
var private GathererVent CurrentVent;
var private Protector ProtectorEscort;
var private ShockPlayer PlayerEscort;
var private ShockPawn PanicInducer;
var array<Actor> SeenInterestingObjects;
var private Actor CurrentResource;
var private bool bIsJumpingOntoProtector;
var private bool bIsGettingOffProtector;
var private bool bSkipExit;
var private Actor NextPanicPoint;
var private bool bIsSaved;
var private bool bIsUnconscious;
var private float IncinerateSkinSwapTime;
var const config float GatherDistance;
var private config name BeginGatherAnimation;
var config array<name> LoopGatherAnimations;
var config array<name> EndGatherAnimations;
var config array<name> GestureFinishedFeedingAnimations;
var private config Class<Pickup> SeaSlugClass;
var private config name SeaSlugAnimation;
var private config name SeaSlugSpawnSocketName;
var private config float SeaSlugVelocityMagnitude;
var private config float SeaSlugAdamPercentage;
var private config Gatherer.GathererVulnerableState VulnerableState;
var private bool IntentionallyPacified;
var private config name PseudoGathererEquipAnimationName;
var private config name PseudoGathererLoopAnimationName;
var private config name PseudoGathererUnEquipAnimationName;
var private int PseudoGathererAnimationHandle;
var private PseudoGatherer PseudoGatherer;
var private config name PseudoGathererSocket;
var private config Class<PseudoGatherer> PseudoGathererClass;
var private config float IncinerateLifeSpan;
var private config float TimeToSwapIncinerateSkin;
var private config bool bCannotBecomeUnconscious;
var bool HasBeenSavedOrPacified;
var private bool SaveOrPacifyExternallyEnabled;
var bool bIsGathering;
var bool bIsCrawlingThroughDoor;

function PreBeginPlay()
{
	super(ShockAI).PreBeginPlay();
	SpawningManager(Level.SpawningManager).AssignLootContainerToAI(self);
	SetHidden(false);
	SetVulnerableState(VulnerableState);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function PostLoadGame()
{
	super.PostLoadGame();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4B
	/*@Error*/
	PlayerEscort.SetEscortedGathererHealth(__NFUN_172__(__NFUN_171__(100.0000000, Health), MaxHealth));
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function UpdateEscortedGathererHealth()
{
	// End:0x41
	if(__NFUN_119__(PlayerEscort, none))
	{
		PlayerEscort.SetEscortedGathererHealth(__NFUN_172__(__NFUN_171__(100.0000000, Health), MaxHealth));
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function AddInitialKeywords()
{
	super(ShockAI).AddInitialKeywords();
	AddLocomotionKeyword('ReturnToVent', -1);
	AddLocomotionKeyword('WaitingForProtector', -1);
	AddLocomotionKeyword('HandsOnHips', -1);
	AddLocomotionKeyword('PointingToThreat', -1);
	AddLocomotionKeyword('Tired', -1);
	AddLocomotionKeyword('ArmsCrossed', -1);
	AddLocomotionKeyword('AttachedToBouncer', -1);
	AddLocomotionKeyword('AttachedToSPF', -1);
	AddLocomotionKeyword('Mourning', -1);
	return;
	@NULL
}

function Destroyed()
{
	RelinquishCurrentResource();
	super(ShockAI).Destroyed();
	return;
	@NULL
}

function OnDamaged(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, bool bIsCriticalHit, optional name HitHighBone, optional name HitLowBone)
{
	super(ShockAI).OnDamaged(DamageStimuli, TotalDamageDealt, Damager, HitLocation, HitNormal, HitImpulseDirection, EffectEventName, bIsCriticalHit, HitHighBone, HitLowBone);
	// End:0xC6
	if(DamageStimuli.HasDamageStimulusType(33))
	{
		// End:0x9D
		if(__NFUN_129__(IsSaved()))
		{
			BecomeStunned();
			goto J0xC6;
			TriggerEffectEvent('GathererSaveFailed', none, none, HitLocation, Rotator(HitNormal));
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x107
			/*@Error*/
			PlayerEscort.SetEscortedGathererHealth(__NFUN_172__(__NFUN_171__(100.0000000, Health), MaxHealth));
		}
		return;
		@NULL
	}
	J0xC6:

	CommanderAction
	stop;
	default.@NULL
}

function OnKilled(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, bool bIsCriticalHit, optional name HitHighBone, optional name HitLowBone)
{
	local ItemStack theStack;

	super(ShockAI).OnKilled(DamageStimuli, TotalDamageDealt, Damager, HitLocation, HitNormal, HitImpulseDirection, EffectEventName, bIsCriticalHit, HitHighBone, HitLowBone);
	RelinquishCurrentResource();
	// End:0x99
	if(__NFUN_254__(Label, 'PlayerEscortedGatherer'))
	{
		SetLabel('DeadPlayerEscortedGatherer');
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x144
		/*@Error*/
		GetMaxHarvestAmount(none);
		theStack = LootContainer.GetItem(0);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x144
		/*@Error*/
	}
	theStack.StackSize = 0;
	MaxHarvestAmount = float(theStack.StackSize);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x16A
	/*@Error*/
	PlayerEscort.SetEscortedGathererDied();
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function BecomeUnconscious(Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name HitLowBone, name HitHighBone, optional float HitMomentumImparted, optional DamageStimuliSet DamageStimuli)
{
	bIsUnconscious = true;
	OnAIIntentionallyDamaged(Damager);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB8
	/*@Error*/
	GathererCommanderAction(Commander.achievingAction).BecomeUnconscious(HitLocation, HitNormal, HitImpulseDirection, HitLowBone, HitHighBone, HitMomentumImparted, DamageStimuli);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function OnFinishedUnconscious()
{
	bIsUnconscious = false;
	return;
	@NULL
}

function bool IsUnconscious()
{
	return bIsUnconscious;
	return;
	@NULL
}

function SetCannotBecomeUnconscious(bool inCannotBecomeUnconscious)
{
	bCannotBecomeUnconscious = inCannotBecomeUnconscious;
	return;
	@NULL
	CommanderAction
}

function SetVulnerableState(Gatherer.GathererVulnerableState inVulnerableState)
{
	VulnerableState = inVulnerableState;
	// End:0x4B
	if(__NFUN_132__(__NFUN_154__(int(VulnerableState), int(2)), __NFUN_154__(int(inVulnerableState), int(1))))
	{
		SetVulnerable(false);
		goto J0x56;
		SetVulnerable(true);
		return;
		@NULL
	}
	CommanderAction
	stop;
	default.@NULL
}

function OnHitByAirBlast()
{
	local ShockPlayer Player;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x90
	/*@Error*/
	Player = ShockPlayer(Level.GetLocalPlayerController().Pawn);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x90
	/*@Error*/
	OnAIIntentionallyDamaged(Player);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnHitBySpringboardTrap()
{
	local ShockPlayer Player;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x90
	/*@Error*/
	Player = ShockPlayer(Level.GetLocalPlayerController().Pawn);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x90
	/*@Error*/
	OnAIIntentionallyDamaged(Player);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function int GetDesiredAnimationCapabilities()
{
	return __NFUN_158__(__NFUN_158__(super(ShockAI).GetDesiredAnimationCapabilities(), 64), 16);
	return;
	@NULL
}

function OnAIIntentionallyDamaged(Actor Damager)
{
	super(ShockAI).OnAIIntentionallyDamaged(Damager);
	// End:0x35
	if(__NFUN_119__(Damager, none))
	{
		NotifyEscortOfDamage(Damager);
		return;
		@NULL
		CommanderAction
		BioshockMovementAction
	}
	@NULL
}

function BecomePhysical()
{
	__NFUN_262__(true, true, true);
	bCollideWorld = true;
	// End:0x27
	if(IsUsingLowDetailMovement())
	{
		__NFUN_3970__(9);
		goto J0x2C;
		__NFUN_3970__(2);
	}
	return;
	@NULL
}

function BecomeNonPhysical()
{
	__NFUN_262__(true, false, false);
	bCollideWorld = false;
	__NFUN_3970__(3);
	return;
	@NULL
}

function bool IsNonPhysical()
{
	return __NFUN_154__(int(Physics), int(3));
	return;
	@NULL
}

function bool IsFullOfResource()
{
	return bIsFullOfResource;
	return;
	@NULL
}

function SetFullOfResource(bool inIsFullOfResource)
{
	bIsFullOfResource = inIsFullOfResource;
	return;
	@NULL
	CommanderAction
}

function GathererVent GetCurrentVent()
{
	return CurrentVent;
	return;
	@NULL
}

function SetCurrentVent(GathererVent inCurrentVent)
{
	assert(__NFUN_119__(inCurrentVent, none));
	CurrentVent = inCurrentVent;
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function SetEscort(ShockPawn inEscort)
{
	assert(__NFUN_119__(inEscort, none));
	ProtectorEscort = Protector(inEscort);
	PlayerEscort = ShockPlayer(inEscort);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xAD
	/*@Error*/
	AddLocomotionKeyword('NotForPlayerEscortedGatherer', Class'ShockAI.ShockAI'.-1);
	PlayerEscort.SetEscortedGathererHealth(__NFUN_172__(__NFUN_171__(100.0000000, Health), MaxHealth));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ClearProtectorEscort()
{
	ProtectorEscort = none;
	return;
	@NULL
}

function ShockPawn GetShockPawnEscort()
{
	// End:0x1C
	if(__NFUN_119__(ProtectorEscort, none))
	{
		return ProtectorEscort;
		goto J0x3A;
		// End:0x38
		if(__NFUN_119__(PlayerEscort, none))
		{
		}
		return PlayerEscort;
		goto J0x3A;
		return none;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function Protector GetProtectorEscort()
{
	return ProtectorEscort;
	return;
	@NULL
}

function ShockPlayer GetPlayerEscort()
{
	return PlayerEscort;
	return;
	@NULL
}

function NotifyLoseProtectorEscort()
{
	GetGathererCommanderAction().NotifyLoseProtectorEscort();
	return;
}

function SetPanicInducer(ShockPawn inPanicInducer)
{
	PanicInducer = inPanicInducer;
	return;
	@NULL
	CommanderAction
}

function ShockPawn GetPanicInducer()
{
	return PanicInducer;
	return;
	@NULL
}

function Actor GetCurrentResource()
{
	return CurrentResource;
	return;
	@NULL
}

function SetCurrentResource(Actor inCurrentResource)
{
	RelinquishCurrentResource();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x69
	/*@Error*/
	assert(inCurrentResource.__NFUN_303__('IBooty'));
	CurrentResource = inCurrentResource;
	IBooty(inCurrentResource).ClaimBooty(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function CancelJumpOntoProtector()
{
	SetIsJumpingOnProtector(false);
	GetGathererCommanderAction().NotifyRestartPanicBehavior();
	return;
}

function bool CanJumpOntoProtector()
{
	return __NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_129__(IsFrozen()), __NFUN_129__(IsShocked())), __NFUN_129__(IsBurning())), __NFUN_129__(IsUnconscious())), __NFUN_129__(IsBeingAttackedByInsectSwarm()));
	return;
}

function bool IsJumpingOnProtector()
{
	return bIsJumpingOntoProtector;
	return;
	@NULL
}

function SetIsJumpingOnProtector(bool inIsJumpingOntoProtector)
{
	bIsJumpingOntoProtector = inIsJumpingOntoProtector;
	return;
	@NULL
	CommanderAction
}

function bool IsGettingOffProtector()
{
	return bIsGettingOffProtector;
	return;
	@NULL
}

function SetIsGettingOffProtector(bool inIsGettingOffProtector)
{
	bIsGettingOffProtector = inIsGettingOffProtector;
	return;
	@NULL
	CommanderAction
}

function bool ShouldSkipExit()
{
	return bSkipExit;
	return;
	@NULL
}

function SetSkipExitFlag(bool Flag)
{
	bSkipExit = Flag;
	return;
	@NULL
	CommanderAction
}

function bool IsSaved()
{
	return bIsSaved;
	return;
	@NULL
}

function SetIsSaved(bool inIsSaved)
{
	bIsSaved = inIsSaved;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x54
	/*@Error*/
	VoiceType = 'SavedGatherer';
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x54
	/*@Error*/
	SetVulnerable(true);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyProtectorEscortStartingExitAnimation()
{
	// End:0x3A
	if(Class'Engine.Pawn'.static.checkAlive(ProtectorEscort))
	{
		ProtectorEscort.NotifyGathererExitingVent();
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function NotifyStartingToFeed()
{
	// End:0x3A
	if(Class'Engine.Pawn'.static.checkAlive(ProtectorEscort))
	{
		ProtectorEscort.NotifyGathererStartingToFeed();
		bIsGathering = true;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
	@NULL
}

function NotifyGatheringInterrupted()
{
	// End:0x3A
	if(Class'Engine.Pawn'.static.checkAlive(ProtectorEscort))
	{
		ProtectorEscort.NotifyGathererFeedingInterrupted();
		bIsGathering = false;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
	@NULL
}

function RelinquishCurrentResource()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x57
	/*@Error*/
	assert(CurrentResource.__NFUN_303__('IBooty'));
	IBooty(CurrentResource).RelinquishBooty(self);
	CurrentResource = none;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyFinishedFeeding()
{
	// End:0x5A
	if(__NFUN_130__(__NFUN_130__(Class'Engine.Pawn'.static.checkAlive(ProtectorEscort), IsAlive()), __NFUN_129__(bDeleteMe)))
	{
		ProtectorEscort.NotifyGathererFinishedFeeding();
		bIsGathering = false;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
	@NULL
}

function NotifyEscortOfDamage(Actor Damager)
{
	assert(__NFUN_119__(Damager, none));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x53
	/*@Error*/
	ProtectorEscort.NotifyEscortedGathererDamaged(self, Damager);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyEscortIsAttacking(ShockPawn AttackTarget)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x31
	/*@Error*/
	GetGathererCommanderAction().NotifyEscortIsAttacking(AttackTarget);
	return;
	@NULL
}

function NotifyEscortStoppedAttacking()
{
	// End:0x28
	if(__NFUN_119__(GetGathererCommanderAction(), none))
	{
		GetGathererCommanderAction().NotifyEscortStoppedAttacking();
	}
	return;
}

function NotifyGathererThatProtectorIsTooFarAway()
{
	// End:0x28
	if(__NFUN_119__(GetGathererCommanderAction(), none))
	{
		GetGathererCommanderAction().NotifyGathererThatProtectorIsTooFarAway();
	}
	return;
}

function NotifyGathererProtectorCaughtUp()
{
	// End:0x28
	if(__NFUN_119__(GetGathererCommanderAction(), none))
	{
		GetGathererCommanderAction().NotifyGathererProtectorCaughtUp();
	}
	return;
}

function DeactivateAlertSensor()
{
	// End:0x28
	if(__NFUN_119__(GetGathererCommanderAction(), none))
	{
		GetGathererCommanderAction().DeactivateAlertSensor();
	}
	return;
}

function NotifyGathererPrepareToBeScoopedUp()
{
	// End:0x28
	if(__NFUN_119__(GetGathererCommanderAction(), none))
	{
		GetGathererCommanderAction().NotifyGathererPrepareToBeScoopedUp();
	}
	return;
}

function NotifyStartScoopUp()
{
	// End:0x28
	if(__NFUN_119__(GetGathererCommanderAction(), none))
	{
		GetGathererCommanderAction().NotifyStartScoopUp();
	}
	return;
}

function NotifyCancelScoop()
{
	// End:0x28
	if(__NFUN_119__(GetGathererCommanderAction(), none))
	{
		GetGathererCommanderAction().NotifyCancelScoop();
	}
	return;
}

function BecomeTired()
{
	// End:0x28
	if(__NFUN_119__(GetGathererCommanderAction(), none))
	{
		GetGathererCommanderAction().BecomeTired();
	}
	return;
}

function NotifyProtectorSaysComeOn()
{
	// End:0x28
	if(__NFUN_119__(GetGathererCommanderAction(), none))
	{
		GetGathererCommanderAction().NotifyProtectorSaysComeOn();
	}
	return;
}

function NotifyProtectorStartingTiredAnimation(bool bUseUnevenSurfaceAnimation)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x32
	/*@Error*/
	GetGathererCommanderAction().NotifyProtectorStartingTiredAnimation(bUseUnevenSurfaceAnimation);
	return;
	@NULL
}

function NotifyPlayPickedUpAnimation()
{
	// End:0x28
	if(__NFUN_119__(GetGathererCommanderAction(), none))
	{
		GetGathererCommanderAction().NotifyPlayPickedUpAnimation();
	}
	return;
}

function NotifyJumpingOffProtector()
{
	// End:0x3A
	if(Class'Engine.Pawn'.static.checkAlive(ProtectorEscort))
	{
		ProtectorEscort.NotifyGathererJumpingOff();
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

event bool IsStunned()
{
	// End:0x29
	if(__NFUN_119__(GetGathererCommanderAction(), none))
	{
		return GetGathererCommanderAction().IsStunned();
	}
	return false;
	return;
}

function bool IsPanicking()
{
	return __NFUN_119__(PanicInducer, none);
	return;
	@NULL
}

function BecomeStunned()
{
	// End:0x28
	if(__NFUN_119__(GetGathererCommanderAction(), none))
	{
		GetGathererCommanderAction().BecomeStunned();
	}
	return;
}

function BecomeSaved()
{
	// End:0x28
	if(__NFUN_119__(GetGathererCommanderAction(), none))
	{
		GetGathererCommanderAction().BecomeSaved();
	}
	return;
}

function IncinerateGatherer()
{
	AssertWithDescription(__NFUN_129__(IsAlive()), "Gatherer::IncinerateGatherer - An alive Gatherer was told to be incinerated.  Only dead gatherers can be incinerated.");
	TriggerEffectEvent('GathererBodyIncinerated');
	IncinerateSkinSwapTime = __NFUN_174__(Level.TimeSeconds, TimeToSwapIncinerateSkin);
	LifeSpan = IncinerateLifeSpan;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function AddCommanderAbility()
{
	assert(__NFUN_119__(CharacterAI, none));
	CharacterAI.addAbility_Class(Class'ShockAI.GathererCommanderAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function CharacterAICreated()
{
	super.CharacterAICreated();
	CharacterAI.addAbility_Class(Class'ShockAI.CharacterMoveToAction');
	CharacterAI.addAbility_Class(Class'ShockAI.CollectResourceAction');
	CharacterAI.addAbility_Class(Class'ShockAI.GatherResourceAction');
	CharacterAI.addAbility_Class(Class'ShockAI.ReturnToVentAction');
	CharacterAI.addAbility_Class(Class'ShockAI.ExitVentAction');
	CharacterAI.addAbility_Class(Class'ShockAI.AlertAction');
	CharacterAI.addAbility_Class(Class'ShockAI.FullBodyReactionAction');
	CharacterAI.addAbility_Class(Class'ShockAI.PickedUpPanicAction');
	CharacterAI.addAbility_Class(Class'ShockAI.WaitForProtectorAction');
	CharacterAI.addAbility_Class(Class'ShockAI.GathererLookAtTargetAction');
	CharacterAI.addAbility_Class(Class'ShockAI.HeadTrackingAction');
	CharacterAI.addAbility_Class(Class'ShockAI.ScoopedUpAction');
	CharacterAI.addAbility_Class(Class'ShockAI.TiredAction');
	CharacterAI.addAbility_Class(Class'ShockAI.FollowPanicAction');
	CharacterAI.addAbility_Class(Class'ShockAI.FrozenAction');
	CharacterAI.addAbility_Class(Class'ShockAI.StunnedAction');
	CharacterAI.addAbility_Class(Class'ShockAI.ShockedAction');
	CharacterAI.addAbility_Class(Class'ShockAI.BurningAction');
	CharacterAI.addAbility_Class(Class'ShockAI.CrawlThroughDoorAction');
	CharacterAI.addAbility_Class(Class'ShockAI.UnconsciousAction');
	CharacterAI.addSensorActionClass(Class'ShockAI.AlertSensorAction');
	CharacterAI.addSensorActionClass(Class'ShockAI.GathererLookAtSensorAction');
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

function GathererCommanderAction GetGathererCommanderAction()
{
	return GathererCommanderAction(Commander.achievingAction);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function NotifyAlertDueTo(ShockPawn AlertTarget)
{
	assert(__NFUN_119__(AlertTarget, none));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x98
	/*@Error*/
	ProtectorEscort.NotifyThreatenTarget(AlertTarget);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x98
	/*@Error*/
	Aggressor(AlertTarget).NotifyCausedGathererAlert(self, ProtectorEscort);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyNoLongerAlertDueTo(ShockPawn FormerAlertTarget)
{
	// End:0x43
	if(Class'Engine.Pawn'.static.checkAlive(ProtectorEscort))
	{
		ProtectorEscort.NotifyRemoveThreatenTarget(FormerAlertTarget);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xAE
		/*@Error*/
	}
	Aggressor(FormerAlertTarget).NotifyGathererAlertOver(self, ProtectorEscort);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyPukedUpSeaSlug()
{
	local Pickup SeaSlug;
	local Coords SeaSlugBoneCoords;
	local Rotator SeaSlugStartRotation;
	local ItemStack theStack;

	SeaSlugBoneCoords = GetBoneCoords(SeaSlugSpawnSocketName, true);
	SeaSlugStartRotation = OrthoRotation(SeaSlugBoneCoords.XAxis, SeaSlugBoneCoords.YAxis, SeaSlugBoneCoords.ZAxis);
	SeaSlug = __NFUN_278__(SeaSlugClass, self,, SeaSlugBoneCoords.Origin, SeaSlugStartRotation);
	SeaSlugPickup(SeaSlug).SetADAMValue(int(__NFUN_171__(GetMaxHarvestAmount(none), SeaSlugAdamPercentage)));
	theStack = LootContainer.GetItem(0);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x184
	/*@Error*/
	theStack.StackSize = 0;
	MaxHarvestAmount = float(theStack.StackSize);
	SeaSlug.PlayAnimationOnChannelFlatEaseIn(0, SeaSlugAnimation, 0.0000000, 8);
	SeaSlug.__NFUN_3970__(4);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyBeganGathering()
{
	IBooty(CurrentResource).NotifyBeganGathering();
	return;
	@NULL
	CommanderAction
}

function NotifyEndedGathering()
{
	IBooty(CurrentResource).NotifyEndedGathering();
	return;
	@NULL
	CommanderAction
}

function name GetBeginGatherAnimation()
{
	return BeginGatherAnimation;
	return;
	@NULL
}

function name GetLoopGatherAnimation()
{
	return LoopGatherAnimations[__NFUN_167__(LoopGatherAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function name GetEndGatherAnimation()
{
	return EndGatherAnimations[__NFUN_167__(EndGatherAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function name GetGestureFinishedFeedingAnimation()
{
	return GestureFinishedFeedingAnimations[__NFUN_167__(GestureFinishedFeedingAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function bool ShouldRotateAfterGatheringToFaceEscort()
{
	return Class'Engine.Pawn'.static.checkAlive(ProtectorEscort);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function name GetShockedAnimation()
{
	// End:0x25
	if(__NFUN_254__(AttachmentBone, 'None'))
	{
		return super(ShockAI).GetShockedAnimation();
		goto J0x2F;
		return 'None';
	}
	return;
	@NULL
	CommanderAction
}

function SetNextPanicPoint(Actor inNextPanicPoint)
{
	assert(__NFUN_119__(inNextPanicPoint, none));
	NextPanicPoint = inNextPanicPoint;
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function Actor GetNextPanicPoint()
{
	return NextPanicPoint;
	return;
	@NULL
}

function ClearNextPanicPoint()
{
	NextPanicPoint = none;
	return;
	@NULL
}

function ActivateGathererLookAtSensor()
{
	// End:0x28
	if(__NFUN_119__(GetGathererCommanderAction(), none))
	{
		GetGathererCommanderAction().ActivateGathererLookAtSensor();
	}
	return;
}

function DeactivateGathererLookAtSensor()
{
	// End:0x28
	if(__NFUN_119__(GetGathererCommanderAction(), none))
	{
		GetGathererCommanderAction().DeactivateGathererLookAtSensor();
	}
	return;
}

function AddSeenInterestingObject(Actor SeenInterestingObject)
{
	assert(__NFUN_129__(HasInterestingObjectBeenSeen(SeenInterestingObject)));
	SeenInterestingObjects[SeenInterestingObjects.Length] = SeenInterestingObject;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool HasInterestingObjectBeenSeen(Actor TestObject)
{
	//native.TestObject;	
	@NULL
}

function NotifyProtectorLookingAtTarget()
{
	// End:0x3A
	if(Class'Engine.Pawn'.static.checkAlive(ProtectorEscort))
	{
		ProtectorEscort.NotifyGathererLookingAtTarget();
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function NotifyProtectorTellingUsToStopLooking()
{
	// End:0x28
	if(__NFUN_119__(GetGathererCommanderAction(), none))
	{
		GetGathererCommanderAction().NotifyProtectorTellingUsToStopLooking();
	}
	return;
}

function NotifyProtectorFinishedLookingAtTarget()
{
	// End:0x3A
	if(Class'Engine.Pawn'.static.checkAlive(ProtectorEscort))
	{
		ProtectorEscort.NotifyGathererFinishedLookingAtTarget();
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function bool LootSlotLocked()
{
	return __NFUN_129__(ShockPawn(Level.GetLocalPlayerController().Pawn).HasMod('RosieLootSlotUnlocked_Exists'));
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function RollLoot(int slotNumber, LootSlot LootSlot, Object InOuter)
{
	local ItemStack Loot;

	super(BaseShockAI).RollLoot(slotNumber, LootSlot, InOuter);
	Loot = LootSlot.GetLoot();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xDD
	/*@Error*/
	__NFUN_159__(Loot.StackSize, ShockPawn(Level.GetLocalPlayerController().Pawn).ModifyStat('GathererCreditLoot_PercentBonus', 1.0000000));
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function bool ShouldBeHarvested()
{
	return false;
	return;
}

function SetSaveOrPacifyExternallyEnabled(bool inSaveOrPacifyExternallyEnabled)
{
	// End:0x68
	if(__NFUN_130__(__NFUN_130__(inSaveOrPacifyExternallyEnabled, __NFUN_129__(SaveOrPacifyExternallyEnabled)), __NFUN_129__(IsStunned())))
	{
		SaveOrPacifyExternallyEnabled = true;
		SpawningManager(Level.SpawningManager).IncrementLootableGatherers();
		SaveOrPacifyExternallyEnabled = inSaveOrPacifyExternallyEnabled;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
	@NULL
}

function bool IsSaveOrPacifyExternallyEnabled()
{
	return SaveOrPacifyExternallyEnabled;
	return;
	@NULL
}

function PlayerFinishedInteractingWithGatherer(ShockPlayer thePlayer, bool WasPacified)
{
	local float ADAMReceivedModifier;
	local Rotator RotationTowardsPlayer;

	UnTriggerEffectEvent('Stunned');
	// End:0x4D
	if(WasPacified)
	{
		IntentionallyPacified = true;
		LifeSpan = 0.0100000;
		ADAMReceivedModifier = 1.0000000;
		goto J0x112;
		RotationTowardsPlayer.Yaw = Rotator(__NFUN_216__(thePlayer.Location, Location)).Yaw;
	}
	__NFUN_299__(RotationTowardsPlayer);
	BecomeSaved();
	TriggerEffectEvent('MaterialSwap', none, none, Location, Rotation, false, false, none, GetCurrentMaterial(0).Name);
	ADAMReceivedModifier = SeaSlugAdamPercentage;
	MuteAI(false);
	thePlayer.GiveItemClass(int(__NFUN_171__(ADAMReceivedModifier, GetMaxHarvestAmount(none))), Class'ShockGame.ADAM');
	OnHarvestedAmount(GetMaxHarvestAmount(none));
	HasBeenSavedOrPacified = true;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function PlayerStartedInteractingWithGatherer(ShockPlayer thePlayer, bool WasPacified)
{
	MuteAI(true);
	return;
}

function PlayerInterruptedInteractingWithGatherer(ShockPlayer thePlayer, bool WasPacified)
{
	MuteAI(false);
	return;
}

function bool CanSaveOrPacify()
{
	return __NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_129__(HasBeenSavedOrPacified), IsAlive()), __NFUN_129__(bIsUnconscious)), __NFUN_132__(IsStunned(), SaveOrPacifyExternallyEnabled));
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function bool CanBeUsedNow()
{
	return CanSaveOrPacify();
	return;
}

function OnUsed(Pawn Pawn)
{
	AssertWithDescription(Pawn.__NFUN_303__('ShockPlayer'), __NFUN_112__(string(Class.Name), " was used by someone other than a ShockPlayer."));
	// End:0x9F
	if(IsAlive())
	{
		ShockPlayer(Pawn).BeginExorcisingGatherer(self, false);
		goto J0xB2;
		super(ShockAI).OnUsed(Pawn);
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function bool IsHacked()
{
	return __NFUN_129__(IsAlive());
	return;
}

function bool CanBeHackedNow(ShockPlayer Player)
{
	return __NFUN_130__(CanSaveOrPacify(), __NFUN_129__(Level.bIsDLC1Level));
	return;
	@NULL
	CommanderAction
}

function OnHackAttempted(ShockPlayer Player)
{
	Player.BeginExorcisingGatherer(self, true);
	return;
	@NULL
}

function HackInfo GetHackInfo()
{
	return none;
	return;
}

function string GetHackVerbText()
{
	return Class'ShockGame.ShockPlayerController'.default.PacifyText;
	return;
	@NULL
	CommanderAction
}

function HackInfo OnHackSucceeded(ShockPlayer Player, string HackResult)
{
	return none;
	return;
}

function HackInfo OnHackFailed(ShockPlayer Player, string HackResult)
{
	return none;
	return;
}

function IPotentialAimOrActionTarget.TargetType GetTargetType()
{
	// End:0x13
	if(CanBeUsedNow())
	{
		return 1;		
	}
	else
	{
		return 0;
	}
	return;
}

function bool ActionBlockedByPawns()
{
	return false;
	return;
}

defaultproperties
{
	SeaSlugAnimation="Slugfish_anim_thrash"
	SeaSlugAdamPercentage=0.5000000
	VulnerableState=1
	PseudoGathererEquipAnimationName="GA_S_StartGatherGun"
	PseudoGathererLoopAnimationName="GA_S_LoopGatherGun"
	PseudoGathererUnEquipAnimationName="GA_S_EndGatherGun"
	PseudoGathererSocket="GathererAttach"
	PseudoGathererClass=Class'ShockGame.PseudoGatherer'
	UseVerbText="Rescue"
	FlailingAnimations[0]="GA_ThrownInAirLoop"
	bOptimizeAIPhysicsAtLowDetail=true
	OptimizedPhysicsWalkSpeed=200.0000000
	OptimizedPhysicsRunSpeed=400.0000000
	bPlayAnimationInsteadOfRagdollFall=true
	bDropToGroundUponSpawning=false
	ReachedDestinationUpThresholdFudge=41.0000000
	ReachedDestinationDownThresholdFudge=20.0000000
	ShadowMapScale=2.0000000
	Physics=3
	bHidden=true
	bAcceptsProjectors=false
	CollisionHeight=45.0000000
	bCollideWorld=false
	bBlockPlayers=false
	bRotateToDesired=false
}