class AtlasCommanderAction extends EcologyFighterCommanderAction
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private HeadTrackingGoal CurrentHeadTrackingGoal;
var Atlas Atlas;
var ShockPawn Target;

function Cleanup()
{
	super.Cleanup();
	ShockAI().StopSpeech('Idling');
	// End:0x54
	if(__NFUN_119__(CurrentHeadTrackingGoal, none))
	{
		CurrentHeadTrackingGoal.__NFUN_198__();
		CurrentHeadTrackingGoal = none;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function bool ShouldHandleDamageEvents()
{
	return Atlas.CanBeDamaged();
	return;
	@NULL
}

function SetAttackTarget(ShockPawn inAttackTarget)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x7C
	/*@Error*/
	super.SetAttackTarget(inAttackTarget);
	return;
	@NULL
	CommanderAction
	stop;
	stop;
	@NULL
}

function ClearAttackTarget()
{
	// End:0x41
	if(__NFUN_119__(CurrentAttackTargetGoal, none))
	{
		CurrentAttackTargetGoal.unPostGoal(self);
		CurrentAttackTargetGoal.__NFUN_198__();
		CurrentAttackTargetGoal = none;
		CurrentAttackTarget = none;
		return;
		@NULL
		CommanderAction
	}
	EcologyFighterCommanderAction
	@NULL
}

function QuickLook(Actor Target, optional float Duration, optional Vector Offset)
{
	HeadTrackingAction(CurrentHeadTrackingGoal.achievingAction).QuickLook(Target, Duration, Offset);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function CasualLook(Actor Target, optional float Duration, optional Vector Offset)
{
	HeadTrackingAction(CurrentHeadTrackingGoal.achievingAction).CasualLook(Target, Duration, Offset);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function StopTracking()
{
	HeadTrackingAction(CurrentHeadTrackingGoal.achievingAction).StopTracking();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function bool IsTracking()
{
	return HeadTrackingAction(CurrentHeadTrackingGoal.achievingAction).IsTracking();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function WaitForDeath()
{
	J0x00:
	// End:0x3F [Loop If]
	if(__NFUN_177__(Atlas.GetHealth(), Atlas.RechargeThreshold))
	{
		yield();
		// [Loop Continue]
		goto J0x00;
		return;
		@NULL
		EcologyAI
	}
	CommanderAction
}

function WaitForAdamDrainBasedOnAdamLevel(float MaxTime)
{
	local float MinAdam, InitialAdam;

	InitialAdam = Atlas.AdamPercentage;
	MinAdam = __NFUN_175__(Atlas.AdamPercentage, Atlas.MaxAdamDrainPercentage);
	// End:0x97
	if(__NFUN_179__(MaxTime, float(0)))
	{
		__NFUN_184__(MaxTime, Atlas.Level.TimeSeconds);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x187
		/*@Error*/
	}
	Atlas.RemoveAllOverlays();
	yield();
	// [Loop Continue]
	goto J0x97;
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function WaitForAdamDrainBasedOnHealth(bool bReleaseAtFullHealth)
{
	J0x00:
	// End:0xAB [Loop If]
	if(__NFUN_130__(__NFUN_130__(__NFUN_177__(Atlas.AdamPercentage, float(0)), __NFUN_132__(__NFUN_132__(__NFUN_129__(bReleaseAtFullHealth), Atlas.bAdamDraining), __NFUN_176__(Atlas.GetHealth(), Atlas.GetMaxHealth()))), __NFUN_129__(Atlas.bAdamWasDrained)))
	{
		yield();
		// [Loop Continue]
		goto J0x00;
		return;
		@NULL
		EcologyAI
		CommanderAction
		@NULL
	}
}

function TeleportOut()
{
	local int Handle;

	assert(__NFUN_114__(CurrentAttackTargetGoal, none));
	__NFUN_165__(Atlas.TeleportCounter);
	Atlas.dispatchMessage(Class'ShockAI.MessageAtlasTeleports'.static.Allocate(self)., construct_Int(Atlas.TeleportCounter));
	Atlas.PlaySpeech('AtlasTeleportOut');
	Atlas.bTeleporting = true;
	Atlas.__NFUN_3970__(3);
	Handle = Atlas.PlayAnimationOnChannel(0, Atlas.TeleportAnimationName, Class'Engine.Actor'.4);
	Atlas.__NFUN_262__(true, false, false);
	Atlas.TriggerEffectEvent('TeleportOutStage_1');
	Atlas.TriggerEffectEvent('TeleportOutStage1Sound');
	__NFUN_256__(Atlas.TeleportOutTelegraphTime);
	Atlas.UnTriggerEffectEvent('TeleportOutStage_1');
	Atlas.TriggerEffectEvent('TeleportOutStage_2');
	Atlas.TriggerEffectEvent('TeleportOutStage2Sound');
	Atlas.SetSkin(0, Atlas.GetTeleportOutTransitionShader());
	Atlas.HideAIAttachments();
	Atlas.bCastSimpleShadow = false;
	Atlas.SetCastShadowMapShadow(false);
	Atlas.__NFUN_262__(false, false, false);
	Atlas.HavokQuitActor();
	__NFUN_256__(Atlas.TeleportOutTransitionTime);
	Atlas.StopAnimation(Handle);
	Atlas.UnTriggerEffectEvent('TeleportOutStage_2');
	Atlas.TriggerEffectEvent('TeleportOutFinish');
	Atlas.TriggerEffectEvent('TeleportedOut');
	Atlas.SetHidden(true);
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function TeleportIn()
{
	local Actor TeleportPoint;

	TeleportPoint = Atlas.GetTeleportPoint();
	Atlas.__NFUN_267__(__NFUN_215__(TeleportPoint.Location, vect(0.0000000, 0.0000000, 17.3162804)), true);
	Atlas.__NFUN_299__(TeleportPoint.Rotation);
	Atlas.InstantStartIdleLoop();
	Atlas.SetHidden(false);
	Atlas.SetSkin(0, Atlas.GetTeleportInTelegraphShader());
	Atlas.UnTriggerEffectEvent('TeleportedOut');
	Atlas.TriggerEffectEvent('TeleportInStage_1');
	Atlas.TriggerEffectEvent('TeleportInStage1Sound');
	__NFUN_256__(Atlas.TeleportInTelegraphTime);
	Atlas.SetSkin(0, Atlas.GetTeleportInTransitionShader());
	Atlas.TriggerEffectEvent('TeleportInStage_2');
	Atlas.TriggerEffectEvent('TeleportInStage2Sound');
	__NFUN_256__(Atlas.TeleportInTransitionTime);
	Atlas.ShowAIAttachments();
	Atlas.__NFUN_262__(true, false, true);
	Atlas.__NFUN_3970__(0);
	Atlas.HavokInitActor();
	Atlas.bCastSimpleShadow = m_Pawn.default.bCastSimpleShadow;
	Atlas.SetCastShadowMapShadow(m_Pawn.default.bCastShadowMapShadow);
	Atlas.SetSkin(0, Atlas.GetNormalSkin());
	Atlas.TriggerEffectEvent('TeleportInFinish');
	Atlas.bInChair = true;
	Atlas.bTeleporting = false;
	Atlas.FlashTweenStartTime = Atlas.Level.TimeSeconds;
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function AtlasGetsOutOfChair()
{
	local int HandleAtlas, HandleChair;

	Atlas.Health = Atlas.GetMaxHealth();
	Atlas.RemoveAllOverlays();
	Atlas.bInChair = false;
	Atlas.bIsJumping = true;
	Atlas.__NFUN_262__(false, false, false);
	Atlas.bCollideWorld = false;
	Atlas.__NFUN_3970__(3);
	ShockPlayer(Target).EndHarvestingAdam();
	__NFUN_165__(Atlas.KnockBackCounter);
	Atlas.dispatchMessage(Class'ShockAI.MessageAtlasHasKnockedPlayerBack'.static.Allocate(self)., construct_Int(Atlas.KnockBackCounter));
	// End:0x22A
	if(Atlas.IsAtDrainingPosition(Atlas.Level.GetLocalPlayerController().Pawn))
	{
		HandleAtlas = Atlas.PlayAnimationOnChannel(0, Atlas.GetUpFromChairAnimationName, Class'Engine.Actor'.2);
		HandleChair = Atlas.AtlasChair.PlayAnimationOnChannel(0, Atlas.ChairGetUpFromChairAnimationName, Class'Engine.Actor'.2);
		goto J0x2C5;
		HandleAtlas = Atlas.PlayAnimationOnChannel(0, Atlas.GetUpFromChairNoKnockbackAnimationName, Class'Engine.Actor'.2);
		HandleChair = Atlas.AtlasChair.PlayAnimationOnChannel(0, Atlas.ChairGetUpFromChairNoKnockbackAnimationName, Class'Engine.Actor'.2);
		Atlas.FinishAnimation(HandleAtlas);
		Atlas.bIsJumping = false;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x366
		/*@Error*/
	}
	Atlas.Level.GetLocalPlayerController().ConsoleCommand("POPINPUTCONTEXT NullInput");
	HandleChair = Atlas.AtlasChair.PlayAnimationOnChannel(0, Atlas.ChairIdleAnimationName, Class'Engine.Actor'.8);
	Atlas.__NFUN_3970__(2);
	Atlas.bCollideWorld = true;
	Atlas.__NFUN_262__(true, true, true);
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function StopAttack()
{
	Atlas.StopAnyWeaponAction();
	// End:0x6D
	if(__NFUN_130__(__NFUN_119__(Atlas.GetActiveHoldable(), none), Atlas.GetActiveHoldable().__NFUN_281__('Firing')))
	{
		yield();
		// [Loop Continue]
		goto J0x17;
		ClearAttackTarget();
		Atlas.ClearForcedEnemies();
	}
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

state Running
{Begin:

	Atlas = Atlas(m_Pawn);
	Target = ShockPlayer(m_Pawn.Level.GetLocalPlayerController().Pawn);
	Atlas.bInChair = true;
	Atlas.__NFUN_262__(true, false, true);
	Atlas.__NFUN_3970__(0);
	// End:0x10E
	if(__NFUN_114__(CurrentHeadTrackingGoal, none))
	{
		CurrentHeadTrackingGoal = HeadTrackingGoal(Class'ShockAI.HeadTrackingGoal'.static.Allocate(self)..@NULL.none);
		@NULL
		Aggressor				
		EcologyFighterCommanderAction
		postGoal(self);
		// End:0x400
		case myAddRef():
			WaitForAdamDrainBasedOnHealth(false);
			Atlas.SetSkin(0, Atlas.AtlasSkinFire);
			Atlas.FlashTweenTotalTime = __NFUN_172__(Atlas.GetMaxHealth(), Atlas.GetHealthRechargeRate());
		}/* !MISMATCHING REMOVE, tried If got Type:Case Position:0x0C7! */
		// End:0x2EB
		if(__NFUN_177__(Atlas.AdamPercentage, float(0)))
		{
			AtlasGetsOutOfChair();
			SetAttackTarget(Target);
			WaitForDeath();
			StopAttack();
			TeleportOut();
			__NFUN_256__(RandRange(Atlas.TeleportTimeRange.Min, Atlas.TeleportTimeRange.Max));
			TeleportIn();
			Atlas.bAdamWasDrained = false;
			WaitForAdamDrainBasedOnHealth(true);
			// End:0x2E8
			if(Atlas.bAdamWasDrained)
			{
				Atlas.NewPhase();
				Atlas.FlashTweenTotalTime = __NFUN_172__(Atlas.GetMaxHealth(), Atlas.GetHealthRechargeRate());
				// [Loop Continue]
				goto J0x18E;
				ShockPlayer(Target).EndHarvestingAdam();
				Atlas.TakeSimpleDamage(36, __NFUN_171__(2.0000000, Atlas.GetMaxHealth()), 1.0000000, Atlas);
				log(,, "@@@@@@ PLAY FINAL CUTSCENE: GATHERERS COME IN - KILL ATLAS - GAME ENDS!");
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

		// BadToken (0x03)
		/*@Error*/
		// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.get_CurrentToken() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 40
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 845
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
		// 1 & Type:Case Position:0x400/* !MISMATCHING REMOVE, tried Case got Type:If Position:0x06A! */
}

defaultproperties
{
	RecentlySeenTime=10000000000.0000000
}