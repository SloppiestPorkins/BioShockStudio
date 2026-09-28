#include "ShockActionEnableWatcher.h"

#include "ShockScript.h"
#include "ShockScriptRegistry.h"
#include "ShockScriptRunner.h"

UShockActionEnableWatcher::UShockActionEnableWatcher()
{
	ActionClassName = TEXT("ActionEnableWatcher");
}

void UShockActionEnableWatcher::Configure(FName InScriptName, FName InWatcherName)
{
	ScriptName = InScriptName;
	WatcherName = InWatcherName;
}

bool UShockActionEnableWatcher::ApplyInWorld(const FShockActionContext& Ctx)
{
	if (WatcherName.IsNone())
	{
		return false;
	}

	UShockScriptRunner* Parent = Cast<UShockScriptRunner>(GetOuter());
	if (!Parent)
	{
		if (AShockScript* Script = Cast<AShockScript>(Ctx.OwnerActor))
		{
			Parent = Script->GetRunner();
		}
	}
	if (!Parent)
	{
		return false;
	}

	UShockScriptRunner* Target = Parent;
	if (!ScriptName.IsNone())
	{
		UShockScriptRegistry* Reg = Parent->Registry;
		Target = Reg ? Reg->FindScript(ScriptName) : nullptr;
		if (!Target)
		{
			return false;
		}
	}
	return Target->SetWatcherEnabled(WatcherName, true, Ctx.WorldTimeSeconds);
}
