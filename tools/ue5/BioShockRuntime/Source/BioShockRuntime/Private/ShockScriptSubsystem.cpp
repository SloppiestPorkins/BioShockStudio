#include "ShockScriptSubsystem.h"

#include "Engine/Engine.h"
#include "Engine/World.h"
#include "ShockScriptRegistry.h"
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
	const FName MessageTrigger(TEXT("MessageTrigger"));
	if (!LevelLabel.IsEmpty())
	{
		DispatchMessage(MessageTrigger, LevelLabel);
	}
	// TipUnlock / Present_LevelStartedCheck / etc. author TriggeredBy as All/all.
	DispatchMessage(MessageTrigger, TEXT("All"));
	DispatchMessage(MessageTrigger, TEXT("all"));
}

void UShockScriptSubsystem::OnWorldBeginPlay(UWorld& InWorld)
{
	Super::OnWorldBeginPlay(InWorld);
	// Actors BeginPlay (script RegisterScript) may still be in flight — defer one tick.
	if (UWorld* World = GetWorld())
	{
		World->GetTimerManager().SetTimerForNextTick([this]()
		{
			DispatchLevelEntryMessages();
		});
	}
}
