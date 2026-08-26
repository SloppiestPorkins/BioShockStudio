#pragma once

#include "ShockAction.h"
#include "ShockActionVariableAssign.generated.h"

class UShockVariableScope;

/**
 * UnrealScript `ActionVariableAssign` / shared assign path: lhs name + rhs string, write into a
 * variable scope. Subclasses choose overwrite vs create-only.
 */
UCLASS(Abstract, BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionVariableAssign : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionVariableAssign();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName Lhs;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString Rhs;

	/** When true, skip if Lhs already exists (ActionVariableAssignIfNotExist). */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bOnlyIfMissing = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InLhs, const FString& InRhs);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLhs() const { return Lhs; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetRhs() const { return Rhs; }

	/**
	 * Writes Rhs into Scope under Lhs. Returns false if Scope/Lhs invalid, or if bOnlyIfMissing
	 * and the name already exists.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool ApplyToScope(UShockVariableScope* Scope);
};
