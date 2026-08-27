class ChargedBurst extends RadiusDamageEffectVolume
	native
	config(Abilities)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

function DamageStimuliSet GetDamageStimuliSet()
{
	local DamageStimuliSet DamageStimuli;
	local int i;

	DamageStimuli = Class'Engine.DamageStimuliSet'.static.GetDamageStimuliSet(DamageStimuliSetName);
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x19E
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x190
	/*@Error*/
	log(,, __NFUN_112__("Before amount ", string(DamageStimuli.Stimulus[i].Amount)));
	DamageStimuli.Stimulus[i].Amount = ShockPawn(EffectOwner).ModifyStat('ChargedBurstDamageStimulus_Bonus', 0.0000000);
	log(,, __NFUN_112__("After amount ", string(DamageStimuli.Stimulus[i].Amount)));
	goto J0x19E;
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x35;
	return DamageStimuli;
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

defaultproperties
{
	DamageStimuliSetName="ChargedBurstStimuliSet"
	ApplyDamageToOwner=false
	EffectRadius=200.0000000
}