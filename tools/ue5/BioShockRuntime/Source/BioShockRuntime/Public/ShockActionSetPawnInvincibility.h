#pragma once

#include "ShockAction.h"
#include "ShockActionSetPawnInvincibility.generated.h"

class UWorld;

/** UnrealScript `ActionSetPawnInvincibility`. ApplyInWorld sets ShockPawn::bInvincible. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetPawnInvincibility : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSetPawnInvincibility();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName PawnLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bInvincible = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastPawnLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InPawn, bool bInInvincible);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetInvincible() const { return bInvincible; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastPawnLabel() const { return LastPawnLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
