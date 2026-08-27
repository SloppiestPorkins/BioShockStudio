class CeilingCrawlerAttackAction extends AggressorAttackAction
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

const kCollisionRadiiMultiplierForJumpUp = 2.0;
const kSmallJumpbackAnimFudgeFactor = 0.1;

struct atomic JumpBackAnimationInfo
{
	var name JumpBackAnimation;
	var float JumpBackWeight;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

var private JumpToCeilingGoal CurrentJumpToCeilingGoal;
var private JumpToFloorGoal CurrentJumpToFloorGoal;
var private int JumpBackAnimationHandle;
var private int JumpAttackAnimationHandle;
var private float EndAttackWithRangedWeaponTime;
var private float NextTimeForRangedAttackMovementTest;
var private bool bWantsToThreaten;
var private bool bDoingRangedAttack;
var private bool bInterrupted;
var private bool bWantsToJumpToCeiling;
var array<name> UsableJumpBackAnimations;
var array<float> UsableJumpBackAnimationWeights;
var array<Vector> UsableJumpBackEndPositions;
var array<int> UsableJumpBackAnimationsToRemove;
var private config int MinNumAttacksBeforeJumpingBack;
var config array<JumpBackAnimationInfo> JumpBackAnimations;
var private config float JumpBackFirstAnimationTweenInTime;
var private config float JumpBackLastAnimationTweenOutTime;
var private config int MinNumJumpbacks;
var private config int MaxNumJumpbacks;
var private config float ChanceToJumpToCeiling;
var private config float ChanceToDropDownImmediately;
var private config float ChanceToMoveAfterRangedAttackOnFloor;
var private config Range MinDesiredDistanceToMoveAroundWhileTargetUnreachableRange;
var private config float MaxDistanceToMoveAround;
var config array<name> KickAttackInitialAnimations;
var config array<name> KickAttackMissAnimations;
var private config float MinTimeToAttackFromCeiling;
var private config float MaxTimeToAttackFromCeiling;
var private config float MinTimeToAttackFromFloor;
var private config float MaxTimeToAttackFromFloor;
var config Rotator MinKickPushPlayerReactionRotation;
var config Rotator MaxKickPushPlayerReactionRotation;
var config float KickPushPlayerPushMagnitude;
var config float KickPushTargetPlayerMoveReactionDuration;
var config float KickPushTargetPlayerRotateReactionDuration;
var config float KickPushFOV;
var config float KickPushDistance;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super.initAction(R, Goal);
	CeilingCrawler(m_Pawn).__OnPushGetPushee__Delegate = OnPushGetPushee;
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
	if(__NFUN_119__(CurrentJumpToCeilingGoal, none))
	{
		CurrentJumpToCeilingGoal.__NFUN_198__();
		CurrentJumpToCeilingGoal = none;
		// End:0x5C
		if(__NFUN_119__(CurrentJumpToFloorGoal, none))
		{
			CurrentJumpToFloorGoal.__NFUN_198__();
		}
		CurrentJumpToFloorGoal = none;
		// End:0x9F
		if(m_Pawn.IsAnimationHandleValid(JumpBackAnimationHandle))
		{
			m_Pawn.SmartPerTrackEaseOutAnimation(JumpBackAnimationHandle);
		}
		// End:0xE2
		if(m_Pawn.IsAnimationHandleValid(JumpAttackAnimationHandle))
		{
			m_Pawn.SmartPerTrackEaseOutAnimation(JumpAttackAnimationHandle);
			ShockAI().NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
		}
		EcologyAI(m_Pawn).NotifyDouseReactionPreventionNoLongerDesired(self);
		CeilingCrawler(m_Pawn).__OnPushGetPushee__Delegate = None;
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyPausedDueToExclusivity()
{
	super(CharacterAttackAction).NotifyPausedDueToExclusivity();
	bInterrupted = true;
	// End:0x57
	if(__NFUN_119__(CurrentJumpToCeilingGoal, none))
	{
		CurrentJumpToCeilingGoal.unPostGoal(self);
		CurrentJumpToCeilingGoal.__NFUN_198__();
		CurrentJumpToCeilingGoal = none;
		// End:0x98
		if(__NFUN_119__(CurrentJumpToFloorGoal, none))
		{
			CurrentJumpToFloorGoal.unPostGoal(self);
		}
		CurrentJumpToFloorGoal.__NFUN_198__();
		CurrentJumpToFloorGoal = none;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x13B
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xF8
		/*@Error*/
	}
	m_Pawn.SmartPerTrackEaseOutAnimation(JumpBackAnimationHandle);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x13B
	/*@Error*/
	m_Pawn.SmartPerTrackEaseOutAnimation(JumpAttackAnimationHandle);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyRunningDueToExclusivity()
{
	super(CharacterAttackAction).NotifyRunningDueToExclusivity();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x23
	/*@Error*/
	runAction();
	return;
	@NULL
	CommanderAction
}

function GetUpdatedDestination(out Actor outDestinationActor, out Vector outDestinationLocation)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x104
	/*@Error*/
	// End:0xD5
	if(__NFUN_114__(MoveToActor, Target))
	{
		// End:0xD2
		if(CurrentMoveToGoal.CannotFindWayToDestination())
		{
			// End:0xD2
			if(__NFUN_132__(__NFUN_129__(CeilingCrawler(m_Pawn).CanAttackTargetWithRangedWeapon(Target)), __NFUN_129__(ShockAI().FindPointToAttackTarget(Target, MoveToActor))))
			{
				EcologyFighter(m_Pawn).AddUnreachableTarget(Target);
				FindAvoidancePoint();
				goto J0x104;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x104
				/*@Error*/
				MoveToActor = Target;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x129
				/*@Error*/
				outDestinationActor = MoveToActor;
			}
		}
	}
	goto J0x13C;
	outDestinationLocation = MoveToPoint;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool GetDesiredFocalPointOverride(out Vector DesiredFocalPoint)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x126
	/*@Error*/
	DesiredFocalPoint = Target.Location;
	return true;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool GetDesiredRotationOverride(out Rotator DesiredRotation)
{
	// End:0x2F
	if(IsJumping())
	{
		DesiredRotation = m_Pawn.Rotation;
		return true;
		return false;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function bool ShouldStopMovingToTarget()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xAA
	/*@Error*/
	return true;
	goto J0xAC;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool CannotMeleeAttackTarget()
{
	return __NFUN_132__(__NFUN_132__(__NFUN_119__(CurrentMoveToGoal.GetDestinationActor(), Target), CurrentMoveToGoal.CannotFindWayToDestination()), Target.IsOnCeiling());
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function AIRangedWeapon GetRangedWeapon()
{
	return CeilingCrawler(m_Pawn).GetRangedWeapon();
	return;
	@NULL
	CommanderAction
}

function bool CanAttackWithHandWeapon(bool bUseCurrentRotation)
{
	local AIWeapon HandWeapon;

	HandWeapon = CeilingCrawler(m_Pawn).GetHandWeapon();
	assert(__NFUN_119__(HandWeapon, none));
	return __NFUN_130__(__NFUN_132__(__NFUN_129__(bUseCurrentRotation), IsRotatedForAttack()), HandWeapon.CanHitTarget(Target, bUseCurrentRotation, false));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool CanJumpAttackWithSlashWeapon(bool bUseCurrentRotation)
{
	local AIWeapon SlashWeapon;

	SlashWeapon = CeilingCrawler(m_Pawn).GetSlashWeapon();
	assert(__NFUN_119__(SlashWeapon, none));
	return __NFUN_130__(__NFUN_132__(__NFUN_129__(bUseCurrentRotation), IsRotatedForAttack()), SlashWeapon.CanHitTarget(Target, bUseCurrentRotation, false));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool CanAttackTarget()
{
	return __NFUN_132__(__NFUN_132__(__NFUN_132__(__NFUN_130__(CannotMeleeAttackTarget(), CanAttackWithRangedWeapon(true)), CanAttackWithHandWeapon(true)), CanJumpAttackWithSlashWeapon(true)), CanAttackWithKickWeapon());
	return;
}

private function bool IsJumping()
{
	return __NFUN_132__(__NFUN_132__(IsJumpingBack(), IsJumpingBetweenCeilingAndFloor()), IsDoingJumpAttack());
	return;
}

function bool IsDoingJumpAttack()
{
	return __NFUN_130__(__NFUN_130__(m_Pawn.IsAnimationHandleValid(JumpAttackAnimationHandle), __NFUN_129__(m_Pawn.IsAnimationPerTrackEasingOut(JumpAttackAnimationHandle))), __NFUN_129__(m_Pawn.IsAnimationFlatEasingOut(JumpAttackAnimationHandle)));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool IsJumpingBack()
{
	return __NFUN_130__(__NFUN_130__(m_Pawn.IsAnimationHandleValid(JumpBackAnimationHandle), __NFUN_129__(m_Pawn.IsAnimationPerTrackEasingOut(JumpBackAnimationHandle))), __NFUN_129__(m_Pawn.IsAnimationFlatEasingOut(JumpBackAnimationHandle)));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool IsJumpingBetweenCeilingAndFloor()
{
	return __NFUN_132__(__NFUN_130__(__NFUN_119__(CurrentJumpToCeilingGoal, none), __NFUN_129__(CurrentJumpToCeilingGoal.hasCompleted())), __NFUN_130__(__NFUN_119__(CurrentJumpToFloorGoal, none), __NFUN_129__(CurrentJumpToFloorGoal.hasCompleted())));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function JumpUp()
{
	assert(__NFUN_132__(__NFUN_114__(CurrentJumpToCeilingGoal, none), CurrentJumpToCeilingGoal.hasCompleted()));
	// End:0x6C
	if(__NFUN_119__(CurrentJumpToCeilingGoal, none))
	{
		CurrentJumpToCeilingGoal.unPostGoal(self);
		CurrentJumpToCeilingGoal.__NFUN_198__();
		CurrentJumpToCeilingGoal = none;
		CurrentJumpToCeilingGoal = Class'ShockAI.JumpToCeilingGoal'.static.Allocate(self).;
	}
	construct_AI_ResourceIntVector(characterResource(), achievingGoal.Priority, m_Pawn.Location);
	CurrentJumpToCeilingGoal.__NFUN_199__();
	CurrentJumpToCeilingGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentJumpToCeilingGoal);
	CurrentJumpToCeilingGoal.unPostGoal(self);
	CurrentJumpToCeilingGoal.__NFUN_198__();
	CurrentJumpToCeilingGoal = none;
	MoveToPoint = m_Pawn.Location;
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function DropDown()
{
	assert(__NFUN_132__(__NFUN_114__(CurrentJumpToFloorGoal, none), CurrentJumpToFloorGoal.hasCompleted()));
	// End:0x6C
	if(__NFUN_119__(CurrentJumpToFloorGoal, none))
	{
		CurrentJumpToFloorGoal.unPostGoal(self);
		CurrentJumpToFloorGoal.__NFUN_198__();
		CurrentJumpToFloorGoal = none;
		CurrentJumpToFloorGoal = Class'ShockAI.JumpToFloorGoal'.static.Allocate(self).;
	}
	construct_AI_ResourceIntVector(characterResource(), achievingGoal.Priority, m_Pawn.Location);
	CurrentJumpToFloorGoal.__NFUN_199__();
	CurrentJumpToFloorGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentJumpToFloorGoal);
	CurrentJumpToFloorGoal.unPostGoal(self);
	CurrentJumpToFloorGoal.__NFUN_198__();
	CurrentJumpToFloorGoal = none;
	MoveToActor = Target;
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function Actor OnPushGetPushee()
{
	local Vector DirectionToTarget, OffsetToTarget;

	OffsetToTarget = __NFUN_216__(Target.Location, m_Pawn.Location);
	DirectionToTarget = __NFUN_226__(OffsetToTarget);
	log('AI', 5, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " OnPushGetPushee - Distance: "), string(__NFUN_225__(OffsetToTarget))), " KickPushDistance: "), string(KickPushDistance)), "  Dot: "), string(__NFUN_219__(Vector(m_Pawn.Rotation), DirectionToTarget))), " Required DOT: "), string(__NFUN_188__(__NFUN_171__(KickPushFOV, 0.0174533)))));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x183
	/*@Error*/
	return Target;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function int ChooseJumpbackAnimation(out array<float> JumpbackAnimationWeights)
{
	local int i;
	local float TotalWeight, SummedWeight, RandomWeight;

	assert(__NFUN_151__(JumpbackAnimationWeights.Length, 0));
	i = 0;
	// End:0x5F
	if(__NFUN_150__(i, JumpbackAnimationWeights.Length))
	{
		__NFUN_184__(TotalWeight, JumpbackAnimationWeights[i]);
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x1B;
		RandomWeight = __NFUN_171__(__NFUN_195__(), TotalWeight);
		log('AI', 5, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " ChooseJumpbackAnimation - RandomWeight is: "), string(RandomWeight)), " Total Weight is: "), string(TotalWeight)));
	}
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1E5
	/*@Error*/
	__NFUN_184__(SummedWeight, JumpbackAnimationWeights[i]);
	log('AI', 5, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " ChooseJumpbackAnimation - i: "), string(i)), " SummedWeight: "), string(SummedWeight)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1D7
	/*@Error*/
	return i;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x109;
	assert(false);
	return -1;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function JumpBack()
{
	local float JumpBackAnimLength;
	local Vector JumpBackTranslation, JumpBackDirection;
	local float JumpBackRotationYaw;
	local int RandomNumJumpbacks, RandomUsableJumpBackAnimationIndex, i, j;
	local name TestJumpAnimation;
	local bool bFirstJumpBack, bLastJumpBack;
	local int JumpBackAnimationEndBehavior;

	ShockAI().NotifyFullBodyHitReactionPreventionDesired(self);
	UsableJumpBackAnimations.Remove(0, UsableJumpBackAnimations.Length);
	UsableJumpBackAnimationWeights.Remove(0, UsableJumpBackAnimationWeights.Length);
	UsableJumpBackEndPositions.Remove(0, UsableJumpBackEndPositions.Length);
	UsableJumpBackAnimationsToRemove.Remove(0, UsableJumpBackAnimationsToRemove.Length);
	RandomNumJumpbacks = __NFUN_146__(__NFUN_167__(__NFUN_147__(MaxNumJumpbacks, MinNumJumpbacks)), MinNumJumpbacks);
	bFirstJumpBack = true;
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x725
	/*@Error*/
	UsableJumpBackAnimations.Remove(0, UsableJumpBackAnimations.Length);
	UsableJumpBackEndPositions.Remove(0, UsableJumpBackEndPositions.Length);
	UsableJumpBackAnimationWeights.Remove(0, UsableJumpBackAnimationWeights.Length);
	j = 0;
	// End:0x2D8
	if(__NFUN_150__(j, JumpBackAnimations.Length))
	{
		TestJumpAnimation = JumpBackAnimations[j].JumpBackAnimation;
		JumpBackAnimLength = m_Pawn.GetAnimationLength(TestJumpAnimation);
		m_Pawn.GetAnimationAbsoluteMotion(TestJumpAnimation, JumpBackAnimLength, JumpBackTranslation, JumpBackRotationYaw);
		JumpBackDirection = __NFUN_276__(__NFUN_226__(JumpBackTranslation), m_Pawn.Rotation);
		JumpBackTranslation = __NFUN_212__(JumpBackDirection, __NFUN_225__(JumpBackTranslation));
		// End:0x2CA
		if(m_Pawn.__NFUN_521__(__NFUN_215__(m_Pawn.Location, JumpBackTranslation)))
		{
			UsableJumpBackAnimations[UsableJumpBackAnimations.Length] = TestJumpAnimation;
			UsableJumpBackAnimationWeights[UsableJumpBackAnimationWeights.Length] = JumpBackAnimations[j].JumpBackWeight;
			UsableJumpBackEndPositions[UsableJumpBackEndPositions.Length] = __NFUN_215__(m_Pawn.Location, JumpBackTranslation);
			__NFUN_163__(j);
			// [Loop Continue]
			goto J0x110;
			// End:0x2EB
			if(__NFUN_154__(UsableJumpBackAnimations.Length, 0))
			{
				goto J0x725;
				UsableJumpBackAnimationsToRemove.Remove(0, UsableJumpBackAnimationsToRemove.Length);
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x551
				/*@Error*/
				j = 0;
				// End:0x395
				if(__NFUN_150__(j, UsableJumpBackAnimations.Length))
				{
					// End:0x387
					if(__NFUN_129__(Class'ShockAI.JumpToCeilingGoal'.static.CanJumpToCeiling(ShockAI(), UsableJumpBackEndPositions[j])))
					{
						UsableJumpBackAnimationsToRemove[UsableJumpBackAnimationsToRemove.Length] = j;
						__NFUN_163__(j);
						goto J0x318;
						// End:0x416
						if(__NFUN_154__(UsableJumpBackAnimationsToRemove.Length, UsableJumpBackAnimations.Length))
						{
							// End:0x3EE
							if(Class'ShockAI.JumpToCeilingGoal'.static.CanJumpToCeiling(ShockAI(), m_Pawn.Location))
							{
								goto J0x725;
								goto J0x413;
								// End:0x413
								if(__NFUN_154__(__NFUN_146__(i, 1), RandomNumJumpbacks))
								{
									__NFUN_165__(RandomNumJumpbacks);
									goto J0x551;
									/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
										
									*/

									// End:0x551
									/*@Error*/
									j = __NFUN_147__(UsableJumpBackAnimationsToRemove.Length, 1);
								}
								/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
									
								*/

								// End:0x551
								/*@Error*/
							}
							log('AI', 5, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " JumpBack - UsableJumpBackAnimations.Length: "), string(UsableJumpBackAnimations.Length)), " Removing index: "), string(UsableJumpBackAnimationsToRemove[j])));
						}
						UsableJumpBackAnimations.Remove(UsableJumpBackAnimationsToRemove[j], 1);
						UsableJumpBackEndPositions.Remove(UsableJumpBackAnimationsToRemove[j], 1);
						UsableJumpBackAnimationWeights.Remove(UsableJumpBackAnimationsToRemove[j], 1);
					}
				}
				__NFUN_164__(j);
				goto J0x447;
				assert(__NFUN_151__(UsableJumpBackAnimations.Length, 0));
				assert(__NFUN_154__(UsableJumpBackAnimationWeights.Length, UsableJumpBackAnimations.Length));
				RandomUsableJumpBackAnimationIndex = ChooseJumpbackAnimation(UsableJumpBackAnimationWeights);
				bLastJumpBack = __NFUN_154__(__NFUN_146__(i, 1), RandomNumJumpbacks);
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x5E1
				/*@Error*/
			}
			JumpBackAnimationEndBehavior = Class'Engine.Actor'.1;
			goto J0x5FA;
			JumpBackAnimationEndBehavior = Class'Engine.Actor'.4;
		}
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x64D
	/*@Error*/
	JumpBackAnimationHandle = m_Pawn.PlayAnimationOnChannelFlatEaseIn(0, UsableJumpBackAnimations[RandomUsableJumpBackAnimationIndex], 0.1000000, JumpBackAnimationEndBehavior);
	goto J0x68B;
	JumpBackAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, UsableJumpBackAnimations[RandomUsableJumpBackAnimationIndex], JumpBackAnimationEndBehavior);
	JumpBackAnimLength = m_Pawn.GetAnimationLengthScaled(JumpBackAnimationHandle);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6E5
	/*@Error*/
	m_Pawn.FinishAnimation(JumpBackAnimationHandle);
	goto J0x6F8;
	__NFUN_256__(__NFUN_175__(JumpBackAnimLength, 0.1000000));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x70B
	/*@Error*/
	goto J0x725;
	goto J0x717;
	bFirstJumpBack = false;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0xAF;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x768
	/*@Error*/
	m_Pawn.SmartPerTrackEaseOutAnimation(JumpBackAnimationHandle);
	ShockAI().NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
	bInterrupted = false;
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function NotifyBeginningAttack()
{
	super.NotifyBeginningAttack();
	MoveToActor = Target;
	return;
	@NULL
	EcologyAI
	BioshockMovementAction
}

