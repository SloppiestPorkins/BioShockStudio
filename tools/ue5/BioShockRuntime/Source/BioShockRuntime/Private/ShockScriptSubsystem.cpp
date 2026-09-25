#include "ShockScriptSubsystem.h"

#include "BaseShockAI.h"
#include "Engine/Engine.h"
#include "Engine/World.h"
#include "GameFramework/Actor.h"
#include "ShockPlayer.h"
#include "ShockScriptRegistry.h"
#include "ShockSecurityDevice.h"
#include "TimerManager.h"

UShockScriptSubsystem* UShockScriptSubsystem::Get(const UWorld* World)
{
	return World ? World->GetSubsystem<UShockScriptSubsystem>() : nullptr;
}

UShockScriptSubsystem* UShockScriptSubsystem::GetForWorld(UObject* WorldContextObject)
{
	if (!GEngine || !WorldContextObject)
	{
		return nullptr;
	}
	UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::ReturnNull);
	return Get(World);
}

UShockScriptRegistry* UShockScriptSubsystem::GetRegistryForWorld(UObject* WorldContextObject)
{
	if (UShockScriptSubsystem* Sub = GetForWorld(WorldContextObject))
	{
		return Sub->GetOrCreateRegistry();
	}
	return nullptr;
}

UShockScriptRegistry* UShockScriptSubsystem::GetOrCreateRegistry()
{
	if (!Registry)
	{
		Registry = NewObject<UShockScriptRegistry>(this, TEXT("ScriptRegistry"));
	}
	return Registry;
}

int32 UShockScriptSubsystem::DispatchMessage(FName MessageClassName, const FString& SourceLabel)
{
	UShockScriptRegistry* Reg = GetOrCreateRegistry();
	return Reg ? Reg->DispatchMessage(MessageClassName, SourceLabel) : 0;
}

int32 UShockScriptSubsystem::DispatchMessageLogged(FName MessageClassName, const FString& SourceLabel)
{
	const int32 Accepted = DispatchMessage(MessageClassName, SourceLabel);
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_MSG class=%s src=%s accepted=%d"),
		*MessageClassName.ToString(), *SourceLabel, Accepted);
	return Accepted;
}

FString UShockScriptSubsystem::ResolveMessageSourceLabel(const AActor* Actor)
{
	if (!Actor)
	{
		return FString();
	}
	if (Cast<AShockPlayer>(Actor))
	{
		// MatchesTriggeredBy is case-insensitive; Medical scripts author both "Player" and "player".
		return TEXT("Player");
	}
	if (const ABaseShockAI* AI = Cast<ABaseShockAI>(Actor))
	{
		if (!AI->GetScriptLabel().IsNone())
		{
			return AI->GetScriptLabel().ToString();
		}
	}
	if (const AShockSecurityDevice* Device = Cast<AShockSecurityDevice>(Actor))
	{
		if (!Device->DeviceLabel.IsNone())
		{
			return Device->DeviceLabel.ToString();
		}
	}
#if WITH_EDITOR
	const FString EditorLabel = Actor->GetActorLabel();
	if (!EditorLabel.IsEmpty())
	{
		return EditorLabel;
	}
#endif
	return Actor->GetName();
}

FString UShockScriptSubsystem::ResolveLevelEntryLabel() const
{
	const UWorld* World = GetWorld();
	if (!World)
	{
		return FString();
	}
	// GetMapName() is often "UEDPIE_0_1-Medical" in PIE — strip play-in-editor prefix.
	FString MapName = World->GetMapName();
	if (MapName.StartsWith(TEXT("UEDPIE_")))
	{
		const int32 First = MapName.Find(TEXT("_"));
		const int32 Second = (First == INDEX_NONE)
			? INDEX_NONE
			: MapName.Find(TEXT("_"), ESearchCase::CaseSensitive, ESearchDir::FromStart, First + 1);
		if (Second != INDEX_NONE && Second + 1 < MapName.Len())
		{
			MapName = MapName.Mid(Second + 1);
		}
	}
	return MapName;
}

void UShockScriptSubsystem::DispatchLevelEntryMessages()
{
	if (bDidLevelEntryDispatch)
	{
		return;
	}
	bDidLevelEntryDispatch = true;

	const FString LevelLabel = ResolveLevelEntryLabel();
	// UE2's real class for level entry, confirmed against the shipped UnrealEd guide ("Level
	// start" pattern: TriggeredBy="<map name>", scriptMessageClass=MessageLevelStarted). Not yet
	// checked receiver-side (see docs/research/message-class-gap.md) but the dispatched name
	// should be the real one.
	const FName MessageLevelStarted(TEXT("MessageLevelStarted"));
	int32 Started = 0;
	if (!LevelLabel.IsEmpty())
	{
		Started += DispatchMessage(MessageLevelStarted, LevelLabel);
	}
	// TipUnlock / Present_LevelStartedCheck / etc. author TriggeredBy as All/all.
	Started += DispatchMessage(MessageLevelStarted, TEXT("All"));
	Started += DispatchMessage(MessageLevelStarted, TEXT("all"));
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_SCRIPT levelEntry label=%s started=%d"),
		*LevelLabel, Started);
}

void UShockScriptSubsystem::OnWorldBeginPlay(UWorld& InWorld)
{
	Super::OnWorldBeginPlay(InWorld);
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_SCRIPT OnWorldBeginPlay world=%s"), *InWorld.GetName());
	// Actors BeginPlay (script RegisterScript) may still be in flight — defer one tick.
	if (UWorld* World = GetWorld())
	{
		World->GetTimerManager().SetTimerForNextTick([this]()
		{
			DispatchLevelEntryMessages();
		});
	}
}
