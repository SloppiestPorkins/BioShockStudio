class ChargeAttackAction extends BioshockCharacterAction
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

const MAX_YAW_DELTA = 800;

var(Parameters) private Actor Target;
var(Parameters) private name TelegraphAnimationName;
var(Parameters) private name ChargeLoopAnimationName;
var(Parameters) private name ChargeEndAnimationName;
var(Parameters) private name ChargeEndFacingTargetAnimationName;
var(Parameters) private name ChargeHitAnimationName;
var int Handle;
var Vector ChargeStart;
var float ChargeStartTime;
var float ChargeDistance;
var Vector ChargeDestination;
var Vector LastLocation;
var int NoProgress;
var bool bCharging;

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4D
	/*@Error*/
	m_Pawn.SmartPerTrackEaseOutAnimation(Handle);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool HaveHitTarget()
{
	return __NFUN_130__(__NFUN_114__(Target, ShockAI(m_Pawn).LastBumpedPawn), __NFUN_177__(ShockAI(m_Pawn).LastBumpedTime, ChargeStartTime));
	return;
	@NULL
	EcologyCommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool FacingTarget()
{
	return __NFUN_177__(__NFUN_219__(__NFUN_216__(m_Pawn.Location, ChargeStart), __NFUN_216__(Target.Location, m_Pawn.Location)), float(0));
	return;
	@NULL
	EcologyCommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool IsChargingOrPreparingToCharge()
{
	return bWasTicked;
	return;
	@NULL
}

function bool IsCharging()
{
	return bCharging;
	return;
	@NULL
}

function bool IsRotationAlignedtoTarget(Actor Target, int MaxYawDelta)
{
	local int YawDiff;

	YawDiff = __NFUN_156__(__NFUN_147__(Rotator(__NFUN_216__(Target.Location, m_Pawn.Location)).Yaw, m_Pawn.Rotation.Yaw), 65535);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA8
	/*@Error*/
	YawDiff = __NFUN_147__(65536, YawDiff);
	return __NFUN_152__(YawDiff, MaxYawDelta);
	return;
	@NULL
	EcologyCommanderAction
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	ChargeDestination = Target.Location;
	log('AI', 4, __NFUN_168__(__NFUN_168__(string(m_Pawn.Name), "charging towards"), string(ChargeDestination)));
	ChargeStart = m_Pawn.Location;
	ChargeStartTime = m_Pawn.Level.TimeSeconds;
	ChargeDistance = __NFUN_228__(__NFUN_216__(ChargeStart, ChargeDestination));
	// End:0x100
	if(__NFUN_129__(IsRotationAlignedtoTarget(Target, 800)))
	{
		yield();
		goto J0xD6;
		Handle = m_Pawn.PlayAnimationOnChannel(0, TelegraphAnimationName, Class'Engine.Actor'.4);
		m_Pawn.FinishAnimation(Handle);
		bCharging = true;
		NoProgress = 0;
	}
	Handle = m_Pawn.PlayAnimationOnChannel(0, ChargeLoopAnimationName, Class'Engine.Actor'.8);
	// End:0x269
	if(__NFUN_130__(__NFUN_130__(__NFUN_176__(__NFUN_225__(__NFUN_216__(ChargeStart, m_Pawn.Location)), ChargeDistance), __NFUN_129__(HaveHitTarget())), __NFUN_150__(NoProgress, 2)))
	{
		// End:0x231
		if(__NFUN_217__(LastLocation, m_Pawn.Location))
		{
			__NFUN_165__(NoProgress);
			goto J0x23C;
			NoProgress = 0;
			LastLocation = m_Pawn.Location;
			yield();
			goto J0x1AB;
			// End:0x2B3
			if(HaveHitTarget())
			{
				Handle = m_Pawn.PlayAnimationOnChannel(0, ChargeHitAnimationName, Class'Engine.Actor'.2);
				goto J0x337;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x2FD
				/*@Error*/
				Handle = m_Pawn.PlayAnimationOnChannel(0, ChargeEndFacingTargetAnimationName, Class'Engine.Actor'.2);
				goto J0x337;
				Handle = m_Pawn.PlayAnimationOnChannel(0, ChargeEndAnimationName, Class'Engine.Actor'.2);
			}
			m_Pawn.FinishAnimation(Handle);
			log('AI', 4, __NFUN_168__(string(m_Pawn.Name), "charge ended."));
		}
		bCharging = false;
		succeed();
		stop;		
		@NULL
		@NULL
		@NULL
	}
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// BadToken (0x03)
	/*@Error*/
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.ChargeAttackGoal'
}