class MessagePlayerFiredWeapon extends Message
	editinlinenew
	hidecategories(Object);

var Class<Weapon> weaponClass;
var Class<Ammunition> AmmoClass;
var bool WeaponWasEmpty;

function Construct(Weapon theWeapon, Class<Ammunition> theAmmoClass, bool wasEmpty)
{
	weaponClass = theWeapon.Class;
	AmmoClass = theAmmoClass;
	WeaponWasEmpty = wasEmpty;
	return;
	@NULL
	Item
	Vector
	@NULL
}

static function string editorDisplay(name Instigator, Message filter)
{
	return "The Player attempted to fire a weapon.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockGame.ShockPlayer'
}