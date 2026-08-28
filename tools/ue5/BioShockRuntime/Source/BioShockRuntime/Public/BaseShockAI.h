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

	/** Last pawn passed to ScriptedAttackTarget. Not a combat state machine. */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<AShockPawn> CurrentScriptedAttackTarget;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TArray<FName> AttackOnSightLabels;

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	void ConfigureIdentity(FName InType, FName InLabel);

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	FName GetScriptLabel() const { return ScriptLabel; }

	/** UnrealScript `ShockAI.ScriptedAttackTarget` — stores the target; no pathing/weapons yet. */
	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	void ScriptedAttackTarget(AShockPawn* Target);

	/** UnrealScript `ShockAI.AddTargetToAttackOnSight` — records the label; no sight cone yet. */
	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	void AddTargetToAttackOnSight(FName InTargetLabel);

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	AShockPawn* GetScriptedAttackTarget() const { return CurrentScriptedAttackTarget; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool HasAttackOnSightLabel(FName InTargetLabel) const;
};
