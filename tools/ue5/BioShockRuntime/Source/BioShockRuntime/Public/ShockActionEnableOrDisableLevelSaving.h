#pragma once

#include "ShockAction.h"
#include "ShockActionEnableOrDisableLevelSaving.generated.h"

class UWorld;

/** UnrealScript `ActionEnableOrDisableLevelSaving`. ApplyInWorld sets the save gate on ShockPlayer. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionEnableOrDisableLevelSaving : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionEnableOrDisableLevelSaving();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bDisableLevelSaving = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastDisableLevelSaving = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(bool bInDisable);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetDisableLevelSaving() const { return bDisableLevelSaving; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetLastDisableLevelSaving() const { return bLastDisableLevelSaving; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
