class BotNavigateToPointLocationMovementAction extends BotBaseNavigateToTargetMovementAction
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) Vector TargetLocation;

function GetUpdatedDestination(out Actor outDestinationActor, out Vector outDestinationLocation)
{
	outDestinationLocation = TargetLocation;
	return;
	@NULL
	CommanderAction
}

state Running
{Begin:

	InitializeMovement();
	waitForGoal_AI_Goal(CurrentMoveToGoal);
	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " has reached the target.  Returning success."));
	succeed();
	stop;	
	@NULL
	@NULL
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.BotNavigateToPointLocationMovementGoal'
}