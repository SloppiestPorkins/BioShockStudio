class ShockPawn extends VPawn implements IDamagee, IModObserver, IAffectedByTelekinesis, ITakeCollisionDamage, ISupportsDamageStates, ICanPropagateFire, IPotentialAimTarget
	abstract
	native
	config(ShockPawn)
	hidecategories(DrawScale3D,DisplayAdvanced);

const kNumCachedVelocities = 4;
const kCachedVelocityFrequency = 0.125;

enum EDamageEvent
{
	NoDamageEvent,                  // 0
	Fall,                           // 1
	FullBodyAnimation,              // 2
	AdditiveHitReaction,            // 3
	QuickHitReaction                // 4
};

struct native atomic UntriggerEffectEventInfo
{
	var config name EffectEventName;
	var config name EffectEventTag;
	var config bool bOnlyOnDestruction;
};

struct native atomic CriticalDamageEffectInfo
{
	var config float DamagePercentage;
	var config name EffectEvent;
	var config bool bUnTriggerEffectEvent;
	var config bool bOnlyOnCriticalHit;
	var bool bHasBeenUsed;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic DamageEventInfo
{
	var config ShockPawn.EDamageEvent DamageEvent;
	var config float PassiveChance;
	var config float AggressiveChance;
	var config float ReactionCoolOffTime;
	var config ShockPawn.EDamageEvent FailedDamageEvent;
	var config bool bTriggerOnce;
	var config bool bTriggerWhenDead;
	var bool bHasBeenUsed;
	var float ReactionCoolOffEndTime;
};

struct native atomic DamageEventInfoSpecifier
{
	var config DamageStimuliSet.EDamageType DamageType;
	var config DamageStimuliSet.EDamageStrength DamageStrength;
	var config Class<Actor> DamagerClass;
};

struct native atomic DamageEventInfoEntry
{
	var config DamageEventInfoSpecifier EntryParameters;
	var config DamageEventInfo EntryEventInfo;
};

struct native atomic DamageEventInfoOverrideEntry
{
	var config name EntrySourceStimuliSetName;
	var config ShockPawn.EDamageEvent DamageEvent;
	var config float PassiveChance;
	var config float AggressiveChance;
	var config ShockPawn.EDamageEvent FailedDamageEvent;
	var config float ReactionCoolOffTime;
	var float ReactionCoolOffEndTime;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic PlayerSourceDamageEventInfoDefaultEntry
{
	var config Range DamagePercentRange;
	var config Range PassiveChanceRange;
	var config Range AggressiveChanceRange;
	var config ShockPawn.EDamageEvent DamageEvent;
	var config float ReactionCoolOffTime;
	var float ReactionCoolOffEndTime;
};

struct native atomic PlayerEventLocationalDamageMultiplierEntry
{
	var config Actor.ESkeletalRegion DamageRegion;
	var config float Multiplier;
};

var private travel ModManager ModManager;
var private travel Hands Hands;
var config string HandsClassString;
var config travel name DamageResistanceSetName;
var private transient DamageResistanceSet ResistanceSet;
var bool ChangeResistanceSet;
var private float BaseCriticalHitChanceModifier;
var private float BaseCriticalHitAmountModifier;
var private bool bIsInvincible;
var bool bDoNotTakeAnyDamage;
var config bool ImmediateFireOfPendingWeaponEnabled;
var config array< Class<Weapon> > AllPossibleWeaponClasses;
var travel Holdable ActiveHoldable;
var private Holdable PendingHoldable;
var travel array<Holdable> Holdables;
var private bool IsBusyDoingSomething;
var config travel float MaxHealth;
var travel float UpgradedHealthBonus;
var private config float MaxFrozenHealth;
var private config float FrozenHealthDecayPerSecond;
var private config float DamageToRegularHealthWhileFrozenModifer;
var private float FrozenHealth;
var private float BurningEfficacy;
var FireRepellingVolume FireRepeller;
var private config float ShatteredDamageAmount;
var private config bool bCannotBeShattered;
var Actor Killer;
var Vector KilledHitLocation;
var Vector KilledHitNormal;
var config Vector HealthBarNormalOffset;
var config Vector HealthBarCeilingOffset;
var array<Vector> CachedVelocities;
var private float LastTimeVelocityCached;
var config float CollisionAvoidancePushDistance;
var config float CollisionAvoidancePushStrength;
var ShockPawn LastBumpedPawn;
var float LastBumpedTime;
var private config float FallingDamageLinearMultiplier;
var private config float FallingDamageGeometricMultiplier;
var private config name FallingDamageStimuliSetName;
var private config float FallingDamageCritChance;
var array<ShockPawn> IntentionalAttackers;
var private ShockDoor DoorPawnIsIn;
var float SecurityBeaconTriggeredTime;
var config float SecurityBeaconDuration;
var config float SecurityBeaconTimeoutWarning;
var bool HasWarnedAboutSecurityBeaconTimeoutYet;
var bool HasWarnedAboutBerserkTimeoutYet;
var float SecurityBeaconEndTime;
var array<ICanBeControlled> OwnedControllables;
var const config int MaxBotControllables;
var const config int NumControllableSectors;
var const config float ControllableDamageMultiplier;
var config array<UntriggerEffectEventInfo> UntriggerEffectEventInfos;
var config float BerserkTimeoutWarning;
var private config float MaxBurningEfficacy;
var private config float MaxFrozenEfficacy;
var private config float MaxShockedEfficacy;
var private config float DiseasedTimeout;
var config float BurningTimeout;
var private config float FrozenTimeout;
var private config float BerserkTimeout;
var private config float ShockedTimeout;
var private config float ShockedInWaterTimeout;
var travel float DiseasedUntil;
var travel float BurningUntil;
var travel float FrozenUntil;
var travel float BerserkUntil;
var travel float ShockedUntil;
var private float LastShockedInWaterAmount;
var private float LastElectricInWaterAmount;
var private Actor LastDamager;
var travel name LastAcquiredState;
var travel name CurrentAcquiredState;
var private const int InfernoID;
var private Actor FireStateInstigator;
var travel float InWaterTimer;
var private config float TimeInWaterToStopBurning;
var private config float DiseaseSpreadCheckInterval;
var private config float DiseaseSpreadCheckRadius;
var private travel float NextDiseaseSpreadCheckTime;
var private bool LatentBerserk;
var(Telekinesis) bool bTelekinesisDisabled;
var config array<CriticalDamageEffectInfo> CriticalDamageEffectInfos;
var config array<DamageEventInfoEntry> DefaultDamageEventInfos;
var config array<DamageEventInfoOverrideEntry> AISourceDamageEventInfoOverrides;
var config ShockPawn.EDamageEvent CriticalHitDamageEvent;
var config array<PlayerSourceDamageEventInfoDefaultEntry> PlayerSourceDamageEventInfoRanges;
var config array<DamageEventInfoOverrideEntry> PlayerSourceDamageEventInfoOverrides;
var config array<PlayerEventLocationalDamageMultiplierEntry> PlayerSourceDamageEventLocationMultipliers;
var private config name DamageMultiplierSetName;
var private DamageMultiplierSet DamageMultiplierSetInstance;
//var delegate<OnPushGetPushee> __OnPushGetPushee__Delegate;

function ShockPawn.EDamageEvent GetDamageEvent(DamageStimuliSet DamageStimuli, Actor Damager, float finalDamageAmount, name HitHighBone, bool bIsCriticalHit)
{
	//native.DamageStimuli;
	//native.Damager;
	//native.finalDamageAmount;
	//native.HitHighBone;
	//native.bIsCriticalHit;	
	@NULL
	@NULL
	return default.@NULL;
}

// Export UShockPawn::execAssignDamageLocationMultipliers(FFrame&, void* const)
native function AssignDamageLocationMultipliers();

// Export UShockPawn::execIsDiseased(FFrame&, void* const)
native function bool IsDiseased();

// Export UShockPawn::execIsBurning(FFrame&, void* const)
native function bool IsBurning();

// Export UShockPawn::execIsFrozen(FFrame&, void* const)
native function bool IsFrozen();

// Export UShockPawn::execIsBerserk(FFrame&, void* const)
native function bool IsBerserk();

// Export UShockPawn::execIsShocked(FFrame&, void* const)
native function bool IsShocked();

// Export UShockPawn::execIsSecurityBeaconed(FFrame&, void* const)
native function bool IsSecurityBeaconed();

function bool ShouldDieWhenShattered()
{
	return __NFUN_180__(ShatteredDamageAmount, 0.0000000);
	return;
	@NULL
}

function float GetFrozenHealth()
{
	return FrozenHealth;
	return;
	@NULL
}

function OnShattered()
{
	dispatchMessage(Class'ShockGame.MessagePawnShattered'.static.Allocate(self)., construct_ShockPawn(self));
	return;
	@NULL
}

function UntriggerStateEffects(bool bTriggerUnAcquiredStateEvent)
{
	//native.bTriggerUnAcquiredStateEvent;	
	@NULL
}

// Export UShockPawn::execRetriggerStateEffects(FFrame&, void* const)
native function RetriggerStateEffects();

// Export UShockPawn::execUntriggerSecurityBeaconEffect(FFrame&, void* const)
native function UntriggerSecurityBeaconEffect();

// Export UShockPawn::execRetriggerSecurityBeaconEffect(FFrame&, void* const)
native function RetriggerSecurityBeaconEffect();

// Export UShockPawn::execClearSecurityBeacon(FFrame&, void* const)
native function ClearSecurityBeacon();

function SetDiseased(optional float Effectiveness, optional Actor StateInstigator)
{
	//native.Effectiveness;
	//native.StateInstigator;	
	@NULL
	@NULL
}

function SetBurning(optional float Effectiveness, optional Actor StateInstigator)
{
	//native.Effectiveness;
	//native.StateInstigator;	
	@NULL
	@NULL
}

function SetFrozen(optional float Effectiveness, optional Actor StateInstigator)
{
	//native.Effectiveness;
	//native.StateInstigator;	
	@NULL
	@NULL
}

function SetBerserk(optional float Effectiveness, optional Actor StateInstigator)
{
	//native.Effectiveness;
	//native.StateInstigator;	
	@NULL
	@NULL
}

function SetShocked(optional float Effectiveness, optional Actor StateInstigator)
{
	//native.Effectiveness;
	//native.StateInstigator;	
	@NULL
	@NULL
}

// Export UShockPawn::execClearDiseased(FFrame&, void* const)
native function ClearDiseased();

// Export UShockPawn::execClearBurning(FFrame&, void* const)
native function ClearBurning();

// Export UShockPawn::execClearFrozen(FFrame&, void* const)
native function ClearFrozen();

// Export UShockPawn::execClearBerserk(FFrame&, void* const)
native function ClearBerserk();

// Export UShockPawn::execClearShocked(FFrame&, void* const)
native function ClearShocked();

// Export UShockPawn::execCreateFireRepeller(FFrame&, void* const)
native function CreateFireRepeller();

// Export UShockPawn::execKillFireRepeller(FFrame&, void* const)
native function KillFireRepeller();

// Export UShockPawn::execGetInfernoID(FFrame&, void* const)
native function int GetInfernoID();

function SetInfernoID(int id)
{
	//native.id;	
	@NULL
}

function Actor GetFireInstigator()
{
	return FireStateInstigator;
	return;
	@NULL
}

// Export UShockPawn::execGetMaxHealth(FFrame&, void* const)
native function float GetMaxHealth();

// Export UShockPawn::execGetHealth(FFrame&, void* const)
native function float GetHealth();

function AddHealth(float numHealth, optional bool AddHealthEvenIfDead)
{
	//native.numHealth;
	//native.AddHealthEvenIfDead;	
	@NULL
	@NULL
}

function RemoveHealth(float numHealth)
{
	//native.numHealth;	
	@NULL
}

function AddMod(Mod inMod, float Duration)
{
	//native.inMod;
	//native.Duration;	
	@NULL
	@NULL
}

function RemoveMod(name modName)
{
	//native.modName;	
	@NULL
}

function float ModifyStat(name GroupName, float BaseValue)
{
	//native.GroupName;
	//native.BaseValue;	
	@NULL
	@NULL
}

function bool HasMod(name GroupName)
{
	//native.GroupName;	
	@NULL
}

function GetModList(out array<Mod> CurrentModList, name GroupName)
{
	//native.CurrentModList;
	//native.GroupName;	
	@NULL
	@NULL
}

function RegisterObserver(IModObserver Observer, name GroupName)
{
	//native.Observer;
	//native.GroupName;	
	@NULL
	@NULL
}

function UnRegisterObserver(IModObserver Observer, name GroupName)
{
	//native.Observer;
	//native.GroupName;	
	@NULL
	@NULL
}

// Export UShockPawn::execNativeInitialize(FFrame&, void* const)
native function NativeInitialize();

function PreBeginPlay()
{
	super.PreBeginPlay();
	NativeInitialize();
	AssignDamageLocationMultipliers();
	return;
	@NULL
}

function PostLoadGame()
{
	super(Pawn).PostLoadGame();
	IsBusyDoingSomething = false;
	return;
	@NULL
	Item
}

function StopAllSounds()
{
	SoundEffectsSubsystem(EffectsSystem(Level.EffectsSystem).GetSubsystem('SoundEffectsSubsystem')).StopMySchemas(self);
	return;
	@NULL
	Item
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

function Notify(name GroupName, bool wasRemoved, name modName)
{
	log('Mods', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::notify( "), string(GroupName)), ", "), string(wasRemoved)), ", "), string(modName)), " )"));
	switch(GroupName)
	{
		// End:0xCF
		case 'ActiveTrackSlots_Bonus':
			log(,, __NFUN_112__(__NFUN_112__(string(self), " ... Unlocked Active track slot. Num unlocked = "), string(ModifyStat(GroupName, 0.0000000))));
			// End:0x33D
			break;
			// End:0x139
			case 'EcologyTrackSlots_Bonus':
				log(,, __NFUN_112__(__NFUN_112__(string(self), " ... Unlocked Ecology track slot. Num unlocked = "), string(ModifyStat(GroupName, 0.0000000))));
			// End:0x33D
			break;
			// End:0x1A7
			case 'EngineeringTrackSlots_Bonus':
				log(,, __NFUN_112__(__NFUN_112__(string(self), " ... Unlocked Engineering track slot. Num unlocked = "), string(ModifyStat(GroupName, 0.0000000))));
			// End:0x33D
			break;
			// End:0x210
			case 'WeaponTrackSlots_Bonus':
				log(,, __NFUN_112__(__NFUN_112__(string(self), " ... Unlocked Weapon track slot. Num unlocked = "), string(ModifyStat(GroupName, 0.0000000))));
			// End:0x33D
			break;
			// End:0x285
			case 'PhysicalTrackSlots_Bonus':
				log(,, __NFUN_112__(__NFUN_112__(string(self), " ... Unlocked Physical track slot. Num unlocked = "), string(ModifyStat(GroupName, 0.0000000))));
			UpdateMaxHealth();
			// End:0x33D
			break;
			// End:0x29E
			case 'GroundSpeed_Bonus':
				UpdateGroundSpeed();
				// End:0x33D
				break;
				// End:0x2AA
				case 'MaxHealth_Bonus':
				// End:0x2C3
				case 'MaxHealth_PercentBonus':
					UpdateMaxHealth();
					// End:0x33D
					break;
				// End:0x33A
				case 'FreezingNimbus_Exists':
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x337
				/*@Error*/
				// End:0x317
				if(HasMod('FreezingNimbus_Exists'))
				{/* !MISMATCHING REMOVE, tried Case got Type:If Position:0x2B6! */
				ActiveHoldable.TriggerEffectEvent('FreezingNimbusApplied');
				// End:0x337
				break;
				ActiveHoldable.UnTriggerEffectEvent('FreezingNimbusApplied');
				// End:0x33D
				break;
				// End:0xFFFF
				default:
					return;
					break;
			}/* !MISMATCHING REMOVE, tried Switch got Type:Case Position:0x261! */
			@NULL
			Item
		}/* !MISMATCHING REMOVE, tried If got Type:Case Position:0x056! */
		Item
		@NULL
	// Failed to format remaining nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 724
	// 2 & Type:Case Position:0x33A
}

function UpdateGroundSpeed()
{
	GroundSpeedBonus = ModifyStat('GroundSpeed_Bonus', 0.0000000);
	GroundSpeed = __NFUN_174__(default.GroundSpeed, GroundSpeedBonus);
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function UpdateMaxHealth()
{
	local float PreviousMaxHealth;

	PreviousMaxHealth = MaxHealth;
	MaxHealth = ModifyStat('MaxHealth_Bonus', __NFUN_174__(default.MaxHealth, UpgradedHealthBonus));
	__NFUN_182__(MaxHealth, ModifyStat('MaxHealth_PercentBonus', 1.0000000));
	AddHealth(0.0000000);
	UpdateUIStats();
	// End:0xFD
	if(__NFUN_177__(MaxHealth, PreviousMaxHealth))
	{
		TriggerEffectEvent('MaxHealthIncreased');
		Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("MaxHealthIncreased");
		goto J0x177;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x177
		/*@Error*/
		TriggerEffectEvent('MaxHealthDecreased');
		Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("MaxHealthDecreased");
	}
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function UpdateUIStats()
{
	return;
}

function array<Holdable> GetAvailableHoldables()
{
	local array<Holdable> outHoldables;
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x7C
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6E
	/*@Error*/
	outHoldables[i] = Holdables[i];
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x0B;
	return outHoldables;
	return;
	@NULL
	Item
	Item
	@NULL
}

function int GetNumHoldables()
{
	return Holdables.Length;
	return;
	@NULL
}

function Holdable GetHoldable(int Index)
{
	// End:0x2B
	if(__NFUN_132__(__NFUN_150__(Index, 0), __NFUN_151__(Index, GetNumHoldables())))
	{
		return none;
		return Holdables[Index];
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function Holdable GetHoldableByClassName(name HoldableClassName)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x80
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x72
	/*@Error*/
	return Holdables[i];
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x0B;
	return none;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function int GetHoldableIndex(Holdable inHoldable)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x76
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x68
	/*@Error*/
	return i;
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x0B;
	return -1;
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool AddAvailableHoldable(Holdable inHoldable)
{
	inHoldable.SetHolder(self);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x68
	/*@Error*/
	Holdables[Holdables.Length] = inHoldable;
	PlayerAddAvailableHoldable(inHoldable);
	return true;
	return false;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function PlayerAddAvailableHoldable(Holdable inHoldable)
{
	return;
}

function RemoveAvailableHoldable(Holdable inHoldable)
{
	local int Index;

	Index = GetHoldableIndex(inHoldable);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x57
	/*@Error*/
	Holdables.Remove(Index, 1);
	PlayerRemoveAvailableHoldable(inHoldable);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerRemoveAvailableHoldable(Holdable inHoldable)
{
	return;
}

// Export UShockPawn::execGetActiveHoldable(FFrame&, void* const)
native function Holdable GetActiveHoldable();

function Holdable GetPendingHoldable()
{
	return PendingHoldable;
	return;
	@NULL
}

function Hands GetHands()
{
	return Hands;
	return;
	@NULL
}

function int GetAnimationChannelForWeapon(Weapon inWeapon)
{
	return 2;
	return;
}

function float GetAnimationTweenTimeForWeapon(Weapon inWeapon)
{
	return 0.2000000;
	return;
}

function float GetAnimationEaseOutTimeBeforeEndForWeapon(Weapon inWeapon)
{
	return 0.2000000;
	return;
}

function OnSpawnedDamageEmitter(DamageEmitter Emitter)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x45
	/*@Error*/
	Weapon(ActiveHoldable).OnSpawnedDamageEmitter(Emitter);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function bool IsBusy()
{
	return IsBusyDoingSomething;
	return;
	@NULL
}

function SetBusy(bool newBusy)
{
	IsBusyDoingSomething = newBusy;
	return;
	@NULL
	Item
}

function Equip(Holdable theHoldable, optional bool forceSwitch)
{
	log('Weapons', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), " is trying to Equip '"), string(theHoldable)), "'"));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xC6
	/*@Error*/
	PendingHoldable = theHoldable;
	// End:0x9E
	if(__NFUN_119__(ActiveHoldable, none))
	{
		ActiveHoldable.UnEquip(true);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xC6
		/*@Error*/
		PendingHoldable.Equip(self, true);
	}
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

event PendingEquip(Holdable theHoldable)
{
	return;
}

function OnEquippingStarted(Holdable theHoldable)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x36
	/*@Error*/
	theHoldable.TriggerEffectEvent('FreezingNimbusApplied');
	return;
	@NULL
}

function OnEquippingFinished(Holdable theHoldable)
{
	log('Weapons', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::OnEquippingFinished( "), string(theHoldable)), " )"));
	ActiveHoldable = theHoldable;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x76
	/*@Error*/
	PendingHoldable = none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnUnEquippingStarted(Holdable theHoldable)
{
	log('Weapons', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::OnUnEquippingStarted( "), string(theHoldable)), " )"));
	return;
	@NULL
}

function OnUnEquippingFinished(Holdable theHoldable)
{
	log('Weapons', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::OnUnEquippingFinished( "), string(theHoldable)), " )"));
	ActiveHoldable = none;
	theHoldable.UnTriggerEffectEvent('FreezingNimbusApplied');
	return;
	@NULL
	Item
	Item
}

function ZoomCycle()
{
	log('Weapons', 3, __NFUN_112__(__NFUN_112__(string(self), " Zoom cycle for "), string(ActiveHoldable)));
	return;
	@NULL
}

function BeginFiring(optional bool inAltFire)
{
	local Weapon Weapon;

	log('Weapons', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), " is trying to Begin Firing "), string(ActiveHoldable)), " IsBusy: "), string(IsBusy())));
	Weapon = Weapon(PendingHoldable);
	// End:0x10F
	if(__NFUN_130__(__NFUN_130__(ImmediateFireOfPendingWeaponEnabled, __NFUN_119__(Weapon, none)), Weapon.CanPendingFire))
	{
		log(,, __NFUN_112__("Trying to pendingFire pending weapon ", string(PendingHoldable)));
		Weapon.PendingFire(inAltFire);
		goto J0x250;
		Weapon = Weapon(ActiveHoldable);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x250
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x215
		/*@Error*/
	}
	Weapon.BeginFiring(inAltFire);
	goto J0x250;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x250
	/*@Error*/
	Weapon.PendingFire(inAltFire);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function CeaseFiring(optional bool inAltFire, optional bool bInterruptBurst)
{
	log('Weapons', 4, __NFUN_112__(string(self), " is trying to Cease Firing"));
	// End:0x92
	if(__NFUN_130__(__NFUN_119__(ActiveHoldable, none), ActiveHoldable.__NFUN_303__('Weapon')))
	{
		Weapon(ActiveHoldable).CeaseFiring(inAltFire, bInterruptBurst);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x102
		/*@Error*/
	}
	Weapon(PendingHoldable).CeaseFiring(inAltFire, bInterruptBurst);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function OnFiringStarted(Weapon theWeapon)
{
	log('Weapons', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::OnFiringStarted( "), string(theWeapon)), " )"));
	SetBusy(true);
	return;
	@NULL
}

function OnFiringFinished(Weapon theWeapon)
{
	log('Weapons', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::OnFiringFinished( "), string(theWeapon)), " )"));
	SetBusy(false);
	return;
	@NULL
}

function OnFiringInterrupted(Weapon theWeapon)
{
	log('Weapons', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::OnFiringInterrupted( "), string(theWeapon)), " )"));
	SetBusy(false);
	return;
	@NULL
}

function bool SelectAmmo(Class<Ammunition> AmmoClass)
{
	log('Weapons', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), " is trying to Select Ammo '"), string(AmmoClass)), "' for PendingHoldable = "), string(PendingHoldable)), ",  ActiveHoldable = "), string(ActiveHoldable)));
	// End:0xEA
	if(__NFUN_130__(__NFUN_119__(PendingHoldable, none), __NFUN_130__(PendingHoldable.__NFUN_303__('Weapon'), Weapon(PendingHoldable).SelectAmmo(AmmoClass))))
	{
		return false;
		return __NFUN_130__(__NFUN_119__(ActiveHoldable, none), __NFUN_130__(ActiveHoldable.__NFUN_303__('Weapon'), Weapon(ActiveHoldable).SelectAmmo(AmmoClass)));
	}
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function ReloadWeapon()
{
	log('Weapons', 3, __NFUN_112__(string(self), " is trying to Reload Weapon"));
	// End:0xDC
	if(__NFUN_130__(__NFUN_130__(__NFUN_119__(ActiveHoldable, none), ActiveHoldable.__NFUN_303__('Weapon')), __NFUN_132__(__NFUN_114__(Shotgun(ActiveHoldable), none), __NFUN_130__(__NFUN_255__(Hands.__NFUN_284__(), 'WeaponFiring'), __NFUN_255__(Hands.__NFUN_284__(), 'WeaponZoomedFiring')))))
	{
		Weapon(ActiveHoldable).Reload();
		goto J0x1A3;
		// End:0x12C
		if(__NFUN_130__(__NFUN_119__(PendingHoldable, none), PendingHoldable.__NFUN_303__('Weapon')))
		{
		}
		Weapon(PendingHoldable).Reload();
		goto J0x1A3;
		Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodString("SelectAmmo", string(Weapon(ActiveHoldable).GetCurrentAmmoSelection().Name));
	}
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function OnReloadingStarted(Weapon theWeapon)
{
	log('Weapons', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::OnReloadingStarted( "), string(theWeapon)), " )"));
	return;
	@NULL
}

function OnReloadingFinished(Weapon theWeapon)
{
	log('Weapons', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::OnReloadingFinished( "), string(theWeapon)), " )"));
	return;
	@NULL
}

function int FillWeaponClipWithAvailableAmmunition(Class<Ammunition> AmmoClass, int ClipSize)
{
	return ClipSize;
	return;
	@NULL
}

function bool HasAmmoRemaining(Class<Ammunition> AmmoClass)
{
	return true;
	return;
}

function int GetNumberOfItems(Class<Item> ItemClass)
{
	return 0;
	return;
}

event UseUpItem(Class<Item> ItemClass, int AmountUsed)
{
	return;
}

function ReleaseAmmunition(Class<Ammunition> AmmoClass)
{
	return;
}

// Export UShockPawn::execIsPlayer(FFrame&, void* const)
native function bool IsPlayer();

// Export UShockPawn::execIsGatherer(FFrame&, void* const)
native function bool IsGatherer();

// Export UShockPawn::execIsAggressor(FFrame&, void* const)
native function bool IsAggressor();

// Export UShockPawn::execIsProtector(FFrame&, void* const)
native function bool IsProtector();

// Export UShockPawn::execIsSecurityCamera(FFrame&, void* const)
native function bool IsSecurityCamera();

// Export UShockPawn::execIsTurret(FFrame&, void* const)
native function bool IsTurret();

// Export UShockPawn::execIsSecurityBot(FFrame&, void* const)
native function bool IsSecurityBot();

// Export UShockPawn::execIsNavBot(FFrame&, void* const)
native function bool IsNavBot();

// Export UShockPawn::execIsDecoy(FFrame&, void* const)
native function bool IsDecoy();

// Export UShockPawn::execShouldPerceiveAsPlayer(FFrame&, void* const)
native function bool ShouldPerceiveAsPlayer();

// Export UShockPawn::execShouldPerceiveAsGatherer(FFrame&, void* const)
native function bool ShouldPerceiveAsGatherer();

// Export UShockPawn::execShouldPerceiveAsAggressor(FFrame&, void* const)
native function bool ShouldPerceiveAsAggressor();

// Export UShockPawn::execShouldPerceiveAsProtector(FFrame&, void* const)
native function bool ShouldPerceiveAsProtector();

// Export UShockPawn::execIsPlayersFriend(FFrame&, void* const)
native function bool IsPlayersFriend();

function TakeCollisionDamage(float Impulse, float Mass, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, float DamageAttenuation, optional name HitHighBone, optional name HitLowBone)
{
	//native.Impulse;
	//native.Mass;
	//native.Damager;
	//native.HitLocation;
	//native.HitNormal;
	//native.HitImpulseDirection;
	//native.DamageAttenuation;
	//native.HitHighBone;
	//native.HitLowBone;	
	@NULL
	@NULL
	return default.@NULL;
}

function TakeSimpleDamage(DamageStimuliSet.DamageStimulusType DamageType, float DamageAmount, optional float DamageChance, optional Actor Damager)
{
	//native.DamageType;
	//native.DamageAmount;
	//native.DamageChance;
	//native.Damager;	
	@NULL
	@NULL
	return default.@NULL;
}

function TakeScriptedDamage(DamageStimuliSet.DamageStimulusType DamageType, float DamageAmount, optional float DamageChance, optional Actor Damager)
{
	//native.DamageType;
	//native.DamageAmount;
	//native.DamageChance;
	//native.Damager;	
	@NULL
	@NULL
	return default.@NULL;
}

function TakeDamage(DamageStimuliSet DamageStimuli, float CritChance, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, float DamageAttenuation, optional name HitHighBone, optional name HitLowBone, optional bool WasMeleeAttack)
{
	//native.DamageStimuli;
	//native.CritChance;
	//native.Damager;
	//native.HitLocation;
	//native.HitNormal;
	//native.HitImpulseDirection;
	//native.EffectEventName;
	//native.DamageAttenuation;
	//native.HitHighBone;
	//native.HitLowBone;
	//native.WasMeleeAttack;	
	@NULL
	@NULL
	return default.@NULL;
}

function SetInvincible(bool inInvincible)
{
	bIsInvincible = inInvincible;
	return;
	@NULL
	Item
}

function bool IsInvincible()
{
	return bIsInvincible;
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
		return 0;
	}
	return;
}

function bool ActionBlockedByPawns()
{
	return true;
	return;
}

function name GetResistanceSetName()
{
	return DamageResistanceSetName;
	return;
	@NULL
}

function float GetUseDistance()
{
	return 0.0000000;
	return;
}

// Export UShockPawn::execGetResistanceSet(FFrame&, void* const)
native function DamageResistanceSet GetResistanceSet();

function bool ShouldTreatAsIntentionalDamage(Actor Damager, DamageStimuliSet DamageStimuli)
{
	// End:0x38
	if(__NFUN_130__(__NFUN_119__(Damager, none), __NFUN_119__(Damager, self)))
	{
		return DamageStimuli.CausesPain();
		return false;
		return;
		@NULL
		Item
	}
	stop;
	default.@NULL
}

function OnDealtDamage(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damagee, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, bool bIsCriticalHit, optional name HitHighBone, optional name HitLowBone)
{
	local ShockPawn PawnDamagee;

	PawnDamagee = ShockPawn(Damagee);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6B
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6B
	/*@Error*/
	NotifyControllablesControllerDealtDamage(PawnDamagee, TotalDamageDealt);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function bool ShouldBeAttackedByControllablesWhenAttacked(ShockPawn DamagingPawn, DamageStimuliSet DamageStimuli)
{
	return DamageStimuli.CausesPain();
	return;
	@NULL
}

function OnDamaged(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, bool bIsCriticalHit, optional name HitHighBone, optional name HitLowBone)
{
	local ShockPawn theShockPawn;
	local ShockPlayerController PlayerController;
	local int DAMAGEDEBUGLEVEL;

	Level.SpawningManager.SendPawnTookDamageMessages(self, Damager);
	HandleCriticalDamageEffects(bIsCriticalHit);
	// End:0xE2
	if(__NFUN_130__(__NFUN_119__(Damager, self), ShouldTreatAsIntentionalDamage(Damager, DamageStimuli)))
	{
		theShockPawn = ShockPawn(Damager);
		// End:0xE2
		if(__NFUN_119__(theShockPawn, none))
		{
			// End:0xE2
			if(AttackerShouldBeConsideredIntentional(theShockPawn))
			{
				AddIntentionalAttacker(theShockPawn);
				NotifyControllablesControllerDamaged(theShockPawn, TotalDamageDealt);
				PlayerController = ShockPlayerController(Level.GetLocalPlayerController());
				// End:0x167
				if(__NFUN_114__(PlayerController, Controller))
				{
					PlayerController.GetPlayerStatsManager().PlayerDamaged(ShockPlayer(self), TotalDamageDealt, Damager);
				}
			}
		}
		goto J0x21C;
		// End:0x21C
		if(__NFUN_114__(Damager, PlayerController.Pawn))
		{
			PlayerController.GetPlayerStatsManager().PlayerDealtDamage(TotalDamageDealt, self);
			// End:0x21C
			if(__NFUN_130__(DamageStimuli.HasDamageStimulusType(34), __NFUN_129__(__NFUN_303__('Protector'))))
			{
			}
			PlayerController.GetPlayerStatsManager().BefriendUsed("NotProtector");
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x291
			/*@Error*/
			DAMAGEDEBUGLEVEL = 4;
			goto J0x29D;
			DAMAGEDEBUGLEVEL = 3;
			log('Damage', byte(DAMAGEDEBUGLEVEL), __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " took "), string(TotalDamageDealt)), " total damage (Health: "), string(Health)), ") from "), string(Damager.Name)));
		}
	}
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function OnKilled(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, bool bIsCriticalHit, optional name HitHighBone, optional name HitLowBone)
{
	local ShockPawn DamagerShockPawn;
	local ShockPlayerController PlayerController;

	HandleCriticalDamageEffects(bIsCriticalHit);
	Killer = Damager;
	KilledHitLocation = HitLocation;
	KilledHitNormal = HitNormal;
	DamagerShockPawn = ShockPawn(Damager);
	// End:0xA1
	if(__NFUN_130__(__NFUN_119__(DamagerShockPawn, none), __NFUN_119__(Damager, self)))
	{
		DamagerShockPawn.OnKilledOtherPawn(self);
		dispatchMessage(Class'ShockGame.MessagePawnDied'.static.Allocate(self)., construct_ShockPawn(self));
		UntriggerEffectsOnDeath(false);
	}
	PlayerController = ShockPlayerController(Level.GetLocalPlayerController());
	// End:0x196
	if(__NFUN_114__(Damager, PlayerController.Pawn))
	{
		PlayerController.GetPlayerStatsManager().PlayerDealtDamage(TotalDamageDealt, self);
		PlayerController.GetPlayerStatsManager().KilledByPlayer(ShockPlayer(Damager), self);
		goto J0x21C;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x21C
		/*@Error*/
		PlayerController.GetPlayerStatsManager().PlayerDamaged(ShockPlayer(self), TotalDamageDealt, Damager);
		PlayerController.GetPlayerStatsManager().PlayerDied(Damager);
		NotifyControllablesOwnerKilled();
	}
	UnregisterAllControllables();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x247
	/*@Error*/
	CreateFireRepeller();
	__NFUN_113__('Dying');
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function UntriggerEffectsOnDeath(bool bIsDestruction)
{
	local int i;

	i = 0;
	// End:0xBC
	if(__NFUN_150__(i, UntriggerEffectEventInfos.Length))
	{
		// End:0xAE
		if(__NFUN_132__(__NFUN_129__(UntriggerEffectEventInfos[i].bOnlyOnDestruction), bIsDestruction))
		{
			UnTriggerEffectEvent(UntriggerEffectEventInfos[i].EffectEventName, UntriggerEffectEventInfos[i].EffectEventTag);
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x0B;
			i = 0;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x117
			/*@Error*/
			Attached[i].TriggerEffectEvent('OwnerDied');
		}
		__NFUN_163__(i);
		goto J0xC7;
		return;
	}
	@NULL
	Item
	J0xC7:

	ShockPawn
	@NULL
}

function HandleCriticalDamageEffects(bool bIsCriticalHit)
{
	local int i;
	local float DamagePct;

	DamagePct = __NFUN_172__(Health, GetMaxHealth());
	log('Damage', 5, __NFUN_112__(__NFUN_112__(string(Name), " HandleCriticalDamageEffects - DamagePct: "), string(DamagePct)));
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2B2
	/*@Error*/
	log('Damage', 5, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Looking at Critical Damage Info at index: ", string(i)), " - EffectEvent: "), string(CriticalDamageEffectInfos[i].EffectEvent)), " Damage Percentage: "), string(CriticalDamageEffectInfos[i].DamagePercentage)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2A4
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x24F
	/*@Error*/
	UnTriggerEffectEvent(CriticalDamageEffectInfos[i].EffectEvent);
	goto J0x27D;
	TriggerEffectEvent(CriticalDamageEffectInfos[i].EffectEvent);
	CriticalDamageEffectInfos[i].bHasBeenUsed = true;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x80;
	return;
	@NULL
	Item
	Item
	@NULL
}

function RemoveCriticalDamageEffects()
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x87
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x79
	/*@Error*/
	UnTriggerEffectEvent(CriticalDamageEffectInfos[i].EffectEvent);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	Item
	@NULL
}

function float GetDamageResistanceTo(Class<IProvideDamageData> DamageDataClass)
{
	//native.DamageDataClass;	
	@NULL
}

// Export UShockPawn::execDestroyManagedObjects(FFrame&, void* const)
native function DestroyManagedObjects();

function Destroyed()
{
	NotifyControllablesOwnerDestroyed();
	UnregisterAllControllables();
	// End:0x46
	if(__NFUN_119__(DoorPawnIsIn, none))
	{
		DoorPawnIsIn.PawnInDoorWasDestroyed(self);
		DoorPawnIsIn = none;
		RemoveCriticalDamageEffects();
		UntriggerEffectsOnDeath(true);
	}
	super.Destroyed();
	DestroyManagedObjects();
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function OnKilledOtherPawn(ShockPawn Killee)
{
	return;
}

function TestUnTrigger(name EventName)
{
	log('Testing', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::TestUnTrigger( "), string(EventName)), " )"));
	UnTriggerEffectEvent(EventName);
	return;
	@NULL
	Item
}

function TestTrigger(name EventName, optional float inValue, optional float inDuration)
{
	local ModEffectEventInfo testInfo;

	// End:0x89
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'TestTrigger', but that command is disabled in the CENSORED version.");
		goto J0x1A5;
		log('Testing', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::TestTrigger( "), string(EventName)), ", "), string(inValue)), ", "), string(inDuration)), " )"));
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x181
	/*@Error*/
	testInfo = Class'Engine.ModEffectEventInfo'.static.Allocate(self).;
	Construct_Void();
	testInfo.Value = inValue;
	testInfo.Duration = inDuration;
	TriggerEffectEvent(EventName,,,,,,,,, testInfo);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function TestUnTriggerPlayerEffectEvent(name EventName, name tagName)
{
	UnTriggerEffectEvent(EventName, tagName);
	return;
	@NULL
	Item
}

function TestTriggerPlayerEffectEvent(name EventName, name tagName)
{
	// End:0x9A
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'TestTriggerPlayerEffectEvent', but that command is disabled in the CENSORED version.");
		goto J0xBD;
		TriggerEffectEvent(EventName,,,,,,,, tagName);
	}
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function TestModify(name GroupName, float inValue)
{
	log('Testing', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::TestModify( "), string(GroupName)), ", "), string(inValue)), " )......  "));
	log('Testing', 3, __NFUN_112__("...... returning: ", string(ModifyStat(GroupName, inValue))));
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function LogEffectsHelper(name EffectEvent, Actor theActor)
{
	local int numExistingEvents, i;
	local string tmp;
	local bool ShouldClearAllLogging;

	ShouldClearAllLogging = __NFUN_130__(__NFUN_114__(theActor, none), __NFUN_254__(EffectEvent, 'None'));
	log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__("EffectEvent is ", string(EffectEvent)), ", TheActor is "), string(theActor)));
	// End:0xB9
	if(__NFUN_119__(theActor, none))
	{
		log('EffectEvent', 3, __NFUN_112__("LogEffects on actor ", string(theActor)));
		goto J0xF4;
		log('EffectEvent', 3, __NFUN_112__("LogEffects for effect event ", string(EffectEvent)));
	}
	numExistingEvents = EffectsSystem(Level.EffectsSystem).EventsToLog.Length;
	// End:0x1BF
	if(__NFUN_132__(ShouldClearAllLogging, __NFUN_254__(EffectEvent, 'All')))
	{
		numExistingEvents = EffectsSystem(Level.EffectsSystem).EventsToLog.Length;
		EffectsSystem(Level.EffectsSystem).EventsToLog.Remove(0, numExistingEvents);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x4C2
		/*@Error*/
		numExistingEvents = EffectsSystem(Level.EffectsSystem).EventsToLog.Length;
		EffectsSystem(Level.EffectsSystem).EventsToLog.Insert(numExistingEvents, 1);
		EffectsSystem(Level.EffectsSystem).EventsToLog[numExistingEvents].Event = EffectEvent;
	}
	EffectsSystem(Level.EffectsSystem).EventsToLog[numExistingEvents].Actor = theActor;
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x469
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x3EE
	/*@Error*/
	tmp = __NFUN_112__(__NFUN_112__(__NFUN_112__(tmp, "Actor:"), string(EffectsSystem(Level.EffectsSystem).EventsToLog[i].Actor.Name)), " ");
	goto J0x45B;
	tmp = __NFUN_112__(__NFUN_112__(__NFUN_112__(tmp, "Event:"), string(EffectsSystem(Level.EffectsSystem).EventsToLog[i].Event)), " ");
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x2E9;
	Level.GetLocalPlayerController().ClientMessage(__NFUN_112__(__NFUN_112__("Now logging FX for: [ ", tmp), "]"), 'EffectEvent');
	goto J0x513;
	Level.GetLocalPlayerController().ClientMessage("Now logging FX for: [ <Nothing> ]", 'EffectEvent');
	return;
	@NULL
	Item
	Item
	@NULL
}

function LogEffects(name EffectEvent)
{
	LogEffectsHelper(EffectEvent, none);
	return;
	@NULL
}

exec function LogEffectsAtFocus()
{
	LogEffectsOnFocusedActor();
	return;
}

function LogEffectsOnFocusedActor()
{
	local Vector startTrace, HitLocation, HitNormal, endTrace;
	local Actor hit;
	local Pawn Player;

	Player = Level.GetLocalPlayerController().Pawn;
	// End:0x79
	if(__NFUN_119__(Player, none))
	{
		startTrace = __NFUN_215__(Player.Location, Player.EyePosition());
		goto J0xA7;
		startTrace = Level.GetLocalPlayerController().Location;
		endTrace = __NFUN_215__(startTrace, __NFUN_212__(Vector(Rotation), float(500000)));
	}
	// End:0x12E
	if(__NFUN_119__(Player, none))
	{
		hit = Player.__NFUN_277__(HitLocation, HitNormal, endTrace, startTrace, true, vect(10.0000000, 10.0000000, 10.0000000));
		goto J0x188;
		hit = Level.GetLocalPlayerController().__NFUN_277__(HitLocation, HitNormal, endTrace, startTrace, true, vect(10.0000000, 10.0000000, 10.0000000));
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x1CD
		/*@Error*/
		LogEffectsHelper('None', hit);
	}
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function DumpMods()
{
	log('Testing', 4, __NFUN_112__(string(self), "::DumpMods()"));
	ModManager.DumpMods();
	return;
	@NULL
}

function GiveWeapon(string WeaponName)
{
	local Class<Weapon> weaponClass;
	local Weapon theWeapon;

	log('Testing', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::GiveWeapon( "), WeaponName), " )"));
	weaponClass = Class<Weapon>(DynamicLoadObject(WeaponName, Class'Core.Class'));
	theWeapon = weaponClass.static.Allocate(self).;
	Construct_Void();
	log('Testing', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::GiveWeapon( "), WeaponName), " )... weaponClass = "), string(weaponClass)), ", theWeapon = "), string(theWeapon)));
	AddAvailableHoldable(theWeapon);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function testEquip(int Index)
{
	local Holdable theWeapon;

	log('Testing', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::testEquip( "), string(Index)), " )"));
	theWeapon = GetHoldable(Index);
	log('Testing', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::Equip( "), string(Index)), " )... theWeapon = "), string(theWeapon)));
	Equip(theWeapon);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function testBeginFiring(optional bool inAltFire)
{
	log('Testing', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::testBeginFiring( "), string(inAltFire)), " )"));
	BeginFiring(inAltFire);
	return;
	@NULL
	Item
}

function testCeaseFiring(optional bool inAltFire)
{
	log('Testing', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::testCeaseFiring( "), string(inAltFire)), " )"));
	CeaseFiring(inAltFire);
	return;
	@NULL
	Item
}

exec function testReload()
{
	log('Testing', 4, __NFUN_112__(string(self), "::testReload()"));
	ReloadWeapon();
	return;
}

function bool testSelectAmmo(string AmmoClassName)
{
	local Class<Ammunition> AmmoClass;

	log('Testing', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::testSelectAmmo( "), AmmoClassName), " )"));
	AmmoClass = Class<Ammunition>(DynamicFindObject(AmmoClassName, Class'Core.Class'));
	return SelectAmmo(AmmoClass);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

// Export UShockPawn::execTakeFallingDamage(FFrame&, void* const)
native function TakeFallingDamage();

function bool HasTargetAttackedUsIntentionally(ShockPawn Target)
{
	//native.Target;	
	@NULL
}

function AddIntentionalAttacker(ShockPawn Attacker)
{
	//native.Attacker;	
	@NULL
}

function RemoveIntentionalAttacker(ShockPawn Attacker)
{
	//native.Attacker;	
	@NULL
}

function bool AttackerShouldBeConsideredIntentional(ShockPawn Attacker)
{
	//native.Attacker;	
	@NULL
}

function ClearIntentionalAttackers()
{
	IntentionalAttackers.Remove(0, IntentionalAttackers.Length);
	return;
	@NULL
	Item
}

function bool IsValidBotAttackTarget()
{
	return IsAlive();
	return;
}

// Export UShockPawn::execCanBeAttacked(FFrame&, void* const)
native function bool CanBeAttacked();

// Export UShockPawn::execGetAverageVelocity(FFrame&, void* const)
native final function Vector GetAverageVelocity();

function RegisterControllable(ICanBeControlled Controllable)
{
	local int i;

	AssertWithDescription(__NFUN_132__(CanHaveMoreProtectorControllables(), CanHaveMoreBotControllables()), __NFUN_112__("The player cannot be given any more controllables like: ", string(Controllable)));
	i = 0;
	// End:0x127
	if(__NFUN_150__(i, OwnedControllables.Length))
	{
		// End:0x119
		if(__NFUN_114__(Controllable, OwnedControllables[i]))
		{
			log(,, __NFUN_112__("Trying to register an ICanBeControlled that is already registered.  Controllable = ", string(Controllable)));
			return;
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x75;
			log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__("REGISTERING CONTROLLABLE ", string(Controllable)), " WITH "), string(self)));
		}
	}
	OwnedControllables[OwnedControllables.Length] = Controllable;
	Controllable.OnRegistered(self);
	return;
	@NULL
	Item
	Item
	@NULL
}

function UnregisterControllable(ICanBeControlled Controllable)
{
	local int i;

	log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__("UNREGISTERING CONTROLLABLE ", string(Controllable)), " WITH "), string(self)));
	i = 0;
	// End:0xC0
	if(__NFUN_150__(i, OwnedControllables.Length))
	{
		// End:0xB2
		if(__NFUN_114__(Controllable, OwnedControllables[i]))
		{
			OwnedControllables.Remove(i, 1);
			Controllable.OnUnregistered(self);
			return;
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x4B;
			log(,, __NFUN_112__("Trying to unregister an ICanBeControlled that is not registered.  Controllable = ", string(Controllable)));
		}
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function UnregisterAllControllables()
{
	local int i;
	local array<ICanBeControlled> ControllableListCopy;

	ControllableListCopy = OwnedControllables;
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x66
	/*@Error*/
	ControllableListCopy[i].OnUnregistered(self);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x1E;
	OwnedControllables.Length = 0;
	return;
	@NULL
	Item
	Item
	@NULL
}

function NotifyControllablesOwnerKilled()
{
	local int i;
	local array<ICanBeControlled> ControllableListCopy;

	ControllableListCopy = OwnedControllables;
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x66
	/*@Error*/
	ControllableListCopy[i].OnControllerKilled(self);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x1E;
	return;
	@NULL
	Item
	Item
	@NULL
}

function NotifyControllablesOwnerDestroyed()
{
	local int i;
	local array<ICanBeControlled> ControllableListCopy;

	ControllableListCopy = OwnedControllables;
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x66
	/*@Error*/
	ControllableListCopy[i].OnControllerDestroyed(self);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x1E;
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool CanHaveMoreBotControllables()
{
	return __NFUN_150__(GetNumBotControllables(), MaxBotControllables);
	return;
	@NULL
}

function bool CanHaveMoreProtectorControllables()
{
	return __NFUN_150__(GetNumProtectorControllables(), 1);
	return;
}

function int GetNumBotControllables()
{
	local int i, NumBotControllables;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x62
	/*@Error*/
	// End:0x54
	if(OwnedControllables[i].__NFUN_303__('SecurityBot'))
	{
		__NFUN_163__(NumBotControllables);
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x0B;
		return NumBotControllables;
		return;
		@NULL
		Item
	}
	Item
	@NULL
}

function int GetNumProtectorControllables()
{
	local int i, NumProtectorControllables;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x62
	/*@Error*/
	// End:0x54
	if(OwnedControllables[i].__NFUN_303__('Protector'))
	{
		__NFUN_163__(NumProtectorControllables);
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x0B;
		return NumProtectorControllables;
		return;
		@NULL
		Item
	}
	Item
	@NULL
}

function int GetNumControllables()
{
	return OwnedControllables.Length;
	return;
	@NULL
}

function AttackTargetWithControllables(ShockPawn Target, bool ForceNewTarget)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x65
	/*@Error*/
	OwnedControllables[i].AttackSpecifiedTarget(Target, ForceNewTarget);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function AttackTargetWithBots(ShockPawn Target, bool ForceNewTarget)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x8B
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x7D
	/*@Error*/
	OwnedControllables[i].AttackSpecifiedTarget(Target, ForceNewTarget);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function NotifyControllablesControllerDamaged(ShockPawn Damager, float Damage)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x64
	/*@Error*/
	OwnedControllables[i].OnControllerDamaged(Damager, Damage);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	Item
	@NULL
}

function NotifyControllablesControllerDealtDamage(ShockPawn Damagee, float Damage)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x64
	/*@Error*/
	OwnedControllables[i].OnControllerDealtDamage(Damagee, Damage);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool OwnsControllable(ICanBeControlled Controllable)
{
	//native.Controllable;	
	@NULL
}

function int GetNumSectors()
{
	return NumControllableSectors;
	return;
	@NULL
}

function int GetAvailableSector()
{
	local array<int> AvailableSectors;
	local int i, j;
	local bool ControllableInSector;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xD8
	/*@Error*/
	ControllableInSector = false;
	j = 0;
	// End:0x9D
	if(__NFUN_150__(j, OwnedControllables.Length))
	{
		// End:0x8F
		if(__NFUN_154__(OwnedControllables[j].GetSector(), i))
		{
			ControllableInSector = true;
			goto J0x9D;
			__NFUN_163__(j);
			// [Loop Continue]
			goto J0x39;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0xCA
			/*@Error*/
			AvailableSectors[AvailableSectors.Length] = i;
			__NFUN_163__(i);
		}
		// [Loop Continue]
		goto J0x0B;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xFF
		/*@Error*/
	}
	return AvailableSectors[__NFUN_167__(AvailableSectors.Length)];
	return __NFUN_167__(NumControllableSectors);
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnAcquiredState(name StateName, Actor StateInstigator)
{
	CurrentAcquiredState = StateName;
	dispatchMessage(Class'ShockGame.MessagePawnAquiredState'.static.Allocate(self)., construct_ShockPawnNameBool(self, StateName, false));
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function OnUnAcquiredState(name StateName)
{
	CurrentAcquiredState = 'None';
	dispatchMessage(Class'ShockGame.MessagePawnAquiredState'.static.Allocate(self)., construct_ShockPawnNameBool(self, StateName, true));
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function SetDoorPawnIsIn(ShockDoor inDoor)
{
	//native.inDoor;	
	@NULL
}

function bool CanOpenDoors()
{
	return true;
	return;
}

event HitByAirBlast(Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, float HitMomentumImparted, name HitLowBone, name HitHighBone, DamageStimuliSet DamageStimuli)
{
	return;
}

event HitBySpringBoardTrap(Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, float HitMomentumImparted, name HitLowBone, name HitHighBone, DamageStimuliSet DamageStimuli)
{
	return;
}

// Export UShockPawn::execIsPassive(FFrame&, void* const)
native function bool IsPassive();

// Export UShockPawn::execIsAggressive(FFrame&, void* const)
native function bool IsAggressive();

function name GetPatrolName()
{
	return 'None';
	return;
}

delegate Actor OnPushGetPushee()
{
	return none;
	return;
}

function Actor GetPusheeFromPush()
{
	return OnPushGetPushee();
	return;
	@NULL
}

// Export UShockPawn::execGetStaticIlluminationLevel(FFrame&, void* const)
native function float GetStaticIlluminationLevel();

function OnTelekinesisStartedPulling(TelekinesisAbility Telekinesis)
{
	SetInfernoID(0);
	return;
}

function OnTelekinesisStartedThrowing(TelekinesisAbility Telekinesis)
{
	return;
}

function OnTelekinesisStartedHolding(TelekinesisAbility Telekinesis)
{
	return;
}

function OnTelekinesisStartedDroping(TelekinesisAbility Telekinesis)
{
	return;
}

function Actor GetAffectedActor()
{
	local Actor AffectedActor;

	// End:0x1D
	if(__NFUN_129__(IsAlive()))
	{
		AffectedActor = self;
		goto J0x28;
		AffectedActor = none;
	}
	return AffectedActor;
	return;
	J0x28:

	@NULL
	Item
	Item
}

function PreTelekinesis()
{
	return;
}

function bool IsAffectedByTelekinesis()
{
	// End:0x12
	if(IsCensoredContent())
	{
		return false;
		goto J0x41;
		return __NFUN_130__(__NFUN_130__(__NFUN_129__(IsAlive()), __NFUN_129__(bTelekinesisDisabled)), __NFUN_129__(IsGatherer()));
	}
	return;
	@NULL
	Item
}

function ShutdownHackingScreenIfOpenedOnSelf()
{
	local ShockPlayerController PlayerController;
	local ShockPlayer Player;

	Player = ShockPlayer(Level.GetLocalPlayerController().Pawn);
	PlayerController = ShockPlayerController(Level.GetLocalPlayerController());
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x104
	/*@Error*/
	Player.CloseHackingScreen();
	PlayerController.ForceUnPause();
	return;
	@NULL
	Item
	Item
	@NULL
}

state Dying
{Begin:

	__NFUN_113__('Dead');
	stop;				
}

state Dead
{	stop;
}

defaultproperties
{
	DamageResistanceSetName="DefaultResistanceSet"
	BaseCriticalHitChanceModifier=1.0000000
	BaseCriticalHitAmountModifier=2.0000000
	MaxHealth=200.0000000
	MaxFrozenHealth=350.0000000
	DamageToRegularHealthWhileFrozenModifer=0.2500000
	HealthBarNormalOffset=(X=0.0000000,Y=0.0000000,Z=70.0000000)
	HealthBarCeilingOffset=(X=0.0000000,Y=0.0000000,Z=-70.0000000)
	CollisionAvoidancePushDistance=5.0000000
	CollisionAvoidancePushStrength=50.0000000
	FallingDamageLinearMultiplier=1.4000000
	FallingDamageStimuliSetName="FallingDamageStimuliSet"
	SecurityBeaconDuration=12.0000000
	SecurityBeaconTimeoutWarning=5.0000000
	SecurityBeaconEndTime=-1.0000000
	MaxBotControllables=2
	NumControllableSectors=8
	ControllableDamageMultiplier=0.2000000
	UntriggerEffectEventInfos[0]=(EffectEventName="TaggedWithSecurityBeacon",EffectEventTag="None",bOnlyOnDestruction=false)
	UntriggerEffectEventInfos[1]=(EffectEventName="TaggedWithAggressorIrritant",EffectEventTag="None",bOnlyOnDestruction=false)
	UntriggerEffectEventInfos[2]=(EffectEventName="HalfHealth",EffectEventTag="None",bOnlyOnDestruction=false)
	UntriggerEffectEventInfos[3]=(EffectEventName="QuarterHealth",EffectEventTag="None",bOnlyOnDestruction=false)
	UntriggerEffectEventInfos[4]=(EffectEventName="AggressorAlive",EffectEventTag="None",bOnlyOnDestruction=false)
	UntriggerEffectEventInfos[5]=(EffectEventName="Hurt",EffectEventTag="None",bOnlyOnDestruction=false)
	UntriggerEffectEventInfos[6]=(EffectEventName="MeleeSparkDrag",EffectEventTag="None",bOnlyOnDestruction=false)
	UntriggerEffectEventInfos[7]=(EffectEventName="HalfHurt",EffectEventTag="None",bOnlyOnDestruction=false)
	UntriggerEffectEventInfos[8]=(EffectEventName="FriendlyToPlayer",EffectEventTag="None",bOnlyOnDestruction=false)
	UntriggerEffectEventInfos[9]=(EffectEventName="NeutralToPlayer",EffectEventTag="None",bOnlyOnDestruction=false)
	UntriggerEffectEventInfos[10]=(EffectEventName="HostileToPlayer",EffectEventTag="None",bOnlyOnDestruction=false)
	UntriggerEffectEventInfos[11]=(EffectEventName="VeryHurt",EffectEventTag="None",bOnlyOnDestruction=false)
	UntriggerEffectEventInfos[12]=(EffectEventName="NearDeath",EffectEventTag="None",bOnlyOnDestruction=false)
	UntriggerEffectEventInfos[13]=(EffectEventName="LightsOn",EffectEventTag="None",bOnlyOnDestruction=false)
	UntriggerEffectEventInfos[14]=(EffectEventName="Alive",EffectEventTag="None",bOnlyOnDestruction=false)
	UntriggerEffectEventInfos[15]=(EffectEventName="Alive",EffectEventTag="Light",bOnlyOnDestruction=false)
	UntriggerEffectEventInfos[16]=(EffectEventName="FlameOn",EffectEventTag="None",bOnlyOnDestruction=false)
	UntriggerEffectEventInfos[17]=(EffectEventName="BoxFire",EffectEventTag="None",bOnlyOnDestruction=false)
	UntriggerEffectEventInfos[18]=(EffectEventName="TeleportOutStage_1",EffectEventTag="None",bOnlyOnDestruction=false)
	UntriggerEffectEventInfos[19]=(EffectEventName="DamagedDead",EffectEventTag="None",bOnlyOnDestruction=true)
	UntriggerEffectEventInfos[20]=(EffectEventName="AcquiredState",EffectEventTag="Burning",bOnlyOnDestruction=true)
	UntriggerEffectEventInfos[21]=(EffectEventName="AcquiredState",EffectEventTag="Berserk",bOnlyOnDestruction=false)
	UntriggerEffectEventInfos[22]=(EffectEventName="AcquiredState",EffectEventTag="Shocked",bOnlyOnDestruction=true)
	UntriggerEffectEventInfos[23]=(EffectEventName="AcquiredState",EffectEventTag="Frozen",bOnlyOnDestruction=false)
	UntriggerEffectEventInfos[24]=(EffectEventName="BouncerPulseWeaponStart",EffectEventTag="None",bOnlyOnDestruction=false)
	UntriggerEffectEventInfos[25]=(EffectEventName="Aggressive",EffectEventTag="None",bOnlyOnDestruction=false)
	UntriggerEffectEventInfos[26]=(EffectEventName="ScriptTrigger",EffectEventTag="GhostNearby",bOnlyOnDestruction=false)
	BerserkTimeoutWarning=5.0000000
	DiseasedTimeout=60.0000000
	BurningTimeout=16.0000000
	FrozenTimeout=6.0000000
	BerserkTimeout=10.0000000
	ShockedTimeout=6.0000000
	ShockedInWaterTimeout=10.0000000
	DiseaseSpreadCheckInterval=1.0000000
	DiseaseSpreadCheckRadius=200.0000000
	DefaultDamageEventInfos[0]=(EntryParameters=(DamageType=0,DamageStrength=0,DamagerClass=Class'Engine.Actor'),EntryEventInfo=(DamageEvent=2,PassiveChance=1.0000000,AggressiveChance=1.0000000,ReactionCoolOffTime=0.2500000,FailedDamageEvent=3,bTriggerOnce=false,bTriggerWhenDead=false,bHasBeenUsed=false,ReactionCoolOffEndTime=0.0000000))
	DefaultDamageEventInfos[1]=(EntryParameters=(DamageType=0,DamageStrength=1,DamagerClass=Class'Engine.Actor'),EntryEventInfo=(DamageEvent=2,PassiveChance=1.0000000,AggressiveChance=1.0000000,ReactionCoolOffTime=0.2500000,FailedDamageEvent=3,bTriggerOnce=false,bTriggerWhenDead=false,bHasBeenUsed=false,ReactionCoolOffEndTime=0.0000000))
	DefaultDamageEventInfos[2]=(EntryParameters=(DamageType=0,DamageStrength=2,DamagerClass=Class'Engine.Actor'),EntryEventInfo=(DamageEvent=2,PassiveChance=1.0000000,AggressiveChance=1.0000000,ReactionCoolOffTime=0.2500000,FailedDamageEvent=3,bTriggerOnce=false,bTriggerWhenDead=false,bHasBeenUsed=false,ReactionCoolOffEndTime=0.0000000))
	DefaultDamageEventInfos[3]=(EntryParameters=(DamageType=1,DamageStrength=0,DamagerClass=Class'Engine.Actor'),EntryEventInfo=(DamageEvent=2,PassiveChance=1.0000000,AggressiveChance=1.0000000,ReactionCoolOffTime=0.2500000,FailedDamageEvent=3,bTriggerOnce=false,bTriggerWhenDead=false,bHasBeenUsed=false,ReactionCoolOffEndTime=0.0000000))
	DefaultDamageEventInfos[4]=(EntryParameters=(DamageType=1,DamageStrength=1,DamagerClass=Class'Engine.Actor'),EntryEventInfo=(DamageEvent=2,PassiveChance=1.0000000,AggressiveChance=1.0000000,ReactionCoolOffTime=0.2500000,FailedDamageEvent=3,bTriggerOnce=false,bTriggerWhenDead=false,bHasBeenUsed=false,ReactionCoolOffEndTime=0.0000000))
	DefaultDamageEventInfos[5]=(EntryParameters=(DamageType=1,DamageStrength=2,DamagerClass=Class'Engine.Actor'),EntryEventInfo=(DamageEvent=2,PassiveChance=1.0000000,AggressiveChance=1.0000000,ReactionCoolOffTime=0.2500000,FailedDamageEvent=3,bTriggerOnce=false,bTriggerWhenDead=false,bHasBeenUsed=false,ReactionCoolOffEndTime=0.0000000))
	DefaultDamageEventInfos[6]=(EntryParameters=(DamageType=2,DamageStrength=0,DamagerClass=Class'Engine.Actor'),EntryEventInfo=(DamageEvent=2,PassiveChance=1.0000000,AggressiveChance=1.0000000,ReactionCoolOffTime=0.2500000,FailedDamageEvent=3,bTriggerOnce=false,bTriggerWhenDead=false,bHasBeenUsed=false,ReactionCoolOffEndTime=0.0000000))
	DefaultDamageEventInfos[7]=(EntryParameters=(DamageType=2,DamageStrength=1,DamagerClass=Class'Engine.Actor'),EntryEventInfo=(DamageEvent=2,PassiveChance=1.0000000,AggressiveChance=1.0000000,ReactionCoolOffTime=0.2500000,FailedDamageEvent=3,bTriggerOnce=false,bTriggerWhenDead=false,bHasBeenUsed=false,ReactionCoolOffEndTime=0.0000000))
	DefaultDamageEventInfos[8]=(EntryParameters=(DamageType=2,DamageStrength=2,DamagerClass=Class'Engine.Actor'),EntryEventInfo=(DamageEvent=2,PassiveChance=1.0000000,AggressiveChance=1.0000000,ReactionCoolOffTime=0.2500000,FailedDamageEvent=3,bTriggerOnce=false,bTriggerWhenDead=false,bHasBeenUsed=false,ReactionCoolOffEndTime=0.0000000))
	CriticalHitDamageEvent=1
	GroundSpeed=450.0000000
	MovingInWaterPenalty=0.8500000
	JumpZ=525.0000000
	CrouchedPct=0.4500000
	BackwardsPct=0.6500000
	MaxDistanceToFallWithoutDamage=500.0000000
	BaseEyeHeight=60.0000000
	CrouchEyeHeight=36.0000000
	Health=200.0000000
	WaterMovementState="PlayerWalking"
	AILookAtType=3
	bNeedPressureChangeEffectEvents=true
}