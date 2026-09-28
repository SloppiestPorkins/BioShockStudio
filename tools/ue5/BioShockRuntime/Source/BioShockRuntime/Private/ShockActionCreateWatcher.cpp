#include "ShockActionCreateWatcher.h"

#include "ShockActionBool.h"
#include "ShockScript.h"
#include "ShockScriptRunner.h"

UShockActionCreateWatcher::UShockActionCreateWatcher()
{
	ActionClassName = TEXT("ActionCreateWatcher");
}

void UShockActionCreateWatcher::Configure(FName InWatcherName, UShockActionBool* InExpression, bool bInEnabled)
{
	WatcherName = InWatcherName;
	WatchedExpression = InExpression;
	bWatcherEnabled = bInEnabled;
}

void UShockActionCreateWatcher::SetWatchedExpression(UShockActionBool* InExpression)
{
	WatchedExpression = InExpression;
}

bool UShockActionCreateWatcher::ApplyInWorld(const FShockActionContext& Ctx)
{
	if (WatcherName.IsNone() || !WatchedExpression)
	{
		return false;
	}

	UShockScriptRunner* Runner = Cast<UShockScriptRunner>(GetOuter());
	if (!Runner)
	{
		if (AShockScript* Script = Cast<AShockScript>(Ctx.OwnerActor))
		{
			Runner = Script->GetRunner();
		}
	}
	if (!Runner)
	{
		return false;
	}

	// UC ActionCreateWatcher: only add + enter LookAtExpression when the watcher starts enabled.
	if (!bWatcherEnabled)
	{
		Runner->AddWatcher(WatcherName, WatchedExpression, false, Ctx.WorldTimeSeconds);
		return true;
	}
	Runner->AddWatcher(WatcherName, WatchedExpression, true, Ctx.WorldTimeSeconds);
	return true;
}
