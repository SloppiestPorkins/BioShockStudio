#pragma once

#include "ShockAction.h"
#include "ShockActionFilterItem.generated.h"

/** UnrealScript `ActionFilterItem`. Records ItemClass + UnFilter; no inventory filter yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionFilterItem : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionFilterItem();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ItemClass;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bUnFilter = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastItemClass;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InItem, bool bInUnFilter);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetUnFilter() const { return bUnFilter; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastItemClass() const { return LastItemClass; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestFilter();
};
