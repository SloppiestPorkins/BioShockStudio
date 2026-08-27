class CommanderAction extends BioshockCharacterAction implements IHearingNotification
	abstract
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn CachedScriptedAttackTarget;
var(Parameters) bool bCachedShouldWait;
var private FrozenGoal CurrentFrozenGoal;
var private ShockedGoal CurrentShockedGoal;
var private BurningGoal CurrentBurningGoal;
var private WaitGoal CurrentWaitGoal;
var private ReactToDamageGoal CurrentReactToDamageGoal;
var private ReactToSwarmGoal CurrentReactToSwarmGoal;
var private int NumInsectSwarmsAttacking;
var private float NextTimeCanStartInsectSwarmReaction;
var private config float MinTimeBetweenStartingInsectSwarmReaction;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	log('AI', 3, __NFUN_112__(__NFUN_112__(string(Name), " initialized for AI: "), string(m_Pawn.Name)));
	m_Pawn.RegisterHearingNotification(self);
	// End:0xA4
	if(__NFUN_119__(CachedScriptedAttackTarget, none))
	{
		ScriptedAttackTarget(CachedScriptedAttackTarget);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xBB
		/*@Error*/
		ScriptedWait();
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	// End:0x33
	if(__NFUN_119__(CurrentFrozenGoal, none))
	{
		CurrentFrozenGoal.__NFUN_198__();
		CurrentFrozenGoal = none;
		// End:0x5C
		if(__NFUN_119__(CurrentShockedGoal, none))
		{
			CurrentShockedGoal.__NFUN_198__();
		}
		CurrentShockedGoal = none;
		// End:0x85
		if(__NFUN_119__(CurrentBurningGoal, none))
		{
			CurrentBurningGoal.__NFUN_198__();
			CurrentBurningGoal = none;
		}
		// End:0xAE
		if(__NFUN_119__(CurrentWaitGoal, none))
		{
			CurrentWaitGoal.__NFUN_198__();
			CurrentWaitGoal = none;
			// End:0xD7
			if(__NFUN_119__(CurrentReactToDamageGoal, none))
			{
			}
			CurrentReactToDamageGoal.__NFUN_198__();
			CurrentReactToDamageGoal = none;
			// End:0x100
			if(__NFUN_119__(CurrentReactToSwarmGoal, none))
			{
				CurrentReactToSwarmGoal.__NFUN_198__();
				CurrentReactToSwarmGoal = none;
			}
			ShockAI().NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
			ShockAI().StopSpeech('BeedUp');
		}
		log('AI', 3, __NFUN_112__(__NFUN_112__(string(Name), " cleaned up for AI: "), string(m_Pawn.Name)));
	}
	m_Pawn.UnregisterHearingNotification(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ScriptedAttackTarget(ShockPawn Target)
{
	log('AI', 2, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " ScriptedAttackTarget - told to attack: "), string(Target.Name)), ", but this hasn't been implemented for this AI!"));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ScriptedWait()
{
	// End:0x5D
	if(__NFUN_130__(__NFUN_119__(CurrentWaitGoal, none), CurrentWaitGoal.hasCompleted()))
	{
		CurrentWaitGoal.unPostGoal(self);
		CurrentWaitGoal.__NFUN_198__();
		CurrentWaitGoal = none;
		// End:0xD1
		if(__NFUN_114__(CurrentWaitGoal, none))
		{
			CurrentWaitGoal = Class'ShockAI.WaitGoal'.static.Allocate(self).;
		}
		construct_AI_Resource(characterResource());
		CurrentWaitGoal.__NFUN_199__();
		CurrentWaitGoal.postGoal(self);
		goto J0x12E;
		log('AI', 3, __NFUN_112__(string(m_Pawn.Name), " was told to wait, but that is already happening!"));
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ScriptedContinue()
{
	// End:0x44
	if(__NFUN_119__(CurrentWaitGoal, none))
	{
		CurrentWaitGoal.unPostGoal(self);
		CurrentWaitGoal.__NFUN_198__();
		CurrentWaitGoal = none;
		goto J0xA0;
		log('AI', 3, __NFUN_112__(string(m_Pawn.Name), " was told to continue, but the AI isn't waiting!"));
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnListenerHeardNoise(VPawn Listener, Actor SoundMaker, Vector SoundOrigin, Vector SoundDirection, name SoundCategory)
{
	local ShockPlayer Player;

	// End:0x4C
	if(__NFUN_130__(__NFUN_254__(SoundCategory, 'FootStep'), ShockGameInfo(Level().Game).bPlayerInvisible))
	{
		return;
		Player = ShockPlayer(m_Pawn.Level.GetLocalPlayerController().Pawn);
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x196
	/*@Error*/
	log('AI', 5, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Listener.Name), " Heard noise from: "), string(SoundMaker)), " SoundCategory: "), string(SoundCategory)), " SoundOrigin: "), string(SoundOrigin)));
	assert(__NFUN_114__(Listener, m_Pawn));
	OnHeardNoise(SoundMaker, SoundOrigin, SoundDirection, SoundCategory);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

