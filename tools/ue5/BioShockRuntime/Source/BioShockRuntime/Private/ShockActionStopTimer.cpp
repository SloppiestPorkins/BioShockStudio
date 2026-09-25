#include "ShockActionStopTimer.h"

#include "ShockScript.h"
#include "ShockScriptRegistry.h"
#include "ShockScriptRunner.h"

UShockActionStopTimer::UShockActionStopTimer()
{
	ActionClassName = TEXT("ActionStopTimer");
}

void UShockActionStopTimer::Configure(FName InScriptLabel)
{
	ScriptLabel = InScriptLabel;
}

bool UShockActionStopTimer::RequestStop()
{
	if (ScriptLabel.IsNone())
	{
		return false;
	}
	LastScriptLabel = ScriptLabel;
	return true;
}

int32 UShockActionStopTimer::ApplyInWorld(UWorld* World)
{
	(void)World;
	return 0;
}

bool UShockActionStopTimer::ApplyInWorld(const FShockActionContext& Ctx)
{
	if (!RequestStop())
	{
		return false;
	}
	UShockScriptRegistry* Registry = nullptr;
	if (UShockScriptRunner* Self = GetTypedOuter<UShockScriptRunner>())
	{
		Registry = Self->Registry;
	}
	else if (AShockScript* Script = Ctx.OwnerActor ? Cast<AShockScript>(Ctx.OwnerActor) : nullptr)
	{
		Registry = Script->GetRegistry();
	}
	if (!Registry)
	{
		return false;
	}
	int32 Stopped = 0;
	for (UShockScriptRunner* Target : Registry->FindAllScripts(ScriptLabel))
	{
		if (Target)
		{
			Target->StopScriptTimer();
			++Stopped;
		}
	}
	return Stopped > 0;
}
