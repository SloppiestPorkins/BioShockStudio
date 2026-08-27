class UpgradeableWeaponStat extends Object
	native
	config(Weapons)
	perobjectconfig;

var config int MinSlotRequirement;
var config int MaxUpgradePoints;
var config int CreditCost;
var config float HackCostModifier;
var config name StatName;
var config localized string FriendlyName;
var config localized array<localized string> Description;
var config travel int PointsAllocated;
