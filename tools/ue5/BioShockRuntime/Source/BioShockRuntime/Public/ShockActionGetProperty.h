#pragma once

#include "ShockAction.h"
#include "ShockActionGetProperty.generated.h"

class AActor;
class UWorld;

/**
 * UnrealScript `ActionGetProperty` (Scripting.U, native): `execute()` finds `Object` by label,
 * reads `Object.GetPropertyTextByName(Property)`, and returns it as a temporary `Variable` for
 * a sibling action's `resolveInfoList` to consume. Port: `ShockScriptReflection::GetPropertyAsText`
 * (component-dotted path support beyond BioShock's flat one — see ShockScriptReflection.h),
 * stored on `UShockAction::ReturnValueText`.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionGetProperty : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionGetProperty();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ObjectLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString PropertyPath;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InObjectLabel, const FString& InPropertyPath);

	/** Resolves ObjectLabel.PropertyPath and stores the text on the return value. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool ApplyInWorld(UWorld* World);

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;
};
