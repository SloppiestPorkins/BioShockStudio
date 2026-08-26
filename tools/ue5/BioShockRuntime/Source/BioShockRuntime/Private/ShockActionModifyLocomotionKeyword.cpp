#include "ShockActionModifyLocomotionKeyword.h"

UShockActionModifyLocomotionKeyword::UShockActionModifyLocomotionKeyword()
{
	ActionClassName = TEXT("ActionModifyLocomotionKeyword");
	KeywordPriority = 1;
	bAddKeyword = true;
}

void UShockActionModifyLocomotionKeyword::Configure(FName InAI, FName InKeyword, int32 InPriority, bool bInAdd)
{
	AILabel = InAI;
	Keyword = InKeyword;
	KeywordPriority = InPriority;
	bAddKeyword = bInAdd;
}

bool UShockActionModifyLocomotionKeyword::RequestModify()
{
	if (AILabel.IsNone() || Keyword.IsNone())
	{
		return false;
	}
	LastAILabel = AILabel;
	return true;
}
