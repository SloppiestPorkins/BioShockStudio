class MeleeAmmo extends Ammunition implements IProvideMeleeDamageData
	config(Weapons);

var config float AttackAngle;
var config float AIvsAIMeleeRange;

function float GetAttackAngle()
{
	return AttackAngle;
	return;
	@NULL
}

function float GetAIvsAIMeleeRange()
{
	// End:0x20
	if(__NFUN_177__(AIvsAIMeleeRange, 0.0000000))
	{
		return AIvsAIMeleeRange;
		goto J0x2A;
		return AttackRange;
		return;
	}
	@NULL
	Item
	J0x2A:

	Item
}

defaultproperties
{
	AttackAngle=30.0000000
	DamageModel=Class'ShockGame.MeleeDamageFactory'
	AttackRange=200.0000000
}