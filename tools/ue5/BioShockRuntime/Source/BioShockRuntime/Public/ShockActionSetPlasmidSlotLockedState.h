#pragma once

#include "ShockAction.h"
#include "ShockActionSetPlasmidSlotLockedState.generated.h"

UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetPlasmidSlotLockedState : public UShockAction
{
	GENERATED_BODY()
public:
	UShockActionSetPlasmidSlotLockedState();
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 Track = 0;
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLock = true;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(int32 InTrack, bool bInLock);
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();
};
