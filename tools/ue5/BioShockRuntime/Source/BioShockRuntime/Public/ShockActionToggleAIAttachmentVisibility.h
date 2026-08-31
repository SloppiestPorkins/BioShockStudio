#pragma once

#include "ShockAction.h"
#include "ShockActionToggleAIAttachmentVisibility.generated.h"

class UWorld;

/** UnrealScript `ActionToggleAIAttachmentVisibility`. ApplyInWorld stores hide flag on labeled AI. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionToggleAIAttachmentVisibility : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionToggleAIAttachmentVisibility();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AttachmentCategory;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bHideAttachments = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastAILabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InAILabel, FName InCategory, bool bInHide);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetHideAttachments() const { return bHideAttachments; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastAILabel() const { return LastAILabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestToggle();

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
