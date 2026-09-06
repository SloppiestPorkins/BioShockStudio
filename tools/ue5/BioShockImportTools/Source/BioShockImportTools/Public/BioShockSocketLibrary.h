#pragma once

#include "Kismet/BlueprintFunctionLibrary.h"
#include "BioShockSocketLibrary.generated.h"

class USkeletalMesh;

UCLASS()
class BIOSHOCKIMPORTTOOLS_API UBioShockSocketLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
	/**
	 * Restore sockets dropped by the FBX round-trip.
	 * RelativeLocations are centimetres in UE left-handed Z-up; RelativeRotations are degrees.
	 * Empty / short arrays leave unset entries identity-on-bone (same as the legacy 3-arg call).
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Import", meta=(AutoCreateRefTerm="RelativeLocations,RelativeRotations"))
	static int32 RestoreSockets(
		USkeletalMesh* Mesh,
		const TArray<FName>& SocketNames,
		const TArray<FName>& BoneNames,
		const TArray<FVector>& RelativeLocations,
		const TArray<FRotator>& RelativeRotations);

	/** Legacy: name/bone only, identity relative transform. */
	static int32 RestoreSockets(USkeletalMesh* Mesh, const TArray<FName>& SocketNames, const TArray<FName>& BoneNames)
	{
		return RestoreSockets(Mesh, SocketNames, BoneNames, TArray<FVector>(), TArray<FRotator>());
	}
};
