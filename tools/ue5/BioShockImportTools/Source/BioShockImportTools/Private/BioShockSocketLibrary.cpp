#include "BioShockSocketLibrary.h"

#include "Animation/Skeleton.h"
#include "Engine/SkeletalMesh.h"
#include "Engine/SkeletalMeshSocket.h"

int32 UBioShockSocketLibrary::RestoreSockets(
	USkeletalMesh* Mesh,
	const TArray<FName>& SocketNames,
	const TArray<FName>& BoneNames,
	const TArray<FVector>& RelativeLocations,
	const TArray<FRotator>& RelativeRotations)
{
	if (!Mesh || SocketNames.Num() != BoneNames.Num()) return 0;

	int32 Added = 0;
	bool bDirty = false;
	for (int32 Index = 0; Index < SocketNames.Num(); ++Index)
	{
		const bool bHasLocation = RelativeLocations.IsValidIndex(Index);
		const bool bHasRotation = RelativeRotations.IsValidIndex(Index);

		if (USkeletalMeshSocket* Existing = Mesh->FindSocket(SocketNames[Index]))
		{
			// FBX SOCKET_* nulls may already have become identity sockets; still apply the
			// manifest transform when one was provided.
			if (bHasLocation)
			{
				Existing->RelativeLocation = RelativeLocations[Index];
				bDirty = true;
			}
			if (bHasRotation)
			{
				Existing->RelativeRotation = RelativeRotations[Index];
				bDirty = true;
			}
			continue;
		}
		if (!Mesh->GetSkeleton() || Mesh->GetSkeleton()->GetReferenceSkeleton().FindBoneIndex(BoneNames[Index]) == INDEX_NONE) continue;
		USkeletalMeshSocket* Socket = NewObject<USkeletalMeshSocket>(Mesh, SocketNames[Index], RF_Transactional);
		Socket->SocketName = SocketNames[Index];
		Socket->BoneName = BoneNames[Index];
		if (bHasLocation)
		{
			Socket->RelativeLocation = RelativeLocations[Index];
		}
		if (bHasRotation)
		{
			Socket->RelativeRotation = RelativeRotations[Index];
		}
		Mesh->AddSocket(Socket, true);
		++Added;
		bDirty = true;
	}
	if (bDirty) Mesh->MarkPackageDirty();
	return Added;
}
