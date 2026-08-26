#pragma once

#include "ShockAction.h"
#include "ShockActionAssassinTeleport.generated.h"

/** UnrealScript `ActionAssassinTeleport`. Records teleport request; no Assassin AI yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionAssassinTeleport : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionAssassinTeleport();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AssassinLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TeleportLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TeleportRotationLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bUseTeleportOutEffects = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bSkipEtherTime = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastAssassinLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InAssassin, FName InTeleport, FName InRotation, bool bInEffects, bool bInSkipEther);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastAssassinLabel() const { return LastAssassinLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestTeleport();
};
