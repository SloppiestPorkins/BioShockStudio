#include "ShockActionShowNeedleElement.h"

UShockActionShowNeedleElement::UShockActionShowNeedleElement()
{
	ActionClassName = TEXT("ShowNeedleElement");
}

bool UShockActionShowNeedleElement::RequestShow()
{
	bShowRequested = true;
	return true;
}
