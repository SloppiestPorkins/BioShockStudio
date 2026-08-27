class StunnedAction extends BioshockCharacterAction implements IInterestedActorDestroyed
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private MoveToGoal CurrentMoveToGoal;
var private Vector CachedProtectorLocation;
var private bool bFoundMournPoint;
var private float NextTimeCanUpdateMournPoint;
var private Vector PointToMournTarget;
var private Protector ProtectorEscort;
var private config float DesiredDistanceToDeadProtector;
var private config float MournPointUpdateTime;
var private config int AlignmentAllowedDeltaYaw;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	m_Pawn.Level.RegisterNotifyActorDestroyed(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	ShockAI().AddLocomotionKeyword('Mourning', Class'ShockAI.ShockAI'.-1);
	// End:0x66
	if(__NFUN_119__(CurrentMoveToGoal, none))
	{
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		m_Pawn.Level.UnRegisterNotifyActorDestroyed(self);
	}
	// End:0xB2
	if(__NFUN_119__(ProtectorEscort, none))
	{
		__NFUN_164__(ProtectorEscort.DelayCorpseRemoval);
		ShockAI().StopSpeech('GathererWeep');
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
	@NULL
}

function OnOtherActorDestroyed(Actor ActorBeingDestroyed)
{
	// End:0x22
	if(__NFUN_114__(ActorBeingDestroyed, ProtectorEscort))
	{
		ProtectorEscort = none;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function GetUpdatedDestination(out Actor outDestinationActor, out Vector outDestinationLocation)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xFF
	/*@Error*/
	CachedProtectorLocation = ProtectorEscort.Location;
	ShockAI().GetPointToApproachTarget(PointToMournTarget, ProtectorEscort, DesiredDistanceToDeadProtector);
	bFoundMournPoint = true;
	NextTimeCanUpdateMournPoint = __NFUN_174__(m_Pawn.Level.TimeSeconds, MournPointUpdateTime);
	outDestinationLocation = PointToMournTarget;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool ShouldStopMovingToProtector()
{
	return __NFUN_132__(__NFUN_132__(__NFUN_114__(ProtectorEscort, none), ProtectorEscort.bDeleteMe), __NFUN_155__(int(ProtectorEscort.GetRagdoll().GetRagdollState()), int(2)));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool GetDesiredFocalPointOverride(out Vector DesiredFocalPoint)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x3E
	/*@Error*/
	DesiredFocalPoint = ProtectorEscort.Location;
	return true;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function MoveToProtector()
{
	ProtectorEscort = Gatherer(m_Pawn).GetProtectorEscort();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x21F
	/*@Error*/
	__NFUN_163__(ProtectorEscort.DelayCorpseRemoval);
	bFoundMournPoint = false;
	AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), "StunnedAction::MoveToProtector - Expected CurrentMoveToGoal to be None!");
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, m_Pawn.Location, true);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__GetDesiredFocalPointOverride__Delegate = GetDesiredFocalPointOverride;
	CurrentMoveToGoal.__ShouldStopMoving__Delegate = ShouldStopMovingToProtector;
	CurrentMoveToGoal.__GetUpdatedDestination__Delegate = GetUpdatedDestination;
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	CurrentMoveToGoal.SetAlignmentAllowedDeltaYaw(AlignmentAllowedDeltaYaw);
	CurrentMoveToGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

state Running
{	J0x00:
	// End:0x62 [Loop If]
	if(__NFUN_132__(Gatherer(m_Pawn).IsNonPhysical(), __NFUN_155__(int(m_Pawn.GetRagdoll().GetRagdollState()), int(0))))
	{
		yield();
		// [Loop Continue]
		goto J0x00;
		ShockAI().PlaySpeech('GathererWeep');
	}
	MoveToProtector();
	ShockAI().AddLocomotionKeyword('Mourning', 1);
	stop;				
	@NULL
	@NULL
	@NULL
}

defaultproperties
{
	DesiredDistanceToDeadProtector=200.0000000
	MournPointUpdateTime=1.0000000
	AlignmentAllowedDeltaYaw=1820
	satisfiesGoal=Class'ShockAI.StunnedGoal'
	bExclusiveAction=true
}