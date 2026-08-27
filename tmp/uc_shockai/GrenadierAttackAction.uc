class GrenadierAttackAction extends AggressorAttackAction
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

const kLastBumpedTargetRecentlyTime = 0.25;
const kMinTimeBetweenStartingFleesAfterBumping = 1.0;
const kMinTimeToTryFleeingAfterFailure = 2.0;

var private bool bFleeing;
var private bool bFinishedFleeing;
var private bool bChoseFleePoint;
var private bool bDropLiveGrenade;
var private bool bDroppedGrenade;
var private bool bMoveAfterAttack;
var private bool bHasMovedOnce;
var private bool m_PreviousCanHitWithGrenadeWeapon;
var private float LastTimeFleeingFailed;
var private float FinishFleeingTime;
var private int NumTimesAttackedWithGrenadeInARow;
var private float TimeToDropLiveGrenade;
var private float LastTimeBumpedTargetRecently;
var private float RangedWeaponDistance;
var private float NextTimeForFindPointToAttackTest;
var private float NextTimeCanFlee;
var private float NextGrenadeWeaponCheckTime;
var private float m_GrenadeCheckTimer;
var private float m_NextAttackMoveCheck;
var private float m_NextAttackMoveCheckTimer;
var config float ChanceToMoveAfterRangedAttack;
var config float ChanceToDropLiveGrenade;
var config Range TimeToDropLiveGrenadeRange;
var config float MinPathfindingDistanceToFlee;
var config Range FleeingStopRange;
var config float FleeDistance;
var config float FleeDistanceZHeight;
var config float FleeClosestApproach;
var config Range LocalDistanceToMoveAfterAttack;
var config float RepositionClosestApproach;
var config Range RepositionMoveRange;
var config float RepositionMinDistanceToTarget;
var config float MinTimeBetweenFindPointToAttackTests;
var config float MinTimeBetweenFleeing;
var config float MeleePushFOV;
var config float MeleePushDistance;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super.initAction(R, Goal);
	MoveToPoint = m_Pawn.Location;
	Grenadier(m_Pawn).__OnPushGetPushee__Delegate = OnPushGetPushee;
	RangedWeaponDistance = IProvideProjectileDamageData(ShockGameInfo(m_Pawn.Level.Game).GetItemFromClass(GetRangedWeapon().GetDefaultAmmoSelection())).GetAttackRange();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	super.Cleanup();
	ShockAI().SetAvoidTarget(none);
	Grenadier(m_Pawn).__OnPushGetPushee__Delegate = None;
	ShockAI().NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
	ShockAI().NotifyFallDownHitReactionPreventionNoLongerDesired(self);
	m_Pawn.UnTriggerEffectEvent('BecameImmuneToFrozenState');
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnDamagedByTarget()
{
	super(CharacterAttackAction).OnDamagedByTarget();
	// End:0x30
	if(__NFUN_130__(bFleeing, bFinishedFleeing))
	{
		StopFleeing();
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function Actor OnPushGetPushee()
{
	local Vector DirectionToTarget, OffsetToTarget;

	OffsetToTarget = __NFUN_216__(Target.Location, m_Pawn.Location);
	DirectionToTarget = __NFUN_226__(OffsetToTarget);
	log('AI', 5, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " OnPushGetPushee - Distance: "), string(__NFUN_225__(OffsetToTarget))), " MeleePushDistance: "), string(MeleePushDistance)), "  Dot: "), string(__NFUN_219__(Vector(m_Pawn.Rotation), DirectionToTarget))), " Required DOT: "), string(__NFUN_188__(__NFUN_171__(MeleePushFOV, 0.0174533)))));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x184
	/*@Error*/
	return Target;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyFinishedDodging()
{
	super(CharacterAttackAction).NotifyFinishedDodging();
	MoveToPoint = m_Pawn.Location;
	MoveToActor = none;
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

// Export UGrenadierAttackAction::execShouldStopMovingToTarget(FFrame&, void* const)
native function bool ShouldStopMovingToTarget();

function GetUpdatedDestination(out Actor outDestinationActor, out Vector outDestinationLocation)
{
	//native.outDestinationActor;
	//native.outDestinationLocation;	
	@NULL
	@NULL
}

// Export UGrenadierAttackAction::execIsShortMovement(FFrame&, void* const)
private native function bool IsShortMovement();

function bool GetDesiredRotationOverride(out Rotator DesiredRotation)
{
	//native.DesiredRotation;	
	@NULL
}

function OnMoveStarted()
{
	super(CharacterAttackAction).OnMoveStarted();
	bHasMovedOnce = true;
	return;
	@NULL
	CommanderAction
}

function OnMoveEnded()
{
	super(CharacterAttackAction).OnMoveEnded();
	// End:0x3C
	if(bMoveAfterAttack)
	{
		ShockAI().SetAvoidTarget(none);
		bMoveAfterAttack = false;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xB6
		/*@Error*/
		bFinishedFleeing = true;
	}
	FinishFleeingTime = __NFUN_174__(Level().TimeSeconds, RandRange(FleeingStopRange.Min, FleeingStopRange.Max));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyCannotFindWayToDestination()
{
	super(CharacterAttackAction).NotifyCannotFindWayToDestination();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4D
	/*@Error*/
	Grenadier(m_Pawn).CancelSpecialCommitSuicideState();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function AIMeleeWeapon GetMeleeWeapon()
{
	return Grenadier(m_Pawn).GetMeleeWeapon();
	return;
	@NULL
	CommanderAction
}

function AIRangedWeapon GetRangedWeapon()
{
	return Grenadier(m_Pawn).GetGrenadeWeapon();
	return;
	@NULL
	CommanderAction
}

function AIWeapon GetSuicideWeapon()
{
	return Grenadier(m_Pawn).GetSuicideWeapon();
	return;
	@NULL
	CommanderAction
}

function AIRangedWeapon GetSmokeWeapon()
{
	return Grenadier(m_Pawn).GetSmokeGrenadeWeapon();
	return;
	@NULL
	CommanderAction
}

function AIRangedWeapon GetLiveGrenadeWeapon()
{
	return Grenadier(m_Pawn).GetLiveGrenadeWeapon();
	return;
	@NULL
	CommanderAction
}

function bool CanHitWithMeleeWeapon(bool bUseCurrentRotation)
{
	//native.bUseCurrentRotation;	
	@NULL
}

// Export UGrenadierAttackAction::execCanAttackWithMeleeWeapon(FFrame&, void* const)
native function bool CanAttackWithMeleeWeapon();

// Export UGrenadierAttackAction::execCanAttackWithGrenadeWeapon(FFrame&, void* const)
native function bool CanAttackWithGrenadeWeapon();

// Export UGrenadierAttackAction::execCanAttackWithSuicideWeapon(FFrame&, void* const)
native function bool CanAttackWithSuicideWeapon();

// Export UGrenadierAttackAction::execCanAttackTarget(FFrame&, void* const)
native function bool CanAttackTarget();

// Export UGrenadierAttackAction::execCanFlee(FFrame&, void* const)
native function bool CanFlee();

// Export UGrenadierAttackAction::execShouldFlee(FFrame&, void* const)
native function bool ShouldFlee();

// Export UGrenadierAttackAction::execStopFleeing(FFrame&, void* const)
private native function StopFleeing();

function bool ShouldPlayInitialReaction()
{
	return __NFUN_130__(__NFUN_129__(Grenadier(m_Pawn).HasSpecialCommitSuicideState()), super.ShouldPlayInitialReaction());
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function bool ShouldThreaten()
{
	// End:0x33
	if(__NFUN_129__(Grenadier(m_Pawn).HasSpecialCommitSuicideState()))
	{
		return super.ShouldThreaten();
		goto J0x35;
		return false;
		return;
		@NULL
		CommanderAction
	}
	J0x35:

	BioshockMovementAction
}

function DropLiveGrenadeWhileFleeing()
{
	local AIWeapon LiveGrenadeWeapon;

	LiveGrenadeWeapon = GetLiveGrenadeWeapon();
	LiveGrenadeWeapon.SetNextUsableAttackInfo(0, Rotator(__NFUN_211__(__NFUN_226__(m_Pawn.PhysicsVolume.Gravity))), Target);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB5
	/*@Error*/
	Grenadier(m_Pawn).Equip(LiveGrenadeWeapon);
	UseCurrentWeapon(LiveGrenadeWeapon);
	bDroppedGrenade = true;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function DropSmokeGrenadeBeforeFleeing()
{
	local AIWeapon SmokeGrenadeWeapon;

	SmokeGrenadeWeapon = GetSmokeWeapon();
	SmokeGrenadeWeapon.SetNextUsableAttackInfo(0, Rotator(__NFUN_226__(m_Pawn.PhysicsVolume.Gravity)), Target);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB3
	/*@Error*/
	Grenadier(m_Pawn).Equip(SmokeGrenadeWeapon);
	UseCurrentWeapon(SmokeGrenadeWeapon);
	bDroppedGrenade = true;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function Flee()
{
	// End:0x6E
	if(bDropLiveGrenade)
	{
		TimeToDropLiveGrenade = __NFUN_174__(Level().TimeSeconds, RandRange(TimeToDropLiveGrenadeRange.Min, TimeToDropLiveGrenadeRange.Max));
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x1B2
		/*@Error*/
		log('AI', 5, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " is fleeing - bDropLiveGrenade: "), string(bDropLiveGrenade)), " bDroppedGrenade: "), string(bDroppedGrenade)));
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x169
	/*@Error*/
	// End:0x15F
	if(bDropLiveGrenade)
	{
		// End:0x15C
		if(__NFUN_130__(__NFUN_177__(__NFUN_225__(m_Pawn.GetVelocity()), 0.0000000), __NFUN_179__(Level().TimeSeconds, TimeToDropLiveGrenade)))
		{
			DropLiveGrenadeWhileFleeing();
			goto J0x169;
			DropSmokeGrenadeBeforeFleeing();
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x1A5
			/*@Error*/
			StopFleeing();
			yield();
			// [Loop Continue]
			goto J0x6E;
			return;
			@NULL
		}
		EcologyAI
	}
	EcologyFighterCommanderAction
	@NULL
}

function NotifyFinishedAttackingTarget()
{
	super(CharacterAttackAction).NotifyFinishedAttackingTarget();
	// End:0x24
	if(bFleeing)
	{
		Flee();
		goto J0x4D;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x4D
		/*@Error*/
	}
	Threaten();
	return;
	@NULL
	EcologyAI
}

function AttackTarget()
{
	local AIWeapon DesiredWeapon;
	local bool bAttackingWithMeleeWeapon, bNotAttacking, bIsRotatedForAttack;

	bIsRotatedForAttack = IsRotatedForAttack();
	// End:0xE7
	if(__NFUN_132__(Grenadier(m_Pawn).ShouldCommittSuicideImmediately(), CanAttackWithSuicideWeapon()))
	{
		DesiredWeapon = GetSuicideWeapon();
		DesiredWeapon.SetNextUsableAttackInfo(0, m_Pawn.Rotation, Target);
		ShockAI().NotifyFullBodyHitReactionPreventionDesired(self);
		ShockAI().NotifyFallDownHitReactionPreventionDesired(self);
		m_Pawn.TriggerEffectEvent('BecameImmuneToFrozenState');
		goto J0x188;
		// End:0x126
		if(__NFUN_130__(bIsRotatedForAttack, CanAttackWithMeleeWeapon()))
		{
			DesiredWeapon = GetMeleeWeapon();
		}
		bAttackingWithMeleeWeapon = true;
		goto J0x188;
		// End:0x142
		if(ShouldFlee())
		{
			bNotAttacking = true;
			goto J0x188;
			assert(bIsRotatedForAttack);
			assert(CanAttackWithGrenadeWeapon());
			DesiredWeapon = GetRangedWeapon();
		}
		bMoveAfterAttack = __NFUN_178__(__NFUN_195__(), ChanceToMoveAfterRangedAttack);
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x201
	/*@Error*/
	// End:0x1EE
	if(__NFUN_119__(Grenadier(m_Pawn).GetActiveHoldable(), DesiredWeapon))
	{
		Grenadier(m_Pawn).Equip(DesiredWeapon);
		UseCurrentWeapon(DesiredWeapon);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x265
		/*@Error*/
		bDroppedGrenade = false;
		bFleeing = true;
		bChoseFleePoint = false;
		bFinishedFleeing = false;
		bDropLiveGrenade = __NFUN_178__(__NFUN_195__(), ChanceToDropLiveGrenade);
		return;
		@NULL
		EcologyAI
	}
	CommanderAction
	@NULL
}

defaultproperties
{
	m_GrenadeCheckTimer=0.2500000
	m_NextAttackMoveCheckTimer=0.2500000
	ChanceToMoveAfterRangedAttack=0.3000000
	ChanceToDropLiveGrenade=0.5000000
	TimeToDropLiveGrenadeRange=(Min=0.7500000,Max=1.5000000)
	MinPathfindingDistanceToFlee=1500.0000000
	FleeingStopRange=(Min=2.0000000,Max=5.0000000)
	FleeDistance=500.0000000
	FleeDistanceZHeight=300.0000000
	FleeClosestApproach=500.0000000
	LocalDistanceToMoveAfterAttack=(Min=100.0000000,Max=400.0000000)
	RepositionClosestApproach=250.0000000
	RepositionMoveRange=(Min=200.0000000,Max=2000.0000000)
	RepositionMinDistanceToTarget=300.0000000
	MinTimeBetweenFindPointToAttackTests=0.5000000
	MinTimeBetweenFleeing=3.0000000
	MeleePushFOV=60.0000000
	MeleePushDistance=125.0000000
	AIThreatenChance=0.2500000
	PlayerWithWrenchEquippedThreatenChance=0.2500000
	PlayerWithoutWrenchEquippedThreatenChance=0.0500000
	ThreatenAnimations[0]="GR_Threaten_B"
	ThreatenAnimations[1]="GR_Threaten_D"
	MimicAttackInfos[0]=(MimicPoseAnimationName="GR_PlayDeadBack_Pose",ForwardAttackAnimationName="GR_getUpBack_B",LeftAttackAnimationName="GR_getUpBack_B",RightAttackAnimationName="GR_getUpBack_B",BackwardAttackAnimationName="GR_getUpBack_B")
	MimicAttackInfos[1]=(MimicPoseAnimationName="GR_PlayDeadStomach_Pose",ForwardAttackAnimationName="GR_getUpStomach_A",LeftAttackAnimationName="GR_getUpStomach_A",RightAttackAnimationName="GR_getUpStomach_A",BackwardAttackAnimationName="GR_getUpStomach_A")
	bCanDodgeWhileAttacking=true
	MinCanTargetHitBeforeDodgeTime=0.2500000
	MinDodgeTime=8.0000000
	DodgeChance=0.2500000
	DodgeFacingAngleDegrees=30.0000000
	InitialReactionAnimations[0]="GR_Threaten_B"
	InitialReactionChance=1.0000000
}