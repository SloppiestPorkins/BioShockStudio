class TrapBoltProjectile extends CrossbowProjectile implements IDamagee, IPotentialAimTarget
	native
	config(Weapons)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Animation);

var private const config float PrimingTime;
var private const config float MaxWireDamageDistance;
var private const config float SpawnOffset;
var private const config float HookEffectOffset;
var private const config name WireTriggeredStimuliSetName;
var private const config float WireHookSpeed;
var private const config Class<TrapBoltWireHook> WireHookClass;
var private const config float MinimumDamageToTrigger;
var private TrapBoltWireHook WireHookInstance;
var private transient Vector WireStartPoint;
var private transient Vector WireEndPoint;
var private config Class<Emitter> BeamEffectClass;
var private Emitter BeamEffectActorInstance;
var private bool IsArmed;
var private transient float NextTickTime;
var private const config float TickDelta;
var private const config float LowLODTickDelta;
var private bool HasBeenTriggered;
var private bool WireHookHasEngaged;
var private Actor TriggeringActor;
var private Vector TriggeringLocation;
var private config localized string ArmedFriendlyName;
var private config localized string UnarmedFriendlyName;
var private config float ChanceToBreakAfterTriggered;
var private config Range ElectricityOnIntervalRange;
var private config Range ElectricityOffIntervalRange;
var private float NextSwitchTime;
var private float WireSagAmount;
var private config float TriggeredShockTime;
var bool CheckWireForCollisions;
var private transient FluidVolume CurrentFluidVolume;

function TakeDamage(DamageStimuliSet DamageStimuli, float CritChance, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, float DamageAttenuation, name HitHighBone, name HitLowBone, bool WasMeleeAttack)
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

function TakeScriptedDamage(DamageStimuliSet.DamageStimulusType DamageType, float DamageAmount, float DamageChance, optional Actor Damager)
{
	return;
}

function Touch(Actor Other)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x97
	/*@Error*/
	WireTripped(Other, Other.Location);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function bool IsAffectedByTelekinesis()
{
	// End:0x58
	if(Level.bIsDLC1Level)
	{
		// End:0x48
		if(Damager.__NFUN_303__('ShockPlayer'))
		{
			return __NFUN_129__(__NFUN_281__('Arming'));
			goto J0x55;
			return __NFUN_281__('Armed');
		}
		goto J0x63;
		return super.IsAffectedByTelekinesis();
		return;
		J0x55:

		@NULL
	}
	Item
	Item
	@NULL
}

event Arm()
{
	__NFUN_113__('Arming');
	return;
}

function WireTripped(Actor inTriggeringActor, Vector inTriggeringLocation)
{
	TriggeringActor = inTriggeringActor;
	TriggeringLocation = inTriggeringLocation;
	__NFUN_113__('Triggered');
	IsArmed = false;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function Destroyed()
{
	CurrentFluidVolume = none;
	DeactivateWire();
	// End:0x3F
	if(__NFUN_119__(WireHookInstance, none))
	{
		WireHookInstance.__NFUN_279__();
		WireHookInstance = none;
		super.Destroyed();
		return;
		@NULL
		Item
	}
	stop;
	default.@NULL
}

function bool CanBeUsedNow()
{
	// End:0x68
	if(Level.bIsDLC1Level)
	{
		return __NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_129__(IsArmed), __NFUN_129__(HasBeenTriggered)), super.CanBeUsedNow()), Damager.__NFUN_303__('ShockPlayer'));
		goto J0x95;
		return __NFUN_130__(__NFUN_130__(__NFUN_129__(IsArmed), __NFUN_129__(HasBeenTriggered)), super.CanBeUsedNow());
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function string GetFocusDisplayName()
{
	// End:0x17
	if(IsArmed)
	{
		return ArmedFriendlyName;
		return UnarmedFriendlyName;
		return;
	}
	@NULL
	Item
	Item
}

function IPotentialAimOrActionTarget.TargetType GetTargetType()
{
	// End:0x24
	if(__NFUN_130__(IsArmed, __NFUN_129__(HasBeenTriggered)))
	{
		return 2;
		goto J0x2F;
		return super.GetTargetType();
		return;
	}
	@NULL
	Item
	J0x2F:

	Item
}

function float GetUseDistance()
{
	return 0.0000000;
	return;
}

function bool BoltIsArmed()
{
	return IsArmed;
	return;
	@NULL
}

// Export UTrapBoltProjectile::execActivateWire(FFrame&, void* const)
private native function ActivateWire();

// Export UTrapBoltProjectile::execDeactivateWire(FFrame&, void* const)
private native function DeactivateWire();

// Export UTrapBoltProjectile::execShockNearbyActors(FFrame&, void* const)
private native function ShockNearbyActors();

function bool MoveTripWireHook(Vector hookDirection, float firingSpeed, float DeltaSeconds)
{
	//native.hookDirection;
	//native.firingSpeed;
	//native.DeltaSeconds;	
	@NULL
	@NULL
	return return @NULL;
}

