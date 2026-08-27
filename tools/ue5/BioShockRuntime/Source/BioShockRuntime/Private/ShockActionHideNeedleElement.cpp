#include "ShockActionHideNeedleElement.h"

UShockActionHideNeedleElement::UShockActionHideNeedleElement()
{
	ActionClassName = TEXT("HideNeedleElement");
}

bool UShockActionHideNeedleElement::RequestHide()
{
	bHideRequested = true;
	return true;
}
