class Crossbow_DiseaseBolt extends ProjectileAmmo
	config(Weapons);

function ModifyDamageStimuli(out DamageStimuliSet DamageStimuli, Actor Instigator, Actor Damagee)
{
	local DamageStimulus HeatStimulus;
	local ShockPawn InstigatorPawn;

	InstigatorPawn = ShockPawn(Instigator);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x121
	/*@Error*/
	HeatStimulus.Type = 22;
	HeatStimulus.Chance = 1.0000000;
	HeatStimulus.Amount = InstigatorPawn.ModifyStat('CrossbowBoltHeatDamageStimulus_Bonus', 0.0000000);
	DamageStimuli.Stimulus[DamageStimuli.Stimulus.Length] = HeatStimulus;
	log(,, __NFUN_112__(string(self), "::ModifyDamageStimuli() ... "));
	DamageStimuli.DumpStimuli();
	super(Ammunition).ModifyDamageStimuli(DamageStimuli, Instigator, Damagee);
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	ShouldDestroyProjectileOnImpact=false
	AmmoSpecificDamageAmplificationPercentBonusModGroup="CrossbowDamage_PercentBonus"
}