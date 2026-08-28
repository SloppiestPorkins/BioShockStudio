#pragma once

#include "ShockAction.h"
#include "ShockActionSetPlayerInvincibility.generated.h"

class UWorld;

/** UnrealScript `ActionSetPlayerInvincibility`. ApplyInWorld sets the local ShockPlayer invincible. */
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

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
