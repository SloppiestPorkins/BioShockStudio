#include "ShockActionRemoveCraftingFormula.h"

UShockActionRemoveCraftingFormula::UShockActionRemoveCraftingFormula()
{
	ActionClassName = TEXT("ActionRemoveCraftingFormula");
}

void UShockActionRemoveCraftingFormula::Configure(FName InFormula)
{
	FormulaClass = InFormula;
}

bool UShockActionRemoveCraftingFormula::RequestRemove()
{
	if (FormulaClass.IsNone())
	{
		return false;
	}
	LastFormulaClass = FormulaClass;
	return true;
}
