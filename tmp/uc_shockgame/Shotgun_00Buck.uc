class Shotgun_00Buck extends TraceAmmo
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
	HeatStimulus.Amount = InstigatorPawn.ModifyStat('BuckshotHeatDamageStimulus_Bonus', 0.0000000);
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
	NumTracesToFire=8
	SpreadOfFire=(Pitch=910,Yaw=910,Roll=0)
	DamageStimuliSetName="Buck00StimuliSet"
	ChanceToCrit=0.0000000
	VisualAmmoModel=StaticMesh'ShockGame.WP_Shotgun.shotgun_shell'
	AmmoSpecificDamageAmplificationPercentBonusModGroup="ShotgunDamage_PercentBonus"
	MaximumStackSize=48
	Description="Standard buckshot for the shotgun.\\n\\nThis basic buckshot for the shotgun provides a devastating blast at short range."
	FriendlyName="00 Buck"
	CreditValue=9.0000000
}