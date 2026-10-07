#pragma once

#include "CoreMinimal.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "ShockBakedLightLibrary.generated.h"

class UStaticMeshComponent;

/**
 * Per-instance baked vertex light for the live renderer (tools/ue5/apply_baked_props.py).
 *
 * BioShock bakes static-mesh light per vertex per placed instance (StaticMeshInstance; decoded by
 * BioShockStudio's VertexLightingExporter, in the exported OBJ's vertex order). UE's render vertices
 * are split and reordered at build, so colours are matched to them by position. The source
 * positions' axis/scale convention is detected from bounding boxes (48 signed axis permutations x
 * a few scales), then each render vertex takes its nearest source vertex's colour. The result goes
 * into the component's LOD0 OverrideVertexColors, which is saved with the level (as painted vertex
 * colours are).
 */
UCLASS()
class BIOSHOCKRUNTIME_API UShockBakedLightLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
	/** Returns how many render vertices found a source vertex within tolerance (-1 on failure). */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Live")
	static int32 ApplyBakedVertexLight(UStaticMeshComponent* Component, const TArray<FVector>& SourcePositions,
		const TArray<FColor>& SourceColors);
};
