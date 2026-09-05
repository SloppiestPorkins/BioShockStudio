#include "ShockUiDisplayNames.h"

namespace ShockUiDisplayNames
{
namespace
{
const TMap<FString, FString>& Table()
{
	static const TMap<FString, FString> Map = {
		{TEXT("ElectroBolt"), TEXT("Electro Bolt")},
		{TEXT("Incinerate"), TEXT("Incinerate!")},
		{TEXT("WinterBlast"), TEXT("Winter Blast")},
		{TEXT("Telekinesis"), TEXT("Telekinesis")},
		{TEXT("InsectSwarm"), TEXT("Insect Swarm")},
		{TEXT("Enrage"), TEXT("Enrage")},
		{TEXT("Wrench"), TEXT("Wrench")},
		{TEXT("Pistol"), TEXT("Pistol")},
		{TEXT("Shotgun"), TEXT("Shotgun")},
		{TEXT("TommyGun"), TEXT("Machine Gun")},
		{TEXT("MachineGun"), TEXT("Machine Gun")},
		{TEXT("ChemicalThrower"), TEXT("Chemical Thrower")},
		{TEXT("GrenadeLauncher"), TEXT("Grenade Launcher")},
		{TEXT("Crossbow"), TEXT("Crossbow")},
		{TEXT("ResearchCamera"), TEXT("Research Camera")},
		{TEXT("Camera"), TEXT("Research Camera")},
	};
	return Map;
}

FString SplitCamel(const FString& In)
{
	if (In.IsEmpty())
	{
		return In;
	}
	FString Out;
	Out.Reserve(In.Len() + 4);
	for (int32 i = 0; i < In.Len(); ++i)
	{
		const TCHAR Ch = In[i];
		if (i > 0 && FChar::IsUpper(Ch) && !FChar::IsUpper(In[i - 1]))
		{
			Out.AppendChar(TEXT(' '));
		}
		Out.AppendChar(Ch);
	}
	return Out;
}
} // namespace

FString Friendly(FName InternalName)
{
	return Friendly(InternalName.IsNone() ? FString() : InternalName.ToString());
}

FString Friendly(const FString& InternalName)
{
	if (InternalName.IsEmpty())
	{
		return InternalName;
	}
	if (const FString* Found = Table().Find(InternalName))
	{
		return *Found;
	}
	return SplitCamel(InternalName);
}
} // namespace ShockUiDisplayNames
