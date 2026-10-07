#include "ShockLiveBridge.h"

#include "AssetRegistry/AssetRegistryModule.h"
#include "Animation/SkeletalMeshActor.h"
#include "Camera/CameraActor.h"
#include "Components/PoseableMeshComponent.h"
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
#include "Kismet/GameplayStatics.h"
#include "Kismet/KismetRenderingLibrary.h"
#include "Misc/PackageName.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Misc/CommandLine.h"
#include "Misc/Paths.h"
#include "ShockHudWidget.h"
#include "ShockPlayer.h"
#include "Sockets.h"
#include "SocketSubsystem.h"
#include "Engine/Texture2D.h"
#include "Engine/GameViewportClient.h"
#include "Widgets/Images/SImage.h"
#include "UnrealClient.h"
#include "Windows/AllowWindowsPlatformTypes.h"
#include <windows.h>
#include "Windows/HideWindowsPlatformTypes.h"

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
				FString Key = S.Mid(FCString::Strlen(KeyTagPrefix));
				// Props placed from manifest `instances` are tagged instance:<actorKey>:<asset>; the
				// game side streams by actorKey. Missing this was the "404 unknown keys".
				if (Key.StartsWith(TEXT("instance:")))
				{
					Key = Key.Mid(9);
					int32 Colon = INDEX_NONE;
					if (Key.FindChar(TEXT(':'), Colon))
					{
						Key = Key.Left(Colon);
					}
				}
				// door:<key>, aprop:<key> and other lowercase prefixes name the same game actor.
				int32 Colon = INDEX_NONE;
				if (Key.FindChar(TEXT(':'), Colon) && Colon > 0 && Colon <= 12 && FChar::IsLower(Key[0]))
				{
					Key = Key.Mid(Colon + 1);
				}
				ByGameKey.Add(FName(*Key), *It);
				FTracked& T = Tracked.Add(FName(*Key));
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
	if (GameHudOverlay && GEngine && GEngine->GameViewport)
	{
		GEngine->GameViewport->RemoveViewportWidgetContent(GameHudOverlay.ToSharedRef());
	}
	GameHudOverlay.Reset();
	if (GameHudView)
	{
		UnmapViewOfFile(GameHudView);
		GameHudView = nullptr;
	}
	if (GameHudMapping)
	{
		CloseHandle(GameHudMapping);
		GameHudMapping = nullptr;
	}
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
		if (Tok.Num() >= 9)
		{
			// The viewmodel's own FOV, and a scale toward the camera so it never clips into walls (the
			// original clears depth before drawing it).
			UCameraComponent* Cam = Camera->GetCameraComponent();
			Cam->SetEnableFirstPersonFieldOfView(true);
			FirstPersonHfov = FCString::Atof(*Tok[8]);
			Cam->SetFirstPersonFieldOfView(FirstPersonHfov);
			Cam->SetEnableFirstPersonScale(true);
			Cam->SetFirstPersonScale(0.2f);
		}
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
		TObjectPtr<AActor>* Found = Spawned.Find(Key);
		// "r=<key>": the stand-in replaces a placed level actor; hide every copy of it once the
		// stand-in exists (if its mesh is missing, the placed copy stays).
		for (int32 t = 4; t < Tok.Num() && Found && Found->Get(); ++t)
		{
			if (Tok[t].StartsWith(TEXT("r=")))
			{
				const FName Replaced(*Tok[t].Mid(2));
				if (!ReplacedKeys.Contains(Replaced))
				{
					TArray<TWeakObjectPtr<AActor>> Copies;
					ByGameKey.MultiFind(Replaced, Copies);
					for (const TWeakObjectPtr<AActor>& C : Copies)
					{
						if (C.IsValid())
						{
							C->SetActorHiddenInGame(true);
							C->SetActorEnableCollision(false);
						}
					}
					ReplacedKeys.Add(Replaced);
				}
			}
		}
		// "fp": the player owns it (hands, held weapon) -> UE's first-person rendering.
		if (Tok.Num() >= 5 && Tok.Contains(TEXT("fp")) && Found && Found->Get())
		{
			TInlineComponentArray<UPrimitiveComponent*> Prims(Found->Get());
			for (UPrimitiveComponent* Prim : Prims)
			{
				if (Prim->FirstPersonPrimitiveType != EFirstPersonPrimitiveType::FirstPerson)
				{
					Prim->SetFirstPersonPrimitiveType(EFirstPersonPrimitiveType::FirstPerson);
				}
			}
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
	else if (Op == TEXT("P") && Tok.Num() >= 3)
	{
		TObjectPtr<AActor>* Found = Spawned.Find(FName(*Tok[1]));
		UPoseableMeshComponent* Pose = (Found && Found->Get()) ? Cast<UPoseableMeshComponent>(Found->Get()->GetRootComponent()) : nullptr;
		if (Pose && Pose->GetSkinnedAsset())
		{
			TArray<FName>& Order = GameBoneOrder.FindOrAdd(FName(*Tok[1]));
			if (Order.IsEmpty())
			{
				const FReferenceSkeleton& Ref = Pose->GetSkinnedAsset()->GetRefSkeleton();
				for (int32 b = 0; b < Ref.GetNum(); ++b)
				{
					if (!Ref.GetBoneName(b).ToString().StartsWith(TEXT("SOCKET_")))
					{
						Order.Add(Ref.GetBoneName(b));
					}
				}
				const int32 Game = FCString::Atoi(*Tok[2]);
				if (Game != Order.Num())
				{
					UE_LOG(LogTemp, Warning, TEXT("BIOSHOCK_LIVE bones %s: game %d, mesh %d (without sockets)"), *Tok[1], Game, Order.Num());
				}
			}
			const int32 N = FMath::Min3(FCString::Atoi(*Tok[2]), Order.Num(), (Tok.Num() - 3) / 7);
			for (int32 i = 0; i < N; ++i)
			{
				const int32 o = 3 + i * 7;
				const FVector T(FCString::Atof(*Tok[o]), FCString::Atof(*Tok[o + 1]), FCString::Atof(*Tok[o + 2]));
				const FQuat Q(FCString::Atof(*Tok[o + 3]), FCString::Atof(*Tok[o + 4]), FCString::Atof(*Tok[o + 5]), FCString::Atof(*Tok[o + 6]));
				Pose->SetBoneTransformByName(Order[i], FTransform(Q.GetNormalized(), T), EBoneSpaces::ComponentSpace);
			}
		}
	}
	else if (Op == TEXT("X") && Tok.Num() >= 2)
	{
		TObjectPtr<AActor> Gone;
		GameBoneOrder.Remove(FName(*Tok[1]));
		if (Spawned.RemoveAndCopyValue(FName(*Tok[1]), Gone) && Gone)
		{
			Gone->Destroy();
		}
	}
	else if (Op == TEXT("M") && Tok.Num() >= 2)
	{
		// The game is on level Tok[1]: show its prepared live copy (tools/livegame/prepare_map.sh).
		const FString LiveMap = FString::Printf(TEXT("/Game/BioShockLive/%s_Baked"), *Tok[1]);
		UWorld* World = GetWorld();
		if (World && !bTravelling && World->GetMapName() != FPackageName::GetShortName(LiveMap))
		{
			if (FPackageName::DoesPackageExist(LiveMap))
			{
				UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_LIVE level %s -> opening %s"), *Tok[1], *LiveMap);
				bTravelling = true;
				UGameplayStatics::OpenLevel(World, FName(*LiveMap), true, TEXT("game=/Script/Engine.GameModeBase"));
			}
			else if (!MissingLevels.Contains(Tok[1]))
			{
				MissingLevels.Add(Tok[1]);
				UE_LOG(LogTemp, Warning, TEXT("BIOSHOCK_LIVE level %s has no live copy (%s) - run prepare_map.sh"), *Tok[1], *LiveMap);
			}
		}
	}
	else if (Op == TEXT("H") && Tok.Num() >= 6)
	{
		if (!bGameHud)  // the game's own HUD replaces the rebuilt one
		{
			UpdateHud(Tok);
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
		if (ReplacedKeys.Contains(Key))
		{
			return;  // drawn by its stand-in now
		}
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

	TickGameHud();

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

void UShockLiveBridge::UpdateHud(const TArray<FString>& Tok)
{
	UWorld* World = GetWorld();
	if (!Hud)
	{
		APlayerController* PC = World ? World->GetFirstPlayerController() : nullptr;
		if (!PC)
		{
			return;
		}
		// A hidden, inert stand-in carries the game's stats for the existing HUD widget, which reads
		// them from an AShockPlayer.
		FActorSpawnParameters Params;
		Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
		HudPlayer = World->SpawnActor<AShockPlayer>(FVector(0, 0, -200000), FRotator::ZeroRotator, Params);
		if (!HudPlayer)
		{
			return;
		}
		HudPlayer->SetActorHiddenInGame(true);
		HudPlayer->SetActorEnableCollision(false);
		HudPlayer->SetActorTickEnabled(false);
		Hud = CreateWidget<UShockHudWidget>(PC, UShockHudWidget::StaticClass());
		if (!Hud)
		{
			return;
		}
		Hud->BindDisplayPlayer(HudPlayer);
		Hud->AddToViewport();
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_LIVE hud attached"));
	}
	const float Health = FCString::Atof(*Tok[1]);
	HudPlayer->AuthoredMaxHealth = FMath::Max(FCString::Atof(*Tok[2]), 1.0f);
	HudPlayer->SetCurrentHealthForVerify(Health);
	HudPlayer->MaxEve = FMath::Max(FCString::Atof(*Tok[4]), 1.0f);
	HudPlayer->SetCurrentEveForVerify(FCString::Atof(*Tok[3]));
	HudPlayer->PlayerAdam = FCString::Atoi(*Tok[5]);
	if (Tok.Num() >= 8)
	{
		// First-aid kits and EVE hypos: the digits beside the two meters.
		TMap<FName, int32> Stacks;
		Stacks.Add(FName(TEXT("FirstAidKit")), FCString::Atoi(*Tok[6]));
		Stacks.Add(FName(TEXT("EveHypo")), FCString::Atoi(*Tok[7]));
		HudPlayer->RestoreInventoryStacksForTravel(Stacks);
	}
	Hud->RefreshDisplayNow();
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
	FString Lookup = MeshName.ToLower();
	// Held weapons are WP_<Name>Mesh in the game and imported as WP_<Name>.
	if (!SkeletalMeshByName.Contains(Lookup) && !StaticMeshByName.Contains(Lookup) && Lookup.EndsWith(TEXT("mesh")))
	{
		Lookup.LeftChopInline(4);
	}
	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	AActor* Spawn = nullptr;
	if (bSkeletal)
	{
		const FSoftObjectPath* Path = SkeletalMeshByName.Find(Lookup);
		USkeletalMesh* Mesh = Path ? Cast<USkeletalMesh>(Path->TryLoad()) : nullptr;
		if (Mesh)
		{
			// A poseable mesh so the game's evaluated bones (P lines) can drive it directly.
			AActor* A = World->SpawnActor<AActor>(AActor::StaticClass(), FTransform::Identity, Params);
			UPoseableMeshComponent* Pose = NewObject<UPoseableMeshComponent>(A, TEXT("Pose"));
			A->SetRootComponent(Pose);
			Pose->SetMobility(EComponentMobility::Movable);
			Pose->RegisterComponent();
			Pose->SetSkinnedAssetAndUpdate(Mesh);
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
	// A scene capture has its own first-person settings; without them the viewmodel is drawn at the
	// world FOV in captures only, unlike the visible window.
	Comp->bEnableFirstPersonFieldOfView = FirstPersonHfov > 0.f;
	Comp->FirstPersonFieldOfView = FirstPersonHfov > 0.f ? FirstPersonHfov : Hfov;
	Comp->bEnableFirstPersonScale = true;
	Comp->FirstPersonScale = 0.2f;
	ApplyAmbient(Comp->PostProcessSettings);
	Comp->PostProcessBlendWeight = 1.f;
	Comp->CaptureScene();
	// The scene capture has no UI; a viewport screenshot (with UI) shows the HUD overlay.
	if (bGameHud)
	{
		FScreenshotRequest::RequestScreenshot(FPaths::Combine(CaptureDir, FString::Printf(TEXT("ui_%06lld.png"), LastFrame)), true, false);
	}
	UKismetRenderingLibrary::ExportRenderTarget(World, Target, CaptureDir,
		FString::Printf(TEXT("ue_%06lld.png"), LastFrame));
}

void UShockLiveBridge::TickGameHud()
{
	struct FHeader { uint32 Magic, Width, Height, Pitch; volatile int32 Frame, Seq; uint32 Reserved[10]; };
	if (!GameHudView)
	{
		GameHudRetry -= GetWorld() ? GetWorld()->GetDeltaSeconds() : 0.f;
		if (GameHudRetry > 0.f)
		{
			return;
		}
		GameHudRetry = 1.f;
		HANDLE Map = OpenFileMappingW(FILE_MAP_READ, 0, L"Local\\BioShockLiveHud");
		if (!Map)
		{
			return;
		}
		GameHudMapping = Map;
		GameHudView = static_cast<const uint8*>(MapViewOfFile(Map, FILE_MAP_READ, 0, 0, 0));
		if (!GameHudView)
		{
			return;
		}
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_LIVE game HUD stream found"));
	}
	const FHeader* H = reinterpret_cast<const FHeader*>(GameHudView);
	const int32 Seq = H->Seq;
	// Show the stream only while it is live (the proxy writes it only while the game's world is
	// suppressed); otherwise fall back to the rebuilt HUD.
	const double Now = GetWorld() ? GetWorld()->GetTimeSeconds() : 0.0;
	if (bGameHud && Now - GameHudLastNew > 1.0)
	{
		bGameHud = false;
		if (GameHudOverlay)
		{
			GameHudOverlay->SetVisibility(EVisibility::Collapsed);
		}
		if (Hud && !Hud->IsInViewport())
		{
			Hud->AddToViewport();
		}
	}
	if (H->Magic != 0x48554431 || (Seq & 1) || Seq == GameHudSeq || H->Width == 0 || H->Width > 3840 || H->Height > 2160)
	{
		return;
	}
	const uint32 W = H->Width, Ht = H->Height, Pitch = H->Pitch;
	uint8* Pixels = static_cast<uint8*>(FMemory::Malloc(W * Ht * 4));
	uint32 Lit = 0, Sampled = 0;
	for (uint32 Y = 0; Y < Ht; ++Y)
	{
		const uint8* Row = GameHudView + sizeof(FHeader) + Y * Pitch;
		FMemory::Memcpy(Pixels + Y * W * 4, Row, W * 4);
		if ((Y & 15) == 0)
		{
			for (uint32 X = 0; X < W; X += 16, ++Sampled)
			{
				Lit += (FMath::Max3(Row[X * 4], Row[X * 4 + 1], Row[X * 4 + 2]) > 8) ? 1 : 0;
			}
		}
	}
	// Normal play lights ~1% of the frame; the pause menu ~24%, the map ~58% (7 Oct 2026). Those
	// cover the view in the game, so draw them opaque instead of keying out their dark parts.
	const bool bFullScreenUi = Sampled && Lit * 10 > Sampled;
	if (H->Seq != Seq)  // rewritten while we copied
	{
		FMemory::Free(Pixels);
		return;
	}
	const bool bFirst = GameHudSeq < 0;
	GameHudSeq = Seq;
	if (bFirst)  // a frame left in the mapping from an earlier session: wait for a new one
	{
		FMemory::Free(Pixels);
		return;
	}
	GameHudLastNew = Now;
	if (!bGameHud && GameHudOverlay)
	{
		bGameHud = true;
		GameHudOverlay->SetVisibility(EVisibility::HitTestInvisible);
		if (Hud)
		{
			Hud->RemoveFromParent();
		}
	}
	if (!GameHudTexture || GameHudTexture->GetSizeX() != int32(W) || GameHudTexture->GetSizeY() != int32(Ht))
	{
		GameHudTexture = UTexture2D::CreateTransient(W, Ht, PF_R8G8B8A8);
		GameHudTexture->SRGB = true;
		GameHudTexture->UpdateResource();
		if (UMaterialInterface* Mat = LoadObject<UMaterialInterface>(nullptr, TEXT("/Game/BioShockLive/M_LiveHud.M_LiveHud")))
		{
			GameHudMid = UMaterialInstanceDynamic::Create(Mat, this);
			GameHudMid->SetTextureParameterValue(TEXT("Hud"), GameHudTexture);
		}
		if (GameHudMid && GEngine && GEngine->GameViewport && !GameHudOverlay)
		{
			GameHudBrush.SetResourceObject(GameHudMid);
			GameHudBrush.ImageSize = FVector2D(W, Ht);
			GameHudBrush.DrawAs = ESlateBrushDrawType::Image;
			GameHudOverlay = SNew(SImage).Image(&GameHudBrush);
			GEngine->GameViewport->AddViewportWidgetContent(GameHudOverlay.ToSharedRef(), 100);
			bGameHud = true;
			if (Hud)
			{
				Hud->RemoveFromParent();
			}
			UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_LIVE game HUD overlay %ux%u"), W, Ht);
		}
	}
	if (GameHudMid)
	{
		GameHudMid->SetScalarParameterValue(TEXT("Opaque"), bFullScreenUi ? 1.f : 0.f);
	}
	FUpdateTextureRegion2D* Region = new FUpdateTextureRegion2D(0, 0, 0, 0, W, Ht);
	GameHudTexture->UpdateTextureRegions(0, 1, Region, W * 4, 4, Pixels,
		[](uint8* Data, const FUpdateTextureRegion2D* R) { FMemory::Free(Data); delete R; });
}
