#pragma once

#include "ShockAction.h"
#include "ShockActionDestroyAIs.generated.h"

/** UnrealScript `ActionDestroyAIs`. Records BaseClass / exceptions; no pawn destroy yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionDestroyAIs : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionDestroyAIs();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName BaseClassName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TArray<FName> LabelExceptions;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bOnlyLowDetailAIs = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastBaseClassName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InBaseClass, bool bInOnlyLowDetail);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void SetLabelExceptions(const TArray<FName>& InExceptions);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetOnlyLowDetail() const { return bOnlyLowDetailAIs; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastBaseClassName() const { return LastBaseClassName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestDestroy();
};
