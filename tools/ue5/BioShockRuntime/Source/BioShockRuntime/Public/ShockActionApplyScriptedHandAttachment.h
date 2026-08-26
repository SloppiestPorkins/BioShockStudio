#pragma once

#include "ShockAction.h"
#include "ShockActionApplyScriptedHandAttachment.generated.h"

/** UnrealScript `ActionApplyScriptedHandAttachment`. Records class + bone; no attach yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionApplyScriptedHandAttachment : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionApplyScriptedHandAttachment();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AttachmentClass;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AttachmentBone;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastAttachmentClass;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InClass, FName InBone);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastAttachmentClass() const { return LastAttachmentClass; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestApply();
};
