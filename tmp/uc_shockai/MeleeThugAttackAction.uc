class MeleeThugAttackAction extends AggressorAttackAction
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private bool bMovingWhileAttacking;
var private Range DesiredMeleeAttackDistance;
var private float MiddleOfDesiredMeleeAttackDistance;
var private AIMeleeWeapon MeleeThugMeleeWeapon;
var private int StepAnimationHandle;
var array<Vector> StepLateralTranslations;
var private float NextTimeCanCheckForDeadlyTarget;
var private config float ChanceToMoveAfterAttacking;
var config array<name> StepLateralAnimations;
var private config Range MoveDistanceRangeWhileWaitingToAttack;
var private config float MaxDistanceToStayRotatedTowardTarget;
var private config float MinOffsetToTarget;
var private config Range DesiredRangeToRunawayFromDeadlyTarget;
var private config Range CheckDeadlyTargetTimeRange;
var private config float MinTimeBeforeAvoidingTargetAgain;
var private config float DotThresholdToAvoidDeadlyPlayerTarget;
var private config float DotThresholdToAvoidDeadlyAITarget;
var config array<name> PushAnimations;
var config name MeleePushDamageStimuliSetName;
var config float PushFOV;
var config float PushDistance;

function initAction(AI_Resource R, AI_Goal Goal)
{
	local float MeleeWeaponAttackRange;

	super.initAction(R, Goal);
	MeleeThugMeleeWeapon = MeleeThug(m_Pawn).GetMeleeWeapon();
	MeleeWeaponAttackRange = IProvideMeleeDamageData(ShockGameInfo(Level().Game).GetItemFromClass(MeleeThugMeleeWeapon.GetDefaultAmmoSelection())).GetAttackRange();
	DesiredMeleeAttackDistance = MeleeThugMeleeWeapon.GetAttackAnimationsTranslationRange();
	__NFUN_184__(DesiredMeleeAttackDistance.Min, MeleeWeaponAttackRange);
	__NFUN_184__(DesiredMeleeAttackDistance.Max, MeleeWeaponAttackRange);
	MiddleOfDesiredMeleeAttackDistance = __NFUN_174__(DesiredMeleeAttackDistance.Min, __NFUN_171__(__NFUN_175__(DesiredMeleeAttackDistance.Max, DesiredMeleeAttackDistance.Min), 0.5000000));
	MeleeThug(m_Pawn).__OnPushGetPushee__Delegate = OnPushGetPushee;
	CacheStepLateralAnimationTranslations();
	ShockAI().MovementAttackTarget = Target;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1E5
	/*@Error*/
	TellBotTargetToStayLow();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function CacheStepLateralAnimationTranslations()
{
	local int i;
	local float AnimLength;
	local Vector IterAnimTranslation;
	local float IterAnimResultYaw;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xC8
	/*@Error*/
	AnimLength = m_Pawn.GetAnimationLength(StepLateralAnimations[i]);
	m_Pawn.GetAnimationAbsoluteMotion(StepLateralAnimations[i], AnimLength, IterAnimTranslation, IterAnimResultYaw);
	StepLateralTranslations[StepLateralTranslations.Length] = IterAnimTranslation;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	assert(__NFUN_154__(StepLateralTranslations.Length, StepLateralAnimations.Length));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function Cleanup()
{
	super.Cleanup();
	MeleeThug(m_Pawn).__OnPushGetPushee__Delegate = None;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x76
	/*@Error*/
	m_Pawn.SmartPerTrackEaseOutAnimation(StepAnimationHandle);
	ShockAI().MovementAttackTarget = none;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool CanPushTarget()
{
	local Vector DirectionToTarget, OffsetToTarget;

	OffsetToTarget = __NFUN_216__(Target.Location, m_Pawn.Location);
	DirectionToTarget = __NFUN_226__(OffsetToTarget);
	return __NFUN_130__(__NFUN_176__(__NFUN_225__(OffsetToTarget), PushDistance), __NFUN_179__(__NFUN_219__(Vector(m_Pawn.Rotation), DirectionToTarget), __NFUN_188__(__NFUN_171__(PushFOV, 0.0174533))));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function Actor OnPushGetPushee()
{
	local Vector DirectionToTarget;
	local DamageStimuliSet DamageSet;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x121
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x117
	/*@Error*/
	DamageSet = Class'Engine.DamageStimuliSet'.static.GetDamageStimuliSet(MeleePushDamageStimuliSetName);
	DirectionToTarget = __NFUN_226__(__NFUN_216__(Target.Location, m_Pawn.Location));
	ShockAI(Target).Fall(Target.Location, __NFUN_211__(DirectionToTarget), DirectionToTarget, 0.0000000, 'None', 'None', DamageSet);
	DamageSet.__NFUN_200__();
	return Target;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnDamagedByTarget()
{
	super(CharacterAttackAction).OnDamagedByTarget();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x68
	/*@Error*/
	FindAvoidancePoint();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Vector GetProjectedTargetPosition()
{
	local Vector ProjectedTargetPosition;

	ProjectedTargetPosition = __NFUN_215__(Target.Location, __NFUN_212__(Target.GetVelocity(), GetMeleeWeapon().GetAverageAttackAnimationInitiateDamageTime()));
	return ProjectedTargetPosition;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

// Export UMeleeThugAttackAction::execIsTooCloseToTarget(FFrame&, void* const)
native function bool IsTooCloseToTarget();

// Export UMeleeThugAttackAction::execShouldStopMovingToTarget(FFrame&, void* const)
native function bool ShouldStopMovingToTarget();

function bool GetDesiredFocalPointOverride(out Vector DesiredFocalPoint)
{
	//native.DesiredFocalPoint;	
	@NULL
}

function GetUpdatedDestination(out Actor outDestinationActor, out Vector outDestinationLocation)
{
	//native.outDestinationActor;
	//native.outDestinationLocation;	
	@NULL
	@NULL
}

function OnMoveStarted()
{
	super(CharacterAttackAction).OnMoveStarted();
	bMovingWhileAttacking = true;
	return;
	@NULL
	CommanderAction
}

function OnMoveEnded()
{
	super(CharacterAttackAction).OnMoveEnded();
	bMovingWhileAttacking = false;
	ShockAI().SetShouldRun();
	return;
	@NULL
	CommanderAction
}

function OnReachedAvoidancePoint()
{
	super(CharacterAttackAction).OnReachedAvoidancePoint();
	ShockAI().bAvoidLastPath = true;
	NextTimeCanCheckForDeadlyTarget = __NFUN_174__(Level().TimeSeconds, MinTimeBeforeAvoidingTargetAgain);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function NotifyCannotFindWayToDestination()
{
	super(CharacterAttackAction).NotifyCannotFindWayToDestination();
	// End:0x55
	if(__NFUN_180__(LastTimeCouldNotFindWayToDestination, 0.0000000))
	{
		// End:0x34
		if(ShouldTellBotTargetToStayLow())
		{
			TellBotTargetToStayLow();
			LastTimeCouldNotFindWayToDestination = Level().TimeSeconds;
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x84
		/*@Error*/
	}
	StopMovingToAvoidancePoint();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyFoundWayToDestination()
{
	super(CharacterAttackAction).NotifyFoundWayToDestination();
	LastTimeCouldNotFindWayToDestination = 0.0000000;
	return;
	@NULL
	CommanderAction
}

function AIMeleeWeapon GetMeleeWeapon()
{
	return MeleeThugMeleeWeapon;
	return;
	@NULL
}

function AIWeapon GetThreeSixtyWeapon()
{
	return MeleeThug(m_Pawn).GetThreeSixtyWeapon();
	return;
	@NULL
	CommanderAction
}

function bool CanHitWithMeleeWeapon(bool bUseCurrentRotation)
{
	//native.bUseCurrentRotation;	
	@NULL
}

// Export UMeleeThugAttackAction::execCanAttackTarget(FFrame&, void* const)
native function bool CanAttackTarget();

function NotifyBeginningAttack()
{
	super.NotifyBeginningAttack();
	MoveToActor = Target;
	return;
	@NULL
	EcologyAI
	BioshockMovementAction
}

function AttackTarget()
{
	local AIWeapon DesiredWeapon;

	// End:0x25
	if(CanHitWithMeleeWeapon(true))
	{
		DesiredWeapon = GetMeleeWeapon();
		goto J0x39;
		DesiredWeapon = GetThreeSixtyWeapon();
	}
	assert(__NFUN_119__(DesiredWeapon, none));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x9F
	/*@Error*/
	MeleeThug(m_Pawn).Equip(DesiredWeapon);
	UseCurrentWeapon(DesiredWeapon);
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function bool IsAnimatingWhileAttacking()
{
	return __NFUN_132__(IsThreatening(), m_Pawn.IsAnimationHandleValid(StepAnimationHandle));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
}

function name ChooseStepLateralAnimation()
{
	local int i;
	local name StepLateralAnimation;
	local Vector TestPoint;
	local array<name> UsableLateralAnimations;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xE8
	/*@Error*/
	TestPoint = __NFUN_215__(m_Pawn.Location, __NFUN_276__(StepLateralTranslations[i], m_Pawn.Rotation));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xDA
	/*@Error*/
	UsableLateralAnimations[UsableLateralAnimations.Length] = StepLateralAnimations[i];
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	StepLateralAnimation = UsableLateralAnimations[__NFUN_167__(UsableLateralAnimations.Length)];
	return StepLateralAnimation;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function StepLaterally()
{
	local name StepLateralAnimation;

	StepLateralAnimation = ChooseStepLateralAnimation();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x76
	/*@Error*/
	StepAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, StepLateralAnimation);
	m_Pawn.FinishAnimation(StepAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function PushTarget()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x68
	/*@Error*/
	StepAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, PushAnimations[__NFUN_167__(PushAnimations.Length)]);
	m_Pawn.FinishAnimation(StepAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function bool ShouldIgnoreThreatenChance()
{
	return CurrentMoveToGoal.CannotFindWayToDestination();
	return;
	@NULL
}

function NotifyCannotAttackTarget()
{
	super(CharacterAttackAction).NotifyCannotAttackTarget();
	// End:0x99
	if(__NFUN_130__(__NFUN_130__(__NFUN_130__(CurrentMoveToGoal.CannotFindWayToDestination(), __NFUN_176__(__NFUN_225__(__NFUN_216__(GetProjectedTargetPosition(), m_Pawn.Location)), PushDistance)), IsRotatedForAttack()), m_Pawn.CanSee(Target)))
	{
		PushTarget();
		goto J0xE9;
		// End:0xB3
		if(ShouldThreaten())
		{
			Threaten();
			goto J0xE9;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0xE9
			/*@Error*/
		}
	}
	StepLaterally();
	CheckIfShouldMoveToAvoidancePoint();
	return;
	@NULL
	EcologyAI
	BioshockMovementAction
	@NULL
}

function NotifyFinishedAttackingTarget()
{
	local float ProjectedDistanceToTarget;

	ProjectedDistanceToTarget = __NFUN_225__(__NFUN_216__(GetProjectedTargetPosition(), m_Pawn.Location));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x113
	/*@Error*/
	// End:0xD4
	if(__NFUN_178__(__NFUN_195__(), ChanceToMoveAfterAttacking))
	{
		StepLaterally();
		goto J0x113;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x113
		/*@Error*/
		PushTarget();
		return;
	}
	@NULL
	EcologyAI
	BioshockMovementAction
	@NULL
}

defaultproperties
{
	ChanceToMoveAfterAttacking=0.6500000
	StepLateralAnimations[0]="ME_dodgeBWD_B"
	MoveDistanceRangeWhileWaitingToAttack=(Min=75.0000000,Max=200.0000000)
	MaxDistanceToStayRotatedTowardTarget=500.0000000
	MinOffsetToTarget=32.0000000
	DesiredRangeToRunawayFromDeadlyTarget=(Min=800.0000000,Max=1000.0000000)
	CheckDeadlyTargetTimeRange=(Min=1.0000000,Max=1.0000000)
	MinTimeBeforeAvoidingTargetAgain=5.0000000
	DotThresholdToAvoidDeadlyPlayerTarget=0.7070000
	DotThresholdToAvoidDeadlyAITarget=0.5000000
	PushAnimations[0]="ME_pushBack_A"
	MeleePushDamageStimuliSetName="AggressorPushStimuliSet"
	PushFOV=40.0000000
	PushDistance=200.0000000
	AIThreatenChance=0.5000000
	PlayerWithWrenchEquippedThreatenChance=0.2500000
	TimeRangeBetweenThreatens=(Min=4.0000000,Max=8.0000000)
	ThreatenAnimations[0]="ME_stepFWD_A"
	ThreatenAnimations[1]="ME_Threaten_A"
	ThreatenAnimations[2]="ME_Threaten_C"
	ThreatenAnimations[3]="ME_Threaten_D"
	ThreatenAnimations[4]="ME_Threaten_G"
	MimicAttackInfos[0]=(MimicPoseAnimationName="ME_PlayDeadBack_Pose",ForwardAttackAnimationName="ME_PlaydeadBack_FWD",LeftAttackAnimationName="ME_PlaydeadBack_Left",RightAttackAnimationName="ME_PlaydeadBack_Right",BackwardAttackAnimationName="ME_PlaydeadBack_BWD")
	MimicAttackInfos[1]=(MimicPoseAnimationName="ME_PlayDeadSitWall_Pose",ForwardAttackAnimationName="ME_PlayDeadSitWall",LeftAttackAnimationName="ME_PlayDeadSitWall",RightAttackAnimationName="ME_PlayDeadSitWall",BackwardAttackAnimationName="ME_PlayDeadSitWall")
	bCanDodgeWhileAttacking=true
	MinDodgeTime=1.5000000
	DodgeChance=1.0000000
	DodgeFacingAngleDegrees=30.0000000
	InitialReactionAnimations[0]="ME_Threaten_A"
	InitialReactionAnimations[1]="ME_Threaten_C"
	InitialReactionAnimations[2]="ME_Threaten_D"
	InitialReactionChance=1.0000000
	DistanceFromTargetToDoInitialReactionRange=(Min=500.0000000,Max=1000.0000000)
	AttackBehaviorAllowedYawRotationErrorTwoByte=8192
	MeleeInterruptDegrees=120.0000000
	MeleeInterruptMaxVelocity=50.0000000
	LocomotionResumeAlignmentThreshold=0.3000000
}