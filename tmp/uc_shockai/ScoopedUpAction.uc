class ScoopedUpAction extends BioshockCharacterAction
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private MoveToGoal CurrentMoveToGoal;
var private int ScoopedUpAnimationHandle;
var config name ScoopedUpAnimationName;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	ShockAI().NotifyFullBodyHitReactionPreventionDesired(self);
	ShockAI().NotifyFallDownHitReactionPreventionDesired(self);
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
		if(m_Pawn.IsAnimationHandleValid(ScoopedUpAnimationHandle))
		{
		}
		m_Pawn.SmartPerTrackEaseOutAnimation(ScoopedUpAnimationHandle);
		ShockAI().NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
		ShockAI().NotifyFallDownHitReactionPreventionNoLongerDesired(self);
	}
	Gatherer(m_Pawn).BecomePhysical();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyStartScoopUp()
{
	runAction();
	return;
}

function bool GetDesiredRotationOverride(out Rotator DesiredRotation)
{
	DesiredRotation = Rotator(__NFUN_216__(m_Pawn.Location, Gatherer(m_Pawn).GetProtectorEscort().Location));
	return true;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function TurnAwayFromCurrentProtector()
{
	assert(__NFUN_114__(CurrentMoveToGoal, none));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, m_Pawn.Location);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetDesiredRotationOverride;
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	CurrentMoveToGoal.postGoal(self);
	Pause();
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function GetScoopedUp()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xA2
	/*@Error*/
	Gatherer(m_Pawn).BecomeNonPhysical();
	ScoopedUpAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, ScoopedUpAnimationName);
	m_Pawn.FinishAnimation(ScoopedUpAnimationHandle);
	Gatherer(m_Pawn).BecomePhysical();
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	TurnAwayFromCurrentProtector();
	GetScoopedUp();
	m_Pawn.dispatchMessage(Class'ShockAI.MessageGathererScoopedUp'.static.Allocate(self)., construct_Gatherer(Gatherer(m_Pawn)));
	succeed();
	stop;	
	@NULL
	@NULL
	@NULL
	@NULL
}

defaultproperties
{
	ScoopedUpAnimationName="GA_RosieSwitch"
	satisfiesGoal=Class'ShockAI.ScoopedUpGoal'
	bExclusiveAction=true
}