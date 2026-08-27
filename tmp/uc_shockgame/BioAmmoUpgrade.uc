class BioAmmoUpgrade extends Freebie
	native
	config(Inventory);

var config float UpgradeAmount;

defaultproperties
{
	UpgradeAmount=6.0000000
	MaximumStackSize=7
	Description="Increase your Maximum EVE"
	FriendlyName="EVE Upgrade"
	CreditValue=80.0000000
}