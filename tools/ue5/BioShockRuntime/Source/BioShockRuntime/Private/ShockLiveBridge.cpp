#include "ShockLiveBridge.h"

#include "Camera/CameraActor.h"
#include "Camera/CameraComponent.h"
#include "Common/UdpSocketBuilder.h"
#include "Components/SceneCaptureComponent2D.h"
#include "Engine/SceneCapture2D.h"
#include "Engine/TextureRenderTarget2D.h"
#include "Engine/World.h"
#include "EngineUtils.h"
#include "GameFramework/PlayerController.h"
#include "HAL/FileManager.h"
#include "Interfaces/IPv4/IPv4Endpoint.h"
#include "Kismet/KismetRenderingLibrary.h"
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

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	Camera = InWorld.SpawnActor<ACameraActor>(FVector::ZeroVector, FRotator::ZeroRotator, Params);
	if (Camera)
	{
		Camera->GetCameraComponent()->bConstrainAspectRatio = false;
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
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_LIVE frame=%lld game_t=%.2f lines=%lld moves=%lld unknown_keys=%d"),
			LastFrame, LastGameSeconds, Lines, Moves, UnknownKeys.Num());
	}
	if (ExitAfter > 0.f && RunClock >= ExitAfter)
	{
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_LIVE done frame=%lld lines=%lld moves=%lld unknown_keys=%d"),
			LastFrame, Lines, Moves, UnknownKeys.Num());
		bActive = false;
		FGenericPlatformMisc::RequestExit(false);
	}
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
	Comp->CaptureScene();
	UKismetRenderingLibrary::ExportRenderTarget(World, Target, CaptureDir,
		FString::Printf(TEXT("ue_%06lld.png"), LastFrame));
}
