#pragma once

#include "ShockActionBool.h"
#include "ShockActionTestFact.generated.h"

/**
 * UnrealScript `ActionTestFact` (ShockGame.U, native). Holds Slot_1/2/3 for a fact check.
 * First slice stores params; EvaluateBool is false until FactDatabase is wired.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionTestFact : public UShockActionBool
{
	GENERATED_BODY()

public:
	UShockActionTestFact();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName Slot1;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString Slot2;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString Slot3;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bRequested = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InSlot1, const FString& InSlot2, const FString& InSlot3);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestTest();

	virtual bool EvaluateBool() const override;
};
