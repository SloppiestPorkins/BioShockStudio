class WaitForProtectorAction extends BioshockCharacterAction
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private MoveToGoal CurrentMoveToGoal;
var private int GestureAnimationHandle;
var array<name> CurrentGestureAnimations;
var config array<name> GestureAnimations;
var private config float InitialWaitForProtectorTime;
var private config Range GestureTimeRange;

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	// End:0x33
	if(__NFUN_119__(CurrentMoveToGoal, none))
	{
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		// End:0x76
		if(m_Pawn.IsAnimationHandleValid(GestureAnimationHandle))
		{
		}
		m_Pawn.SmartPerTrackEaseOutAnimation(GestureAnimationHandle);
		ShockAI().AddLocomotionKeyword('WaitingForProtector', Class'ShockAI.ShockAI'.-1);
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyPausedDueToExclusivity()
{
	super(AI_RunnableAction).NotifyPausedDueToExclusivity();
	// End:0x4D
	if(m_Pawn.IsAnimationHandleValid(GestureAnimationHandle))
	{
		m_Pawn.SmartPerTrackEaseOutAnimation(GestureAnimationHandle);
		ShockAI().AddLocomotionKeyword('WaitingForProtector', Class'ShockAI.ShockAI'.-1);
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyRunningDueToExclusivity()
{
	super(AI_RunnableAction).NotifyRunningDueToExclusivity();
	ShockAI().AddLocomotionKeyword('WaitingForProtector', 1);
	return;
	@NULL
}

function name GetGestureAnimation()
{
	local name Animation;
	local int AnimationIndex;

	// End:0x23
	if(__NFUN_154__(CurrentGestureAnimations.Length, 0))
	{
		CurrentGestureAnimations = GestureAnimations;
		AnimationIndex = __NFUN_167__(CurrentGestureAnimations.Length);
	}
	Animation = CurrentGestureAnimations[AnimationIndex];
	CurrentGestureAnimations.Remove(AnimationIndex, 1);
	return Animation;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function PlayGestureAnimation()
{
	local name GestureAnimation;

	GestureAnimation = GetGestureAnimation();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x76
	/*@Error*/
	GestureAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, GestureAnimation);
	m_Pawn.FinishAnimation(GestureAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	ShockAI().AddLocomotionKeyword('WaitingForProtector', 1);
	__NFUN_256__(InitialWaitForProtectorTime);
	PlayGestureAnimation();
	__NFUN_256__(RandRange(GestureTimeRange.Min, GestureTimeRange.Max));
	goto 'Loop';
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
	GestureAnimations[0]="GA_gThisWay_A_idle_mid"
	GestureAnimations[1]="GA_gThisWay_E"
	GestureAnimations[2]="GA_gThisWay_F"
	GestureAnimations[3]="GA_gThisWay_G"
	GestureAnimations[4]="GA_gThisWay_H"
	GestureTimeRange=(Min=0.0000000,Max=0.5000000)
	satisfiesGoal=Class'ShockAI.WaitForProtectorGoal'
	bExclusiveAction=true
}