#pragma once

#include "ShockPawn.h"
#include "BaseShockAI.generated.h"

/**
 * UnrealScript `BaseShockAI`. No states — playable-slice home for a spawnable AI pawn.
 * ScriptLabel mirrors level actor labels for Action* lookups (not a full label system).
 */
UCLASS()
class BIOSHOCKRUNTIME_API ABaseShockAI : public AShockPawn
{
	GENERATED_BODY()

public:
	ABaseShockAI();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ScriptLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AITypeName;

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	void ConfigureIdentity(FName InType, FName InLabel);

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	FName GetScriptLabel() const { return ScriptLabel; }
};
