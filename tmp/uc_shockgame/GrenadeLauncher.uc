class GrenadeLauncher extends PlayerWeapon
	native
	config(Weapons)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

function bool ShouldShowAmmoModel()
{
	return __NFUN_132__(__NFUN_151__(RoundsRemaining, 1), __NFUN_119__(PendingAmmoSelection, CurrentAmmoSelection));
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	AltFireModAttachmentClass=Class'ShockGame.WeaponUpgradeClasses.GL_UpgradeA'
	StrictlySuperiorModAttachmentClass=Class'ShockGame.WeaponUpgradeClasses.GL_UpgradeB'
	AltFireModAttachmentSocket="upgradeA"
	StrictlySuperiorModAttachmentSocket="upgradeB"
	EmptyIdlingHandsAnim="EmptyFidgetLauncher"
	ReloadingEmptyWeaponHandsAnim[0]=(AnimationName="ReloadLauncher",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	ReloadingNotEmptyWeaponHandsAnim[0]=(AnimationName="ReloadLauncher",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	FiringHandsAnim[0]=(AnimationName="FireLauncher",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	FiringFinalShotHandsAnim[0]=(AnimationName="FireLastLauncher",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	ZoomedFiringFinalShotHandsAnim[0]=(AnimationName="FireLastLauncher",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	ZoomedFiringFinalShotAnim[0]=(AnimationName="FireLast",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	FriendlyName="Grenade Launcher"
	AvailableAmmoTypes[0]=Class'ShockGame.GrenadeLauncher_FragGrenade'
	AvailableAmmoTypes[1]=Class'ShockGame.GrenadeLauncher_StickyGrenade'
	AvailableAmmoTypes[2]=Class'ShockGame.GrenadeLauncher_RPG'
	DefaultAmmoSelection=Class'ShockGame.GrenadeLauncher_FragGrenade'
	WeaponModel=SkeletalMesh'ShockGame.WP_GrenadeLauncher.WP_GrenadeLauncherMesh'
	AmmunitionModelSocket="AmmoDummySocket"
	ReloadingEmptyWeaponAnim[0]=(AnimationName="Reload",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	ReloadingNotEmptyWeaponAnim[0]=(AnimationName="Reload",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	FiringAnim[0]=(AnimationName="Fire",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	FiringFinalShotAnim[0]=(AnimationName="FireLast",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	BaseMagazineSize=6
	BaseAccuracy=0.0000000
	UpgradeStatName[0]="GrenadeLauncherUpgrade_Damage"
	UpgradeStatName[1]="GrenadeLauncherUpgrade_Immunity"
	AltFireModStatName="Immunity"
	IdlingHandsAnim[0]="FidgetLauncher"
	IdlingHandsAnim[1]="FidgetLauncher_Accent_A"
	IdlingHandsAnim[2]="FidgetLauncher_Accent_C"
	IdlingHandsAnim[3]="FidgetLauncher_Accent_D"
	IdlingHandsAnimWeight[0]=100.0000000
	IdlingHandsAnimWeight[1]=100.0000000
	IdlingHandsAnimWeight[2]=100.0000000
	IdlingHandsAnimWeight[3]=20.0000000
	EquippingHandsAnim="EquipLauncher"
	AttachBone="Launcher"
}