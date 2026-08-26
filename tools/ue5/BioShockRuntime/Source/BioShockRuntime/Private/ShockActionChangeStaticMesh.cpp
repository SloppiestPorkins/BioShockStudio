#include "ShockActionChangeStaticMesh.h"

UShockActionChangeStaticMesh::UShockActionChangeStaticMesh()
{
	ActionClassName = TEXT("ActionChangeStaticMesh");
	TargetLabel = TEXT("UNSPECIFIED");
}

void UShockActionChangeStaticMesh::Configure(FName InTarget, FName InMesh)
{
	TargetLabel = InTarget;
	StaticMeshName = InMesh;
}

bool UShockActionChangeStaticMesh::RequestChange()
{
	if (TargetLabel.IsNone())
	{
		return false;
	}
	LastTargetLabel = TargetLabel;
	return true;
}
