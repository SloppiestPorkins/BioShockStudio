class TeleportAction extends BioshockCharacterAction
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

enum ETeleportPointScore
{
	kNotGoodPoint,                  // 0
	kUsablePoint,                   // 1
	kDesiredPoint                   // 2
};

var(Parameters) private Actor TeleportAnchor;
var(Parameters) private Vector TeleportLocation;
var(Parameters) private bool TeleportRightNow;
var(Parameters) private bool UseOverriddenRotation;
var(Parameters) private Rotator OverriddenRotation;
var(Parameters) private bool SkipTimeInEther;
var private Vector TeleportDestination;
var config Range TeleportDistanceRange;
var config float TeleportDesiredMinDistance;
var private config Range TeleportTimeRange;
var config float TeleportOutTelegraphTime;
var config float TeleportOutTransitionTime;
var config float TeleportInTelegraphTime;
var config float ExtendedTeleportInTelegraphTime;
var config float TeleportInTransitionTime;
var private config float TeleportPointBias;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	Goal.goalName = string(Goal.Name);
	ShockAI().AddFrozenResistance();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	Assassin(m_Pawn).ResetOriginalSkin();
	// End:0x85
	if(ShockAI().IsTeleportingOut())
	{
		m_Pawn.UnTriggerEffectEvent('TeleportOutStage_1');
		m_Pawn.UnTriggerEffectEvent('TeleportOutStage_2');
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x192
		/*@Error*/
	}
	m_Pawn.__NFUN_262__(true, true, true);
	// End:0xED
	if(Class'Engine.Pawn'.static.checkAlive(m_Pawn))
	{
		m_Pawn.HavokInitActor();
		m_Pawn.SetHidden(false);
		m_Pawn.bCastSimpleShadow = m_Pawn.default.bCastSimpleShadow;
	}
	m_Pawn.SetCastShadowMapShadow(m_Pawn.default.bCastShadowMapShadow);
	ShockAI().RetriggerStateEffects();
	ShockAI().RetriggerSecurityBeaconEffect();
	ShockAI().TeleportState = 0;
	ShockAI().RemoveFrozenResistance();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

// Export UTeleportAction::execFindTeleportLocation(FFrame&, void* const)
private native function FindTeleportLocation();

