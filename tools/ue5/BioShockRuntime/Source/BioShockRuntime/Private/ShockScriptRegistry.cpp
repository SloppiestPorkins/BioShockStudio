#include "ShockScriptRegistry.h"

#include "ShockScriptRunner.h"
#include "ShockScriptSubsystem.h"

void UShockScriptRegistry::RegisterScript(UShockScriptRunner* Script)
{
	if (!Script || Script->ScriptLabel.IsNone())
	{
		return;
	}
	TArray<TObjectPtr<UShockScriptRunner>>& Slot = ByLabel.FindOrAdd(Script->ScriptLabel).Runners;
	Slot.AddUnique(Script);
}

UShockScriptRunner* UShockScriptRegistry::FindScript(FName Label) const
{
	if (Label.IsNone())
	{
		return nullptr;
	}
	if (const FShockRunnerList* Found = ByLabel.Find(Label))
	{
		for (const TObjectPtr<UShockScriptRunner>& Runner : Found->Runners)
		{
			if (Runner)
			{
				return Runner.Get();
			}
		}
	}
	return nullptr;
}

TArray<UShockScriptRunner*> UShockScriptRegistry::FindAllScripts(FName Label) const
{
	TArray<UShockScriptRunner*> Out;
	if (Label.IsNone())
	{
		return Out;
	}
	if (const FShockRunnerList* Found = ByLabel.Find(Label))
	{
		for (const TObjectPtr<UShockScriptRunner>& Runner : Found->Runners)
		{
			if (Runner)
			{
				Out.Add(Runner.Get());
			}
		}
	}
	return Out;
}

TArray<UShockScriptRunner*> UShockScriptRegistry::GetAllRunners() const
{
	TArray<UShockScriptRunner*> Out;
	for (const TPair<FName, FShockRunnerList>& Pair : ByLabel)
	{
		for (const TObjectPtr<UShockScriptRunner>& Runner : Pair.Value.Runners)
		{
			if (Runner)
			{
				Out.Add(Runner.Get());
			}
		}
	}
	return Out;
}

int32 UShockScriptRegistry::Num() const
{
	int32 Total = 0;
	for (const TPair<FName, FShockRunnerList>& Pair : ByLabel)
	{
		Total += Pair.Value.Runners.Num();
	}
	return Total;
}

int32 UShockScriptRegistry::DispatchMessage(FName MessageClassName, const FString& SourceLabel)
{
	return DispatchMessageWithFields(MessageClassName, SourceLabel, TMap<FString, FString>());
}

int32 UShockScriptRegistry::DispatchMessageWithFields(
	FName MessageClassName, const FString& SourceLabel, const TMap<FString, FString>& Fields)
{
	int32 Started = 0;
	for (const TPair<FName, FShockRunnerList>& Pair : ByLabel)
	{
		for (const TObjectPtr<UShockScriptRunner>& RunnerPtr : Pair.Value.Runners)
		{
			UShockScriptRunner* Script = RunnerPtr.Get();
			if (!Script)
			{
				continue;
			}
			if (Script->TryStartFromMessageWithFields(MessageClassName, SourceLabel, Fields))
			{
				++Started;
			}
		}
	}
	// ScriptableMovers listen for MessageTrigger via the owning subsystem (SCR-G01).
	if (UShockScriptSubsystem* Sub = Cast<UShockScriptSubsystem>(GetOuter()))
	{
		Started += Sub->NotifyAnimatedProps(MessageClassName, SourceLabel);
	}
	UE_LOG(LogTemp, Verbose, TEXT("BIOSHOCK_SCRIPT dispatch msg=%s src=%s runners=%d started=%d"),
		*MessageClassName.ToString(), *SourceLabel, Num(), Started);
	return Started;
}
