#include "ShockActionPropertyTest.h"

#include "EngineUtils.h"
#include "GameFramework/Actor.h"

UShockActionPropertyTest::UShockActionPropertyTest()
{
	ActionClassName = TEXT("ActionPropertyTest");
	OpTest = 2;
	MaxPasses = -1;
}

void UShockActionPropertyTest::Configure(
	FName InLabel, const FString& InPropertyPath, const FString& InValue, int32 InOpTest, int32 InMaxPasses)
{
	Label = InLabel;
	PropertyPath = InPropertyPath;
	Value = InValue;
	OpTest = InOpTest;
	MaxPasses = InMaxPasses;
}

bool UShockActionPropertyTest::EvaluateBool() const
{
	// Needs a World to resolve Label — use EvaluateInWorld from the runner/If.
	return false;
}

static bool ComparePropertyStrings(int32 OpTest, const FString& Left, const FString& Right)
{
	float LeftNum = 0.0f;
	float RightNum = 0.0f;
	const bool bBothNumeric = Left.IsNumeric() && Right.IsNumeric();
	if (bBothNumeric)
	{
		LeftNum = FCString::Atof(*Left);
		RightNum = FCString::Atof(*Right);
	}

	switch (OpTest)
	{
	case 0: // Less
		return bBothNumeric ? (LeftNum < RightNum) : (Left < Right);
	case 1: // LessEqual
		return bBothNumeric ? (LeftNum <= RightNum) : (Left <= Right);
	case 2: // Equals
		return Left.Equals(Right, ESearchCase::CaseSensitive);
	case 3: // NotEqual
		return !Left.Equals(Right, ESearchCase::CaseSensitive);
	case 4: // GreaterEqual
		return bBothNumeric ? (LeftNum >= RightNum) : (Left >= Right);
	case 5: // Greater
		return bBothNumeric ? (LeftNum > RightNum) : (Left > Right);
	default:
		return false;
	}
}

bool UShockActionPropertyTest::EvaluateInWorld(UWorld* World) const
{
	if (!World || Label.IsNone())
	{
		return false;
	}

	const FString Path = PropertyPath.IsEmpty() ? TEXT("Label") : PropertyPath;
	const bool bIsLabelPath = Path.Equals(TEXT("Label"), ESearchCase::IgnoreCase)
		|| Path.Equals(TEXT("ActorLabel"), ESearchCase::IgnoreCase);
	if (!bIsLabelPath)
	{
		return false;
	}

	const FString WantLabel = Label.ToString();
	for (TActorIterator<AActor> It(World); It; ++It)
	{
		AActor* Actor = *It;
		if (!Actor)
		{
			continue;
		}
#if WITH_EDITOR
		if (!Actor->GetActorLabel().Equals(WantLabel, ESearchCase::CaseSensitive))
		{
			continue;
		}
		return ComparePropertyStrings(OpTest, Actor->GetActorLabel(), Value);
#else
		(void)Actor;
		return false;
#endif
	}
	return false;
}
