#pragma once

#include "ShockAction.h"
#include "ShockActionToggleAIReactions.generated.h"

class UWorld;

UENUM(BlueprintType)
enum class EShockToggleHitReactions : uint8
{
	DoNotChange = 0,
	Use = 1,
	DoNotUse = 2,
};

/**
 * UnrealScript `ActionToggleAIReactions`. ApplyInWorld stores full-body/quick reaction
 * bytes on labeled BaseShockAI. No montage playback.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionToggleAIReactions : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionToggleAIReactions();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	EShockToggleHitReactions FullBodyHitReactions = EShockToggleHitReactions::DoNotChange;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	EShockToggleHitReactions QuickHitReactions = EShockToggleHitReactions::DoNotChange;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	EShockToggleHitReactions FallDownHitReactions = EShockToggleHitReactions::DoNotChange;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	EShockToggleHitReactions EventReactions = EShockToggleHitReactions::DoNotChange;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastAILabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InAILabel, EShockToggleHitReactions InFullBody, EShockToggleHitReactions InQuick);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	EShockToggleHitReactions GetFullBodyHitReactions() const { return FullBodyHitReactions; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastAILabel() const { return LastAILabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestToggle();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
