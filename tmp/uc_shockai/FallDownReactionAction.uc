class FallDownReactionAction extends BioshockCharacterAction
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn.EDamageEvent DamageEvent;
var(Parameters) Vector HitLocation;
var(Parameters) Vector HitNormal;
var(Parameters) Vector HitImpulseDirection;
var(Parameters) float HitMomentumImparted;
var(Parameters) float MomentumScale;
var(Parameters) name HitLowBone;
var(Parameters) name HitHighBone;
var(Parameters) DamageStimuliSetState HitDamageStimuliSetState;
var private bool bUsingAIRagdollCollisionListener;
var private bool bFellEffectTriggered;
var private float InitialFlailingTime;
var private int FlailAnimationHandle;
var config Range TimeToWaitBeforeFlailingRange;

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	// End:0x4D
	if(m_Pawn.IsAnimationHandleValid(FlailAnimationHandle))
	{
		m_Pawn.SmartPerTrackEaseOutAnimation(FlailAnimationHandle);
		m_Pawn.UnTriggerEffectEvent('fell');
	}
	m_Pawn.UnTriggerEffectEvent('HitByAirBlast');
	m_Pawn.UnTriggerEffectEvent('HitBySpringBoardTrap');
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function float selectionHeuristic(AI_Goal Goal)
{
	local ShockAI AI;

	assert(Goal.__NFUN_303__('ReactToDamageGoal'));
	AI = ShockAI(Goal.resource.Pawn());
	assert(__NFUN_119__(AI, none));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xD7
	/*@Error*/
	return 1.0000000;
	goto J0xDD;
	return 0.0000000;
	return;
	@NULL
	CommanderAction
	Class'ShockAI.CommanderAction'
	@NULL
}

function Fall(Vector inHitLocation, Vector inHitNormal, Vector inHitImpulseDirection, float inHitMomentumImparted, float inMomentumScale, DamageStimuliSetState inHitDamageStimuliSetState, name inHitLowBone, name inHitHighBone)
{
	HitLocation = inHitLocation;
	HitNormal = inHitNormal;
	HitImpulseDirection = inHitImpulseDirection;
	HitMomentumImparted = inHitMomentumImparted;
	MomentumScale = inMomentumScale;
	HitLowBone = inHitLowBone;
	HitHighBone = inHitHighBone;
	HitDamageStimuliSetState = inHitDamageStimuliSetState;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xC7
	/*@Error*/
	m_Pawn.TriggerEffectEvent('fell');
	__NFUN_113__('None');
	__NFUN_113__('Running');
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function DelayOnGround()
{
	local float DelayTime;

	DelayTime = ShockAI().GetDelayOnGroundTime();
	log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " will delay on ground for "), string(DelayTime)), " seconds."));
	__NFUN_256__(DelayTime);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

protected function NotifyFinishedGettingUp()
{
	return;
}

