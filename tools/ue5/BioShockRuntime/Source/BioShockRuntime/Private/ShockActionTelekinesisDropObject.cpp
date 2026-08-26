#include "ShockActionTelekinesisDropObject.h"

UShockActionTelekinesisDropObject::UShockActionTelekinesisDropObject()
{
	ActionClassName = TEXT("ActionTelekinesisDropObject");
}

bool UShockActionTelekinesisDropObject::RequestDrop()
{
	bDropRequested = true;
	return true;
}
