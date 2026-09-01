#pragma once

#include "ShockAction.h"
#include "ShockActionActivateSecurityBot.generated.h"

class UWorld;

/** UnrealScript `ActionActivateSecurityBot`. Records pawn + bot labels; no bot spawn yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionActivateSecurityBot : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionActivateSecurityBot();

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;

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

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
