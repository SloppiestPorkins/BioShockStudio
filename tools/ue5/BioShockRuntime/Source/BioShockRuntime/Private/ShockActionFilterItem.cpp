#include "ShockActionFilterItem.h"

UShockActionFilterItem::UShockActionFilterItem()
{
	ActionClassName = TEXT("ActionFilterItem");
}

void UShockActionFilterItem::Configure(FName InItem, bool bInUnFilter)
{
	ItemClass = InItem;
	bUnFilter = bInUnFilter;
}

bool UShockActionFilterItem::RequestFilter()
{
	if (ItemClass.IsNone())
	{
		return false;
	}
	LastItemClass = ItemClass;
	return true;
}
