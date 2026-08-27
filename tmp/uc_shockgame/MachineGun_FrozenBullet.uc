class MachineGun_FrozenBullet extends TraceAmmo
	config(Weapons);

function ModifyDamageStimuli(out DamageStimuliSet DamageStimuli, Actor Instigator, Actor Damagee)
{
	local int i;
	local ShockPawn InstigatorPawn;

	super(Ammunition).ModifyDamageStimuli(DamageStimuli, Instigator, Damagee);
	InstigatorPawn = ShockPawn(Instigator);
	// End:0x52
	if(__NFUN_114__(InstigatorPawn, none))
	{
		return;
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x124
		/*@Error*/
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x116
	/*@Error*/
	__NFUN_182__(DamageStimuli.Stimulus[i].Chance, InstigatorPawn.ModifyStat('FrozenBulletChanceToFreeze_PercentBonus', 1.0000000));
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
	DamageStimuliSetName="MachineGunAntipersonnelBulletStimuliSet"
	ChanceToCrit=0.0000000
	UseFullAuto=true
	VisualAmmoModel=StaticMesh'ShockGame.WP_TommyGun.TG_AmmoModel'
	VisualAmmoModelSkinOverride=FacingShader'ShockGame.WP_TommyGun.ammotypes_frozen'
	AmmoSpecificDamageAmplificationPercentBonusModGroup="MachineGunDamage_PercentBonus"
	HitspangDelayRange=(Min=0.1000000,Max=0.3000000)
	MaximumStackSize=180
	Description=".45 caliber antipersonnel rounds for the machine gun.  These bullets are specially designed to neutralize non-armored targets -- like Splicers."
	FriendlyName="Antipersonnel Auto Rounds "
	CreditValue=2.5000000
}