#pragma once

#include "ShockAction.h"
#include "ShockActionToggleAIAttacking.generated.h"

/** UnrealScript `ActionToggleAIAttacking`. Records AILabel + bCanAttack; no combat yet. */
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
};
