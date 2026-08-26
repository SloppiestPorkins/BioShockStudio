#include "ShockActionDisableOrEnableConcept.h"

UShockActionDisableOrEnableConcept::UShockActionDisableOrEnableConcept()
{
	ActionClassName = TEXT("ActionDisableOrEnableConcept");
}

void UShockActionDisableOrEnableConcept::Configure(FName InConceptName, bool bInEnable)
{
	ConceptName = InConceptName;
	bEnable = bInEnable;
}

bool UShockActionDisableOrEnableConcept::RequestToggle()
{
	if (ConceptName.IsNone())
	{
		return false;
	}
	LastConceptName = ConceptName;
	bLastEnable = bEnable;
	return true;
}
