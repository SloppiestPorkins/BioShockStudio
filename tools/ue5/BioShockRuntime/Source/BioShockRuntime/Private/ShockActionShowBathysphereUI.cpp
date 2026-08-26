#include "ShockActionShowBathysphereUI.h"

UShockActionShowBathysphereUI::UShockActionShowBathysphereUI()
{
	ActionClassName = TEXT("ActionShowBathysphereUI");
	BathysphereSystem = TEXT("BioshockBathyspheres");
}

void UShockActionShowBathysphereUI::Configure(FName InSystem)
{
	BathysphereSystem = InSystem;
}

bool UShockActionShowBathysphereUI::RequestShow()
{
	if (BathysphereSystem.IsNone())
	{
		return false;
	}
	LastBathysphereSystem = BathysphereSystem;
	return true;
}
