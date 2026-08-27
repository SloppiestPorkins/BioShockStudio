class Wrench extends PlayerWeapon
	native
	config(Weapons)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

var bool ShowHitBox;
var array<Actor> HitActors;
var private transient pointer HitBoxCollidable;
var private float CollisionPhantomStartTime;
var private float CollisionPhantomStopTime;
var private int NumTimesSampled;

function OnFiringStarted()
{
	super(Weapon).OnFiringStarted();
	CreateCollisionPhantom();
	return;
	@NULL
}

// Export UWrench::execCreateCollisionPhantom(FFrame&, void* const)
native function CreateCollisionPhantom();

defaultproperties
{
	FiringHandsAnim[0]=(AnimationName="Swing_A_Wrench",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	FiringHandsAnim[1]=(AnimationName="Swing_B_Wrench",minAnimRate=0.0000000,maxAnimRate=100.0000000)
	FriendlyName="Wrench"
	AvailableAmmoTypes[0]=Class'ShockGame.WrenchAmmo'
	DefaultAmmoSelection=Class'ShockGame.WrenchAmmo'
	UsesAmmunition=false
	StaticWeaponModel=StaticMesh'ShockGame.WP_Wrench.WP_WrenchMesh'
	BaseAccuracy=0.0000000
	IdlingHandsAnim[0]="FidgetWrench"
	IdlingHandsAnim[1]="FidgetSlapWrench"
	IdlingHandsAnimWeight[0]=100.0000000
	IdlingHandsAnimWeight[1]=50.0000000
	EquippingHandsAnim="EquipWrench"
	AttachBone="Wrench"
	DrawPriority=1
}