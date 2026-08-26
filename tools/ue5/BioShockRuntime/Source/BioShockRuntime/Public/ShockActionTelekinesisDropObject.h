#pragma once

#include "ShockAction.h"
#include "ShockActionTelekinesisDropObject.generated.h"

/** UnrealScript `ActionTelekinesisDropObject`. Records drop request; no TK hold yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionTelekinesisDropObject : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionTelekinesisDropObject();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bDropRequested = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetDropRequested() const { return bDropRequested; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestDrop();
};
