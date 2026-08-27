class HealthUpgrade extends Freebie
	native
	config(Inventory);

var config float UpgradeAmount;

defaultproperties
{
	UpgradeAmount=35.0000000
	MaximumStackSize=7
	Description="Increase your Maximum Health"
	FriendlyName="Health Upgrade"
	CreditValue=80.0000000
}