function NotifyThreatenBegan()
{
	super.NotifyThreatenBegan();
	bWantsToThreaten = true;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x32
	/*@Error*/
	yield();
	// [Loop Continue]
	goto J0x16;
	return;
	@NULL
	EcologyAI
}

function NotifyThreatenEnded()
{
	bWantsToThreaten = false;
	return;
	@NULL
}

function AttackWithSlashWeapon()
{
	local Weapon MeleeWeapon;

	MeleeWeapon = CeilingCrawler(m_Pawn).GetSlashWeapon();
	ShockAI().NotifyFullBodyHitReactionPreventionDesired(self);
	// End:0x9A
	if(__NFUN_119__(CeilingCrawler(m_Pawn).GetActiveHoldable(), MeleeWeapon))
	{
		CeilingCrawler(m_Pawn).Equip(MeleeWeapon);
		CeilingCrawler(m_Pawn).BeginFiring();
		// End:0xE5
		if(__NFUN_130__(__NFUN_129__(bInterrupted), IsAttackingTarget()))
		{
		}
		yield();
		goto J0xBA;
		ShockAI().NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
		bInterrupted = false;
		return;
		@NULL
		EcologyAI
		EcologyFighterCommanderAction
	}
	@NULL
}

function AttackWithMeleeWeapon()
{
	local Weapon MeleeWeapon;

	MeleeWeapon = CeilingCrawler(m_Pawn).GetHandWeapon();
	// End:0x81
	if(__NFUN_119__(CeilingCrawler(m_Pawn).GetActiveHoldable(), MeleeWeapon))
	{
		CeilingCrawler(m_Pawn).Equip(MeleeWeapon);
		CeilingCrawler(m_Pawn).BeginFiring();
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xCC
		/*@Error*/
	}
	yield();
	goto J0xA1;
	bInterrupted = false;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function bool CanAttackWithKickWeapon()
{
	local AIWeapon KickWeapon;

	KickWeapon = CeilingCrawler(m_Pawn).GetKickWeapon();
	assert(__NFUN_119__(KickWeapon, none));
	return __NFUN_130__(__NFUN_129__(CurrentMoveToGoal.bIsMoving), KickWeapon.CanHitTarget(Target, true, false));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function PlayKickMissAnimation(int KickAnimationChannel)
{
	local name KickMissAnimation;

	KickMissAnimation = KickAttackMissAnimations[__NFUN_167__(KickAttackMissAnimations.Length)];
	JumpAttackAnimationHandle = m_Pawn.PlayAnimationOnChannelFlatEaseIn(KickAnimationChannel, KickMissAnimation, 0.1000000);
	m_Pawn.FinishAnimation(JumpAttackAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function AttackWithKickWeapon()
{
	local Weapon KickWeapon;
	local int KickAnimationChannel;
	local name KickAnimation;

	KickWeapon = CeilingCrawler(m_Pawn).GetKickWeapon();
	KickAnimationChannel = CeilingCrawler(m_Pawn).GetAnimationChannelForWeapon(KickWeapon);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x246
	/*@Error*/
	ShockAI().NotifyFullBodyHitReactionPreventionDesired(self);
	EcologyAI(m_Pawn).NotifyDouseReactionPreventionDesired(self);
	KickAnimation = KickAttackInitialAnimations[__NFUN_167__(KickAttackInitialAnimations.Length)];
	JumpAttackAnimationHandle = m_Pawn.PlayAnimationOnChannel(KickAnimationChannel, KickAnimation, Class'Engine.Actor'.4);
	m_Pawn.FinishAnimation(JumpAttackAnimationHandle);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x20C
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1F9
	/*@Error*/
	CeilingCrawler(m_Pawn).Equip(KickWeapon);
	CeilingCrawler(m_Pawn).BeginFiring();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1F6
	/*@Error*/
	yield();
	goto J0x1DC;
	goto J0x20C;
	PlayKickMissAnimation(KickAnimationChannel);
	ShockAI().NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
	EcologyAI(m_Pawn).NotifyDouseReactionPreventionNoLongerDesired(self);
	bInterrupted = false;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function bool IsRangedWeaponReadyToUse()
{
	local AIWeapon RangedWeapon;

	RangedWeapon = CeilingCrawler(m_Pawn).GetRangedWeapon();
	return RangedWeapon.IsReadyToUse();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool CanAttackWithRangedWeapon(bool bUseCurrentRotation)
{
	local AIWeapon RangedWeapon;

	RangedWeapon = CeilingCrawler(m_Pawn).GetRangedWeapon();
	return __NFUN_130__(__NFUN_130__(CeilingCrawler(m_Pawn).CanAttackTargetWithRangedWeapon(Target), __NFUN_132__(__NFUN_132__(m_Pawn.IsOnCeiling(), __NFUN_129__(bUseCurrentRotation)), IsRotatedForAttack())), RangedWeapon.CanHitTarget(Target, bUseCurrentRotation, false));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function float GetEndAttackWithRangedWeaponTime()
{
	// End:0x53
	if(m_Pawn.bUseLocalGravityDirection)
	{
		return __NFUN_174__(Level().TimeSeconds, RandRange(MinTimeToAttackFromCeiling, MaxTimeToAttackFromCeiling));
		goto J0x89;
		return __NFUN_174__(Level().TimeSeconds, RandRange(MinTimeToAttackFromFloor, MaxTimeToAttackFromFloor));
	}
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function AttackWithRangedWeapon()
{
	local AIWeapon RangedWeapon;
	local bool bCanAttack;
	local float DesiredDistanceToMove;

	RangedWeapon = CeilingCrawler(m_Pawn).GetRangedWeapon();
	CeilingCrawler(m_Pawn).Equip(RangedWeapon);
	EndAttackWithRangedWeaponTime = GetEndAttackWithRangedWeaponTime();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2FF
	/*@Error*/
	bCanAttack = CanAttackWithRangedWeapon(true);
	// End:0x22A
	if(bCanAttack)
	{
		// End:0x13D
		if(IsRangedWeaponReadyToUse())
		{
			CeilingCrawler(m_Pawn).BeginFiring();
			// End:0x13D
			if(__NFUN_130__(__NFUN_129__(bInterrupted), IsAttackingTarget()))
			{
				yield();
				goto J0x112;
				// End:0x227
				if(__NFUN_130__(__NFUN_130__(__NFUN_129__(m_Pawn.IsOnCeiling()), __NFUN_129__(CurrentMoveToGoal.bIsMoving)), __NFUN_176__(__NFUN_195__(), ChanceToMoveAfterRangedAttackOnFloor)))
				{
					DesiredDistanceToMove = RandRange(MinDesiredDistanceToMoveAroundWhileTargetUnreachableRange.Min, MinDesiredDistanceToMoveAroundWhileTargetUnreachableRange.Max);
				}
			}
			ShockAI().FindPointToAttackTarget(Target, MoveToActor, 0.0000000, 0.0000000, DesiredDistanceToMove, MaxDistanceToMoveAround, true, 0.0000000, RangedWeapon, true);
			goto J0x2F2;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x2F2
			/*@Error*/
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x2F2
			/*@Error*/
			ShockAI().FindPointToAttackTarget(Target, MoveToActor, 0.0000000, 0.0000000, 0.0000000, MaxDistanceToMoveAround, true, 0.0000000, RangedWeapon, true);
			NextTimeForRangedAttackMovementTest = __NFUN_174__(Level().TimeSeconds, 0.2500000);
		}
	}
	yield();
	// [Loop Continue]
	goto J0x67;
	MoveToActor = Target;
	bInterrupted = false;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function bool HasCeilingAnchor()
{
	local NavigationPoint CurrentAnchor;
	local CeilingPathNode CeilingPathNodeAnchor;
	local CeilingPatrolPoint CeilingPatrolPointAnchor;

	CurrentAnchor = m_Pawn.GetAnchor();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x95
	/*@Error*/
	CeilingPathNodeAnchor = CeilingPathNode(CurrentAnchor);
	CeilingPatrolPointAnchor = CeilingPatrolPoint(CurrentAnchor);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x95
	/*@Error*/
	return true;
	return false;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function AttackTarget()
{
	local bool bUseRangedAttackOnly, bUsedKickAttack;

	bInterrupted = false;
	// End:0x27
	if(CanJumpAttackWithSlashWeapon(true))
	{
		AttackWithSlashWeapon();
		goto J0x74;
		// End:0x4D
		if(CanAttackWithKickWeapon())
		{
		}
		AttackWithKickWeapon();
		bUsedKickAttack = true;
		goto J0x74;
		// End:0x68
		if(CanAttackWithHandWeapon(true))
		{
		}
		AttackWithMeleeWeapon();
		goto J0x74;
		bUseRangedAttackOnly = true;
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2FF
	/*@Error*/
	// End:0xBF
	if(__NFUN_130__(__NFUN_129__(bUsedKickAttack), CanAttackWithKickWeapon()))
	{
		AttackWithKickWeapon();
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x2FF
		/*@Error*/
		bWantsToJumpToCeiling = __NFUN_176__(__NFUN_195__(), ChanceToJumpToCeiling);
	}
	// End:0x197
	if(__NFUN_130__(__NFUN_129__(bUseRangedAttackOnly), __NFUN_179__(__NFUN_219__(__NFUN_216__(Target.Location, m_Pawn.Location), Vector(m_Pawn.Rotation)), 0.0000000)))
	{
		ShockAI().NotifyCeilingVisionDesired();
		JumpBack();
		ShockAI().NotifyCeilingVisionNoLongerDesired();
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x2FF
		/*@Error*/
		bDoingRangedAttack = true;
		// End:0x248
		if(__NFUN_130__(__NFUN_130__(__NFUN_129__(bUseRangedAttackOnly), bWantsToJumpToCeiling), Class'ShockAI.JumpToCeilingGoal'.static.CanJumpToCeiling(ShockAI(), m_Pawn.Location)))
		{
		}
		JumpUp();
		// End:0x27E
		if(CeilingCrawler(m_Pawn).CanAttackTargetWithRangedWeapon(Target))
		{
			AttackWithRangedWeapon();
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x2F3
			/*@Error*/
		}
		DropDown();
		bDoingRangedAttack = false;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x334
		/*@Error*/
	}
	Threaten();
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

defaultproperties
{
	MinNumAttacksBeforeJumpingBack=1
	JumpBackAnimations[0]=(JumpBackAnimation="CR_Backhandspring",JumpBackWeight=1.0000000)
	JumpBackAnimations[1]=(JumpBackAnimation="CR_BackHandspringRIGHT",JumpBackWeight=1.0000000)
	JumpBackAnimations[2]=(JumpBackAnimation="CR_BackHandspringLEFT",JumpBackWeight=1.0000000)
	JumpBackFirstAnimationTweenInTime=0.2500000
	JumpBackLastAnimationTweenOutTime=0.2500000
	MinNumJumpbacks=1
	MaxNumJumpbacks=3
	ChanceToJumpToCeiling=0.7500000
	ChanceToDropDownImmediately=0.5000000
	ChanceToMoveAfterRangedAttackOnFloor=1.0000000
	MinDesiredDistanceToMoveAroundWhileTargetUnreachableRange=(Min=200.0000000,Max=500.0000000)
	MaxDistanceToMoveAround=2000.0000000
	KickAttackInitialAnimations[0]="CR_AttackMelee_F_start"
	KickAttackMissAnimations[0]="CR_AttackMelee_F_miss"
	MinTimeToAttackFromCeiling=2.0000000
	MaxTimeToAttackFromCeiling=4.0000000
	MinTimeToAttackFromFloor=2.0000000
	MaxTimeToAttackFromFloor=4.0000000
	MinKickPushPlayerReactionRotation=(Pitch=-6371,Yaw=-6371,Roll=0)
	MaxKickPushPlayerReactionRotation=(Pitch=-2731,Yaw=-2731,Roll=0)
	KickPushPlayerPushMagnitude=1000.0000000
	KickPushTargetPlayerMoveReactionDuration=0.5000000
	KickPushTargetPlayerRotateReactionDuration=0.2500000
	KickPushFOV=60.0000000
	KickPushDistance=250.0000000
	AIThreatenChance=0.5000000
	PlayerWithWrenchEquippedThreatenChance=0.2500000
	PlayerWithoutWrenchEquippedThreatenChance=0.0500000
	ThreatenAnimations[0]="CR_initialReaction_A"
	MimicAttackInfos[0]=(MimicPoseAnimationName="CR_PlayDeadBack_POSE",ForwardAttackAnimationName="CR_getUpBack_D",LeftAttackAnimationName="CR_getUpBack_D",RightAttackAnimationName="CR_getUpBack_D",BackwardAttackAnimationName="CR_getUpBack_D")
	MimicAttackInfos[1]=(MimicPoseAnimationName="CR_PlayDeadStomach_POSE",ForwardAttackAnimationName="CR_getUpStomach_D",LeftAttackAnimationName="CR_getUpStomach_D",RightAttackAnimationName="CR_getUpStomach_D",BackwardAttackAnimationName="CR_getUpStomach_D")
	InitialReactionAnimations[0]="CR_initialReaction_A"
	InitialReactionChance=1.0000000
	AttackBehaviorAllowedYawRotationErrorTwoByte=5461
}