#include "BioShockSocketLibrary.h"

#include "Animation/Skeleton.h"
#include "Engine/SkeletalMesh.h"
#include "Engine/SkeletalMeshSocket.h"

int32 UBioShockSocketLibrary::RestoreSockets(USkeletalMesh* Mesh, const TArray<FName>& SocketNames, const TArray<FName>& BoneNames)
{
    if (!Mesh || SocketNames.Num() != BoneNames.Num()) return 0;

    int32 Added = 0;
    for (int32 Index = 0; Index < SocketNames.Num(); ++Index)
    {
        if (Mesh->FindSocket(SocketNames[Index])) continue;
        if (!Mesh->GetSkeleton() || Mesh->GetSkeleton()->GetReferenceSkeleton().FindBoneIndex(BoneNames[Index]) == INDEX_NONE) continue;
        USkeletalMeshSocket* Socket = NewObject<USkeletalMeshSocket>(Mesh, SocketNames[Index], RF_Transactional);
        Socket->SocketName = SocketNames[Index];
        Socket->BoneName = BoneNames[Index];
        Mesh->AddSocket(Socket, true);
        ++Added;
    }
    if (Added) Mesh->MarkPackageDirty();
    return Added;
}
