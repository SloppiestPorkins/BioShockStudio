class ReactToTiredGathererAction extends BioshockCharacterAction implements IInterestedActorDestroyed, IInterestedPawnDied
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private MoveToGoal CurrentMoveToGoal;
var private int TiredReactionAnimationHandle;
var private config float DesiredDistanceToGatherer;
var private config Range TimeBeforeFrustrationRange;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	m_Pawn.Level.RegisterNotifyActorDestroyed(self);
	m_Pawn.Level.RegisterNotifyPawnDied(self);
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
		if(m_Pawn.IsAnimationHandleValid(TiredReactionAnimationHandle))
		{
		}
		m_Pawn.SmartPerTrackEaseOutAnimation(TiredReactionAnimationHandle);
		m_Pawn.Level.UnRegisterNotifyActorDestroyed(self);
		m_Pawn.Level.UnRegisterNotifyPawnDied(self);
	}
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
		instantSucceed();
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
		instantSucceed();
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function PlayComeOnAnimation()
{
	local name ComeOnAnimation;

	ComeOnAnimation = Protector(m_Pawn).GetComeOnTiredGathererAnimation();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x8C
	/*@Error*/
	TiredReactionAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, ComeOnAnimation);
	m_Pawn.FinishAnimation(TiredReactionAnimationHandle);
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function PlayFrustratedAnimation()
{
	local name FrustratedAnimation;

	FrustratedAnimation = Protector(m_Pawn).GetFrustratedAtTiredGathererAnimationName();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x8C
	/*@Error*/
	TiredReactionAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, FrustratedAnimation);
	m_Pawn.FinishAnimation(TiredReactionAnimationHandle);
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function bool ShouldStopMovingToGatherer()
{
	local Gatherer CurrentGatherer;
	local float DistanceToGatherer;

	CurrentGatherer = Protector(m_Pawn).GetCurrentGatherer();
	DistanceToGatherer = __NFUN_225__(__NFUN_216__(CurrentGatherer.Location, m_Pawn.Location));
	log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("DistanceToGatherer: ", string(DistanceToGatherer)), " DesiredDistanceToGatherer: "), string(DesiredDistanceToGatherer)), " NumLOS: "), string(m_Pawn.GetNumLineOfSightsTo(CurrentGatherer))));
	return __NFUN_130__(__NFUN_178__(DistanceToGatherer, DesiredDistanceToGatherer), __NFUN_153__(m_Pawn.GetNumLineOfSightsTo(CurrentGatherer), 4));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool GetRotationTowardsGatherer(out Rotator DesiredRotation)
{
	local Gatherer CurrentGatherer;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x82
	/*@Error*/
	CurrentGatherer = Protector(m_Pawn).GetCurrentGatherer();
	DesiredRotation = Rotator(__NFUN_216__(CurrentGatherer.Location, m_Pawn.Location));
	return true;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function MoveToGatherer()
{
	AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, Protector(m_Pawn).GetCurrentGatherer());
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__ShouldStopMoving__Delegate = ShouldStopMovingToGatherer;
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetRotationTowardsGatherer;
	CurrentMoveToGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentMoveToGoal);
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function PlaySynchedAnimation()
{
	local name SynchedTiredAnimation;
	local bool bUseUnevenSurfaceAnimation;
	local Gatherer CurrentGatherer;

	CurrentGatherer = Protector(m_Pawn).GetCurrentGatherer();
	bUseUnevenSurfaceAnimation = __NFUN_129__(Class'ShockAI.ShockAI'.static.AreAIsOnLevelSurface(m_Pawn, CurrentGatherer, m_Pawn.Location, CurrentGatherer.Location));
	Protector(m_Pawn).GetCurrentGatherer().NotifyProtectorStartingTiredAnimation(bUseUnevenSurfaceAnimation);
	SynchedTiredAnimation = Protector(m_Pawn).GetSynchedTiredAnimation(bUseUnevenSurfaceAnimation);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x15A
	/*@Error*/
	TiredReactionAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, SynchedTiredAnimation);
	m_Pawn.FinishAnimation(TiredReactionAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function WaitForGathererToRotate()
{
	local Gatherer CurrentGatherer;

	CurrentGatherer = Protector(m_Pawn).GetCurrentGatherer();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x9A
	/*@Error*/
	yield();
	// [Loop Continue]
	goto J0x2A;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	PlayComeOnAnimation();
	Protector(m_Pawn).GetCurrentGatherer().NotifyProtectorSaysComeOn();
	__NFUN_256__(RandRange(TimeBeforeFrustrationRange.Min, TimeBeforeFrustrationRange.Max));
	PlayFrustratedAnimation();
	MoveToGatherer();
	WaitForGathererToRotate();
	PlaySynchedAnimation();
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
	DesiredDistanceToGatherer=137.8880005
	TimeBeforeFrustrationRange=(Min=1.0000000,Max=2.0000000)
	satisfiesGoal=Class'ShockAI.ReactToTiredGathererGoal'
	bExclusiveAction=true
}