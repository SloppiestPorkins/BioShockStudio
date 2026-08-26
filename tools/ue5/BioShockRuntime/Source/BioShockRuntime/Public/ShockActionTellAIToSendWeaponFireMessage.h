#pragma once

#include "ShockAction.h"
#include "ShockActionTellAIToSendWeaponFireMessage.generated.h"

/**
 * UnrealScript `ActionTellAIToSendWeaponFireMessage`.
 * First slice records labels + weaponClass name; no fire message routing yet.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionTellAIToSendWeaponFireMessage : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionTellAIToSendWeaponFireMessage();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName WeaponLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName WeaponClass;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastAILabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InAI, FName InWeaponLabel, FName InWeaponClass);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastAILabel() const { return LastAILabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestTell();
};
