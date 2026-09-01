#pragma once

#include "ShockAction.h"
#include "ShockActionAssignNextSecurityBotSpawnLocation.generated.h"

class UWorld;

/** UnrealScript `ActionAssignNextSecurityBotSpawnLocation`. Records SpawnLocationLabel. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionAssignNextSecurityBotSpawnLocation : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionAssignNextSecurityBotSpawnLocation();

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;

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

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
