#include "ShockAnimatedProp.h"

#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "EngineUtils.h"
#include "ShockScriptReflection.h"
#include "UObject/ConstructorHelpers.h"

AShockAnimatedProp::AShockAnimatedProp()
{
	PrimaryActorTick.bCanEverTick = true;

	PropMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("PropMesh"));
	SetRootComponent(PropMesh);
	PropMesh->SetMobility(EComponentMobility::Movable);
	PropMesh->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	PropMesh->SetCollisionProfileName(TEXT("BlockAll"));
	// Kinematic mover: sweep collisions, do not simulate physics.
	PropMesh->SetSimulatePhysics(false);

	static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeMesh(
		TEXT("/Engine/BasicShapes/Cube.Cube"));
	if (CubeMesh.Succeeded())
	{
		PropMesh->SetStaticMesh(CubeMesh.Object);
		PropMesh->SetRelativeScale3D(FVector(1.0f, 1.0f, 0.2f));
	}
}

void AShockAnimatedProp::BeginPlay()
{
	Super::BeginPlay();
	CaptureRestPose();

	if (MotionMode == EShockAnimatedPropMode::ContinuousSpin && bSpinOnBeginPlay)
	{
		bSpinEnabled = true;
	}
}

void AShockAnimatedProp::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);

	if (MotionMode == EShockAnimatedPropMode::ContinuousSpin)
	{
		TickSpin(DeltaSeconds);
	}
	else if (MotionMode == EShockAnimatedPropMode::KeyframeMove)
	{
		TickKeyframe(DeltaSeconds);
	}
}

void AShockAnimatedProp::CaptureRestPose()
{
	if (!PropMesh)
	{
		return;
	}
	RestRelativeTransform = PropMesh->GetRelativeTransform();
	bRestCaptured = true;

	if (KeyframeRelativeTransforms.Num() == 0)
	{
		KeyframeRelativeTransforms.Add(RestRelativeTransform);
	}
	else
	{
		// Key 0 is always the rest pose captured at begin / configure time.
		KeyframeRelativeTransforms[0] = RestRelativeTransform;
	}
}

void AShockAnimatedProp::ConfigureContinuousSpin(
	FName Label,
	FVector Axis,
	float InRevolutionsPerSecond,
	bool bStartEnabled)
{
	PropLabel = Label;
	MotionMode = EShockAnimatedPropMode::ContinuousSpin;
	SpinAxis = Axis.GetSafeNormal();
	if (SpinAxis.IsNearlyZero())
	{
		SpinAxis = FVector(1.0f, 0.0f, 0.0f);
	}
	RevolutionsPerSecond = InRevolutionsPerSecond;
	SpinRateScale = 1.0f;
	bSpinEnabled = bStartEnabled;
	bSpinOnBeginPlay = bStartEnabled;
	bKeyframeMoving = false;
	CaptureRestPose();
}

void AShockAnimatedProp::ConfigureKeyframeMotion(
	FName Label,
	const TArray<FTransform>& RelativeKeys,
	float InMoveDuration,
	EShockPropLoopMode InLoopMode)
{
	PropLabel = Label;
	MotionMode = EShockAnimatedPropMode::KeyframeMove;
	MoveDuration = FMath::Max(KINDA_SMALL_NUMBER, InMoveDuration);
	MotionRateScale = 1.0f;
	LoopMode = InLoopMode;
	bSpinEnabled = false;
	bKeyframeMoving = false;
	KeyframeAlpha = 0.0f;
	KeyframeDirection = 1.0f;

	CaptureRestPose();
	KeyframeRelativeTransforms.Reset();
	KeyframeRelativeTransforms.Add(RestRelativeTransform);
	for (const FTransform& Key : RelativeKeys)
	{
		// RelativeKeys are offsets from rest (KeyPos/KeyRot), not absolute transforms.
		const FTransform Absolute(
			Key.GetRotation() * RestRelativeTransform.GetRotation(),
			RestRelativeTransform.GetLocation() + Key.GetLocation(),
			RestRelativeTransform.GetScale3D());
		KeyframeRelativeTransforms.Add(Absolute);
	}
	ApplyKeyframeAlpha(0.0f);
}

