class DamageVolume extends BaseDamageVolume implements ISpawnableDamageSource
	native
	config
	hidecategories(DisplayAdvanced);

struct native atomic TouchingDamagee
{
	var IDamagee Damagee;
	var float NextDamageTime;
};

var name DamageStimuliSetName;
var float ChanceToCrit;
var private transient Actor Damager;
var private editconst bool bInitialized;
var float PeriodicDamageDuration;
var private float OuterDamageRadius;
var private float InnerDamageRadius;
var array<TouchingDamagee> TouchingDamagees;

function Initialize()
{
	local Actor A;

	bInitialized = true;
	// End:0x41
	foreach __NFUN_321__(Class'Engine.Actor', A, OuterDamageRadius)
	{
		SetTouchingWhenSpawned(A);				
		return;
		@NULL
		Freebie
		Item
		@NULL
	}
}

function SetTouchingWhenSpawned(Actor A)
{
	//native.A;	
	@NULL
}

function Touch(Actor Other)
{
	log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::event Touch( "), string(Other)), " )"));
	OnActorEnteredVolume(Other);
	return;
	@NULL
	Item
}

function UnTouch(Actor Other)
{
	log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::event UnTouch( "), string(Other)), " )"));
	OnActorLeftVolume(Other);
	return;
	@NULL
	Item
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

function SetDamager(Actor inDamager)
{
	Damager = inDamager;
	Initialize();
	return;
	@NULL
	Item
	Item
}

function SetOuterDamageRadius(float inRadius)
{
	//native.inRadius;	
	@NULL
}

function SetInnerDamageRadius(float inRadius)
{
	//native.inRadius;	
	@NULL
}

function SetDamageDuration(float inDuration)
{
	LifeSpan = inDuration;
	return;
	@NULL
	Item
}

defaultproperties
{
	DamageStimuliSetName="DefaultStimuliSet"
	ChanceToCrit=0.5000000
	DrawType=8
	StaticMesh=StaticMesh'ShockGame.SimpleShapes.Cube256Diameter'
	bHidden=true
	bCollideActors=true
}