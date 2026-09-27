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
 *
 * ScriptableMovers (SCR-G01): listen for MessageTrigger from labels in TriggeredBy (TriggerToggle),
 * ignore triggers mid-move, and emit MessageMoverOpening/Opened/Closing/Closed under PropLabel.
 */
UCLASS()
class BIOSHOCKRUNTIME_API AShockAnimatedProp : public AActor
{
	GENERATED_BODY()

public:
	AShockAnimatedProp();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|AnimatedProp")
	FName PropLabel;

	/**
	 * Comma-separated Script Labels whose MessageTrigger toggles this mover (UE2 TriggeredBy).
	 * Empty / "none" → never message-driven (script PlayAnimation still works).
	 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|AnimatedProp|Mover")
	FString TriggeredBy;

	/** UE2 triggerMessageType; movers listen for MessageTrigger (and subclasses). */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|AnimatedProp|Mover")
	FName TriggerMessageType = FName(TEXT("MessageTrigger"));

	/** UE2 bTriggerOnceOnly — after one completed toggle cycle, further triggers are ignored. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|AnimatedProp|Mover")
	bool bTriggerOnceOnly = false;

	/** UE2 StayOpenTime — used when InitialState is TriggerOpenTimed (auto-close after open). */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|AnimatedProp|Mover")
	float StayOpenTime = 0.0f;

	/** UE2 InitialState name (TriggerToggle / TriggerOpenTimed). Default TriggerToggle. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|AnimatedProp|Mover")
	FName InitialState = FName(TEXT("TriggerToggle"));

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

	/** Seconds to traverse one keyframe segment at MotionRateScale == 1 (UE2 MoveTime). */
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
	void SetTriggeredBy(const FString& InTriggeredBy) { TriggeredBy = InTriggeredBy; }

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

	/**
	 * MessageTrigger (or subclass) from a Script Label listed in TriggeredBy.
	 * TriggerToggle: ignore while mid-move; otherwise open or close along keyframes and emit
	 * MessageMover* under PropLabel. Returns true when the trigger was accepted.
	 */
	UFUNCTION(BlueprintCallable, Category = "BioShock|AnimatedProp")
	bool HandleTriggerMessage(FName MessageClassName, const FString& SourceLabel);

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

	UFUNCTION(BlueprintPure, Category = "BioShock|AnimatedProp")
	FString GetTriggeredBy() const { return TriggeredBy; }

	UFUNCTION(BlueprintPure, Category = "BioShock|AnimatedProp")
	bool HasCompletedTriggerOnce() const { return bTriggerOnceCompleted; }

	UFUNCTION(BlueprintCallable, Category = "BioShock|AnimatedProp")
	void AdvanceMotionForVerify(float DeltaSeconds);

	UFUNCTION(BlueprintCallable, Category = "BioShock|AnimatedProp")
	void ConfigureSpinForVerify(FName Label, float InRevolutionsPerSecond);

	UFUNCTION(BlueprintCallable, Category = "BioShock|AnimatedProp")
	void ConfigureKeyframeForVerify(FName Label, FVector TargetRelativeLocation, float InMoveDuration);

	/** Headless: keyframe mover + TriggeredBy + MoveTime (StayOpen unused unless InitialState set). */
	UFUNCTION(BlueprintCallable, Category = "BioShock|AnimatedProp")
	void ConfigureMoverForVerify(
		FName Label,
		const FString& InTriggeredBy,
		FVector TargetRelativeLocation,
		float InMoveDuration,
		bool bInTriggerOnceOnly = false);

	static AShockAnimatedProp* FindByLabel(UWorld* World, FName Label);

protected:
	virtual void BeginPlay() override;
	virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;
	virtual void Tick(float DeltaSeconds) override;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|AnimatedProp")
	TObjectPtr<UStaticMeshComponent> PropMesh;

private:
	void TickSpin(float DeltaSeconds);
	void TickKeyframe(float DeltaSeconds);
	void ApplyKeyframeAlpha(float Alpha);
	void CaptureRestPose();
	int32 KeyframeSegmentCount() const;
	bool MatchesTriggeredBy(const FString& SourceLabel) const;
	bool MatchesTriggerMessageClass(FName MessageClassName) const;
	bool BeginKeyframeToggle(/*out*/ bool& bOpening);
	void EmitMoverMessage(FName MessageClassName);
	void RegisterWithScriptSubsystem();
	void UnregisterFromScriptSubsystem();

	FTransform RestRelativeTransform = FTransform::Identity;
	bool bRestCaptured = false;
	bool bKeyframeMoving = false;
	/** 0..SegmentCount progress along the path (can reverse for ping-pong). */
	float KeyframeAlpha = 0.0f;
	float KeyframeDirection = 1.0f;
	FName LastScriptAnimation;
	float AccumulatedSpinDegrees = 0.0f;

	/** Message class to emit when the current one-shot move stops (Opened or Closed). */
	FName PendingEndMessage = NAME_None;
	bool bOpeningMove = false;
	bool bTriggerOnceCompleted = false;
	bool bRegisteredWithSubsystem = false;
	float StayOpenRemaining = -1.0f;
};
