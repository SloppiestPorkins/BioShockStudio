class Hands extends Actor
	native
	config(Weapons)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

const kUseAbilityAnimationChannel = 1;
const kHandBobAnimationChannel = 2;
const kDefaultAnimationChannel = 0;

struct native atomic StateTransitionSequence
{
	var name InterruptionLabel;
	var array<name> StateNames;
	var int NextStateIndex;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

var private travel ShockPawn PawnOwner;
var private transient Ability CurrentAbility;
var private transient Ability OldAbility;
var private Holdable CurrentHoldable;
var private travel name UseAbilityAnimation;
var private const config Class<Item> BioAmmoClass;
var private config Vector PlayerViewOffset;
var private config Vector PlayerViewOffsetWidescreen;
var private config float WeaponBobDamping;
var private config float PreferredHarvestInterval;
var private bool bUsingGathererTool;
var private config float ProceduralLoweringTime;
var private config bool ShouldClearAbilityEffectsInWeaponsMode;
var private travel bool bIsInWeaponMode;
var private bool ShouldDisplayTargetIndicator;
var private bool bNeedleInserted;
var config name HandsOffscreenAnimationName;
var config name GenericEquippingAbilityAnimationName;
var config name GenericUnEquippingAbilityAnimationName;
var config name GenericIdlingAbilityAnimationName;
var config name InjectingEveAnimationName;
var config name UsingGathererToolEquipAnimationName;
var config name UsingGathererToolLoopAnimationName;
var config name UsingGathererToolUnEquipAnimationName;
var config name ExorcisingGathererAnimationName;
var config name ExorcisingPseudoGathererAnimationName;
var config name PacifyingGathererAnimationName;
var config name PacifyingPseudoGathererAnimationName;
var bool IsPacifyingGatherer;
var config float HarvestingAdamCollectionTime;
var private Actor PacifyingSeaSlug;
var private Actor SavingSeaSlug;
var private config Class<Actor> PacifyingSeaSlugClass;
var private config Class<Actor> SavingSeaSlugClass;
var private config name PacifyingSeaSlugSocket;
var private config name SavingSeaSlugSocket;
var private config name PacifyingSeaSlugAnimationName;
var private config name PacifyingSeaSlugHandAnimationName;
var private config name SavingSeaSlugAnimationName;
var private config name SavingSeaSlugHandAnimationName;
var config name PseudoGathererSocket;
var config name GathererToolSocket;
var config name BioAmmoHypoToolSocket;
var private name CurrentScriptedAnimationName;
var private PseudoGatherer PseudoGatherer;
var private GathererTool GathererTool;
var private BioAmmoHypoTool BioAmmoHypoTool;
var Actor ScriptedAttachment;
var int ScriptedHandsAnimationHandle;
var int ScriptedAttachmentAnimationHandle;
var private int PseudoGathererAnimationHandle;
var private int ToolAnimationHandle;
var private int HandsAnimationHandle;
var private int HolderAnimationHandle;
var private int WeaponAnimationHandle;
var private int AltFireAttachmentAnimationHandle;
var private int StrictlySuperiorAttachmentAnimationHandle;
var private bool bFinishedStateAnimations;
var private bool AbilityHasBeenReleased;
var private bool CurrentlyExecutingScriptedHandAnimationSequence;
var private float AbilityPendingFirePressedTime;
var private bool AbilityPendingFireReleased;
var private float LastAbilityFiredTime;
var private config float ZoomedLookModifier;
var private StateTransitionSequence CurrentTransitionSequence;
var private config name DamageEmitterSocket;
var private DamageEmitter CurrentDamageEmitter;
var travel array<name> PersistentEffectsSystemContexts;
var private const noexport transient TMap_Padding StateTransitionMap;

function AddPersistentEffectsSystemContext(name Context)
{
	local int i;

	i = 0;
	// End:0x54
	if(__NFUN_150__(i, PersistentEffectsSystemContexts.Length))
	{
		// End:0x46
		if(__NFUN_254__(PersistentEffectsSystemContexts[i], Context))
		{
			return;
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x0B;
			PersistentEffectsSystemContexts[PersistentEffectsSystemContexts.Length] = Context;
		}
		return;
		@NULL
		Item
	}
	Item
	@NULL
}

function RemovePersistentEffectsSystemContext(name Context)
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
	PersistentEffectsSystemContexts.Remove(i, 1);
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

function ShockPawn GetOwner()
{
	return PawnOwner;
	return;
	@NULL
}

function Ability GetCurrentAbility()
{
	return CurrentAbility;
	return;
	@NULL
}

function bool InWeaponsMode()
{
	return bIsInWeaponMode;
	return;
	@NULL
}

function SetHandsMode(name NewMode)
{
	// End:0x66
	if(__NFUN_129__(bHidden))
	{
		Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodString("SetActiveHands", string(NewMode));
		// End:0x8C
		if(__NFUN_254__(NewMode, 'Weapon'))
		{
		}
		bIsInWeaponMode = true;
		goto J0xAF;
		// End:0xAF
		if(__NFUN_254__(NewMode, 'Ability'))
		{
			bIsInWeaponMode = false;
		}
		ShockPlayerController(PawnOwner.Controller).GetPlayerStatsManager().HandsModeChanged(NewMode);
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function PostBeginPlay()
{
	super.PostBeginPlay();
	AssertWithDescription(__NFUN_255__(Level.Label, 'None'), "Every level must have its label set. The current level's label is None.");
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x110
	/*@Error*/
	GathererTool = __NFUN_278__(Class'ShockGame.GathererTool');
	GathererTool.DrawPriority = 1;
	GathererTool.UpdateRenderRevision();
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function PreLevelTravel()
{
	super.PreLevelTravel();
	// End:0x23
	if(__NFUN_119__(OldAbility, none))
	{
		SetAbilityEffects();
		// End:0x5A
		if(__NFUN_119__(CurrentAbility, none))
		{
		}
		OldAbility = CurrentAbility;
		CurrentAbility = none;
		SetAbilityEffects();
		HandsAnimationHandle = PlayAnimationOnChannelInstantEaseIn(0, HandsOffscreenAnimationName, 4);
		StopAnimation(HandsAnimationHandle);
	}
	__NFUN_113__('HandsOffscreen');
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function TravelPostAccept()
{
	super.TravelPostAccept();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x9C
	/*@Error*/
	GathererTool = __NFUN_278__(Class'ShockGame.GathererTool');
	GathererTool.DrawPriority = 1;
	GathererTool.UpdateRenderRevision();
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function UpdateLocation()
{
	local Vector NewLocation;
	local Rotator NewRotation;
	local Vector totalOffset;
	local PlayerController PC;

	// End:0x11
	if(__NFUN_114__(PawnOwner, none))
	{
		return;
		NewRotation = PawnOwner.GetViewRotation();
	}
	PC = PlayerController(PawnOwner.Controller);
	// End:0xA8
	if(__NFUN_130__(__NFUN_119__(PC, none), PC.IsWidescreen))
	{
		totalOffset = __NFUN_276__(PlayerViewOffsetWidescreen, NewRotation);
		goto J0xC7;
		totalOffset = __NFUN_276__(PlayerViewOffset, NewRotation);
		__NFUN_184__(totalOffset.Z, PawnOwner.EyeHeight);
		NewLocation = __NFUN_215__(__NFUN_215__(PawnOwner.Location, totalOffset), ShockPlayer(PawnOwner).ViewLocationOffset(NewRotation));
	}
	__NFUN_267__(NewLocation);
	__NFUN_299__(NewRotation);
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function PlayHandBobAnimation(name AnimName)
{
	local bool bAnimIsAdditive;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xBF
	/*@Error*/
	bAnimIsAdditive = IsAnimationAdditive(AnimName);
	AssertWithDescription(bAnimIsAdditive, __NFUN_112__(__NFUN_112__("Hand-bob animation '", string(AnimName)), "' is not additive and will not be played"));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xBC
	/*@Error*/
	PlayAnimationOnChannel(2, AnimName, 8);
	goto J0xDA;
	FlatEaseOutAnimation(GetAnimationOnChannel(2), 0.2000000);
	return;
	@NULL
	Item
	Item
	@NULL
}

function UpdateHandBobAnimationParameters()
{
	local int AnimHandle;
	local float MovementRateRelativeToDefault;

	AnimHandle = GetAnimationOnChannel(2);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x97
	/*@Error*/
	MovementRateRelativeToDefault = __NFUN_172__(__NFUN_225__(PawnOwner.Velocity), Class'Engine.Pawn'.default.GroundSpeed);
	SetAnimationPlaybackRate(AnimHandle, MovementRateRelativeToDefault);
	SetAnimationWeight(AnimHandle, MovementRateRelativeToDefault);
	return;
	@NULL
	Item
	Item
	@NULL
}

event UpdateHandValues(float DeltaTime)
{
	UpdateLocation();
	UpdateHandBobAnimationParameters();
	return;
}

function OnEquippingStarted(Holdable theHoldable)
{
	log('Hands', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::OnEquippingStarted( "), string(theHoldable)), " )"));
	AttachToBone(theHoldable, theHoldable.GetAttachBone(PawnOwner));
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnUnEquippingFinished(Holdable theHoldable)
{
	log('Hands', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::OnUnEquippingFinished( "), string(theHoldable)), " )"));
	DetachFromBone(theHoldable);
	return;
	@NULL
	Item
	Item
}

function SetActiveAbility(Ability inAbility)
{
	log('Hands', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::SetActiveAbility( "), string(inAbility)), " )"));
	// End:0x60
	if(__NFUN_114__(OldAbility, none))
	{
		OldAbility = CurrentAbility;
		CurrentAbility = inAbility;
		UpdateAbilityUsability();
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool CanChangeActiveAbility()
{
	return CanExecuteAction('EquipUsableAbility');
	return;
}

function SetAbilityEffects()
{
	log('Hands', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::SetAbilityEffects() ... OldAbility = "), string(OldAbility)), ", CurrentAbility = "), string(CurrentAbility)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x295
	/*@Error*/
	// End:0x172
	if(__NFUN_130__(__NFUN_119__(OldAbility, none), OldAbility.AbilityEffectsTriggered))
	{
		UnTriggerEffectEvent('SelectedAbility', OldAbility.Class.Name);
		RemovePersistentContext(OldAbility.Class.Name);
		// End:0x159
		if(__NFUN_119__(OldAbility.TargetIndicatorClass, none))
		{
			ShockPlayer(PawnOwner).ClearTargetIndicator();
			OldAbility.AbilityEffectsTriggered = false;
			OldAbility = none;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x295
			/*@Error*/
			CurrentAbility.AbilityEffectsTriggered = true;
		}
		AddPersistentContext(CurrentAbility.Class.Name);
	}
	TriggerEffectEvent('SelectedAbility',,,,,,,, CurrentAbility.Class.Name);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x295
	/*@Error*/
	ShockPlayer(PawnOwner).SetTargetIndicator(CurrentAbility.TargetIndicatorClass, CurrentAbility.TargetIndicatorOffset);
	return;
	@NULL
	Item
	Item
	@NULL
}

function UpdateAbilityUsability(optional bool DontReTransitionToUnUsable)
{
	// End:0x67
	if(__NFUN_119__(CurrentAbility, none))
	{
		// End:0x3B
		if(IsAbilityUsable(CurrentAbility))
		{
			ExecuteStateTransition('EquipUsableAbility');
			goto J0x67;
			// End:0x67
			if(__NFUN_129__(DontReTransitionToUnUsable))
			{
			}
			SetAbilityEffects();
			ExecuteStateTransition('EquipUnUsableAbility');
			return;
			@NULL
			Item
		}
	}
	J0x67:

	stop;
	default.@NULL
}

function bool IsAbilityUsable(Ability inAbility)
{
	return __NFUN_132__(__NFUN_130__(__NFUN_119__(inAbility, none), __NFUN_180__(inAbility.GetBioAmmoCost(ShockPlayer(PawnOwner)), float(0))), __NFUN_177__(ShockPlayer(PawnOwner).GetBioAmmo(), float(0)));
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function PostLoadGame()
{
	local name StateName;

	CheckForActiveAbility();
	StateName = __NFUN_284__();
	// End:0xF3
	if(__NFUN_132__(__NFUN_132__(__NFUN_132__(__NFUN_132__(__NFUN_132__(__NFUN_132__(__NFUN_132__(__NFUN_254__(StateName, 'WeaponEquipping'), __NFUN_254__(StateName, 'WeaponUnEquipping')), __NFUN_254__(StateName, 'WeaponIdling')), __NFUN_254__(StateName, 'WeaponFiring')), __NFUN_254__(StateName, 'WeaponReloading')), __NFUN_254__(StateName, 'ProceduralWeaponReloading')), __NFUN_254__(StateName, 'WeaponZoomedIdling')), __NFUN_254__(StateName, 'WeaponZoomedFiring')))
	{
		SetHandsMode('Weapon');
		goto J0x106;
		SetHandsMode('Ability');
		super.PostLoadGame();
		return;
		@NULL
		Item
	}
	stop;
	default.@NULL
}

function CheckForActiveAbility()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x50
	/*@Error*/
	CurrentAbility = ShockPlayer(PawnOwner).GetActiveAbility();
	return;
	@NULL
	Item
	Item
	@NULL
}

function UseActiveAbility(optional bool doNotModifyAbilityPendingFireReleased)
{
	// End:0x1B
	if(__NFUN_129__(doNotModifyAbilityPendingFireReleased))
	{
		AbilityPendingFireReleased = false;
		// End:0x3B
		if(__NFUN_132__(__NFUN_114__(CurrentAbility, none), bIsInWeaponMode))
		{
		}
		return;
		// End:0x12B
		if(CanExecuteAction('FireAbility'))
		{
		}
		// End:0xDC
		if(CurrentAbility.CanUseAbility(ShockPlayer(PawnOwner)))
		{
			LastAbilityFiredTime = Level.TimeSeconds;
			CurrentAbility.StartedUsingAbility(ShockPlayer(PawnOwner));
			ExecuteStateTransition('FireAbility');
			goto J0x119;
			TriggerEffectEvent('FailedToUseAbility',,,,,,,, CurrentAbility.Class.Name);
			AbilityPendingFirePressedTime = 0.0000000;
		}
		goto J0x1B4;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x168
		/*@Error*/
		AbilityPendingFirePressedTime = Level.TimeSeconds;
		goto J0x1B4;
		TriggerEffectEvent('FailedToUseAbility',,,,,,,, CurrentAbility.Class.Name);
	}
	AbilityPendingFirePressedTime = 0.0000000;
	return;
	@NULL
	Item
	Item
	@NULL
}

function UseActiveAbilityRelease()
{
	// End:0x1F
	if(__NFUN_177__(AbilityPendingFirePressedTime, 0.0000000))
	{
		AbilityPendingFireReleased = true;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xE1
		/*@Error*/
	}
	// End:0xA4
	if(CurrentAbility.CanUseAbilityOnRelease(ShockPlayer(PawnOwner)))
	{
		CurrentAbility.UseAbilityRelease(ShockPlayer(PawnOwner));
		goto J0xE1;
		TriggerEffectEvent('FailedToUseAbility',,,,,,,, CurrentAbility.Class.Name);
	}
	AbilityHasBeenReleased = true;
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnSpawnedDamageEmitter(DamageEmitter Emitter)
{
	// End:0x9A
	if(__NFUN_119__(CurrentDamageEmitter, none))
	{
		log('Weapons', 3, __NFUN_112__(string(self.Name), " already has an emitter and is trying to add another one.  Removing old emitter."));
		CurrentDamageEmitter.Kill();
		CurrentDamageEmitter = Emitter;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xE0
		/*@Error*/
	}
	AttachToBone(CurrentDamageEmitter, DamageEmitterSocket);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function OnUsingActiveAbilityStarted()
{
	log('Ability', 4, __NFUN_112__(string(self), "::OnUsingActiveAbilityStarted()"));
	ShockPlayer(PawnOwner).TriggerEffectEvent('BeganUsingAbility',,,,,,,, CurrentAbility.Class.Name);
	ShockPlayer(PawnOwner).OnUsingActiveAbilityStarted();
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnUsingActiveAbilityFinished()
{
	log('Ability', 4, __NFUN_112__(string(self), "::OnUsingActiveAbilityFinished()"));
	ShockPlayer(PawnOwner).UnTriggerEffectEvent('BeganUsingAbility', CurrentAbility.Class.Name);
	ShockPlayer(PawnOwner).OnUsingActiveAbilityFinished();
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnCompletedHarvestingAdam()
{
	log('Hands', 4, __NFUN_112__(string(self), "::OnCompletedHarvestingAdam()"));
	ShockPlayer(PawnOwner).OnCompletedHarvestingAdam();
	return;
	@NULL
	Item
}

function OnCompletedExorcisingGatherer()
{
	log('Hands', 4, __NFUN_112__(string(self), "::OnCompletedExorcisingGatherer()"));
	ShockPlayer(PawnOwner).OnCompletedExorcisingGatherer(IsPacifyingGatherer);
	return;
	@NULL
	Item
	Item
}

function OnStartedInteractingWithGatherer(bool bSaving)
{
	assert(__NFUN_242__(bSaving, __NFUN_129__(IsPacifyingGatherer)));
	return;
	@NULL
	Item
}

function OnFinishedInteractingWithGatherer(bool bSaving)
{
	assert(__NFUN_242__(bSaving, __NFUN_129__(IsPacifyingGatherer)));
	OnCompletedExorcisingGatherer();
	return;
	@NULL
	Item
}

function OnCompletedInjectingEve()
{
	log('Hands', 4, __NFUN_112__(string(self), "::OnCompletedInjectingEve()"));
	ShockPlayer(PawnOwner).OnCompletedInjectingEve();
	return;
	@NULL
	Item
}

function UseCurrentAbility()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x92
	/*@Error*/
	TriggerEffectEvent('UsedAbility',,,,,,,, CurrentAbility.Class.Name);
	CurrentAbility.UseAbility(ShockPlayer(PawnOwner));
	return;
	@NULL
	Item
	Item
	@NULL
}

function FadeFOV(float StartFOV, float StopFOV, float StartForegroundFOV, float StopForegroundFOV)
{
	local float ZoomStartTime, ZoomStopTime, Alpha;

	ZoomStartTime = Level.TimeSeconds;
	ZoomStopTime = __NFUN_174__(GetAnimationLength(PlayerWeapon(CurrentHoldable).GetZoomingInHandsAnim()), ZoomStartTime);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x17D
	/*@Error*/
	Alpha = __NFUN_172__(__NFUN_175__(Level.TimeSeconds, ZoomStartTime), __NFUN_175__(ZoomStopTime, ZoomStartTime));
	PlayerController(PawnOwner.Controller).DesiredFOV = __NFUN_174__(StartFOV, __NFUN_171__(Alpha, __NFUN_175__(StopFOV, StartFOV)));
	PlayerController(PawnOwner.Controller).ForegroundFovAngle = __NFUN_174__(StartForegroundFOV, __NFUN_171__(Alpha, __NFUN_175__(StopForegroundFOV, StartForegroundFOV)));
	__NFUN_256__(0.0000000);
	// [Loop Continue]
	goto J0x5F;
	PlayerController(PawnOwner.Controller).DesiredFOV = StopFOV;
	PlayerController(PawnOwner.Controller).ForegroundFovAngle = StopForegroundFOV;
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function PlayAndFinishHandsAnimation(name AnimationName)
{
	bFinishedStateAnimations = false;
	HandsAnimationHandle = PlayAnimationOnChannelInstantEaseIn(0, AnimationName, 4);
	FinishAnimation(HandsAnimationHandle);
	bFinishedStateAnimations = true;
	return;
	@NULL
	Collectable
	ShockPawn
	@NULL
}

function HarvestAdam()
{
	local float MaxTime, CurrentHarvest, MaxHarvest, CurrentHarvestTime, AmountToHarvestPerInterval, HarvestInterval;

	local ICanBeHarvested HarvestTarget;

	HarvestTarget = ShockPlayer(PawnOwner).GetHarvestingTarget();
	MaxTime = HarvestTarget.GetHarvestingTime(self);
	MaxHarvest = HarvestTarget.GetMaxHarvestAmount(self);
	CurrentHarvest = HarvestTarget.GetCurrentHarvestAmount(self);
	AmountToHarvestPerInterval = __NFUN_172__(__NFUN_171__(MaxHarvest, PreferredHarvestInterval), MaxTime);
	AmountToHarvestPerInterval = float(int(__NFUN_174__(AmountToHarvestPerInterval, float(1))));
	HarvestInterval = __NFUN_172__(__NFUN_171__(MaxTime, AmountToHarvestPerInterval), MaxHarvest);
	CurrentHarvestTime = __NFUN_172__(__NFUN_171__(MaxTime, CurrentHarvest), MaxHarvest);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x18A
	/*@Error*/
	__NFUN_256__(HarvestInterval);
	__NFUN_184__(CurrentHarvestTime, HarvestInterval);
	ShockPlayer(PawnOwner).HarvestTarget(AmountToHarvestPerInterval);
	goto J0x127;
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function SetCurrentTransitionSequence(name Action)
{
	//native.Action;	
	@NULL
}

function bool CanExecuteAction(name Action)
{
	//native.Action;	
	@NULL
}

function InterruptAnimNotifiesForAnimation(name AnimationName)
{
	//native.AnimationName;	
	@NULL
}

function ExecuteStateTransition(name Action)
{
	log('Hands', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::ExecuteStateTransition( "), string(Action)), " )"));
	// End:0x120
	if(__NFUN_130__(CanExecuteAction(Action), __NFUN_129__(CurrentlyExecutingScriptedHandAnimationSequence)))
	{
		SetCurrentTransitionSequence(Action);
		// End:0x11D
		if(__NFUN_153__(CurrentTransitionSequence.NextStateIndex, 0))
		{
			// End:0xD3
			if(__NFUN_254__(CurrentTransitionSequence.InterruptionLabel, 'End'))
			{
				TransitionToNextStateInSequence();
				goto J0x11D;
				// End:0x11D
				if(__NFUN_255__(CurrentTransitionSequence.InterruptionLabel, 'None'))
				{
					__NFUN_113__(__NFUN_284__(), CurrentTransitionSequence.InterruptionLabel);
				}
				goto J0x11D;
				goto J0x17D;
				log('Hands', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), " UNABLE to execute action '"), string(Action)), "' from state '"), string(__NFUN_284__())), "'"));
			}
		}
	}
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function TransitionToNextStateInSequence()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x177
	/*@Error*/
	log('Hands', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::TransitionToNextStateInSequence()...  CurrentTransitionSequence.StateNames[ "), string(CurrentTransitionSequence.NextStateIndex)), " ] = "), string(CurrentTransitionSequence.StateNames[CurrentTransitionSequence.NextStateIndex])));
	__NFUN_165__(CurrentTransitionSequence.NextStateIndex);
	__NFUN_113__(CurrentTransitionSequence.StateNames[__NFUN_147__(CurrentTransitionSequence.NextStateIndex, 1)]);
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function InterruptStateTransitionExecution()
{
	CurrentTransitionSequence.NextStateIndex = -1;
	__NFUN_113__('HandsOffscreen');
	return;
	@NULL
	Item
	Item
}

function EquipWeapon()
{
	ExecuteStateTransition('EquipWeapon');
	return;
}

function UnEquipWeapon()
{
	ExecuteStateTransition('UnEquipWeapon');
	return;
}

function FireWeapon()
{
	ExecuteStateTransition('FireWeapon');
	return;
}

function ReloadWeapon()
{
	ExecuteStateTransition('ReloadWeapon');
	return;
}

function UseBioAmmoHypo()
{
	ExecuteStateTransition('UseEveHypo');
	return;
}

function bool UseGathererTool()
{
	// End:0x3A
	if(CanExecuteAction('UseGathererTool'))
	{
		bUsingGathererTool = true;
		ExecuteStateTransition('UseGathererTool');
		return true;
		goto J0x3C;
		return false;
		return;
	}
	@NULL
}

function StopUsingGathererTool()
{
	bUsingGathererTool = false;
	ShockPlayer(PawnOwner).ResetCurrentHandMode();
	return;
	@NULL
	Item
	Item
}

function GathererTool GetGathererTool()
{
	return GathererTool;
	return;
	@NULL
}

function ExorciseGatherer(BaseShockAI theGatherer, bool PacifyHer)
{
	IsPacifyingGatherer = PacifyHer;
	// End:0x6A
	if(__NFUN_114__(PseudoGatherer, none))
	{
		PseudoGatherer = __NFUN_278__(Class'ShockGame.PseudoGatherer');
		PseudoGatherer.DrawPriority = 1;
		PseudoGatherer.UpdateRenderRevision();
		PseudoGatherer.TriggerEffectEvent('MaterialSwap', none, none, Location, Rotation, false, false, none, theGatherer.GetCurrentMaterial(0).Name);
	}
	ExecuteStateTransition('ExorciseGatherer');
	return;
	@NULL
	Item
	Item
	@NULL
}

function ToggleZoom()
{
	// End:0x2C
	if(CanExecuteAction('UnZoomWeapon'))
	{
		ExecuteStateTransition('UnZoomWeapon');		
	}
	else
	{
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xA2
		/*@Error*/
		ExecuteStateTransition('ZoomWeapon');
		return;
		@NULL
		Item
		Item
		@NULL
	}
}

function FinishAbilityFiring()
{
	// End:0x5D
	if(__NFUN_132__(IsAbilityUsable(CurrentAbility), __NFUN_155__(ShockPlayer(PawnOwner).GetNumberOfItems(BioAmmoClass), 0)))
	{
		ExecuteStateTransition('FinishAbilityFiringWithEve');
		goto J0x70;
		ExecuteStateTransition('FinishAbilityFiringWithoutEve');
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function StartScriptedHandAnimationSequence()
{
	ExecuteStateTransition('PlayScriptedHandAnimation');
	CurrentlyExecutingScriptedHandAnimationSequence = true;
	return;
	@NULL
}

function StopScriptedHandAnimationSequence()
{
	RemoveScriptedHandAttachment();
	CurrentlyExecutingScriptedHandAnimationSequence = false;
	ShockPlayer(PawnOwner).ResetCurrentHandMode();
	return;
	@NULL
	Item
	Item
}

function PlayScriptedHandAnimation(name ScriptedHandsAnimation, name ScriptedAttachmentAnimation, int AnimationEndBehavior, float EaseIn)
{
	// End:0x47
	if(__NFUN_255__(ScriptedHandsAnimation, 'None'))
	{
		ScriptedHandsAnimationHandle = PlayAnimationOnChannelFlatEaseIn(0, ScriptedHandsAnimation, EaseIn, AnimationEndBehavior);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xAC
		/*@Error*/
	}
	ScriptedAttachmentAnimationHandle = ScriptedAttachment.PlayAnimationOnChannelFlatEaseIn(0, ScriptedAttachmentAnimation, EaseIn, AnimationEndBehavior);
	return;
	@NULL
	Item
	Item
	@NULL
}

function ApplyScriptedHandAttachment(Class<Actor> AttachmentClass, name AttachmentBone)
{
	RemoveScriptedHandAttachment();
	ScriptedAttachment = __NFUN_278__(AttachmentClass);
	AttachToBone(ScriptedAttachment, AttachmentBone);
	ScriptedAttachment.DrawPriority = 1;
	ScriptedAttachment.UpdateRenderRevision();
	return;
	@NULL
	Item
	Item
	@NULL
}

function RemoveScriptedHandAttachment()
{
	// End:0x32
	if(__NFUN_119__(ScriptedAttachment, none))
	{
		DetachFromBone(ScriptedAttachment);
		ScriptedAttachment.__NFUN_279__();
		ScriptedAttachment = none;
		return;
		@NULL
		Item
	}
	Item
	@NULL
}

state TransitionalState
{	stop;
}

state ProceduralLoweringHands extends TransitionalState
{Begin:

	PauseAnimation(HandsAnimationHandle);
	HandsAnimationHandle = PlayAnimationOnChannelFlatEaseIn(0, HandsOffscreenAnimationName, ProceduralLoweringTime, 8);
	assert(IsAnimationHandleValid(HandsAnimationHandle));
	// End:0x75
	if(__NFUN_129__(IsAnimationEntirelyFlatEasedIn(HandsAnimationHandle)))
	{
		__NFUN_256__(0.0000000);
		goto J0x52;
		// End:0xB9
		if(__NFUN_130__(__NFUN_119__(CurrentHoldable, none), __NFUN_129__(CurrentHoldable.bHidden)))
		{
			CurrentHoldable.HideHoldable();
		}
		TransitionToNextStateInSequence();
		stop;								
		@NULL
	}
End:


	// BadToken (0x03)
	@NULL
	@NULL
	Holdable
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

auto state HandsOffscreen
{End:

	TransitionToNextStateInSequence();
	stop;	
}

state WeaponEquipping extends TransitionalState
{
	ignores EndState, BeginState;
Begin:

	bFinishedStateAnimations = false;
	HandsAnimationHandle = PlayAnimationOnChannelInstantEaseIn(0, CurrentHoldable.GetEquippingHandsAnim(), 4);
	WeaponAnimationHandle = CurrentHoldable.PlayAnimationOnChannelInstantEaseIn(0, CurrentHoldable.GetEquippingAnim(), 4);
	FinishAnimation(HandsAnimationHandle);
	FinishAnimation(WeaponAnimationHandle);
	bFinishedStateAnimations = true;
	TransitionToNextStateInSequence();
	stop;		
	@NULL
	// BadToken (0x03)
	@NULL
	@NULL
	Holdable
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

state WeaponUnEquipping extends TransitionalState
{
	ignores EndState, BeginState;
Begin:

	bFinishedStateAnimations = false;
	HandsAnimationHandle = PlayAnimationOnChannelInstantEaseIn(0, CurrentHoldable.GetUnEquippingHandsAnim(), 4);
	WeaponAnimationHandle = CurrentHoldable.PlayAnimationOnChannelInstantEaseIn(0, CurrentHoldable.GetUnEquippingAnim(), 4);
	FinishAnimation(HandsAnimationHandle);
	FinishAnimation(WeaponAnimationHandle);
	bFinishedStateAnimations = true;
	TransitionToNextStateInSequence();
	stop;		
	@NULL
	// BadToken (0x03)
	@NULL
	@NULL
	Holdable
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

state WeaponIdling extends TransitionalState
{Begin:

	SetHandsMode('Weapon');
End:


	TransitionToNextStateInSequence();
	CurrentHoldable = PawnOwner.GetActiveHoldable();
	WeaponAnimationHandle = CurrentHoldable.PlayAnimationOnChannelInstantEaseIn(0, CurrentHoldable.GetIdlingAnim(), 8);
	Weapon(CurrentHoldable).PlayIdleAnimations();
	// End:0x11D
	if(__NFUN_255__(CurrentHoldable.GetIdlingHandsAnim(), 'None'))
	{
		// End:0x11D
		if(true)
		{
			HandsAnimationHandle = PlayAnimationOnChannelFlatEaseIn(0, CurrentHoldable.GetIdlingHandsAnim(), CurrentHoldable.GetIdlingHandsAnimTweenTime(), 4);
			FinishAnimation(HandsAnimationHandle);
			// [Loop Continue]
			goto J0xBE;
			stop;						
			@NULL
			// BadToken (0x03)
			@NULL
			@NULL
			Holdable
		}
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

state WeaponFiring extends TransitionalState
{
	ignores EndState;
Begin:

	SetHandsMode('Weapon');
	CurrentHoldable = PawnOwner.GetActiveHoldable();
	bFinishedStateAnimations = false;
	PlayerWeapon(CurrentHoldable).ZoomedFiring = false;
	Weapon(CurrentHoldable).PlayWeaponFiringAnimations();
	bFinishedStateAnimations = true;
	TransitionToNextStateInSequence();
	stop;			
	@NULL
	// BadToken (0x03)
	@NULL
	@NULL
	Holdable
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

state PostWeaponFiring extends TransitionalState
{Begin:

	// End:0x38
	if(__NFUN_119__(PlayerWeapon(CurrentHoldable), none))
	{
		PlayerWeapon(CurrentHoldable).PostFired();
		TransitionToNextStateInSequence();
		stop;		
	}
	@NULL
	// BadToken (0x03)
	@NULL
	@NULL
}

state PostWeaponZoomedFiring extends TransitionalState
{Begin:

	// End:0x38
	if(__NFUN_119__(PlayerWeapon(CurrentHoldable), none))
	{
		PlayerWeapon(CurrentHoldable).PostFired();
		TransitionToNextStateInSequence();
		stop;		
	}
	@NULL
	// BadToken (0x03)
	@NULL
	@NULL
}

state WeaponReloading extends TransitionalState
{
	ignores EndState, BeginState;
Begin:

	SetHandsMode('Weapon');
	CurrentHoldable = PawnOwner.GetActiveHoldable();
	bFinishedStateAnimations = false;
	Weapon(CurrentHoldable).PlayReloadingAnimations();
	FinishAnimation(HandsAnimationHandle);
	FinishAnimation(WeaponAnimationHandle);
	bFinishedStateAnimations = true;
	TransitionToNextStateInSequence();
	stop;			
	@NULL
	// BadToken (0x03)
	@NULL
	@NULL
	Holdable
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

state ProceduralWeaponReloading extends TransitionalState
{
	ignores EndState;
Begin:

	SetHandsMode('Weapon');
	CurrentHoldable = PawnOwner.GetActiveHoldable();
	// End:0x76
	if(__NFUN_130__(__NFUN_119__(CurrentHoldable, none), CurrentHoldable.bHidden))
	{
		CurrentHoldable.UnHideHoldable();
		bFinishedStateAnimations = false;
		Weapon(CurrentHoldable).PlayReloadingAnimations(0.0000000);
	}
	FinishAnimation(HandsAnimationHandle);
	FinishAnimation(WeaponAnimationHandle);
	bFinishedStateAnimations = true;
	TransitionToNextStateInSequence();
	stop;				
	@NULL
End:


	// BadToken (0x03)
	@NULL
	@NULL
	Holdable
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

state WeaponZoomingIn extends TransitionalState
{
	ignores EndState, BeginState;
Begin:

	bFinishedStateAnimations = false;
	HandsAnimationHandle = PlayAnimationOnChannelInstantEaseIn(0, PlayerWeapon(CurrentHoldable).GetZoomingInHandsAnim(), 4);
	FadeFOV(PlayerController(PawnOwner.Controller).DefaultFOV, PlayerWeapon(CurrentHoldable).ZoomedFOVAngle, PlayerController(PawnOwner.Controller).ForegroundFovAngle, PlayerWeapon(CurrentHoldable).ZoomedForegroundFOVAngle);
	FinishAnimation(HandsAnimationHandle);
	bFinishedStateAnimations = true;
	TransitionToNextStateInSequence();
	stop;			
	@NULL
	// BadToken (0x03)
	@NULL
	@NULL
	Holdable
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/;
}

state WeaponZoomingOut extends TransitionalState
{
	ignores EndState, BeginState;
Begin:

	bFinishedStateAnimations = false;
	HandsAnimationHandle = PlayAnimationOnChannelInstantEaseIn(0, PlayerWeapon(CurrentHoldable).GetZoomingOutHandsAnim(), 4);
	FadeFOV(PlayerWeapon(CurrentHoldable).ZoomedFOVAngle, PlayerController(PawnOwner.Controller).DefaultFOV, PlayerController(PawnOwner.Controller).ForegroundFovAngle, PlayerController(PawnOwner.Controller).DefaultForegroundFOV);
	FinishAnimation(HandsAnimationHandle);
	bFinishedStateAnimations = true;
	TransitionToNextStateInSequence();
	stop;		
	@NULL
	// BadToken (0x03)
	@NULL
	@NULL
	Holdable
	/* Statement decompilation error: Object reference not set to an instance of an object.
		
	*/

	/*@Error*/
}

state WeaponZoomedIdling extends TransitionalState
{Begin:

	SetHandsMode('Weapon');
End:


	TransitionToNextStateInSequence();
	CurrentHoldable = PawnOwner.GetActiveHoldable();
	WeaponAnimationHandle = CurrentHoldable.PlayAnimationOnChannelInstantEaseIn(0, CurrentHoldable.GetIdlingAnim(), 8);
	Weapon(CurrentHoldable).PlayIdleAnimations();
	// End:0x118
	if(__NFUN_255__(PlayerWeapon(CurrentHoldable).GetZoomedIdlingHandsAnim(), 'None'))
	{
		// End:0x118
		if(true)
		{
			HandsAnimationHandle = PlayAnimationOnChannelInstantEaseIn(0, PlayerWeapon(CurrentHoldable).GetZoomedIdlingHandsAnim(), 4);
			FinishAnimation(HandsAnimationHandle);
			// [Loop Continue]
			goto J0xC7;
			stop;									
			@NULL
			// BadToken (0x03)
			@NULL
			@NULL
			Holdable
			/* Statement decompilation error: Object reference not set to an instance of an object.
				
			*/

			/*@Error*/
		}
	}
}

state WeaponZoomedFiring extends TransitionalState
{
	ignores EndState;
Begin:

	SetHandsMode('Weapon');
	CurrentHoldable = PawnOwner.GetActiveHoldable();
	bFinishedStateAnimations = false;
	PlayerWeapon(CurrentHoldable).ZoomedFiring = true;
	PlayerWeapon(CurrentHoldable).PlayWeaponFiringAnimations();
	bFinishedStateAnimations = true;
	TransitionToNextStateInSequence();
	stop;			
	@NULL
	// BadToken (0x03)
	@NULL
	@NULL
	Holdable
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

state AbilityFastEquipping extends TransitionalState
{
	ignores EndState, BeginState;
Begin:

	SetHandsMode('Ability');
	PlayAndFinishHandsAnimation(CurrentAbility.FastEquipAnimationName);
	ShockPlayer(PawnOwner).OnAbilityEquippingFinished(CurrentAbility);
	TransitionToNextStateInSequence();
	stop;	
	@NULL
	// BadToken (0x03)
	@NULL
	@NULL
	Holdable
}

state AbilityFastUnEquipping extends TransitionalState
{Begin:

	SetHandsMode('Ability');
	// End:0x45
	if(__NFUN_119__(OldAbility, none))
	{
		PlayAndFinishHandsAnimation(OldAbility.FastUnEquipAnimationName);
		goto J0x65;
		PlayAndFinishHandsAnimation(CurrentAbility.FastUnEquipAnimationName);
	}
	TransitionToNextStateInSequence();
	stop;				
	@NULL
	// BadToken (0x03)
	@NULL
	@NULL
	Holdable
}

state AbilitySlowEquipping extends TransitionalState
{
	ignores EndState, BeginState;
Begin:

	SetHandsMode('Ability');
	PlayAndFinishHandsAnimation(CurrentAbility.SlowEquipAnimationName);
	ShockPlayer(PawnOwner).OnAbilityEquippingFinished(CurrentAbility);
	TransitionToNextStateInSequence();
	stop;	
	@NULL
	// BadToken (0x03)
	@NULL
	@NULL
	Holdable
}

state AbilitySlowUnEquipping extends TransitionalState
{Begin:

	SetHandsMode('Ability');
	// End:0x45
	if(__NFUN_119__(OldAbility, none))
	{
		PlayAndFinishHandsAnimation(OldAbility.SlowUnEquipAnimationName);
		goto J0x65;
		PlayAndFinishHandsAnimation(CurrentAbility.SlowUnEquipAnimationName);
	}
	TransitionToNextStateInSequence();
	stop;				
	@NULL
	// BadToken (0x03)
	@NULL
	@NULL
	Holdable
}

state AbilityFiring extends TransitionalState
{
	ignores EndState, BeginState;
Begin:

	SetHandsMode('Ability');
	AbilityHasBeenReleased = false;
	OnUsingActiveAbilityStarted();
	// End:0x68
	if(__NFUN_130__(CurrentAbility.CanPendingFire, AbilityPendingFireReleased))
	{
		UseActiveAbilityRelease();
		AbilityPendingFireReleased = false;
		PlayAndFinishHandsAnimation(CurrentAbility.FireAnimationName);
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x173
	/*@Error*/
	HandsAnimationHandle = PlayAnimationOnChannelInstantEaseIn(0, CurrentAbility.FireLoopAnimationName, 8);
	// End:0x12A
	if(__NFUN_130__(__NFUN_129__(AbilityHasBeenReleased), __NFUN_129__(CurrentAbility.HasBeenInterrupted(ShockPlayer(PawnOwner)))))
	{
		__NFUN_256__(0.0000000);
		// [Loop Continue]
		goto J0xE0;
		CurrentAbility.OnReleased(ShockPlayer(PawnOwner));
		PlayAndFinishHandsAnimation(CurrentAbility.FireReleaseAnimationName);
		FinishAbilityFiring();
		stop;				
	}
	@NULL
	// BadToken (0x03)
	@NULL
	@NULL
	Holdable
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

state FinishAbilityFiringWithEve extends TransitionalState
{Begin:

	SetHandsMode('Ability');
	PlayAndFinishHandsAnimation(CurrentAbility.GetFinishFireWithEveAnimationName());
	TransitionToNextStateInSequence();
	stop;	
	@NULL
}

state FinishAbilityFiringWithoutEve extends TransitionalState
{Begin:

	SetHandsMode('Ability');
	PlayAndFinishHandsAnimation(CurrentAbility.GetFinishFireWithoutEveAnimationName());
	TransitionToNextStateInSequence();
	stop;	
	@NULL
}

state AbilityIdling extends TransitionalState
{
	ignores EndState, BeginState;
Begin:

	SetHandsMode('Ability');
	// End:0x83
	if(__NFUN_130__(__NFUN_180__(ShockPlayer(PawnOwner).GetBioAmmo(), float(0)), PawnOwner.IsAlive()))
	{
		ShockPlayer(PawnOwner).UseHypoByClassName('BioAmmoHypo');
		goto J0x1AC;
		// End:0x126
		if(__NFUN_130__(__NFUN_130__(CurrentAbility.CanPendingFire, CurrentAbility.CanUseAbility(ShockPlayer(PawnOwner))), __NFUN_177__(__NFUN_174__(AbilityPendingFirePressedTime, CurrentAbility.PendingFireDelayTime), Level.TimeSeconds)))
		{
		}
		AbilityPendingFirePressedTime = 0.0000000;
		UseActiveAbility(true);
		goto J0x1AC;
		// End:0x1AC
		if(__NFUN_130__(bool(PawnOwner.Controller.bHoldingFireAbility), CurrentAbility.CanUseAbility(ShockPlayer(PawnOwner))))
		{
			PawnOwner.Controller.bHoldingFireAbility = 0;
		}
		UseActiveAbility();
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x1FF
		/*@Error*/
		HandsAnimationHandle = PlayAnimationOnChannelInstantEaseIn(0, CurrentAbility.GetIdlingAnim(), 4);
		FinishAnimation(HandsAnimationHandle);
		goto J0x1AC;
		TransitionToNextStateInSequence();
		stop;				
	}
	@NULL
	// BadToken (0x03)
	@NULL
	@NULL
	Holdable
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

state AbilityGenericIdling extends TransitionalState
{Begin:

	SetHandsMode('Ability');
	HandsAnimationHandle = PlayAnimationOnChannelInstantEaseIn(0, GenericIdlingAbilityAnimationName, 8);
	TransitionToNextStateInSequence();
	// End:0xA8
	if(true)
	{
		// End:0x92
		if(__NFUN_180__(ShockPlayer(PawnOwner).GetBioAmmo(), float(0)))
		{
			ShockPlayer(PawnOwner).UseHypoByClassName('BioAmmoHypo');
			UpdateAbilityUsability(true);
			__NFUN_256__(0.5000000);
			// [Loop Continue]
			goto J0x3D;
			stop;									
		}
	}
	@NULL
	// BadToken (0x03)
	@NULL
	@NULL
	Holdable
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

state AbilityGenericEquipping extends TransitionalState
{
	ignores BeginState;
Begin:

	SetHandsMode('Ability');
	PlayAndFinishHandsAnimation(GenericEquippingAbilityAnimationName);
	TransitionToNextStateInSequence();
	stop;			
	@NULL
}

state AbilityGenericUnEquipping extends TransitionalState
{Begin:

	SetHandsMode('Ability');
	PlayAndFinishHandsAnimation(GenericUnEquippingAbilityAnimationName);
	TransitionToNextStateInSequence();
	stop;			
	@NULL
}

state InjectingEve extends TransitionalState
{
	ignores EndState, BeginState;
Begin:

	bFinishedStateAnimations = false;
	ToolAnimationHandle = BioAmmoHypoTool.PlayAnimationOnChannelInstantEaseIn(0, BioAmmoHypoTool.InjectingEveAnimationName, 4);
	PlayAndFinishHandsAnimation(InjectingEveAnimationName);
	OnCompletedInjectingEve();
	bFinishedStateAnimations = true;
	TransitionToNextStateInSequence();
	stop;		
	@NULL
	// BadToken (0x03)
	@NULL
	@NULL
	Holdable
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

state UsingGathererTool extends TransitionalState
{
	ignores EndState, BeginState;
Begin:


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x324
	/*@Error*/
	bFinishedStateAnimations = false;
	ToolAnimationHandle = GathererTool.PlayAnimationOnChannelInstantEaseIn(0, ShockPlayer(PawnOwner).GetHarvestingTarget().GetHandEquippingAnimationName(self), 4);
	PlayAndFinishHandsAnimation(ShockPlayer(PawnOwner).GetHarvestingTarget().GetHandEquippingAnimationName(self));
	ShockPlayer(PawnOwner).GetHarvestingTarget().OnNeedleInserted(self);
	bNeedleInserted = true;
	ShockPlayer(PawnOwner).dispatchMessage(Class'ShockGame.MessagePlayerStartedHarvesting'.static.Allocate(self)., construct_ICanBeHarvested(ShockPlayer(PawnOwner).GetHarvestingTarget()));
	ToolAnimationHandle = GathererTool.PlayAnimationOnChannelInstantEaseIn(0, ShockPlayer(PawnOwner).GetHarvestingTarget().GetHandLoopingAnimationName(self), 4);
	HandsAnimationHandle = PlayAnimationOnChannelInstantEaseIn(0, ShockPlayer(PawnOwner).GetHarvestingTarget().GetHandLoopingAnimationName(self), 8);
	HarvestAdam();
	ShockPlayer(PawnOwner).dispatchMessage(Class'ShockGame.MessagePlayerFinishedHarvesting'.static.Allocate(self)., construct_ICanBeHarvested(ShockPlayer(PawnOwner).GetHarvestingTarget()));
	ShockPlayer(PawnOwner).GetHarvestingTarget().OnNeedleRemoved(self);
	bNeedleInserted = false;
	ToolAnimationHandle = GathererTool.PlayAnimationOnChannelInstantEaseIn(0, ShockPlayer(PawnOwner).GetHarvestingTarget().GetHandUnequippingAnimationName(self), 4);
	PlayAndFinishHandsAnimation(ShockPlayer(PawnOwner).GetHarvestingTarget().GetHandUnequippingAnimationName(self));
	bFinishedStateAnimations = true;
	ShockPlayer(PawnOwner).ResetCurrentHandMode();
	stop;			
	@NULL
	// BadToken (0x03)
	@NULL
	@NULL
	Holdable
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// BadToken (0x03)
	/*@Error*/
}

state ExorcisingGatherer extends TransitionalState
{
	ignores EndState, BeginState;
Begin:

	bFinishedStateAnimations = false;
	ShockPlayer(PawnOwner).CurrentExorcismTarget.SetHidden(true);
	// End:0x8F
	if(__NFUN_114__(PseudoGatherer, none))
	{
		PseudoGatherer = __NFUN_278__(Class'ShockGame.PseudoGatherer');
		PseudoGatherer.DrawPriority = 1;
		PseudoGatherer.UpdateRenderRevision();
		AttachToBone(PseudoGatherer, PseudoGathererSocket);
		PseudoGatherer.Show();
		// End:0x112
		if(IsPacifyingGatherer)
		{
			PseudoGathererAnimationHandle = PseudoGatherer.PlayAnimationOnChannelInstantEaseIn(0, PacifyingPseudoGathererAnimationName, 4);
		}
		PlayAndFinishHandsAnimation(PacifyingGathererAnimationName);
		goto J0x152;
		PseudoGathererAnimationHandle = PseudoGatherer.PlayAnimationOnChannelInstantEaseIn(0, ExorcisingPseudoGathererAnimationName, 4);
		PlayAndFinishHandsAnimation(ExorcisingGathererAnimationName);
		DetachFromBone(PseudoGatherer);
		PseudoGatherer.Hide();
		// End:0x28D
		if(IsPacifyingGatherer)
		{
			// End:0x28A
			if(__NFUN_119__(PacifyingSeaSlugClass, none))
			{
				// End:0x1ED
				if(__NFUN_114__(PacifyingSeaSlug, none))
				{
				}
				PacifyingSeaSlug = __NFUN_278__(PacifyingSeaSlugClass);
				PacifyingSeaSlug.DrawPriority = 1;
				PacifyingSeaSlug.UpdateRenderRevision();
				AttachToBone(PacifyingSeaSlug, PacifyingSeaSlugSocket);
				PacifyingSeaSlug.Show();
				PseudoGathererAnimationHandle = PacifyingSeaSlug.PlayAnimationOnChannelInstantEaseIn(0, PacifyingSeaSlugAnimationName, 4);
				PlayAndFinishHandsAnimation(PacifyingSeaSlugHandAnimationName);
				DetachFromBone(PacifyingSeaSlug);
				PacifyingSeaSlug.Hide();
				goto J0x3BC;
				ShockPlayer(PawnOwner).CurrentExorcismTarget.SetHidden(false);
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x3BC
				/*@Error*/
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x31F
				/*@Error*/
				SavingSeaSlug = __NFUN_278__(SavingSeaSlugClass);
			}
			SavingSeaSlug.DrawPriority = 1;
			SavingSeaSlug.UpdateRenderRevision();
			AttachToBone(SavingSeaSlug, SavingSeaSlugSocket);
			SavingSeaSlug.Show();
			PseudoGathererAnimationHandle = SavingSeaSlug.PlayAnimationOnChannelInstantEaseIn(0, SavingSeaSlugAnimationName, 4);
			PlayAndFinishHandsAnimation(SavingSeaSlugHandAnimationName);
			DetachFromBone(SavingSeaSlug);
			SavingSeaSlug.Hide();
			bFinishedStateAnimations = true;
			ShockPlayer(PawnOwner).ResetCurrentHandMode();
		}
	}
	stop;			
	@NULL
	// BadToken (0x03)
	@NULL
	@NULL
	Holdable
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// BadToken (0x03)
	/*@Error*/
}

state PlayingScriptedHandAnimation extends TransitionalState
{End:

	stop;			
}

defaultproperties
{
	BioAmmoClass=Class'ShockGame.ShockDesignerClasses.BioAmmoHypo'
	WeaponBobDamping=0.5000000
	PreferredHarvestInterval=0.3300000
	ShouldClearAbilityEffectsInWeaponsMode=true
	HandsOffscreenAnimationName="HandsDown"
	GenericEquippingAbilityAnimationName="NoEve_Equip"
	GenericUnEquippingAbilityAnimationName="NoEve_UnEquip"
	GenericIdlingAbilityAnimationName="NoEve_Fidget"
	InjectingEveAnimationName="Eve_ArmJab"
	UsingGathererToolEquipAnimationName="StartGatherGun"
	UsingGathererToolLoopAnimationName="LoopGatherGun"
	UsingGathererToolUnEquipAnimationName="EndGatherGun"
	ExorcisingGathererAnimationName="GathererSave_Heal"
	ExorcisingPseudoGathererAnimationName="GA_GathererSave_Heal"
	PacifyingGathererAnimationName="GathererHarvest"
	PacifyingPseudoGathererAnimationName="GA_GathererHarvest"
	HarvestingAdamCollectionTime=5.0000000
	PacifyingSeaSlugClass=Class'ShockGame.PlayerAttachments.PLAYER_HarvestSlug'
	PacifyingSeaSlugSocket="Pistol"
	PacifyingSeaSlugAnimationName="HarvestSlugFish_Thrash"
	PacifyingSeaSlugHandAnimationName="Slug_HarvestHold"
	PseudoGathererSocket="GathererAttach"
	GathererToolSocket="Pistol"
	BioAmmoHypoToolSocket="Pistol"
	ZoomedLookModifier=0.5000000
	DamageEmitterSocket="Bip01_R_Hand"
	DrawType=2
	bHidden=true
	bInGameRenderable=true
	Mesh=SkeletalMesh'SimpleAnim.SimpleAnim'
	DrawPriority=1
	bNeedLifetimeEffectEvents=true
	ShouldSerializeSkeletonInstance=true
}