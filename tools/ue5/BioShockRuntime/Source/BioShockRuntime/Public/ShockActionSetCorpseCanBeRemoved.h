#pragma once

#include "ShockAction.h"
#include "ShockActionSetCorpseCanBeRemoved.generated.h"

/** UnrealScript `ActionSetCorpseCanBeRemoved`. Records corpse label + flag; no corpse fade yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetCorpseCanBeRemoved : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSetCorpseCanBeRemoved();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName CorpseLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bCorpseCanBeRemoved = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastCorpseLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InCorpse, bool bInCanRemove);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetCorpseCanBeRemoved() const { return bCorpseCanBeRemoved; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastCorpseLabel() const { return LastCorpseLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();
};
