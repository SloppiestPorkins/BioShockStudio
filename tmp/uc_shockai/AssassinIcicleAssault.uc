class AssassinIcicleAssault extends AssassinRangedWeapon
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

defaultproperties
{
	AccuracyRangeVsPlayer=(Min=0.7500000,Max=3.0000000)
	AccuracyChangeTimeRangeVsPlayer=(Min=7.0000000,Max=12.0000000)
	AccuracyRangeVsAI=(Min=0.5000000,Max=0.5000000)
	BaseMaxTimeBetweenUsage=0.8000000
	AvailableAmmoTypes=/* Array type was not detected. */
	DefaultAmmoSelection=Class'ShockAI.AssassinIcicleAssaultAmmo'
}