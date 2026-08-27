class PlasmidManager extends ReferenceCountedObject
	native
	config(Plasmids);

var travel ShockPlayer PlayerOwner;
var travel array<name> AvailablePlasmids;
var private travel PlasmidTrack Tracks[5];
var private config int MaxEffectiveSlots;
var config array<name> LinkConfigurations;
var config array<int> SlotPurchaseCost;
var private name SelectedLinkConfigurationName;
var private travel LinkConfiguration LinkConfiguration;
var private const noexport transient TMap_Padding PlasmidMap;

function int GetNumAvailablePlasmids()
{
	return AvailablePlasmids.Length;
	return;
	@NULL
}

function name GetAvailablePlasmidNameByIndex(int Index)
{
	return AvailablePlasmids[Index];
	return;
	@NULL
	Item
}

// Export UPlasmidManager::execHasEmptyPlasmidSlot(FFrame&, void* const)
native function bool HasEmptyPlasmidSlot();

function bool IsNonDLCPlasmid(name PlasmidName)
{
	//native.PlasmidName;	
	@NULL
}

function DumpPlasmids()
{
	local int i;

	log(,, "********************************************************");
	log(,, "*** Dumping Plasmid System ***");
	log(,, "");
	log(,, "--------------------------------------------------------");
	log(,, "--- Available Plasmids ---");
	log(,, "");
	i = 0;
	// End:0x132
	if(__NFUN_150__(i, AvailablePlasmids.Length))
	{
		log(,, __NFUN_112__("   ", string(AvailablePlasmids[i])));
		__NFUN_165__(i);
		// [Loop Continue]
		goto J0xE9;
		log(,, "");
		log(,, "--------------------------------------------------------");
	}
	log(,, "--- Equipped Plasmids ---");
	log(,, "");
	i = 1;
	// End:0x228
	if(__NFUN_150__(i, int(5)))
	{
		log(,, __NFUN_112__(__NFUN_112__("=== ", string(GetEnum(Enum'ShockGame.Plasmid.ePlasmidTrack', i))), " ==="));
		Tracks[i].DumpTrack();
		__NFUN_165__(i);
		// [Loop Continue]
		goto J0x1B2;
		log(,, "");
		log(,, "--------------------------------------------------------");
	}
	log(,, "--- Link Configuration ---");
	log(,, "");
	log(,, __NFUN_112__(__NFUN_112__("=== ", string(SelectedLinkConfigurationName)), " ==="));
	LinkConfiguration.DumpConfiguration();
	log(,, "********************************************************");
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

defaultproperties
{
	MaxEffectiveSlots=8
	LinkConfigurations[0]="LinkConfigA"
	LinkConfigurations[1]="LinkConfigB"
	LinkConfigurations[2]="LinkConfigC"
	LinkConfigurations[3]="LinkConfigD"
	LinkConfigurations[4]="LinkConfigE"
	LinkConfigurations[5]="LinkConfigF"
	SlotPurchaseCost[0]=0
	SlotPurchaseCost[1]=8
	SlotPurchaseCost[2]=4
	SlotPurchaseCost[3]=12
	SlotPurchaseCost[4]=16
	SlotPurchaseCost[5]=28
}