function bool IsFlailing()
{
	return __NFUN_130__(m_Pawn.IsAnimationHandleValid(FlailAnimationHandle), __NFUN_129__(m_Pawn.IsAnimationPerTrackEasingOut(FlailAnimationHandle)));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool CanFlail()
{
	return __NFUN_130__(__NFUN_130__(__NFUN_130__(bUsingAIRagdollCollisionListener, __NFUN_179__(Level().TimeSeconds, InitialFlailingTime)), ShockAI().HasFlailingAnimation()), __NFUN_176__(ShockAI().LastRagdollCollisionTime, InitialFlailingTime));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function StartFlail()
{
	local name FlailAnimation;

	FlailAnimation = ShockAI().GetFlailingAnimation();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xBF
	/*@Error*/
	FlailAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, FlailAnimation, Class'Engine.Actor'.8);
	m_Pawn.GetRagdoll().SetRisePoseMatchingEnabled(false);
	m_Pawn.GetRagdoll().SetMotorsEnabled(true);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function StopFlail()
{
	// End:0x43
	if(m_Pawn.IsAnimationHandleValid(FlailAnimationHandle))
	{
		m_Pawn.SmartPerTrackEaseOutAnimation(FlailAnimationHandle);
		m_Pawn.GetRagdoll().SetMotorsEnabled(false);
	}
	m_Pawn.GetRagdoll().SetRisePoseMatchingEnabled(true);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function FallDown()
{
	local Aggressor AggressorAI;

	InitialFlailingTime = __NFUN_174__(Level().TimeSeconds, RandRange(TimeToWaitBeforeFlailingRange.Min, TimeToWaitBeforeFlailingRange.Max));
	m_Pawn.GetRagdoll().SetRisePoseMatchingEnabled(true);
	m_Pawn.GetRagdoll().Fall();
	m_Pawn.TriggerEffectEvent('fell');
	bFellEffectTriggered = true;
	// End:0x14A
	if(__NFUN_177__(HitDamageStimuliSetState.MomentumScale, 0.0000000))
	{
		bUsingAIRagdollCollisionListener = ApplyDeferredMomentum(ShockAI(m_Pawn), HitDamageStimuliSetState, HitImpulseDirection, HitLocation, HitLowBone);
		goto J0x1EB;
		log('Damage', 3, __NFUN_112__(__NFUN_112__(string(Name), " FallDownAction IGNORING deferred damage momentum because HitDamageStimuliSetState.MomentumScale is "), string(HitDamageStimuliSetState.MomentumScale)));
	}
	yield();
	// End:0x2A4
	if(__NFUN_130__(__NFUN_155__(int(m_Pawn.GetRagdoll().GetRagdollState()), int(2)), __NFUN_155__(int(m_Pawn.GetRagdoll().GetRagdollState()), int(0))))
	{
		// End:0x280
		if(IsFlailing())
		{
			// End:0x27D
			if(__NFUN_129__(CanFlail()))
			{
				StopFlail();
				goto J0x297;
				// End:0x297
				if(CanFlail())
				{
					StartFlail();
					yield();
					// [Loop Continue]
					goto J0x1F5;
					StopFlail();
					// End:0x309
					if(__NFUN_155__(int(m_Pawn.GetRagdoll().GetRagdollState()), int(0)))
					{
						DelayOnGround();
						ShockAI().PlaySpeech('GotUp');
					}
				}
				// End:0x407
				if(__NFUN_155__(int(m_Pawn.GetRagdoll().GetRagdollState()), int(0)))
				{
				}
			}
			// End:0x3FA
			if(__NFUN_154__(int(m_Pawn.GetRagdoll().GetRagdollState()), int(2)))
			{
				m_Pawn.UnTriggerEffectEvent('HitByAirBlast');
				m_Pawn.UnTriggerEffectEvent('HitBySpringBoardTrap');
			}
			m_Pawn.UnTriggerEffectEvent('fell');
			bFellEffectTriggered = false;
			m_Pawn.GetRagdoll().Rise();
			yield();
			// [Loop Continue]
			goto J0x309;
			m_Pawn.GetRagdoll().SetRisePoseMatchingEnabled(false);
			m_Pawn.GetAnchor();
			AggressorAI = Aggressor(m_Pawn);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x4A3
			/*@Error*/
			AggressorAI.SetIsMimic(false);
			NotifyFinishedGettingUp();
			return;
		}
		@NULL
		EcologyAI
		EcologyFighterCommanderAction
	}
	@NULL
}

function bool ApplyDeferredMomentum(ShockAI theAI, DamageStimuliSetState HitDamageStimuliSetState, Vector HitImpulseDirection, Vector HitLocation, name HitLowBone)
{
	local int i;
	local bool UsingSpecialMomentumAction;

	log('Damage', 3, __NFUN_112__(__NFUN_112__(string(theAI.Name), " FallDownAction: applying deferred damage momentum; HitDamageStimuliSetState.MomentumScale is "), string(HitDamageStimuliSetState.MomentumScale)));
	log('Damage', 3, __NFUN_112__(string(theAI.Name), " FallDownAction:     applying deferred damage momentum "));
	i = 0;
	// End:0x413
	if(__NFUN_130__(__NFUN_150__(i, HitDamageStimuliSetState.Stimulus.Length), __NFUN_129__(UsingSpecialMomentumAction)))
	{
		switch(HitDamageStimuliSetState.Stimulus[i].Type)
		{
			// End:0x25D
			case 35:
				log('Damage', 3, __NFUN_112__(string(theAI.Name), " FallDownAction:         applying SpringboardTrap damage momentum "));
				UsingSpecialMomentumAction = true;
				theAI.ApplySpringBoardMomentum(HitImpulseDirection, HitDamageStimuliSetState.MomentumScale, HitDamageStimuliSetState.MomentumDuration);
				// End:0x405
				break;
				// End:0x32C
				case 32:
					log('Damage', 3, __NFUN_112__(string(theAI.Name), " FallDownAction:         applying AirBlast damage momentum "));
					UsingSpecialMomentumAction = true;
					theAI.ApplyAirBlastMomentum(HitImpulseDirection, HitDamageStimuliSetState.MomentumScale, HitDamageStimuliSetState.MomentumDuration);
				// End:0x405
				break;
				// End:0x402
				case 21:
					log('Damage', 3, __NFUN_112__(string(theAI.Name), " FallDownAction:         applying ProtectorPushAI damage momentum "));
					UsingSpecialMomentumAction = true;
					theAI.ApplyProtectorPushMomentum(HitImpulseDirection, HitDamageStimuliSetState.MomentumScale, HitDamageStimuliSetState.MomentumDuration);
				// End:0x405
				break;
				// End:0xFFFF
				default:
					__NFUN_163__(i);
					// [Loop Continue]
					goto J0x116;
					/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
						
					*/

					// End:0x609
					/*@Error*/
					/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
						
					*/

					// End:0x59C
					/*@Error*/
					log('Damage', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(theAI.Name), " FallDownAction:         applying momentum scale of "), string(HitDamageStimuliSetState.MomentumScale)), " in Direction "), string(HitImpulseDirection)), "at HitLocation: "), string(HitLocation)), " On LowBone: "), string(HitLowBone)));
					break;/* Tried to find Switch scope, found Case instead */
		}
	}
	theAI.ForcePoseUpdate();
	theAI.ApplyDamageMomentum(HitDamageStimuliSetState.StimuliSetName, HitLocation, HitImpulseDirection);
	goto J0x609;
	log('Damage', 3, __NFUN_112__(string(theAI.Name), " FallDownAction:         IGNORING damage momentum because it is 0"));
	return UsingSpecialMomentumAction;
	return;
	@NULL
	CommanderAction
	Class'ShockAI.CommanderAction'
	@NULL
}

state Running
{Begin:

	// End:0x28
	if(__NFUN_114__(DummyMovementGoal, none))
	{
		useResources(Class'VengeanceShared.AI_Resource'.4);
		// End:0xA4
		if(m_Pawn.IsOnCeiling())
		{
		}
		m_Pawn.ClearLocalGravityDirection();
		ShockAI().AddLocomotionKeyword('Ceiling', Class'ShockAI.ShockAI'.-1);
		ShockAI().NotifyCeilingVisionNoLongerDesired();
		ShockAI().StopAnyWeaponAction();
	}
	FallDown();
	succeed();
	stop;			
	@NULL
	@NULL
	@NULL
	@NULL
}

defaultproperties
{
	TimeToWaitBeforeFlailingRange=(Min=0.1000000,Max=0.2500000)
	satisfiesGoal=Class'ShockAI.ReactToDamageGoal'
	bExclusiveAction=true
}