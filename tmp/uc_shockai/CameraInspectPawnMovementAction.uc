class CameraInspectPawnMovementAction extends CameraTrackPawnMovementAction
	collapsecategories
	hidecategories(Object,InternalParameters);

var bool ShouldUpdateTargetLocation;

function Rotator UpdateDesiredRotation()
{
	// End:0x17
	if(ShouldUpdateTargetLocation)
	{
		UpdateTargetLocation();
		return CalculateRotationToTarget();
	}
	return;
	@NULL
}

function OnPawnSeen(ShockPawn Seen)
{
	return;
}

function OnPawnLost(ShockPawn Seen)
{
	return;
}

function TrackUnseenTarget()
{
	local float LostTargetEndTime;

	LostTargetEndTime = __NFUN_174__(MyCamera.Level.TimeSeconds, MyCamera.GetInspectLostTargetDuration());
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x118
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xEF
	/*@Error*/
	LostTargetEndTime = __NFUN_174__(MyCamera.Level.TimeSeconds, MyCamera.GetInspectLostTargetDuration());
	ShouldUpdateTargetLocation = true;
	goto J0xFB;
	ShouldUpdateTargetLocation = false;
	__NFUN_256__(MyCamera.GetInspectLostTargetTestPeriod());
	// [Loop Continue]
	goto J0x46;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting inspect pawn movement action."));
	__NFUN_113__('CanSeeTarget');
	stop;		
	@NULL
}

state CanSeeTarget
{
	ignores OnPawnLost;
Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting CanSeeTarget state."));
	yield();
	// End:0x76
	if(__NFUN_129__(MyCamera.isVisible(TrackingTarget)))
	{
		__NFUN_113__('CannotSeeTarget');
		ShouldUpdateTargetLocation = true;
		stop;		
	}
	@NULL
	@NULL
	@NULL
	@NULL
}

state CannotSeeTarget
{
	ignores OnPawnSeen;
Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting CannotSeeTarget state."));
	yield();
	// End:0x77
	if(MyCamera.isVisible(TrackingTarget))
	{
		__NFUN_113__('CanSeeTarget');
		TrackUnseenTarget();
		stop;		
	}	
	@NULL
	@NULL
	@NULL
}

defaultproperties
{
	ShouldUpdateTargetLocation=true
	satisfiesGoal=Class'ShockAI.CameraInspectPawnMovementGoal'
}