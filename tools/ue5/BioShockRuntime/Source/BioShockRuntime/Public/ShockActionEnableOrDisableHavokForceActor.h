#pragma once

#include "ShockAction.h"
#include "ShockActionEnableOrDisableHavokForceActor.generated.h"

/** UnrealScript `ActionEnableOrDisableHavokForceActor`. Records Target + enabled; no Havok gate yet. */
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
};
