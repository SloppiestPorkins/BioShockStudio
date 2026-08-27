class FrozenAction extends BioshockCharacterAction
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

struct native atomic PreFrozenEasePausedState
{
	var int AnimHandle;
	var int EasePausedFlags;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

var private int FrozenAnimationHandle;
var array<PreFrozenEasePausedState> PreFrozenEasePausedFlags;
var private config int FrozenSpeechPriorityRestriction;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	ShockAI().AddColdResistance();
	ShockAI().NotifyFullBodyHitReactionPreventionDesired(self);
	ShockAI().NotifyFallDownHitReactionPreventionDesired(self);
	ShockAI().NotifyQuickHitReactionPreventionDesired(self);
	ShockAI().NotifyEventReactionPreventionDesired(self);
	ShockAI().SetSpeechPriorityRestriction(FrozenSpeechPriorityRestriction);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	Unfreeze();
	// End:0x57
	if(m_Pawn.IsAnimationHandleValid(FrozenAnimationHandle))
	{
		m_Pawn.SmartPerTrackEaseOutAnimation(FrozenAnimationHandle);
		ShockAI().NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
		ShockAI().NotifyFallDownHitReactionPreventionNoLongerDesired(self);
	}
	ShockAI().NotifyQuickHitReactionPreventionNoLongerDesired(self);
	ShockAI().NotifyEventReactionPreventionNoLongerDesired(self);
	ShockAI().SetSpeechPriorityRestriction(-1);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Freeze()
{
	local Ragdoll.ERagdollState CurrentRagdollState;

	CurrentRagdollState = m_Pawn.GetRagdoll().GetRagdollState();
	// End:0x7D
	if(__NFUN_132__(__NFUN_154__(int(CurrentRagdollState), int(0)), __NFUN_154__(int(CurrentRagdollState), int(3))))
	{
		m_Pawn.PauseAllAnimations();
		PauseAnimationEasing();
		goto J0xA2;
		m_Pawn.GetRagdoll().Freeze();
	}
	// End:0xE4
	if(__NFUN_119__(m_Pawn.GetQuickHitReaction(), none))
	{
		m_Pawn.GetQuickHitReaction().Freeze();
		ShockAI().FreezeAiming();
		ShockAI().FreezeHeadTracking();
	}
	ShockAI().SkeletonInstanceFreeze();
	UntriggerWeaponSoundEffects();
	m_Pawn.ForcePoseUpdate();
	TriggerFrozenEffect();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function UntriggerWeaponSoundEffects()
{
	local Weapon ActiveWeapon;

	ActiveWeapon = Weapon(ShockAI().GetActiveHoldable());
	// End:0x51
	if(__NFUN_119__(ActiveWeapon, none))
	{
		ActiveWeapon.UntriggerFiringSoundEffectEvents();
		return;
		@NULL
		CommanderAction
		EcologyFighterCommanderAction
	}
	@NULL
}

function Unfreeze()
{
	local Ragdoll.ERagdollState CurrentRagdollState;

	CurrentRagdollState = m_Pawn.GetRagdoll().GetRagdollState();
	// End:0x7D
	if(__NFUN_132__(__NFUN_154__(int(CurrentRagdollState), int(0)), __NFUN_154__(int(CurrentRagdollState), int(3))))
	{
		UnpauseAnimationEasing();
		m_Pawn.ResumeAllAnimations();
		goto J0xA2;
		m_Pawn.GetRagdoll().Unfreeze();
	}
	// End:0xE4
	if(__NFUN_119__(m_Pawn.GetQuickHitReaction(), none))
	{
		m_Pawn.GetQuickHitReaction().Unfreeze();
		ShockAI().UnfreezeAiming();
		ShockAI().UnfreezeHeadTracking();
	}
	ShockAI().SkeletonInstanceUnfreeze();
	ShockAI().RemoveColdResistance();
	ShockAI().StopSpeech('Frozen');
	UntriggerFrozenEffect();
	ShockAI().StopAnyWeaponAction();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function TriggerFrozenEffect()
{
	local name FrozenEffectTag;
	local int i;
	local Actor Attachment;

	// End:0x30
	if(m_Pawn.IsOnCeiling())
	{
		FrozenEffectTag = 'IsOnCeiling';
		goto J0x66;
		// End:0x66
		if(ShockAI(m_Pawn).IsOnSlope())
		{
		}
		FrozenEffectTag = 'IsOnSlope';
		ShockAI().TriggerEffectEvent('BecameFrozen',,,,,,,, FrozenEffectTag);
	}
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1DF
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1D1
	/*@Error*/
	Attachment = ShockAI().Attached[i];
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1D1
	/*@Error*/
	Attachment.TriggerEffectEvent('BecameFrozen',,,,,,,, FrozenEffectTag);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0xA2;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function UntriggerFrozenEffect()
{
	local name FrozenEffectTag;
	local Actor Attachment;
	local int i;

	// End:0x30
	if(m_Pawn.IsOnCeiling())
	{
		FrozenEffectTag = 'IsOnCeiling';
		goto J0x66;
		// End:0x66
		if(ShockAI(m_Pawn).IsOnSlope())
		{
		}
		FrozenEffectTag = 'IsOnSlope';
		ShockAI().UnTriggerEffectEvent('BecameFrozen', FrozenEffectTag);
	}
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1D1
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1C3
	/*@Error*/
	Attachment = ShockAI().Attached[i];
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1C3
	/*@Error*/
	Attachment.UnTriggerEffectEvent('BecameFrozen', FrozenEffectTag);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x9B;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

// Export UFrozenAction::execPauseAnimationEasing(FFrame&, void* const)
private native function PauseAnimationEasing();

// Export UFrozenAction::execUnpauseAnimationEasing(FFrame&, void* const)
private native function UnpauseAnimationEasing();

function PlayPostShatteredAnimation()
{
	local name PostShatteredAnimationName;

	PostShatteredAnimationName = ShockAI().GetPostShatteredAnimation();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xE0
	/*@Error*/
	FrozenAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, PostShatteredAnimationName);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xE0
	/*@Error*/
	yield();
	// [Loop Continue]
	goto J0x64;
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

state Running
{Begin:

	ShockAI().PlaySpeech('Frozen');
	Freeze();
	J0x2B:

	// End:0x5D [Loop If]
	if(__NFUN_129__(BioshockCharacterGoal(achievingGoal).ShouldFinishUp()))
	{
		yield();
		// [Loop Continue]
		goto J0x2B;
		Unfreeze();
	}
	// End:0xB2
	if(__NFUN_130__(__NFUN_178__(ShockAI().GetFrozenHealth(), 0.0000000), __NFUN_129__(ShockAI().ShouldDieWhenShattered())))
	{
		PlayPostShatteredAnimation();
		// End:0xE2
		if(BioshockCharacterGoal(achievingGoal).ShouldFinishUp())
		{
		}
		succeed();
		goto J0xEC;
		goto 'Begin';
		stop;						
	}
	@NULL
	@NULL
	@NULL
	@NULL
}

defaultproperties
{
	FrozenSpeechPriorityRestriction=2
	satisfiesGoal=Class'ShockAI.FrozenGoal'
	bExclusiveAction=true
}