protected function OnHeardNoise(Actor SoundMaker, Vector SoundOrigin, Vector SoundDirection, name SoundCategory)
{
	return;
}

function OnDamaged(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name HitLowBone, name HitHighBone, array<ShockPawn.EDamageEvent> DamageEvents)
{
	local int i;
	local bool ShouldTreatAsDamage;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x414
	/*@Error*/
	// End:0x14D
	if(Damager.__NFUN_303__('ShockPlayer'))
	{
		ShouldTreatAsDamage = false;
		i = 0;
		// End:0x13C
		if(__NFUN_150__(i, DamageStimuli.Stimulus.Length))
		{
			// End:0x12E
			if(__NFUN_130__(__NFUN_130__(__NFUN_155__(int(DamageStimuli.Stimulus[i].Type), int(27)), __NFUN_155__(int(DamageStimuli.Stimulus[i].Type), int(28))), __NFUN_155__(int(DamageStimuli.Stimulus[i].Type), int(6))))
			{
				ShouldTreatAsDamage = true;
				goto J0x13C;
				__NFUN_163__(i);
				// [Loop Continue]
				goto J0x42;
				// End:0x14D
				if(__NFUN_129__(ShouldTreatAsDamage))
				{
					return;
					/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
						
					*/

					// End:0x414
					/*@Error*/
					// End:0x1D8
					if(__NFUN_130__(__NFUN_130__(__NFUN_119__(CurrentBurningGoal, none), __NFUN_119__(Damager, m_Pawn)), Damager.__NFUN_303__('ShockPawn')))
					{
					}
					CurrentBurningGoal.unPostGoal(self);
				}
				CurrentBurningGoal.__NFUN_198__();
			}
		}
		CurrentBurningGoal = none;
		// End:0x252
		if(__NFUN_130__(__NFUN_130__(__NFUN_119__(CurrentReactToSwarmGoal, none), __NFUN_119__(Damager, m_Pawn)), __NFUN_129__(Damager.__NFUN_303__('InsectSwarm'))))
		{
			CurrentReactToSwarmGoal.unPostGoal(self);
			CurrentReactToSwarmGoal.__NFUN_198__();
			CurrentReactToSwarmGoal = none;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x414
			/*@Error*/
		}
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x414
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x406
		/*@Error*/
	}
	ShockAI().ClearShocked();
	goto J0x414;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x292;
	NotifyDamaged(Damager);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x47D
	/*@Error*/
	HandleDamageEvents(DamageEvents, DamageStimuli, HitLocation, HitNormal, HitImpulseDirection, HitLowBone, HitHighBone);
	return;
	@NULL
	EcologyCommanderAction
	CommanderAction
	@NULL
}

protected function NotifyDamaged(Actor Damager)
{
	return;
}

protected function bool ShouldHandleDamageEvents()
{
	return true;
	return;
}

