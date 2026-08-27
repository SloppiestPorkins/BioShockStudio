class AggressorAttackAction extends CharacterAttackAction
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

struct native atomic MimicAttackInfo
{
	var config name MimicPoseAnimationName;
	var config name ForwardAttackAnimationName;
	var config name LeftAttackAnimationName;
	var config name RightAttackAnimationName;
	var config name BackwardAttackAnimationName;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

var private int ThreatenAnimationHandle;
var private config float AIThreatenChance;
var private config float PlayerWithWrenchEquippedThreatenChance;
var private config float PlayerWithoutWrenchEquippedThreatenChance;
var private config float ThreatenDistanceRange;
var private config Range TimeRangeBetweenThreatens;
var private config float ThreatenIgnoreDamageTime;
var private float NextThreatenTime;
var config array<name> ThreatenAnimations;
var private config float RequiredThreatenAngleDegrees;
var config array<MimicAttackInfo> MimicAttackInfos;
var config float MimicAttackFrontOrBackDegrees;
var private int MimicAttackAnimationHandle;
var private float NextTimeShouldNotifyAggressorsAttacking;
var config float TimeBetweenAggressorAttackingNotifications;

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
	// End:0x4D
	if(m_Pawn.IsAnimationHandleValid(MimicAttackAnimationHandle))
	{
		m_Pawn.SmartPerTrackEaseOutAnimation(MimicAttackAnimationHandle);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x90
		/*@Error*/
		m_Pawn.SmartPerTrackEaseOutAnimation(ThreatenAnimationHandle);
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

protected function OnInitialReactionFinished()
{
	ResetThreatenTime();
	return;
}

function ResetThreatenTime()
{
	NextThreatenTime = __NFUN_174__(Level().TimeSeconds, RandRange(TimeRangeBetweenThreatens.Min, TimeRangeBetweenThreatens.Max));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

// Export UAggressorAttackAction::execIsThreatening(FFrame&, void* const)
protected native function bool IsThreatening();

function bool PassesThreatenChance()
{
	local Weapon TargetsActiveWeapon;

	// End:0x12
	if(ShouldIgnoreThreatenChance())
	{
		return true;		
	}
	else
	{
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xD1
		/*@Error*/
		TargetsActiveWeapon = Weapon(Target.GetActiveHoldable());
		// End:0xC0
		if(__NFUN_130__(__NFUN_130__(Target.GetHands().InWeaponsMode(), __NFUN_119__(TargetsActiveWeapon, none)), TargetsActiveWeapon.__NFUN_303__('Wrench')))
		{
			return __NFUN_176__(__NFUN_195__(), PlayerWithWrenchEquippedThreatenChance);
			goto J0xCE;
			return __NFUN_176__(__NFUN_195__(), PlayerWithoutWrenchEquippedThreatenChance);
			goto J0xDF;
			return __NFUN_176__(__NFUN_195__(), AIThreatenChance);
			return false;
			return;
			@NULL
		}
		CommanderAction
		EcologyFighterCommanderAction
		@NULL
	}
}

function bool ShouldThreaten()
{
	return __NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_179__(Level().TimeSeconds, NextThreatenTime), PassesThreatenChance()), __NFUN_129__(HasBeenDamagedByTargetRecently(ThreatenIgnoreDamageTime))), IsPointWithinCylinder(Target.Location, m_Pawn.Location, DistanceFromTargetToDoInitialReactionRange.Max, __NFUN_171__(m_Pawn.CollisionHeight, 4.0000000))), __NFUN_129__(IsPointWithinCylinder(Target.Location, m_Pawn.Location, DistanceFromTargetToDoInitialReactionRange.Min, __NFUN_171__(m_Pawn.CollisionHeight, 2.0000000)))), Class'ShockAI.MoveToAction'.static.IsRotatedTo(m_Pawn.Rotation, Rotator(__NFUN_216__(Target.Location, m_Pawn.Location)), int(__NFUN_171__(RequiredThreatenAngleDegrees, 182.0444489)))), m_Pawn.LineOfSightTo(Target));
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

protected function bool ShouldIgnoreThreatenChance()
{
	return false;
	return;
}

protected latent function NotifyThreatenBegan()
{
	return;
}

protected latent function NotifyThreatenEnded()
{
	return;
}

