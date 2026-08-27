class ChemicalThrower extends PlayerWeapon
	config(Weapons)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

function UnHideHoldable()
{
	super(Holdable).UnHideHoldable();
	TriggerEffectEvent('EquipAmmo',,,,,,,, CurrentAmmoSelection.Name);
	return;
	@NULL
	Item
	Item
}

function HideHoldable()
{
	super(Holdable).HideHoldable();
	UnTriggerEffectEvent('EquipAmmo', CurrentAmmoSelection.Name);
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	AltFireModAttachmentClass=Class'ShockGame.WeaponUpgradeClasses.CT_UpgradeA'
	StrictlySuperiorModAttachmentClass=Class'ShockGame.WeaponUpgradeClasses.CT_UpgradeB'
	AltFireModAttachmentSocket="upgradeA"
	StrictlySuperiorModAttachmentSocket="upgradeB"
	EmptyIdlingHandsAnim="EmptyFidgetChem"
	WaitForFireReleaseTrigger=true
	LoopFiringHandsAnim[0]=(AnimationName="FireLoopChem",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	LoopFiringAnim[0]=(AnimationName="FireLoop",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	FinishFiringHandsAnim[0]=(AnimationName="FireEndChem",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	FinishFiringAnim[0]=(AnimationName="FireEnd",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	ReloadingEmptyWeaponHandsAnim[0]=(AnimationName="ReloadChem",minAnimRate=0.0000000,maxAnimRate=1.8900000)
	ReloadingEmptyWeaponHandsAnim[1]=(AnimationName="ReloadChem",minAnimRate=1.9000000,maxAnimRate=3.0000000)
	ReloadingNotEmptyWeaponHandsAnim[0]=(AnimationName="ReloadChem",minAnimRate=0.0000000,maxAnimRate=1.8900000)
	ReloadingNotEmptyWeaponHandsAnim[1]=(AnimationName="ReloadChem",minAnimRate=1.9000000,maxAnimRate=3.0000000)
	FiringHandsAnim[0]=(AnimationName="FireStartChem",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	FiringFinalShotHandsAnim[0]=(AnimationName="FireChem",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	FiringFinalShotHandsAnim[1]=(AnimationName="FireStartChem",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	ZoomedFiringFinalShotHandsAnim[0]=(AnimationName="FireChem",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	ZoomedFiringFinalShotAnim[0]=(AnimationName="Fire",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	FriendlyName="Chemical Thrower"
	AvailableAmmoTypes[0]=Class'ShockGame.ChemicalThrower_Kerosene'
	AvailableAmmoTypes[1]=Class'ShockGame.ChemicalThrower_LiquidNitrogen'
	AvailableAmmoTypes[2]=Class'ShockGame.ChemicalThrower_IonicGel'
	DefaultAmmoSelection=Class'ShockGame.ChemicalThrower_Kerosene'
	WeaponModel=SkeletalMesh'ShockGame.WP_ChemicalThrower.WP_ChemicalThrowerMesh'
	DamageEmitterSocket="muzzle"
	ReloadingEmptyWeaponAnim[0]=(AnimationName="Reload",minAnimRate=0.0000000,maxAnimRate=1.8900000)
	ReloadingEmptyWeaponAnim[1]=(AnimationName="Reload",minAnimRate=1.8900000,maxAnimRate=3.0000000)
	ReloadingNotEmptyWeaponAnim[0]=(AnimationName="Reload",minAnimRate=0.0000000,maxAnimRate=1.8900000)
	ReloadingNotEmptyWeaponAnim[1]=(AnimationName="Reload",minAnimRate=1.8900000,maxAnimRate=3.0000000)
	FiringAnim[0]=(AnimationName="FireStart",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	FiringFinalShotAnim[0]=(AnimationName="Fire",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	FiringFinalShotAnim[1]=(AnimationName="FireStart",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	BaseMagazineSize=100
	BaseAccuracy=0.0000000
	BaseAmmoConsumptionRate=0.0500000
	UpgradeStatName[0]="ChemicalThrowerUpgrade_ConsumptionRate"
	UpgradeStatName[1]="ChemicalThrowerUpgrade_Range"
	AltFireModStatName="Range"
	IdlingHandsAnim[0]="FidgetChem"
	IdlingHandsAnim[1]="FidgetChem_Accent_A"
	IdlingHandsAnim[2]="FidgetChem_Accent_B"
	IdlingHandsAnim[3]="FidgetChem_Accent_C"
	IdlingHandsAnimWeight[0]=100.0000000
	IdlingHandsAnimWeight[1]=50.0000000
	IdlingHandsAnimWeight[2]=50.0000000
	IdlingHandsAnimWeight[3]=50.0000000
	IdlingAnim="Fidget"
	EquippingHandsAnim="EquipChem"
	AttachBone="Chem"
}