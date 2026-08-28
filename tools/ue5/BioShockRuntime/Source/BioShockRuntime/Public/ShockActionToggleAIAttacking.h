#pragma once

#include "ShockAction.h"
#include "ShockActionToggleAIAttacking.generated.h"

class UWorld;

/** UnrealScript `ActionToggleAIAttacking`. ApplyInWorld writes bCanAttack on labeled BaseShockAI. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionToggleAIAttacking : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionToggleAIAttacking();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bCanAttack = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastAILabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InAILabel, bool bInCanAttack);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetCanAttack() const { return bCanAttack; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastAILabel() const { return LastAILabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestToggle();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
