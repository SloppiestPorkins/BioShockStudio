class RadialAmmo extends Ammunition implements IProvideRadialDamageData
	config(Weapons);

var config bool bShouldDamageDamager;

function bool ShouldDamageDamager()
{
	return bShouldDamageDamager;
	return;
	@NULL
}

function ModifyDamageStimuli(out DamageStimuliSet DamageStimuli, Actor Instigator, Actor Damagee)
{
	local int i;
	local ShockPawn InstigatorPawn;

	super.ModifyDamageStimuli(DamageStimuli, Instigator, Damagee);
	InstigatorPawn = ShockPawn(Instigator);
	// End:0x52
	if(__NFUN_114__(InstigatorPawn, none))
	{
		return;
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x113
		/*@Error*/
	}
	DamageStimuli.Stimulus[i].Amount = InstigatorPawn.ModifyStat('RadialDamage_Bonus', DamageStimuli.Stimulus[i].Amount);
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x5D;
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	DamageModel=Class'ShockGame.RadialDamageFactory'
	AttackRange=200.0000000
}