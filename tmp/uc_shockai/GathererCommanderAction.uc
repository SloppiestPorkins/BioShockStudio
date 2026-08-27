class GathererCommanderAction extends EcologyCommanderAction implements IInterestedActorDestroyed, IInterestedPawnDied
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

const kReturnToVentElevatedPriority = 76;
const PANIC_DISTANCE = 2000.0f;

var private ExitVentGoal CurrentExitVentGoal;
var private GatherResourceGoal CurrentGatherResourceGoal;
var private AlertGoal CurrentAlertGoal;
var private PanicGoal CurrentPanicGoal;
var private WaitForProtectorGoal CurrentWaitForProtectorGoal;
var private ReturnToVentGoal CurrentReturnToVentGoal;
var private GathererLookAtTargetGoal CurrentGathererLookAtTargetGoal;
var private HeadTrackingGoal CurrentHeadTrackingGoal;
var private ScoopedUpGoal CurrentScoopedUpGoal;
var private TiredGoal CurrentTiredGoal;
var private StunnedGoal CurrentStunnedGoal;
var private UnconsciousGoal CurrentUnconsciousGoal;
var private AlertSensor CurrentAlertSensor;
var private GathererLookAtSensor CurrentGathererLookAtSensor;
var private PlayerEscortedGatherer PlayerEscortedGatherer;
var private int ExitFromVentAnimationHandle;
var private float LastTimeLookedAtInterestingObject;
var private Vector OldLocation;
var private bool bFellBehind;
var private config float LookAtInterestingObjectChance;
var private config float MinTimeBetweenLookingAtInterestingObjects;
var config Range AlertedDistanceRange;
var private config float DistanceForPEGToWait;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(CommanderAction).initAction(R, Goal);
	m_Pawn.Level.RegisterNotifyActorDestroyed(self);
	m_Pawn.Level.RegisterNotifyPawnDied(self);
	ShockAI().BecomePassive();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	super.Cleanup();
	// End:0x33
	if(__NFUN_119__(CurrentExitVentGoal, none))
	{
		CurrentExitVentGoal.__NFUN_198__();
		CurrentExitVentGoal = none;
		// End:0x5C
		if(__NFUN_119__(CurrentGatherResourceGoal, none))
		{
			CurrentGatherResourceGoal.__NFUN_198__();
		}
		CurrentGatherResourceGoal = none;
		// End:0x85
		if(__NFUN_119__(CurrentAlertGoal, none))
		{
			CurrentAlertGoal.__NFUN_198__();
			CurrentAlertGoal = none;
		}
		// End:0xAE
		if(__NFUN_119__(CurrentPanicGoal, none))
		{
			CurrentPanicGoal.__NFUN_198__();
			CurrentPanicGoal = none;
			// End:0xD7
			if(__NFUN_119__(CurrentWaitForProtectorGoal, none))
			{
			}
			CurrentWaitForProtectorGoal.__NFUN_198__();
			CurrentWaitForProtectorGoal = none;
			// End:0x100
			if(__NFUN_119__(CurrentReturnToVentGoal, none))
			{
				CurrentReturnToVentGoal.__NFUN_198__();
				CurrentReturnToVentGoal = none;
			}
			// End:0x129
			if(__NFUN_119__(CurrentGathererLookAtTargetGoal, none))
			{
				CurrentGathererLookAtTargetGoal.__NFUN_198__();
				CurrentGathererLookAtTargetGoal = none;
				// End:0x152
				if(__NFUN_119__(CurrentHeadTrackingGoal, none))
				{
				}
				CurrentHeadTrackingGoal.__NFUN_198__();
				CurrentHeadTrackingGoal = none;
				// End:0x17B
				if(__NFUN_119__(CurrentScoopedUpGoal, none))
				{
					CurrentScoopedUpGoal.__NFUN_198__();
				}
				CurrentScoopedUpGoal = none;
				// End:0x1A4
				if(__NFUN_119__(CurrentTiredGoal, none))
				{
					CurrentTiredGoal.__NFUN_198__();
					CurrentTiredGoal = none;
					/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
						
					*/

					// End:0x1CD
					/*@Error*/
				}
				CurrentStunnedGoal.__NFUN_198__();
				CurrentStunnedGoal = none;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x1F6
				/*@Error*/
				CurrentUnconsciousGoal.__NFUN_198__();
			}
			CurrentUnconsciousGoal = none;
			DeactivateAlertSensor();
			DeactivateGathererLookAtSensor();
			m_Pawn.Level.UnRegisterNotifyActorDestroyed(self);
		}
		m_Pawn.Level.UnRegisterNotifyPawnDied(self);
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ShockPawn GetPanicInducer()
{
	return Gatherer(m_Pawn).GetPanicInducer();
	return;
	@NULL
	CommanderAction
}

function OnOtherPawnDied(Pawn DeadPawn)
{
	// End:0x38
	if(__NFUN_114__(DeadPawn, Gatherer(m_Pawn).GetProtectorEscort()))
	{
		HandleProtectorEscortDied();
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function OnOtherActorDestroyed(Actor ActorBeingDestroyed)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x90
	/*@Error*/
	// End:0x70
	if(__NFUN_177__(Gatherer(m_Pawn).GetProtectorEscort().GetHealth(), 0.0000000))
	{
		HandleProtectorEscortDied();
		Gatherer(m_Pawn).ClearProtectorEscort();
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function HandleProtectorEscortDied()
{
	// End:0x41
	if(__NFUN_119__(CurrentAlertGoal, none))
	{
		CurrentAlertGoal.unPostGoal(self);
		CurrentAlertGoal.__NFUN_198__();
		CurrentAlertGoal = none;
		// End:0x82
		if(__NFUN_119__(CurrentPanicGoal, none))
		{
			CurrentPanicGoal.unPostGoal(self);
		}
		CurrentPanicGoal.__NFUN_198__();
		CurrentPanicGoal = none;
		// End:0xC3
		if(__NFUN_119__(CurrentWaitForProtectorGoal, none))
		{
			CurrentWaitForProtectorGoal.unPostGoal(self);
			CurrentWaitForProtectorGoal.__NFUN_198__();
		}
		CurrentWaitForProtectorGoal = none;
		// End:0x104
		if(__NFUN_119__(CurrentGatherResourceGoal, none))
		{
			CurrentGatherResourceGoal.unPostGoal(self);
			CurrentGatherResourceGoal.__NFUN_198__();
			CurrentGatherResourceGoal = none;
		}
		// End:0x145
		if(__NFUN_119__(CurrentTiredGoal, none))
		{
			CurrentTiredGoal.unPostGoal(self);
			CurrentTiredGoal.__NFUN_198__();
			CurrentTiredGoal = none;
			// End:0x186
			if(__NFUN_119__(CurrentReturnToVentGoal, none))
			{
				CurrentReturnToVentGoal.unPostGoal(self);
			}
			CurrentReturnToVentGoal.__NFUN_198__();
			CurrentReturnToVentGoal = none;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x1C7
			/*@Error*/
			CurrentScoopedUpGoal.unPostGoal(self);
		}
		CurrentScoopedUpGoal.__NFUN_198__();
		CurrentScoopedUpGoal = none;
		DeactivateAlertSensor();
		DeactivateGathererLookAtSensor();
		ShockAI().PlaySpeech('EscortDied');
	}
	BecomeStunned();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function OnSensorMessage(AI_Sensor sensor, AI_SensorData Value, Object userData)
{
	local Actor InterestingObject;
	local ShockPawn AlertedPawn;

	super(AI_Action).OnSensorMessage(sensor, Value, userData);
	log('AI', 5, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " OnSensorMessage from "), string(sensor.Name)), " - value is: "), string(Value.objectData)));
	// End:0x102
	if(__NFUN_114__(sensor, CurrentAlertSensor))
	{
		AlertedPawn = ShockPawn(Value.objectData);
		HandleAlertSensorMessage(AlertedPawn);
		goto J0x155;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x155
		/*@Error*/
		InterestingObject = Actor(Value.objectData);
		HandleLookAtSensorMessage(InterestingObject);
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function HandleAlertSensorMessage(ShockPawn AlertedPawn)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x119
	/*@Error*/
	// End:0x63
	if(__NFUN_114__(AlertedPawn, none))
	{
		// End:0x60
		if(__NFUN_119__(CurrentAlertGoal, none))
		{
			CurrentAlertGoal.FinishUp();
			goto J0x119;
			StopTiredGoal();
			// End:0xAE
			if(__NFUN_119__(CurrentAlertGoal, none))
			{
			}
		}
		CurrentAlertGoal.unPostGoal(self);
		CurrentAlertGoal.__NFUN_198__();
		CurrentAlertGoal = none;
		CurrentAlertGoal = Class'ShockAI.AlertGoal'.static.Allocate(self).;
		construct_AI_ResourceShockPawn(characterResource(), AlertedPawn);
	}
	CurrentAlertGoal.__NFUN_199__();
	CurrentAlertGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function ActivateAlertSensor()
{
	CurrentAlertSensor = AlertSensor(Class'VengeanceShared.AI_Sensor'.static.activateSensor(self, Class'ShockAI.AlertSensor', characterResource(), 0.0000000, 1000000.0000000));
	CurrentAlertSensor.setParameters(ShockAI(), m_Pawn, AlertedDistanceRange, false);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function DeactivateAlertSensor()
{
	// End:0x32
	if(__NFUN_119__(CurrentAlertSensor, none))
	{
		CurrentAlertSensor.deactivateSensor(self);
		CurrentAlertSensor = none;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function HandleLookAtSensorMessage(Actor InterestingObject)
{
	// End:0x160
	if(__NFUN_130__(__NFUN_130__(__NFUN_155__(int(InterestingObject.AILookAtType), int(3)), __NFUN_178__(__NFUN_195__(), LookAtInterestingObjectChance)), __NFUN_177__(__NFUN_175__(Level().TimeSeconds, LastTimeLookedAtInterestingObject), MinTimeBetweenLookingAtInterestingObjects)))
	{
		// End:0xC2
		if(__NFUN_130__(__NFUN_119__(CurrentGathererLookAtTargetGoal, none), CurrentGathererLookAtTargetGoal.wasAchieved()))
		{
			CurrentGathererLookAtTargetGoal.unPostGoal(self);
			CurrentGathererLookAtTargetGoal.__NFUN_198__();
			CurrentGathererLookAtTargetGoal = none;
			// End:0x15D
			if(__NFUN_114__(CurrentGathererLookAtTargetGoal, none))
			{
				LastTimeLookedAtInterestingObject = Level().TimeSeconds;
				CurrentGathererLookAtTargetGoal = Class'ShockAI.GathererLookAtTargetGoal'.static.Allocate(self).;
			}
			construct_AI_ResourceActor(characterResource(), InterestingObject);
			CurrentGathererLookAtTargetGoal.__NFUN_199__();
			CurrentGathererLookAtTargetGoal.postGoal(self);
			goto J0x1D0;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x1D0
			/*@Error*/
			ShockAI().CasualLook(InterestingObject, 2.0000000);
		}
	}
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function ActivateGathererLookAtSensor()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xBC
	/*@Error*/
	CurrentGathererLookAtSensor = GathererLookAtSensor(Class'VengeanceShared.AI_Sensor'.static.activateSensor(self, Class'ShockAI.GathererLookAtSensor', characterResource(), 0.0000000, 1000000.0000000));
	CurrentGathererLookAtSensor.setParameters(Gatherer(m_Pawn));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function DeactivateGathererLookAtSensor()
{
	// End:0x32
	if(__NFUN_119__(CurrentGathererLookAtSensor, none))
	{
		CurrentGathererLookAtSensor.deactivateSensor(self);
		CurrentGathererLookAtSensor = none;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function BecomeUnconscious(Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name HitLowBone, name HitHighBone, optional float HitMomentumImparted, optional DamageStimuliSet DamageStimuli)
{
	local ShockPawn.EDamageEvent DamageEvent;

	// End:0x41
	if(__NFUN_119__(CurrentUnconsciousGoal, none))
	{
		CurrentUnconsciousGoal.unPostGoal(self);
		CurrentUnconsciousGoal.__NFUN_198__();
		CurrentUnconsciousGoal = none;
		DamageEvent = 1;
		CurrentUnconsciousGoal = Class'ShockAI.UnconsciousGoal'.static.Allocate(self).;
	}
	construct_AI_ResourceByteVectorVectorVectorFloatDamageStimuliSetNameName(characterResource(), DamageEvent, HitLocation, HitNormal, HitImpulseDirection, HitMomentumImparted, DamageStimuli, HitLowBone, HitHighBone);
	CurrentUnconsciousGoal.__NFUN_199__();
	CurrentUnconsciousGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyDamaged(Actor Damager)
{
	super(CommanderAction).NotifyDamaged(Damager);
	DeactivateGathererLookAtSensor();
	return;
	@NULL
	CommanderAction
}

function bool ShouldHandleDamageEvents()
{
	return __NFUN_129__(Gatherer(m_Pawn).IsNonPhysical());
	return;
	@NULL
	CommanderAction
}

function bool IsStunned()
{
	return __NFUN_130__(__NFUN_119__(CurrentStunnedGoal, none), __NFUN_132__(__NFUN_129__(CurrentStunnedGoal.wasConsidered()), CurrentStunnedGoal.beingAchieved()));
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function BecomeStunned()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x21C
	/*@Error*/
	DeactivateAlertSensor();
	// End:0x3F
	if(__NFUN_119__(CurrentPanicGoal, none))
	{
		CurrentPanicGoal.FinishUp();
		// End:0xF6
		if(__NFUN_119__(CurrentTiredGoal, none))
		{
			CurrentTiredGoal.unPostGoal(self);
		}
		CurrentTiredGoal.__NFUN_198__();
		CurrentTiredGoal = none;
		// End:0xF6
		if(Class'Engine.Pawn'.static.checkAlive(Gatherer(m_Pawn).GetProtectorEscort()))
		{
			Gatherer(m_Pawn).GetProtectorEscort().GetProtectorCommanderAction().StopReactingToTiredGatherer();
			ShockAI().dispatchMessage(Class'ShockAI.MessageGathererStunned'.static.Allocate(self)., construct_Gatherer(Gatherer(m_Pawn)));
		}
	}
	m_Pawn.TriggerEffectEvent('Stunned');
	CurrentStunnedGoal = Class'ShockAI.StunnedGoal'.static.Allocate(self).;
	construct_AI_Resource(characterResource());
	CurrentStunnedGoal.__NFUN_199__();
	CurrentStunnedGoal.postGoal(self);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x21C
	/*@Error*/
	SpawningManager(Level().SpawningManager).IncrementLootableGatherers();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ForgetAboutGathering()
{
	DeactivateAlertSensor();
	// End:0x4B
	if(__NFUN_119__(CurrentStunnedGoal, none))
	{
		CurrentStunnedGoal.unPostGoal(self);
		CurrentStunnedGoal.__NFUN_198__();
		CurrentStunnedGoal = none;
		// End:0x8C
		if(__NFUN_119__(CurrentGatherResourceGoal, none))
		{
			CurrentGatherResourceGoal.unPostGoal(self);
		}
		CurrentGatherResourceGoal.__NFUN_198__();
		CurrentGatherResourceGoal = none;
		// End:0xCD
		if(__NFUN_119__(CurrentAlertGoal, none))
		{
			CurrentAlertGoal.unPostGoal(self);
			CurrentAlertGoal.__NFUN_198__();
		}
		CurrentAlertGoal = none;
		// End:0x10E
		if(__NFUN_119__(CurrentWaitForProtectorGoal, none))
		{
			CurrentWaitForProtectorGoal.unPostGoal(self);
			CurrentWaitForProtectorGoal.__NFUN_198__();
			CurrentWaitForProtectorGoal = none;
		}
		// End:0x14F
		if(__NFUN_119__(CurrentGathererLookAtTargetGoal, none))
		{
			CurrentGathererLookAtTargetGoal.unPostGoal(self);
			CurrentGathererLookAtTargetGoal.__NFUN_198__();
			CurrentGathererLookAtTargetGoal = none;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x206
			/*@Error*/
			CurrentTiredGoal.unPostGoal(self);
		}
		CurrentTiredGoal.__NFUN_198__();
		CurrentTiredGoal = none;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x206
		/*@Error*/
	}
	Gatherer(m_Pawn).GetProtectorEscort().GetProtectorCommanderAction().StopReactingToTiredGatherer();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x247
	/*@Error*/
	CurrentScoopedUpGoal.unPostGoal(self);
	CurrentScoopedUpGoal.__NFUN_198__();
	CurrentScoopedUpGoal = none;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x26D
	/*@Error*/
	CurrentPanicGoal.FinishUp();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function BecomeSaved()
{
	ShockAI().dispatchMessage(Class'ShockAI.MessageGathererSaved'.static.Allocate(self)., construct_Gatherer(Gatherer(m_Pawn)));
	ForgetAboutGathering();
	Gatherer(m_Pawn).SetIsSaved(true);
	ReturnToVent();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function QuickLook(Actor Target, optional float Duration, optional Vector Offset)
{
	HeadTrackingAction(CurrentHeadTrackingGoal.achievingAction).QuickLook(Target, Duration, Offset);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function CasualLook(Actor Target, optional float Duration, optional Vector Offset)
{
	HeadTrackingAction(CurrentHeadTrackingGoal.achievingAction).CasualLook(Target, Duration, Offset);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function StopTracking()
{
	HeadTrackingAction(CurrentHeadTrackingGoal.achievingAction).StopTracking();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function bool IsTracking()
{
	return HeadTrackingAction(CurrentHeadTrackingGoal.achievingAction).IsTracking();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function NotifyEscortIsAttacking(ShockPawn AttackTarget)
{
	Gatherer(m_Pawn).SetPanicInducer(AttackTarget);
	StopTiredGoal();
	// End:0xA8
	if(__NFUN_119__(CurrentPanicGoal, none))
	{
		// End:0x91
		if(CurrentPanicGoal.hasCompleted())
		{
			CurrentPanicGoal.unPostGoal(self);
			CurrentPanicGoal.__NFUN_198__();
			CurrentPanicGoal = none;
			goto J0xA8;
			CurrentPanicGoal.CancelFinishUp();
			DeactivateAlertSensor();
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x115
			/*@Error*/
		}
		else
		{
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x102
			/*@Error*/
			CurrentAlertGoal.unPostGoal(self);
		}/* !MISMATCHING REMOVE, tried If got Type:Else Position:0x091! */
		CurrentAlertGoal.__NFUN_198__();
		CurrentAlertGoal = none;
		StartPanicBehavior(AttackTarget);
		return;
		@NULL
		CommanderAction
		CommanderAction
		@NULL
	}/* !MISMATCHING REMOVE, tried Else got Type:If Position:0x027! */
}

function StartPanicBehavior(ShockPawn AttackTarget)
{
	assert(__NFUN_114__(CurrentPanicGoal, none));
	CurrentPanicGoal = Class'ShockAI.PanicGoal'.static.Allocate(self).;
	construct_AI_ResourceShockPawn(characterResource(), AttackTarget);
	CurrentPanicGoal.__NFUN_199__();
	CurrentPanicGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyRestartPanicBehavior()
{
	// End:0x35
	if(__NFUN_119__(CurrentPanicGoal, none))
	{
		CurrentPanicGoal.achievingAction.instantFail(1);
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function NotifyEscortStoppedAttacking()
{
	// End:0x26
	if(__NFUN_119__(CurrentPanicGoal, none))
	{
		CurrentPanicGoal.FinishUp();
		Gatherer(m_Pawn).SetPanicInducer(none);
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x77
	/*@Error*/
	ActivateAlertSensor();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyGathererThatProtectorIsTooFarAway()
{
	assert(__NFUN_114__(CurrentWaitForProtectorGoal, none));
	CurrentWaitForProtectorGoal = Class'ShockAI.WaitForProtectorGoal'.static.Allocate(self).;
	construct_AI_Resource(characterResource());
	CurrentWaitForProtectorGoal.__NFUN_199__();
	CurrentWaitForProtectorGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyGathererProtectorCaughtUp()
{
	assert(__NFUN_119__(CurrentWaitForProtectorGoal, none));
	CurrentWaitForProtectorGoal.unPostGoal(self);
	CurrentWaitForProtectorGoal.__NFUN_198__();
	CurrentWaitForProtectorGoal = none;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyProtectorTellingUsToStopLooking()
{
	assert(__NFUN_119__(CurrentGathererLookAtTargetGoal, none));
	CurrentGathererLookAtTargetGoal.NotifyProtectorTellingUsToStopLooking();
	return;
	@NULL
	CommanderAction
}

function NotifyGathererPrepareToBeScoopedUp()
{
	// End:0x41
	if(__NFUN_119__(CurrentScoopedUpGoal, none))
	{
		CurrentScoopedUpGoal.unPostGoal(self);
		CurrentScoopedUpGoal.__NFUN_198__();
		CurrentScoopedUpGoal = none;
		CurrentScoopedUpGoal = Class'ShockAI.ScoopedUpGoal'.static.Allocate(self).;
	}
	construct_AI_Resource(characterResource());
	CurrentScoopedUpGoal.__NFUN_199__();
	CurrentScoopedUpGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyStartScoopUp()
{
	assert(__NFUN_119__(CurrentScoopedUpGoal, none));
	CurrentScoopedUpGoal.NotifyStartScoopUp();
	return;
	@NULL
	CommanderAction
}

function NotifyCancelScoop()
{
	// End:0x41
	if(__NFUN_119__(CurrentScoopedUpGoal, none))
	{
		CurrentScoopedUpGoal.unPostGoal(self);
		CurrentScoopedUpGoal.__NFUN_198__();
		CurrentScoopedUpGoal = none;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function BecomeTired()
{
	assert(__NFUN_114__(CurrentTiredGoal, none));
	CurrentTiredGoal = Class'ShockAI.TiredGoal'.static.Allocate(self).;
	construct_AI_Resource(characterResource());
	CurrentTiredGoal.__NFUN_199__();
	CurrentTiredGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function StopTiredGoal()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xB7
	/*@Error*/
	CurrentTiredGoal.unPostGoal(self);
	CurrentTiredGoal.__NFUN_198__();
	CurrentTiredGoal = none;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB7
	/*@Error*/
	Gatherer(m_Pawn).GetProtectorEscort().GetProtectorCommanderAction().StopReactingToTiredGatherer();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyProtectorSaysComeOn()
{
	assert(__NFUN_119__(CurrentTiredGoal, none));
	CurrentTiredGoal.NotifyProtectorSaysComeOn();
	return;
	@NULL
	CommanderAction
}

function NotifyProtectorStartingTiredAnimation(bool bUseUnevenSurfaceAnimation)
{
	assert(__NFUN_119__(CurrentTiredGoal, none));
	CurrentTiredGoal.NotifyProtectorStartingTiredAnimation(bUseUnevenSurfaceAnimation);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function NotifyPlayPickedUpAnimation()
{
	assert(__NFUN_119__(CurrentPanicGoal, none));
	CurrentPanicGoal.NotifyPlayPickedUpAnimation();
	return;
	@NULL
	CommanderAction
}

function NotifyLoseProtectorEscort()
{
	ForgetAboutGathering();
	Gatherer(m_Pawn).ClearProtectorEscort();
	return;
	@NULL
	CommanderAction
}

function bool PEGShouldWait()
{
	local PlayerEscortedGatherer Gatherer;

	Gatherer = PlayerEscortedGatherer(m_Pawn);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xCF
	/*@Error*/
	bFellBehind = AmReducingDistanceToEscort();
	return __NFUN_129__(bFellBehind);
	goto J0xD1;
	return false;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool PEGShouldStopWaiting()
{
	local PlayerEscortedGatherer Gatherer;

	Gatherer = PlayerEscortedGatherer(m_Pawn);
	return __NFUN_130__(__NFUN_130__(__NFUN_119__(Gatherer, none), __NFUN_129__(Gatherer.bDontWaitForPlayer)), __NFUN_176__(VSizeSquared(__NFUN_216__(m_Pawn.Location, Gatherer.GetPlayerEscort().Location)), __NFUN_171__(__NFUN_171__(__NFUN_171__(0.8000000, 0.8000000), DistanceForPEGToWait), DistanceForPEGToWait)));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function SetDistanceForPEGToWait(float NewDistance)
{
	DistanceForPEGToWait = NewDistance;
	return;
	@NULL
	CommanderAction
}

function bool AmReducingDistanceToEscort()
{
	local ShockPawn Escort;

	Escort = Gatherer(m_Pawn).GetShockPawnEscort();
	return __NFUN_130__(__NFUN_129__(IsNearlyZero(m_Pawn.RootMotionVelocity)), __NFUN_176__(VSizeSquared2D(__NFUN_216__(Escort.Location, m_Pawn.Location)), VSizeSquared2D(__NFUN_216__(Escort.Location, OldLocation))));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ExitFromVent()
{
	assert(__NFUN_114__(CurrentExitVentGoal, none));
	CurrentExitVentGoal = Class'ShockAI.ExitVentGoal'.static.Allocate(self).;
	construct_AI_Resource(characterResource());
	CurrentExitVentGoal.__NFUN_199__();
	CurrentExitVentGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentExitVentGoal);
	CurrentExitVentGoal.unPostGoal(self);
	CurrentExitVentGoal.__NFUN_198__();
	CurrentExitVentGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function GatherResource()
{
	CurrentGatherResourceGoal = Class'ShockAI.GatherResourceGoal'.static.Allocate(self).;
	construct_AI_Resource(characterResource());
	CurrentGatherResourceGoal.__NFUN_199__();
	CurrentGatherResourceGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentGatherResourceGoal);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB6
	/*@Error*/
	CurrentGatherResourceGoal.unPostGoal(self);
	CurrentGatherResourceGoal.__NFUN_198__();
	CurrentGatherResourceGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function ReturnToVent()
{
	// End:0x41
	if(__NFUN_119__(CurrentReturnToVentGoal, none))
	{
		CurrentReturnToVentGoal.unPostGoal(self);
		CurrentReturnToVentGoal.__NFUN_198__();
		CurrentReturnToVentGoal = none;
		// End:0x96
		if(Class'Engine.Pawn'.static.checkAlive(Gatherer(m_Pawn).GetProtectorEscort()))
		{
		}
		ShockAI().SetShouldWalk();
		goto J0xAE;
		ShockAI().SetShouldRun();
		CurrentReturnToVentGoal = Class'ShockAI.ReturnToVentGoal'.static.Allocate(self).;
	}
	construct_AI_ResourceBoolBool(characterResource(), Class'Engine.Pawn'.static.checkAlive(Gatherer(m_Pawn).GetProtectorEscort()), true);
	CurrentReturnToVentGoal.__NFUN_199__();
	CurrentReturnToVentGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	PlayerEscortedGatherer = PlayerEscortedGatherer(m_Pawn);
	// End:0x4B
	if(__NFUN_129__(Gatherer(m_Pawn).ShouldSkipExit()))
	{
		ExitFromVent();
		// End:0xBB
		if(__NFUN_114__(CurrentHeadTrackingGoal, none))
		{
			CurrentHeadTrackingGoal = HeadTrackingGoal(Class'ShockAI.HeadTrackingGoal'.static.Allocate(self)..@NULL.none);
		}
		@NULL
		Aggressor				
		EcologyFighterCommanderAction
		postGoal(self);
		// End:0x400
		case myAddRef():
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x3D4
			/*@Error*/
			// End:0x3D1
			if(true)
			{
				// End:0x1B7
				if(__NFUN_130__(__NFUN_119__(PlayerEscortedGatherer.GetPlayerEscort(), none), __NFUN_114__(PlayerEscortedGatherer.GetPlayerEscort().EscortedGatherer, none)))
				{
				}
				PlayerEscortedGatherer.GetPlayerEscort().EscortedGatherer = PlayerEscortedGatherer;
				log('AI', 2, __NFUN_168__(__NFUN_168__("WARNING: Player is escorting", string(PlayerEscortedGatherer.Name)), "yet has unset 'EscortedGatherer' field"));
				// End:0x293
				if(__NFUN_130__(__NFUN_130__(__NFUN_119__(CurrentPanicGoal, none), __NFUN_114__(CurrentAlertSensor, none)), __NFUN_132__(__NFUN_132__(__NFUN_177__(m_Pawn.Level.TimeSeconds, PlayerEscortedGatherer.PanicEndTime), Class'Engine.Pawn'.static.checkDead(GetPanicInducer())), __NFUN_177__(VSizeSquared(__NFUN_216__(GetPanicInducer().Location, m_Pawn.Location)), __NFUN_171__(2000.0000000, 2000.0000000)))))
				{
				}
				NotifyEscortStoppedAttacking();
				// End:0x2DA
				if(__NFUN_130__(__NFUN_130__(__NFUN_119__(PlayerEscortedGatherer.GetPlayerEscort(), none), __NFUN_114__(CurrentWaitForProtectorGoal, none)), PEGShouldWait()))
				{
					NotifyGathererThatProtectorIsTooFarAway();
					// End:0x321
					if(__NFUN_130__(__NFUN_130__(__NFUN_119__(PlayerEscortedGatherer.GetPlayerEscort(), none), __NFUN_119__(CurrentWaitForProtectorGoal, none)), PEGShouldStopWaiting()))
					{
					}
					NotifyGathererProtectorCaughtUp();
					// End:0x3A6
					if(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_129__(PlayerEscortedGatherer.bDontWaitForPlayer), PlayerEscortedGatherer.bIsARealPEG), bFellBehind), __NFUN_129__(IsNearlyZero(m_Pawn.RootMotionVelocity))))
					{
					}
					PlayerEscortedGatherer.SetShouldRun();
					OldLocation = m_Pawn.Location;
					__NFUN_256__(1.0000000);
					// [Loop Continue]
					goto J0xCA;
					goto J0x462;
				}
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x458
				/*@Error*/
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x44E
				/*@Error*/
				ActivateAlertSensor();
				GatherResource();
				ReturnToVent();
				stop;				
			}
			@NULL
			@NULL
			@NULL
			@NULL
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			/*@Error*/
			// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.get_CurrentToken() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 40
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 845
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
			// 2 & Type:If Position:0x3D1
		}/* !MISMATCHING REMOVE, tried If got Type:Case Position:0x094! *//* !MISMATCHING REMOVE, tried Case got Type:If Position:0x010! */
}

defaultproperties
{
	LookAtInterestingObjectChance=0.7500000
	MinTimeBetweenLookingAtInterestingObjects=60.0000000
	AlertedDistanceRange=(Min=300.0000000,Max=750.0000000)
	DistanceForPEGToWait=1750.0000000
}