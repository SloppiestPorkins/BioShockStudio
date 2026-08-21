#pragma once

#include "Kismet/BlueprintFunctionLibrary.h"
#include "BioShockSocketLibrary.generated.h"

class USkeletalMesh;

UCLASS()
class BIOSHOCKIMPORTTOOLS_API UBioShockSocketLibrary : public UBlueprintFunctionLibrary
{
    GENERATED_BODY()

public:
    UFUNCTION(BlueprintCallable, Category="BioShock|Import")
    static int32 RestoreSockets(USkeletalMesh* Mesh, const TArray<FName>& SocketNames, const TArray<FName>& BoneNames);
};
