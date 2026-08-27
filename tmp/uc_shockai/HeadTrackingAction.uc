class HeadTrackingAction extends BioshockCharacterAction implements IInterestedActorDestroyed, IInterestedPawnDied
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var private float StopTime;
var private bool bIsTracking;
var private Actor LastTrackingActor;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	m_Pawn.Level.RegisterNotifyPawnDied(self);
	m_Pawn.Level.RegisterNotifyActorDestroyed(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	LastTrackingActor = none;
	m_Pawn.Level.UnRegisterNotifyPawnDied(self);
	m_Pawn.Level.UnRegisterNotifyActorDestroyed(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnOtherPawnDied(Pawn DeadPawn)
{
	// End:0x39
	if(__NFUN_114__(DeadPawn, LastTrackingActor))
	{
		// End:0x2E
		if(IsTracking())
		{
			StopTracking();
			LastTrackingActor = none;
			return;
		}
		@NULL
		CommanderAction
	}
	CommanderAction
}

function OnOtherActorDestroyed(Actor ActorBeingDestroyed)
{
	// End:0x39
	if(__NFUN_114__(ActorBeingDestroyed, LastTrackingActor))
	{
		// End:0x2E
		if(IsTracking())
		{
			StopTracking();
			LastTrackingActor = none;
			return;
		}
		@NULL
		CommanderAction
	}
	CommanderAction
}

function QuickLook(Actor Target, optional float Duration, optional Vector Offset)
{
	local HeadTargetTracker Tracker;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x166
	/*@Error*/
	Tracker = m_Pawn.GetHeadTargetTracker();
	// End:0x73
	if(__NFUN_180__(Duration, 0.0000000))
	{
		StopTime = -1.0000000;
		goto J0xAB;
		StopTime = __NFUN_174__(m_Pawn.Level.TimeSeconds, Duration);
	}
	log('AI', 4, __NFUN_168__(__NFUN_168__(__NFUN_168__(__NFUN_168__(__NFUN_168__("========== QuickLook!", string(ShockAI())), "->"), string(Target)), "DisallowHeadTracking():"), string(DisallowHeadTracking())));
	Tracker.SetInertialAcceleration(ShockAI().QuickHeadTurnAcceleration);
	StartTracking(Target, Offset);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function CasualLook(Actor Target, optional float Duration, optional Vector Offset)
{
	local HeadTargetTracker Tracker;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x167
	/*@Error*/
	Tracker = m_Pawn.GetHeadTargetTracker();
	log('AI', 4, __NFUN_168__(__NFUN_168__(__NFUN_168__(__NFUN_168__(__NFUN_168__("========== CasualLook!", string(ShockAI())), "->"), string(Target)), "DisallowHeadTracking():"), string(DisallowHeadTracking())));
	// End:0xE5
	if(__NFUN_180__(Duration, 0.0000000))
	{
		StopTime = -1.0000000;
		goto J0x11D;
		StopTime = __NFUN_174__(m_Pawn.Level.TimeSeconds, Duration);
	}
	Tracker.SetInertialAcceleration(ShockAI().CasualHeadTurnAcceleration);
	StartTracking(Target, Offset);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function StartTracking(Actor Target, optional Vector Offset)
{
	local HeadTargetTracker Tracker;

	// End:0x90
	if(__NFUN_129__(DisallowHeadTracking()))
	{
		Tracker = m_Pawn.GetHeadTargetTracker();
		ShockAI().AddLocomotionKeyword('HeadTracking', 1);
		Tracker.TrackTarget(Target, 'None', Offset);
		bIsTracking = true;
		LastTrackingActor = Target;
		return;
		@NULL
		CommanderAction
		EcologyFighterCommanderAction
	}
	@NULL
}

function StopTracking(optional bool bDoNotSetStopTime)
{
	local HeadTargetTracker Tracker;

	Tracker = m_Pawn.GetHeadTargetTracker();
	log('AI', 4, __NFUN_168__("========== Stop looking", string(ShockAI())));
	// End:0xAC
	if(__NFUN_119__(Tracker, none))
	{
		Tracker.SetInertialAcceleration(ShockAI().CasualHeadTurnAcceleration);
		Tracker.UntrackTarget();
		ShockAI().RemoveLocomotionKeyword('HeadTracking');
	}
	bIsTracking = false;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x115
	/*@Error*/
	StopTime = m_Pawn.Level.TimeSeconds;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool IsTracking()
{
	return bIsTracking;
	return;
	@NULL
}

function bool DisallowHeadTracking()
{
	return __NFUN_132__(__NFUN_132__(__NFUN_132__(__NFUN_132__(__NFUN_114__(m_Pawn.GetHeadTargetTracker(), none), ShockAI().DisallowHeadTracking()), m_Pawn.IsOnCeiling()), __NFUN_155__(int(m_Pawn.GetRagdoll().GetRagdollState()), int(0))), ShockAI().KeywordSearchOnBone(m_Pawn.GetHeadTargetTracker().GetHeadBoneIdx(), 'DisallowHeadTracking', 0.2000000));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool ShouldBeTracking()
{
	return __NFUN_130__(__NFUN_119__(LastTrackingActor, none), __NFUN_132__(__NFUN_180__(StopTime, -1.0000000), __NFUN_176__(m_Pawn.Level.TimeSeconds, StopTime)));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

state Running
{	J0x00:
	// End:0xB0 [Loop If]
	if(true)
	{
		// End:0x74
		if(IsTracking())
		{
			// End:0x71
			if(__NFUN_132__(DisallowHeadTracking(), __NFUN_130__(__NFUN_181__(StopTime, -1.0000000), __NFUN_179__(m_Pawn.Level.TimeSeconds, StopTime))))
			{
				StopTracking(true);
				goto J0xA5;
				// End:0xA5
				if(__NFUN_130__(ShouldBeTracking(), __NFUN_129__(DisallowHeadTracking())))
				{
				}
			}
			StartTracking(LastTrackingActor);
			__NFUN_256__(0.1000000);
			// [Loop Continue]
			goto J0x00;
			succeed();
			stop;			
		}
	}
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.HeadTrackingGoal'
}