#include "ShockLiveBridge.h"

#include "AssetRegistry/AssetRegistryModule.h"
#include "Animation/SkeletalMeshActor.h"
#include "Camera/CameraActor.h"
#include "Components/SkeletalMeshComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/SkeletalMesh.h"
#include "Engine/StaticMesh.h"
#include "Engine/StaticMeshActor.h"
#include "Camera/CameraComponent.h"
#include "Common/UdpSocketBuilder.h"
#include "Components/SceneCaptureComponent2D.h"
#include "Engine/SceneCapture2D.h"
#include "Engine/TextureCube.h"
#include "Engine/TextureRenderTarget2D.h"
#include "Engine/World.h"
#include "EngineUtils.h"
#include "GameFramework/PlayerController.h"
#include "HAL/FileManager.h"
#include "Interfaces/IPv4/IPv4Endpoint.h"
#include "Kismet/KismetRenderingLibrary.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Misc/CommandLine.h"
#include "Misc/Paths.h"
#include "Sockets.h"
#include "SocketSubsystem.h"

namespace
{
	const TCHAR* KeyTagPrefix = TEXT("BioShockKey=");

	FQuat GameRot(const FString& P, const FString& Y, const FString& R)
	{
		return FRotator(FCString::Atof(*P), FCString::Atof(*Y), FCString::Atof(*R)).Quaternion();
	}

	FVector GameVec(const FString& X, const FString& Y, const FString& Z)
	{
		return FVector(FCString::Atof(*X), FCString::Atof(*Y), FCString::Atof(*Z));
	}
}

bool UShockLiveBridge::ShouldCreateSubsystem(UObject* Outer) const
{
	const UWorld* World = Cast<UWorld>(Outer);
	// FParse::Param only matches the bare switch; -bioshocklive=<port> needs FParse::Value.
	int32 AnyPort = 0;
	const bool bAsked = FParse::Param(FCommandLine::Get(), TEXT("bioshocklive"))
		|| FParse::Value(FCommandLine::Get(), TEXT("bioshocklive="), AnyPort);
	return World && World->IsGameWorld() && bAsked;
}

void UShockLiveBridge::Initialize(FSubsystemCollectionBase& Collection)
{
	Super::Initialize(Collection);
	FParse::Value(FCommandLine::Get(), TEXT("bioshocklive="), Port);
	FParse::Value(FCommandLine::Get(), TEXT("bioshocklivecapture="), CaptureDir);
	FParse::Value(FCommandLine::Get(), TEXT("bioshocklivecapevery="), CaptureEvery);
	FParse::Value(FCommandLine::Get(), TEXT("bioshockliveseconds="), ExitAfter);
}

void UShockLiveBridge::OnWorldBeginPlay(UWorld& InWorld)
{
	Super::OnWorldBeginPlay(InWorld);

	for (TActorIterator<AActor> It(&InWorld); It; ++It)
	{
		for (const FName& Tag : It->Tags)
		{
			const FString S = Tag.ToString();
			if (S.StartsWith(KeyTagPrefix))
			{
				FTracked& T = Tracked.Add(FName(*S.Mid(FCString::Strlen(KeyTagPrefix))));
				T.Actor = *It;
				T.UeLoc0 = It->GetActorLocation();
				T.UeRot0 = It->GetActorQuat();
				T.bHidden = It->IsHidden();
				break;
			}
		}
	}

	BuildMeshIndex();

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	Camera = InWorld.SpawnActor<ACameraActor>(FVector::ZeroVector, FRotator::ZeroRotator, Params);
	if (Camera)
	{
		Camera->GetCameraComponent()->bConstrainAspectRatio = false;
	}

	// A uniform white cube (tools/livegame/import_white_cube.py), so the zone tint the game sends is
	// the colour that lands. The engine's DefaultCubemap is strongly warm and turned a cool
	// blue-grey zone ambient orange (measured 6 Oct 2026); it is only the fallback.
	AmbientCube = LoadObject<UTextureCube>(nullptr, TEXT("/Game/BioShockLive/WhiteAmbientCube.WhiteAmbientCube"));
	if (!AmbientCube)
	{
		AmbientCube = LoadObject<UTextureCube>(nullptr, TEXT("/Engine/EngineMaterials/DefaultCubemap.DefaultCubemap"));
	}

	Socket = FUdpSocketBuilder(TEXT("ShockLiveBridge"))
		.AsNonBlocking()
		.AsReusable()
		.BoundToEndpoint(FIPv4Endpoint(FIPv4Address(127, 0, 0, 1), Port))
		.WithReceiveBufferSize(8 * 1024 * 1024)
		.Build();

	bActive = Socket != nullptr;
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_LIVE start port=%d tracked=%d socket=%s capture=%s"),
		Port, Tracked.Num(), Socket ? TEXT("ok") : TEXT("FAILED"), *CaptureDir);
}

