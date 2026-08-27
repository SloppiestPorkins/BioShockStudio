class ReactToDamageGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn.EDamageEvent DamageEvent;
var(Parameters) Vector HitLocation;
var(Parameters) Vector HitNormal;
var(Parameters) Vector HitImpulseDirection;
var(Parameters) float HitMomentumImparted;
var(Parameters) float MomentumScale;
var(Parameters) name HitLowBone;
var(Parameters) name HitHighBone;
var(Parameters) DamageStimuliSetState HitDamageStimuliSetState;

function Construct(AI_Resource R, ShockPawn.EDamageEvent inDamageEvent, Vector inHitLocation, Vector inHitNormal, Vector inHitImpulseDirection, float inHitMomentumImparted, DamageStimuliSet inDamageStimuli, name inHitLowBone, name inHitHighBone)
{
	construct_AI_Resource(R);
	DamageEvent = inDamageEvent;
	SetHitParameters(inHitLocation, inHitNormal, inHitImpulseDirection, inHitMomentumImparted, inDamageStimuli, inHitLowBone, inHitHighBone);
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

function SetHitParameters(Vector inHitLocation, Vector inHitNormal, Vector inHitImpulseDirection, float inHitMomentumImparted, DamageStimuliSet inDamageStimuli, name inHitLowBone, name inHitHighBone)
{
	HitLocation = inHitLocation;
	HitNormal = inHitNormal;
	HitImpulseDirection = inHitImpulseDirection;
	HitMomentumImparted = inHitMomentumImparted;
	// End:0x9F
	if(__NFUN_119__(inDamageStimuli, none))
	{
		MomentumScale = inDamageStimuli.MomentumScale;
		HitDamageStimuliSetState = inDamageStimuli.GetState();
		goto J0xAE;
		MomentumScale = -1.0000000;
		HitLowBone = inHitLowBone;
		HitHighBone = inHitHighBone;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x169
		/*@Error*/
	}
	FallDownReactionAction(achievingAction).Fall(inHitLocation, inHitNormal, inHitImpulseDirection, HitMomentumImparted, MomentumScale, HitDamageStimuliSetState, inHitLowBone, inHitHighBone);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function Fall(Vector inHitLocation, Vector inHitNormal, Vector inHitImpulseDirection, float inHitMomentumImparted, DamageStimuliSet inDamageStimuli, name inHitLowBone, name inHitHighBone)
{
	SetHitParameters(inHitLocation, inHitNormal, inHitImpulseDirection, inHitMomentumImparted, inDamageStimuli, inHitLowBone, inHitHighBone);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	bTryOnlyOnce=true
	Priority=90
}