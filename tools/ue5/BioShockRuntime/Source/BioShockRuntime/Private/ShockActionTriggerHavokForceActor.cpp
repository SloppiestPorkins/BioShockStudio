#include "ShockActionTriggerHavokForceActor.h"

#include "ShockPhysicsLibrary.h"

namespace
{
// PLAUSIBLE stand-in for decoded Havok force-field assets (licence-blocked).
constexpr float DefaultForceRadius = 300.0f;
constexpr float DefaultForceStrength = 50000.0f;
} // namespace

UShockActionTriggerHavokForceActor::UShockActionTriggerHavokForceActor()
{
	ActionClassName = TEXT("ActionTriggerHavokForceActor");
}

void UShockActionTriggerHavokForceActor::Configure(FName InTarget)
{
	TargetLabel = InTarget;
}

bool UShockActionTriggerHavokForceActor::RequestTrigger()
{
	if (TargetLabel.IsNone())
	{
		return false;
	}
	LastTargetLabel = TargetLabel;
	return true;
}

int32 UShockActionTriggerHavokForceActor::ApplyInWorld(UWorld* World)
{
	if (!RequestTrigger() || !World)
	{
		return 0;
	}
	if (!UShockPhysicsLibrary::IsHavokForceActorEnabled(TargetLabel))
	{
		return 0;
	}
	AActor* ForceActor = UShockPhysicsLibrary::FindActorByLabel(World, TargetLabel);
	if (!ForceActor)
	{
		return 0;
	}
	return UShockPhysicsLibrary::ApplyRadialImpulse(
		World,
		ForceActor->GetActorLocation(),
		DefaultForceRadius,
		DefaultForceStrength,
		true);
}

bool UShockActionTriggerHavokForceActor::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
