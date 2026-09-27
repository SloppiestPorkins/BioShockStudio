#include "ShockScriptSubsystem.h"

#include "BaseShockAI.h"
#include "Engine/Engine.h"
#include "Engine/World.h"
#include "GameFramework/Actor.h"
#include "ShockAnimatedProp.h"
#include "ShockGameInstance.h"
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

int32 UShockScriptSubsystem::DispatchMessageLoggedWithFields(
	FName MessageClassName, const FString& SourceLabel, const TMap<FString, FString>& Fields)
{
	UShockScriptRegistry* Reg = GetOrCreateRegistry();
	const int32 Accepted = Reg ? Reg->DispatchMessageWithFields(MessageClassName, SourceLabel, Fields) : 0;
	FString FieldText;
	for (const TPair<FString, FString>& Field : Fields)
	{
		FieldText += FString::Printf(TEXT(" %s=%s"), *Field.Key, *Field.Value);
	}
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_MSG class=%s src=%s accepted=%d%s"),
		*MessageClassName.ToString(), *SourceLabel, Accepted, *FieldText);
	return Accepted;
}

int32 UShockScriptSubsystem::DispatchDoorKeypadUsed(const FString& KeypadLabel, const FString& Keycode)
{
	if (KeypadLabel.IsEmpty())
	{
		return 0;
	}
	TMap<FString, FString> Fields;
	Fields.Add(TEXT("Keycode"), Keycode);
	Fields.Add(TEXT("Instigator"), TEXT("Player"));
	return DispatchMessageLoggedWithFields(FName(TEXT("MessageDoorKeypadUsed")), KeypadLabel, Fields);
}

void UShockScriptSubsystem::RegisterAnimatedProp(AShockAnimatedProp* Prop)
{
	if (Prop)
	{
		RegisteredMovers.AddUnique(Prop);
	}
}

void UShockScriptSubsystem::UnregisterAnimatedProp(AShockAnimatedProp* Prop)
{
	RegisteredMovers.Remove(Prop);
}

int32 UShockScriptSubsystem::NotifyAnimatedProps(FName MessageClassName, const FString& SourceLabel)
{
	int32 Accepted = 0;
	for (int32 i = RegisteredMovers.Num() - 1; i >= 0; --i)
	{
		AShockAnimatedProp* Prop = RegisteredMovers[i].Get();
		if (!IsValid(Prop))
		{
			RegisteredMovers.RemoveAt(i);
			continue;
		}
		if (Prop->HandleTriggerMessage(MessageClassName, SourceLabel))
		{
			++Accepted;
		}
	}
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
		return; // don't consume the pending-restore flag on a repeat call
	}
	// SCR-G11: save restore uses MessageSavegameRestored so _Resume ambient scripts restart;
	// a fresh start still sends MessageLevelStarted.
	bool bSaveRestore = false;
	if (UShockGameInstance* GI = UShockGameInstance::GetShockInstance(GetWorld()))
	{
		bSaveRestore = GI->ConsumePendingSavegameRestore();
	}
	DispatchLevelEntryMessagesMode(bSaveRestore);
}

void UShockScriptSubsystem::DispatchLevelEntryMessagesMode(bool bSaveRestore)
{
	if (bDidLevelEntryDispatch)
	{
		return;
	}
	bDidLevelEntryDispatch = true;

	const FString LevelLabel = ResolveLevelEntryLabel();
	const FName EntryClass = bSaveRestore
		? FName(TEXT("MessageSavegameRestored"))
		: FName(TEXT("MessageLevelStarted"));
	int32 Started = 0;
	if (!LevelLabel.IsEmpty())
	{
		Started += DispatchMessage(EntryClass, LevelLabel);
	}
	// TipUnlock / Present_LevelStartedCheck / etc. author TriggeredBy as All/all.
	Started += DispatchMessage(EntryClass, TEXT("All"));
	Started += DispatchMessage(EntryClass, TEXT("all"));
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_SCRIPT levelEntry class=%s label=%s started=%d"),
		*EntryClass.ToString(), *LevelLabel, Started);
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
