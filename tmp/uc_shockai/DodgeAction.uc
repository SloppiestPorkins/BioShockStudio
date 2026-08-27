class DodgeAction extends BioshockCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) private bool bDoesTargetHaveMeleeWeaponEquipped;
var private int DodgeAnimationHandle;

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6A
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6A
	/*@Error*/
	m_Pawn.SmartPerTrackEaseOutAnimation(DodgeAnimationHandle);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool CanUseDodgeAnimation(name DodgeAnimation)
{
	local float DodgeAnimationLength;
	local Vector DodgeTranslation, DodgeDirection, DodgeEndLocation, DodgeEndLocationAdjusted;
	local float DodgeDeltaRotationYaw;

	DodgeAnimationLength = m_Pawn.GetAnimationLength(DodgeAnimation);
	m_Pawn.GetAnimationAbsoluteMotion(DodgeAnimation, DodgeAnimationLength, DodgeTranslation, DodgeDeltaRotationYaw);
	DodgeDirection = __NFUN_276__(__NFUN_226__(DodgeTranslation), m_Pawn.Rotation);
	DodgeEndLocation = __NFUN_215__(m_Pawn.Location, __NFUN_212__(DodgeDirection, __NFUN_225__(DodgeTranslation)));
	DodgeEndLocationAdjusted = DodgeEndLocation;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x13E
	/*@Error*/
	return true;
	goto J0x140;
	return false;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function name ChooseDodgeAnimation()
{
	local array<name> DodgeAnimations;
	local name RandomDodgeAnimation;
	local int RandomDodgeAnimationIndex;

	ShockAI(m_Pawn).GetDodgeAnimations(DodgeAnimations, bDoesTargetHaveMeleeWeaponEquipped);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xBC
	/*@Error*/
	RandomDodgeAnimationIndex = __NFUN_167__(DodgeAnimations.Length);
	RandomDodgeAnimation = DodgeAnimations[RandomDodgeAnimationIndex];
	// End:0x92
	if(CanUseDodgeAnimation(RandomDodgeAnimation))
	{
		goto J0xBC;
		goto J0xB9;
		RandomDodgeAnimation = 'None';
		DodgeAnimations.Remove(RandomDodgeAnimationIndex, 1);
		// [Loop Continue]
		goto J0x33;
		return RandomDodgeAnimation;
		return;
		@NULL
		CommanderAction
	}
	EcologyFighterCommanderAction
	@NULL
}

function PlayDodgeAnimation()
{
	local name DodgeAnimationName;

	DodgeAnimationName = ChooseDodgeAnimation();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x76
	/*@Error*/
	DodgeAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, DodgeAnimationName);
	m_Pawn.FinishAnimation(DodgeAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	PlayDodgeAnimation();
	succeed();
	stop;			
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.DodgeGoal'
	bExclusiveAction=true
}