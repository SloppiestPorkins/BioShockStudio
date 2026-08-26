#pragma once

#include "ShockAction.h"
#include "ShockActionToggleCeilingCrawlerRangedAttack.generated.h"

/** UnrealScript `ActionToggleCeilingCrawlerRangedAttack`. Records toggle; no crawler AI yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionToggleCeilingCrawlerRangedAttack : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionToggleCeilingCrawlerRangedAttack();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName CeilingCrawlerLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bEnableRangedAttack = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastCeilingCrawlerLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InLabel, bool bInEnable);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetEnableRangedAttack() const { return bEnableRangedAttack; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastCeilingCrawlerLabel() const { return LastCeilingCrawlerLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestToggle();
};
