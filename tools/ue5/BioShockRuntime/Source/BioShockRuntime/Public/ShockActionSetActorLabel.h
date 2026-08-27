#pragma once

#include "ShockAction.h"
#include "ShockActionSetActorLabel.generated.h"

class AActor;
class UWorld;

/**
 * UnrealScript `ActionSetActorLabel`: rename ActorLabel → NewLabel.
 * First slice applies SetActorLabel on a passed actor (editor).
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetActorLabel : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSetActorLabel();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ActorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName NewLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastNewLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InActorLabel, FName InNewLabel);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastNewLabel() const { return LastNewLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool ApplyToActor(AActor* Target);

	/** Find ActorLabel and ApplyToActor (rename to NewLabel). */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
