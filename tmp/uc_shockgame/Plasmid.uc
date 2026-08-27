class Plasmid extends Freebie
	abstract
	native
	config(Plasmids);

enum ePlasmidTrack
{
	TRACK_None,                     // 0
	TRACK_Active,                   // 1
	TRACK_Physical,                 // 2
	TRACK_Engineering,              // 3
	TRACK_Weapons                   // 4
};

enum ePlasmidColor
{
	COLOR_None,                     // 0
	COLOR_Yellow,                   // 1
	COLOR_Green,                    // 2
	COLOR_Blue,                     // 3
	COLOR_Orange                    // 4
};

var config int Prereqs[5];
var config Class<Plasmid> PlasmidPrerequisite;
var config Plasmid.ePlasmidTrack Track;
var config Plasmid.ePlasmidColor Color;
var config localized string CurrentEffectString;
var config localized string FlavorDescription;
var config bool DisplayCurrentEffectWhenUnEquipped;
var config bool LockedContent;
var config bool MandatoryEquip;
var config string FoundIn;

function OnPlasmidEquipped(ShockPlayer Instigator)
{
	ShockPlayerController(Instigator.Controller).GetPlayerStatsManager().PlayerPlasmidEquipped(Instigator, self);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function OnPlasmidUnEquipped(ShockPlayer Instigator)
{
	ShockPlayerController(Instigator.Controller).GetPlayerStatsManager().PlayerPlasmidUnEquipped(Instigator, self);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}