function TeleportOutStage_1()
{
	ShockAI().TeleportState = 3;
	m_Pawn.__NFUN_262__(true, false, false);
	m_Pawn.TriggerEffectEvent('TeleportOutStage_1');
	m_Pawn.TriggerEffectEvent('TeleportOutStage1Sound');
	SetTeleportExplosion(3);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function TeleportOutStage_2()
{
	ShockAI().TeleportState = 4;
	m_Pawn.UnTriggerEffectEvent('TeleportOutStage_1');
	m_Pawn.TriggerEffectEvent('TeleportOutStage_2');
	m_Pawn.TriggerEffectEvent('TeleportOutStage2Sound');
	m_Pawn.SetSkin(0, ShockAI().TeleportOutTransitionShader);
	ShockAI().HideAIAttachments();
	m_Pawn.bCastSimpleShadow = false;
	m_Pawn.SetCastShadowMapShadow(false);
	m_Pawn.__NFUN_262__(false, false, false);
	m_Pawn.HavokQuitActor();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function TeleportOutFinish()
{
	m_Pawn.UnTriggerEffectEvent('TeleportOutStage_2');
	m_Pawn.TriggerEffectEvent('TeleportOutFinish');
	m_Pawn.TriggerEffectEvent('TeleportedOut');
	m_Pawn.SetHidden(true);
	ShockAI().TeleportState = 5;
	Class'ShockGame.CrossbowProjectile'.static.DetachAnyCrossbowBoltsFromActor(m_Pawn);
	SetTeleportExplosion(5);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function TeleportInStage_1()
{
	local Rotator NewRotation;

	m_Pawn.SetHidden(false);
	// End:0x5D
	if(UseOverriddenRotation)
	{
		NewRotation.Yaw = OverriddenRotation.Yaw;
		goto J0x100;
		// End:0xBE
		if(__NFUN_119__(TeleportAnchor, none))
		{
			NewRotation.Yaw = Rotator(__NFUN_216__(TeleportAnchor.Location, TeleportDestination)).Yaw;
		}
		goto J0x100;
		NewRotation.Yaw = Rotator(__NFUN_216__(TeleportLocation, TeleportDestination)).Yaw;
		m_Pawn.__NFUN_267__(TeleportDestination);
		m_Pawn.__NFUN_299__(NewRotation);
	}
	m_Pawn.__NFUN_262__(true, true, true);
	m_Pawn.SetSkin(0, ShockAI().TeleportInTelegraphShader);
	m_Pawn.UnTriggerEffectEvent('TeleportedOut');
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x288
	/*@Error*/
	m_Pawn.TriggerEffectEvent('TeleportInStage_1',,,,,,,, 'Extended');
	m_Pawn.TriggerEffectEvent('TeleportInStage1Sound',,,,,,,, 'Extended');
	__NFUN_256__(__NFUN_175__(ExtendedTeleportInTelegraphTime, TeleportInTelegraphTime));
	ShockAI().TeleportState = 1;
	__NFUN_256__(TeleportInTelegraphTime);
	goto J0x2EE;
	m_Pawn.TriggerEffectEvent('TeleportInStage_1');
	m_Pawn.TriggerEffectEvent('TeleportInStage1Sound');
	ShockAI().TeleportState = 1;
	__NFUN_256__(TeleportInTelegraphTime);
	SetTeleportExplosion(1);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function TeleportInStage_2()
{
	ShockAI().TeleportState = 2;
	m_Pawn.SetSkin(0, ShockAI().TeleportInTransitionShader);
	m_Pawn.TriggerEffectEvent('TeleportInStage_2');
	m_Pawn.TriggerEffectEvent('TeleportInStage2Sound');
	ShockAI().RetriggerStateEffects();
	ShockAI().RetriggerSecurityBeaconEffect();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function TeleportInFinish()
{
	ShockAI().ShowAIAttachments();
	m_Pawn.HavokInitActor();
	m_Pawn.bCastSimpleShadow = m_Pawn.default.bCastSimpleShadow;
	m_Pawn.SetCastShadowMapShadow(m_Pawn.default.bCastShadowMapShadow);
	Assassin(m_Pawn).ResetOriginalSkin();
	m_Pawn.TriggerEffectEvent('TeleportInFinish');
	ShockAI().TeleportState = 0;
	SetTeleportExplosion(0);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function SetupTeleportPoint()
{
	local Actor NextTeleportPoint;

	NextTeleportPoint = Assassin(m_Pawn).GetNextTeleportPoint();
	log('AI', 4, __NFUN_112__(__NFUN_112__(string(Name), " NextTeleportPoint: "), string(NextTeleportPoint)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xDC
	/*@Error*/
	TeleportDestination = NextTeleportPoint.Location;
	m_Pawn.GetPointOnFloor(TeleportDestination);
	Assassin(m_Pawn).ClearNextTeleportPoint();
	goto J0xE6;
	FindTeleportLocation();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function SetTeleportExplosion(ShockAI.ETeleportState State)
{
	local Assassin Assassin;

	Assassin = Assassin(ShockAI());
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xD6
	/*@Error*/
	switch(State)
	{
		// End:0x73
		case 3:
			Assassin.SetTeleportInExplosionEnabled(true);
			// End:0xD6
			break;
			// End:0x93
			case 5:
				Assassin.SetTeleportInExplosionEnabled(false);
			// End:0xD6
			break;
			// End:0xB3
			case 1:
				Assassin.SetTeleportOutExplosionEnabled(true);
				// End:0xD6
				break;
			// End:0xD3
			case 0:
				Assassin.SetTeleportOutExplosionEnabled(false);
				// End:0xD6
				break;
				// End:0xFFFF
				default:
					return;
					break;
			}/* !MISMATCHING REMOVE, tried Switch got Type:Case Position:0x093! */
		@NULL
		CommanderAction
		CommanderAction
		@NULL
	// Failed to format remaining nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 724
	// 1 & Type:Switch Position:0x0D6
}

state Running
{Begin:

	ShockAI().UntriggerStateEffects(false);
	ShockAI().UntriggerSecurityBeaconEffect();
	ShockAI().RemoveAllOverlays();
	// End:0xB4
	if(__NFUN_129__(TeleportRightNow))
	{
		TeleportOutStage_1();
		__NFUN_256__(TeleportOutTelegraphTime);
		TeleportOutStage_2();
		__NFUN_256__(TeleportOutTransitionTime);
		// End:0xB1
		if(Class'Engine.Pawn'.static.checkAlive(m_Pawn))
		{
			TeleportOutFinish();
			goto J0x13F;
			ShockAI().HideAIAttachments();
		}
	}
	m_Pawn.SetHidden(true);
	m_Pawn.bCastSimpleShadow = false;
	m_Pawn.SetCastShadowMapShadow(false);
	m_Pawn.__NFUN_262__(false, false, false);
	m_Pawn.HavokQuitActor();
	m_Pawn.dispatchMessage(Class'ShockAI.MessageAssassinTeleportedOut'.static.Allocate(self)., construct_AssassinStr(Assassin(m_Pawn), achievingGoal.goalName));
	// End:0x1F8
	if(__NFUN_129__(SkipTimeInEther))
	{
		__NFUN_256__(RandRange(TeleportTimeRange.Min, TeleportTimeRange.Max));
		goto J0x202;
		yield();
		SetupTeleportPoint();
		TeleportInStage_1();
		TeleportInStage_2();
		__NFUN_256__(TeleportInTransitionTime);
		TeleportInFinish();
		succeed();
		stop;						
		@NULL
		@NULL
		@NULL
		@NULL
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

defaultproperties
{
	TeleportDistanceRange=(Min=350.0000000,Max=1200.0000000)
	TeleportDesiredMinDistance=700.0000000
	TeleportTimeRange=(Min=1.0000000,Max=2.0000000)
	TeleportOutTelegraphTime=1.0000000
	TeleportOutTransitionTime=0.5000000
	TeleportInTelegraphTime=0.4000000
	ExtendedTeleportInTelegraphTime=2.0000000
	TeleportInTransitionTime=1.0000000
	TeleportPointBias=0.5000000
	satisfiesGoal=Class'ShockAI.TeleportGoal'
}