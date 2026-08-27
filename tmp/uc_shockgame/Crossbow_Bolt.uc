class Crossbow_Bolt extends ProjectileAmmo
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
	InitialVelocity=6000.0000000
	ProjectileClass=Class'ShockGame.ShockDesignerClasses.CrossbowBoltProjectile'
	ShouldDestroyProjectileOnImpact=false
	VisibilityDelay=0.0500000
	DamageStimuliSetName="BoltStimuliSet"
	ChanceToCrit=0.0000000
	AttackRange=2000.0000000
	VisualAmmoModel=StaticMesh'ShockGame.WP_Crossbow.arrow_antipersonell'
	VisualAmmoModelSkinOverride=Shader'ShockGame.WP_Crossbow.ammo_pickup_antipersonell_diffuse_shader'
	AmmoSpecificDamageAmplificationPercentBonusModGroup="CrossbowDamage_PercentBonus"
	MaximumStackSize=48
	Description="Steel-Tip Bolts for the crossbow.\\n\\nThese bolts fly true even at long ranges."
	FriendlyName="Steel-Tip Bolt"
	CreditValue=5.0000000
}