void UShockLiveBridge::Deinitialize()
{
	if (Socket)
	{
		Socket->Close();
		ISocketSubsystem::Get(PLATFORM_SOCKETSUBSYSTEM)->DestroySocket(Socket);
		Socket = nullptr;
	}
	Super::Deinitialize();
}

TStatId UShockLiveBridge::GetStatId() const
{
	RETURN_QUICK_DECLARE_CYCLE_STAT(UShockLiveBridge, STATGROUP_Tickables);
}

void UShockLiveBridge::ApplyLine(const TArray<FString>& Tok)
{
	if (Tok.Num() == 0)
	{
		return;
	}
	++Lines;
	const FString& Op = Tok[0];
	if (Op == TEXT("F") && Tok.Num() >= 3)
	{
		LastFrame = FCString::Atoi64(*Tok[1]);
		LastGameSeconds = FCString::Atof(*Tok[2]);
	}
	else if (Op == TEXT("C") && Tok.Num() >= 8 && Camera)
	{
		Camera->SetActorLocationAndRotation(GameVec(Tok[1], Tok[2], Tok[3]), GameRot(Tok[4], Tok[5], Tok[6]));
		Hfov = FCString::Atof(*Tok[7]);
		Camera->GetCameraComponent()->SetFieldOfView(Hfov);
		bHaveCamera = true;
	}
	else if (Op == TEXT("Z") && Tok.Num() >= 5)
	{
		AmbientTint = FLinearColor(FCString::Atof(*Tok[1]), FCString::Atof(*Tok[2]), FCString::Atof(*Tok[3]));
		AmbientIntensity = FCString::Atof(*Tok[4]);
		// The baked world is unlit, so it takes the zone ambient as a material term instead.
		// Optional 6th token: its own scale (default: the same intensity).
		const float BakedAmb = Tok.Num() >= 6 ? FCString::Atof(*Tok[5]) : AmbientIntensity;
		for (UMaterialInstanceDynamic* Mid : BakedMids)
		{
			if (Mid)
			{
				Mid->SetVectorParameterValue(TEXT("ZoneAmbient"), AmbientTint * BakedAmb);
			}
		}
		if (Camera)
		{
			ApplyAmbient(Camera->GetCameraComponent()->PostProcessSettings);
			Camera->GetCameraComponent()->PostProcessBlendWeight = 1.f;
		}
	}
	else if (Op == TEXT("S") && Tok.Num() >= 4)
	{
		const FName Key(*Tok[1]);
		if (!Spawned.Contains(Key))
		{
			SpawnStandIn(Key, Tok[2] == TEXT("skel"), Tok[3]);
		}
	}
	else if (Op == TEXT("D") && Tok.Num() >= 11)
	{
		if (TObjectPtr<AActor>* Found = Spawned.Find(FName(*Tok[1])))
		{
			if (AActor* A = Found->Get())
			{
				A->SetActorLocationAndRotation(GameVec(Tok[2], Tok[3], Tok[4]), GameRot(Tok[5], Tok[6], Tok[7]),
					false, nullptr, ETeleportType::TeleportPhysics);
				A->SetActorScale3D(GameVec(Tok[8], Tok[9], Tok[10]));
				A->SetActorHiddenInGame(Tok.Num() >= 12 && Tok[11] == TEXT("1"));
			}
		}
	}
	else if (Op == TEXT("X") && Tok.Num() >= 2)
	{
		TObjectPtr<AActor> Gone;
		if (Spawned.RemoveAndCopyValue(FName(*Tok[1]), Gone) && Gone)
		{
			Gone->Destroy();
		}
	}
	else if (Op == TEXT("L") && Tok.Num() >= 2)
	{
		SetBakedExposure(FCString::Atof(*Tok[1]));
		// Optional debug factors: L <exposure> <useBase> <useLightmap>
		if (Tok.Num() >= 4)
		{
			for (UMaterialInstanceDynamic* Mid : BakedMids)
			{
				if (Mid)
				{
					Mid->SetScalarParameterValue(TEXT("UseBase"), FCString::Atof(*Tok[2]));
					Mid->SetScalarParameterValue(TEXT("UseLightmap"), FCString::Atof(*Tok[3]));
					if (Tok.Num() >= 5)
					{
						Mid->SetScalarParameterValue(TEXT("LightmapFromUV0"), FCString::Atof(*Tok[4]));
					}
					if (Tok.Num() >= 6)
					{
						Mid->SetScalarParameterValue(TEXT("ShowLightmapUV"), FCString::Atof(*Tok[5]));
					}
				}
			}
		}
	}
	else if ((Op == TEXT("B") || Op == TEXT("A")) && Tok.Num() >= 8)
	{
		const FName Key(*Tok[1]);
		FTracked* T = Tracked.Find(Key);
		if (!T || !T->Actor.IsValid())
		{
			UnknownKeys.Add(Key);
			return;
		}
		const FVector Loc = GameVec(Tok[2], Tok[3], Tok[4]);
		const FQuat Rot = GameRot(Tok[5], Tok[6], Tok[7]);
		if (Op == TEXT("B"))
		{
			T->GameLoc0 = Loc;
			T->GameRot0 = Rot;
			T->bHaveBase = true;
			return;
		}
		if (!T->bHaveBase)
		{
			return;
		}
		AActor* A = T->Actor.Get();
		const FVector NewLoc = T->UeLoc0 + (Loc - T->GameLoc0);
		const FQuat NewRot = (Rot * T->GameRot0.Inverse()) * T->UeRot0;
		if (!NewLoc.Equals(A->GetActorLocation(), 0.5f) || !NewRot.Equals(A->GetActorQuat(), 1e-4f))
		{
			if (!T->bMadeMovable && A->GetRootComponent())
			{
				// Only what the game actually moves becomes Movable; everything else keeps its
				// static lighting.
				A->GetRootComponent()->SetMobility(EComponentMobility::Movable);
				T->bMadeMovable = true;
			}
			A->SetActorLocationAndRotation(NewLoc, NewRot, false, nullptr, ETeleportType::TeleportPhysics);
			++Moves;
		}
		const bool bHid = Tok.Num() >= 9 && Tok[8] == TEXT("1");
		if (bHid != T->bHidden)
		{
			A->SetActorHiddenInGame(bHid);
			T->bHidden = bHid;
		}
	}
}

