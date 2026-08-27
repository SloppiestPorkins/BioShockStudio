class DecoyHumanAbility extends Ability
	native
	config(Abilities);

var config string TargetIndicatorClassString;
var config string DecoyHumanClassString;
var Class<BaseShockAI> DecoyHumanClass;
var config Vector SpawnOffset;

function UseAbility(ShockPlayer Instigator)
{
	local BaseShockAI NewDecoyHuman;
	local Vector DecoyPosition;

	DecoyPosition = __NFUN_215__(Instigator.LastTargetLocation, SpawnOffset);
	NewDecoyHuman = Instigator.__NFUN_278__(DecoyHumanClass, none,, DecoyPosition, Instigator.Rotation, true);
	NewDecoyHuman.LifeSpan = Instigator.ModifyStat('DecoyHumanLifeSpan_Bonus', 0.0000000);
	super.UseAbility(Instigator);
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool CanUseAbility(ShockPlayer Instigator)
{
	return __NFUN_130__(Instigator.TargetLocationIsValid, super.CanUseAbility(Instigator));
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	TargetIndicatorClassString="FXClass.DecoyHumanTarget"
	DecoyHumanClassString="ShockAIClasses.SpawnedDecoyHumanAI"
	SpawnOffset=(X=0.0000000,Y=0.0000000,Z=80.0000000)
	ModGroupName="DecoyHuman_Exists"
	BioAmmoCost=8.0000000
	FriendlyName="Target Dummy"
	TargetIndicatorOffset=(X=0.0000000,Y=0.0000000,Z=80.0000000)
}