class PanicGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn AttackPawn;
var(Parameters) Vector PointToBePickedUpAt;

function Construct(AI_Resource R, ShockPawn inAttackPawn)
{
	construct_AI_Resource(R);
	AttackPawn = inAttackPawn;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

function NotifyPlayPickedUpAnimation()
{
	// End:0x2F
	if(__NFUN_119__(achievingAction, none))
	{
		BasePanicAction(achievingAction).NotifyPlayPickedUpAnimation();
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

defaultproperties
{
	Priority=75
}