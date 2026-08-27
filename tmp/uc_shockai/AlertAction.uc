class AlertAction extends BioshockCharacterAction
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn AlertedPawn;
var private MoveToGoal CurrentMoveToGoal;
var private bool bNotifiedNoLongerAlert;
var private bool bFinishedPointing;
var private bool bRotatingWhilePointing;
var private int CowerAnimationHandle;
var private float DesiredMoveBehindDot;
var private Range HideBehindDotRange;
var private Rotator DesiredRotationToPoint;
var private Rotator CurrentFaceRotation;
var private config float HideDistanceBehindEscort;
var private config Range HideBehindAngleRange;
var private config float TurnToFaceThreatDegrees;
var private config name StandingPointAnimation;
var private config name EndCowerAnimation;
var private config Range PointWaitTime;
var private config float MinHidingTurnDegrees;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	HideBehindDotRange.Min = __NFUN_188__(__NFUN_171__(HideBehindAngleRange.Min, 0.0174533));
	HideBehindDotRange.Max = __NFUN_188__(__NFUN_171__(HideBehindAngleRange.Max, 0.0174533));
	DesiredMoveBehindDot = HideBehindDotRange.Min;
	Gatherer(m_Pawn).NotifyAlertDueTo(AlertedPawn);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	// End:0x33
	if(__NFUN_119__(CurrentMoveToGoal, none))
	{
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		// End:0x76
		if(m_Pawn.IsAnimationHandleValid(CowerAnimationHandle))
		{
		}
		m_Pawn.SmartPerTrackEaseOutAnimation(CowerAnimationHandle);
		NotifyNoLongerAlert();
		ShockAI().AddLocomotionKeyword('PointingToThreat', Class'ShockAI.ShockAI'.-1);
	}
	ShockAI().StopSpeech('Alerted');
	ShockAI().StopTracking();
	StopRotationTowardsAlertedPawn();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyNoLongerAlert()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x44
	/*@Error*/
	bNotifiedNoLongerAlert = true;
	Gatherer(m_Pawn).NotifyNoLongerAlertDueTo(AlertedPawn);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool GetRotationToAlertedPawn(out Rotator DesiredRotation)
{
	// End:0x57
	if(__NFUN_129__(bFinishedPointing))
	{
		// End:0x32
		if(bRotatingWhilePointing)
		{
			DesiredRotation = DesiredRotationToPoint;
			goto J0x52;
			DesiredRotation = m_Pawn.Rotation;
		}
		return true;
		goto J0x18B;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x189
		/*@Error*/
		// End:0x114
		if(__NFUN_129__(Class'ShockAI.MoveToAction'.static.IsRotatedTo(CurrentFaceRotation, Rotator(__NFUN_216__(AlertedPawn.Location, m_Pawn.Location)), int(__NFUN_171__(MinHidingTurnDegrees, 182.0444489)))))
		{
		}
		CurrentFaceRotation = Rotator(__NFUN_216__(AlertedPawn.Location, m_Pawn.Location));
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x171
		/*@Error*/
		DesiredRotation = m_Pawn.Rotation;
		goto J0x184;
		DesiredRotation = CurrentFaceRotation;
		return true;
		goto J0x18B;
		return false;
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

function GetUpdatedDestination(out Actor outDestinationActor, out Vector outDestinationLocation)
{
	local Protector ProtectorEscort;
	local Vector PositionToUse, PositionBehindEscort, DirectionBehindProtector, DirectionFromEscort, EscortPosition, DirectionNextToEscort,
		PositionNextToEscort;

	local float GathererPositionDot;
	local bool bFoundPointToUse;

	ProtectorEscort = Gatherer(m_Pawn).GetProtectorEscort();
	// End:0x6D
	if(__NFUN_132__(__NFUN_129__(bFinishedPointing), __NFUN_114__(ProtectorEscort, none)))
	{
		outDestinationLocation = m_Pawn.Location;
		goto J0x5C1;
		DirectionBehindProtector = __NFUN_226__(__NFUN_216__(ProtectorEscort.Location, AlertedPawn.Location));
	}
	DirectionBehindProtector.Z = 0.0000000;
	DirectionFromEscort = __NFUN_226__(__NFUN_216__(m_Pawn.Location, ProtectorEscort.Location));
	DirectionFromEscort.Z = 0.0000000;
	GathererPositionDot = __NFUN_219__(DirectionBehindProtector, DirectionFromEscort);
	PositionToUse = m_Pawn.Location;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x524
	/*@Error*/
	EscortPosition = ProtectorEscort.Location;
	__NFUN_184__(EscortPosition.Z, __NFUN_175__(m_Pawn.CollisionHeight, ProtectorEscort.CollisionHeight));
	PositionBehindEscort = __NFUN_215__(EscortPosition, __NFUN_212__(DirectionBehindProtector, HideDistanceBehindEscort));
	// End:0x2C7
	if(__NFUN_130__(__NFUN_130__(m_Pawn.GetAdjustedPoint(PositionBehindEscort), m_Pawn.GetPointOnFloor(PositionBehindEscort)), m_Pawn.IsAreaClearOfPawns(PositionBehindEscort, m_Pawn.GetCylinderExtent())))
	{
		PositionToUse = PositionBehindEscort;
		bFoundPointToUse = true;
		goto J0x524;
		DirectionNextToEscort = __NFUN_220__(DirectionBehindProtector, vect(0.0000000, 0.0000000, 1.0000000));
		// End:0x31C
		if(__NFUN_176__(__NFUN_219__(DirectionNextToEscort, DirectionFromEscort), 0.0000000))
		{
			DirectionNextToEscort = __NFUN_211__(DirectionNextToEscort);
			PositionNextToEscort = __NFUN_215__(EscortPosition, __NFUN_212__(DirectionNextToEscort, __NFUN_174__(ProtectorEscort.CollisionRadius, __NFUN_171__(m_Pawn.CollisionRadius, 2.0000000))));
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x417
			/*@Error*/
			PositionToUse = PositionNextToEscort;
			bFoundPointToUse = true;
			goto J0x524;
			DirectionNextToEscort = __NFUN_211__(DirectionNextToEscort);
		}
		PositionNextToEscort = __NFUN_215__(EscortPosition, __NFUN_212__(DirectionNextToEscort, __NFUN_174__(ProtectorEscort.CollisionRadius, __NFUN_171__(m_Pawn.CollisionRadius, 2.0000000))));
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x524
		/*@Error*/
	}
	PositionToUse = PositionNextToEscort;
	bFoundPointToUse = true;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x56E
	/*@Error*/
	outDestinationLocation = PositionToUse;
	goto J0x5C1;
	ShockAI().AddLocomotionKeyword('PointingToThreat', Class'ShockAI.ShockAI'.-1);
	outDestinationLocation = m_Pawn.Location;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnMoveEnded()
{
	ShockAI().AddLocomotionKeyword('PointingToThreat', Class'ShockAI.ShockAI'.-1);
	return;
	@NULL
}

function MoveDuringAlert()
{
	assert(__NFUN_114__(CurrentMoveToGoal, none));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, m_Pawn.Location, true);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetRotationToAlertedPawn;
	CurrentMoveToGoal.__GetUpdatedDestination__Delegate = GetUpdatedDestination;
	CurrentMoveToGoal.__OnMoveEnded__Delegate = OnMoveEnded;
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	CurrentMoveToGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function RemoveMovementGoal()
{
	assert(__NFUN_119__(CurrentMoveToGoal, none));
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool ShouldRotateToFaceThreat()
{
	return __NFUN_129__(Class'ShockAI.MoveToAction'.static.IsRotatedTo(m_Pawn.Rotation, Rotator(__NFUN_216__(AlertedPawn.Location, m_Pawn.Location)), int(__NFUN_171__(TurnToFaceThreatDegrees, 182.0444489))));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function PlayStandingPointAnimation()
{
	local float StandingPointAnimLength;

	CowerAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, StandingPointAnimation);
	StandingPointAnimLength = m_Pawn.GetAnimationLengthScaled(CowerAnimationHandle);
	__NFUN_256__(__NFUN_175__(StandingPointAnimLength, 0.2500000));
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function PlayEndCowerAnimation()
{
	CowerAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, EndCowerAnimation);
	// End:0x82
	if(__NFUN_130__(m_Pawn.IsAnimationHandleValid(CowerAnimationHandle), __NFUN_129__(m_Pawn.IsAnimationPerTrackEntirelyEasedIn(CowerAnimationHandle))))
	{
		yield();
		// [Loop Continue]
		goto J0x2B;
		ShockAI().BecomePassive();
		m_Pawn.FinishAnimation(CowerAnimationHandle);
	}
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function StartRotationTowardsAlertedPawn()
{
	m_Pawn.Controller.Focus = AlertedPawn;
	m_Pawn.bRotateToDesired = true;
	m_Pawn.RotationRate.Yaw = 20000;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function StopRotationTowardsAlertedPawn()
{
	m_Pawn.RotationRate.Yaw = m_Pawn.default.RotationRate.Yaw;
	m_Pawn.Controller.Focus = none;
	m_Pawn.bRotateToDesired = false;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function Point()
{
	ShockAI().QuickLook(AlertedPawn, 20.0000000);
	// End:0x4C
	if(__NFUN_129__(ShouldRotateToFaceThreat()))
	{
		StartRotationTowardsAlertedPawn();
		PlayStandingPointAnimation();
		goto J0xF0;
		bRotatingWhilePointing = true;
	}
	DesiredRotationToPoint = Rotator(__NFUN_216__(AlertedPawn.Location, m_Pawn.Location));
	// End:0xDA
	if(__NFUN_129__(Class'ShockAI.MoveToAction'.static.IsRotatedTo(m_Pawn.Rotation, DesiredRotationToPoint)))
	{
		yield();
		// [Loop Continue]
		goto J0x92;
		bRotatingWhilePointing = false;
		StartRotationTowardsAlertedPawn();
		__NFUN_256__(RandRange(PointWaitTime.Min, PointWaitTime.Max));
	}
	StopRotationTowardsAlertedPawn();
	bFinishedPointing = true;
	ShockAI().StopTracking();
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	ShockAI().PlaySpeech('Alerted');
	ShockAI().SetShouldRun();
	ShockAI().BecomeAggressive();
	ShockAI().AddLocomotionKeyword('PointingToThreat', 1);
	MoveDuringAlert();
	Point();
	J0x87:

	// End:0xB9 [Loop If]
	if(__NFUN_129__(BioshockCharacterGoal(achievingGoal).ShouldFinishUp()))
	{
		yield();
		// [Loop Continue]
		goto J0x87;
		NotifyNoLongerAlert();
	}
	RemoveMovementGoal();
	PlayEndCowerAnimation();
	succeed();
	stop;		
	@NULL
	@NULL
}

defaultproperties
{
	HideDistanceBehindEscort=150.0000000
	HideBehindAngleRange=(Min=45.0000000,Max=85.0000000)
	TurnToFaceThreatDegrees=22.5000000
	EndCowerAnimation="GA_endCower"
	PointWaitTime=(Min=1.0000000,Max=1.0000000)
	MinHidingTurnDegrees=22.5000000
	satisfiesGoal=Class'ShockAI.AlertGoal'
	bExclusiveAction=true
}