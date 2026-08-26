#pragma once

#include "ShockAction.h"
#include "ShockActionSetGathererVentPlayerCanSpawn.generated.h"

/** UnrealScript `ActionSetGathererVentPlayerCanSpawn`. Records vent + Flag. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetGathererVentPlayerCanSpawn : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSetGathererVentPlayerCanSpawn();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName GathererVentLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bFlag = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastGathererVentLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InVent, bool bInFlag);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetFlag() const { return bFlag; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastGathererVentLabel() const { return LastGathererVentLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();
};