function AutoArm()
{
	local Vector hookDirection;
	local int i;

	IsArmed = true;
	ActivateWire();
	hookDirection = __NFUN_211__(Vector(Rotation));
	WireEndPoint = __NFUN_215__(Location, __NFUN_212__(hookDirection, __NFUN_171__(__NFUN_169__(SpawnOffset), 2.0000000)));
	SpawnWireHook(WireEndPoint, Inverse(Rotation));
	WireHookHasEngaged = false;
	i = 0;
	// End:0xF3
	if(__NFUN_130__(__NFUN_150__(i, 100), __NFUN_129__(WireHookHasEngaged)))
	{
		WireHookHasEngaged = MoveTripWireHook(hookDirection, 1000000.0000000, 1.0000000);
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x9C;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x177
		/*@Error*/
		log('Weapons', 3, __NFUN_112__(__NFUN_112__("Could not deploy placed trap bolt ", string(self)), ".  Make sure it has something to stick the wire to."));
	}
	__NFUN_279__();
	return;
	__NFUN_113__('Armed');
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

function SpawnWireHook(Vector SpawnLocation, Rotator SpawnRotation)
{
	WireHookInstance = __NFUN_278__(WireHookClass, none,, SpawnLocation, SpawnRotation, true);
	assert(__NFUN_119__(WireHookInstance, none));
	WireHookInstance.OwnerTrapBolt = self;
	WireHookInstance.__NFUN_262__(false, false, false);
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function FireTripWire()
{
	local Vector hookDirection;
	local float lastMovedTime;

	ActivateWire();
	TriggerEffectEvent('WireHookFiring');
	hookDirection = __NFUN_211__(Vector(Rotation));
	WireHookHasEngaged = false;
	lastMovedTime = Level.TimeSeconds;
	WireEndPoint = __NFUN_215__(Location, __NFUN_212__(hookDirection, __NFUN_171__(__NFUN_169__(SpawnOffset), 2.0000000)));
	SpawnWireHook(WireEndPoint, Inverse(Rotation));
	WireHookInstance.TriggerEffectEvent('WireHookFiring');
	// End:0x15A
	if(__NFUN_129__(WireHookHasEngaged))
	{
		__NFUN_256__(0.0000000);
		WireHookHasEngaged = MoveTripWireHook(hookDirection, WireHookSpeed, __NFUN_175__(Level.TimeSeconds, lastMovedTime));
		lastMovedTime = Level.TimeSeconds;
		// [Loop Continue]
		goto J0xD8;
		WireHookInstance.UnTriggerEffectEvent('WireHookFiring');
		UnTriggerEffectEvent('WireHookFiring');
		TriggerEffectEvent('WireHookEngaged');
		WireHookInstance.TriggerEffectEvent('WireHookEngaged');
		return;
	}
	@NULL
	Collectable
	ShockPawn
	@NULL
}

function DispatchMessageTrapBoltTripped()
{
	dispatchMessage(Class'ShockGame.MessageTrapBoltTripped'.static.Allocate(self)., construct_Actor(Damager));
	return;
	@NULL
	Item
}

state Arming
{
	ignores Arm;
Begin:

	TriggerEffectEvent('StartedArming');
	__NFUN_256__(PrimingTime);
	IsArmed = true;
	FireTripWire();
	TriggerEffectEvent('FinishedArming');
	__NFUN_113__('Armed');
	stop;				
	@NULL
	@NULL
}

state Armed
{	stop;
}

state Triggered
{
	ignores Arm;
Begin:

	TriggerEffectEvent('WireTripped');
	IsArmed = false;
	HasBeenTriggered = true;
	bDisableTouch = true;
	DeactivateWire();
	ShockNearbyActors();
	ChanceToBreak = ChanceToBreakAfterTriggered;
	// End:0x95
	if(__NFUN_114__(WireHookInstance.Base, none))
	{
		WireHookInstance.__NFUN_279__();
		WireHookInstance = none;
		LifeSpan = -1.0000000;
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

defaultproperties
{
	PrimingTime=1.5000000
	MaxWireDamageDistance=15.0000000
	SpawnOffset=-28.0000000
	HookEffectOffset=7.0000000
	WireTriggeredStimuliSetName="TrapBoltWireStimuliSet"
	WireHookSpeed=3000.0000000
	WireHookClass=Class'ShockGame.ShockDesignerClasses.DefaultTrapBoltWireHook'
	MinimumDamageToTrigger=10.0000000
	BeamEffectClass=Class'ShockGame.FXClass.TrapBoltBeam'
	TickDelta=0.0500000
	LowLODTickDelta=0.3000000
	ArmedFriendlyName="Trap Bolt (Armed)"
	UnarmedFriendlyName="Trap Bolt (Unarmed)"
	ChanceToBreakAfterTriggered=0.5000000
	ElectricityOnIntervalRange=(Min=0.1000000,Max=0.2000000)
	ElectricityOffIntervalRange=(Min=0.5000000,Max=3.5000000)
	TriggeredShockTime=0.7000000
	CheckWireForCollisions=true
	MaxAngleOfDeflection=0.0000000
	ChanceToBreak=0.0000000
	GravityModifier=-1.0000000
	bApplyNormalGravityAfterImpact=true
}