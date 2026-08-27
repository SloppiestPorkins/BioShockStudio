#pragma once

#include "ShockAction.h"
#include "ShockActionSetProperty.generated.h"

class AActor;
class UWorld;

/**
 * UnrealScript `ActionSetProperty` (Scripting.U, native). Finds actors by label (`Object`) and
 * sets `Property` from `NewValue` via SetPropertyText. This class holds the three parameters and a
 * UE5 stand-in for the property write; it does not walk a script graph.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetProperty : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSetProperty();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ObjectLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName PropertyName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString NewValue;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InObjectLabel, FName InPropertyName, const FString& InNewValue);

	/** Sets ActorLabel when PropertyName is Label; bHidden/Hidden toggles actor hidden-in-game. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool ApplyToActor(AActor* Target);

	/** Find actors by ObjectLabel and ApplyToActor each. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
