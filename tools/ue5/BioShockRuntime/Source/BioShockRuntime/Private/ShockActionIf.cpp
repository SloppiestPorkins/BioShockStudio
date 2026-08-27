#include "ShockActionIf.h"

#include "ShockActionBool.h"

UShockActionIf::UShockActionIf()
{
	ActionClassName = TEXT("ActionIf");
}

void UShockActionIf::AddTest(UShockActionBool* Test)
{
	if (Test)
	{
		TestsOr.Add(Test);
	}
}

void UShockActionIf::AddTrueAction(UShockAction* Action)
{
	if (Action)
	{
		TrueActions.Add(Action);
	}
}

void UShockActionIf::AddElseAction(UShockAction* Action)
{
	if (Action)
	{
		ElseActions.Add(Action);
	}
}

bool UShockActionIf::EvaluateTestsOr(UWorld* World) const
{
	for (const TObjectPtr<UShockActionBool>& Test : TestsOr)
	{
		if (!Test)
		{
			continue;
		}
		if (World ? Test->EvaluateInWorld(World) : Test->EvaluateBool())
		{
			return true;
		}
	}
	return false;
}

FString UShockActionIf::ChooseBranch(UWorld* World)
{
	LastBranch = EvaluateTestsOr(World) ? TEXT("true") : TEXT("else");
	return LastBranch;
}
