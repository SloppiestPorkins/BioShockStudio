#include "ShockTriggerRelayComponent.h"

#include "Components/PrimitiveComponent.h"
#include "Engine/World.h"
#include "GameFramework/Actor.h"
#include "ShockPlayer.h"
#include "ShockScriptSubsystem.h"

UShockTriggerRelayComponent::UShockTriggerRelayComponent()
{
	PrimaryComponentTick.bCanEverTick = false;
}

void UShockTriggerRelayComponent::Configure(const FString& InLabel, bool bInTriggerOnlyOnce, bool bInDisabled)
{
	VolumeLabel = InLabel;
	bTriggerOnlyOnce = bInTriggerOnlyOnce;
	bDisabled = bInDisabled;
}

UShockTriggerRelayComponent* UShockTriggerRelayComponent::InstallOnActor(
	AActor* Owner,
	const FString& InLabel,
	bool bInTriggerOnlyOnce,
	bool bInDisabled)
{
	if (!Owner)
	{
		return nullptr;
	}

	UShockTriggerRelayComponent* Existing = Owner->FindComponentByClass<UShockTriggerRelayComponent>();
	if (Existing)
	{
		Existing->Configure(InLabel, bInTriggerOnlyOnce, bInDisabled);
		return Existing;
	}

	UShockTriggerRelayComponent* Comp = NewObject<UShockTriggerRelayComponent>(Owner, TEXT("ShockTriggerRelay"));
	Comp->Configure(InLabel, bInTriggerOnlyOnce, bInDisabled);
	Owner->AddInstanceComponent(Comp);
	Comp->RegisterComponent();
	// Overlap binding is a play-time concern — done in BeginPlay, not here (editor time), so a
	// saved-then-loaded map does not end up double-bound.
	return Comp;
}

void UShockTriggerRelayComponent::BeginPlay()
{
	Super::BeginPlay();
	if (VolumeLabel.IsEmpty())
	{
#if WITH_EDITOR
		VolumeLabel = GetOwner() ? GetOwner()->GetActorLabel() : FString();
#else
		VolumeLabel = GetOwner() ? GetOwner()->GetName() : FString();
#endif
	}
	BindOverlap();
}

void UShockTriggerRelayComponent::BindOverlap()
{
	AActor* Owner = GetOwner();
	if (!Owner)
	{
		return;
	}

	TArray<UPrimitiveComponent*> Prims;
	Owner->GetComponents<UPrimitiveComponent>(Prims);
	for (UPrimitiveComponent* Prim : Prims)
	{
		if (!Prim)
		{
			continue;
		}
		Prim->SetGenerateOverlapEvents(true);
		// Remove-then-add so a re-bind (or a stray serialized binding) can't double up.
		Prim->OnComponentBeginOverlap.RemoveDynamic(this, &UShockTriggerRelayComponent::OnBeginOverlap);
		Prim->OnComponentBeginOverlap.AddDynamic(this, &UShockTriggerRelayComponent::OnBeginOverlap);
		bBound = true;
		break;
	}
}

int32 UShockTriggerRelayComponent::DispatchNow()
{
	if (bDisabled)
	{
		return 0;
	}
	if (bTriggerOnlyOnce && bHasFired)
	{
		return 0;
	}
	if (VolumeLabel.IsEmpty())
	{
		return 0;
	}

	UWorld* World = GetWorld();
	if (!World)
	{
		if (AActor* Owner = GetOwner())
		{
			World = Owner->GetWorld();
		}
	}
	UShockScriptSubsystem* Sub = UShockScriptSubsystem::Get(World);
	if (!Sub)
	{
		return 0;
	}

	// UE2's real class for a TriggerVolume enter, confirmed against the shipped UnrealEd guide.
	// Not yet checked receiver-side (see docs/research/message-class-gap.md) but the dispatched
	// name should be the real one.
	const int32 Accepted = Sub->DispatchMessage(FName(TEXT("MessageTriggerVolumeEnter")), VolumeLabel);
	bHasFired = true;
	return Accepted;
}

int32 UShockTriggerRelayComponent::FireForVerify()
{
	return DispatchNow();
}

void UShockTriggerRelayComponent::OnBeginOverlap(
	UPrimitiveComponent* OverlappedComponent,
	AActor* OtherActor,
	UPrimitiveComponent* OtherComp,
	int32 OtherBodyIndex,
	bool bFromSweep,
	const FHitResult& SweepResult)
{
	(void)OverlappedComponent;
	(void)OtherComp;
	(void)OtherBodyIndex;
	(void)bFromSweep;
	(void)SweepResult;

	if (bPlayerOnly && !Cast<AShockPlayer>(OtherActor))
	{
		return;
	}
	DispatchNow();
}
