#include "ShockActionPropertyTest.h"

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
	// Native findTestProperty/doPropertyTest not ported — refuse true rather than invent.
	return false;
}
