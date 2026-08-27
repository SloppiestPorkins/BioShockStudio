class EcologyAI extends ShockAI
	abstract
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

var config array<name> RangedFrontAttackReactionAnimations;
var config array<name> RangedLeftAttackReactionAnimations;
var config array<name> RangedRightAttackReactionAnimations;
var config array<name> RangedBackAttackReactionAnimations;
var config array<name> ExplosiveFrontAttackReactionAnimations;
var config array<name> ExplosiveLeftAttackReactionAnimations;
var config array<name> ExplosiveRightAttackReactionAnimations;
var config array<name> ExplosiveBackAttackReactionAnimations;
var config array<name> MeleeFrontAttackReactionAnimations;
var config array<name> MeleeLeftAttackReactionAnimations;
var config array<name> MeleeRightAttackReactionAnimations;
var config array<name> MeleeBackAttackReactionAnimations;
var private config float ChanceToDouseNormal;
var private config float ChanceToDouseAttacking;
var private config float MinTimeBetweenDouses;
var private config float MaxDistanceToMoveToWater;
var private bool bCanDouse;
var private float LastTimeDoused;
var array<Object> DouseReactionPreventionRequesters;

function PostLoadGame()
{
	super.PostLoadGame();
	RegisterRotationListener();
	return;
	@NULL
}

// Export UEcologyAI::execRegisterRotationListener(FFrame&, void* const)
native function RegisterRotationListener();

function CharacterAICreated()
{
	super.CharacterAICreated();
	CharacterAI.addAbility_Class(Class'ShockAI.EventReactionAction');
	CharacterAI.addAbility_Class(Class'ShockAI.AttackReactionAction');
	CharacterAI.addAbility_Class(Class'ShockAI.DouseAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function bool CanDouse()
{
	return __NFUN_130__(bCanDouse, __NFUN_154__(DouseReactionPreventionRequesters.Length, 0));
	return;
	@NULL
	CommanderAction
}

function bool ShouldDouse()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x68
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x68
	/*@Error*/
	// End:0x5A
	if(IsAttacking())
	{
		return __NFUN_178__(__NFUN_195__(), ChanceToDouseAttacking);
		goto J0x68;
		return __NFUN_178__(__NFUN_195__(), ChanceToDouseNormal);
		return false;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
	@NULL
}

function SetLastTimeDoused()
{
	LastTimeDoused = Level.TimeSeconds;
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function float GetMaxDistanceToMoveToWater()
{
	return MaxDistanceToMoveToWater;
	return;
	@NULL
}

function SetCanDouse(bool inCanDouse)
{
	bCanDouse = inCanDouse;
	return;
	@NULL
	CommanderAction
}

function bool IsDouseReactionRequester(Object Requester)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x54
	/*@Error*/
	// End:0x46
	if(__NFUN_114__(DouseReactionPreventionRequesters[i], Requester))
	{
		return true;
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x0B;
		return false;
		return;
		@NULL
		CommanderAction
	}
	EcologyFighterCommanderAction
	@NULL
}

function NotifyDouseReactionPreventionDesired(Object Requester)
{
	// End:0x36
	if(__NFUN_129__(IsDouseReactionRequester(Requester)))
	{
		DouseReactionPreventionRequesters[DouseReactionPreventionRequesters.Length] = Requester;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function NotifyDouseReactionPreventionNoLongerDesired(Object Requester)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x69
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5B
	/*@Error*/
	DouseReactionPreventionRequesters.Remove(i, 1);
	goto J0x69;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function name GetRandomAnimation(array<name> AnimationSet)
{
	// End:0x27
	if(__NFUN_151__(AnimationSet.Length, 0))
	{
		return AnimationSet[__NFUN_167__(AnimationSet.Length)];
		return 'None';
		return;
	}
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
}

function name GetAttackReactionAnimation(Actor Attacker, DamageStimuliSet.EDamageType DamageType)
{
	local ShockAI.EDirection HitDirection;

	HitDirection = GetDirectionForPoint(Rotation, __NFUN_226__(__NFUN_216__(Attacker.Location, Location)), 90.0000000);
	switch(DamageType)
	{
		// End:0xCA
		case 0:
			switch(HitDirection)
			{
				// End:0x79
				case 0:
					return GetRandomAnimation(RangedFrontAttackReactionAnimations);
					// End:0x92
					case 2:
						return GetRandomAnimation(RangedLeftAttackReactionAnimations);
						// End:0xAB
						case 3:
							return GetRandomAnimation(RangedRightAttackReactionAnimations);
						// End:0xC4
						case 1:
							return GetRandomAnimation(RangedBackAttackReactionAnimations);
						// End:0xFFFF
						default:
							// End:0x1C1
							break;
							break;
					}/* !MISMATCHING REMOVE, tried Switch got Type:Case Position:0x059! */
					// End:0x144
					case 1:
						switch(HitDirection)
						{
							// End:0xF3
							case 0:
							return GetRandomAnimation(ExplosiveFrontAttackReactionAnimations);
							// End:0x10C
							case 2:
							return GetRandomAnimation(ExplosiveLeftAttackReactionAnimations);/* !MISMATCHING REMOVE, tried Case got Type:Switch Position:0x0A3! */
						// End:0x125
						case 3:
							return GetRandomAnimation(ExplosiveRightAttackReactionAnimations);
							// End:0x13E
							case 1:
								return GetRandomAnimation(ExplosiveBackAttackReactionAnimations);
							// End:0xFFFF
							default:
								// End:0x1C1
								break;
								break;
						}/* !MISMATCHING REMOVE, tried Switch got Type:Case Position:0x0D4! */
						// End:0x1BE
						case 2:
							switch(HitDirection)
							{/* !MISMATCHING REMOVE, tried Case got Type:Switch Position:0x109! */
							// End:0x16D
							case 0:
								return GetRandomAnimation(MeleeFrontAttackReactionAnimations);
							// End:0x186
							case 2:
								return GetRandomAnimation(MeleeLeftAttackReactionAnimations);
								// End:0x19F
								case 3:
								return GetRandomAnimation(MeleeRightAttackReactionAnimations);
							// End:0x1B8
							case 1:
								return GetRandomAnimation(MeleeBackAttackReactionAnimations);
								// End:0xFFFF
								default:
									// End:0x1C1
									break;
									break;
							}/* !MISMATCHING REMOVE, tried Switch got Type:Case Position:0x14F! */
							// End:0xFFFF
							default:
								break;/* Tried to find Switch scope, found Case instead */
						return 'None';
						return;
						@NULL
						CommanderAction
						CommanderAction
					@NULL/* !MISMATCHING REMOVE, tried Case got Type:Switch Position:0x03D! */
}

defaultproperties
{
	ChanceToDouseNormal=1.0000000
	ChanceToDouseAttacking=1.0000000
	MinTimeBetweenDouses=10.0000000
	MaxDistanceToMoveToWater=3000.0000000
	bCanDouse=true
}