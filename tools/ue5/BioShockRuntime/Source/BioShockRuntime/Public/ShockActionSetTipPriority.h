#pragma once

#include "ShockAction.h"
#include "ShockActionSetTipPriority.generated.h"

class UWorld;

/** UnrealScript `ActionSetTipPriority`: writes TipName → Priority on the local ShockPlayer. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetTipPriority : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSetTipPriority();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TipName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 Priority = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastTipName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 LastPriority = 0;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTipName, int32 InPriority);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTipName() const { return LastTipName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetLastPriority() const { return LastPriority; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
