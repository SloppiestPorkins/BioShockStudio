class InsectSwarmCommanderAction extends CommanderAction implements IVisionNotification
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private InsectSwarmSearchGoal CurrentSearchGoal;
var private InsectSwarmAttackGoal CurrentAttackGoal;
var array<ShockPawn> VisiblePawns;
var private Rotator StartingRotation;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super.initAction(R, Goal);
	m_Pawn.RegisterVisionNotification(self);
	StartingRotation = m_Pawn.Rotation;
	StartingRotation.Roll = 0;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	m_Pawn.UnregisterVisionNotification(self);
	super.Cleanup();
	StopChildGoals();
	return;
	@NULL
	CommanderAction
}

function CleanupGoals()
{
	// End:0x29
	if(__NFUN_119__(CurrentSearchGoal, none))
	{
		CurrentSearchGoal.__NFUN_198__();
		CurrentSearchGoal = none;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x52
		/*@Error*/
		CurrentAttackGoal.__NFUN_198__();
	}
	CurrentAttackGoal = none;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function StartChildGoals()
{
	CurrentSearchGoal = Class'ShockAI.InsectSwarmSearchGoal'.static.Allocate(self).;
	construct_AI_ResourceRotator(characterResource(), StartingRotation);
	assert(__NFUN_119__(CurrentSearchGoal, none));
	CurrentSearchGoal.__NFUN_199__();
	CurrentSearchGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

private function StopChildGoals()
{
	CleanupGoals();
	return;
}

function OnViewerSawPawn(VPawn Viewer, Pawn Seen)
{
	local ShockPawn ShockSeen;

	log('AI_Bioweapon',, __NFUN_112__(__NFUN_112__(string(Viewer.Name), " saw "), string(Seen.Name)));
	ShockSeen = ShockPawn(Seen);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xCA
	/*@Error*/
	log('AI_Bioweapon', 4, __NFUN_112__("Adding to VisiblePawns: ", string(Seen)));
	VisiblePawns[VisiblePawns.Length] = ShockSeen;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnViewerLostPawn(VPawn Viewer, Pawn Seen)
{
	local int i;
	local ShockPawn ShockSeen;

	log('AI_Bioweapon',, __NFUN_112__(__NFUN_112__(string(Viewer.Name), " lost view of "), string(Seen.Name)));
	ShockSeen = ShockPawn(Seen);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x122
	/*@Error*/
	log('AI_Bioweapon', 4, __NFUN_112__("Removing from VisiblePawns: ", string(Seen)));
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x122
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x114
	/*@Error*/
	VisiblePawns.Remove(i, 1);
	goto J0x122;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0xC4;
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

protected function bool ShouldHandleDamageEvents()
{
	return false;
	return;
}

function bool IsValidAttackTarget(ShockPawn AttackTarget)
{
	return __NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_114__(InsectSwarm(AttackTarget), none), __NFUN_129__(AttackTarget.IsSecurityBot())), __NFUN_129__(AttackTarget.IsSecurityCamera())), __NFUN_129__(AttackTarget.IsTurret())), __NFUN_129__(AttackTarget.IsNavBot()));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function AttackSpecifiedTarget(ShockPawn AttackTarget)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xFB
	/*@Error*/
	log('AI_Bioweapon', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " attacking "), string(AttackTarget)), "."));
	CurrentAttackGoal = Class'ShockAI.InsectSwarmAttackGoal'.static.Allocate(self).;
	construct_AI_ResourceShockPawnRotator(characterResource(), AttackTarget, StartingRotation);
	assert(__NFUN_119__(CurrentAttackGoal, none));
	CurrentAttackGoal.__NFUN_199__();
	CurrentAttackGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentAttackGoal);
	CurrentAttackGoal.__NFUN_198__();
	CurrentAttackGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function FindNewAttackTarget()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x27
	/*@Error*/
	CurrentAttackGoal.unPostGoal(self);
	return;
	@NULL
	CommanderAction
}

function ShockPawn GetRandomTarget()
{
	local int i;
	local array<ShockPawn> AvailableTargets;

	log('AI_Bioweapon', 4, __NFUN_112__(string(Name), " checking for available targets."));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xEF
	/*@Error*/
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xC8
	/*@Error*/
	// End:0xBA
	if(IsValidAttackTarget(VisiblePawns[i]))
	{
		AvailableTargets[AvailableTargets.Length] = VisiblePawns[i];
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x5A;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xEF
		/*@Error*/
		return AvailableTargets[__NFUN_167__(AvailableTargets.Length)];
		return none;
		return;
		@NULL
	}
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function AttackAvailableTargets()
{
	local ShockPawn Target;
	local InsectSwarm MySwarm;

	MySwarm = InsectSwarm(m_Pawn);
	// End:0x96
	if(__NFUN_119__(MySwarm.ForcedAttackTarget, none))
	{
		// End:0x7B
		if(IsValidAttackTarget(MySwarm.ForcedAttackTarget))
		{
			Target = MySwarm.ForcedAttackTarget;
			MySwarm.ForcedAttackTarget = none;
			goto J0xAA;
			Target = GetRandomTarget();
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0xCC
			/*@Error*/
		}
		AttackSpecifiedTarget(Target);
		return;
		@NULL
	}
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	StartChildGoals();
	__NFUN_113__('Attacking');
	stop;		
}

state Attacking
{Begin:

	AttackAvailableTargets();
	__NFUN_256__(0.2000000);
	goto 'Begin';
	stop;			
}