function HandleDamageEvents(out array<ShockPawn.EDamageEvent> DamageEvents, DamageStimuliSet DamageStimuli, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name HitLowBone, name HitHighBone)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xC7
	/*@Error*/
	// End:0x65
	if(__NFUN_154__(int(DamageEvents[i]), int(3)))
	{
		ShockAI().PlayAdditiveHitReaction(HitNormal);
		goto J0xB9;
		NotifyReactToDamage(DamageEvents[i], HitLocation, HitNormal, HitImpulseDirection, HitLowBone, HitHighBone,, DamageStimuli);
	}
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyReactToDamage(ShockPawn.EDamageEvent DamageEvent, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name HitLowBone, name HitHighBone, optional float HitMomentumImparted, optional DamageStimuliSet DamageStimuli)
{
	// End:0x3D
	if(__NFUN_130__(__NFUN_154__(int(DamageEvent), int(1)), ShockAI().bPlayAnimationInsteadOfRagdollFall))
	{
		DamageEvent = 2;
		// End:0xD9
		if(__NFUN_130__(__NFUN_130__(__NFUN_154__(int(DamageEvent), int(1)), __NFUN_119__(CurrentShockedGoal, none)), __NFUN_129__(CurrentShockedGoal.hasCompleted())))
		{
		}
		CurrentShockedGoal.FallDown(HitLocation, HitNormal, HitImpulseDirection, HitMomentumImparted, HitLowBone, HitHighBone, DamageStimuli);
		goto J0x3BA;
		// End:0x16A
		if(__NFUN_154__(int(DamageEvent), int(4)))
		{
			// End:0x167
			if(__NFUN_130__(ShockAI().CanPlayQuickHitReaction(), __NFUN_119__(m_Pawn.GetQuickHitReaction(), none)))
			{
			}
			m_Pawn.GetQuickHitReaction().TakeHit(HitLocation, HitImpulseDirection, HitHighBone);
			goto J0x3BA;
			// End:0x248
			if(__NFUN_119__(CurrentReactToDamageGoal, none))
			{
				// End:0x248
				if(__NFUN_132__(__NFUN_132__(CurrentReactToDamageGoal.hasCompleted(), CurrentReactToDamageGoal.hasExpired()), __NFUN_130__(__NFUN_155__(int(CurrentReactToDamageGoal.DamageEvent), int(1)), __NFUN_132__(__NFUN_154__(int(DamageEvent), int(1)), __NFUN_154__(int(DamageEvent), int(2))))))
				{
				}
			}
			CurrentReactToDamageGoal.unPostGoal(self);
			CurrentReactToDamageGoal.__NFUN_198__();
			CurrentReactToDamageGoal = none;
			__NFUN_166__(m_Pawn.CantThrottleAICount);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x350
			/*@Error*/
			CurrentReactToDamageGoal = Class'ShockAI.ReactToDamageGoal'.static.Allocate(self).;
			construct_AI_ResourceByteVectorVectorVectorFloatDamageStimuliSetNameName(characterResource(), DamageEvent, HitLocation, HitNormal, HitImpulseDirection, HitMomentumImparted, DamageStimuli, HitLowBone, HitHighBone);
			CurrentReactToDamageGoal.__NFUN_199__();
			CurrentReactToDamageGoal.setExpirationTime(0.0000000);
		}
	}
	CurrentReactToDamageGoal.postGoal(self);
	m_Pawn.SetIgnoreLODCount(1);
	__NFUN_165__(m_Pawn.CantThrottleAICount);
	goto J0x3BA;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x3BA
	/*@Error*/
	CurrentReactToDamageGoal.Fall(HitLocation, HitNormal, HitImpulseDirection, HitMomentumImparted, DamageStimuli, HitLowBone, HitHighBone);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool IsReactingToDamage()
{
	return __NFUN_130__(__NFUN_119__(CurrentReactToDamageGoal, none), __NFUN_129__(CurrentReactToDamageGoal.hasCompleted()));
	return;
	@NULL
	CommanderAction
}

function OnDealtDamage(Actor Damagee)
{
	return;
}

protected function CheckForVisiblePawnsToAttack()
{
	return;
}

function QuickLook(Actor Target, optional float Duration, optional Vector Offset)
{
	return;
}

function CasualLook(Actor Target, optional float Duration, optional Vector Offset)
{
	return;
}

function StopTracking()
{
	return;
}

function bool IsTracking()
{
	return;
}

function HandleAIEventNotification(AIEventNotification Event)
{
	return;
}

function HandleAIAttackNotification(Actor Attacker, float InitiateDamageDelay, DamageStimuliSet.EDamageType DamageType)
{
	return;
}

function bool CanReactToAttack()
{
	return false;
	return;
}

function OnAcquiredState(name StateName, Actor Instigator)
{
	log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " OnAcquiredState - state is: "), string(StateName)), " Instigator is: "), string(Instigator)));
	switch(StateName)
	{
		// End:0x8E
		case 'Diseased':
			StartDiseasedBehavior();
			// End:0x158
			break;
			// End:0xA7
			case 'Burning':
				StartBurningBehavior();
			// End:0x158
			break;
			// End:0xC0
			case 'Frozen':
				StartFrozenBehavior();
			// End:0x158
			break;
			// End:0xD9
			case 'Berserk':
				StartBerserkBehavior();
			// End:0x158
			break;
			// End:0xF2
			case 'Shocked':
				StartShockedBehavior();
			// End:0x158
			break;
			// End:0xFFFF
			default:
				log('AI', 2, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " OnAcquiredState - state passed ("), string(StateName)), ") was not handled."));
				break;/* Tried to find Switch scope, found Case instead */
		return;
		@NULL
		CommanderAction
		CommanderAction
		@NULL
	}
}

