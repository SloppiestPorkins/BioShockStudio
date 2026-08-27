class ChargeAttackGoal extends BioshockCharacterGoal
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) private Actor Target;
var(Parameters) private name TelegraphAnimationName;
var(Parameters) private name ChargeLoopAnimationName;
var(Parameters) private name ChargeEndAnimationName;
var(Parameters) private name ChargeEndFacingTargetAnimationName;
var(Parameters) private name ChargeHitAnimationName;

function Construct(AI_Resource R, Actor inTarget, name inTelegraphAnimationName, name inChargeLoopAnimationName, name inChargeEndAnimationName, name inChargeEndFacingTargetAnimationName, name inChargeHitAnimationName)
{
	construct_AI_Resource(R);
	Target = inTarget;
	TelegraphAnimationName = inTelegraphAnimationName;
	ChargeLoopAnimationName = inChargeLoopAnimationName;
	ChargeEndAnimationName = inChargeEndAnimationName;
	ChargeEndFacingTargetAnimationName = inChargeEndFacingTargetAnimationName;
	ChargeHitAnimationName = inChargeHitAnimationName;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

function bool IsChargingOrPreparingToCharge()
{
	return __NFUN_130__(__NFUN_119__(achievingAction, none), ChargeAttackAction(achievingAction).super(ChargeAttackGoal).IsChargingOrPreparingToCharge());
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function bool IsCharging()
{
	return __NFUN_130__(__NFUN_119__(achievingAction, none), ChargeAttackAction(achievingAction).super(ChargeAttackGoal).IsCharging());
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

defaultproperties
{
	bTryOnlyOnce=true
	Priority=76
}