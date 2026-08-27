class WrenchAmmo extends TraceAmmo
	config(Weapons);

var private config float ShockedDamage_PercentBonus;

function ModifyDamageStimuli(out DamageStimuliSet DamageStimuli, Actor Instigator, Actor Damagee)
{
	local int i;
	local ShockPawn InstigatorPawn;
	local BaseShockAI DamageeAI;
	local DamageStimulus FrozenStimulus;
	local float DefenselessDamageMultiplier;

	super(Ammunition).ModifyDamageStimuli(DamageStimuli, Instigator, Damagee);
	InstigatorPawn = ShockPawn(Instigator);
	// End:0x52
	if(__NFUN_114__(InstigatorPawn, none))
	{
		return;
		DamageeAI = BaseShockAI(Damagee);
		log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__("Damagee = ", string(Damagee)), ", DamageeAI = "), string(DamageeAI)));
	}
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x320
	/*@Error*/
	__NFUN_182__(DamageStimuli.Stimulus[i].Amount, InstigatorPawn.ModifyStat('MeleeDamage_PercentBonus', 1.0000000));
	// End:0x1F4
	if(__NFUN_154__(int(DamageStimuli.Stimulus[i].Type), int(23)))
	{
		DamageStimuli.Stimulus[i].Amount = InstigatorPawn.ModifyStat('FreezingNimbusMeleeDamage_Bonus', DamageStimuli.Stimulus[i].Amount);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x312
		/*@Error*/
		DefenselessDamageMultiplier = InstigatorPawn.ModifyStat('SneakAttackDamage_PercentBonus', 1.0000000);
		// End:0x2A8
		if(__NFUN_177__(DefenselessDamageMultiplier, 1.0000000))
		{
			InstigatorPawn.TriggerEffectEvent('SneakAttackSuccessful');
			// End:0x2D6
			if(DamageeAI.IsShocked())
			{
			}
			__NFUN_184__(DefenselessDamageMultiplier, ShockedDamage_PercentBonus);
			__NFUN_182__(DamageStimuli.Stimulus[i].Amount, DefenselessDamageMultiplier);
			__NFUN_165__(i);
			// [Loop Continue]
			goto J0xB8;
			FrozenStimulus.Type = 2;
			FrozenStimulus.Amount = 1.0000000;
			FrozenStimulus.Chance = InstigatorPawn.ModifyStat('FreezingNimbusFreezingChance_Bonus', 0.0000000);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x3F9
			/*@Error*/
		}
		DamageStimuli.Stimulus[DamageStimuli.Stimulus.Length] = FrozenStimulus;
		return;
		@NULL
		Item
	}
	Item
	@NULL
}

defaultproperties
{
	ShockedDamage_PercentBonus=4.0000000
	TraceDistance=220.0000000
	DamageStimuliSetName="WrenchAmmoStimuliSet"
	ChanceToCrit=0.0000000
	FriendlyName=" "
}