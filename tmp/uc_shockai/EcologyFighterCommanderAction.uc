class EcologyFighterCommanderAction extends EcologyCommanderAction
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

const kMaxNoisesToRemember = 10;

struct native atomic RecentlyHeardNoise
{
	structcpptext
	{

		FRecentlyHeardNoise(AActor* inSoundMaker, const FVector inSoundOrigin, const FVector inSoundDirection, const FVector inSuspiciousDirection, const FName inSoundCategory, const FLOAT inCurrentTime)
			: SoundMaker(inSoundMaker), 
			  SoundOrigin(inSoundOrigin), 
			  SoundDirection(inSoundDirection), 
			  SuspiciousDirection(inSuspiciousDirection), 
			  SoundCategory(inSoundCategory),
			  TimeHeard(inCurrentTime)
		{
		}
	
	}

	var Actor SoundMaker;
	var Vector SoundOrigin;
	var Vector SoundDirection;
	var Vector SuspiciousDirection;
	var name SoundCategory;
	var float TimeHeard;
};

var private AttackTargetGoal CurrentAttackTargetGoal;
var private MoveToSpawnPointGoal CurrentMoveToSpawnPointGoal;
var private InvestigateGoal CurrentInvestigateGoal;
var private SearchGoal CurrentSearchGoal;
var private VisionSensor VisionSensor;
var private ShockPawn CurrentAttackTarget;
var array<ShockPawn> VisiblePawns;
var array<RecentlyHeardNoise> RecentlyHeardNoises;
var config float RecentlySeenTime;
var config float MinTimeToIgnoreOtherSounds;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(CommanderAction).initAction(R, Goal);
	InitVisionSensor();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function Cleanup()
{
	local ShockPawn PlayerPawn;

	super.Cleanup();
	// End:0x33
	if(__NFUN_119__(CurrentAttackTargetGoal, none))
	{
		CurrentAttackTargetGoal.__NFUN_198__();
		CurrentAttackTargetGoal = none;
		// End:0x5C
		if(__NFUN_119__(CurrentMoveToSpawnPointGoal, none))
		{
			CurrentMoveToSpawnPointGoal.__NFUN_198__();
		}
		CurrentMoveToSpawnPointGoal = none;
		// End:0x85
		if(__NFUN_119__(CurrentInvestigateGoal, none))
		{
			CurrentInvestigateGoal.__NFUN_198__();
			CurrentInvestigateGoal = none;
		}
		// End:0xAE
		if(__NFUN_119__(CurrentSearchGoal, none))
		{
			CurrentSearchGoal.__NFUN_198__();
			CurrentSearchGoal = none;
			// End:0xE0
			if(__NFUN_119__(VisionSensor, none))
			{
			}
			VisionSensor.deactivateSensor(self);
			VisionSensor = none;
			PlayerPawn = ShockPawn(Level().GetLocalPlayerController().Pawn);
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x141
		/*@Error*/
		RemoveVisiblePawn(PlayerPawn);
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ScriptedAttackTarget(ShockPawn Target)
{
	EcologyFighter(m_Pawn).AddForcedEnemy(Target);
	SetAttackTarget(Target);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyDamaged(Actor Damager)
{
	local ShockPawn Target;

	super(CommanderAction).NotifyDamaged(Damager);
	Target = ShockPawn(Damager);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xE9
	/*@Error*/
	// End:0xA1
	if(__NFUN_130__(__NFUN_119__(CurrentAttackTargetGoal, none), __NFUN_114__(CurrentAttackTargetGoal.Target, Target)))
	{
		CurrentAttackTargetGoal.OnDamagedByTarget();
		goto J0xE9;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xE9
		/*@Error*/
		SetAttackTarget(Target);
	}
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function OnDealtDamage(Actor Damagee)
{
	super(CommanderAction).OnDealtDamage(Damagee);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5F
	/*@Error*/
	CurrentAttackTargetGoal.OnDamagedTarget();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function InitVisionSensor()
{
	VisionSensor = VisionSensor(Class'VengeanceShared.AI_Sensor'.static.activateSensor(self, Class'ShockAI.VisionSensor', characterResource(), 0.0000000, 1000000.0000000));
	VisionSensor.setParameters(ShockAI());
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function OnSensorMessage(AI_Sensor sensor, AI_SensorData Value, Object userData)
{
	local ShockPawn VisionSensorTarget;
	local VisionSensor.EVisionNotificationStatus VisionNotificationStatus;
	local Vector LastKnownLocation, LastMovingDirection, LocationWhenLostTarget;

	super(AI_Action).OnSensorMessage(sensor, Value, userData);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1D9
	/*@Error*/
	VisionSensorTarget = ShockPawn(Value.objectData);
	assert(__NFUN_119__(VisionSensorTarget, none));
	VisionNotificationStatus = byte(Value.integerData);
	assert(__NFUN_155__(int(VisionNotificationStatus), int(0)));
	// End:0xD4
	if(__NFUN_154__(int(VisionNotificationStatus), int(1)))
	{
		OnSawPawn(VisionSensorTarget);
		goto J0x1D9;
		// End:0xFE
		if(__NFUN_154__(int(VisionNotificationStatus), int(3)))
		{
			OnSuspiciousTargetViewed(VisionSensorTarget);
			goto J0x1D9;
			assert(__NFUN_154__(int(VisionNotificationStatus), int(2)));
			LastKnownLocation = VisionSensor(sensor).GetLastKnownLocationFor(VisionSensorTarget);
		}
		LastMovingDirection = VisionSensor(sensor).GetLastMovingDirectionFor(VisionSensorTarget);
	}
	LocationWhenLostTarget = VisionSensor(sensor).GetLocationWhenLost(VisionSensorTarget);
	OnLostPawn(VisionSensorTarget, LastKnownLocation, LastMovingDirection, LocationWhenLostTarget);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnSawPawn(ShockPawn Seen)
{
	log('AI', 3, __NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " Saw "), string(Seen.Name)));
	AddVisiblePawn(Seen);
	// End:0xCB
	if(Seen.__NFUN_303__('ShockPlayer'))
	{
		ShockAI().dispatchMessage(Class'ShockAI.MessageAIRecognizedPlayer'.static.Allocate(self)., construct_EcologyFighter(EcologyFighter(m_Pawn)));
		// End:0x120
		if(EcologyFighter(m_Pawn).IsTargetToAttackOnSight(Seen))
		{
			EcologyFighter(m_Pawn).AddForcedEnemy(Seen);
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x15D
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x15D
		/*@Error*/
		CurrentAttackTargetGoal.CancelFinishUp();
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function OnLostPawn(ShockPawn Lost, Vector LastKnownLocation, Vector LastMovingDirection, Vector LocationWhenLostTarget)
{
	log('AI', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " Lost "), string(Lost.Name)), " CurrentAttackTarget: "), string(CurrentAttackTarget)));
	RemoveVisiblePawn(Lost);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xCD
	/*@Error*/
	CheckShouldTauntDeadPlayer();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xCD
	/*@Error*/
	CurrentAttackTargetGoal.FinishUp();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function AddVisiblePawn(ShockPawn Target)
{
	assert(__NFUN_129__(IsVisiblePawn(Target)));
	VisiblePawns[VisiblePawns.Length] = Target;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x80
	/*@Error*/
	SpawningManager(Level().SpawningManager).AddEcologyFighterThatCanSeePlayer();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function RemoveVisiblePawn(ShockPawn Target)
{
	local int i;

	assert(IsVisiblePawn(Target));
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xC9
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xBB
	/*@Error*/
	VisiblePawns.Remove(i, 1);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB8
	/*@Error*/
	SpawningManager(Level().SpawningManager).RemoveEcologyFighterThatCanSeePlayer();
	goto J0xC9;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x21;
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function bool IsVisiblePawn(ShockPawn Test)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x54
	/*@Error*/
	// End:0x46
	if(__NFUN_114__(Test, VisiblePawns[i]))
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
	BioshockMovementAction
	@NULL
}

function GetCurrentlyVisiblePawns(out array<ShockPawn> CurrentlyVisiblePawns)
{
	CurrentlyVisiblePawns = VisiblePawns;
	return;
	@NULL
	CommanderAction
}

function Vector GetLastKnownLocationFor(ShockPawn Target)
{
	return VisionSensor.GetLastKnownLocationFor(Target);
	return;
	@NULL
	CommanderAction
}

function OnSuspiciousTargetViewed(ShockPawn SuspiciousTarget)
{
	log('AI', 3, __NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " became suspicious by viewing "), string(SuspiciousTarget.Name)));
	HandleSuspiciousEvent(SuspiciousTarget.Location, SuspiciousTarget.GetVelocity());
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnHeardNoise(Actor SoundMaker, Vector SoundOrigin, Vector SoundDirection, name SoundCategory)
{
	local Vector SuspiciousDirection;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x192
	/*@Error*/
	// End:0xAF
	if(__NFUN_254__(SoundCategory, 'FootStep'))
	{
		__NFUN_184__(SoundOrigin.Z, SoundMaker.CollisionHeight);
		// End:0xAF
		if(SoundMaker.__NFUN_303__('ShockPawn'))
		{
			__NFUN_184__(SoundOrigin.Z, ShockPawn(SoundMaker).BaseEyeHeight);
			// End:0xDE
			if(__NFUN_254__(SoundCategory, 'WeaponFire'))
			{
				SuspiciousDirection = __NFUN_211__(SoundDirection);
				goto J0x136;
				// End:0x10B
				if(__NFUN_254__(SoundCategory, 'HitSpang'))
				{
					SuspiciousDirection = SoundDirection;
				}
			}
			goto J0x136;
			SuspiciousDirection = __NFUN_216__(SoundOrigin, m_Pawn.Location);
			RememberSuspiciousNoise(SoundMaker, SoundOrigin, SoundDirection, SuspiciousDirection, SoundCategory);
		}
		HandleSuspiciousEvent(SoundOrigin, SuspiciousDirection, SoundCategory);
	}
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function RememberSuspiciousNoise(Actor SoundMaker, Vector SoundOrigin, Vector SoundDirection, Vector SuspiciousDirection, name SoundCategory)
{
	//native.SoundMaker;
	//native.SoundOrigin;
	//native.SoundDirection;
	//native.SuspiciousDirection;
	//native.SoundCategory;	
	@NULL
	@NULL
	return return @NULL;
}

function bool HasHeardSoundCategoryRecentlyFrom(Actor Target, name SoundCategory, float RecentTime)
{
	//native.Target;
	//native.SoundCategory;
	//native.RecentTime;	
	@NULL
	@NULL
	return default.@NULL;
}

protected function HandleSuspiciousEvent(Vector SuspiciousLocation, Vector SuspiciousDirection, optional name SoundCategory)
{
	return;
}

function Investigate(Vector InvestigateLocation, Vector InvestigateDirection, optional name SoundCategory)
{
	// End:0x5D
	if(__NFUN_130__(__NFUN_119__(CurrentInvestigateGoal, none), CurrentInvestigateGoal.hasCompleted()))
	{
		CurrentInvestigateGoal.unPostGoal(self);
		CurrentInvestigateGoal.__NFUN_198__();
		CurrentInvestigateGoal = none;
		// End:0x10D
		if(__NFUN_114__(CurrentInvestigateGoal, none))
		{
			ShockAI().StopSpeech('Idling');
		}
		CurrentInvestigateGoal = Class'ShockAI.InvestigateGoal'.static.Allocate(self).;
		construct_AI_ResourceVectorVectorName(characterResource(), InvestigateLocation, InvestigateDirection, SoundCategory);
		CurrentInvestigateGoal.__NFUN_199__();
		CurrentInvestigateGoal.postGoal(self);
		goto J0x183;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x183
		/*@Error*/
	}
	CurrentInvestigateGoal.UpdateInvestigationLocation(InvestigateLocation, InvestigateDirection, SoundCategory);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool ShouldUpdateInvestigateLocation(name CurrentSoundCategory, name LastSoundCategory, float LastInvestigateTime)
{
	// End:0x1C
	if(__NFUN_254__(LastSoundCategory, 'None'))
	{
		return true;
		goto J0xC9;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xC9
		/*@Error*/
	}
	// End:0x94
	if(__NFUN_254__(LastSoundCategory, 'WeaponFire'))
	{
		return __NFUN_254__(CurrentSoundCategory, 'FootStep');
		goto J0xC9;
		// End:0xB0
		if(__NFUN_254__(LastSoundCategory, 'FootStep'))
		{
			return false;
			goto J0xC9;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0xC9
			/*@Error*/
		}
		return true;
		return true;
		return;
		@NULL
		CommanderAction
		EcologyFighterCommanderAction
	}
	@NULL
}

function SearchForTarget(ShockPawn Target, Vector LastKnownLocation, Vector LastMovingDirection, Vector LocationWhenLostTarget)
{
	return;
}

function bool CanReactToAttack()
{
	local CharacterAttackAction AttackAction;

	// End:0x14
	if(__NFUN_114__(CurrentAttackTargetGoal, none))
	{
		return true;
		goto J0xBE;
		AttackAction = CharacterAttackAction(CurrentAttackTargetGoal.achievingAction);
	}
	return __NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_119__(AttackAction, none), __NFUN_129__(AttackAction.IsDodging())), __NFUN_129__(AttackAction.IsAttackingTarget())), __NFUN_129__(IsReactingToDamage())), __NFUN_129__(Aggressor(m_Pawn).IsMimic()));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function goalAchievedCB(AI_Goal Goal, AI_Action Child)
{
	super.goalAchievedCB(Goal, Child);
	assert(__NFUN_119__(Goal, none));
	// End:0x58
	if(__NFUN_114__(Goal, CurrentAttackTargetGoal))
	{
		HandleFinishedAttackTargetGoal(Goal);
		goto J0xAF;
		// End:0x85
		if(__NFUN_114__(Goal, CurrentInvestigateGoal))
		{
			HandleFinishedInvestigateGoal(Goal);
		}
		goto J0xAF;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xAF
		/*@Error*/
		HandleFinishedSearchGoal(Goal);
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
	// End:0x61
	if(__NFUN_114__(Goal, CurrentAttackTargetGoal))
	{
		HandleFinishedAttackTargetGoal(Goal);
		goto J0xB8;
		// End:0x8E
		if(__NFUN_114__(Goal, CurrentInvestigateGoal))
		{
			HandleFinishedInvestigateGoal(Goal);
			goto J0xB8;
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xB8
		/*@Error*/
		HandleFinishedSearchGoal(Goal);
		HandleFinishedGoal();
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

function HandleFinishedInvestigateGoal(AI_Goal Goal)
{
	CurrentInvestigateGoal.unPostGoal(self);
	CurrentInvestigateGoal.__NFUN_198__();
	CurrentInvestigateGoal = none;
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function HandleFinishedSearchGoal(AI_Goal Goal)
{
	CurrentSearchGoal.unPostGoal(self);
	CurrentSearchGoal.__NFUN_198__();
	CurrentSearchGoal = none;
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

protected function HandleFinishedGoal()
{
	return;
}

function ResetAttackTarget(ShockPawn Target)
{
	EcologyFighter(m_Pawn).RemoveIntentionalAttacker(Target);
	EcologyFighter(m_Pawn).RemoveForcedEnemy(Target);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x9A
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x8F
	/*@Error*/
	CurrentAttackTargetGoal.FinishUp();
	CurrentAttackTarget = none;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

// Export UEcologyFighterCommanderAction::execUpdateAttackTargets(FFrame&, void* const)
protected native final function UpdateAttackTargets();

function TestEnrageFailure()
{
	// End:0x7B
	if(ShockAI().IsEnrageFailure(CurrentAttackTarget))
	{
		ShockGameDriver(ShockAI().Level.GetGameDriver()).GetPlayerStatsManager().EnrageFailure(ShockAI());
		goto J0xEA;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xEA
		/*@Error*/
	}
	ShockGameDriver(ShockAI().Level.GetGameDriver()).GetPlayerStatsManager().EnrageSuccess(ShockAI());
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function SetAttackTarget(ShockPawn inAttackTarget)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x17A
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x170
	/*@Error*/
	log('AI', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " setting attack target to: "), string(inAttackTarget)), " (was: "), string(CurrentAttackTarget)), ") CurrentAttackTargetGoal: "), string(CurrentAttackTargetGoal)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x149
	/*@Error*/
	CurrentAttackTargetGoal.unPostGoal(self);
	CurrentAttackTargetGoal.__NFUN_198__();
	CurrentAttackTargetGoal = none;
	CurrentAttackTarget = inAttackTarget;
	AttackCurrentTarget();
	OnAttackTargetSet();
	TestEnrageFailure();
	return;
	@NULL
	CommanderAction
	stop;
	stop;
	@NULL
}

function CheckShouldTauntDeadPlayer()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xA4
	/*@Error*/
	ShockAI().PlaySpeech('PlayerDied');
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

protected function OnAttackTargetSet()
{
	return;
}

function AttackCurrentTarget()
{
	log('AI', 3, __NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " Is going to attack "), string(CurrentAttackTarget.Name)));
	assert(Class'Engine.Pawn'.static.checkAlive(CurrentAttackTarget));
	assert(__NFUN_114__(CurrentAttackTargetGoal, none));
	// End:0xCD
	if(__NFUN_119__(CurrentSearchGoal, none))
	{
		CurrentSearchGoal.unPostGoal(self);
		CurrentSearchGoal.__NFUN_198__();
		CurrentSearchGoal = none;
		// End:0x10E
		if(__NFUN_119__(CurrentInvestigateGoal, none))
		{
			CurrentInvestigateGoal.unPostGoal(self);
			CurrentInvestigateGoal.__NFUN_198__();
			CurrentInvestigateGoal = none;
		}
		ShockAI().StopSpeech('Idling');
		CurrentAttackTargetGoal = Class'ShockAI.AttackTargetGoal'.static.Allocate(self).;
	}
	construct_AI_ResourceShockPawn(characterResource(), CurrentAttackTarget);
	CurrentAttackTargetGoal.__NFUN_199__();
	CurrentAttackTargetGoal.postGoal(self);
	return;
	@NULL
	EcologyCommanderAction
	BioshockMovementAction
	@NULL
}

function HandleFinishedAttackTargetGoal(AI_Goal Goal)
{
	local ShockPawn OldAttackTarget;
	local bool bIsSearching;
	local Vector DirectionToTarget;

	assert(__NFUN_114__(CurrentAttackTargetGoal, Goal));
	assert(__NFUN_242__(CurrentAttackTargetGoal.bTryOnlyOnce, true));
	OldAttackTarget = CurrentAttackTarget;
	CurrentAttackTargetGoal.__NFUN_198__();
	CurrentAttackTargetGoal = none;
	CurrentAttackTarget = none;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2A9
	/*@Error*/
	UpdateAttackTargets();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2A9
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x26F
	/*@Error*/
	// End:0x1A2
	if(VisionSensor.HasEverSeenTarget(OldAttackTarget))
	{
		SearchForTarget(OldAttackTarget, VisionSensor.GetLastKnownLocationFor(OldAttackTarget), VisionSensor.GetLastMovingDirectionFor(OldAttackTarget), VisionSensor.GetLocationWhenLost(OldAttackTarget));
		bIsSearching = true;
		goto J0x26F;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x26F
		/*@Error*/
		DirectionToTarget = __NFUN_226__(__NFUN_216__(OldAttackTarget.Location, m_Pawn.Location));
		SearchForTarget(OldAttackTarget, DirectionToTarget, DirectionToTarget, m_Pawn.Location);
	}
	bIsSearching = true;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2A9
	/*@Error*/
	ShockAI().PlaySpeech('ExitedCombat');
	NotifyFinishedAttacking();
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

protected function NotifyFinishedAttacking()
{
	return;
}

function bool HasSpawnPoint()
{
	return __NFUN_119__(EcologyFighter(m_Pawn).SpawnPoint, none);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function Actor GetSpawnPoint()
{
	return EcologyFighter(m_Pawn).SpawnPoint;
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function MoveToSpawnPoint()
{
	// End:0x5D
	if(__NFUN_130__(__NFUN_119__(CurrentMoveToSpawnPointGoal, none), CurrentMoveToSpawnPointGoal.hasCompleted()))
	{
		CurrentMoveToSpawnPointGoal.unPostGoal(self);
		CurrentMoveToSpawnPointGoal.__NFUN_198__();
		CurrentMoveToSpawnPointGoal = none;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xE7
		/*@Error*/
		CurrentMoveToSpawnPointGoal = Class'ShockAI.MoveToSpawnPointGoal'.static.Allocate(self).;
	}
	construct_AI_ResourceActor(characterResource(), GetSpawnPoint());
	assert(__NFUN_119__(CurrentMoveToSpawnPointGoal, none));
	CurrentMoveToSpawnPointGoal.__NFUN_199__();
	CurrentMoveToSpawnPointGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

defaultproperties
{
	MinTimeToIgnoreOtherSounds=0.5000000
}