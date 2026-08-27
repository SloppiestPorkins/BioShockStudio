class MimicAction extends BioshockCharacterAction
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private MoveToGoal CurrentMoveToGoal;
var private config float MimicUpdateTime;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	ShockAI().NotifyFullBodyHitReactionPreventionDesired(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	// End:0x33
	if(__NFUN_119__(CurrentMoveToGoal, none))
	{
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		ShockAI().NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function MoveToUsableMimicSpot()
{
	local NavigationPoint Destination;

	Destination = Aggressor(m_Pawn).GetUsableMimicSpot();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x14B
	/*@Error*/
	AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, Destination);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentMoveToGoal);
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function SetMimicPose()
{
	local PoseData Pose;

	Pose = Aggressor(m_Pawn).GetMimicInitialPose();
	m_Pawn.SetPose(Pose);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	// End:0x6F
	if(__NFUN_130__(__NFUN_114__(DummyWeaponGoal, none), __NFUN_114__(CurrentMoveToGoal, none)))
	{
		waitForResourcesAvailable(achievingGoal.Priority, achievingGoal.Priority);
		useResources(Class'VengeanceShared.AI_Resource'.2);
		// End:0xE4
		if(__NFUN_129__(Aggressor(m_Pawn).IsAtSpawnPoint()))
		{
		}
		MoveToUsableMimicSpot();
		// End:0xE4
		if(__NFUN_179__(__NFUN_174__(m_Pawn.LastRenderTime, 1.0000000), Level().TimeSeconds))
		{
			yield();
			// [Loop Continue]
			goto J0x9E;
			m_Pawn.UnTriggerEffectEvent('AggressorAlive');
			Aggressor(m_Pawn).SetIsMimic(true);
		}
	}
	SetMimicPose();
	stop;				
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
	satisfiesGoal=Class'ShockAI.MimicGoal'
	bExclusiveAction=true
}