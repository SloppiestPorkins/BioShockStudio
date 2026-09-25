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

void UShockTriggerRelayComponent::ConfigureMessages(FName InEnterMessageClass, FName InExitMessageClass)
{
	EnterMessageClass = InEnterMessageClass;
	ExitMessageClass = InExitMessageClass;
}

UShockTriggerRelayComponent* UShockTriggerRelayComponent::InstallOnActor(
	AActor* Owner,
	const FString& InLabel,
	bool bInTriggerOnlyOnce,
	bool bInDisabled,
	FName InEnterMessageClass,
	FName InExitMessageClass)
{
	if (!Owner)
	{
		return nullptr;
	}

	UShockTriggerRelayComponent* Existing = Owner->FindComponentByClass<UShockTriggerRelayComponent>();
	if (Existing)
	{
		Existing->Configure(InLabel, bInTriggerOnlyOnce, bInDisabled);
		Existing->ConfigureMessages(InEnterMessageClass, InExitMessageClass);
		return Existing;
	}

	UShockTriggerRelayComponent* Comp = NewObject<UShockTriggerRelayComponent>(Owner, TEXT("ShockTriggerRelay"));
	Comp->Configure(InLabel, bInTriggerOnlyOnce, bInDisabled);
	Comp->ConfigureMessages(InEnterMessageClass, InExitMessageClass);
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
		Prim->OnComponentEndOverlap.RemoveDynamic(this, &UShockTriggerRelayComponent::OnEndOverlap);
		Prim->OnComponentEndOverlap.AddDynamic(this, &UShockTriggerRelayComponent::OnEndOverlap);
		bBound = true;
		break;
	}
}

int32 UShockTriggerRelayComponent::DispatchNow(FName MessageClass)
{
	if (bDisabled || MessageClass.IsNone())
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

	// The relay only ever reports the player (bPlayerOnly), so the message's Instigator is Player --
	// what scripts authored with messageFilter Instigator=Player compare against.
	TMap<FString, FString> Fields;
	if (bPlayerOnly)
	{
		Fields.Add(TEXT("Instigator"), TEXT("Player"));
	}
	return Sub->DispatchMessageLoggedWithFields(MessageClass, VolumeLabel, Fields);
}

int32 UShockTriggerRelayComponent::FireForVerify()
{
	if (bTriggerOnlyOnce && bHasFired)
	{
		return 0;
	}
	const int32 Accepted = DispatchNow(EnterMessageClass);
	bHasFired = true;
	return Accepted;
}

int32 UShockTriggerRelayComponent::FireExitForVerify()
{
	return DispatchNow(ExitMessageClass);
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
	if (bTriggerOnlyOnce && bHasFired)
	{
		return;
	}
	DispatchNow(EnterMessageClass);
	bHasFired = true;
}

void UShockTriggerRelayComponent::OnEndOverlap(
	UPrimitiveComponent* OverlappedComponent,
	AActor* OtherActor,
	UPrimitiveComponent* OtherComp,
	int32 OtherBodyIndex)
{
	(void)OverlappedComponent;
	(void)OtherComp;
	(void)OtherBodyIndex;

	if (bPlayerOnly && !Cast<AShockPlayer>(OtherActor))
	{
		return;
	}
	DispatchNow(ExitMessageClass);
}
