#pragma once

#include "ShockAction.h"
#include "ShockActionPlayAnimation.generated.h"

class AActor;
class UWorld;

/** Mirrors UnrealScript ActionPlayAnimation.EEndBehaviorMode. */
UENUM(BlueprintType)
enum class EShockAnimEndBehavior : uint8
{
	Pause = 0,
	Loop = 1,
	Stop = 2,
	EaseOut = 3,
};

/**
 * UnrealScript `ActionPlayAnimation` (ShockGame.U). Finds actors by TargetLabel and plays:
 * - AShockAnimatedProp: start/toggle keyframe move or enable spin
 * - otherwise: records the play request only (mesh AnimSequence path not wired)
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionPlayAnimation : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionPlayAnimation();

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName Animation;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float AnimationRate = 1.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float TweenTime = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 Channel = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	EShockAnimEndBehavior EndBehavior = EShockAnimEndBehavior::Pause;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bWaitForCompletion = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bOnlyPlayOnAlivePawns = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastPlayedAnimation;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString LastPlayedActorName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTargetLabel, FName InAnimation, float InRate, int32 InChannel);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void SetWaitForCompletion(bool bWait) { bWaitForCompletion = bWait; }

	UFUNCTION(BlueprintPure, Category="BioShock|Action")
	bool ShouldWaitForCompletion() const { return bWaitForCompletion; }

	/** Door-only latent completion used by UShockScriptRunner. */
	bool IsCompleteInWorld(UWorld* World) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetAnimation() const { return Animation; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetAnimationRate() const { return AnimationRate; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetOnlyPlayOnAlivePawns() const { return bOnlyPlayOnAlivePawns; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastPlayedAnimation() const { return LastPlayedAnimation; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetLastPlayedActorName() const { return LastPlayedActorName; }

	/** Records the play request; drives AShockAnimatedProp when the target is one. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool PlayOnActor(AActor* Target);

	/** Find actors by TargetLabel and PlayOnActor each. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 PlayInWorld(UWorld* World);
};
