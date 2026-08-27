class ThreatenAction extends BioshockCharacterAction
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

const kThreatenBehaviorAllowedYawRotationError = 910.2222;

var private MoveToGoal CurrentMoveToGoal;
var private int ThreatenAnimationHandle;
var private int BashTargetAnimationHandle;
var private float NextTimeToPlayThreatenAnimation;
var private float TimeToMoveAndBashTarget;
var private float NextTimeCanBash;
var private Vector StartPosition;
var config Range ThreatenAITimeRange;
var config Range ThreatenPlayerTimeRange;
var config float DistanceToMoveTo;
var config float RunDistanceToMoveTo;
var config float MinTimeBeforeMovingToBashPlayerTarget;
var config float MinTimeBeforeMovingToBashAITarget;
var config float MinTimeBetweenBashes;
var config float DesiredXYDistanceToGatherer;
var config float BashFOV;
var config float BashDistance;
var config name BashAIStimuliSetName;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	Protector(m_Pawn).__OnPushGetPushee__Delegate = OnPushGetPushee;
	Protector(m_Pawn).NotifyStartingThreatenBehavior();
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
		if(m_Pawn.IsAnimationHandleValid(ThreatenAnimationHandle))
		{
		}
		m_Pawn.SmartPerTrackEaseOutAnimation(ThreatenAnimationHandle);
		// End:0xB9
		if(m_Pawn.IsAnimationHandleValid(BashTargetAnimationHandle))
		{
			m_Pawn.SmartPerTrackEaseOutAnimation(BashTargetAnimationHandle);
		}
		StopAimingWeaponAtTarget();
		ShockAI().StopSpeech('Threaten');
		Protector(m_Pawn).__OnPushGetPushee__Delegate = None;
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x14A
	/*@Error*/
	Protector(m_Pawn).SetLastTimeFinishedThreateningPlayer();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyPausedDueToExclusivity()
{
	super(AI_RunnableAction).NotifyPausedDueToExclusivity();
	Protector(m_Pawn).__OnPushGetPushee__Delegate = None;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xE0
	/*@Error*/
	// End:0x93
	if(m_Pawn.IsAnimationHandleValid(ThreatenAnimationHandle))
	{
		m_Pawn.SmartPerTrackEaseOutAnimation(ThreatenAnimationHandle);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xD6
		/*@Error*/
		m_Pawn.SmartPerTrackEaseOutAnimation(BashTargetAnimationHandle);
	}
	StopAimingWeaponAtTarget();
	ShockAI().StopSpeech('Threaten');
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyRunningDueToExclusivity()
{
	super(AI_RunnableAction).NotifyRunningDueToExclusivity();
	Protector(m_Pawn).__OnPushGetPushee__Delegate = OnPushGetPushee;
	ShockAI().PlaySpeech('Threaten');
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ShockPawn GetThreatenTarget()
{
	return ThreatenGoal(achievingGoal).GetThreatenTarget();
	return;
	@NULL
	CommanderAction
}

function bool IsEscortingGatherer()
{
	return __NFUN_129__(Protector(m_Pawn).IsGuardingProtector());
	return;
	@NULL
	CommanderAction
}

function bool IsAggressorMovingAway()
{
	return __NFUN_130__(__NFUN_177__(__NFUN_228__(GetThreatenTarget().GetVelocity()), 10.0000000), __NFUN_177__(__NFUN_228__(__NFUN_216__(GetThreatenTarget().Location, Protector(m_Pawn).GetCurrentGatherer().Location)), __NFUN_228__(__NFUN_216__(m_Pawn.Location, Protector(m_Pawn).GetCurrentGatherer().Location))));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool IsRotatedToFaceTarget()
{
	// End:0x5E
	if(__NFUN_130__(ShockAI().CanAimWeapon(), ShockAI().IsAimingWeapon()))
	{
		return ShockAI().IsWeaponTargetWithinTrackingArea(GetThreatenTarget());		
	}
	else
	{
		return Class'ShockAI.MoveToAction'.static.IsRotatedTo(m_Pawn.Rotation, Rotator(__NFUN_216__(GetThreatenTarget().Location, m_Pawn.Location)), int(910.2222290));
		return;
		@NULL
		CommanderAction
		CommanderAction
		@NULL
	}
}

function bool GetRotationToThreat(out Rotator DesiredRotation)
{
	local float DistanceToThreatenTarget;

	DistanceToThreatenTarget = __NFUN_225__(__NFUN_216__(GetThreatenTarget().Location, m_Pawn.Location));
	// End:0xC0
	if(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_129__(CurrentMoveToGoal.IsMoving()), __NFUN_129__(CurrentMoveToGoal.IsTurning())), __NFUN_177__(DistanceToThreatenTarget, BashDistance)), IsRotatedToFaceTarget()))
	{
		DesiredRotation = m_Pawn.Rotation;
		goto J0xFB;
		DesiredRotation = Rotator(__NFUN_216__(GetThreatenTarget().Location, m_Pawn.Location));
		return true;
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnMoveStarted()
{
	StopAimingWeaponAtTarget();
	return;
}

function bool ShouldStopMoving()
{
	local Gatherer CurrentGatherer;

	CurrentGatherer = Protector(m_Pawn).GetCurrentGatherer();
	// End:0x4D
	if(__NFUN_132__(__NFUN_114__(CurrentGatherer, none), CanBashTarget()))
	{
		return true;
		goto J0xB9;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xB9
		/*@Error*/
		return IsPointWithinCylinder(CurrentGatherer.Location, m_Pawn.Location, DesiredXYDistanceToGatherer, __NFUN_171__(m_Pawn.CollisionHeight, 2.0000000));
	}
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function GetUpdatedDestination(out Actor outDestinationActor, out Vector outDestinationLocation)
{
	local Gatherer CurrentGatherer;
	local Vector PositionTowardsGatherer;

	CurrentGatherer = Protector(m_Pawn).GetCurrentGatherer();
	// End:0x67
	if(__NFUN_114__(CurrentGatherer, none))
	{
		outDestinationLocation = m_Pawn.Location;
		outDestinationActor = none;
		goto J0x164;
		// End:0x8B
		if(ShouldMoveToBashTarget())
		{
			outDestinationActor = GetThreatenTarget();
			// [Explicit Continue]
			goto J0x164;
		}
		PositionTowardsGatherer = __NFUN_215__(CurrentGatherer.Location, __NFUN_212__(__NFUN_226__(__NFUN_216__(m_Pawn.Location, CurrentGatherer.Location)), DesiredXYDistanceToGatherer));
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x151
	/*@Error*/
	outDestinationLocation = PositionTowardsGatherer;
	outDestinationActor = none;
	goto J0x164;
	outDestinationActor = CurrentGatherer;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function MoveToThreatenTarget()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x136
	/*@Error*/
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, m_Pawn.Location, true);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetRotationToThreat;
	CurrentMoveToGoal.__ShouldStopMoving__Delegate = ShouldStopMoving;
	CurrentMoveToGoal.__OnMoveStarted__Delegate = OnMoveStarted;
	CurrentMoveToGoal.__GetUpdatedDestination__Delegate = GetUpdatedDestination;
	CurrentMoveToGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function Actor OnPushGetPushee()
{
	local Vector DirectionToTarget, OffsetToTarget;
	local DamageStimuliSet DamageSet;

	OffsetToTarget = __NFUN_216__(GetThreatenTarget().Location, m_Pawn.Location);
	DirectionToTarget = __NFUN_226__(OffsetToTarget);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x128
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x11D
	/*@Error*/
	DamageSet = Class'Engine.DamageStimuliSet'.static.GetDamageStimuliSet(BashAIStimuliSetName);
	ShockAI(GetThreatenTarget()).Fall(GetThreatenTarget().Location, __NFUN_211__(DirectionToTarget), DirectionToTarget, 0.0000000, 'None', 'None', DamageSet);
	DamageSet.__NFUN_200__();
	return GetThreatenTarget();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool CanReachBashTarget()
{
	return __NFUN_130__(IsPointWithinCylinder(GetThreatenTarget().Location, m_Pawn.Location, BashDistance, __NFUN_171__(m_Pawn.CollisionHeight, 2.0000000)), __NFUN_177__(__NFUN_219__(Vector(m_Pawn.Rotation), __NFUN_226__(__NFUN_216__(GetThreatenTarget().Location, m_Pawn.Location))), __NFUN_188__(__NFUN_171__(BashFOV, 0.0174533))));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

private function bool IsInPositionToBashTarget()
{
	return __NFUN_130__(__NFUN_129__(IsAggressorMovingAway()), CanReachBashTarget());
	return;
}

function ResetBashTargetTime()
{
	// End:0x4C
	if(GetThreatenTarget().__NFUN_303__('ShockPlayer'))
	{
		TimeToMoveAndBashTarget = __NFUN_174__(Level().TimeSeconds, MinTimeBeforeMovingToBashPlayerTarget);
		goto J0x78;
		TimeToMoveAndBashTarget = __NFUN_174__(Level().TimeSeconds, MinTimeBeforeMovingToBashAITarget);
	}
	NextTimeCanBash = __NFUN_174__(Level().TimeSeconds, MinTimeBetweenBashes);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool ShouldMoveToBashTarget()
{
	return __NFUN_179__(Level().TimeSeconds, TimeToMoveAndBashTarget);
	return;
	@NULL
	CommanderAction
}

function bool CanBashTarget()
{
	return __NFUN_130__(__NFUN_130__(__NFUN_130__(Class'Engine.Pawn'.static.checkAlive(GetThreatenTarget()), __NFUN_179__(Level().TimeSeconds, NextTimeCanBash)), __NFUN_132__(GetThreatenTarget().__NFUN_303__('ShockPlayer'), __NFUN_154__(int(GetThreatenTarget().GetRagdoll().GetRagdollState()), int(0)))), IsInPositionToBashTarget());
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool CanThreatenTarget()
{
	local Vector ThreatenSourceLocation, DirectionToThreatenSource, DirectionToTarget;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x139
	/*@Error*/
	// End:0x7B
	if(IsEscortingGatherer())
	{
		ThreatenSourceLocation = Protector(m_Pawn).GetCurrentGatherer().Location;
		goto J0xB1;
		ThreatenSourceLocation = Protector(m_Pawn).SpawnPoint.Location;
	}
	DirectionToThreatenSource = __NFUN_226__(__NFUN_216__(ThreatenSourceLocation, m_Pawn.Location));
	DirectionToTarget = __NFUN_226__(__NFUN_216__(GetThreatenTarget().Location, m_Pawn.Location));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x139
	/*@Error*/
	return true;
	return false;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

private function StopAimingWeaponAtTarget()
{
	// End:0x50
	if(__NFUN_130__(ShockAI().CanAimWeapon(), ShockAI().IsAimingWeapon()))
	{
		ShockAI().StopAimingWeapon();
	}
	return;
}

private function AimWeaponAtTarget()
{
	// End:0x83
	if(__NFUN_130__(__NFUN_130__(ShockAI().CanAimWeapon(), __NFUN_129__(ShockAI().IsAimingWeapon())), ShockAI().IsWeaponTargetWithinTrackingArea(GetThreatenTarget())))
	{
		ShockAI().AimWeaponAtTarget(GetThreatenTarget());
	}
	return;
}

function TransitionIntoAggressive()
{
	local name TransitionIntoAggressiveAnimName;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x118
	/*@Error*/
	TransitionIntoAggressiveAnimName = Protector(m_Pawn).GetTransitionIntoAggressiveName();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x118
	/*@Error*/
	ThreatenAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, TransitionIntoAggressiveAnimName);
	// End:0xE0
	if(__NFUN_130__(m_Pawn.IsAnimationHandleValid(ThreatenAnimationHandle), __NFUN_129__(m_Pawn.IsAnimationPerTrackEntirelyEasedIn(ThreatenAnimationHandle))))
	{
		yield();
		// [Loop Continue]
		goto J0x89;
		ShockAI().BecomeAggressive();
		m_Pawn.FinishAnimation(ThreatenAnimationHandle);
		return;
		@NULL
		EcologyAI
	}
	EcologyFighterCommanderAction
	@NULL
}

function SendBashTargetNotification(name BashTargetAnimationName)
{
	local array<AnimNotify> PushAnimNotifies;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xB6
	/*@Error*/
	m_Pawn.GetAnimationAnimNotifies(BashTargetAnimationName, PushAnimNotifies, Class'ShockAI.AnimNotify_Push');
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB6
	/*@Error*/
	Aggressor(GetThreatenTarget()).HandleAIAttackNotification(m_Pawn, m_Pawn.GetAnimationAnimNotifyTime(BashTargetAnimationName, PushAnimNotifies[0]), 2);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function Threaten()
{
	local name ThreatenAnimationName, BashTargetAnimationName;

	ShockAI().PlaySpeech('Threaten');
	ResetBashTargetTime();
	ShockAI().SetShouldWalk();
	J0x43:

	// End:0x469 [Loop If]
	if(__NFUN_129__(BioshockCharacterGoal(achievingGoal).ShouldFinishUp()))
	{
		// End:0x8F
		if(__NFUN_129__(ShockAI().IsAggressive()))
		{
			TransitionIntoAggressive();
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x45C
			/*@Error*/
		}
		// End:0x291
		if(CanBashTarget())
		{
			StopAimingWeaponAtTarget();
			BashTargetAnimationName = Protector(m_Pawn).GetBashTargetAnimationName(GetThreatenTarget());
			SendBashTargetNotification(BashTargetAnimationName);
			BashTargetAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, BashTargetAnimationName);
			m_Pawn.FinishAnimation(BashTargetAnimationHandle);
			// End:0x1EB
			if(GetThreatenTarget().__NFUN_303__('Aggressor'))
			{
				Aggressor(GetThreatenTarget()).NotifyKnockedBackByThreateningProtector(Protector(m_Pawn));
				goto J0x284;
				// End:0x284
				if(__NFUN_130__(GetThreatenTarget().__NFUN_303__('ShockPlayer'), IsEscortingGatherer()))
				{
					Protector(m_Pawn).RampUpThreatenPlayerState();
					// End:0x284
					if(Protector(m_Pawn).ShouldAttackThreateningPlayer())
					{
					}
					Protector(m_Pawn).AddForcedEnemy(GetThreatenTarget());
					ResetBashTargetTime();
					goto J0x45C;
					/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
						
					*/

					// End:0x452
					/*@Error*/
					StopAimingWeaponAtTarget();
					ThreatenAnimationName = Protector(m_Pawn).GetThreatenAnimationName();
					ThreatenAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, ThreatenAnimationName);
					m_Pawn.FinishAnimation(ThreatenAnimationHandle);
				}
			}
			// End:0x36D
			if(GetThreatenTarget().__NFUN_303__('Aggressor'))
			{
			}
			Aggressor(GetThreatenTarget()).NotifyThreatened(Protector(m_Pawn));
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x3EE
			/*@Error*/
			NextTimeToPlayThreatenAnimation = __NFUN_174__(Level().TimeSeconds, RandRange(ThreatenAITimeRange.Min, ThreatenAITimeRange.Max));
			goto J0x44F;
			NextTimeToPlayThreatenAnimation = __NFUN_174__(Level().TimeSeconds, RandRange(ThreatenPlayerTimeRange.Min, ThreatenPlayerTimeRange.Max));
			goto J0x45C;
		}
		AimWeaponAtTarget();
		yield();
		// [Loop Continue]
		goto J0x43;
		StopAimingWeaponAtTarget();
		return;
		@NULL
		EcologyAI
		EcologyFighterCommanderAction
		@NULL
	}
}

function PlayFinalAnimation(name FinalAnimationName)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xD1
	/*@Error*/
	ThreatenAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, FinalAnimationName);
	// End:0x99
	if(__NFUN_130__(m_Pawn.IsAnimationHandleValid(ThreatenAnimationHandle), __NFUN_129__(m_Pawn.IsAnimationPerTrackEntirelyEasedIn(ThreatenAnimationHandle))))
	{
		yield();
		// [Loop Continue]
		goto J0x42;
		ShockAI().BecomePassive();
		m_Pawn.FinishAnimation(ThreatenAnimationHandle);
	}
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function PlayFinalThreatAnimation()
{
	local name FinalThreatAnimation;

	FinalThreatAnimation = Protector(m_Pawn).GetFinalThreatAnimationName();
	PlayFinalAnimation(FinalThreatAnimation);
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function PlayTransitionIntoPassiveAnimation()
{
	local name TransitionIntoPassiveAnimation;

	TransitionIntoPassiveAnimation = Protector(m_Pawn).GetTransitionIntoIdleName();
	PlayFinalAnimation(TransitionIntoPassiveAnimation);
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

state Running
{Begin:

	MoveToThreatenTarget();
	Threaten();
	// End:0x61
	if(m_Pawn.CanSee(GetThreatenTarget()))
	{
		// End:0x54
		if(__NFUN_129__(IsRotatedToFaceTarget()))
		{
			yield();
			// [Loop Continue]
			goto J0x38;
			PlayFinalThreatAnimation();
		}
		goto J0x6B;
		PlayTransitionIntoPassiveAnimation();
	}
	// End:0x9D
	if(__NFUN_129__(BioshockCharacterGoal(achievingGoal).ShouldFinishUp()))
	{
		goto 'Begin';
		goto J0xA7;
		succeed();
		stop;		
	}			
	@NULL
	@NULL
	@NULL
}

defaultproperties
{
	ThreatenAITimeRange=(Min=3.0000000,Max=5.0000000)
	ThreatenPlayerTimeRange=(Min=10.0000000,Max=10.0000000)
	DistanceToMoveTo=1000.0000000
	RunDistanceToMoveTo=300.0000000
	MinTimeBeforeMovingToBashPlayerTarget=10.0000000
	MinTimeBeforeMovingToBashAITarget=5.0000000
	MinTimeBetweenBashes=2.0000000
	DesiredXYDistanceToGatherer=150.0000000
	BashFOV=45.0000000
	BashDistance=250.0000000
	BashAIStimuliSetName="ProtectorPushAIStimuliSet"
	satisfiesGoal=Class'ShockAI.ThreatenGoal'
	bExclusiveAction=true
}