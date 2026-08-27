class PatrolAction extends BioshockCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) PatrolList Patrol;
var private MoveToGoal CurrentMoveToGoal;
var private TeleportGoal CurrentTeleportGoal;
var private PatrolPoint NextPatrolPoint;
var private bool bShouldRotateToFacePatrolPointRotation;
var private int PatrolAnimationHandle;

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	// End:0x33
	if(__NFUN_119__(CurrentMoveToGoal, none))
	{
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		// End:0x5C
		if(__NFUN_119__(CurrentTeleportGoal, none))
		{
			CurrentTeleportGoal.__NFUN_198__();
		}
		CurrentTeleportGoal = none;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x9F
		/*@Error*/
		m_Pawn.SmartPerTrackEaseOutAnimation(PatrolAnimationHandle);
	}
	ShockAI().NotifyPatrolVisionNoLongerDesired();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function int GetCurrentPatrolIndex()
{
	return PatrolGoal(achievingGoal).CurrentPatrolIndex;
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function IncrementCurrentPatrolIndex()
{
	__NFUN_163__(PatrolGoal(achievingGoal).CurrentPatrolIndex);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x7D
	/*@Error*/
	PatrolGoal(achievingGoal).CurrentPatrolIndex = 0;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool GetDesiredEndRotationOverride(out Rotator DesiredRotation)
{
	// End:0x2F
	if(bShouldRotateToFacePatrolPointRotation)
	{
		DesiredRotation = NextPatrolPoint.Rotation;
		return true;
		return false;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function TeleportToNextPatrolPoint()
{
	AssertWithDescription(__NFUN_114__(CurrentTeleportGoal, none), __NFUN_112__(string(Name), " expected CurrentTeleportGoal to be None!"));
	CurrentTeleportGoal = Class'ShockAI.TeleportGoal'.static.Allocate(self).;
	construct_AI_ResourceVectorBoolBoolRotatorBool(characterResource(), NextPatrolPoint.GetPawnUsageLocation(m_Pawn), __NFUN_154__(int(m_Pawn.AI_LOD_Level), int(3)), true, NextPatrolPoint.Rotation);
	CurrentTeleportGoal.__NFUN_199__();
	CurrentTeleportGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentTeleportGoal);
	CurrentTeleportGoal.unPostGoal(self);
	CurrentTeleportGoal.__NFUN_198__();
	CurrentTeleportGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function MoveToNextPatrolPoint()
{
	local bool bCouldNotFindPathToPatrolPoint;

	AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, NextPatrolPoint);
	assert(__NFUN_119__(CurrentMoveToGoal, none));
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.bTerminateIfStolen = true;
	CurrentMoveToGoal.__GetDesiredEndRotationOverride__Delegate = GetDesiredEndRotationOverride;
	CurrentMoveToGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentMoveToGoal);
	bCouldNotFindPathToPatrolPoint = CurrentMoveToGoal.CannotFindWayToDestination();
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x232
	/*@Error*/
	log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " could not find a path to "), string(NextPatrolPoint)), " while patrolling, just going to teleport there instead."));
	TeleportToNextPatrolPoint();
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function PlayAnimationAtPatrolPoint(int CurrentPatrolIndex)
{
	local PatrolEntry CurrentPatrolEntry;
	local name AnimationName;

	CurrentPatrolEntry = Patrol.GetPatrolEntry(CurrentPatrolIndex);
	// End:0x105
	if(__NFUN_255__(CurrentPatrolEntry.AnimationCategoryToPlayOnce, 'None'))
	{
		AnimationName = SpawningManager(Level().SpawningManager).GetAnimationByCategory(m_Pawn.Class, CurrentPatrolEntry.AnimationCategoryToPlayOnce);
		PatrolAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, AnimationName);
		m_Pawn.FinishAnimation(PatrolAnimationHandle);
		// End:0x1CF
		if(__NFUN_255__(CurrentPatrolEntry.AnimationCategoryToLoop, 'None'))
		{
			AnimationName = SpawningManager(Level().SpawningManager).GetAnimationByCategory(m_Pawn.Class, CurrentPatrolEntry.AnimationCategoryToLoop);
		}
		PatrolAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, AnimationName, Class'Engine.Actor'.8);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x2BC
		/*@Error*/
		log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " will play animation "), string(CurrentPatrolEntry.AnimationToPlayOnce)), " once."));
		PatrolAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, CurrentPatrolEntry.AnimationToPlayOnce);
	}
	m_Pawn.FinishAnimation(PatrolAnimationHandle);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x32F
	/*@Error*/
	PatrolAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, CurrentPatrolEntry.AnimationToLoop, Class'Engine.Actor'.8);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function PauseAtPatrolPoint()
{
	local int RandomChance, SpecifiedChance, CurrentPatrolIndex;
	local float TimeToPause;
	local PatrolEntry CurrentPatrolEntry;

	CurrentPatrolIndex = GetCurrentPatrolIndex();
	RandomChance = __NFUN_167__(100);
	CurrentPatrolEntry = Patrol.GetPatrolEntry(CurrentPatrolIndex);
	SpecifiedChance = CurrentPatrolEntry.IdleChance;
	log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " RandomChance to pause is: "), string(RandomChance)), " Specified Chance is: "), string(SpecifiedChance)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x3FE
	/*@Error*/
	ShockAI().NotifyPatrolVisionDesired();
	PlayAnimationAtPatrolPoint(CurrentPatrolIndex);
	// End:0x20C
	if(__NFUN_132__(CurrentPatrolEntry.IdleForever, __NFUN_154__(Patrol.GetNumPatrolEntries(), 1)))
	{
		log('AI', 4, __NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " will idle forever at current PatrolPoint "), string(Patrol.GetPatrolEntry(CurrentPatrolIndex).PatrolPoint.Name)));
		Pause();
		TimeToPause = RandRange(Patrol.GetPatrolEntry(CurrentPatrolIndex).IdleTime.Min, Patrol.GetPatrolEntry(CurrentPatrolIndex).IdleTime.Max);
		log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " will pause at current PatrolPoint "), string(Patrol.GetPatrolEntry(CurrentPatrolIndex).PatrolPoint.Name)), " for "), string(TimeToPause)), " seconds while looping the animation "), string(CurrentPatrolEntry.AnimationToLoop)), "."));
	}
	__NFUN_256__(TimeToPause);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x3E6
	/*@Error*/
	m_Pawn.SmartPerTrackEaseOutAnimation(PatrolAnimationHandle);
	ShockAI().NotifyPatrolVisionNoLongerDesired();
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function PatrolToNextPatrolPoint()
{
	local int CurrentPatrolIndex;
	local bool bShouldBeAggressive, bShouldRun;

	CurrentPatrolIndex = GetCurrentPatrolIndex();
	NextPatrolPoint = Patrol.GetPatrolEntry(CurrentPatrolIndex).PatrolPoint;
	AssertWithDescription(__NFUN_119__(NextPatrolPoint, none), __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("PatrolAction::MoveToNextPatrolPoint - Invalid Patrol Point Entry in Patrol Named: ", string(Patrol.PatrolName)), " for "), string(m_Pawn.Name)), " in its PatrolList at index: "), string(CurrentPatrolIndex)));
	bShouldRotateToFacePatrolPointRotation = __NFUN_129__(Patrol.GetPatrolEntry(CurrentPatrolIndex).bDoNotRotateToFacePatrolPointRotation);
	bShouldRun = Patrol.GetPatrolEntry(CurrentPatrolIndex).bShouldRun;
	bShouldBeAggressive = Patrol.GetPatrolEntry(CurrentPatrolIndex).bShouldBeAggressive;
	// End:0x205
	if(bShouldBeAggressive)
	{
		ShockAI().BecomeAggressive();
		goto J0x21D;
		ShockAI().BecomePassive();
		// End:0x245
		if(bShouldRun)
		{
			ShockAI().SetShouldRun();
			goto J0x25D;
			ShockAI().SetShouldWalk();
			clearDummyMovementGoal();
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x2AD
			/*@Error*/
		}
		MoveToNextPatrolPoint();
		goto J0x2B7;
		yield();
		useResources(Class'VengeanceShared.AI_Resource'.4);
	}
	PauseAtPatrolPoint();
	IncrementCurrentPatrolIndex();
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
	PatrolToNextPatrolPoint();
	yield();
	goto 'Begin';
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
	satisfiesGoal=Class'ShockAI.PatrolGoal'
}