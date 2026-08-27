class DamageMultiplierSet extends Object
	native
	config(AI)
	perobjectconfig;

struct native atomic LocationalDamageMultiplierEntry
{
	var config Actor.ESkeletalRegion DamageRegion;
	var config name StimuliSetName;
	var config float Multiplier;
};

var config array<LocationalDamageMultiplierEntry> Multipliers;
var array<float> DefaultDamageLocationMultipliers;
var private native const noexport TMap_Padding SpecificDamageLocationMultipliers;
