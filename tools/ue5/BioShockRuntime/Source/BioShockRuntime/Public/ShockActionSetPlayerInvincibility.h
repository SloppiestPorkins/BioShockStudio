#pragma once

#include "ShockAction.h"
#include "ShockActionSetPlayerInvincibility.generated.h"

/** UnrealScript `ActionSetPlayerInvincibility`. Records bInvincible; no god-mode wiring yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetPlayerInvincibility : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSetPlayerInvincibility();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bInvincible = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastInvincible = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(bool bInInvincible);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetInvincible() const { return bInvincible; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetLastInvincible() const { return bLastInvincible; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();
};