bool AShockAnimatedProp::PlayScriptedMotion(FName AnimationName, float Rate, bool bLoop)
{
	LastScriptAnimation = AnimationName;
	if (Rate > KINDA_SMALL_NUMBER)
	{
		if (MotionMode == EShockAnimatedPropMode::ContinuousSpin)
		{
			SetSpinRateScale(Rate);
		}
		else
		{
			SetMotionRateScale(Rate);
		}
	}

	if (MotionMode == EShockAnimatedPropMode::ContinuousSpin)
	{
		SetSpinEnabled(true);
		return true;
	}

	// Keyframe path — ensure we are in keyframe mode even if import left defaults.
	MotionMode = EShockAnimatedPropMode::KeyframeMove;
	if (bLoop)
	{
		LoopMode = EShockPropLoopMode::PingPong;
	}

	if (KeyframeRelativeTransforms.Num() < 2)
	{
		return false;
	}

	if (!bKeyframeMoving)
	{
		if (KeyframeAlpha >= static_cast<float>(KeyframeSegmentCount()) - KINDA_SMALL_NUMBER)
		{
			KeyframeDirection = -1.0f;
		}
		else if (KeyframeAlpha <= KINDA_SMALL_NUMBER)
		{
			KeyframeDirection = 1.0f;
		}
		bKeyframeMoving = true;
		return true;
	}

	KeyframeDirection *= -1.0f;
	return true;
}

void AShockAnimatedProp::SetSpinEnabled(bool bEnabled)
{
	bSpinEnabled = bEnabled;
}

void AShockAnimatedProp::SetSpinRateScale(float Scale)
{
	SpinRateScale = FMath::Max(0.0f, Scale);
}

void AShockAnimatedProp::SetMotionRateScale(float Scale)
{
	MotionRateScale = FMath::Max(0.0f, Scale);
}

FVector AShockAnimatedProp::GetMeshRelativeLocation() const
{
	return PropMesh ? PropMesh->GetRelativeLocation() : FVector::ZeroVector;
}

FRotator AShockAnimatedProp::GetMeshRelativeRotation() const
{
	return PropMesh ? PropMesh->GetRelativeRotation() : FRotator::ZeroRotator;
}

void AShockAnimatedProp::AdvanceMotionForVerify(float DeltaSeconds)
{
	Tick(DeltaSeconds);
}

void AShockAnimatedProp::ConfigureSpinForVerify(FName Label, float InRevolutionsPerSecond)
{
	ConfigureContinuousSpin(Label, FVector(0.0f, 0.0f, 1.0f), InRevolutionsPerSecond, true);
}

void AShockAnimatedProp::ConfigureKeyframeForVerify(
	FName Label,
	FVector TargetRelativeLocation,
	float InMoveDuration)
{
	TArray<FTransform> Keys;
	Keys.Add(FTransform(FRotator::ZeroRotator, TargetRelativeLocation));
	ConfigureKeyframeMotion(Label, Keys, InMoveDuration, EShockPropLoopMode::OneShot);
}

AShockAnimatedProp* AShockAnimatedProp::FindByLabel(UWorld* World, FName Label)
{
	if (!World || Label.IsNone())
	{
		return nullptr;
	}
	const FString Want = Label.ToString();
	for (TActorIterator<AShockAnimatedProp> It(World); It; ++It)
	{
		AShockAnimatedProp* Prop = *It;
		if (Prop && ShockScriptReflection::ActorMatchesLabel(Prop, Want))
		{
			return Prop;
		}
	}
	return nullptr;
}

