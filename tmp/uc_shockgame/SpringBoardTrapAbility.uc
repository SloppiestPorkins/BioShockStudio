class SpringBoardTrapAbility extends Ability
	native
	config(Abilities);

function CreateSpringBoardTrap(ShockPlayer Instigator)
{
	//native.Instigator;	
	@NULL
}

function UseAbility(ShockPlayer Instigator)
{
	CreateSpringBoardTrap(Instigator);
	super.UseAbility(Instigator);
	return;
	@NULL
	Item
	Item
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
	ModGroupName="SpringBoardTrap_Exists"
	BioAmmoCost=16.0000000
	FriendlyName="Cyclone Trap"
	FastEquipAnimationName="Vortex_Equip"
	SlowEquipAnimationName="Vortex_Equip"
	FireAnimationName="Vortex_Fire"
	FinishFireWithEveAnimationName="Vortex_FireEve"
	FinishFireWithoutEveAnimationName="Vortex_FireNoEve"
	IdlingAnimationName[0]="Vortex_Fidget"
	TargetIndicatorClass=Class'ShockGame.FXClass.SpringBoard_Cursor'
}