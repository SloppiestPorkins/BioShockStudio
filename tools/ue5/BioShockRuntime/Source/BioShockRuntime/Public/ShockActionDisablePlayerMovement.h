#pragma once

#include "ShockAction.h"
#include "ShockActionDisablePlayerMovement.generated.h"

/** UnrealScript `ActionDisablePlayerMovement`. Records DisableMovement; no input gate yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionDisablePlayerMovement : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionDisablePlayerMovement();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bDisableMovement = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastDisableMovement = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(bool bInDisable);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetDisableMovement() const { return bDisableMovement; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetLastDisableMovement() const { return bLastDisableMovement; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();
};
