class ExitVentAction extends BioshockCharacterAction
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private int ExitFromVentAnimationHandle;
var config array<name> ExitFromVentWithBouncerAnimations;
var config array<name> ExitFromVentWithRosieAnimations;
var config array<name> ExitFromVentWithSPFAnimations;
var config array<name> ExitFromVentWithPlayerAnimations;

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	ShockAI().bDoNotTakeAnyDamage = false;
	m_Pawn.UnTriggerEffectEvent('BecameImmuneToFrozenState');
	ShockAI().NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
	ShockAI().NotifyFallDownHitReactionPreventionNoLongerDesired(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function name GetExitFromVentAnimationName()
{
	local Protector ProtectorEscort;
	local name ExitFromVentAnimationName;

	ProtectorEscort = Gatherer(m_Pawn).GetProtectorEscort();
	// End:0x5C
	if(__NFUN_114__(ProtectorEscort, none))
	{
		ExitFromVentAnimationName = ExitFromVentWithPlayerAnimations[__NFUN_167__(ExitFromVentWithPlayerAnimations.Length)];
		goto J0x116;
		// End:0x9B
		if(ProtectorEscort.__NFUN_303__('Rosie'))
		{
			ExitFromVentAnimationName = ExitFromVentWithRosieAnimations[__NFUN_167__(ExitFromVentWithRosieAnimations.Length)];
		}
		goto J0x116;
		// End:0xDA
		if(ProtectorEscort.__NFUN_303__('Bouncer'))
		{
			ExitFromVentAnimationName = ExitFromVentWithBouncerAnimations[__NFUN_167__(ExitFromVentWithBouncerAnimations.Length)];
		}
		goto J0x116;
		assert(ProtectorEscort.__NFUN_303__('SPF'));
		ExitFromVentAnimationName = ExitFromVentWithSPFAnimations[__NFUN_167__(ExitFromVentWithSPFAnimations.Length)];
		return ExitFromVentAnimationName;
		return;
		@NULL
		CommanderAction
	}
	EcologyFighterCommanderAction
	@NULL
}

function PlayExitFromVentAnimation()
{
	local name ExitFromVentAnimationName;

	Gatherer(m_Pawn).NotifyProtectorEscortStartingExitAnimation();
	ExitFromVentAnimationName = GetExitFromVentAnimationName();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA3
	/*@Error*/
	ExitFromVentAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, ExitFromVentAnimationName);
	__NFUN_256__(__NFUN_175__(m_Pawn.GetAnimationLengthScaled(ExitFromVentAnimationHandle), 0.2500000));
	goto J0xAD;
	yield();
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	ShockAI().bDoNotTakeAnyDamage = true;
	m_Pawn.TriggerEffectEvent('BecameImmuneToFrozenState');
	ShockAI().NotifyFullBodyHitReactionPreventionDesired(self);
	ShockAI().NotifyFallDownHitReactionPreventionDesired(self);
	useResources(__NFUN_158__(Class'VengeanceShared.AI_Resource'.2, Class'VengeanceShared.AI_Resource'.4));
	PlayExitFromVentAnimation();
	Gatherer(m_Pawn).BecomePhysical();
	ShockAI().dispatchMessage(Class'ShockAI.MessageGathererExitedVent'.static.Allocate(self)., construct_Gatherer(Gatherer(m_Pawn)));
	succeed();
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
	ExitFromVentWithBouncerAnimations[0]="GA_ExitVentProtectorBouncer"
	ExitFromVentWithRosieAnimations[0]="GA_ExitVentProtectorRosie"
	ExitFromVentWithSPFAnimations[0]="GA_ExitVentProtectorSPF"
	ExitFromVentWithPlayerAnimations[0]="GA_ExitVentAlone"
	satisfiesGoal=Class'ShockAI.ExitVentGoal'
	bExclusiveAction=true
}