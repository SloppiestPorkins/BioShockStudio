#pragma once

#include "ShockAction.h"
#include "ShockActionAttachToBone.generated.h"

/** UnrealScript `ActionAttachToBone`. Records attachment params; no attach yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionAttachToBone : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionAttachToBone();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AttachmentActorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName BaseActorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetBone;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FVector AttachmentRelativeLocation = FVector::ZeroVector;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FRotator AttachmentRelativeRotation = FRotator::ZeroRotator;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastAttachmentActorLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(
		FName InAttachment,
		FName InBase,
		FName InBone,
		FVector InRelativeLocation,
		FRotator InRelativeRotation);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastAttachmentActorLabel() const { return LastAttachmentActorLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestAttach();
};
