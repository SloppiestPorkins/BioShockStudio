#pragma once

#include "ShockAction.h"
#include "ShockActionEnableOrDisableHavokForceActor.generated.h"

class UWorld;

/** UnrealScript `ActionEnableOrDisableHavokForceActor`. PLAUSIBLE enable gate on force trigger. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionEnableOrDisableHavokForceActor : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionEnableOrDisableHavokForceActor();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName Target;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bEnabled = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastTarget;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTarget, bool bInEnabled);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetEnabled() const { return bEnabled; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTarget() const { return LastTarget; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
