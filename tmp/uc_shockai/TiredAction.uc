class TiredAction extends BioshockCharacterAction
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private MoveToGoal CurrentMoveToGoal;
var private int TiredAnimationHandle;
var private bool bWaiting;
var config array<name> TiredGestureAnimations;
var config array<name> StillTiredGestureAnimations;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	return;
	@NULL
	CommanderAction
	CommanderAction
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
		if(m_Pawn.IsAnimationHandleValid(TiredAnimationHandle))
		{
		}
		m_Pawn.SmartPerTrackEaseOutAnimation(TiredAnimationHandle);
		ShockAI().AddLocomotionKeyword('Tired', Class'ShockAI.ShockAI'.-1);
	}
	ShockAI().AddLocomotionKeyword('ArmsCrossed', Class'ShockAI.ShockAI'.-1);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyProtectorSaysComeOn()
{
	bWaiting = false;
	return;
	@NULL
}

function NotifyProtectorStartingTiredAnimation(bool bUseUnevenSurfaceAnimation)
{
	bWaiting = false;
	StartSynchedAnimation(bUseUnevenSurfaceAnimation);
	return;
	@NULL
	CommanderAction
}

function PlayTiredGesture()
{
	local name TiredAnimationName;

	TiredAnimationName = TiredGestureAnimations[__NFUN_167__(TiredGestureAnimations.Length)];
	TiredAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, TiredAnimationName);
	m_Pawn.FinishAnimation(TiredAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function PlayStillTiredGesture()
{
	local name StillTiredAnimationName;

	StillTiredAnimationName = StillTiredGestureAnimations[__NFUN_167__(StillTiredGestureAnimations.Length)];
	TiredAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, StillTiredAnimationName);
	m_Pawn.FinishAnimation(TiredAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function StartSynchedAnimation(bool bUseUnevenSurfaceAnimation)
{
	local name SynchedAnimationName;

	SynchedAnimationName = Gatherer(m_Pawn).GetProtectorEscort().GetSynchedTiredAnimationForGatherer(bUseUnevenSurfaceAnimation);
	TiredAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, SynchedAnimationName);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function FinishSynchedAnimation()
{
	m_Pawn.FinishAnimation(TiredAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
}

function bool GetRotationTowardsProtector(out Rotator DesiredRotation)
{
	local Protector CurrentProtector;

	CurrentProtector = Gatherer(m_Pawn).GetProtectorEscort();
	DesiredRotation = Rotator(__NFUN_216__(CurrentProtector.Location, m_Pawn.Location));
	return true;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function FaceProtector()
{
	AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, m_Pawn.Location);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetRotationTowardsProtector;
	CurrentMoveToGoal.postGoal(self);
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function StopFacingProtector()
{
	// End:0x41
	if(__NFUN_119__(CurrentMoveToGoal, none))
	{
		CurrentMoveToGoal.unPostGoal(self);
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		useResources(Class'VengeanceShared.AI_Resource'.4);
	}
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	PlayTiredGesture();
	Gatherer(m_Pawn).GetProtectorEscort().NotifyReactToTiredGatherer();
	bWaiting = true;
	// End:0x5E
	if(bWaiting)
	{
		yield();
		// [Loop Continue]
		goto J0x44;
		ShockAI().AddLocomotionKeyword('Tired', Class'ShockAI.ShockAI'.-1);
	}
	ShockAI().AddLocomotionKeyword('ArmsCrossed', 1);
	PlayStillTiredGesture();
	FaceProtector();
	bWaiting = true;
	// End:0xED
	if(bWaiting)
	{
		yield();
		goto J0xD3;
		StopFacingProtector();
		ShockAI().AddLocomotionKeyword('ArmsCrossed', Class'ShockAI.ShockAI'.-1);
	}
	FinishSynchedAnimation();
	succeed();
	stop;	
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/;
}

defaultproperties
{
	TiredGestureAnimations[0]="GA_gTired_A"
	StillTiredGestureAnimations[0]="GA_gStillTired_A"
	satisfiesGoal=Class'ShockAI.TiredGoal'
	bExclusiveAction=true
}