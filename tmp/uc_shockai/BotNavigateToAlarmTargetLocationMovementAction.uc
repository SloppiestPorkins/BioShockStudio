class BotNavigateToAlarmTargetLocationMovementAction extends BotBaseNavigateToTargetMovementAction
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) SecurityManager SecuritySystem;
var(Parameters) float LookAtActorDistance;
var private bool ReachedDestination;
var private int DestinationStage;
var private Vector CurrentDestinationLocation;

function GetUpdatedDestination(out Actor outDestinationActor, out Vector outDestinationLocation)
{
	// End:0x33
	if(__NFUN_154__(DestinationStage, 0))
	{
		outDestinationLocation = SecuritySystem.GetLastAlarmTargetLocation();
		goto J0x46;
		outDestinationLocation = CurrentDestinationLocation;
		return;
	}
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnDestinationReached()
{
	ReachedDestination = true;
	return;
	@NULL
}

function bool GetDesiredRotationOverride(out Rotator DesiredRotation)
{
	local Vector DirectionToTarget;
	local float DistanceFromLastKnownLocationSquared, MaxDistanceSquared;
	local ShockPawn AlarmTarget;

	AlarmTarget = SecuritySystem.GetAlarmTarget();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x107
	/*@Error*/
	DirectionToTarget = __NFUN_216__(AlarmTarget.Location, MyBot.Location);
	MaxDistanceSquared = __NFUN_171__(LookAtActorDistance, LookAtActorDistance);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x107
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

function NotifyCannotFindWayToDestination()
{
	local Vector LastSeenByBotLocation;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x142
	/*@Error*/
	LastSeenByBotLocation = SecuritySystem.GetLastAlarmTargetLocationAsSeenByBots();
	// End:0x93
	if(__NFUN_130__(__NFUN_129__(IsZero(LastSeenByBotLocation)), MyBot.__NFUN_548__(LastSeenByBotLocation, SecuritySystem.GetLastAlarmTargetLocation())))
	{
		CurrentDestinationLocation = LastSeenByBotLocation;
		goto J0xBE;
		CurrentDestinationLocation = GetFailsafeDestination(SecuritySystem.GetLastAlarmTargetLocation());
		log('AI_Security', 2, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(MyBot), " could not find it's way to the destination, going to nearby "), string(CurrentDestinationLocation)), " instead."));
	}
	DestinationStage = 1;
	goto J0x14E;
	ReachedDestination = true;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Vector GetFailsafeDestination(Vector OriginalDesiredDestination)
{
	//native.OriginalDesiredDestination;	
	@NULL
}

function bool TargetIsInDetectRange(ShockPawn Target)
{
	//native.Target;	
	@NULL
}

state Running
{Begin:

	ReachedDestination = false;
	DestinationStage = 0;
	InitializeMovement(true);
	// End:0x66
	if(__NFUN_130__(__NFUN_129__(ReachedDestination), __NFUN_129__(TargetIsInDetectRange(SecuritySystem.GetAlarmTarget()))))
	{
		yield();
		// [Loop Continue]
		goto J0x22;
		// End:0x115
		if(__NFUN_129__(TargetIsInDetectRange(SecuritySystem.GetAlarmTarget())))
		{
		}
		log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " reached the last known alarm target location, but could not find the target.  Returning fail."));
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
	satisfiesGoal=Class'ShockAI.BotNavigateToAlarmTargetLocationMovementGoal'
}