function OnUnAcquiredState(name StateName)
{
	log('AI', 4, __NFUN_112__(__NFUN_112__(string(Name), " OnUnAcquiredState - state is: "), string(StateName)));
	switch(StateName)
	{
		// End:0x6F
		case 'Diseased':
			StopDiseasedBehavior();
			// End:0x13B
			break;
			// End:0x88
			case 'Burning':
			StopBurningBehavior();
			// End:0x13B
			break;
			// End:0xA1
			case 'Frozen':
			StopFrozenBehavior();
			// End:0x13B
			break;
			// End:0xBA
			case 'Berserk':
			StopBerserkBehavior();
			// End:0x13B
			break;
			// End:0xD3
			case 'Shocked':
			StopShockedBehavior();
			// End:0x13B
			break;
			// End:0xFFFF
			default:
				log('AI', 2, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " OnUnAcquiredState - state passed ("), string(StateName)), ") was not handled."));
				break;/* Tried to find Switch scope, found Case instead */
		return;
		@NULL
		CommanderAction
		CommanderAction
		@NULL
	}
}

private function StartDiseasedBehavior()
{
	ShockAI().PlaySpeech('Diseased');
	return;
}

private function StopDiseasedBehavior()
{
	ShockAI().StopSpeech('Diseased');
	return;
}

function StartBurningBehavior()
{
	// End:0x3F
	if(__NFUN_129__(ShockAI().bDoNotDoBurningAnimations))
	{
		ShockAI().AddLocomotionKeyword('Burning', 1);
		ShockAI().NotifyFullBodyHitReactionPreventionDesired(self);
	}
	ShockAI().PlaySpeech('Burning');
	CreateBurningBehavior();
	return;
	@NULL
}

function CreateBurningBehavior()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x90
	/*@Error*/
	CurrentBurningGoal = Class'ShockAI.BurningGoal'.static.Allocate(self).;
	construct_AI_Resource(characterResource());
	CurrentBurningGoal.__NFUN_199__();
	CurrentBurningGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function StopBurningBehavior()
{
	ShockAI().AddLocomotionKeyword('Burning', Class'ShockAI.ShockAI'.-1);
	ShockAI().NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
	ShockAI().StopSpeech('Burning');
	// End:0xAE
	if(__NFUN_119__(CurrentBurningGoal, none))
	{
		CurrentBurningGoal.unPostGoal(self);
		CurrentBurningGoal.__NFUN_198__();
		CurrentBurningGoal = none;
		RemoveBurningBehavior();
		return;
		@NULL
		CommanderAction
	}
	EcologyFighterCommanderAction
	@NULL
}

protected function RemoveBurningBehavior()
{
	return;
}

protected function StartBerserkBehavior()
{
	ShockAI().PlaySpeech('Berserk');
	ShockAI().NotifyBerserkVisionDesired();
	CheckForVisiblePawnsToAttack();
	return;
}

protected function StopBerserkBehavior()
{
	ShockAI().StopSpeech('Berserk');
	ShockAI().NotifyBerserkVisionNoLongerDesired();
	return;
}

