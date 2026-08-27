class ScoopUpGathererAction extends BioshockCharacterAction implements IInterestedActorDestroyed, IInterestedPawnDied
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn AttackTarget;
var private MoveToGoal CurrentMoveToGoal;
var private int ScoopUpAnimationHandle;
var private Vector PositionToScoopUpGatherer;
var private config name ScoopUpAnimationName;
var private config float DesiredGathererXOffset;
var private config float MinAngleDegreesToGrabGatherer;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	ShockAI().NotifyFullBodyHitReactionPreventionDesired(self);
	ShockAI().NotifyFallDownHitReactionPreventionDesired(self);
	m_Pawn.Level.RegisterNotifyPawnDied(self);
	m_Pawn.Level.RegisterNotifyActorDestroyed(self);
	ShockAI().bAvoidFuturePawnCollisions = false;
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
		if(m_Pawn.IsAnimationHandleValid(ScoopUpAnimationHandle))
		{
		}
		m_Pawn.SmartPerTrackEaseOutAnimation(ScoopUpAnimationHandle);
		ShockAI().NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
		ShockAI().NotifyFallDownHitReactionPreventionNoLongerDesired(self);
	}
	m_Pawn.Level.UnRegisterNotifyPawnDied(self);
	m_Pawn.Level.UnRegisterNotifyActorDestroyed(self);
	ShockAI().bAvoidFuturePawnCollisions = true;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnOtherPawnDied(Pawn DeadPawn)
{
	// End:0x38
	if(__NFUN_114__(DeadPawn, Protector(m_Pawn).GetCurrentGatherer()))
	{
		HandleGathererDied();
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function OnOtherActorDestroyed(Actor ActorBeingDestroyed)
{
	// End:0x38
	if(__NFUN_114__(ActorBeingDestroyed, Protector(m_Pawn).GetCurrentGatherer()))
	{
		HandleGathererDied();
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

private function HandleGathererDied()
{
	instantSucceed();
	return;
}

function bool IsGathererInCorrectPositionForScoopingUp()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x7B
	/*@Error*/
	return true;
	goto J0x7D;
	return false;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function Vector GetScoopedUpEndLocation()
{
	local name GathererScoopAnimationName;
	local float ScoopedUpAnimLength, ScoopedUpAnimResultYaw;
	local Vector ScoopedUpAnimTranslation, ScoopedUpEndLocation;
	local Gatherer CurrentGatherer;

	CurrentGatherer = Protector(m_Pawn).GetCurrentGatherer();
	assert(__NFUN_119__(CurrentGatherer, none));
	GathererScoopAnimationName = Class'ShockAI.ScoopedUpAction'.default.ScoopedUpAnimationName;
	assert(__NFUN_255__(GathererScoopAnimationName, 'None'));
	ScoopedUpAnimLength = CurrentGatherer.GetAnimationLength(GathererScoopAnimationName);
	CurrentGatherer.GetAnimationAbsoluteMotion(GathererScoopAnimationName, ScoopedUpAnimLength, ScoopedUpAnimTranslation, ScoopedUpAnimResultYaw);
	ScoopedUpEndLocation = __NFUN_215__(CurrentGatherer.Location, __NFUN_276__(ScoopedUpAnimTranslation, Rotator(__NFUN_216__(CurrentGatherer.Location, PositionToScoopUpGatherer))));
	return ScoopedUpEndLocation;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool IsAreaClearForScoopingGatherer()
{
	local Vector ScoopedUpEndLocation;
	local Gatherer CurrentGatherer;

	CurrentGatherer = Protector(m_Pawn).GetCurrentGatherer();
	assert(__NFUN_119__(CurrentGatherer, none));
	ScoopedUpEndLocation = GetScoopedUpEndLocation();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB7
	/*@Error*/
	return true;
	goto J0xB9;
	return false;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool ShouldMoveToScoopUpGatherer()
{
	local Gatherer CurrentGatherer;

	CurrentGatherer = Protector(m_Pawn).GetCurrentGatherer();
	return __NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_129__(ShockAI().IsBurning()), Class'Engine.Pawn'.static.checkAlive(CurrentGatherer)), ShockAI().GetPointToApproachTarget(PositionToScoopUpGatherer, CurrentGatherer, DesiredGathererXOffset)), Class'ShockAI.ShockAI'.static.AreAIsOnLevelSurface(CurrentGatherer, m_Pawn, CurrentGatherer.Location, PositionToScoopUpGatherer)), IsGathererInCorrectPositionForScoopingUp()), IsAreaClearForScoopingGatherer());
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool ShouldScoopUpGatherer()
{
	return __NFUN_130__(__NFUN_129__(ShockAI().IsBurning()), Class'Engine.Pawn'.static.checkAlive(Protector(m_Pawn).GetCurrentGatherer()));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool GetDesiredRotationOverride(out Rotator DesiredRotation)
{
	local Gatherer CurrentGatherer;

	CurrentGatherer = Protector(m_Pawn).GetCurrentGatherer();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA7
	/*@Error*/
	DesiredRotation = Rotator(__NFUN_216__(CurrentGatherer.Location, m_Pawn.Location));
	return true;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool ShouldStopMovingToGatherer()
{
	return __NFUN_129__(ShouldScoopUpGatherer());
	return;
}

function MoveToScoopUpGatherer()
{
	assert(__NFUN_114__(CurrentMoveToGoal, none));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, PositionToScoopUpGatherer);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetDesiredRotationOverride;
	CurrentMoveToGoal.__ShouldStopMoving__Delegate = ShouldStopMovingToGatherer;
	CurrentMoveToGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentMoveToGoal);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x19A
	/*@Error*/
	log('AI', 2, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " could not move to scoop up the gatherer in behavior ("), string(Name)), "), failing behavior!"));
	CancelScoop();
	succeed();
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function ScoopUpGatherer()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x90
	/*@Error*/
	Protector(m_Pawn).GetCurrentGatherer().NotifyStartScoopUp();
	ScoopUpAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, ScoopUpAnimationName);
	m_Pawn.FinishAnimation(ScoopUpAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function CancelScoop()
{
	local Gatherer CurrentGatherer;

	CurrentGatherer = Protector(m_Pawn).GetCurrentGatherer();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x50
	/*@Error*/
	CurrentGatherer.NotifyCancelScoop();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function WaitToScoopUpGatherer()
{
	local Gatherer CurrentGatherer;

	J0x00:
	yield();
	CurrentGatherer = Protector(m_Pawn).GetCurrentGatherer();
	// End:0x00
	if(!(__NFUN_132__(__NFUN_129__(ShouldScoopUpGatherer()), Class'ShockAI.MoveToAction'.static.IsRotatedTo(CurrentGatherer.Rotation, Rotator(__NFUN_216__(CurrentGatherer.Location, m_Pawn.Location)), 500))))
		goto J0x00;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	Protector(m_Pawn).GetCurrentGatherer().NotifyGathererPrepareToBeScoopedUp();
	// End:0x76
	if(ShouldMoveToScoopUpGatherer())
	{
		MoveToScoopUpGatherer();
		WaitToScoopUpGatherer();
		// End:0x69
		if(ShouldScoopUpGatherer())
		{
			ScoopUpGatherer();
			goto J0x73;
			CancelScoop();
		}
		goto J0x80;
		CancelScoop();
	}
	succeed();
	stop;	
	@NULL
	@NULL
}

defaultproperties
{
	ScoopUpAnimationName="MG_GathererSwitch"
	DesiredGathererXOffset=146.3600006
	MinAngleDegreesToGrabGatherer=90.0000000
	satisfiesGoal=Class'ShockAI.ScoopUpGathererGoal'
}