#pragma once

#include "ShockAction.h"
#include "ShockActionSetPawnInvincibility.generated.h"

/** UnrealScript `ActionSetPawnInvincibility`. Records PawnLabel + flag; no damage gate yet. */
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
};
