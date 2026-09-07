#include "ShockViewHandsAnimInstance.h"

#include "Animation/AnimSequence.h"
#include "Animation/AnimationPoseData.h"
#include "AnimationRuntime.h"

void FShockViewHandsProxy::PreUpdate(UAnimInstance* InAnimInstance, float DeltaSeconds)
{
	FAnimInstanceProxy::PreUpdate(InAnimInstance, DeltaSeconds);

	UShockViewHandsAnimInstance* Inst = Cast<UShockViewHandsAnimInstance>(InAnimInstance);
	if (!Inst)
	{
		return;
	}

	if (Inst->PlayToken != LastSeenPlayToken)
	{
		LastSeenPlayToken = Inst->PlayToken;
		PrevClip = CurClip;
		PrevTime = CurTime;
		CurClip = Inst->PendingClip;
		bCurLoop = Inst->bPendingLoop;
		BlendDuration = FMath::Max(0.0f, Inst->PendingBlend);
		CurTime = 0.0f;
		BlendAlpha = (PrevClip && BlendDuration > KINDA_SMALL_NUMBER) ? 0.0f : 1.0f;
	}

	Inst->CachedCurTime = CurTime;
}

void FShockViewHandsProxy::Update(float DeltaSeconds)
{
	FAnimInstanceProxy::Update(DeltaSeconds);

	if (CurClip)
	{
		CurTime += DeltaSeconds;
		const float Len = CurClip->GetPlayLength();
		if (bCurLoop && Len > KINDA_SMALL_NUMBER)
		{
			CurTime = FMath::Fmod(CurTime, Len);
		}
		else
		{
			CurTime = FMath::Min(CurTime, Len);
		}
	}

	if (PrevClip)
	{
		PrevTime = FMath::Min(PrevTime + DeltaSeconds, PrevClip->GetPlayLength());
	}

	if (BlendAlpha < 1.0f && BlendDuration > KINDA_SMALL_NUMBER)
	{
		BlendAlpha = FMath::Min(1.0f, BlendAlpha + DeltaSeconds / BlendDuration);
		if (BlendAlpha >= 1.0f)
		{
			PrevClip = nullptr;
		}
	}
}

bool FShockViewHandsProxy::Evaluate(FPoseContext& Output)
{
	if (!CurClip)
	{
		Output.ResetToRefPose();
		return true;
	}

	const bool bBlending = (BlendAlpha < 1.0f) && (PrevClip != nullptr);

	if (!bBlending)
	{
		FAnimationPoseData OutData(Output);
		CurClip->GetAnimationPose(
			OutData, FAnimExtractContext(static_cast<double>(CurTime), false, FDeltaTimeRecord(), bCurLoop));
		return true;
	}

	FPoseContext CurCtx(Output);
	{
		FAnimationPoseData D(CurCtx);
		CurClip->GetAnimationPose(
			D, FAnimExtractContext(static_cast<double>(CurTime), false, FDeltaTimeRecord(), bCurLoop));
	}

	FPoseContext PrevCtx(Output);
	{
		FAnimationPoseData D(PrevCtx);
		PrevClip->GetAnimationPose(
			D, FAnimExtractContext(static_cast<double>(PrevTime), false, FDeltaTimeRecord(), false));
	}

	FAnimationPoseData PrevData(PrevCtx);
	FAnimationPoseData CurData(CurCtx);
	FAnimationPoseData OutData(Output);
	// WeightOfPoseOne applies to the first arg — feed PrevClip first with weight (1 - alpha).
	FAnimationRuntime::BlendTwoPosesTogether(PrevData, CurData, 1.0f - BlendAlpha, OutData);
	return true;
}

void FShockViewHandsProxy::AddReferencedObjects(UAnimInstance* InAnimInstance, FReferenceCollector& Collector)
{
	FAnimInstanceProxy::AddReferencedObjects(InAnimInstance, Collector);
	Collector.AddReferencedObject(CurClip);
	Collector.AddReferencedObject(PrevClip);
}

void UShockViewHandsAnimInstance::PlayClip(UAnimSequence* Sequence, bool bLoop, float BlendTime)
{
	if (!Sequence)
	{
		return;
	}
	PendingPrevClip = PendingClip;
	PendingClip = Sequence;
	bPendingLoop = bLoop;
	PendingBlend = FMath::Max(0.0f, BlendTime);
	++PlayToken;
}

float UShockViewHandsAnimInstance::GetPlayingClipRemaining() const
{
	if (!PendingClip || bPendingLoop)
	{
		return 0.0f;
	}
	return FMath::Max(0.0f, PendingClip->GetPlayLength() - CachedCurTime);
}
