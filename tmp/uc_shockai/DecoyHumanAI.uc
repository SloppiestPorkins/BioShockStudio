class DecoyHumanAI extends ShockAI
	abstract
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

function int GetDesiredAnimationCapabilities()
{
	return __NFUN_156__(super.GetDesiredAnimationCapabilities(), __NFUN_141__(256));
	return;
	@NULL
}

function AddInitialKeywords()
{
	super.AddInitialKeywords();
	AddLocomotionKeyword('DecoyHuman', 0);
	AddLocomotionKeyword('ReturnToVent', -1);
	AddLocomotionKeyword('WaitingForProtector', -1);
	AddLocomotionKeyword('HandsOnHips', -1);
	AddLocomotionKeyword('PointingToThreat', -1);
	AddLocomotionKeyword('Tired', -1);
	AddLocomotionKeyword('ArmsCrossed', -1);
	AddLocomotionKeyword('AttachedToBouncer', -1);
	AddLocomotionKeyword('AttachedToSPF', -1);
	BecomeAggressive();
	return;
	@NULL
}

function AddCommanderAbility()
{
	assert(__NFUN_119__(CharacterAI, none));
	CharacterAI.addAbility_Class(Class'ShockAI.DecoyHumanCommanderAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function CharacterAICreated()
{
	super.CharacterAICreated();
	CharacterAI.addAbility_Class(Class'ShockAI.FullBodyReactionAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function MovementAICreated()
{
	super.MovementAICreated();
	MovementAI.addAbility_Class(Class'ShockAI.MoveToAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function OnDamaged(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, bool bIsCriticalHit, optional name HitHighBone, optional name HitLowBone)
{
	super.OnDamaged(DamageStimuli, TotalDamageDealt, Damager, HitLocation, HitNormal, HitImpulseDirection, EffectEventName, bIsCriticalHit, HitHighBone, HitLowBone);
	Health = default.Health;
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function bool CanBeFocusedNow()
{
	return true;
	return;
}

function IPotentialAimOrActionTarget.TargetType GetTargetType()
{
	return 0;
	return;
}

function float GetUseDistance()
{
	return 0.0000000;
	return;
}

defaultproperties
{
	bDropToGroundUponSpawning=false
	bCanWalk=false
	bCastSimpleShadow=false
	CollisionRadius=50.0000000
	CollisionHeight=45.0000000
	bCollideActors=false
	bBlockPlayers=false
	bRotateToDesired=false
	bCastShadowMapShadow=false
}