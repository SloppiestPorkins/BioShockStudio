class GatherResourceAction extends BioshockCharacterAction implements IInterestedActorDestroyed
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

const kCheckReachabilityToBootyDeltaTime = 0.25;

var(Parameters) Actor Booty;
var(Parameters) bool bShouldRun;
var private MoveToGoal CurrentMoveToGoal;
var private int GatherAnimHandle;
var private int GestureAnimHandle;
var private bool bGatherSuccessful;
var private bool bGatherInterrupted;
var private bool bFoundGatherPoint;
var private Vector GatherPoint;
var private Vector GatherPointRigidBodyLocation;
var private int GatherPointRigidBodyIndex;
var array<Actor> BootyToAvoid;
var private float NextCheckReachabilityToBootyDeltaTime;
var private config float MinGatherTime;
var private config float MaxGatherTime;
var private config float SignificantRigidBodyMovementSize;

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
	// End:0x33
	if(__NFUN_119__(CurrentMoveToGoal, none))
	{
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		// End:0x76
		if(m_Pawn.IsAnimationHandleValid(GatherAnimHandle))
		{
		}
		m_Pawn.SmartPerTrackEaseOutAnimation(GatherAnimHandle);
		// End:0xB9
		if(m_Pawn.IsAnimationHandleValid(GestureAnimHandle))
		{
			m_Pawn.SmartPerTrackEaseOutAnimation(GestureAnimHandle);
		}
		ShockAI().StopSpeech('HeadedToBody');
		Gatherer(m_Pawn).RelinquishCurrentResource();
		m_Pawn.Level.UnRegisterNotifyActorDestroyed(self);
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnOtherActorDestroyed(Actor ActorBeingDestroyed)
{
	// End:0x4F
	if(__NFUN_114__(ActorBeingDestroyed, GetCurrentResource()))
	{
		Gatherer(m_Pawn).SetCurrentResource(none);
		__NFUN_113__('None');
		__NFUN_113__('Running');
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function NotifyPausedDueToExclusivity()
{
	super(AI_RunnableAction).NotifyPausedDueToExclusivity();
	// End:0x4D
	if(m_Pawn.IsAnimationHandleValid(GatherAnimHandle))
	{
		m_Pawn.SmartPerTrackEaseOutAnimation(GatherAnimHandle);
		// End:0x7C
		if(__NFUN_129__(bGatherSuccessful))
		{
			Gatherer(m_Pawn).NotifyGatheringInterrupted();
		}
		bGatherInterrupted = true;
		ShockAI().StopSpeech('HeadedToBody');
	}
	ShockAI().StopSpeech('SummonedProtector');
	Gatherer(m_Pawn).DeactivateGathererLookAtSensor();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyRunningDueToExclusivity()
{
	super(AI_RunnableAction).NotifyRunningDueToExclusivity();
	ShockAI().BecomePassive();
	ShockAI().SetShouldWalk();
	// End:0x88
	if(IsLocomotingToResource())
	{
		ShockAI().PlaySpeech('HeadedToBody');
		Gatherer(m_Pawn).ActivateGathererLookAtSensor();
		ShockAI().PlaySpeech('SummonedProtector');
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function Actor GetCurrentResource()
{
	return Gatherer(m_Pawn).GetCurrentResource();
	return;
	@NULL
	CommanderAction
}

function SetResourceForGatherer()
{
	// End:0x106
	if(__NFUN_119__(Booty, none))
	{
		// End:0xDA
		if(ShouldAvoidBooty(Booty))
		{
			log('AI', 2, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " (Label: "), string(m_Pawn.Label)), " has tried to move to "), string(Booty)), " already, and it was unreachable.  Will keep trying though."));
			Gatherer(m_Pawn).SetCurrentResource(Booty);
		}
		goto J0x120;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x120
		/*@Error*/
		FindResourceForGatherer();
		return;
		@NULL
		CommanderAction
		EcologyFighterCommanderAction
	}
	@NULL
}

function bool IsResourceOnFire()
{
	local Actor CurrentResource;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xBE
	/*@Error*/
	CurrentResource = GetCurrentResource();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xBE
	/*@Error*/
	// End:0x81
	if(CurrentResource.__NFUN_303__('ShockPawn'))
	{
		return ShockPawn(CurrentResource).IsBurning();
		goto J0xBE;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xBE
		/*@Error*/
	}
	return ReactiveActor(CurrentResource).IsBurning();
	return false;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool ShouldAvoidBooty(Actor TestBooty)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x54
	/*@Error*/
	// End:0x46
	if(__NFUN_114__(TestBooty, BootyToAvoid[i]))
	{
		return true;
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x0B;
		return false;
		return;
		@NULL
		CommanderAction
	}
	EcologyFighterCommanderAction
	@NULL
}

function FindResourceForGatherer()
{
	local Actor CurrentResource;
	local SpawnZoneInfo SpawnZoneIter;
	local array<IBooty> UsableBooty;
	local IBooty Iter;
	local NavigationPoint StartNavPoint, ClosestNavPointToBooty;
	local float Distance;
	local int i, j;
	local ShockAIScout GameScout;

	GameScout = SpawningManager(Level().SpawningManager).GetGameScout();
	assert(__NFUN_119__(GameScout, none));
	StartNavPoint = Gatherer(m_Pawn).GetCurrentVent().GetFrontPathNode();
	log('Gatherer', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__("FindResourceForGatherer - Gatherer: ", string(m_Pawn.Name)), " StartNavPoint: "), string(StartNavPoint)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x581
	/*@Error*/
	// End:0x1D9
	if(__NFUN_154__(StartNavPoint.Region.Zone.SpawnZones.Length, 0))
	{
		log('Gatherer', 2, __NFUN_112__(__NFUN_112__(__NFUN_112__("Could not find any spawn zones for gatherer at the node (", string(StartNavPoint.Name)), ") in front of: "), string(Gatherer(m_Pawn).GetCurrentVent())));
		goto J0x57E;
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x57E
		/*@Error*/
		SpawnZoneIter = SpawningManager(Level().SpawningManager).GetSpawnZoneByName(StartNavPoint.Region.Zone.SpawnZones[i]);
	}
	j = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x570
	/*@Error*/
	Iter = SpawnZoneIter.Booty[j];
	AssertWithDescription(__NFUN_119__(Iter, none), "Map needs to be rebuilt due to missing Booty.");
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x562
	/*@Error*/
	ClosestNavPointToBooty = Iter.GetClosestNavigationPoint();
	log('Gatherer', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("FindResourceForGatherer - Iter: ", string(Iter)), " ClosestNavPointToBooty: "), string(ClosestNavPointToBooty)), " SpawnZone: "), string(StartNavPoint.Region.Zone.SpawnZones[i])));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x562
	/*@Error*/
	Distance = GameScout.GetPathfindingDistanceBetween(m_Pawn, m_Pawn.Location, ClosestNavPointToBooty, ClosestNavPointToBooty.Location, m_Pawn.Class);
	log('Gatherer', 4, __NFUN_112__("FindResourceForGatherer - Distance: ", string(Distance)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x544
	/*@Error*/
	goto J0x562;
	UsableBooty[UsableBooty.Length] = Iter;
	__NFUN_163__(j);
	// [Loop Continue]
	goto J0x2A8;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x1E4;
	goto J0x5EA;
	log('Gatherer', 2, __NFUN_112__("Could not find a start point for gatherer in vent: ", string(Gatherer(m_Pawn).GetCurrentVent())));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x632
	/*@Error*/
	CurrentResource = Actor(UsableBooty[__NFUN_167__(UsableBooty.Length)]);
	assert(__NFUN_119__(CurrentResource, none));
	Gatherer(m_Pawn).SetCurrentResource(CurrentResource);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool IsRotatedToFaceEscort()
{
	local ShockPawn Escort;

	Escort = Gatherer(m_Pawn).GetShockPawnEscort();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xD3
	/*@Error*/
	return Class'ShockAI.MoveToAction'.static.IsRotatedTo(m_Pawn.Rotation, Rotator(__NFUN_216__(Escort.Location, m_Pawn.Location)));
	goto J0xD5;
	return true;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool GetDesiredRotationOverride(out Rotator DesiredRotation)
{
	local ShockPawn Escort;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x116
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xDA
	/*@Error*/
	Escort = Gatherer(m_Pawn).GetShockPawnEscort();
	// End:0xD7
	if(Class'Engine.Pawn'.static.checkAlive(Escort))
	{
		DesiredRotation = Rotator(__NFUN_216__(Escort.Location, m_Pawn.Location));
		return true;
		goto J0x116;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x116
		/*@Error*/
		DesiredRotation = Rotator(__NFUN_216__(GatherPoint, m_Pawn.Location));
		return true;
		return false;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function OnMoveStarted()
{
	// End:0x43
	if(m_Pawn.IsAnimationHandleValid(GatherAnimHandle))
	{
		m_Pawn.SmartPerTrackEaseOutAnimation(GatherAnimHandle);
		bGatherInterrupted = true;
		ShockAI().PlaySpeech('HeadedToBody');
	}
	Gatherer(m_Pawn).ActivateGathererLookAtSensor();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnMoveEnded()
{
	ShockAI().StopSpeech('HeadedToBody');
	Gatherer(m_Pawn).DeactivateGathererLookAtSensor();
	return;
	@NULL
	CommanderAction
}

function OnTurnStarted()
{
	// End:0x43
	if(m_Pawn.IsAnimationHandleValid(GatherAnimHandle))
	{
		m_Pawn.SmartPerTrackEaseOutAnimation(GatherAnimHandle);
		bGatherInterrupted = true;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function MoveToResource()
{
	assert(__NFUN_119__(GetCurrentResource(), none));
	assert(__NFUN_114__(CurrentMoveToGoal, none));
	// End:0x5F
	if(bShouldRun)
	{
		ShockAI().BecomeAggressive();
		ShockAI().SetShouldRun();
		goto J0x8F;
		ShockAI().SetShouldWalk();
	}
	ShockAI().BecomePassive();
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, GetCurrentResource());
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetDesiredRotationOverride;
	CurrentMoveToGoal.__GetUpdatedDestination__Delegate = GetUpdatedDestination;
	CurrentMoveToGoal.__OnMoveStarted__Delegate = OnMoveStarted;
	CurrentMoveToGoal.__OnMoveEnded__Delegate = OnMoveEnded;
	CurrentMoveToGoal.__OnTurnStarted__Delegate = OnTurnStarted;
	CurrentMoveToGoal.postGoal(self);
	NextCheckReachabilityToBootyDeltaTime = __NFUN_174__(Level().TimeSeconds, 0.2500000);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function RemoveMovementBehavior()
{
	// End:0x41
	if(__NFUN_119__(CurrentMoveToGoal, none))
	{
		CurrentMoveToGoal.unPostGoal(self);
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		bFoundGatherPoint = false;
		return;
		@NULL
		CommanderAction
	}
	EcologyFighterCommanderAction
	@NULL
}

function bool IsLocomotingToResource()
{
	return __NFUN_130__(__NFUN_130__(__NFUN_119__(CurrentMoveToGoal, none), __NFUN_129__(CurrentMoveToGoal.CannotFindWayToDestination())), __NFUN_132__(__NFUN_132__(__NFUN_129__(bFoundGatherPoint), __NFUN_129__(m_Pawn.ReachedLocation(GetGatherLocation()))), __NFUN_129__(Class'ShockAI.MoveToAction'.static.IsRotatedTo(Rotator(__NFUN_216__(GatherPoint, m_Pawn.Location)), m_Pawn.Rotation))));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function GatherResource()
{
	local float EndGatherResourceTime;

	bGatherInterrupted = false;
	GatherAnimHandle = m_Pawn.PlayAnimationOnChannel(0, Gatherer(m_Pawn).GetBeginGatherAnimation(), Class'Engine.Actor'.4);
	m_Pawn.FinishAnimation(GatherAnimHandle);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x20C
	/*@Error*/
	GatherAnimHandle = m_Pawn.PlayAnimationOnChannel(0, Gatherer(m_Pawn).GetLoopGatherAnimation(), Class'Engine.Actor'.8);
	EndGatherResourceTime = __NFUN_174__(Level().TimeSeconds, RandRange(MinGatherTime, MaxGatherTime));
	// End:0x15F
	if(__NFUN_130__(__NFUN_129__(ShouldInterruptGathering()), __NFUN_176__(Level().TimeSeconds, EndGatherResourceTime)))
	{
		yield();
		goto J0x11C;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x20C
		/*@Error*/
		GatherAnimHandle = m_Pawn.PlayAnimationOnChannel(0, Gatherer(m_Pawn).GetEndGatherAnimation());
		m_Pawn.FinishAnimation(GatherAnimHandle);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x20C
		/*@Error*/
	}
	bGatherSuccessful = true;
	Gatherer(m_Pawn).SetFullOfResource(true);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function GestureFinishedFeeding()
{
	local name GestureFinishedFeedingAnimation;

	GestureFinishedFeedingAnimation = Gatherer(m_Pawn).GetGestureFinishedFeedingAnimation();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x8C
	/*@Error*/
	GestureAnimHandle = m_Pawn.PlayAnimationOnChannel(0, GestureFinishedFeedingAnimation);
	m_Pawn.FinishAnimation(GestureAnimHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function bool HasGatherPointMovedSignificantly()
{
	local Vector RigidBodyLocation;

	RigidBodyLocation = IBooty(GetCurrentResource()).GetUpdatedRigidBodyLocation(GatherPointRigidBodyIndex);
	log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("RigidBodyLocation: ", string(RigidBodyLocation)), " GatherPoint: "), string(GatherPoint)), " Diff: "), string(VSizeSquared(__NFUN_216__(RigidBodyLocation, GatherPoint)))));
	return __NFUN_177__(VSizeSquared(__NFUN_216__(RigidBodyLocation, GatherPointRigidBodyLocation)), __NFUN_171__(SignificantRigidBodyMovementSize, SignificantRigidBodyMovementSize));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool ShouldInterruptGathering()
{
	log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__("bGatherInterrupted: ", string(bGatherInterrupted)), " HasGatherPointMovedSignificantly: "), string(HasGatherPointMovedSignificantly())));
	return __NFUN_132__(bGatherInterrupted, HasGatherPointMovedSignificantly());
	return;
	@NULL
	CommanderAction
}

function Vector GetGatherLocation()
{
	local Vector GatherLocation, DirectionToGathererXY;

	// End:0x66
	if(HasGatherPointMovedSignificantly())
	{
		// End:0x66
		if(__NFUN_129__(IBooty(GetCurrentResource()).GetBestGatherPoint(GatherPoint, GatherPointRigidBodyLocation, GatherPointRigidBodyIndex)))
		{
			bFoundGatherPoint = false;
			bGatherInterrupted = true;
			DirectionToGathererXY = __NFUN_226__(__NFUN_216__(m_Pawn.Location, GatherPoint));
		}
	}
	DirectionToGathererXY.Z = 0.0000000;
	GatherLocation = __NFUN_215__(GatherPoint, __NFUN_212__(DirectionToGathererXY, Gatherer(m_Pawn).GatherDistance));
	return GatherLocation;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function GetUpdatedDestination(out Actor outDestinationActor, out Vector outDestinationLocation)
{
	// End:0x2F
	if(bFoundGatherPoint)
	{
		outDestinationLocation = GetGatherLocation();
		outDestinationActor = none;
		goto J0x43;
		outDestinationActor = GetCurrentResource();
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

state Running
{Begin:

	RemoveMovementBehavior();
	SetResourceForGatherer();
	// End:0x2CB
	if(__NFUN_119__(GetCurrentResource(), none))
	{
		// End:0x6D
		if(__NFUN_114__(DummyWeaponGoal, none))
		{
			useResources(Class'VengeanceShared.AI_Resource'.2);
			ShockAI().PlaySpeech('SummonedProtector');
			MoveToResource();
		}
		// End:0x2C8
		if(__NFUN_129__(bGatherSuccessful))
		{
			// End:0x22E
			if(IsLocomotingToResource())
			{
				// End:0x1C1
				if(__NFUN_129__(bFoundGatherPoint))
				{
					// End:0x1BE
					if(__NFUN_177__(Level().TimeSeconds, NextCheckReachabilityToBootyDeltaTime))
					{
						// End:0x196
						if(Pawn.__NFUN_520__(GetCurrentResource()))
						{
							// End:0x143
							if(__NFUN_130__(__NFUN_129__(IsResourceOnFire()), IBooty(GetCurrentResource()).GetBestGatherPoint(GatherPoint, GatherPointRigidBodyLocation, GatherPointRigidBodyIndex)))
							{
								bFoundGatherPoint = true;
								goto J0x196;
								BootyToAvoid[BootyToAvoid.Length] = GetCurrentResource();
								Gatherer(m_Pawn).RelinquishCurrentResource();
								yield();
							}
							goto 'Begin';
							NextCheckReachabilityToBootyDeltaTime = __NFUN_174__(Level().TimeSeconds, 0.2500000);
							goto J0x221;
							// End:0x221
							if(IsResourceOnFire())
							{
								BootyToAvoid[BootyToAvoid.Length] = GetCurrentResource();
							}
							Gatherer(m_Pawn).RelinquishCurrentResource();
							yield();
						}
						goto 'Begin';
					}
					yield();
					// [Loop Continue]
					goto J0x86;
					// End:0x29B
					if(CurrentMoveToGoal.CannotFindWayToDestination())
					{
						BootyToAvoid[BootyToAvoid.Length] = GetCurrentResource();
						Gatherer(m_Pawn).RelinquishCurrentResource();
						yield();
					}
					goto 'Begin';
				}
				Gatherer(m_Pawn).NotifyStartingToFeed();
				GatherResource();
				// [Loop Continue]
				goto J0x77;
				goto J0x318;
				log('AI', 2, __NFUN_112__(string(m_Pawn.Name), " could not find a resource to use"));
			}
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x363
			/*@Error*/
		}
	}
	yield();
	goto J0x318;
	GestureFinishedFeeding();
	Gatherer(m_Pawn).NotifyFinishedFeeding();
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
	MinGatherTime=6.0000000
	MaxGatherTime=6.0000000
	SignificantRigidBodyMovementSize=4.0000000
	satisfiesGoal=Class'ShockAI.GatherResourceGoal'
	bExclusiveAction=true
}