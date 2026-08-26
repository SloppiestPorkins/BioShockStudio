#pragma once

#include "ShockAction.h"
#include "ShockActionAttachCollisionDamageListener.generated.h"

/** UnrealScript `ActionAttachCollisionDamageListener`. Records target + owner; no listener yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionAttachCollisionDamageListener : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionAttachCollisionDamageListener();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName OwnerLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastTargetLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTarget, FName InOwner);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTargetLabel() const { return LastTargetLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestAttach();
};
