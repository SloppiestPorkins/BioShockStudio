#pragma once

#include "ShockAction.h"
#include "ShockActionAssignNextSecurityBotSpawnLocation.generated.h"

/** UnrealScript `ActionAssignNextSecurityBotSpawnLocation`. Records SpawnLocationLabel. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionAssignNextSecurityBotSpawnLocation : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionAssignNextSecurityBotSpawnLocation();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName SpawnLocationLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastSpawnLocationLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InLabel);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastSpawnLocationLabel() const { return LastSpawnLocationLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestAssign();
};
