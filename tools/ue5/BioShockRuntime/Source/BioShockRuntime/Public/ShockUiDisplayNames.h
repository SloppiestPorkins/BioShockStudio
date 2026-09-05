#pragma once

#include "CoreMinimal.h"

/**
 * Maps internal weapon/plasmid def names (ElectroBolt, TommyGun, …) to BioShock-style
 * HUD / radial labels ("Electro Bolt", "Machine Gun"). Unknown names get a light CamelCase split.
 */
namespace ShockUiDisplayNames
{
BIOSHOCKRUNTIME_API FString Friendly(FName InternalName);
BIOSHOCKRUNTIME_API FString Friendly(const FString& InternalName);
}
