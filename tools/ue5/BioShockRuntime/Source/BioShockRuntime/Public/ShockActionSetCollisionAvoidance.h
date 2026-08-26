#pragma once

#include "ShockAction.h"
#include "ShockActionSetCollisionAvoidance.generated.h"

/** UnrealScript `ActionSetCollisionAvoidance`. Records avoidance flag; no nav yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetCollisionAvoidance : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSetCollisionAvoidance();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bShouldUseCollisionAvoidance = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastAILabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InAILabel, bool bInUse);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetShouldUseCollisionAvoidance() const { return bShouldUseCollisionAvoidance; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastAILabel() const { return LastAILabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();
};
