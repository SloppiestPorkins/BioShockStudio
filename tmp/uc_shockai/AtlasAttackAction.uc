class AtlasAttackAction extends AggressorAttackAction
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

const MAX_CHARGE_RANGE = 3000.0f;

var private ChargeAttackGoal CurrentChargeGoal;
var private bool bRepositioning;
var private int NumMeleeAttacks;
var private int NumRangedAttacks;
var private float MeleeAttackRange;
var private float RangedAttackRange;
var config float CloseToMeleeRange;
var config float MinDistanceToApproachTarget;
var config Range LocalDistanceRangeForAttack;
var config float PreferredRange;
var config float MaxRepositioningRange;
var config float RepositioningRangeToNotFaceTarget;
var config int NumMeleeAttacksBeforeRepositioning;
var config int NumRangedAttacksBeforeRepositioning;
var config name ChargeTelegraphAnimationName;
var config name ChargeLoopAnimationName;
var config name ChargeEndAnimationName;
var config name ChargeEndFacingTargetAnimationName;
var config name ChargeHitAnimationName;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super.initAction(R, Goal);
	assert(__NFUN_119__(Level(), none));
	assert(__NFUN_119__(m_Pawn, none));
	MeleeAttackRange = IProvideMeleeDamageData(ShockGameInfo(Level().Game).GetItemFromClass(GetMeleeWeapon().GetDefaultAmmoSelection())).GetAttackRange();
	RangedAttackRange = IProvideProjectileDamageData(ShockGameInfo(Level().Game).GetItemFromClass(GetRangedWeapon().GetDefaultAmmoSelection())).GetAttackRange();
	Atlas(m_Pawn).__OnPushGetPushee__Delegate = OnPushGetPushee;
	ShockAI().QuickLook(Target);
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
	if(__NFUN_119__(CurrentChargeGoal, none))
	{
		CurrentChargeGoal.__NFUN_198__();
		CurrentChargeGoal = none;
		Atlas(m_Pawn).__OnPushGetPushee__Delegate = None;
	}
	ShockAI().StopTracking();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

// Export UAtlasAttackAction::execIsChargingOrPreparingToCharge(FFrame&, void* const)
native function bool IsChargingOrPreparingToCharge();

// Export UAtlasAttackAction::execIsCharging(FFrame&, void* const)
native function bool IsCharging();

// Export UAtlasAttackAction::execShouldStopMovingToTarget(FFrame&, void* const)
native function bool ShouldStopMovingToTarget();

function GetUpdatedDestination(out Actor outDestinationActor, out Vector outDestinationLocation)
{
	//native.outDestinationActor;
	//native.outDestinationLocation;	
	@NULL
	@NULL
}

function bool GetDesiredRotationOverride(out Rotator DesiredRotation)
{
	//native.DesiredRotation;	
	@NULL
}

// Export UAtlasAttackAction::execGetMinDistanceToApproachTarget(FFrame&, void* const)
private native function float GetMinDistanceToApproachTarget();

// Export UAtlasAttackAction::execIsWithinRangeForMeleeWeapon(FFrame&, void* const)
native function bool IsWithinRangeForMeleeWeapon();

function bool CanHitWithMeleeWeapon(bool bUseCurrentRotation)
{
	//native.bUseCurrentRotation;	
	@NULL
}

// Export UAtlasAttackAction::execCanAttackWithMeleeWeapon(FFrame&, void* const)
native function bool CanAttackWithMeleeWeapon();

function bool CanHitWithRangedWeapon(bool bUseCurrentRotation)
{
	//native.bUseCurrentRotation;	
	@NULL
}

// Export UAtlasAttackAction::execCanAttackWithRangedWeapon(FFrame&, void* const)
native function bool CanAttackWithRangedWeapon();

// Export UAtlasAttackAction::execCanAttackTarget(FFrame&, void* const)
native function bool CanAttackTarget();

function AIRangedWeapon GetRangedWeapon()
{
	return Atlas(m_Pawn).GetRangedWeapon();
	return;
	@NULL
	CommanderAction
}

function AIMeleeWeapon GetMeleeWeapon()
{
	return Atlas(m_Pawn).GetMeleeWeapon();
	return;
	@NULL
	CommanderAction
}

function NotifyGoingToStartAttacking()
{
	super.NotifyGoingToStartAttacking();
	bRepositioning = false;
	return;
	@NULL
	EcologyAI
}

function NotifyCannotFindWayToDestination()
{
	bRepositioning = false;
	return;
	@NULL
}

function NotifyBeginningAttack()
{
	super.NotifyBeginningAttack();
	Threaten();
	return;
	@NULL
}

