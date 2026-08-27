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
