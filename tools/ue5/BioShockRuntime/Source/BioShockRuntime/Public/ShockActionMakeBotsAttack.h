#pragma once

#include "ShockAction.h"
#include "ShockActionMakeBotsAttack.generated.h"

/** UnrealScript `ActionMakeBotsAttack`. Records controller + attackee labels. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionMakeBotsAttack : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionMakeBotsAttack();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ControllerLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AttackeeLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastControllerLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InController, FName InAttackee);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastControllerLabel() const { return LastControllerLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestAttack();
};
