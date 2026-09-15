#pragma once

#include "ShockAction.h"
#include "ShockActionSetEffectsSystemContext.generated.h"

/**
 * UnrealScript `ActionSetEffectsSystemContext`. R3.1: pushes/removes Context on
 * `UShockEffectsSubsystem`'s context stack (`GetCurrentContext`) — a future context-aware
 * bundle table can read it; the bundle resolver itself does not yet branch on context.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetEffectsSystemContext : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSetEffectsSystemContext();

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;

	/** Python/Blueprint-visible entry point (FShockActionContext is a native-only struct). */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool ApplyInWorld(UWorld* World);

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName Context;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	uint8 ContextAppliesTo = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bRemoveInsteadOfAdd = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLogTriggerInfo = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastContext;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InContext, uint8 InAppliesTo, bool bInRemove, bool bInLog);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	uint8 GetContextAppliesTo() const { return ContextAppliesTo; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetRemoveInsteadOfAdd() const { return bRemoveInsteadOfAdd; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastContext() const { return LastContext; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();
};