void UShockLiveBridge::Tick(float DeltaTime)
{
	if (!bActive)
	{
		return;
	}
	UWorld* World = GetWorld();

	uint32 Pending = 0;
	TArray<uint8> Buf;
	TArray<FString> LinesIn, Tok;
	while (Socket->HasPendingData(Pending))
	{
		Buf.SetNumUninitialized(FMath::Min<uint32>(Pending, 65507u) + 1);
		int32 Read = 0;
		TSharedRef<FInternetAddr> From = ISocketSubsystem::Get(PLATFORM_SOCKETSUBSYSTEM)->CreateInternetAddr();
		if (!Socket->RecvFrom(Buf.GetData(), Buf.Num() - 1, Read, *From) || Read <= 0)
		{
			break;
		}
		Buf[Read] = 0;
		const FString Text(UTF8_TO_TCHAR(reinterpret_cast<const ANSICHAR*>(Buf.GetData())));
		Text.ParseIntoArrayLines(LinesIn);
		for (const FString& L : LinesIn)
		{
			L.ParseIntoArrayWS(Tok);
			ApplyLine(Tok);
		}
	}

	if (Camera && World)
	{
		if (APlayerController* PC = World->GetFirstPlayerController())
		{
			if (PC->GetViewTarget() != Camera)
			{
				PC->SetViewTarget(Camera);
			}
		}
	}

	RunClock += DeltaTime;
	CaptureClock += DeltaTime;
	LogClock += DeltaTime;
	if (!CaptureDir.IsEmpty() && bHaveCamera && CaptureClock >= CaptureEvery)
	{
		CaptureClock = 0.f;
		CaptureFrame();
	}
	if (LogClock >= 5.f)
	{
		LogClock = 0.f;
		int32 Live = 0;
		for (const auto& Pair : Spawned) { Live += Pair.Value ? 1 : 0; }
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_LIVE frame=%lld game_t=%.2f lines=%lld moves=%lld unknown_keys=%d spawned=%d/%d missing_meshes=%d"),
			LastFrame, LastGameSeconds, Lines, Moves, UnknownKeys.Num(), Live, Spawned.Num(), MissingMeshes.Num());
	}
	if (ExitAfter > 0.f && RunClock >= ExitAfter)
	{
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_LIVE done frame=%lld lines=%lld moves=%lld unknown_keys=%d"),
			LastFrame, Lines, Moves, UnknownKeys.Num());
		bActive = false;
		FGenericPlatformMisc::RequestExit(false);
	}
}

