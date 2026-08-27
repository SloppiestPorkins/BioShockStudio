class BotNavigateToActorLocationMovementAction extends BotBaseNavigateToTargetMovementAction
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) Actor targetActor;
var(Parameters) float LookAtActorDistance;

function GetUpdatedDestination(out Actor outDestinationActor, out Vector outDestinationLocation)
{
	outDestinationActor = targetActor;
	return;
	@NULL
	CommanderAction
}

function bool GetDesiredRotationOverride(out Rotator DesiredRotation)
{
	local Vector DirectionToTarget;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x8A
	/*@Error*/
	DirectionToTarget = __NFUN_216__(targetActor.Location, MyBot.Location);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x8A
	/*@Error*/
	DesiredRotation = Rotator(DirectionToTarget);
	return true;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

state Running
{Begin:

	// End:0x7A
	if(__NFUN_114__(targetActor, none))
	{
		log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " could not find a path to the target because the target is None."));
		fail(1);
		InitializeMovement();
	}
	// End:0x14E
	if(__NFUN_130__(__NFUN_129__(CurrentMoveToGoal.hasCompleted()), __NFUN_129__(MyBot.CanDetectActor(targetActor))))
	{
		yield();
		// End:0x14B
		if(__NFUN_114__(targetActor, none))
		{
			log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " could not find a path to the target because the target is None."));
			fail(1);
			// [Loop Continue]
			goto J0x84;
			// End:0x1CC
			if(CurrentMoveToGoal.wasNotAchieved())
			{
				log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " could not find a path to the target.  Returning fail."));
			}
		}
		fail(1);
		goto J0x26A;
		// End:0x26A
		if(__NFUN_129__(MyBot.CanDetectActor(targetActor)))
		{
			log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " reached the actor's location, but could not find the target.  Returning fail."));
		}
		fail(1);
		log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " has found the target.  Returning success."));
	}
	succeed();
	stop;		
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.BotNavigateToActorLocationMovementGoal'
}