#pragma once

#include "ShockAction.h"
#include "ShockActionPlayScriptedHandAnimation.generated.h"

/**
 * UnrealScript `ActionPlayScriptedHandAnimation`. Records hand/attachment anim params;
 * no player hand mesh yet. AnimationEndBehavior default 4 from schema.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionPlayScriptedHandAnimation : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionPlayScriptedHandAnimation();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName HandAnimation;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AttachmentAnimation;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 AnimationEndBehavior = 4;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float EaseIn = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bWaitForAnimationToFinish = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastHandAnimation;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InHand, FName InAttachment, int32 InEndBehavior, float InEaseIn, bool bInWait);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetAnimationEndBehavior() const { return AnimationEndBehavior; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastHandAnimation() const { return LastHandAnimation; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestPlay();
};
