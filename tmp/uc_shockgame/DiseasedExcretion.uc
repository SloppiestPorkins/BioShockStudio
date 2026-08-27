class DiseasedExcretion extends RadiusDamageEffectVolume
	config(Abilities)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

function bool IsValidTarget(Actor Target)
{
	return __NFUN_130__(__NFUN_130__(__NFUN_130__(super.IsValidTarget(Target), Target.__NFUN_303__('ShockPawn')), ShockPawn(Target).IsAlive()), ShockPawn(Target).CanBeAttacked());
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

function DamageStimuliSet GetDamageStimuliSet()
{
	local DamageStimuliSet StimuliSet;
	local int i;

	StimuliSet = super.GetDamageStimuliSet();
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xEE
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xE0
	/*@Error*/
	StimuliSet.Stimulus[i].Chance = ShockPawn(EffectOwner).ModifyStat('DiseasedExcretionChance_Bonus', 0.0000000);
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x1F;
	return StimuliSet;
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

defaultproperties
{
	DamageStimuliSetName="DiseasedExcretionStimuliSet"
	ApplyDamageToOwner=false
	EffectRadius=100.0000000
	ApplyEffectInterval=1.0000000
}