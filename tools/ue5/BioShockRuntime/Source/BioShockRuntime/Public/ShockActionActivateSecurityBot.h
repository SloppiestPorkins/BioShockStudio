#pragma once

#include "ShockAction.h"
#include "ShockActionActivateSecurityBot.generated.h"

/** UnrealScript `ActionActivateSecurityBot`. Records pawn + bot labels; no bot spawn yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionActivateSecurityBot : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionActivateSecurityBot();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName PawnLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName BotLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastBotLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InPawn, FName InBot);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastBotLabel() const { return LastBotLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestActivate();
};
