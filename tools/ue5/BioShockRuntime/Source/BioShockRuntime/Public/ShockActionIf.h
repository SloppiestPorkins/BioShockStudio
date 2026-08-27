#pragma once

#include "ShockAction.h"
#include "ShockActionIf.generated.h"

class UShockActionBool;

/**
 * UnrealScript `ActionIf` (Scripting.U, native). OR over `testsOr`; if any is true run
 * `trueActions`, else `elseActions`. This slice chooses the branch; it does not yet drive
 * latent nested Execute on a script VM.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionIf : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionIf();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TArray<TObjectPtr<UShockActionBool>> TestsOr;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TArray<TObjectPtr<UShockAction>> TrueActions;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TArray<TObjectPtr<UShockAction>> ElseActions;

	/** "true", "else", or empty before ChooseBranch. */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString LastBranch;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void AddTest(UShockActionBool* Test);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void AddTrueAction(UShockAction* Action);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void AddElseAction(UShockAction* Action);

	/** OR of EvaluateBool on testsOr. Empty testsOr is false (editor: "If nothing"). */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool EvaluateTestsOr() const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString ChooseBranch();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetLastBranch() const { return LastBranch; }
};