void AShockAnimatedProp::TickSpin(float DeltaSeconds)
{
	if (!bSpinEnabled || DeltaSeconds <= 0.0f)
	{
		return;
	}

	const float DegPerSec = GetEffectiveRevolutionsPerSecond() * 360.0f;
	if (FMath::IsNearlyZero(DegPerSec))
	{
		return;
	}

	FVector Axis = SpinAxis.GetSafeNormal();
	if (Axis.IsNearlyZero())
	{
		Axis = FVector::UpVector;
	}

	const float DeltaDeg = DegPerSec * DeltaSeconds;
	AccumulatedSpinDegrees += DeltaDeg;

	// Spin the actor (root). Relative mesh rotation alone is unreliable for a root
	// component in headless editor worlds; actor rotation is what -game renders.
	const FQuat DeltaQ(Axis, FMath::DegreesToRadians(DeltaDeg));
	SetActorRotation((GetActorQuat() * DeltaQ).GetNormalized());
}

int32 AShockAnimatedProp::KeyframeSegmentCount() const
{
	return FMath::Max(1, KeyframeRelativeTransforms.Num() - 1);
}

void AShockAnimatedProp::ApplyKeyframeAlpha(float Alpha)
{
	if (KeyframeRelativeTransforms.Num() == 0)
	{
		return;
	}

	const int32 Segments = KeyframeSegmentCount();
	const float Clamped = FMath::Clamp(Alpha, 0.0f, static_cast<float>(Segments));
	const int32 SegmentIndex = FMath::Min(Segments - 1, FMath::FloorToInt(Clamped));
	const float LocalT = Clamped - static_cast<float>(SegmentIndex);

	const FTransform& From = KeyframeRelativeTransforms[SegmentIndex];
	const FTransform& To = KeyframeRelativeTransforms[
		FMath::Min(SegmentIndex + 1, KeyframeRelativeTransforms.Num() - 1)];
	const FVector NewLoc = FMath::Lerp(From.GetLocation(), To.GetLocation(), LocalT);
	const FQuat NewRot = FQuat::Slerp(From.GetRotation(), To.GetRotation(), LocalT);

	// Root relative == world when unattached; sweep so movers push/block.
	FHitResult Hit;
	SetActorLocationAndRotation(NewLoc, NewRot.Rotator(), true, &Hit, ETeleportType::None);
}

void AShockAnimatedProp::TickKeyframe(float DeltaSeconds)
{
	if (!bKeyframeMoving || DeltaSeconds <= 0.0f)
	{
		return;
	}

	const int32 Segments = KeyframeSegmentCount();
	const float Duration = FMath::Max(KINDA_SMALL_NUMBER, MoveDuration);
	const float Rate = FMath::Max(0.0f, MotionRateScale);
	const float Step = (DeltaSeconds / Duration) * Rate;
	KeyframeAlpha += Step * KeyframeDirection;

	const float MaxAlpha = static_cast<float>(Segments);

	if (KeyframeAlpha >= MaxAlpha)
	{
		switch (LoopMode)
		{
		case EShockPropLoopMode::PingPong:
			KeyframeAlpha = MaxAlpha;
			KeyframeDirection = -1.0f;
			break;
		case EShockPropLoopMode::Loop:
			KeyframeAlpha = FMath::Fmod(KeyframeAlpha, MaxAlpha);
			break;
		default:
			KeyframeAlpha = MaxAlpha;
			bKeyframeMoving = false;
			break;
		}
	}
	else if (KeyframeAlpha <= 0.0f)
	{
		switch (LoopMode)
		{
		case EShockPropLoopMode::PingPong:
			KeyframeAlpha = 0.0f;
			KeyframeDirection = 1.0f;
			break;
		case EShockPropLoopMode::Loop:
			KeyframeAlpha = MaxAlpha;
			break;
		default:
			KeyframeAlpha = 0.0f;
			bKeyframeMoving = false;
			break;
		}
	}

	ApplyKeyframeAlpha(KeyframeAlpha);
}
