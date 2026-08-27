class MedHypoBase extends Hypo
	native
	config(Inventory);

var config localized string AtFullHealthMessage;
var config float HealthAmount;

defaultproperties
{
	AtFullHealthMessage="Health Already Full"
}