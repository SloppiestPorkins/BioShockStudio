#include "ShockActionStartTimer.h"

#include "ShockScript.h"
#include "ShockScriptRunner.h"

UShockActionStartTimer::UShockActionStartTimer()
{
	ActionClassName = TEXT("ActionStartTimer");
}

void UShockActionStartTimer::Configure(float InSeconds)
{
	Seconds = InSeconds;
}

bool UShockActionStartTimer::RequestStart()
{
	if (Seconds <= 0.0f)
	{
		return false;
	}
	LastSeconds = Seconds;
	return true;
}

static UShockScriptRunner* ResolveOwningRunner(const FShockActionContext& Ctx, UShockAction* Self)
{
	if (UShockScriptRunner* OuterRunner = Self ? Self->GetTypedOuter<UShockScriptRunner>() : nullptr)
	{
		return OuterRunner;
	}
	if (AShockScript* Script = Ctx.OwnerActor ? Cast<AShockScript>(Ctx.OwnerActor) : nullptr)
	{
		return Script->GetRunner();
	}
	return nullptr;
}

int32 UShockActionStartTimer::ApplyInWorld(UWorld* World)
{
	(void)World;
	// Prefer the context overload (needs WorldTimeSeconds on the running script).
	return 0;
}

bool UShockActionStartTimer::ApplyInWorld(const FShockActionContext& Ctx)
{
	if (!RequestStart())
	{
		return false;
	}
	UShockScriptRunner* Runner = ResolveOwningRunner(Ctx, this);
	if (!Runner)
	{
		return false;
	}
	Runner->StartScriptTimer(Seconds, Ctx.WorldTimeSeconds);
	return true;
}
