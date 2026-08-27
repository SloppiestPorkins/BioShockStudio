class WeaponUpgradeStation extends ShockMachine
	native
	config(Machines)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

var int StationLevel;

function HackInfo OnHackSucceeded(ShockPlayer Player, string HackResult)
{
	super.OnHackSucceeded(Player, HackResult);
	CurrentPlayer.BeginWeaponUpgradeInteraction();
	return GetHackInfo();
	return;
	@NULL
	Item
	Item
	@NULL
}

state Interacting
{
	protected latent function BeginInteracting()
	{
		return;
	}
	stop;
}

defaultproperties
{
	StationLevel=1
	HackInfoName="WeaponUpgradeStationDefault"
	bCanBeHacked=false
	HackingSuccessFeedbackText="Succesfully hacking this station will cause all upgrades to be cheaper."
	FriendlyName="Weapon Upgrade Station"
	DormantFriendlyName="Closed Weapon Upgrade Station"
}