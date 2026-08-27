class BioweaponRepellantVolume extends RepellingVolume implements ISpawnableDamageSource
	native
	config
	hidecategories(DrawScale3D,DisplayAdvanced);

var array<Actor> ActorsInVolume;
var private bool bInitialized;

// Export UBioweaponRepellantVolume::execInitialize(FFrame&, void* const)
native final function Initialize();

function SetDamager(Actor inDamager)
{
	Initialize();
	return;
	@NULL
}

function SetOuterDamageRadius(float inRadius)
{
	//native.inRadius;	
	@NULL
}

function SetInnerDamageRadius(float inRadius)
{
	return;
}

function SetDamageDuration(float inDuration)
{
	LifeSpan = inDuration;
	return;
	@NULL
	Item
}

function Touch(Actor Other)
{
	OnActorEnteredVolume(Other);
	return;
	@NULL
}

function UnTouch(Actor Other)
{
	OnActorLeftVolume(Other);
	return;
	@NULL
}

function OnActorEnteredVolume(Actor Other)
{
	//native.Other;	
	@NULL
}

function OnActorLeftVolume(Actor Other)
{
	//native.Other;	
	@NULL
}

function StopTouchingWhenDestroyed(Actor A)
{
	//native.A;	
	@NULL
}

function Destroyed()
{
	super(Actor).Destroyed();
	// End:0x32
	if(__NFUN_151__(ActorsInVolume.Length, 0))
	{
		StopTouchingWhenDestroyed(ActorsInVolume[0]);
		// [Loop Continue]
		goto J0x0A;
		Level.UnregisterRepellingVolume(self);
	}
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

defaultproperties
{
	bCollideActors=true
}