function NotifyFinishedAttackingTarget()
{
	// End:0x55
	if(__NFUN_130__(CanCharge(Target.Location), ShouldCharge()))
	{
		ChargeAttack();
		NumMeleeAttacks = 0;
		NumRangedAttacks = 0;
		goto J0x27D;
		// End:0x161
		if(__NFUN_153__(NumMeleeAttacks, NumMeleeAttacksBeforeRepositioning))
		{
			// End:0x15E
			if(ShockAI().FindPointToAttackTarget(Target, MoveToActor, MeleeAttackRange, RangedAttackRange, 150.0000000))
			{
			}
			log('AI', 4, __NFUN_168__(__NFUN_168__("Atlas repositioning at melee, new dest is", string(__NFUN_225__(__NFUN_216__(m_Pawn.Location, MoveToActor.Location)))), "units away."));
			bRepositioning = true;
			NumMeleeAttacks = 0;
			ShockAI().SetAvoidTarget(none);
			goto J0x266;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x266
			/*@Error*/
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x266
			/*@Error*/
		}
	}
	log('AI', 4, __NFUN_168__(__NFUN_168__("Atlas repositioning at range, new dest is", string(__NFUN_225__(__NFUN_216__(m_Pawn.Location, MoveToActor.Location)))), "units away."));
	bRepositioning = true;
	NumRangedAttacks = 0;
	ShockAI().SetAvoidTarget(none);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x27D
	/*@Error*/
	Threaten();
	return;
	@NULL
	EcologyAI
	BioshockMovementAction
	@NULL
}

function NotifyAttackCompleted()
{
	local Pawn Player;

	Player = m_Pawn.Level.GetLocalPlayerController().Pawn;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x89
	/*@Error*/
	ShockAI().PlaySpeech('TauntedPlayer');
	super(CharacterAttackAction).NotifyAttackCompleted();
	return;
	@NULL
	EcologyAI
	BioshockMovementAction
	@NULL
}

function AttackTarget()
{
	local AIWeapon CurrentWeapon;

	// End:0x66
	if(__NFUN_132__(CanAttackWithMeleeWeapon(), IsCloseToMeleeRange()))
	{
		// End:0x4F
		if(ShockAI().IsAimingWeapon())
		{
			ShockAI().StopAimingWeapon();
		}
		CurrentWeapon = GetMeleeWeapon();
		goto J0x7A;
		CurrentWeapon = GetRangedWeapon();
	}
	// End:0xD1
	if(__NFUN_119__(Atlas(m_Pawn).GetActiveHoldable(), CurrentWeapon))
	{
		Atlas(m_Pawn).Equip(CurrentWeapon);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x152
		/*@Error*/
	}
	UseCurrentWeapon(CurrentWeapon);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x13C
	/*@Error*/
	__NFUN_163__(NumMeleeAttacks);
	NumRangedAttacks = 0;
	goto J0x152;
	__NFUN_163__(NumRangedAttacks);
	NumMeleeAttacks = 0;
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

// Export UAtlasAttackAction::execIsCloseToMeleeRange(FFrame&, void* const)
native function bool IsCloseToMeleeRange();

// Export UAtlasAttackAction::execIsWithinChargeRange(FFrame&, void* const)
native function bool IsWithinChargeRange();

// Export UAtlasAttackAction::execIsWithinPreferredRange(FFrame&, void* const)
native function bool IsWithinPreferredRange();

function bool CanCharge(Vector ChargeDestination)
{
	return m_Pawn.FarPointReachable(ChargeDestination, 3000.0000000);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
}

function bool ShouldCharge()
{
	return __NFUN_130__(__NFUN_130__(__NFUN_129__(IsChargingOrPreparingToCharge()), __NFUN_129__(IsCloseToMeleeRange())), __NFUN_176__(__NFUN_195__(), Atlas(m_Pawn).ChargeChance));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
}

function ChargeAttack()
{
	ShockAI().PlaySpeech('AtlasCharge');
	CurrentChargeGoal = Class'ShockAI.ChargeAttackGoal'.static.Allocate(self).;
	construct_AI_ResourceActorNameNameNameNameName(characterResource(), Target, ChargeTelegraphAnimationName, ChargeLoopAnimationName, ChargeEndAnimationName, ChargeEndFacingTargetAnimationName, ChargeHitAnimationName);
	CurrentChargeGoal.__NFUN_199__();
	CurrentChargeGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentChargeGoal);
	CurrentChargeGoal.unPostGoal(self);
	CurrentChargeGoal.__NFUN_198__();
	CurrentChargeGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function Actor OnPushGetPushee()
{
	// End:0x1A
	if(IsChargingOrPreparingToCharge())
	{
		return Target;
		goto J0x1C;
		return none;
		return;
	}
	@NULL
}

defaultproperties
{
	bRepositioning=true
	CloseToMeleeRange=550.0000000
	MinDistanceToApproachTarget=350.0000000
	LocalDistanceRangeForAttack=(Min=200.0000000,Max=400.0000000)
	PreferredRange=1200.0000000
	MaxRepositioningRange=1000.0000000
	RepositioningRangeToNotFaceTarget=400.0000000
	NumMeleeAttacksBeforeRepositioning=2
	NumRangedAttacksBeforeRepositioning=3
	ChargeTelegraphAnimationName="AT_chargewindup"
	ChargeLoopAnimationName="AT_charge"
	ChargeEndAnimationName="AT_chargeend"
	ChargeEndFacingTargetAnimationName="AT_chargeendNoTurn"
	ChargeHitAnimationName="AT_chargeendhit"
	AIThreatenChance=0.8000000
	PlayerWithWrenchEquippedThreatenChance=0.5000000
	PlayerWithoutWrenchEquippedThreatenChance=0.0500000
	ThreatenAnimations[0]="AT_Threaten_A"
	RequiredThreatenAngleDegrees=15.0000000
}