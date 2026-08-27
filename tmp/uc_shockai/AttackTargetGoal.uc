class AttackTargetGoal extends BioshockCharacterGoal
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn Target;

overloaded function Construct(AI_Resource R)
{
	assert(false);
	return;
}

function Construct(AI_Resource R, ShockPawn inTarget)
{
	construct_AI_Resource(R);
	assert(Class'Engine.Pawn'.static.checkAlive(inTarget));
	Target = inTarget;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

function OnDamagedByTarget()
{
	// End:0x2F
	if(__NFUN_119__(achievingAction, none))
	{
		CharacterAttackAction(achievingAction).OnDamagedByTarget();
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function OnDamagedTarget()
{
	// End:0x2F
	if(__NFUN_119__(achievingAction, none))
	{
		CharacterAttackAction(achievingAction).OnDamagedTarget();
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

defaultproperties
{
	bTryOnlyOnce=true
	Priority=75
}