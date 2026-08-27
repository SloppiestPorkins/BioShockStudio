class BotBaseAction extends BotBehaviorActionInterface implements IVisionNotification
	abstract
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

struct native atomic DamagingPawnInfo
{
	var ShockPawn DamagingPawn;
	var float TotalDamageAmount;
	var float LastDamageTime;

	structdefaultproperties
	{
		CheckpointTypePadding=452
	}
};

var private ShockPawn AttackTarget;
var array<Pawn> VisiblePawns;
var private BotBaseSubGoal CurrentSubGoal;
var array<DamagingPawnInfo> DamagingPawnList;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super.initAction(R, Goal);
	MyBot.RegisterVisionNotification(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	MyBot.UnregisterVisionNotification(self);
	// End:0x41
	if(__NFUN_119__(CurrentSubGoal, none))
	{
		CurrentSubGoal.__NFUN_198__();
		CurrentSubGoal = none;
		super.Cleanup();
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
	@NULL
}

// Export UBotBaseAction::execGetAttackTarget(FFrame&, void* const)
native function ShockPawn GetAttackTarget();

function bool AttackTargetCanBeDetected()
{
	return false;
	return;
}

function StartAttackTargetSubGoal(ShockPawn Target)
{
	local BotAttackTargetGoal AttackGoal;

	StopSubGoals();
	AttackGoal = Class'ShockAI.BotAttackTargetGoal'.static.Allocate(self).;
	construct_AI_ResourceShockPawn(characterResource(), Target);
	AttackGoal.__TargetCanBeDetected__Delegate = AttackTargetCanBeDetected;
	AttackGoal.__NFUN_199__();
	AttackGoal.postGoal(self);
	CurrentSubGoal = AttackGoal;
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function StopSubGoals()
{
	// End:0x41
	if(__NFUN_119__(CurrentSubGoal, none))
	{
		CurrentSubGoal.unPostGoal(self);
		CurrentSubGoal.__NFUN_198__();
		CurrentSubGoal = none;
		return;
		@NULL
		CommanderAction
		BioshockMovementAction
	}
	@NULL
}

function OnViewerSawPawn(VPawn Viewer, Pawn Seen)
{
	log('AI_Security', 3, __NFUN_112__(__NFUN_112__(string(Viewer.Name), " saw "), string(Seen.Name)));
	VisiblePawns[VisiblePawns.Length] = Seen;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA0
	/*@Error*/
	MyBot.TriggerEffectEvent('SawTarget');
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnViewerLostPawn(VPawn Viewer, Pawn Seen)
{
	local int i;

	log('AI_Security', 3, __NFUN_112__(__NFUN_112__(string(Viewer.Name), " lost view of "), string(Seen.Name)));
	i = 0;
	// End:0xBD
	if(__NFUN_150__(i, VisiblePawns.Length))
	{
		// End:0xAF
		if(__NFUN_114__(Seen, VisiblePawns[i]))
		{
			VisiblePawns.Remove(i, 1);
			goto J0xBD;
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x5F;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0xF4
			/*@Error*/
			MyBot.TriggerEffectEvent('LostTarget');
		}
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
	@NULL
}

function OnNumLOSChanged(VPawn Viewer, Pawn Seen, int NewNumLOS)
{
	return;
}

function bool TargetIsVisible(Pawn Candidate)
{
	//native.Candidate;	
	@NULL
}

function bool AttackTargetIsVisible()
{
	return __NFUN_130__(__NFUN_119__(AttackTarget, none), TargetIsVisible(AttackTarget));
	return;
	@NULL
	CommanderAction
}

function OnBumpedOtherBot(SecurityBot OtherBot)
{
	CurrentSubGoal.OnBumpedOtherBot(OtherBot);
	return;
	@NULL
	CommanderAction
}

function AddAlternateDamager(ShockPawn Damager, float TotalDamageDealt)
{
	//native.Damager;
	//native.TotalDamageDealt;	
	@NULL
	@NULL
}

function ShockPawn GetMostThreateningAlternateDamager(bool DontFilterByLocation)
{
	//native.DontFilterByLocation;	
	@NULL
}

function bool CanTraceToTarget(ShockPawn Target)
{
	return MyBot.__NFUN_548__(Target.GetTargetTrackingLocation(), MyBot.Location);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function bool IsValidAttackTarget(ShockPawn Target)
{
	return __NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_119__(Target, none), __NFUN_119__(Target, MyBot)), Target.IsAlive()), Target.CanBeAttacked());
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}