function StartFrozenBehavior()
{
	// End:0x75
	if(__NFUN_119__(CurrentFrozenGoal, none))
	{
		// End:0x5E
		if(CurrentFrozenGoal.hasCompleted())
		{
			CurrentFrozenGoal.unPostGoal(self);
			CurrentFrozenGoal.__NFUN_198__();
			CurrentFrozenGoal = none;
			goto J0x75;
			CurrentFrozenGoal.CancelFinishUp();
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0xE6
			/*@Error*/
		}
		CurrentFrozenGoal = Class'ShockAI.FrozenGoal'.static.Allocate(self).;
	}
	construct_AI_Resource(characterResource());
	CurrentFrozenGoal.__NFUN_199__();
	CurrentFrozenGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function StopFrozenBehavior()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x26
	/*@Error*/
	CurrentFrozenGoal.FinishUp();
	return;
	@NULL
	CommanderAction
}

function StartShockedBehavior()
{
	local bool bShouldRagdollIntoShocked;

	// End:0x5D
	if(__NFUN_130__(__NFUN_119__(CurrentShockedGoal, none), CurrentShockedGoal.hasCompleted()))
	{
		CurrentShockedGoal.unPostGoal(self);
		CurrentShockedGoal.__NFUN_198__();
		CurrentShockedGoal = none;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x167
		/*@Error*/
		// End:0xF8
		if(__NFUN_132__(__NFUN_132__(m_Pawn.IsOnCeiling(), __NFUN_154__(int(m_Pawn.Physics), int(4))), __NFUN_130__(m_Pawn.__NFUN_303__('Aggressor'), Aggressor(m_Pawn).IsMimic())))
		{
		}
		bShouldRagdollIntoShocked = true;
		CurrentShockedGoal = Class'ShockAI.ShockedGoal'.static.Allocate(self).;
		construct_AI_ResourceBool(characterResource(), bShouldRagdollIntoShocked);
	}
	CurrentShockedGoal.__NFUN_199__();
	CurrentShockedGoal.postGoal(self);
	goto J0x17E;
	CurrentShockedGoal.CancelFinishUp();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function StopShockedBehavior()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x26
	/*@Error*/
	CurrentShockedGoal.FinishUp();
	return;
	@NULL
	CommanderAction
}

function StartAttackedByInsectSwarmBehavior()
{
	__NFUN_163__(NumInsectSwarmsAttacking);
	log('AI', 4, __NFUN_112__("++NumInsectSwarmsAttacking: ", string(NumInsectSwarmsAttacking)));
	// End:0xA6
	if(__NFUN_129__(ShockAI().bDoNotDoInsectSwarmAnimations))
	{
		ShockAI().AddLocomotionKeyword('Burning', 1);
		ShockAI().PlaySpeech('BeedUp');
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x20D
		/*@Error*/
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x20D
	/*@Error*/
	// End:0x170
	if(__NFUN_119__(CurrentReactToSwarmGoal, none))
	{
		CurrentReactToSwarmGoal.unPostGoal(self);
		CurrentReactToSwarmGoal.__NFUN_198__();
		CurrentReactToSwarmGoal = none;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x1E1
		/*@Error*/
		CurrentReactToSwarmGoal = Class'ShockAI.ReactToSwarmGoal'.static.Allocate(self).;
		construct_AI_Resource(characterResource());
	}
	CurrentReactToSwarmGoal.__NFUN_199__();
	CurrentReactToSwarmGoal.postGoal(self);
	NextTimeCanStartInsectSwarmReaction = __NFUN_174__(Level().TimeSeconds, MinTimeBetweenStartingInsectSwarmReaction);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function StopAttackedByInsectSwarmBehavior()
{
	__NFUN_164__(NumInsectSwarmsAttacking);
	log('AI', 4, __NFUN_112__("--NumInsectSwarmsAttacking: ", string(NumInsectSwarmsAttacking)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xEA
	/*@Error*/
	ShockAI().AddLocomotionKeyword('Burning', Class'ShockAI.ShockAI'.-1);
	ShockAI().StopSpeech('BeedUp');
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xEA
	/*@Error*/
	CurrentReactToSwarmGoal.unPostGoal(self);
	CurrentReactToSwarmGoal.__NFUN_198__();
	CurrentReactToSwarmGoal = none;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool IsBeingAttackedByInsectSwarm()
{
	return __NFUN_151__(NumInsectSwarmsAttacking, 0);
	return;
	@NULL
}

defaultproperties
{
	MinTimeBetweenStartingInsectSwarmReaction=7.0000000
	satisfiesGoal=Class'ShockAI.CommanderGoal'
}