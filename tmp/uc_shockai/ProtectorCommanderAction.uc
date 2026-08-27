class ProtectorCommanderAction extends EcologyFighterCommanderAction
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private ThreatenGoal CurrentThreatenGoal;
var private EscortGoal CurrentEscortGoal;
var private WaitForGathererGoal CurrentWaitForGathererGoal;
var private ReactToGathererDeathGoal CurrentReactToGathererDeathGoal;
var private ReactToTiredGathererGoal CurrentReactToTiredGathererGoal;
var private ReactToStunnedGathererGoal CurrentReactToStunnedGathererGoal;
var private ProtectPlayerGoal CurrentProtectPlayerGoal;
var private AlertSensor AlertSensor;
var array<ShockPawn> EscortDamagers;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super.initAction(R, Goal);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function Cleanup()
{
	super.Cleanup();
	// End:0x33
	if(__NFUN_119__(CurrentThreatenGoal, none))
	{
		CurrentThreatenGoal.__NFUN_198__();
		CurrentThreatenGoal = none;
		// End:0x5C
		if(__NFUN_119__(CurrentEscortGoal, none))
		{
			CurrentEscortGoal.__NFUN_198__();
		}
		CurrentEscortGoal = none;
		// End:0x85
		if(__NFUN_119__(CurrentWaitForGathererGoal, none))
		{
			CurrentWaitForGathererGoal.__NFUN_198__();
			CurrentWaitForGathererGoal = none;
		}
		// End:0xAE
		if(__NFUN_119__(CurrentReactToGathererDeathGoal, none))
		{
			CurrentReactToGathererDeathGoal.__NFUN_198__();
			CurrentReactToGathererDeathGoal = none;
			// End:0xD7
			if(__NFUN_119__(CurrentReactToTiredGathererGoal, none))
			{
			}
			CurrentReactToTiredGathererGoal.__NFUN_198__();
			CurrentReactToTiredGathererGoal = none;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x100
			/*@Error*/
			CurrentReactToStunnedGathererGoal.__NFUN_198__();
			CurrentReactToStunnedGathererGoal = none;
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x129
		/*@Error*/
		CurrentProtectPlayerGoal.__NFUN_198__();
		CurrentProtectPlayerGoal = none;
		DeactivateAlertSensor();
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function HandleEscortedGathererDied(Gatherer DeadGatherer, ShockPawn Killer)
{
	assert(__NFUN_132__(__NFUN_114__(CurrentReactToGathererDeathGoal, none), CurrentReactToGathererDeathGoal.hasCompleted()));
	assert(__NFUN_130__(__NFUN_119__(DeadGatherer, none), __NFUN_129__(DeadGatherer.IsAlive())));
	// End:0x99
	if(__NFUN_119__(CurrentReactToGathererDeathGoal, none))
	{
		CurrentReactToGathererDeathGoal.unPostGoal(self);
		CurrentReactToGathererDeathGoal.__NFUN_198__();
		CurrentReactToGathererDeathGoal = none;
		CurrentReactToGathererDeathGoal = Class'ShockAI.ReactToGathererDeathGoal'.static.Allocate(self).;
		construct_AI_ResourceGathererShockPawn(characterResource(), DeadGatherer, Killer);
	}
	CurrentReactToGathererDeathGoal.__NFUN_199__();
	CurrentReactToGathererDeathGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function NotifyAttackDamagerOfPerceivedGatherer(ShockPawn Damager)
{
	AddUniqueEscortDamager(Damager);
	SetAttackTarget(Damager);
	return;
	@NULL
	CommanderAction
}

function BeginProtectingPlayer(ShockPlayer PlayerToProtect)
{
	// End:0x41
	if(__NFUN_119__(CurrentThreatenGoal, none))
	{
		CurrentThreatenGoal.unPostGoal(self);
		CurrentThreatenGoal.__NFUN_198__();
		CurrentThreatenGoal = none;
		// End:0x82
		if(__NFUN_119__(CurrentReactToTiredGathererGoal, none))
		{
			CurrentReactToTiredGathererGoal.unPostGoal(self);
		}
		CurrentReactToTiredGathererGoal.__NFUN_198__();
		CurrentReactToTiredGathererGoal = none;
		// End:0xC3
		if(__NFUN_119__(CurrentWaitForGathererGoal, none))
		{
			CurrentWaitForGathererGoal.unPostGoal(self);
			CurrentWaitForGathererGoal.__NFUN_198__();
		}
		CurrentWaitForGathererGoal = none;
		// End:0x104
		if(__NFUN_119__(CurrentInvestigateGoal, none))
		{
			CurrentInvestigateGoal.unPostGoal(self);
			CurrentInvestigateGoal.__NFUN_198__();
			CurrentInvestigateGoal = none;
		}
		// End:0x145
		if(__NFUN_119__(CurrentSearchGoal, none))
		{
			CurrentInvestigateGoal.unPostGoal(self);
			CurrentInvestigateGoal.__NFUN_198__();
			CurrentInvestigateGoal = none;
			// End:0x1A2
			if(__NFUN_130__(__NFUN_119__(CurrentProtectPlayerGoal, none), CurrentProtectPlayerGoal.hasCompleted()))
			{
			}
			CurrentProtectPlayerGoal.unPostGoal(self);
			CurrentProtectPlayerGoal.__NFUN_198__();
			CurrentProtectPlayerGoal = none;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x21C
			/*@Error*/
		}
		CurrentProtectPlayerGoal = Class'ShockAI.ProtectPlayerGoal'.static.Allocate(self).;
		construct_AI_ResourceShockPlayer(characterResource(), PlayerToProtect);
		CurrentProtectPlayerGoal.__NFUN_199__();
		CurrentProtectPlayerGoal.postGoal(self);
		return;
	}
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function EndProtectingPlayer()
{
	// End:0x41
	if(__NFUN_119__(CurrentProtectPlayerGoal, none))
	{
		CurrentProtectPlayerGoal.unPostGoal(self);
		CurrentProtectPlayerGoal.__NFUN_198__();
		CurrentProtectPlayerGoal = none;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function goalAchievedCB(AI_Goal Goal, AI_Action Child)
{
	super.goalAchievedCB(Goal, Child);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x46
	/*@Error*/
	HandleFinishedThreatenGoal(Goal);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function goalNotAchievedCB(AI_Goal Goal, AI_Action Child, ActionBase.ACT_ErrorCodes errorCode)
{
	super.goalNotAchievedCB(Goal, Child, errorCode);
	assert(__NFUN_119__(Goal, none));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5E
	/*@Error*/
	HandleFinishedThreatenGoal(Goal);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function HandleFinishedSearchGoal(AI_Goal Goal)
{
	super.HandleFinishedSearchGoal(Goal);
	NotifyGathererThatWeStoppedAttacking();
	return;
	@NULL
	CommanderAction
}

function HandleFinishedThreatenGoal(AI_Goal Goal)
{
	assert(__NFUN_114__(Goal, CurrentThreatenGoal));
	CurrentThreatenGoal.unPostGoal(self);
	CurrentThreatenGoal.__NFUN_198__();
	CurrentThreatenGoal = none;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function ResetAttackTarget(ShockPawn Target)
{
	super.ResetAttackTarget(Target);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x71
	/*@Error*/
	RemoveEscortDamager(Target);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x71
	/*@Error*/
	Protector(m_Pawn).ResetDispositionToPlayer();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ResetAttackTargets()
{
	log('AI', 4, __NFUN_112__(string(m_Pawn.Name), " ResetAttackTargets - clearing current attack target, intentional attackers, and escort damagers. resetting disposition to the player."));
	CurrentAttackTarget = none;
	EscortDamagers.Remove(0, EscortDamagers.Length);
	ShockAI().ClearIntentionalAttackers();
	EcologyFighter(m_Pawn).ClearForcedEnemies();
	Protector(m_Pawn).ResetDispositionToPlayer();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x164
	/*@Error*/
	CurrentAttackTargetGoal.unPostGoal(self);
	HandleFinishedAttackTargetGoal(CurrentAttackTargetGoal);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnSensorMessage(AI_Sensor sensor, AI_SensorData Value, Object userData)
{
	local ShockPawn AlertedPawn;

	super.OnSensorMessage(sensor, Value, userData);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x78
	/*@Error*/
	AlertedPawn = ShockPawn(Value.objectData);
	HandleAlertSensorMessage(AlertedPawn);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function HandleAlertSensorMessage(ShockPawn AlertedPawn)
{
	// End:0x5F
	if(__NFUN_114__(AlertedPawn, none))
	{
		// End:0x5C
		if(__NFUN_130__(__NFUN_119__(CurrentThreatenGoal, none), __NFUN_129__(CurrentThreatenGoal.hasCompleted())))
		{
			CurrentThreatenGoal.StopThreateningTarget(AlertedPawn);
			goto J0x198;
			// End:0xA0
			if(__NFUN_119__(CurrentMoveToSpawnPointGoal, none))
			{
				CurrentMoveToSpawnPointGoal.unPostGoal(self);
			}
		}
		CurrentMoveToSpawnPointGoal.__NFUN_198__();
		CurrentMoveToSpawnPointGoal = none;
		// End:0x11E
		if(__NFUN_119__(CurrentThreatenGoal, none))
		{
			// End:0xFE
			if(CurrentThreatenGoal.hasCompleted())
			{
				CurrentThreatenGoal.unPostGoal(self);
			}
			CurrentThreatenGoal.__NFUN_198__();
			CurrentThreatenGoal = none;
			goto J0x11E;
			CurrentThreatenGoal.StartThreateningTarget(AlertedPawn);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x198
			/*@Error*/
			CurrentThreatenGoal = Class'ShockAI.ThreatenGoal'.static.Allocate(self).;
		}
		construct_AI_ResourceShockPawn(characterResource(), AlertedPawn);
	}
	CurrentThreatenGoal.__NFUN_199__();
	CurrentThreatenGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function ActivateAlertSensor()
{
	assert(__NFUN_114__(AlertSensor, none));
	AlertSensor = AlertSensor(Class'VengeanceShared.AI_Sensor'.static.activateSensor(self, Class'ShockAI.AlertSensor', characterResource(), 0.0000000, 1000000.0000000));
	AlertSensor.setParameters(ShockAI(), EcologyFighter(m_Pawn).SpawnPoint, Protector(m_Pawn).GuardProtectorRange, true);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function DeactivateAlertSensor()
{
	// End:0x32
	if(__NFUN_119__(AlertSensor, none))
	{
		AlertSensor.deactivateSensor(self);
		AlertSensor = none;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function SearchForTarget(ShockPawn Target, Vector LastKnownLocation, Vector LastMovingDirection, Vector LocationWhenLostTarget)
{
	local Gatherer CurrentGatherer;
	local float MaxDistanceFromGathererWhileSearching;

	// End:0x41
	if(__NFUN_119__(CurrentSearchGoal, none))
	{
		CurrentSearchGoal.unPostGoal(self);
		CurrentSearchGoal.__NFUN_198__();
		CurrentSearchGoal = none;
		CurrentGatherer = Protector(m_Pawn).GetCurrentGatherer();
	}
	// End:0xC0
	if(__NFUN_130__(__NFUN_119__(CurrentGatherer, none), CurrentGatherer.IsAlive()))
	{
		MaxDistanceFromGathererWhileSearching = Protector(m_Pawn).GetMaxDistanceFromGathererWhileSearching();
		CurrentSearchGoal = Class'ShockAI.SearchGoal'.static.Allocate(self).;
		construct_AI_ResourceShockPawnVectorVectorVector(characterResource(), Target, LastKnownLocation, LastMovingDirection, LocationWhenLostTarget);
	}
	CurrentSearchGoal.__NFUN_199__();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x16A
	/*@Error*/
	CurrentSearchGoal.SetMaximumDistanceToMoveFromActor(CurrentGatherer, MaxDistanceFromGathererWhileSearching);
	CurrentSearchGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function HandleSuspiciousEvent(Vector SuspiciousLocation, Vector SuspiciousDirection, optional name SoundCategory)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x56
	/*@Error*/
	CurrentSearchGoal.UpdateSuspiciousLocation(SuspiciousLocation, SuspiciousDirection);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function NotifyGathererExitingVent()
{
	assert(__NFUN_119__(CurrentEscortGoal, none));
	CurrentEscortGoal.NotifyGathererExitingVent();
	return;
	@NULL
	CommanderAction
}

function NotifyGathererStartingToFeed()
{
	assert(__NFUN_119__(CurrentEscortGoal, none));
	CurrentEscortGoal.NotifyGathererStartingToFeed();
	return;
	@NULL
	CommanderAction
}

function NotifyGathererFeedingInterrupted()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x26
	/*@Error*/
	CurrentEscortGoal.NotifyGathererFeedingInterrupted();
	return;
	@NULL
	CommanderAction
}

function NotifyGathererFinishedFeeding()
{
	assert(__NFUN_119__(CurrentEscortGoal, none));
	CurrentEscortGoal.NotifyGathererFinishedFeeding();
	return;
	@NULL
	CommanderAction
}

function AddUniqueEscortDamager(ShockPawn EscortDamager)
{
	local int i;

	i = 0;
	// End:0x54
	if(__NFUN_150__(i, EscortDamagers.Length))
	{
		// End:0x46
		if(__NFUN_114__(EscortDamagers[i], EscortDamager))
		{
			return;
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x0B;
			EscortDamagers[EscortDamagers.Length] = EscortDamager;
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xAE
		/*@Error*/
	}
	Protector(m_Pawn).BecomeHostileTowardsPlayer();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function RemoveEscortDamager(ShockPawn EscortDamager)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x66
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x58
	/*@Error*/
	EscortDamagers.Remove(i, 1);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function NotifyEscortedGathererDamaged(Gatherer DamagedGatherer, Actor Damager)
{
	local ShockPawn ShockPawnDamager;

	log('AI_Ecology', 4, __NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " NotifyEscortedGathererDamaged - Damager is: "), string(Damager)));
	// End:0xD5
	if(__NFUN_130__(Damager.__NFUN_303__('InsectSwarm'), __NFUN_119__(InsectSwarm(Damager).SwarmPlayerOwner, none)))
	{
		ShockPawnDamager = InsectSwarm(Damager).SwarmPlayerOwner;
		goto J0xF1;
		ShockPawnDamager = ShockPawn(Damager);
		// End:0x142
		if(__NFUN_119__(ShockPawnDamager, none))
		{
			AddUniqueEscortDamager(ShockPawnDamager);
			// End:0x142
			if(__NFUN_129__(Class'Engine.Pawn'.static.checkAlive(CurrentAttackTarget)))
			{
			}
			UpdateAttackTargets();
			// End:0x183
			if(__NFUN_129__(Class'Engine.Pawn'.static.checkAlive(DamagedGatherer)))
			{
				HandleEscortedGathererDied(DamagedGatherer, ShockPawnDamager);
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x20A
				/*@Error*/
			}
		}
		InvestigateGathererDamage(DamagedGatherer, Damager);
		return;
	}
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyGathererThatWeAreAttacking()
{
	// End:0x3E
	if(__NFUN_119__(CurrentEscortGoal, none))
	{
		assert(__NFUN_119__(CurrentAttackTarget, none));
		CurrentEscortGoal.NotifyGathererThatWeAreAttacking(CurrentAttackTarget);
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function NotifyGathererThatWeStoppedAttacking()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x26
	/*@Error*/
	CurrentEscortGoal.NotifyGathererThatWeStoppedAttacking();
	return;
	@NULL
	CommanderAction
}

function NotifyGathererPlayingPreEnterAnimation()
{
	assert(__NFUN_119__(CurrentEscortGoal, none));
	CurrentEscortGoal.NotifyGathererPlayingPreEnterAnimation();
	return;
	@NULL
	CommanderAction
}

function NotifyGathererReadyToEnterVent()
{
	assert(__NFUN_119__(CurrentEscortGoal, none));
	CurrentEscortGoal.NotifyGathererReadyToEnterVent();
	return;
	@NULL
	CommanderAction
}

function NotifyGathererLookingAtTarget()
{
	// End:0x5B
	if(__NFUN_119__(CurrentWaitForGathererGoal, none))
	{
		assert(CurrentWaitForGathererGoal.hasCompleted());
		CurrentWaitForGathererGoal.unPostGoal(self);
		CurrentWaitForGathererGoal.__NFUN_198__();
		CurrentWaitForGathererGoal = none;
		assert(__NFUN_114__(CurrentWaitForGathererGoal, none));
		CurrentWaitForGathererGoal = Class'ShockAI.WaitForGathererGoal'.static.Allocate(self).;
	}
	construct_AI_ResourceGatherer(characterResource(), Protector(m_Pawn).GetCurrentGatherer());
	CurrentWaitForGathererGoal.__NFUN_199__();
	CurrentWaitForGathererGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyGathererFinishedLookingAtTarget()
{
	// End:0x41
	if(__NFUN_119__(CurrentWaitForGathererGoal, none))
	{
		CurrentWaitForGathererGoal.unPostGoal(self);
		CurrentWaitForGathererGoal.__NFUN_198__();
		CurrentWaitForGathererGoal = none;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function NotifyReactToTiredGatherer()
{
	StopReactingToTiredGatherer();
	CurrentReactToTiredGathererGoal = Class'ShockAI.ReactToTiredGathererGoal'.static.Allocate(self).;
	construct_AI_Resource(characterResource());
	CurrentReactToTiredGathererGoal.__NFUN_199__();
	CurrentReactToTiredGathererGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function StopReactingToTiredGatherer()
{
	// End:0x41
	if(__NFUN_119__(CurrentReactToTiredGathererGoal, none))
	{
		CurrentReactToTiredGathererGoal.unPostGoal(self);
		CurrentReactToTiredGathererGoal.__NFUN_198__();
		CurrentReactToTiredGathererGoal = none;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function NotifyGathererJumpingOff()
{
	assert(__NFUN_119__(CurrentEscortGoal, none));
	CurrentEscortGoal.NotifyGathererJumpingOff();
	return;
	@NULL
	CommanderAction
}

function NotifyGathererStunned()
{
	// End:0x41
	if(__NFUN_119__(CurrentReactToStunnedGathererGoal, none))
	{
		CurrentReactToStunnedGathererGoal.unPostGoal(self);
		CurrentReactToStunnedGathererGoal.__NFUN_198__();
		CurrentReactToStunnedGathererGoal = none;
		CurrentReactToStunnedGathererGoal = Class'ShockAI.ReactToStunnedGathererGoal'.static.Allocate(self).;
	}
	construct_AI_Resource(characterResource());
	CurrentReactToStunnedGathererGoal.__NFUN_199__();
	CurrentReactToStunnedGathererGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyGathererNoLongerStunned()
{
	// End:0x41
	if(__NFUN_119__(CurrentReactToStunnedGathererGoal, none))
	{
		CurrentReactToStunnedGathererGoal.unPostGoal(self);
		CurrentReactToStunnedGathererGoal.__NFUN_198__();
		CurrentReactToStunnedGathererGoal = none;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function StartBerserkBehavior()
{
	super(CommanderAction).StartBerserkBehavior();
	Protector(m_Pawn).BecomeHostileTowardsPlayer();
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function StopBerserkBehavior()
{
	local ShockPlayer Player;

	super(CommanderAction).StopBerserkBehavior();
	Player = ShockPlayer(Level().GetLocalPlayerController().Pawn);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x90
	/*@Error*/
	Protector(m_Pawn).ResetDispositionToPlayer();
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function InvestigateGathererDamage(Gatherer DamagedGatherer, Actor Damager)
{
	Investigate(Damager.Location, __NFUN_216__(Damager.Location, DamagedGatherer.Location));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function InvestigatePlayer(ShockPlayer Player)
{
	Investigate(Player.Location, __NFUN_216__(Player.Location, m_Pawn.Location));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyThreatenTarget(ShockPawn NewThreatenTarget)
{
	ThreatenTarget(NewThreatenTarget);
	return;
	@NULL
}

function NotifyRemoveThreatenTarget(ShockPawn FormerThreatenTarget)
{
	StopThreateningTarget(FormerThreatenTarget);
	return;
	@NULL
}

function ThreatenTarget(ShockPawn ThreatenTarget)
{
	AssertWithDescription(Class'Engine.Pawn'.static.checkAlive(ThreatenTarget), __NFUN_112__(__NFUN_112__("ThreatenTarget (", string(ThreatenTarget)), ") is not alive!"));
	Protector(m_Pawn).SetLastThreatenTarget(ThreatenTarget);
	// End:0x102
	if(__NFUN_114__(CurrentThreatenGoal, none))
	{
		CurrentThreatenGoal = Class'ShockAI.ThreatenGoal'.static.Allocate(self).;
		construct_AI_ResourceShockPawn(characterResource(), ThreatenTarget);
		CurrentThreatenGoal.__NFUN_199__();
		CurrentThreatenGoal.postGoal(self);
		goto J0x13E;
		assert(__NFUN_129__(CurrentThreatenGoal.hasCompleted()));
		CurrentThreatenGoal.StartThreateningTarget(ThreatenTarget);
		return;
		@NULL
		CommanderAction
	}
	EcologyFighterCommanderAction
	@NULL
}

function StopThreateningTarget(ShockPawn FormerThreatenTarget)
{
	// End:0x2F
	if(__NFUN_119__(CurrentThreatenGoal, none))
	{
		CurrentThreatenGoal.StopThreateningTarget(FormerThreatenTarget);
		return;
		@NULL
		CommanderAction
	}
	EcologyFighterCommanderAction
}

function bool IsSuspectingAttackFrom(ShockPawn Target)
{
	return __NFUN_132__(__NFUN_114__(CurrentAttackTarget, Target), __NFUN_130__(__NFUN_119__(CurrentThreatenGoal, none), __NFUN_114__(CurrentThreatenGoal.GetThreatenTarget(), Target)));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool HasDamagedGatherer(ShockPawn Target)
{
	//native.Target;	
	@NULL
}

function OnAttackTargetSet()
{
	super.OnAttackTargetSet();
	Protector(m_Pawn).SetCanPickUpGatherer(true);
	NotifyGathererThatWeAreAttacking();
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function NotifyFinishedAttacking()
{
	super.NotifyFinishedAttacking();
	NotifyGathererThatWeStoppedAttacking();
	return;
	@NULL
}

function Escort()
{
	assert(__NFUN_114__(CurrentEscortGoal, none));
	CurrentEscortGoal = Class'ShockAI.EscortGoal'.static.Allocate(self).;
	construct_AI_Resource(characterResource());
	CurrentEscortGoal.__NFUN_199__();
	CurrentEscortGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	log('AI', 3, __NFUN_112__(__NFUN_112__(string(Name), " Running for: "), string(m_Pawn.Name)));
	ShockAI().SetInitialAIState();
	// End:0xFA
	if(Protector(m_Pawn).IsGuardingProtector())
	{
		ActivateAlertSensor();
		// End:0xF7
		if(true)
		{
			// End:0xEC
			if(__NFUN_130__(__NFUN_132__(__NFUN_114__(CurrentThreatenGoal, none), CurrentThreatenGoal.hasCompleted()), __NFUN_129__(EcologyFighter(m_Pawn).IsAtSpawnPoint())))
			{
				MoveToSpawnPoint();
				__NFUN_256__(1.0000000);
				// [Loop Continue]
				goto J0x8C;
				goto J0x104;
				Escort();
				stop;												
			}
		}
	}
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
	RecentlySeenTime=20.0000000
}