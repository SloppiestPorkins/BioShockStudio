class SPFAttackAction extends ProtectorAttackAction
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private int KneelAnimationHandle;
var private float MeleeAttackRange;
var private bool bShouldFireAtLastKnownLocation;
var private bool bFireAtLastKnownLocation;
var private bool bHasBeenAbleToAttack;
var private bool bMoveAfterBeingAttacked;
var private config name KneelDownAnimation;
var private config name GetUpFromKneelAnimation;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super.initAction(R, Goal);
	assert(__NFUN_119__(Level(), none));
	assert(__NFUN_119__(m_Pawn, none));
	MeleeAttackRange = IProvideMeleeDamageData(ShockGameInfo(Level().Game).GetItemFromClass(SPF(m_Pawn).GetMeleeWeapon().GetDefaultAmmoSelection())).GetAttackRange();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	super.Cleanup();
	// End:0x3D
	if(ShockAI().IsAimingWeapon())
	{
		ShockAI().StopAimingWeapon();
		// End:0x80
		if(m_Pawn.IsAnimationHandleValid(KneelAnimationHandle))
		{
		}
		m_Pawn.SmartPerTrackEaseOutAnimation(KneelAnimationHandle);
		Protector(m_Pawn).NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
		Protector(m_Pawn).NotifyFallDownHitReactionPreventionNoLongerDesired(self);
	}
	ShockAI().AddLocomotionKeyword('Kneeling', Class'ShockAI.ShockAI'.-1);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyPausedDueToExclusivity()
{
	super(CharacterAttackAction).NotifyPausedDueToExclusivity();
	// End:0x3D
	if(ShockAI().IsAimingWeapon())
	{
		ShockAI().StopAimingWeapon();
		// End:0x80
		if(m_Pawn.IsAnimationHandleValid(KneelAnimationHandle))
		{
		}
		m_Pawn.SmartPerTrackEaseOutAnimation(KneelAnimationHandle);
		ShockAI().AddLocomotionKeyword('Kneeling', Class'ShockAI.ShockAI'.-1);
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnDamagedByTarget()
{
	super(CharacterAttackAction).OnDamagedByTarget();
	// End:0x41
	if(__NFUN_130__(HasAliveGatherer(), __NFUN_129__(CanHitWithRangedWeapon(false))))
	{
		bMoveAfterBeingAttacked = true;
		bShouldFireAtLastKnownLocation = false;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function bool GetDesiredRotationOverride(out Rotator DesiredRotation)
{
	//native.DesiredRotation;	
	@NULL
}

// Export USPFAttackAction::execShouldStopMovingToTarget(FFrame&, void* const)
native function bool ShouldStopMovingToTarget();

function AIRangedWeapon GetRangedWeapon()
{
	return SPF(m_Pawn).GetRangedWeapon();
	return;
	@NULL
	CommanderAction
}

function AIMeleeWeapon GetMeleeWeapon()
{
	return SPF(m_Pawn).GetMeleeWeapon();
	return;
	@NULL
	CommanderAction
}

// Export USPFAttackAction::execIsWithinRangeForMeleeWeapon(FFrame&, void* const)
native function bool IsWithinRangeForMeleeWeapon();

function bool CanHitWithMeleeWeapon(bool bTestCurrentRotation)
{
	//native.bTestCurrentRotation;	
	@NULL
}

function bool CanHitWithRangedWeapon(bool bTestCurrentRotation)
{
	//native.bTestCurrentRotation;	
	@NULL
}

// Export USPFAttackAction::execCanAttackWithMeleeWeapon(FFrame&, void* const)
native function bool CanAttackWithMeleeWeapon();

// Export USPFAttackAction::execCanAttackWithRangedWeapon(FFrame&, void* const)
native function bool CanAttackWithRangedWeapon();

// Export USPFAttackAction::execShouldGetUpFromKneelingPosition(FFrame&, void* const)
native function bool ShouldGetUpFromKneelingPosition();

// Export USPFAttackAction::execCanAttackTarget(FFrame&, void* const)
native function bool CanAttackTarget();

function GetUpFromKneel()
{
	ShockAI().AddLocomotionKeyword('Kneeling', Class'ShockAI.ShockAI'.-1);
	KneelAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, GetUpFromKneelAnimation);
	m_Pawn.FinishAnimation(KneelAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function KneelDown()
{
	ShockAI().AddLocomotionKeyword('Kneeling', 1);
	KneelAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, KneelDownAnimation);
	m_Pawn.FinishAnimation(KneelAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function NotifyBeginningAttack()
{
	super.NotifyBeginningAttack();
	PickUpGatherer();
	return;
	@NULL
}

function NotifyCannotAttackTarget()
{
	super(CharacterAttackAction).NotifyCannotAttackTarget();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x45
	/*@Error*/
	bHasBeenAbleToAttack = false;
	ShockAI().StopAimingWeapon();
	GetUpFromKneel();
	return;
	@NULL
	EcologyAI
}

function NotifyFinishedAttackingTarget()
{
	super(CharacterAttackAction).NotifyFinishedAttackingTarget();
	// End:0x41
	if(__NFUN_130__(bShouldFireAtLastKnownLocation, bFireAtLastKnownLocation))
	{
		bShouldFireAtLastKnownLocation = false;
		bFireAtLastKnownLocation = false;
		goto J0x74;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x74
		/*@Error*/
	}
	bShouldFireAtLastKnownLocation = true;
	return;
	@NULL
	EcologyAI
	BioshockMovementAction
	@NULL
}

function AttackTarget()
{
	local bool bIsAimingWeapon;
	local Weapon CurrentWeapon;

	// End:0x77
	if(CanAttackWithMeleeWeapon())
	{
		CurrentWeapon = SPF(m_Pawn).GetMeleeWeapon();
		// End:0x74
		if(ShockAI().IsAimingWeapon())
		{
			ShockAI().StopAimingWeapon();
			GetUpFromKneel();
			goto J0x343;
			CurrentWeapon = GetRangedWeapon();
		}
	}
	// End:0xF4
	if(__NFUN_129__(ShockAI().IsAimingWeapon()))
	{
		Protector(m_Pawn).NotifyFullBodyHitReactionPreventionDesired(self);
		KneelDown();
		ShockAI().AimWeaponAtTarget(Target);
		// End:0x32B
		if(__NFUN_129__(ShockAI().IsWeaponLockedOnTarget()))
		{
		}
		log('AI', 5, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " yield 3 - ShockAI().IsWeaponLockedOnTarget(): "), string(ShockAI().IsWeaponLockedOnTarget())), " ShockAI().IsAimingWeapon(): "), string(ShockAI().IsAimingWeapon())), " ShockAI().IsWeaponTargetWithinTrackingArea(Target): "), string(ShockAI().IsWeaponTargetWithinTrackingArea(Target))));
		yield();
		bIsAimingWeapon = ShockAI().IsAimingWeapon();
		// End:0x328
		if(__NFUN_132__(__NFUN_132__(__NFUN_132__(__NFUN_132__(__NFUN_129__(bIsAimingWeapon), __NFUN_129__(Class'Engine.Pawn'.static.checkAlive(Target))), IsWithinRangeForMeleeWeapon()), __NFUN_129__(ShockAI().IsWeaponTargetWithinTrackingArea(Target))), __NFUN_130__(__NFUN_129__(HasAliveGatherer()), __NFUN_129__(CanAttackWithRangedWeapon()))))
		{
			// End:0x30E
			if(bIsAimingWeapon)
			{
				ShockAI().StopAimingWeapon();
				GetUpFromKneel();
				bShouldFireAtLastKnownLocation = false;
				bFireAtLastKnownLocation = false;
				return;
				// [Loop Continue]
				goto J0xF4;
				ShockAI().FreezeAiming();
				assert(__NFUN_119__(CurrentWeapon, none));
				// End:0x3A9
				if(__NFUN_119__(SPF(m_Pawn).GetActiveHoldable(), CurrentWeapon))
				{
				}
				SPF(m_Pawn).Equip(CurrentWeapon);
			}
		}
		SPF(m_Pawn).BeginFiring();
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x3E3
		/*@Error*/
		yield();
		goto J0x3C9;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x416
		/*@Error*/
		ShockAI().UnfreezeAiming();
		bHasBeenAbleToAttack = true;
	}
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

defaultproperties
{
	KneelDownAnimation="SP_attackRanged_kneelDown"
	GetUpFromKneelAnimation="SP_attackRanged_getup"
}