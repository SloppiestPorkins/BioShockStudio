class Credits extends Freebie
	native
	config(Inventory);

var config localized string AtFullCreditsMessage;
var config localized string JustFilledCreditsMessage;
var config float CreditsLootModifier;

defaultproperties
{
	AtFullCreditsMessage="Wallet Already Full"
	JustFilledCreditsMessage="Wallet Filled To Full"
	CreditsLootModifier=0.7000000
	MaximumStackSize=1000000
	FriendlyName="Dollars"
}