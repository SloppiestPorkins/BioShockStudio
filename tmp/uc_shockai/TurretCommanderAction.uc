class TurretCommanderAction extends CommanderAction implements IVisionNotification
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private TurretStandbyGoal CurrentStandbyGoal;
var private TurretAttackGoal CurrentAttackGoal;
var private TurretDormantGoal CurrentDormantGoal;
var private TurretShockedGoal CurrentShockedGoal;
var private TurretFrozenGoal CurrentFrozenGoal;
var array<ShockPawn> VisiblePawns;
var private Turret MyTurret;
var private ShockPawn AttackTarget;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super.initAction(R, Goal);
	MyTurret = Turret(m_Pawn);
	assert(__NFUN_119__(MyTurret, none));
	m_Pawn.RegisterVisionNotification(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	m_Pawn.UnregisterVisionNotification(self);
	// End:0x41
	if(__NFUN_119__(CurrentStandbyGoal, none))
	{
		CurrentStandbyGoal.__NFUN_198__();
		CurrentStandbyGoal = none;
		// End:0x6A
		if(__NFUN_119__(CurrentAttackGoal, none))
		{
			CurrentAttackGoal.__NFUN_198__();
		}
		CurrentAttackGoal = none;
		// End:0x93
		if(__NFUN_119__(CurrentDormantGoal, none))
		{
			CurrentDormantGoal.__NFUN_198__();
			CurrentDormantGoal = none;
		}
		// End:0xBC
		if(__NFUN_119__(CurrentShockedGoal, none))
		{
			CurrentShockedGoal.__NFUN_198__();
			CurrentShockedGoal = none;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0xE5
			/*@Error*/
		}
		CurrentFrozenGoal.__NFUN_198__();
		CurrentFrozenGoal = none;
		super.Cleanup();
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function CleanupGoals()
{
	MyTurret.SetCurrentMovementDirection(2);
	// End:0x5A
	if(__NFUN_119__(CurrentStandbyGoal, none))
	{
		CurrentStandbyGoal.unPostGoal(self);
		CurrentStandbyGoal.__NFUN_198__();
		CurrentStandbyGoal = none;
		// End:0x9B
		if(__NFUN_119__(CurrentAttackGoal, none))
		{
			CurrentAttackGoal.unPostGoal(self);
		}
		CurrentAttackGoal.__NFUN_198__();
		CurrentAttackGoal = none;
		// End:0xDC
		if(__NFUN_119__(CurrentDormantGoal, none))
		{
			CurrentDormantGoal.unPostGoal(self);
			CurrentDormantGoal.__NFUN_198__();
		}
		CurrentDormantGoal = none;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x11D
		/*@Error*/
		CurrentShockedGoal.unPostGoal(self);
		CurrentShockedGoal.__NFUN_198__();
		CurrentShockedGoal = none;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x15E
		/*@Error*/
	}
	else
	{
		CurrentFrozenGoal.unPostGoal(self);
		CurrentFrozenGoal.__NFUN_198__();
		CurrentFrozenGoal = none;
		return;
		@NULL
		CommanderAction
		EcologyFighterCommanderAction
		@NULL
	}
}

function OnViewerSawPawn(VPawn Viewer, Pawn Seen)
{
	local ShockPawn SeenShockPawn;
	local int SeenPriority, CurrentTargetPriority;

	log('AI_Security', 3, __NFUN_112__(__NFUN_112__(string(Viewer.Name), " saw "), string(Seen.Name)));
	SeenShockPawn = ShockPawn(Seen);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x18D
	/*@Error*/
	VisiblePawns[VisiblePawns.Length] = SeenShockPawn;
	SeenPriority = MyTurret.GetTargetPriority(SeenShockPawn);
	// End:0xFA
	if(__NFUN_119__(AttackTarget, none))
	{
		CurrentTargetPriority = MyTurret.GetTargetPriority(AttackTarget);
		goto J0x105;
		CurrentTargetPriority = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x15E
		/*@Error*/
		BeAttacking(SeenShockPawn);
	}
	NotifyChildSawPawn(Viewer, SeenShockPawn);
	OnSawPawn(SeenShockPawn);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnViewerLostPawn(VPawn Viewer, Pawn Seen)
{
	local int i;
	local ShockPawn SeenShockPawn;

	log('AI_Security', 3, __NFUN_112__(__NFUN_112__(string(Viewer.Name), " lost view of "), string(Seen.Name)));
	SeenShockPawn = ShockPawn(Seen);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x139
	/*@Error*/
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x139
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x12B
	/*@Error*/
	VisiblePawns.Remove(i, 1);
	NotifyChildLostPawn(Viewer, SeenShockPawn);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x115
	/*@Error*/
	__NFUN_113__('LostTarget');
	OnLostPawn(SeenShockPawn);
	goto J0x139;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x8A;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnNumLOSChanged(VPawn Viewer, Pawn Seen, int NewNumLOS)
{
	return;
}

function NotifyChildSawPawn(VPawn Viewer, ShockPawn Seen)
{
	local TurretAttackAction CurrentAttackAction;

	CurrentAttackAction = GetAttackAction();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4C
	/*@Error*/
	CurrentAttackAction.OnViewerSawPawn(Viewer, Seen);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyChildLostPawn(VPawn Viewer, ShockPawn Seen)
{
	local TurretAttackAction CurrentAttackAction;

	CurrentAttackAction = GetAttackAction();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4C
	/*@Error*/
	CurrentAttackAction.OnViewerLostPawn(Viewer, Seen);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

private function OnSawPawn(ShockPawn Seen)
{
	return;
}

private function OnLostPawn(ShockPawn Seen)
{
	return;
}

function GetVisiblePawns(out array<ShockPawn> pawns)
{
	pawns = VisiblePawns;
	return;
	@NULL
	CommanderAction
}

function ShockPawn GetHighestPriorityPawn(ShockPawn IgnoreTarget)
{
	local int i, HighestPriority, CurrentPriority;
	local ShockPawn HighestPriorityPawn;

	HighestPriority = 0;
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xD8
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xCA
	/*@Error*/
	CurrentPriority = MyTurret.GetTargetPriority(VisiblePawns[i]);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xCA
	/*@Error*/
	HighestPriorityPawn = VisiblePawns[i];
	HighestPriority = CurrentPriority;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x16;
	return HighestPriorityPawn;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool CheckForOtherAvailableTargets()
{
	local ShockPawn NewTarget;

	NewTarget = GetHighestPriorityPawn(AttackTarget);
	// End:0x41
	if(__NFUN_119__(NewTarget, none))
	{
		BeAttacking(NewTarget);
		return true;
		return false;
		return;
		@NULL
		CommanderAction
		EcologyFighterCommanderAction
	}
	@NULL
}

function bool isVisible(ShockPawn Target)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x54
	/*@Error*/
	// End:0x46
	if(__NFUN_114__(Target, VisiblePawns[i]))
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
	CommanderAction
	@NULL
}

function bool AttackTargetIsVisible()
{
	return __NFUN_130__(__NFUN_119__(AttackTarget, none), isVisible(AttackTarget));
	return;
	@NULL
	CommanderAction
}

protected function bool ShouldHandleDamageEvents()
{
	return false;
	return;
}

function bool IsStandby()
{
	return __NFUN_119__(CurrentStandbyGoal, none);
	return;
	@NULL
}

function bool IsAttacking()
{
	return __NFUN_119__(CurrentAttackGoal, none);
	return;
	@NULL
}

function bool IsDormant()
{
	return __NFUN_119__(CurrentDormantGoal, none);
	return;
	@NULL
}

function bool IsFrozen()
{
	return __NFUN_119__(CurrentFrozenGoal, none);
	return;
	@NULL
}

function bool IsShocked()
{
	return __NFUN_119__(CurrentShockedGoal, none);
	return;
	@NULL
}

function bool CanLeaveDormantState()
{
	return __NFUN_130__(__NFUN_130__(__NFUN_129__(IsFrozen()), __NFUN_129__(IsShocked())), __NFUN_132__(MyTurret.IsHacked(), MyTurret.GetSecurityManager().IsActive()));
	return;
	@NULL
	CommanderAction
}

function TurretStandbyAction GetStandbyAction()
{
	// End:0x2F
	if(__NFUN_119__(CurrentStandbyGoal, none))
	{
		return TurretStandbyAction(CurrentStandbyGoal.achievingAction);
		return none;
		return;
		@NULL
		CommanderAction
		EcologyFighterCommanderAction
	}
	@NULL
}

function TurretAttackAction GetAttackAction()
{
	// End:0x2F
	if(__NFUN_119__(CurrentAttackGoal, none))
	{
		return TurretAttackAction(CurrentAttackGoal.achievingAction);
		return none;
		return;
		@NULL
		CommanderAction
		EcologyFighterCommanderAction
	}
	@NULL
}

function TurretDormantAction GetDormantAction()
{
	// End:0x2F
	if(__NFUN_119__(CurrentDormantGoal, none))
	{
		return TurretDormantAction(CurrentDormantGoal.achievingAction);
		return none;
		return;
		@NULL
		CommanderAction
		EcologyFighterCommanderAction
	}
	@NULL
}

function OnStandbyPositionChanged()
{
	// End:0x25
	if(IsStandby())
	{
		GetStandbyAction().OnStandbyPositionChanged();
	}
	return;
}

function OnIntentionallyDamaged(ShockPawn Damager)
{
	local Turret AttackingTurret;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x9B
	/*@Error*/
	AttackingTurret = Turret(Damager);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x9B
	/*@Error*/
	ForceAttackTarget(Damager);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ForceAttackTarget(ShockPawn Target)
{
	BeAttacking(Target);
	return;
	@NULL
}

// Export UTurretCommanderAction::execGetAttackTarget(FFrame&, void* const)
native function ShockPawn GetAttackTarget();

function BeStandby()
{
	// End:0x6A
	if(__NFUN_129__(CanLeaveDormantState()))
	{
		log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " tried to start standby, but couldn't leave dormant state."));
		return;
		CleanupGoals();
	}
	AttackTarget = none;
	CurrentStandbyGoal = Class'ShockAI.TurretStandbyGoal'.static.Allocate(self).;
	construct_AI_Resource(characterResource());
	assert(__NFUN_119__(CurrentStandbyGoal, none));
	CurrentStandbyGoal.__NFUN_199__();
	CurrentStandbyGoal.postGoal(self);
	__NFUN_113__('None');
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function BeAttacking(ShockPawn Target)
{
	local bool CurrentlyAttacking;

	// End:0x6C
	if(__NFUN_129__(CanLeaveDormantState()))
	{
		log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " tried to start attacking, but couldn't leave dormant state."));
		return;
		// End:0x91
		if(MyTurret.PawnIsFriendly(Target))
		{
		}
		return;
		CurrentlyAttacking = IsAttacking();
	}
	CleanupGoals();
	AttackTarget = Target;
	CurrentAttackGoal = Class'ShockAI.TurretAttackGoal'.static.Allocate(self).;
	construct_AI_ResourceShockPawnBool(characterResource(), Target, __NFUN_129__(CurrentlyAttacking));
	assert(__NFUN_119__(CurrentAttackGoal, none));
	CurrentAttackGoal.__NFUN_199__();
	CurrentAttackGoal.postGoal(self);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x166
	/*@Error*/
	__NFUN_113__('LostTarget');
	goto J0x171;
	__NFUN_113__('None');
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function BeDormant()
{
	CleanupGoals();
	AttackTarget = none;
	CurrentDormantGoal = Class'ShockAI.TurretDormantGoal'.static.Allocate(self).;
	construct_AI_Resource(characterResource());
	assert(__NFUN_119__(CurrentDormantGoal, none));
	CurrentDormantGoal.__NFUN_199__();
	CurrentDormantGoal.postGoal(self);
	__NFUN_113__('None');
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function OnNotifySecuritySystemActive()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x26
	/*@Error*/
	BeStandby();
	return;
	@NULL
}

function OnNotifySecuritySystemInactive()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x26
	/*@Error*/
	BeDormant();
	return;
	@NULL
}

function OnNotifySecurityBeaconApplied(Actor Damager, ShockPawn SecurityBeaconTarget)
{
	local int NewTargetPriority, CurrentTargetPriority;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xE0
	/*@Error*/
	NewTargetPriority = MyTurret.GetTargetPriority(SecurityBeaconTarget);
	// End:0x7C
	if(__NFUN_119__(AttackTarget, none))
	{
		CurrentTargetPriority = MyTurret.GetTargetPriority(AttackTarget);
		goto J0x87;
		CurrentTargetPriority = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xE0
		/*@Error*/
	}
	BeAttacking(SecurityBeaconTarget);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnHackSucceeded(ShockPlayer Player)
{
	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " has been hacked, going back to standby."));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xE1
	/*@Error*/
	ShockAI().ClearFrozen();
	ShockAI().ClearShocked();
	BeStandby();
	return;
	@NULL
	CommanderAction
}

function OnHackFailed(ShockPlayer Player)
{
	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " was not hacked.  Attacking hacker."));
	BeAttacking(Player);
	return;
	@NULL
	CommanderAction
}

function OnSetUnhacked()
{
	// End:0x29
	if(IsStandby())
	{
		log(,, "InStandby");
		CheckForOtherAvailableTargets();
	}
	return;
}

function ResumeAttackingIfPossible()
{
	local ShockPawn NewTarget;

	// End:0x3D
	if(__NFUN_130__(__NFUN_119__(AttackTarget, none), isVisible(AttackTarget)))
	{
		NewTarget = AttackTarget;
		goto J0x5A;
		NewTarget = GetHighestPriorityPawn(AttackTarget);
	}
	// End:0xF8
	if(__NFUN_119__(NewTarget, none))
	{
		log('AI_Security', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(MyTurret), " found a target "), string(NewTarget)), " after leaving shocked or frozen state.  Attacking target"));
		BeAttacking(NewTarget);
		goto J0x16E;
		log('AI_Security', 4, __NFUN_112__(string(MyTurret), " did not find a target after leaving shocked or frozen state.  Going standby."));
	}
	BeStandby();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function StartShockedBehavior()
{
	CleanupGoals();
	CurrentShockedGoal = Class'ShockAI.TurretShockedGoal'.static.Allocate(self).;
	construct_AI_Resource(characterResource());
	assert(__NFUN_119__(CurrentShockedGoal, none));
	CurrentShockedGoal.__NFUN_199__();
	CurrentShockedGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

private function StopShockedBehavior()
{
	CleanupGoals();
	ResumeAttackingIfPossible();
	return;
}

function StartFrozenBehavior()
{
	local Turret.TurretMovementDirection MovementDirection;

	MovementDirection = MyTurret.GetCurrentMovementDirection();
	CleanupGoals();
	CurrentFrozenGoal = Class'ShockAI.TurretFrozenGoal'.static.Allocate(self).;
	construct_AI_ResourceByte(characterResource(), MovementDirection);
	assert(__NFUN_119__(CurrentFrozenGoal, none));
	CurrentFrozenGoal.__NFUN_199__();
	CurrentFrozenGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

private function StopFrozenBehavior()
{
	CleanupGoals();
	ResumeAttackingIfPossible();
	return;
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting commander action."));
	BeStandby();
	stop;			
	@NULL
}

state LostTarget
{
	ignores WaitToGoStandby, OnNotifySecurityBeaconApplied, OnSawPawn;
Begin:

	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn), " starting TurretCommanderAction::LostTarget.  Starting lost contact duration at "), string(MyTurret.GetLostContactDuration(AttackTarget))), "."));
	__NFUN_256__(MyTurret.GetNewTargetAcquisitionDelay());
	CheckForOtherAvailableTargets();
	WaitToGoStandby();
	BeStandby();
	stop;			
	@NULL
	@NULL
	@NULL
	@NULL
}
