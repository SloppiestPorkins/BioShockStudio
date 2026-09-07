#pragma once

#include "CoreMinimal.h"
#include "Animation/AnimInstance.h"
#include "Animation/AnimInstanceProxy.h"
#include "ShockViewHandsAnimInstance.generated.h"

class UAnimSequence;

/**
 * Minimal native anim instance for the first-person ViewHands mesh: plays one clip at a time and
 * crossfades from the previous clip over a short blend so equip / fire / reload / swing / fidget
 * transitions are smooth instead of the hard cut UAnimSingleNodeInstance gives.
 *
 * All playback lives in FShockViewHandsProxy (worker thread). The game thread only stages the
 * next clip via PlayClip(); PreUpdate copies that across under a play token.
 */
USTRUCT()
struct FShockViewHandsProxy : public FAnimInstanceProxy
{
	GENERATED_BODY()

	FShockViewHandsProxy() = default;
	explicit FShockViewHandsProxy(UAnimInstance* InInstance) : FAnimInstanceProxy(InInstance) {}

	virtual void PreUpdate(UAnimInstance* InAnimInstance, float DeltaSeconds) override;
	virtual void Update(float DeltaSeconds) override;
	virtual bool Evaluate(FPoseContext& Output) override;
	virtual void AddReferencedObjects(UAnimInstance* InAnimInstance, FReferenceCollector& Collector) override;

	/** Position (seconds) of the clip that is fully faded in — for the one-shot completion check. */
	float GetCurrentTime() const { return CurTime; }
	const UAnimSequence* GetCurrentClip() const { return CurClip; }

	// Copied from the instance in PreUpdate.
	TObjectPtr<UAnimSequence> CurClip = nullptr;
	TObjectPtr<UAnimSequence> PrevClip = nullptr;
	bool bCurLoop = false;
	float BlendDuration = 0.1f;
	uint32 LastSeenPlayToken = 0;

	// Proxy-owned playback state.
	float CurTime = 0.0f;
	float PrevTime = 0.0f;
	float BlendAlpha = 1.0f; // 0 = fully PrevClip, 1 = fully CurClip
};

UCLASS()
class BIOSHOCKRUNTIME_API UShockViewHandsAnimInstance : public UAnimInstance
{
	GENERATED_BODY()

public:
	/** Stage a clip. Crossfades from whatever is playing over BlendTime seconds. */
	void PlayClip(UAnimSequence* Sequence, bool bLoop, float BlendTime = 0.08f);

	UAnimSequence* GetPlayingClip() const { return PendingClip; }
	bool IsPlayingClip(const UAnimSequence* Sequence) const { return PendingClip == Sequence; }

	/** Seconds left on the current non-looping clip (0 for looping / none). Read from the proxy. */
	float GetPlayingClipRemaining() const;

protected:
	virtual FAnimInstanceProxy* CreateAnimInstanceProxy() override { return new FShockViewHandsProxy(this); }
	virtual void DestroyAnimInstanceProxy(FAnimInstanceProxy* InProxy) override { delete InProxy; }

private:
	friend struct FShockViewHandsProxy;

	UPROPERTY(Transient)
	TObjectPtr<UAnimSequence> PendingClip = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UAnimSequence> PendingPrevClip = nullptr;

	bool bPendingLoop = false;
	float PendingBlend = 0.08f;
	uint32 PlayToken = 0;

	// Mirrored back from the proxy each PreUpdate for GetPlayingClipRemaining().
	float CachedCurTime = 0.0f;
};