void UShockLiveBridge::BuildMeshIndex()
{
	// Every static and skeletal mesh in the project, by asset name and by the name with the importer's
	// "_<exportIndex>" suffix stripped, so a game mesh name ("Med_DoorRight") finds its asset.
	// Also by the asset's FOLDER name: character imports reuse rigs, so Agg_LadySmith/ holds an
	// asset named AggressorBabyJane. An uncooked -game run scans the registry asynchronously, which
	// had indexed only 5 skeletal meshes by BeginPlay -- so block for a full scan first.
	IAssetRegistry& Registry = FModuleManager::LoadModuleChecked<FAssetRegistryModule>(TEXT("AssetRegistry")).Get();
	Registry.SearchAllAssets(true);
	auto Index = [&Registry](UClass* Class, TMap<FString, FSoftObjectPath>& Out)
	{
		TArray<FAssetData> Assets;
		Registry.GetAssetsByClass(Class->GetClassPathName(), Assets, true);
		for (const FAssetData& A : Assets)
		{
			const FString Name = A.AssetName.ToString().ToLower();
			Out.FindOrAdd(Name, A.GetSoftObjectPath());
			const FString Folder = FPaths::GetCleanFilename(A.PackagePath.ToString()).ToLower();
			if (!Folder.IsEmpty())
			{
				Out.FindOrAdd(Folder, A.GetSoftObjectPath());
			}
			int32 Underscore = INDEX_NONE;
			if (Name.FindLastChar(TEXT('_'), Underscore) && Underscore > 0)
			{
				const FString Tail = Name.Mid(Underscore + 1);
				if (Tail.Len() > 0 && Tail.IsNumeric())
				{
					Out.FindOrAdd(Name.Left(Underscore), A.GetSoftObjectPath());
				}
			}
		}
	};
	Index(UStaticMesh::StaticClass(), StaticMeshByName);
	Index(USkeletalMesh::StaticClass(), SkeletalMeshByName);
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_LIVE mesh index static=%d skeletal=%d"), StaticMeshByName.Num(), SkeletalMeshByName.Num());
}

void UShockLiveBridge::SpawnStandIn(const FName& Key, bool bSkeletal, const FString& MeshName)
{
	UWorld* World = GetWorld();
	const FString Lookup = MeshName.ToLower();
	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	AActor* Spawn = nullptr;
	if (bSkeletal)
	{
		const FSoftObjectPath* Path = SkeletalMeshByName.Find(Lookup);
		USkeletalMesh* Mesh = Path ? Cast<USkeletalMesh>(Path->TryLoad()) : nullptr;
		if (Mesh)
		{
			ASkeletalMeshActor* A = World->SpawnActor<ASkeletalMeshActor>(FVector::ZeroVector, FRotator::ZeroRotator, Params);
			A->GetSkeletalMeshComponent()->SetSkeletalMeshAsset(Mesh);
			Spawn = A;
		}
	}
	else
	{
		const FSoftObjectPath* Path = StaticMeshByName.Find(Lookup);
		UStaticMesh* Mesh = Path ? Cast<UStaticMesh>(Path->TryLoad()) : nullptr;
		if (Mesh)
		{
			AStaticMeshActor* A = World->SpawnActor<AStaticMeshActor>(FVector::ZeroVector, FRotator::ZeroRotator, Params);
			A->GetStaticMeshComponent()->SetMobility(EComponentMobility::Movable);
			A->GetStaticMeshComponent()->SetStaticMesh(Mesh);
			Spawn = A;
		}
	}
	if (!Spawn)
	{
		if (!MissingMeshes.Contains(Lookup))
		{
			MissingMeshes.Add(Lookup);
			UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_LIVE no %s mesh named %s (for %s)"),
				bSkeletal ? TEXT("skeletal") : TEXT("static"), *MeshName, *Key.ToString());
		}
		Spawned.Add(Key, nullptr);  // do not retry every frame
		return;
	}
	Spawn->Tags.Add(Key);
	Spawned.Add(Key, Spawn);
}

