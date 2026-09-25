#include "ShockScriptRegistry.h"

#include "ShockScriptRunner.h"

void UShockScriptRegistry::RegisterScript(UShockScriptRunner* Script)
{
	if (!Script || Script->ScriptLabel.IsNone())
	{
		return;
	}
	ByLabel.Add(Script->ScriptLabel, Script);
}

UShockScriptRunner* UShockScriptRegistry::FindScript(FName Label) const
{
	if (Label.IsNone())
	{
		return nullptr;
	}
	if (const TObjectPtr<UShockScriptRunner>* Found = ByLabel.Find(Label))
	{
		return Found->Get();
	}
	return nullptr;
}

int32 UShockScriptRegistry::DispatchMessage(FName MessageClassName, const FString& SourceLabel)
{
	return DispatchMessageWithFields(MessageClassName, SourceLabel, TMap<FString, FString>());
}

int32 UShockScriptRegistry::DispatchMessageWithFields(
	FName MessageClassName, const FString& SourceLabel, const TMap<FString, FString>& Fields)
{
	int32 Started = 0;
	for (const TPair<FName, TObjectPtr<UShockScriptRunner>>& Pair : ByLabel)
	{
		UShockScriptRunner* Script = Pair.Value.Get();
		if (!Script)
		{
			continue;
		}
		if (Script->TryStartFromMessageWithFields(MessageClassName, SourceLabel, Fields))
		{
			++Started;
		}
	}
	UE_LOG(LogTemp, Verbose, TEXT("BIOSHOCK_SCRIPT dispatch msg=%s src=%s runners=%d started=%d"),
		*MessageClassName.ToString(), *SourceLabel, ByLabel.Num(), Started);
	return Started;
}
