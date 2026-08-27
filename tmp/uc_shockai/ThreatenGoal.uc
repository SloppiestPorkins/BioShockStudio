class ThreatenGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var private ShockPawn ThreatenTarget;

overloaded function Construct(AI_Resource R)
{
	assert(false);
	return;
}

function Construct(AI_Resource R, ShockPawn inThreatenTarget)
{
	construct_AI_Resource(R);
	assert(Class'Engine.Pawn'.static.checkAlive(inThreatenTarget));
	ThreatenTarget = inThreatenTarget;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

function ShockPawn GetThreatenTarget()
{
	return ThreatenTarget;
	return;
	@NULL
}

function StopThreateningTarget(ShockPawn inThreatenTarget)
{
	assert(__NFUN_132__(__NFUN_114__(ThreatenTarget, inThreatenTarget), __NFUN_114__(inThreatenTarget, none)));
	FinishUp();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function StartThreateningTarget(ShockPawn inThreatenTarget)
{
	ThreatenTarget = inThreatenTarget;
	CancelFinishUp();
	return;
	@NULL
	CommanderAction
}

defaultproperties
{
	bTryOnlyOnce=true
	Priority=73
}