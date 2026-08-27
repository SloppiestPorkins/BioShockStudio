#pragma once

#include "ShockAction.h"
#include "ShockActionEndGame.generated.h"

/** UnrealScript `ActionEndGame`. Records bad-ending threshold; no ending sequence yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionEndGame : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionEndGame();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 NumberOfGatherersKilledToGetBadEnding = 14;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bEndRequested = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(int32 InNumberOfGatherersKilledToGetBadEnding);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetNumberOfGatherersKilledToGetBadEnding() const { return NumberOfGatherersKilledToGetBadEnding; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetEndRequested() const { return bEndRequested; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestEnd();
};
