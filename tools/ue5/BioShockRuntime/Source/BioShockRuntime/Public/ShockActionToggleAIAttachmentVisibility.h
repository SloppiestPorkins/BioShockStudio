#pragma once

#include "ShockAction.h"
#include "ShockActionToggleAIAttachmentVisibility.generated.h"

/** UnrealScript `ActionToggleAIAttachmentVisibility`. Records hide request; no attachments yet. */
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
};