void UShockLiveBridge::SetBakedExposure(float Value)
{
	if (FMath::IsNearlyEqual(Value, BakedExposure) && BakedMids.Num() > 0)
	{
		return;
	}
	BakedExposure = Value;
	if (BakedMids.Num() == 0)
	{
		// The actor import_baked_world.py places; its materials get dynamic instances once.
		for (TActorIterator<AActor> It(GetWorld()); It; ++It)
		{
			if (!It->Tags.Contains(FName(TEXT("BIOSHOCK_BAKED_WORLD"))))
			{
				continue;
			}
			TArray<UPrimitiveComponent*> Prims;
			It->GetComponents<UPrimitiveComponent>(Prims);
			for (UPrimitiveComponent* P : Prims)
			{
				for (int32 i = 0; i < P->GetNumMaterials(); ++i)
				{
					if (UMaterialInstanceDynamic* Mid = P->CreateAndSetMaterialInstanceDynamic(i))
					{
						BakedMids.Add(Mid);
					}
				}
			}
		}
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_LIVE baked world materials=%d"), BakedMids.Num());
	}
	for (UMaterialInstanceDynamic* Mid : BakedMids)
	{
		if (Mid)
		{
			Mid->SetScalarParameterValue(TEXT("BakedExposure"), BakedExposure);
		}
	}
}

void UShockLiveBridge::ApplyAmbient(FPostProcessSettings& PP) const
{
	if (AmbientIntensity < 0.f || !AmbientCube)
	{
		return;
	}
	PP.bOverride_AmbientCubemapIntensity = true;
	PP.bOverride_AmbientCubemapTint = true;
	PP.AmbientCubemap = AmbientCube;
	PP.AmbientCubemapIntensity = AmbientIntensity;
	PP.AmbientCubemapTint = AmbientTint;
}

void UShockLiveBridge::CaptureFrame()
{
	UWorld* World = GetWorld();
	if (!World || !Camera)
	{
		return;
	}
	if (!Target)
	{
		int32 W = 1280, H = 720;
		FParse::Value(FCommandLine::Get(), TEXT("bioshockshotwidth="), W);
		FParse::Value(FCommandLine::Get(), TEXT("bioshockshotheight="), H);
		Target = UKismetRenderingLibrary::CreateRenderTarget2D(World, W, H, RTF_RGBA8);
		FActorSpawnParameters Params;
		Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
		Capture = World->SpawnActor<ASceneCapture2D>(FVector::ZeroVector, FRotator::ZeroRotator, Params);
		if (!Capture || !Target)
		{
			CaptureDir.Empty();
			return;
		}
		USceneCaptureComponent2D* Comp = Capture->GetCaptureComponent2D();
		Comp->TextureTarget = Target;
		Comp->CaptureSource = ESceneCaptureSource::SCS_FinalColorLDR;
		Comp->bCaptureEveryFrame = false;
		Comp->bCaptureOnMovement = false;
		IFileManager::Get().MakeDirectory(*CaptureDir, true);
	}
	Capture->SetActorLocationAndRotation(Camera->GetActorLocation(), Camera->GetActorRotation());
	USceneCaptureComponent2D* Comp = Capture->GetCaptureComponent2D();
	Comp->FOVAngle = Hfov;
	ApplyAmbient(Comp->PostProcessSettings);
	Comp->PostProcessBlendWeight = 1.f;
	Comp->CaptureScene();
	UKismetRenderingLibrary::ExportRenderTarget(World, Target, CaptureDir,
		FString::Printf(TEXT("ue_%06lld.png"), LastFrame));
}
