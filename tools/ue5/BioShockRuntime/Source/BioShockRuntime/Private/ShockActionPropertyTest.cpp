#include "ShockActionPropertyTest.h"

#include "EngineUtils.h"
#include "GameFramework/Actor.h"
#include "ShockScriptReflection.h"
#include "ShockVariable.h"

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
		// Numeric compare when both sides parse as numbers — a reflected float property exports
		// as "12.500000" (ExportTextItem_Direct's default precision) and a script value of "12.5"
		// must still compare equal; a bare string compare false-negatives every such case.
		return bBothNumeric ? FMath::IsNearlyEqual(LeftNum, RightNum, KINDA_SMALL_NUMBER)
			: Left.Equals(Right, ESearchCase::CaseSensitive);
	case 3: // NotEqual
		return bBothNumeric ? !FMath::IsNearlyEqual(LeftNum, RightNum, KINDA_SMALL_NUMBER)
			: !Left.Equals(Right, ESearchCase::CaseSensitive);
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

	AActor* Target = ShockScriptReflection::ResolveTargetActor(World, Label);
	if (!Target)
	{
		return false;
	}

	const FString Path = PropertyPath.IsEmpty() ? TEXT("Label") : PropertyPath;
	const bool bIsLabelPath = Path.Equals(TEXT("Label"), ESearchCase::IgnoreCase)
		|| Path.Equals(TEXT("ActorLabel"), ESearchCase::IgnoreCase);
	const bool bIsHiddenPath = Path.Equals(TEXT("bHidden"), ESearchCase::IgnoreCase)
		|| Path.Equals(TEXT("Hidden"), ESearchCase::IgnoreCase);

	FString LeftText;
	if (bIsHiddenPath)
	{
		LeftText = Target->IsHidden() ? TEXT("True") : TEXT("False");
	}
#if WITH_EDITOR
	else if (bIsLabelPath)
	{
		LeftText = Target->GetActorLabel();
	}
#endif
	else
	{
		// Everything else: generic FProperty reflection (R2.1), same dotted-component path as
		// ActionSetProperty/ActionGetProperty.
		if (!ShockScriptReflection::GetPropertyAsText(Target, Path, LeftText))
		{
			return false;
		}
	}

	const bool bResult = ComparePropertyStrings(OpTest, LeftText, Value);
	// Cache for a sibling action's resolveInfoList (R1.1) — a PropertyTest's boolean drives the
	// next action's param, same as ActionGetProperty's return. ActionPropertyTest returns a
	// VariableBool in the decompiled source (Scripting.U).
	const_cast<UShockActionPropertyTest*>(this)->SetReturnValueText(
		bResult ? TEXT("True") : TEXT("False"), TEXT("VariableBool"));
	return bResult;
}
