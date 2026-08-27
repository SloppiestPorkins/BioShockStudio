#include "ShockActionTrainingCondition.h"

UShockActionTrainingCondition::UShockActionTrainingCondition()
{
	ActionClassName = TEXT("TrainingCondition");
	TickDelay = 10;
}
void UShockActionTrainingCondition::Configure(float InWeight, int32 InTickDelay, int32 InPriority, FName InConcept)
{
	Weight = InWeight;
	TickDelay = InTickDelay;
	Priority = InPriority;
	ConceptName = InConcept;
}
bool UShockActionTrainingCondition::RequestEvaluate()
{
	bConditionRequested = true;
	return !ConceptName.IsNone();
}
