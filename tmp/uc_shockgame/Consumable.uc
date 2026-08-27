class Consumable extends Item
	abstract
	native
	config(Inventory);

var config localized string AtFullHealthMessage;
var config localized string AtFullBioAmmoMessage;
var config localized string JustFilledHealthMessage;
var config localized string JustFilledBioAmmoMessage;
var config float HealthBonus;
var config float BioAmmoBonus;
var config int ADAMBonus;
var config int CreditBonus;

defaultproperties
{
	AtFullHealthMessage="Health Already Full"
	AtFullBioAmmoMessage="EVE Already Full"
	JustFilledHealthMessage="Health Filled To Full"
	JustFilledBioAmmoMessage="EVE Filled To Full"
}