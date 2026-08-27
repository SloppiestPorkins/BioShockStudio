class AirBlastAbility extends Ability
	native
	config(Abilities);

var config float CosInnerCone;
var config float CosOuterCone;
var config float MaxForce;
var config float MaxSuctionForce;
var config float PawnForceMultiplier;
var config float ForceDuration;
var config float ForceDelayScale;
var config float AirBlastRadius;
var config float AirBlastRadiusAtPlayer;
var config float HalfPowerDistance;

function UseAbility(ShockPlayer Instigator)
{
	return;
}

function StartedUsingAbility(ShockPlayer Instigator)
{
	//native.Instigator;	
	@NULL
}

defaultproperties
{
	CosInnerCone=0.9400000
	CosOuterCone=0.9400000
	MaxForce=1000000.0000000
	MaxSuctionForce=500000.0000000
	PawnForceMultiplier=2000.0000000
	ForceDuration=0.1000000
	ForceDelayScale=0.0010000
	AirBlastRadius=800.0000000
	AirBlastRadiusAtPlayer=68.0000000
	HalfPowerDistance=1000.0000000
	ModGroupName="AirBlast_Exists"
	BioAmmoCost=15.0000000
	FriendlyName="Sonic Boom"
	FireAnimationName="None"
	FireLoopAnimationName="None"
	FinishFireWithEveAnimationName="TK_FireEve"
	FinishFireWithoutEveAnimationName="TK_FireNoEve"
}