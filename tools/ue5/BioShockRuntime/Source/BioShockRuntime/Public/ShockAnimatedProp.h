#pragma once

#include "GameFramework/Actor.h"
#include "ShockAnimatedProp.generated.h"

class UStaticMeshComponent;
class UWorld;

/** How this prop moves once activated. */
UENUM(BlueprintType)
enum class EShockAnimatedPropMode : uint8
{
	/** Continuous local-axis spin (fans). Runs from BeginPlay when bSpinOnBeginPlay. */
	ContinuousSpin = 0,
	/** Interpolate RelativeTransform through authored keyframes (ScriptableMover). */
	KeyframeMove = 1,
};

/** What happens when a keyframe move reaches the end. */
UENUM(BlueprintType)
enum class EShockPropLoopMode : uint8
{
	/** Play once and stop at the last key. */
	OneShot = 0,
	/** Reverse direction at each end (ping-pong). */
	PingPong = 1,
	/** Jump back to the start and repeat. */
	Loop = 2,
};

/**
 * Movable static-mesh prop for BioShock fans and ScriptableMovers.
 *
 * Transform-driven motion only — no skeletal animation data. Fans spin about a local axis;
 * movers interpolate RelativeTransform between keyframes with a swept move so they push/block
 * the player rather than teleporting through them.
 */
UCLASS()
class BIOSHOCKRUNTIME_API AShockAnimatedProp : public AActor
{
	GENERATED_BODY()

public:
	AShockAnimatedProp();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|AnimatedProp")
	FName PropLabel;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|AnimatedProp")
	EShockAnimatedPropMode MotionMode = EShockAnimatedPropMode::ContinuousSpin;

	/** Local axis for ContinuousSpin (unit vector in component space). Default +X. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|AnimatedProp|Spin")
	FVector SpinAxis = FVector(1.0f, 0.0f, 0.0f);

	/** Revolutions per second when SpinRateScale == 1. APPROXIMATED default for fans. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|AnimatedProp|Spin")
	float RevolutionsPerSecond = 1.0f;

	/** Runtime multiplier applied by ActionChangeAnimationRate. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|AnimatedProp|Spin")
	float SpinRateScale = 1.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|AnimatedProp|Spin")
	bool bSpinEnabled = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|AnimatedProp|Spin")
	bool bSpinOnBeginPlay = true;

	/** Seconds to traverse one keyframe segment at MotionRateScale == 1. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|AnimatedProp|Keyframe")
	float MoveDuration = 1.0f;

	/** Multiplier for keyframe speed (ActionChangeAnimationRate). */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|AnimatedProp|Keyframe")
	float MotionRateScale = 1.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|AnimatedProp|Keyframe")
	EShockPropLoopMode LoopMode = EShockPropLoopMode::OneShot;

	/** Relative transforms: index 0 = rest pose, 1..N = KeyPos/KeyRot targets. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|AnimatedProp|Keyframe")
	TArray<FTransform> KeyframeRelativeTransforms;

	UFUNCTION(BlueprintCallable, Category = "BioShock|AnimatedProp")
	void SetPropLabel(FName Label) { PropLabel = Label; }

	UFUNCTION(BlueprintCallable, Category = "BioShock|AnimatedProp")
	void ConfigureContinuousSpin(FName Label, FVector Axis, float InRevolutionsPerSecond, bool bStartEnabled = true);

	UFUNCTION(BlueprintCallable, Category = "BioShock|AnimatedProp")
	void ConfigureKeyframeMotion(
		FName Label,
		const TArray<FTransform>& RelativeKeys,
		float InMoveDuration,
		EShockPropLoopMode InLoopMode);

	/** Script ActionPlayAnimation: start/toggle keyframe move, or ensure spin is on. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|AnimatedProp")
	bool PlayScriptedMotion(FName AnimationName, float Rate, bool bLoop);

	UFUNCTION(BlueprintCallable, Category = "BioShock|AnimatedProp")
	void SetSpinEnabled(bool bEnabled);

	UFUNCTION(BlueprintCallable, Category = "BioShock|AnimatedProp")
	void SetSpinRateScale(float Scale);

	UFUNCTION(BlueprintCallable, Category = "BioShock|AnimatedProp")
	void SetMotionRateScale(float Scale);

	UFUNCTION(BlueprintPure, Category = "BioShock|AnimatedProp")
	uint8 GetMotionModeForVerify() const { return static_cast<uint8>(MotionMode); }

	UFUNCTION(BlueprintPure, Category = "BioShock|AnimatedProp")
	bool IsSpinEnabled() const { return bSpinEnabled; }

	UFUNCTION(BlueprintPure, Category = "BioShock|AnimatedProp")
	float GetEffectiveRevolutionsPerSecond() const { return RevolutionsPerSecond * SpinRateScale; }

	UFUNCTION(BlueprintPure, Category = "BioShock|AnimatedProp")
	float GetSpinRateScale() const { return SpinRateScale; }

	UFUNCTION(BlueprintPure, Category = "BioShock|AnimatedProp")
	float GetMotionRateScale() const { return MotionRateScale; }

	UFUNCTION(BlueprintPure, Category = "BioShock|AnimatedProp")
	bool IsKeyframeMoving() const { return bKeyframeMoving; }

	UFUNCTION(BlueprintPure, Category = "BioShock|AnimatedProp")
	float GetKeyframeAlpha() const { return KeyframeAlpha; }

	UFUNCTION(BlueprintPure, Category = "BioShock|AnimatedProp")
	FVector GetMeshRelativeLocation() const;

	UFUNCTION(BlueprintPure, Category = "BioShock|AnimatedProp")
	FRotator GetMeshRelativeRotation() const;

	UFUNCTION(BlueprintPure, Category = "BioShock|AnimatedProp")
	int32 GetKeyframeCountForVerify() const { return KeyframeRelativeTransforms.Num(); }

	UFUNCTION(BlueprintPure, Category = "BioShock|AnimatedProp")
	float GetAccumulatedSpinDegrees() const { return AccumulatedSpinDegrees; }

	UFUNCTION(BlueprintCallable, Category = "BioShock|AnimatedProp")
	void AdvanceMotionForVerify(float DeltaSeconds);

	UFUNCTION(BlueprintCallable, Category = "BioShock|AnimatedProp")
	void ConfigureSpinForVerify(FName Label, float InRevolutionsPerSecond);

	UFUNCTION(BlueprintCallable, Category = "BioShock|AnimatedProp")
	void ConfigureKeyframeForVerify(FName Label, FVector TargetRelativeLocation, float InMoveDuration);

	static AShockAnimatedProp* FindByLabel(UWorld* World, FName Label);

protected:
	virtual void BeginPlay() override;
	virtual void Tick(float DeltaSeconds) override;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|AnimatedProp")
	TObjectPtr<UStaticMeshComponent> PropMesh;

private:
	void TickSpin(float DeltaSeconds);
	void TickKeyframe(float DeltaSeconds);
	void ApplyKeyframeAlpha(float Alpha);
	void CaptureRestPose();
	int32 KeyframeSegmentCount() const;

	FTransform RestRelativeTransform = FTransform::Identity;
	bool bRestCaptured = false;
	bool bKeyframeMoving = false;
	/** 0..SegmentCount progress along the path (can reverse for ping-pong). */
	float KeyframeAlpha = 0.0f;
	float KeyframeDirection = 1.0f;
	FName LastScriptAnimation;
	float AccumulatedSpinDegrees = 0.0f;
};
