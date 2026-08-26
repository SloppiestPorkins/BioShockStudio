#pragma once

#include "ShockAction.h"
#include "ShockActionRemoveScriptedHandAttachment.generated.h"

/** UnrealScript `ActionRemoveScriptedHandAttachment`. No params; records remove request. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionRemoveScriptedHandAttachment : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionRemoveScriptedHandAttachment();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bRemoveRequested = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool WasRemoveRequested() const { return bRemoveRequested; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestRemove();
};
