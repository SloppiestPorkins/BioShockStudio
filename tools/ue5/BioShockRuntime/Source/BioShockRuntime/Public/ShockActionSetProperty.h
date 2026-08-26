#pragma once

#include "ShockAction.h"
#include "ShockActionSetProperty.generated.h"

class AActor;

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

	/** Sets ActorLabel when PropertyName is Label/label; other properties stay UNKNOWN here. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool ApplyToActor(AActor* Target);
};
