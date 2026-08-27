class ProtectPlayerGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) private ShockPlayer TargetPlayer;

function Construct(AI_Resource R, ShockPlayer inTargetPlayer)
{
	construct_AI_Resource(R);
	assert(Class'Engine.Pawn'.static.checkAlive(inTargetPlayer));
	TargetPlayer = inTargetPlayer;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

defaultproperties
{
	Priority=60
}