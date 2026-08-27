class ResearchCamera extends PlayerWeapon
	native
	config(Weapons)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

var private DynamicLightEffect FlashBulb;
var bool PhotoDisplayInProgress;

function PostBeginPlay()
{
	super.PostBeginPlay();
	FlashBulb = __NFUN_278__(Class'Engine.DynamicLightEffect');
	assert(__NFUN_119__(FlashBulb, none));
	AttachToBone(FlashBulb, 'None');
	FlashBulb.SetLightType(0);
	FlashBulb.LightBrightness = LightBrightness;
	FlashBulb.LightColor = LightColor;
	FlashBulb.LightRadius = LightRadius;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function bool UsesAmmo()
{
	return __NFUN_130__(__NFUN_129__(Holder.HasMod('PhotosensitiveSecretions_Exists')), super(Weapon).UsesAmmo());
	return;
	@NULL
	Item
}

protected function UseAmmo(bool inAltFiring)
{
	return;
}

function UseFilm()
{
	UseAmmo(false);
	return;
	@NULL
}

function OnFiringStarted()
{
	super(Weapon).OnFiringStarted();
	// End:0x30
	if(HasStrictlySuperiorMod())
	{
		FlashBulb.SetLightType(1);
		ShockPlayerController(Holder.Controller).CallHUDFunction('HideCameraOverlay');
	}
	ShockPlayerController(Holder.Controller).CallHUDFunction('ActivateShutter');
	Level.EffectsSystem.AddPersistentContext('PauseByCamera');
	ShockPlayerController(Holder.Controller).ForcePause();
	PlayerController(Holder.Controller).Player.Console.ConsoleCommand("PUSHINPUTCONTEXT PhotoGradingUIActive");
	PhotoDisplayInProgress = true;
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

function FinishAnimations()
{
	super.FinishAnimations();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x22
	/*@Error*/
	__NFUN_256__(0.0000000);
	// [Loop Continue]
	goto J0x0A;
	return;
	@NULL
	Collectable
}

function OnFiringFinished()
{
	super(Weapon).OnFiringFinished();
	FlashBulb.SetLightType(0);
	return;
	@NULL
	Item
	DifficultyAdjustment
}

function OnFiringInterrupted()
{
	super.OnFiringInterrupted();
	PhotoDisplayInProgress = false;
	Holder.UnTriggerEffectEvent('PhotoTaken');
	// End:0x7F
	if(__NFUN_119__(Level.Pauser, none))
	{
		ShockPlayerController(Holder.Controller).Pause();
		Level.EffectsSystem.RemovePersistentContext('PauseByCamera');
	}
	ShockPlayerController(Holder.Controller).bDisablePause = false;
	PlayerController(Holder.Controller).Player.Console.ConsoleCommand("POPINPUTCONTEXT PhotoGradingUIActive");
	Level.GetFlashGUIController().UnhideMovie('HUD');
	ShockPlayerController(Holder.Controller).CallHUDFunction('ClearPhotoInfo');
	ShockPlayerController(Holder.Controller).CallHUDFunction('showAll');
	ShockPlayerController(Holder.Controller).CallHUDFunction('ShowCameraOverlay');
	FlashBulb.SetLightType(0);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function Reload()
{
	SetCurrentAmmoSelection(DefaultAmmoSelection);
	return;
	@NULL
}

function OnEquippingFinished()
{
	SetCurrentAmmoSelection(DefaultAmmoSelection);
	super.OnEquippingFinished();
	ShockPlayerController(Holder.Controller).CallHUDFunction('ShowCameraOverlay');
	TriggerEffectEvent('CameraEquipped');
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnUnEquippingStarted()
{
	super(Holdable).OnUnEquippingStarted();
	ShockPlayerController(Holder.Controller).CallHUDFunction('HideCameraOverlay');
	UnTriggerEffectEvent('CameraEquipped');
	HideWeapon(true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnUnEquippingFinished()
{
	super(Holdable).OnUnEquippingFinished();
	HideWeapon(false);
	return;
	@NULL
}

function GiveAltFireMod()
{
	return;
}

function GiveStrictlySuperiorMod()
{
	return;
}

function PostLoadGame()
{
	super.PostLoadGame();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6E
	/*@Error*/
	ShockPlayerController(Holder.Controller).CallHUDFunction('ShowCameraOverlay');
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

defaultproperties
{
	CanBeZoomed=true
	ZoomedFOVAngle=45.0000000
	ZoomedForegroundFOVAngle=45.0000000
	ReloadingEmptyWeaponHandsAnim[0]=(AnimationName="CameraLoad",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	ReloadingNotEmptyWeaponHandsAnim[0]=(AnimationName="CameraLoad",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	FiringHandsAnim[0]=(AnimationName="None",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	FiringFinalShotHandsAnim[0]=(AnimationName="None",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	ZoomedFiringFinalShotHandsAnim[0]=(AnimationName="None",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	FriendlyName="Research Camera"
	AvailableAmmoTypes[0]=Class'ShockGame.Film'
	DefaultAmmoSelection=Class'ShockGame.Film'
	CanPendingFire=false
	bUseForDodgeTesting=false
	BaseMagazineSize=1000
	BaseAccuracy=0.0000000
	BaseFireRate=1.5000000
	IdlingHandsAnim[0]="None"
	IdlingHandsAnimWeight[0]=100.0000000
	AttachBone="Pistol"
	LightBrightness=3.0000000
	LightColor=(R=255,G=255,B=150,A=0)
	LightRadius=5000.0000000
}