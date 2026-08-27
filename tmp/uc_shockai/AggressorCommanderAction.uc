class AggressorCommanderAction extends EcologyFighterCommanderAction
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private PatrolGoal CurrentPatrolGoal;
var private MimicGoal CurrentMimicGoal;
var private HealAtHealthStationGoal CurrentHealAtHealthStationGoal;
var private ReactToAlertGathererGoal CurrentReactToAlertGathererGoal;
var private HeadTrackingGoal CurrentHeadTrackingGoal;
var private FleeGoal CurrentFleeGoal;
var private config float MinDistanceToFleeFromHitSpang;
var private config float MinDistanceToFleeFromWeaponFire;

function Cleanup()
{
	super.Cleanup();
	// End:0x33
	if(__NFUN_119__(CurrentPatrolGoal, none))
	{
		CurrentPatrolGoal.__NFUN_198__();
		CurrentPatrolGoal = none;
		// End:0x5C
		if(__NFUN_119__(CurrentMimicGoal, none))
		{
			CurrentMimicGoal.__NFUN_198__();
		}
		CurrentMimicGoal = none;
		// End:0x85
		if(__NFUN_119__(CurrentHealAtHealthStationGoal, none))
		{
			CurrentHealAtHealthStationGoal.__NFUN_198__();
			CurrentHealAtHealthStationGoal = none;
		}
		// End:0xAE
		if(__NFUN_119__(CurrentReactToAlertGathererGoal, none))
		{
			CurrentReactToAlertGathererGoal.__NFUN_198__();
			CurrentReactToAlertGathererGoal = none;
			// End:0xD7
			if(__NFUN_119__(CurrentHeadTrackingGoal, none))
			{
			}
			CurrentHeadTrackingGoal.__NFUN_198__();
			CurrentHeadTrackingGoal = none;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x100
			/*@Error*/
			CurrentFleeGoal.__NFUN_198__();
			CurrentFleeGoal = none;
		}
		ShockAI().StopSpeech('Idling');
		return;
	}
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function SearchForTarget(ShockPawn Target, Vector LastKnownLocation, Vector LastMovingDirection, Vector LocationWhenLostTarget)
{
	// End:0x41
	if(__NFUN_119__(CurrentSearchGoal, none))
	{
		CurrentSearchGoal.unPostGoal(self);
		CurrentSearchGoal.__NFUN_198__();
		CurrentSearchGoal = none;
		CurrentSearchGoal = Class'ShockAI.SearchGoal'.static.Allocate(self).;
	}
	construct_AI_ResourceShockPawnVectorVectorVector(characterResource(), Target, LastKnownLocation, LastMovingDirection, LocationWhenLostTarget);
	CurrentSearchGoal.__NFUN_199__();
	CurrentSearchGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function HandleSuspiciousEvent(Vector SuspiciousLocation, Vector SuspiciousDirection, optional name SoundCategory)
{
	// End:0x59
	if(__NFUN_130__(__NFUN_119__(CurrentSearchGoal, none), __NFUN_129__(CurrentSearchGoal.hasCompleted())))
	{
		CurrentSearchGoal.UpdateSuspiciousLocation(SuspiciousLocation, SuspiciousDirection);
		goto J0xD8;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xD8
		/*@Error*/
	}
	// End:0xB3
	if(ShouldFlee(SuspiciousLocation, SoundCategory))
	{
		Flee(SuspiciousLocation);
		goto J0xD8;
		Investigate(SuspiciousLocation, SuspiciousDirection, SoundCategory);
		return;
		@NULL
		CommanderAction
		BioshockMovementAction
	}
	@NULL
}

function bool ShouldFlee(Vector SuspiciousLocation, name SoundCategory)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x1D1
	/*@Error*/
	return true;
	goto J0x1D3;
	return false;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function Flee(Vector SuspiciousLocation)
{
	// End:0x41
	if(__NFUN_119__(CurrentInvestigateGoal, none))
	{
		CurrentInvestigateGoal.unPostGoal(self);
		CurrentInvestigateGoal.__NFUN_198__();
		CurrentInvestigateGoal = none;
		// End:0xC2
		if(__NFUN_130__(__NFUN_119__(CurrentFleeGoal, none), __NFUN_150__(CurrentFleeGoal.Priority, CurrentFleeGoal.Class.default.Priority)))
		{
		}
		CurrentFleeGoal.unPostGoal(self);
		CurrentFleeGoal.__NFUN_198__();
		CurrentFleeGoal = none;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x13C
		/*@Error*/
		CurrentFleeGoal = Class'ShockAI.FleeGoal'.static.Allocate(self).;
		construct_AI_ResourceVector(characterResource(), SuspiciousLocation);
	}
	CurrentFleeGoal.__NFUN_199__();
	CurrentFleeGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function goalAchievedCB(AI_Goal Goal, AI_Action Child)
{
	super.goalAchievedCB(Goal, Child);
	assert(__NFUN_119__(Goal, none));
	// End:0x77
	if(__NFUN_114__(Goal, CurrentHealAtHealthStationGoal))
	{
		CurrentHealAtHealthStationGoal.unPostGoal(self);
		CurrentHealAtHealthStationGoal.__NFUN_198__();
		CurrentHealAtHealthStationGoal = none;
		goto J0x10C;
		// End:0xC3
		if(__NFUN_114__(Goal, CurrentReactToAlertGathererGoal))
		{
			CurrentReactToAlertGathererGoal.unPostGoal(self);
			CurrentReactToAlertGathererGoal.__NFUN_198__();
		}
		CurrentReactToAlertGathererGoal = none;
		goto J0x10C;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x10C
		/*@Error*/
		CurrentFleeGoal.unPostGoal(self);
		CurrentFleeGoal.__NFUN_198__();
		CurrentFleeGoal = none;
		HandleFinishedGoal();
	}
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
	// End:0x80
	if(__NFUN_114__(Goal, CurrentHealAtHealthStationGoal))
	{
		CurrentHealAtHealthStationGoal.unPostGoal(self);
		CurrentHealAtHealthStationGoal.__NFUN_198__();
		CurrentHealAtHealthStationGoal = none;
		goto J0x11F;
		// End:0xD6
		if(__NFUN_114__(Goal, CurrentReactToAlertGathererGoal))
		{
			CurrentReactToAlertGathererGoal.unPostGoal(self);
			CurrentReactToAlertGathererGoal.__NFUN_198__();
		}
		CurrentReactToAlertGathererGoal = none;
		UpdateAttackTargets();
		goto J0x11F;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x11F
		/*@Error*/
		CurrentFleeGoal.unPostGoal(self);
		CurrentFleeGoal.__NFUN_198__();
		CurrentFleeGoal = none;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
	@NULL
}

function HandleFinishedGoal()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x9B
	/*@Error*/
	ResetToIdle();
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function NotifyCausedGathererAlert(Gatherer AlertGatherer, Protector ThreateningProtector)
{
	// End:0x5D
	if(__NFUN_130__(__NFUN_119__(CurrentReactToAlertGathererGoal, none), CurrentReactToAlertGathererGoal.hasCompleted()))
	{
		CurrentReactToAlertGathererGoal.unPostGoal(self);
		CurrentReactToAlertGathererGoal.__NFUN_198__();
		CurrentReactToAlertGathererGoal = none;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xE3
		/*@Error*/
		CurrentReactToAlertGathererGoal = Class'ShockAI.ReactToAlertGathererGoal'.static.Allocate(self).;
	}
	construct_AI_ResourceGathererProtector(characterResource(), AlertGatherer, ThreateningProtector);
	CurrentReactToAlertGathererGoal.__NFUN_199__();
	CurrentReactToAlertGathererGoal.postGoal(self);
	goto J0x10C;
	CurrentReactToAlertGathererGoal.NotifyCausedGathererAlert(AlertGatherer, ThreateningProtector);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyGathererAlertOver(Gatherer FormerAlertGatherer, Protector FormerThreateningProtector)
{
	// End:0x38
	if(__NFUN_119__(CurrentReactToAlertGathererGoal, none))
	{
		CurrentReactToAlertGathererGoal.NotifyGathererAlertOver(FormerAlertGatherer, FormerThreateningProtector);
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function NotifyProtectorThreatening(Protector ThreateningProtector)
{
	// End:0x2F
	if(__NFUN_119__(CurrentReactToAlertGathererGoal, none))
	{
		CurrentReactToAlertGathererGoal.NotifyProtectorThreatening(ThreateningProtector);
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function NotifyKnockedBackByThreateningProtector(Protector ThreateningProtector)
{
	// End:0x2F
	if(__NFUN_119__(CurrentReactToAlertGathererGoal, none))
	{
		CurrentReactToAlertGathererGoal.NotifyKnockedBackByThreateningProtector(ThreateningProtector);
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function bool ShouldHandleDamageEvents()
{
	return __NFUN_129__(Aggressor(m_Pawn).IsMimic());
	return;
	@NULL
	CommanderAction
}

function bool IsRunningHealAtHealthStationBehavior()
{
	return __NFUN_130__(__NFUN_130__(__NFUN_119__(CurrentHealAtHealthStationGoal, none), __NFUN_129__(CurrentHealAtHealthStationGoal.hasCompleted())), __NFUN_129__(CurrentHealAtHealthStationGoal.hasExpired()));
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function HealAtHealthStation()
{
	// End:0x79
	if(__NFUN_130__(__NFUN_119__(CurrentHealAtHealthStationGoal, none), __NFUN_132__(CurrentHealAtHealthStationGoal.hasCompleted(), CurrentHealAtHealthStationGoal.hasExpired())))
	{
		CurrentHealAtHealthStationGoal.unPostGoal(self);
		CurrentHealAtHealthStationGoal.__NFUN_198__();
		CurrentHealAtHealthStationGoal = none;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x10F
		/*@Error*/
		CurrentHealAtHealthStationGoal = Class'ShockAI.HealAtHealthStationGoal'.static.Allocate(self).;
	}
	construct_AI_ResourceShockPawn(characterResource(), CurrentAttackTarget);
	CurrentHealAtHealthStationGoal.__NFUN_199__();
	CurrentHealAtHealthStationGoal.setExpirationTime(0.0000000);
	CurrentHealAtHealthStationGoal.postGoal(self);
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

function bool IsSuspectingAttackFrom(ShockPawn Target)
{
	return __NFUN_132__(__NFUN_114__(CurrentAttackTarget, Target), __NFUN_130__(__NFUN_119__(CurrentSearchGoal, none), __NFUN_114__(CurrentSearchGoal.GetSearchTarget(), Target)));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnPatrolChanged()
{
	// End:0x41
	if(__NFUN_119__(CurrentMimicGoal, none))
	{
		CurrentMimicGoal.unPostGoal(self);
		CurrentMimicGoal.__NFUN_198__();
		CurrentMimicGoal = none;
		// End:0x82
		if(__NFUN_119__(CurrentMoveToSpawnPointGoal, none))
		{
			CurrentMoveToSpawnPointGoal.unPostGoal(self);
		}
		CurrentMoveToSpawnPointGoal.__NFUN_198__();
		CurrentMoveToSpawnPointGoal = none;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xC3
		/*@Error*/
		CurrentPatrolGoal.unPostGoal(self);
		CurrentPatrolGoal.__NFUN_198__();
	}
	CurrentPatrolGoal = none;
	Patrol();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function PatrolList GetPatrol()
{
	return Aggressor(m_Pawn).GetPatrol();
	return;
	@NULL
	CommanderAction
}

private function bool HasPatrol()
{
	return __NFUN_119__(GetPatrol(), none);
	return;
}

function Patrol()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x8A
	/*@Error*/
	CurrentPatrolGoal = Class'ShockAI.PatrolGoal'.static.Allocate(self).;
	construct_AI_ResourcePatrolList(characterResource(), GetPatrol());
	assert(__NFUN_119__(CurrentPatrolGoal, none));
	CurrentPatrolGoal.__NFUN_199__();
	CurrentPatrolGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function ResetToIdle()
{
	// End:0x46
	if(__NFUN_129__(Aggressor(m_Pawn).ShouldStartOutAsMimic()))
	{
		ShockAI().PlaySpeech('Idling');
		ShockAI().SetInitialAIState();
	}
	return;
	@NULL
	CommanderAction
}

function BecomeMimic()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x71
	/*@Error*/
	CurrentMimicGoal = Class'ShockAI.MimicGoal'.static.Allocate(self).;
	construct_AI_Resource(characterResource());
	CurrentMimicGoal.__NFUN_199__();
	CurrentMimicGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	// End:0x70
	if(__NFUN_114__(CurrentHeadTrackingGoal, none))
	{
		CurrentHeadTrackingGoal = HeadTrackingGoal(Class'ShockAI.HeadTrackingGoal'.static.Allocate(self)..@NULL.none);
		@NULL
		Aggressor				
		EcologyFighterCommanderAction
		postGoal(self);
		// End:0x400
		case myAddRef():
			// End:0xA0
			if(Aggressor(m_Pawn).ShouldStartOutAsMimic())
			{
			}
			BecomeMimic();
			goto J0xF1;
			m_Pawn.TriggerEffectEvent('AggressorAlive');
		}/* !MISMATCHING REMOVE, tried If got Type:Case Position:0x05D! */
		// End:0xDA
		if(HasPatrol())
		{
			Patrol();
			goto J0xF1;
			// End:0xF1
			if(HasSpawnPoint())
			{
				MoveToSpawnPoint();
			}
			ResetToIdle();
			stop;												
		}
		@NULL
		@NULL
		@NULL
		@NULL/* !MISMATCHING REMOVE, tried Case got Type:If Position:0x000! */
}

defaultproperties
{
	MinDistanceToFleeFromHitSpang=500.0000000
	MinDistanceToFleeFromWeaponFire=1000.0000000
	RecentlySeenTime=20.0000000
}