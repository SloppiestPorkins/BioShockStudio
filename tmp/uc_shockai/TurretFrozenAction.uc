class TurretFrozenAction extends BioshockCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) Turret.TurretMovementDirection MovementDirection;
var private Turret MyTurret;
var private TurretGoToLocationMovementGoal MovementGoal;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	MyTurret = Turret(m_Pawn);
	assert(__NFUN_119__(MyTurret, none));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	// End:0x29
	if(__NFUN_119__(MovementGoal, none))
	{
		MovementGoal.__NFUN_198__();
		MovementGoal = none;
		super(AI_CharacterAction).Cleanup();
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

function Rotator DetermineTargetRotation()
{
	local int YawMovementDistance;
	local Rotator TargetRotation;

	YawMovementDistance = int(__NFUN_171__(float(MyTurret.GetYawSpeed()), MyTurret.GetFrozenTransitionTime()));
	TargetRotation = MyTurret.GetRotation();
	switch(MovementDirection)
	{
		// End:0x97
		case 0:
			__NFUN_161__(TargetRotation.Yaw, YawMovementDistance);
			// End:0xCF
			break;
			// End:0xC4
			case 1:
				__NFUN_162__(TargetRotation.Yaw, YawMovementDistance);
				// End:0xCF
				break;
				// End:0xCC
				case 2:
					// End:0xCF
					break;
					// End:0xFFFF
					default:
						break;/* Tried to find Switch scope, found Case instead */
				return TargetRotation;
				return;
				@NULL
				CommanderAction
				EcologyFighterCommanderAction
				@NULL
	}
}

function SlowMovementOverTime(Rotator TargetRotation)
{
	local float StartTime, SpeedPercentage;

	MovementGoal = Class'ShockAI.TurretGoToLocationMovementGoal'.static.Allocate(self).;
	construct_AI_ResourceNameIntIntRotator(characterResource(), 'Moving', MyTurret.GetPitchSpeed(), MyTurret.GetYawSpeed(), TargetRotation);
	MovementGoal.__NFUN_199__();
	MovementGoal.postGoal(self);
	StartTime = Level().TimeSeconds;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1AD
	/*@Error*/
	SpeedPercentage = __NFUN_175__(1.0000000, __NFUN_172__(__NFUN_175__(Level().TimeSeconds, StartTime), MyTurret.GetFrozenTransitionTime()));
	TurretGoToLocationMovementAction(MovementGoal.achievingAction).SetYawSpeed(int(__NFUN_171__(float(MyTurret.GetYawSpeed()), SpeedPercentage)));
	yield();
	// [Loop Continue]
	goto J0xC3;
	MovementGoal.unPostGoal(self);
	MovementGoal.__NFUN_198__();
	MovementGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function PerformFrozenBehavior()
{
	local Rotator TargetRotation;

	MyTurret.StopEngine(MyTurret.GetFrozenTransitionTime());
	TargetRotation = DetermineTargetRotation();
	// End:0x7D
	if(__NFUN_203__(TargetRotation, MyTurret.GetRotation()))
	{
		SlowMovementOverTime(TargetRotation);
		goto J0x97;
		__NFUN_256__(MyTurret.GetFrozenTransitionTime());
		return;
	}
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting TurretFrozenAction::Running."));
	PerformFrozenBehavior();
	stop;				
	@NULL
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.TurretFrozenGoal'
	bExclusiveAction=true
}