#pragma once

#include "ShockAction.h"
#include "ShockActionEnableBathysphereModeForPlayer.generated.h"

/** UnrealScript `ActionEnableBathysphereModeForPlayer`. Records enable flag; no player mode yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionEnableBathysphereModeForPlayer : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionEnableBathysphereModeForPlayer();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bEnableBathysphereMode = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastEnableBathysphereMode = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(bool bInEnable);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetEnableBathysphereMode() const { return bEnableBathysphereMode; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();
};
