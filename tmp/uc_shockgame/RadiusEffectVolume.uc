class RadiusEffectVolume extends Actor
	native
	config
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

var private config float Duration;
var private float ExpirationTime;
var private config float EffectRadius;
var private transient Actor EffectOwner;
var private config float SafeRadius;
var private config float ApplyEffectInterval;
var private config name SpawnAnimationName;
var private config name InEffectAnimationName;
var private config name DisperseAnimationName;
var private int CurrentAnimationHandle;

function SetEffectOwner(Actor inEffectOwner)
{
	EffectOwner = inEffectOwner;
	SetTimeToLive();
	return;
	@NULL
	Item
}

function SetTimeToLive()
{
	log('RadiusEffectVolume', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Telling ", string(Class.Name)), " to live for "), string(Duration)), " seconds."));
	ExpirationTime = __NFUN_174__(Level.TimeSeconds, Duration);
	__NFUN_113__('CheckingForExpiration');
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

function PlaySpawnAnimationSequence()
{
	TriggerEffectEvent('Spawned');
	FinishAnimation(PlayAnimationOnChannel(0, SpawnAnimationName));
	TriggerEffectEvent('InEffect');
	CurrentAnimationHandle = PlayAnimationOnChannel(0, InEffectAnimationName, 8);
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function PlayDisperseAnimation()
{
	FinishAnimation(CurrentAnimationHandle);
	UnTriggerEffectEvent('InEffect');
	TriggerEffectEvent('Dispersed');
	FinishAnimation(PlayAnimationOnChannel(0, DisperseAnimationName));
	return;
	@NULL
	Collectable
	Item
	@NULL
}

protected function bool IsValidTarget(Actor Target)
{
	return true;
	return;
}

protected function ApplyEffectTo(Actor Target)
{
	return;
}

function ApplyEffect()
{
	local Actor Actor;
	local float DistanceSquared, SafeRadiusSquared;

	TriggerEffectEvent('ApplyEffect');
	SafeRadiusSquared = __NFUN_171__(SafeRadius, SafeRadius);
	// End:0xCA
	foreach __NFUN_310__(Class'Engine.Actor', Actor, EffectRadius)
	{
		DistanceSquared = VSizeSquared(__NFUN_216__(Actor.Location, Location));
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xC9
		/*@Error*/
		ApplyEffectTo(Actor);				
		return;
		@NULL
		Item
		DifficultyAdjustment
		@NULL
	}
}

state CheckingForExpiration
{Begin:

	PlaySpawnAnimationSequence();
	ApplyEffect();
	J0x14:

	// End:0x51 [Loop If]
	if(__NFUN_177__(ExpirationTime, Level.TimeSeconds))
	{
		__NFUN_256__(ApplyEffectInterval);
		ApplyEffect();
		// [Loop Continue]
		goto J0x14;
		PlayDisperseAnimation();
		__NFUN_279__();
		stop;		
	}
	@NULL
	@NULL
	@NULL
	@NULL
}

defaultproperties
{
	bBlockZeroExtentTraces=false
	bBlockNonZeroExtentTraces=false
}