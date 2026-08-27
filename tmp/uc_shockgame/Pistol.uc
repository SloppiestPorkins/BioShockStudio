class Pistol extends PlayerWeapon
	config(Weapons)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

var private config Class<WeaponModAttachment> StrictlySuperiorModAttachmentTwoClass;
var private config name StrictlySuperiorModAttachmentTwoSocket;
var private travel WeaponModAttachment StrictlySuperiorModAttachmentTwo;

function PostBeginPlay()
{
	// End:0x4D
	if(__NFUN_130__(__NFUN_255__(StrictlySuperiorModAttachmentTwoSocket, 'None'), __NFUN_119__(StrictlySuperiorModAttachmentTwoClass, none)))
	{
		StrictlySuperiorModAttachmentTwo = __NFUN_278__(StrictlySuperiorModAttachmentTwoClass);
		assert(__NFUN_119__(StrictlySuperiorModAttachmentTwo, none));
		super.PostBeginPlay();
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xD9
		/*@Error*/
		AttachToBone(StrictlySuperiorModAttachmentTwo, StrictlySuperiorModAttachmentTwoSocket);
	}
	StrictlySuperiorModAttachmentTwo.DrawPriority = 1;
	StrictlySuperiorModAttachmentTwo.UpdateRenderRevision();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xD9
	/*@Error*/
	StrictlySuperiorModAttachmentTwo.SetHidden(true);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function ResetBurstShotsRemaining()
{
	// End:0x46
	if(Holder.HasMod('TwoRoundBurst_Exists'))
	{
		BurstShotsRemaining = Class'ShockGame.TwoRoundBurst'.default.NumberOfBurstShots;
		goto J0x50;
		super(Weapon).ResetBurstShotsRemaining();
		return;
		@NULL
		Item
	}
	DifficultyAdjustment
	@NULL
}

function float GetFireRate()
{
	return Holder.ModifyStat(string("TwoRoundBurstFireRate_Bonus"), super(Weapon).GetFireRate());
	return;
	@NULL
	Item
}

function GiveStrictlySuperiorMod()
{
	super.GiveStrictlySuperiorMod();
	AssertWithDescription(__NFUN_119__(StrictlySuperiorModAttachmentTwo, none), __NFUN_112__(__NFUN_112__("Attempted to apply the Strictly Superior weapon mod for weapon ", string(self)), ", but there is no corresponding attachment."));
	StrictlySuperiorModAttachmentTwo.SetHidden(false);
	StrictlySuperiorModAttachmentTwo.bGiven = true;
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	StrictlySuperiorModAttachmentTwoClass=Class'ShockGame.WeaponUpgradeClasses.PI_UpgradeBalt'
	StrictlySuperiorModAttachmentTwoSocket="upgradeBalt"
	AltFireModAttachmentClass=Class'ShockGame.WeaponUpgradeClasses.PI_UpgradeA'
	StrictlySuperiorModAttachmentClass=Class'ShockGame.WeaponUpgradeClasses.PI_UpgradeB'
	AltFireModAttachmentSocket="upgradeA"
	StrictlySuperiorModAttachmentSocket="upgradeB"
	EmptyIdlingHandsAnim="EmptyFidgetPistol"
	CanBeZoomed=true
	ZoomedFOVAngle=55.0000000
	ZoomedForegroundFOVAngle=55.0000000
	ZoomingInHandsAnim="ZoomingInPistol"
	ZoomingOutHandsAnim="ZoomingOutPistol"
	ZoomedIdlingHandsAnim="ZoomedInFidgetPistol"
	ZoomedFiringHandsAnim[0]=(AnimationName="ZoomedInFireSinglePistol",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	ZoomedFiringAnim[0]=(AnimationName="FireSingle",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	ReloadingEmptyWeaponHandsAnim[0]=(AnimationName="FastReloadPistol",minAnimRate=0.0000000,maxAnimRate=1.8900000)
	ReloadingEmptyWeaponHandsAnim[1]=(AnimationName="FastReloadPistol",minAnimRate=1.9000000,maxAnimRate=3.0000000)
	ReloadingNotEmptyWeaponHandsAnim[0]=(AnimationName="FastReloadPistol",minAnimRate=0.0000000,maxAnimRate=1.8900000)
	ReloadingNotEmptyWeaponHandsAnim[1]=(AnimationName="FastReloadPistol",minAnimRate=1.9000000,maxAnimRate=3.0000000)
	FiringHandsAnim[0]=(AnimationName="FireSinglePistol",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	FiringFinalShotHandsAnim[0]=(AnimationName="FireSinglePistol",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	ZoomedFiringFinalShotHandsAnim[0]=(AnimationName="ZoomedInFireSinglePistol",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	ZoomedFiringFinalShotAnim[0]=(AnimationName="FireSingle",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	FriendlyName="Pistol"
	AvailableAmmoTypes[0]=Class'ShockGame.Pistol_Bullet'
	AvailableAmmoTypes[1]=Class'ShockGame.Pistol_ArmorPiercing'
	AvailableAmmoTypes[2]=Class'ShockGame.Pistol_AntiPersonnel'
	DefaultAmmoSelection=Class'ShockGame.Pistol_Bullet'
	WeaponModel=SkeletalMesh'ShockGame.WP_Pistol.WP_PistolMesh'
	AmmunitionModelSocket="AmmoDummySocket"
	MagicBulletRadius=0.0650000
	MouseMagicBulletRadius=0.0650000
	MagicBulletChance=1.0000000
	EffectiveMagicBulletDistance=1200.0000000
	ReloadingEmptyWeaponAnim[0]=(AnimationName="FastReload",minAnimRate=0.0000000,maxAnimRate=1.8900000)
	ReloadingEmptyWeaponAnim[1]=(AnimationName="FastReload",minAnimRate=1.8900000,maxAnimRate=3.0000000)
	ReloadingNotEmptyWeaponAnim[0]=(AnimationName="FastReload",minAnimRate=0.0000000,maxAnimRate=1.8900000)
	ReloadingNotEmptyWeaponAnim[1]=(AnimationName="FastReload",minAnimRate=1.8900000,maxAnimRate=3.0000000)
	FiringAnim[0]=(AnimationName="FireSingle",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	FiringFinalShotAnim[0]=(AnimationName="FireSingle",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	BaseMagazineSize=6
	BaseAccuracy=0.5000000
	UpgradeStatName[0]="PistolUpgrade_MagazineSize"
	UpgradeStatName[1]="PistolUpgrade_Damage"
	AltFireModStatName="MagazineSize"
	OnFiredEffects[0]=(EmitterClass=Class'ShockGame.FXClass.Pistol_MuzzleFX',LightClass=Class'ShockGame.FXClass.DynamicLightMuzzleFlash',AttachmentBone="muzzle",LocationOffset=(X=0.0000000,Y=0.0000000,Z=0.0000000),RotationOffset=(Pitch=0,Yaw=0,Roll=0),AmmoType="None",UpgradeType=0,EmitterAction=0)
	IdlingHandsAnim[0]="FidgetPistol"
	IdlingHandsAnimWeight[0]=100.0000000
	EquippingHandsAnim="EquipPistol"
	AttachBone="Pistol"
}