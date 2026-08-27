class CrawlThroughDoorAction extends BioshockCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

const NEAR_DOOR = 100.0f;

var(Parameters) ThreeStateDoor Door;
var(Parameters) bool bShouldUnlock;
var private MoveToGoal CurrentMoveToGoal;
var private int CrawlingHandle;
var private Gatherer AI;

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	// End:0x33
	if(__NFUN_119__(CurrentMoveToGoal, none))
	{
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		Door.CloseAlternateDoor();
	}
	Gatherer(m_Pawn).BecomePhysical();
	AI.bIsCrawlingThroughDoor = false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Vector FindNearSocket(ThreeStateDoor Door)
{
	local Vector Socket_1, Socket_2;

	Socket_1 = Door.GetBoneCoords('AISocket_1', true).Origin;
	Socket_2 = Door.GetBoneCoords('AISocket_2', true).Origin;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xE0
	/*@Error*/
	return Socket_1;
	goto J0xEA;
	return Socket_2;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function Vector FindFarSocket(ThreeStateDoor Door)
{
	local Vector Socket_1, Socket_2;

	Socket_1 = Door.GetBoneCoords('AISocket_1', true).Origin;
	Socket_2 = Door.GetBoneCoords('AISocket_2', true).Origin;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xE0
	/*@Error*/
	return Socket_2;
	goto J0xEA;
	return Socket_1;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool GetDesiredRotationOverride(out Rotator NewDesiredRotation)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x85
	/*@Error*/
	NewDesiredRotation = Rotator(__NFUN_216__(Door.Location, m_Pawn.Location));
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

	AI = Gatherer(m_Pawn);
	AI.bIsCrawlingThroughDoor = true;
	// End:0x136
	if(__NFUN_129__(Door.IsLocked()))
	{
		AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
		CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
		construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, FindFarSocket(Door), false);
		CurrentMoveToGoal.postGoal(self).__NFUN_199__();
		waitForGoal_AI_Goal(CurrentMoveToGoal);
		goto J0x381;
		AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
	}
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, FindNearSocket(Door), false);
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetDesiredRotationOverride;
	CurrentMoveToGoal.postGoal(self).__NFUN_199__();
	waitForGoal_AI_Goal(CurrentMoveToGoal);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	Door.OpenAlternateDoor();
	__NFUN_256__(1.0000000);
	AI.BecomeNonPhysical();
	CrawlingHandle = AI.PlayAnimationOnChannel(0, 'GA_CrawlDoor', Class'Engine.Actor'.4);
	AI.FinishAnimation(CrawlingHandle);
	AI.FlatEaseOutAnimation(CrawlingHandle, 0.5000000);
	AI.BecomePhysical();
	Door.CloseAlternateDoor();
	AI.PlaySpeech('GathererThroughDoor');
	__NFUN_256__(1.5000000);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x381
	/*@Error*/
	Door.unlock();
	succeed();
	stop;				
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// BadToken (0x03)
	/*@Error*/
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.CrawlThroughDoorGoal'
	bExclusiveAction=true
}