function Threaten()
{
	local float ThreatenAnimLength;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xA3
	/*@Error*/
	NotifyThreatenBegan();
	ThreatenAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, ThreatenAnimations[__NFUN_167__(ThreatenAnimations.Length)]);
	ThreatenAnimLength = m_Pawn.GetAnimationLengthScaled(ThreatenAnimationHandle);
	__NFUN_256__(__NFUN_175__(ThreatenAnimLength, 0.2500000));
	ResetThreatenTime();
	NotifyThreatenEnded();
	return;
	@NULL
	EcologyAI
	BioshockMovementAction
	@NULL
}

function NotifyGoingToStartAttacking()
{
	super.NotifyGoingToStartAttacking();
	SpawningManager(Level().SpawningManager).NotifyAggressorIsAttacking(Aggressor(m_Pawn), Target);
	return;
	@NULL
	EcologyAI
	BioshockMovementAction
	@NULL
}

function bool ShouldPlayInitialReaction()
{
	return __NFUN_130__(__NFUN_129__(Aggressor(m_Pawn).ShouldStartOutAsMimic()), super.ShouldPlayInitialReaction());
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function NotifyBeginningAttack()
{
	super.NotifyBeginningAttack();
	// End:0x37
	if(Aggressor(m_Pawn).IsMimic())
	{
		GetUpAsMimic();
		return;
		@NULL
		EcologyAI
	}
	BioshockMovementAction
}

function GetUpAsMimic()
{
	m_Pawn.TriggerEffectEvent('AggressorAlive');
	ShockAI().PlaySpeech('MimicWokeUp');
	Aggressor(m_Pawn).SetIsMimic(false);
	AttackFromMimic();
	return;
	@NULL
	EcologyAI
	BioshockMovementAction
}

function AttackFromMimic()
{
	local PoseData MimicInitialPose;
	local int i;

	MimicInitialPose = Aggressor(m_Pawn).GetMimicInitialPose();
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xBE
	/*@Error*/
	J0x35:

	// End:0xB0 [Loop If]
	if(__NFUN_254__(MimicAttackInfos[i].MimicPoseAnimationName, MimicInitialPose.AnimationName))
	{
		PlayMimicAttackAnimation(MimicAttackInfos[i]);
		goto J0xBE;
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x35;
		return;
		@NULL
		EcologyAI
		EcologyFighterCommanderAction
		@NULL
	}
}

function name GetMimicAttackAnimation(MimicAttackInfo AppropriateMimicAttackInfo)
{
	local ShockAI.EDirection AttackDirection;

	AttackDirection = Class'ShockAI.ShockAI'.static.GetDirectionForPoint(m_Pawn.Rotation, __NFUN_226__(__NFUN_216__(Target.Location, m_Pawn.Location)), MimicAttackFrontOrBackDegrees);
	switch(AttackDirection)
	{
		// End:0x9B
		case 2:
			return AppropriateMimicAttackInfo.LeftAttackAnimationName;
			// End:0xBB
			case 3:
				return AppropriateMimicAttackInfo.RightAttackAnimationName;
				// End:0xDB
				case 1:
					return AppropriateMimicAttackInfo.BackwardAttackAnimationName;
					// End:0xE0
					case 0:
						// End:0xFFFF
						default:
							return AppropriateMimicAttackInfo.ForwardAttackAnimationName;
							break;
					}/* !MISMATCHING REMOVE, tried Switch got Type:Case Position:0x08F! */
				return;
				@NULL
				CommanderAction
				EcologyFighterCommanderAction
				@NULL/* !MISMATCHING REMOVE, tried Case got Type:Switch Position:0x04C! */
}

function PlayMimicAttackAnimation(MimicAttackInfo AppropriateMimicAttackInfo)
{
	local name MimicAttackAnimation;

	MimicAttackAnimation = GetMimicAttackAnimation(AppropriateMimicAttackInfo);
	log('AI', 4, __NFUN_112__("MimicAttackAnimation: ", string(MimicAttackAnimation)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB4
	/*@Error*/
	MimicAttackAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, MimicAttackAnimation);
	m_Pawn.FinishAnimation(MimicAttackAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

defaultproperties
{
	TimeRangeBetweenThreatens=(Min=5.0000000,Max=10.0000000)
	ThreatenIgnoreDamageTime=2.0000000
	RequiredThreatenAngleDegrees=30.0000000
	MimicAttackFrontOrBackDegrees=45.0000000
	TimeBetweenAggressorAttackingNotifications=0.5000000
	DistanceFromTargetToDoInitialReactionRange=(Min=500.0000000,Max=1200.0000000)
}