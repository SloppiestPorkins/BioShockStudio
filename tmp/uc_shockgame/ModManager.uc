class ModManager extends Object
	native;

struct native atomic TemporaryModData
{
	var travel name modName;
	var travel float TimeOut;
};

var travel ShockPawn PawnOwner;
var travel array<TemporaryModData> TemporaryMods;
var private native const noexport travel TMap_Padding Mods;
var private native const noexport travel TMap_Padding ModGroups;
var private native const noexport travel TMap_Padding ModObservers;

// Export UModManager::execDumpMods(FFrame&, void* const)
native function DumpMods();
