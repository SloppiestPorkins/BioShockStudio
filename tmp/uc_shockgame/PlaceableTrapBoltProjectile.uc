class PlaceableTrapBoltProjectile extends TrapBoltProjectile
	native
	config(Weapons)
	placeable
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Animation);

var config Class<Item> ItemClass;
var config Class<DamageFactory> SpecifiedDamageFactoryClass;

function PostBeginPlay()
{
	super(ShockProjectile).PostBeginPlay();
	__NFUN_3970__(0);
	__NFUN_262__(true, false, false);
	AssertWithDescription(__NFUN_119__(SpecifiedDamageFactoryClass, none), "SpecifiedDamageFactoryClass must be set for placed trap bolts in weapons.ini!");
	DamageFactoryClass = SpecifiedDamageFactoryClass;
	AssertWithDescription(__NFUN_119__(ItemClass, none), "ItemClass must be set for placed trap bolts in weapons.ini!");
	ProjectileData = IProvideProjectileDamageData(ShockGameInfo(Level.Game).GetItemFromClass(ItemClass));
	assert(__NFUN_119__(ProjectileData, none));
	AutoArm();
	return;
	@NULL
	Item
	stop;
	default.@NULL
}
