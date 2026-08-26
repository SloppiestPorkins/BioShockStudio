#pragma once

#include "ShockAction.h"
#include "ShockActionGrenadierUseLiveGrenadeWeapon.generated.h"

/** UnrealScript `ActionGrenadierUseLiveGrenadeWeapon`. Records GrenadierLabel; no grenade AI yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionGrenadierUseLiveGrenadeWeapon : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionGrenadierUseLiveGrenadeWeapon();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName GrenadierLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastGrenadierLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InGrenadier);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastGrenadierLabel() const { return LastGrenadierLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestUse();
};
