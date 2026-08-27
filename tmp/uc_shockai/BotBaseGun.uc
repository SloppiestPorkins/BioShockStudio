class BotBaseGun extends AIRangedWeapon
	native
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

var private config float ChargeTime;

function StartCharging()
{
	return;
}

function float GetChargeTime()
{
	return ChargeTime;
	return;
	@NULL
}

function bool WeaponHandlesOwnAttack()
{
	return false;
	return;
}

latent function FireWeapon()
{
	BeginFiring();
	return;
}

function OnFiringStarted()
{
	super.OnFiringStarted();
	TriggerEffectEvent('BotFiring');
	return;
	@NULL
}

function OnFiringFinished()
{
	UnTriggerEffectEvent('BotFiring');
	super(AIWeapon).OnFiringFinished();
	return;
	@NULL
}
