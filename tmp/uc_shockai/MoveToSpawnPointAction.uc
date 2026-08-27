class MoveToSpawnPointAction extends BioshockCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) Actor SpawnPoint;
var private bool bFinishedMovingToSpawnPoint;
var private MoveToGoal CurrentMoveToGoal;

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	// End:0x33
	if(__NFUN_119__(CurrentMoveToGoal, none))
	{
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function OnMoveStarted()
{
	bFinishedMovingToSpawnPoint = false;
	return;
	@NULL
}

function OnMoveEnded()
{
	bFinishedMovingToSpawnPoint = true;
	return;
	@NULL
}

function bool GetDesiredRotationOverride(out Rotator DesiredRotation)
{
	// End:0x2F
	if(bFinishedMovingToSpawnPoint)
	{
		DesiredRotation = SpawnPoint.Rotation;
		return true;
		return false;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function MoveToSpawnPoint()
{
	AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, SpawnPoint);
	assert(__NFUN_119__(CurrentMoveToGoal, none));
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__OnMoveEnded__Delegate = OnMoveEnded;
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetDesiredRotationOverride;
	CurrentMoveToGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentMoveToGoal);
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	// End:0x6F
	if(__NFUN_130__(__NFUN_114__(DummyWeaponGoal, none), __NFUN_114__(CurrentMoveToGoal, none)))
	{
		waitForResourcesAvailable(achievingGoal.Priority, achievingGoal.Priority);
		useResources(Class'VengeanceShared.AI_Resource'.2);
		ShockAI().SetShouldWalk();
		ShockAI().BecomePassive();
	}
	MoveToSpawnPoint();
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
	satisfiesGoal=Class'ShockAI.MoveToSpawnPointGoal'
}