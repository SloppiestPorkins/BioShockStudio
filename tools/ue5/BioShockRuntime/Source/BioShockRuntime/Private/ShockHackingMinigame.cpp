#include "ShockHackingMinigame.h"

#include "Blueprint/WidgetTree.h"
#include "Components/Button.h"
#include "Components/HorizontalBox.h"
#include "Components/HorizontalBoxSlot.h"
#include "Components/Image.h"
#include "Components/SizeBox.h"
#include "Components/TextBlock.h"
#include "Components/UniformGridPanel.h"
#include "Components/UniformGridSlot.h"
#include "Components/VerticalBox.h"
#include "Components/VerticalBoxSlot.h"
#include "Engine/Engine.h"
#include "Engine/Texture2D.h"
#include "Engine/World.h"
#include "GameFramework/PlayerController.h"
#include "InputCoreTypes.h"
#include "ShockPlayer.h"
#include "ShockSecurityDeviceTypes.h"
#include "ShockTurret.h"

FString UShockHackingMinigame::LastHackingMinigameVerifyError;

namespace ShockHackPrivate
{
	constexpr uint8 N = 1;
	constexpr uint8 E = 2;
	constexpr uint8 S = 4;
	constexpr uint8 W = 8;

	uint8 RotatePorts(uint8 Ports, int32 Rot)
	{
		Rot = ((Rot % 4) + 4) % 4;
		uint8 Out = Ports;
		for (int32 i = 0; i < Rot; ++i)
		{
			Out = ((Out & N) ? E : 0) | ((Out & E) ? S : 0) | ((Out & S) ? W : 0) | ((Out & W) ? N : 0);
		}
		return Out;
	}

	uint8 CanonicalPorts(EShockHackTileType Type)
	{
		switch (Type)
		{
		case EShockHackTileType::Straight:
			return N | S;
		case EShockHackTileType::Elbow:
			return N | E;
		case EShockHackTileType::Tee:
			return N | E | S;
		case EShockHackTileType::Cross:
			return N | E | S | W;
		case EShockHackTileType::Source:
			return E;
		case EShockHackTileType::Target:
			return W;
		default:
			return 0;
		}
	}

	uint8 Opposite(uint8 Dir)
	{
		switch (Dir)
		{
		case N:
			return S;
		case E:
			return W;
		case S:
			return N;
		case W:
			return E;
		default:
			return 0;
		}
	}

	FString TileLabel(const FShockHackTile& Tile)
	{
		if (!Tile.bRevealed)
		{
			return TEXT("?");
		}
		const TCHAR* Base = TEXT(".");
		switch (Tile.Type)
		{
		case EShockHackTileType::Straight:
			Base = (Tile.Rotation % 2 == 0) ? TEXT("|") : TEXT("-");
			break;
		case EShockHackTileType::Elbow:
			Base = TEXT("L");
			break;
		case EShockHackTileType::Tee:
			Base = TEXT("T");
			break;
		case EShockHackTileType::Cross:
			Base = TEXT("+");
			break;
		case EShockHackTileType::Source:
			Base = TEXT("S");
			break;
		case EShockHackTileType::Target:
			Base = TEXT("G");
			break;
		default:
			break;
		}
		FString Out(Base);
		if (Tile.Hazard == EShockHackHazard::SpeedUp)
		{
			Out += TEXT("!");
		}
		else if (Tile.Hazard == EShockHackHazard::Overload)
		{
			Out += TEXT("X");
		}
		else if (Tile.Hazard == EShockHackHazard::Alarm)
		{
			Out += TEXT("A");
		}
		return Out;
	}

	FLinearColor TileColor(const FShockHackTile& Tile, bool bOnPath, bool bSelected)
	{
		if (!Tile.bRevealed)
		{
			return FLinearColor(0.15f, 0.15f, 0.18f, 1.0f);
		}
		FLinearColor C(0.25f, 0.35f, 0.4f, 1.0f);
		switch (Tile.Type)
		{
		case EShockHackTileType::Source:
			C = FLinearColor(0.2f, 0.75f, 0.35f, 1.0f);
			break;
		case EShockHackTileType::Target:
			C = FLinearColor(0.85f, 0.7f, 0.2f, 1.0f);
			break;
		case EShockHackTileType::Empty:
			C = FLinearColor(0.12f, 0.12f, 0.14f, 1.0f);
			break;
		default:
			break;
		}
		if (Tile.Hazard == EShockHackHazard::Overload)
		{
			C = FLinearColor(0.7f, 0.15f, 0.1f, 1.0f);
		}
		else if (Tile.Hazard == EShockHackHazard::Alarm)
		{
			C = FLinearColor(0.75f, 0.55f, 0.1f, 1.0f);
		}
		else if (Tile.Hazard == EShockHackHazard::SpeedUp)
		{
			C = FLinearColor(0.2f, 0.55f, 0.85f, 1.0f);
		}
		if (bOnPath)
		{
			C = FMath::Lerp(C, FLinearColor(0.15f, 0.9f, 0.35f, 1.0f), 0.55f);
		}
		if (bSelected)
		{
			C = FMath::Lerp(C, FLinearColor(1.0f, 1.0f, 1.0f, 1.0f), 0.35f);
		}
		return C;
	}
}

UShockHackingMinigame::UShockHackingMinigame(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	SetVisibility(ESlateVisibility::Collapsed);
	SetIsFocusable(true);
}

FString UShockHackingMinigame::GetLastHackingMinigameVerifyError()
{
	return LastHackingMinigameVerifyError;
}

void UShockHackingMinigame::BindDisplayPlayer(AShockPlayer* Player)
{
	DisplayPlayerOverride = Player;
}

void UShockHackingMinigame::BindDevice(AShockSecurityDevice* Device)
{
	BoundDevice = Device;
}

AShockPlayer* UShockHackingMinigame::ResolvePlayer() const
{
	if (AShockPlayer* Override = DisplayPlayerOverride.Get())
	{
		return Override;
	}
	if (APlayerController* PC = GetOwningPlayer())
	{
		return Cast<AShockPlayer>(PC->GetPawn());
	}
	return nullptr;
}

AShockSecurityDevice* UShockHackingMinigame::ResolveDevice() const
{
	return BoundDevice.Get();
}

void UShockHackingMinigame::EnsureTextures()
{
	if (!BezelTexture)
	{
		BezelTexture = LoadObject<UTexture2D>(
			nullptr, TEXT("/Game/BioShockUI/Hacking/T_Hack_Bezel.T_Hack_Bezel"));
	}
	if (!HazardStripTexture)
	{
		HazardStripTexture = LoadObject<UTexture2D>(
			nullptr, TEXT("/Game/BioShockUI/Hacking/T_Hack_HazardStrip.T_Hack_HazardStrip"));
	}
	if (!BannerTexture)
	{
		BannerTexture = LoadObject<UTexture2D>(
			nullptr, TEXT("/Game/BioShockUI/Hacking/T_Hack_Banner.T_Hack_Banner"));
	}
	if (!RingTexture)
	{
		RingTexture = LoadObject<UTexture2D>(
			nullptr, TEXT("/Game/BioShockUI/Hacking/T_Hack_Ring.T_Hack_Ring"));
	}
}

void UShockHackingMinigame::EnsureWidgetTree()
{
	if (!WidgetTree || RootColumn)
	{
		return;
	}

	RootColumn = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(), TEXT("HackRoot"));
	WidgetTree->RootWidget = RootColumn;

	BezelImage = WidgetTree->ConstructWidget<UImage>(UImage::StaticClass(), TEXT("HackBezel"));
	BezelImage->SetDesiredSizeOverride(FVector2D(640.0f, 96.0f));
	if (UVerticalBoxSlot* BezelSlot = RootColumn->AddChildToVerticalBox(BezelImage))
	{
		BezelSlot->SetHorizontalAlignment(HAlign_Center);
		BezelSlot->SetPadding(FMargin(24.0f, 28.0f, 24.0f, 4.0f));
	}

	HazardStripImage =
		WidgetTree->ConstructWidget<UImage>(UImage::StaticClass(), TEXT("HackHazardStrip"));
	HazardStripImage->SetDesiredSizeOverride(FVector2D(560.0f, 48.0f));
	if (UVerticalBoxSlot* StripSlot = RootColumn->AddChildToVerticalBox(HazardStripImage))
	{
		StripSlot->SetHorizontalAlignment(HAlign_Center);
		StripSlot->SetPadding(FMargin(8.0f, 4.0f));
	}

	TitleText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("HackTitle"));
	TitleText->SetText(FText::FromString(TEXT("Hacking (pipe puzzle — UMG pipe shapes)")));
	if (UVerticalBoxSlot* TitleSlot = RootColumn->AddChildToVerticalBox(TitleText))
	{
		TitleSlot->SetHorizontalAlignment(HAlign_Center);
		TitleSlot->SetPadding(FMargin(8.0f, 6.0f));
	}

	StatusText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("HackStatus"));
	if (UVerticalBoxSlot* StatusSlot = RootColumn->AddChildToVerticalBox(StatusText))
	{
		StatusSlot->SetHorizontalAlignment(HAlign_Center);
		StatusSlot->SetPadding(FMargin(8.0f, 2.0f));
	}

	BoardGrid =
		WidgetTree->ConstructWidget<UUniformGridPanel>(UUniformGridPanel::StaticClass(), TEXT("HackBoard"));
	if (UVerticalBoxSlot* GridSlot = RootColumn->AddChildToVerticalBox(BoardGrid))
	{
		GridSlot->SetHorizontalAlignment(HAlign_Center);
		GridSlot->SetPadding(FMargin(16.0f, 8.0f));
	}

	OptionsRow =
		WidgetTree->ConstructWidget<UHorizontalBox>(UHorizontalBox::StaticClass(), TEXT("HackOptions"));
	if (UVerticalBoxSlot* OptSlot = RootColumn->AddChildToVerticalBox(OptionsRow))
	{
		OptSlot->SetHorizontalAlignment(HAlign_Center);
		OptSlot->SetPadding(FMargin(8.0f, 10.0f));
	}
}

TSharedRef<SWidget> UShockHackingMinigame::RebuildWidget()
{
	EnsureWidgetTree();
	return Super::RebuildWidget();
}

void UShockHackingMinigame::NativeConstruct()
{
	Super::NativeConstruct();
	EnsureWidgetTree();
}

void UShockHackingMinigame::SetPaused(bool bPause)
{
	// Do not SetGamePaused — fluid must keep advancing while the modal is up.
	bDidPause = bPause;
	if (APlayerController* PC = GetOwningPlayer())
	{
		PC->bShowMouseCursor = bPause;
		if (bPause)
		{
			FInputModeGameAndUI Mode;
			Mode.SetWidgetToFocus(TakeWidget());
			Mode.SetLockMouseToViewportBehavior(EMouseLockMode::DoNotLock);
			PC->SetInputMode(Mode);
		}
		else
		{
			FInputModeGameOnly Mode;
			PC->SetInputMode(Mode);
		}
	}
}

int32 UShockHackingMinigame::IndexAt(int32 X, int32 Y) const
{
	return Y * BoardWidth + X;
}

bool UShockHackingMinigame::InBounds(int32 X, int32 Y) const
{
	return X >= 0 && Y >= 0 && X < BoardWidth && Y < BoardHeight;
}

uint8 UShockHackingMinigame::PortsForTile(const FShockHackTile& Tile) const
{
	return ShockHackPrivate::RotatePorts(
		ShockHackPrivate::CanonicalPorts(Tile.Type), Tile.Rotation);
}

bool UShockHackingMinigame::TilesConnect(int32 IndexA, int32 IndexB) const
{
	if (!Tiles.IsValidIndex(IndexA) || !Tiles.IsValidIndex(IndexB))
	{
		return false;
	}
	const FShockHackTile& A = Tiles[IndexA];
	const FShockHackTile& B = Tiles[IndexB];
	if (!A.bRevealed || !B.bRevealed)
	{
		return false;
	}
	if (A.Type == EShockHackTileType::Empty || B.Type == EShockHackTileType::Empty)
	{
		return false;
	}

	const int32 AX = IndexA % BoardWidth;
	const int32 AY = IndexA / BoardWidth;
	const int32 BX = IndexB % BoardWidth;
	const int32 BY = IndexB / BoardWidth;
	const int32 DX = BX - AX;
	const int32 DY = BY - AY;
	uint8 Dir = 0;
	if (DX == 1 && DY == 0)
	{
		Dir = ShockHackPrivate::E;
	}
	else if (DX == -1 && DY == 0)
	{
		Dir = ShockHackPrivate::W;
	}
	else if (DX == 0 && DY == 1)
	{
		Dir = ShockHackPrivate::S;
	}
	else if (DX == 0 && DY == -1)
	{
		Dir = ShockHackPrivate::N;
	}
	else
	{
		return false;
	}

	const uint8 PortsA = PortsForTile(A);
	const uint8 PortsB = PortsForTile(B);
	return (PortsA & Dir) != 0 && (PortsB & ShockHackPrivate::Opposite(Dir)) != 0;
}

bool UShockHackingMinigame::FindPath(TArray<int32>& OutPath) const
{
	OutPath.Reset();
	if (SourceIndex == INDEX_NONE || TargetIndex == INDEX_NONE || !Tiles.IsValidIndex(SourceIndex))
	{
		return false;
	}

	TArray<int32> CameFrom;
	CameFrom.Init(INDEX_NONE, Tiles.Num());
	TArray<int32> Queue;
	Queue.Add(SourceIndex);
	CameFrom[SourceIndex] = SourceIndex;

	while (Queue.Num() > 0)
	{
		const int32 Cur = Queue[0];
		Queue.RemoveAt(0);
		if (Cur == TargetIndex)
		{
			break;
		}
		const int32 CX = Cur % BoardWidth;
		const int32 CY = Cur / BoardWidth;
		static const uint8 Dirs[4] = {
			ShockHackPrivate::N, ShockHackPrivate::E, ShockHackPrivate::S, ShockHackPrivate::W};
		for (uint8 Dir : Dirs)
		{
			const int32 NX = CX
				+ ((Dir == ShockHackPrivate::E) ? 1 : (Dir == ShockHackPrivate::W) ? -1 : 0);
			const int32 NY = CY
				+ ((Dir == ShockHackPrivate::S) ? 1 : (Dir == ShockHackPrivate::N) ? -1 : 0);
			if (!InBounds(NX, NY))
			{
				continue;
			}
			const int32 Ni = IndexAt(NX, NY);
			if (CameFrom[Ni] != INDEX_NONE)
			{
				continue;
			}
			if (!TilesConnect(Cur, Ni))
			{
				continue;
			}
			CameFrom[Ni] = Cur;
			Queue.Add(Ni);
		}
	}

	if (CameFrom[TargetIndex] == INDEX_NONE)
	{
		int32 Best = SourceIndex;
		int32 BestDepth = 0;
		for (int32 i = 0; i < CameFrom.Num(); ++i)
		{
			if (CameFrom[i] == INDEX_NONE)
			{
				continue;
			}
			int32 Depth = 0;
			int32 Walk = i;
			while (Walk != SourceIndex && CameFrom.IsValidIndex(Walk) && CameFrom[Walk] != INDEX_NONE
				&& Depth < Tiles.Num())
			{
				Walk = CameFrom[Walk];
				++Depth;
			}
			if (Depth > BestDepth)
			{
				BestDepth = Depth;
				Best = i;
			}
		}
		int32 Walk = Best;
		TArray<int32> Rev;
		while (true)
		{
			Rev.Add(Walk);
			if (Walk == SourceIndex)
			{
				break;
			}
			Walk = CameFrom[Walk];
			if (Walk == INDEX_NONE)
			{
				break;
			}
		}
		for (int32 i = Rev.Num() - 1; i >= 0; --i)
		{
			OutPath.Add(Rev[i]);
		}
		return false;
	}

	int32 Walk = TargetIndex;
	TArray<int32> Rev;
	while (true)
	{
		Rev.Add(Walk);
		if (Walk == SourceIndex)
		{
			break;
		}
		Walk = CameFrom[Walk];
	}
	for (int32 i = Rev.Num() - 1; i >= 0; --i)
	{
		OutPath.Add(Rev[i]);
	}
	return true;
}

bool UShockHackingMinigame::HasPathSourceToTarget() const
{
	TArray<int32> Path;
	return FindPath(Path);
}

void UShockHackingMinigame::RecomputePath()
{
	FindPath(CurrentPath);
}

int32 UShockHackingMinigame::GetFaceDownCount() const
{
	int32 Count = 0;
	for (const FShockHackTile& Tile : Tiles)
	{
		if (!Tile.bRevealed)
		{
			++Count;
		}
	}
	return Count;
}

void UShockHackingMinigame::ScaleParamsFromDifficulty(float Difficulty01)
{
	Difficulty = FMath::Clamp(Difficulty01, 0.0f, 1.0f);
	BoardWidth = 5 + FMath::RoundToInt(Difficulty * 2.0f);  // 5..7
	BoardHeight = 4 + FMath::RoundToInt(Difficulty * 2.0f); // 4..6
	FluidSpeed = 0.08f + Difficulty * 0.16f;
	BuyOutCost = 30 + FMath::RoundToInt(Difficulty * 70.0f);
	FluidDelayRemaining = 1.25f - Difficulty * 0.4f;
}

void UShockHackingMinigame::BuildBoardForDifficulty(float Difficulty01)
{
	ScaleParamsFromDifficulty(Difficulty01);
	Tiles.SetNum(BoardWidth * BoardHeight);
	SourceIndex = IndexAt(0, BoardHeight / 2);
	TargetIndex = IndexAt(BoardWidth - 1, BoardHeight / 2);

	const int32 Seed = 1000 + FMath::RoundToInt(Difficulty * 997.0f);
	FRandomStream Rng(Seed);

	for (int32 i = 0; i < Tiles.Num(); ++i)
	{
		FShockHackTile& Tile = Tiles[i];
		Tile = FShockHackTile();
		if (i == SourceIndex)
		{
			Tile.Type = EShockHackTileType::Source;
			Tile.Rotation = 0;
			Tile.bRevealed = true;
			continue;
		}
		if (i == TargetIndex)
		{
			Tile.Type = EShockHackTileType::Target;
			Tile.Rotation = 0;
			Tile.bRevealed = true;
			continue;
		}

		const int32 Roll = Rng.RandRange(0, 99);
		if (Roll < 35)
		{
			Tile.Type = EShockHackTileType::Straight;
		}
		else if (Roll < 70)
		{
			Tile.Type = EShockHackTileType::Elbow;
		}
		else if (Roll < 88)
		{
			Tile.Type = EShockHackTileType::Tee;
		}
		else if (Roll < 95)
		{
			Tile.Type = EShockHackTileType::Cross;
		}
		else
		{
			Tile.Type = EShockHackTileType::Empty;
		}
		Tile.Rotation = Rng.RandRange(0, 3);
		Tile.bRevealed = true;

		const int32 Hz = Rng.RandRange(0, 99);
		if (Hz < FMath::RoundToInt(4.0f + Difficulty * 10.0f))
		{
			const int32 Kind = Rng.RandRange(0, 2);
			Tile.Hazard = Kind == 0 ? EShockHackHazard::SpeedUp
				: (Kind == 1 ? EShockHackHazard::Alarm : EShockHackHazard::Overload);
		}
	}

	const int32 FaceDownBudget =
		FMath::RoundToInt(static_cast<float>(Tiles.Num()) * (0.15f + Difficulty * 0.35f));
	int32 Faced = 0;
	int32 Attempts = 0;
	while (Faced < FaceDownBudget && Attempts < Tiles.Num() * 8)
	{
		++Attempts;
		const int32 Idx = Rng.RandRange(0, Tiles.Num() - 1);
		if (Idx == SourceIndex || Idx == TargetIndex || !Tiles[Idx].bRevealed)
		{
			continue;
		}
		Tiles[Idx].bRevealed = false;
		++Faced;
	}

	RecomputePath();
}

void UShockHackingMinigame::BuildScriptedWinBoard(TArray<int32>& OutSwapA, TArray<int32>& OutSwapB)
{
	OutSwapA.Reset();
	OutSwapB.Reset();
	Difficulty = 0.25f;
	BoardWidth = 5;
	BoardHeight = 4;
	FluidSpeed = 0.6f;
	FluidDelayRemaining = 0.0f;
	BuyOutCost = 40;
	Tiles.SetNum(BoardWidth * BoardHeight);
	for (FShockHackTile& Tile : Tiles)
	{
		Tile = FShockHackTile();
		Tile.Type = EShockHackTileType::Empty;
		Tile.bRevealed = true;
	}

	const int32 Mid = 1;
	SourceIndex = IndexAt(0, Mid);
	TargetIndex = IndexAt(4, Mid);
	Tiles[SourceIndex].Type = EShockHackTileType::Source;
	Tiles[TargetIndex].Type = EShockHackTileType::Target;

	for (int32 X = 1; X <= 3; ++X)
	{
		const int32 Wrong = IndexAt(X, Mid);
		const int32 Right = IndexAt(X, Mid + 1);
		Tiles[Wrong].Type = EShockHackTileType::Straight;
		Tiles[Wrong].Rotation = 0; // N-S
		Tiles[Right].Type = EShockHackTileType::Straight;
		Tiles[Right].Rotation = 1; // E-W
		OutSwapA.Add(Wrong);
		OutSwapB.Add(Right);
	}

	BeginPlaying();
	RebuildBoardVisual();
}

void UShockHackingMinigame::BuildScriptedLoseBoard()
{
	Difficulty = 0.25f;
	BoardWidth = 5;
	BoardHeight = 3;
	FluidSpeed = 0.4f;
	FluidDelayRemaining = 0.0f;
	Tiles.SetNum(BoardWidth * BoardHeight);
	for (FShockHackTile& Tile : Tiles)
	{
		Tile = FShockHackTile();
		Tile.Type = EShockHackTileType::Empty;
		Tile.bRevealed = true;
	}
	SourceIndex = IndexAt(0, 1);
	TargetIndex = IndexAt(4, 1);
	Tiles[SourceIndex].Type = EShockHackTileType::Source;
	Tiles[TargetIndex].Type = EShockHackTileType::Target;
	Tiles[IndexAt(1, 1)].Type = EShockHackTileType::Straight;
	Tiles[IndexAt(1, 1)].Rotation = 1;
	BeginPlaying();
	RebuildBoardVisual();
}

void UShockHackingMinigame::BuildScriptedAlarmBoard()
{
	Difficulty = 0.25f;
	BoardWidth = 5;
	BoardHeight = 3;
	FluidSpeed = 0.45f;
	FluidDelayRemaining = 0.0f;
	Tiles.SetNum(BoardWidth * BoardHeight);
	for (FShockHackTile& Tile : Tiles)
	{
		Tile = FShockHackTile();
		Tile.Type = EShockHackTileType::Empty;
		Tile.bRevealed = true;
	}
	SourceIndex = IndexAt(0, 1);
	TargetIndex = IndexAt(4, 1);
	Tiles[SourceIndex].Type = EShockHackTileType::Source;
	Tiles[TargetIndex].Type = EShockHackTileType::Target;
	for (int32 X = 1; X <= 3; ++X)
	{
		const int32 Idx = IndexAt(X, 1);
		Tiles[Idx].Type = EShockHackTileType::Straight;
		Tiles[Idx].Rotation = 1;
	}
	Tiles[IndexAt(2, 1)].Hazard = EShockHackHazard::Alarm;
	BeginPlaying();
	RebuildBoardVisual();
}

void UShockHackingMinigame::BeginPlaying()
{
	Result = EShockHackResult::Playing;
	FluidProgress = 0.0f;
	SpeedMultiplier = 1.0f;
	bDidSetSecurityHacked = false;
	bDidRaiseAlarm = false;
	bAlarmTriggered = false;
	HazardsTriggered.Reset();
	SelectedTileIndex = INDEX_NONE;
	RecomputePath();
	RefreshStatusText();
}

void UShockHackingMinigame::ApplyHackSuccessToWorld()
{
	AShockPlayer* Player = ResolvePlayer();
	if (!Player)
	{
		return;
	}

	if (AShockSecurityDevice* Device = ResolveDevice())
	{
		Device->SetAllegiance(EShockDeviceAllegiance::Friendly);
		const FName Label = Device->DeviceLabel.IsNone() ? Device->GetFName() : Device->DeviceLabel;
		Player->SetTurretHacked(Label, true);
	}

	Player->SetSecurityHacked(true, HackShutdownSeconds);
	bDidSetSecurityHacked = true;
}

void UShockHackingMinigame::FinishWin()
{
	if (Result != EShockHackResult::Playing)
	{
		return;
	}
	Result = EShockHackResult::Won;
	ApplyHackSuccessToWorld();
	RefreshStatusText();
	RebuildBoardVisual();
}

void UShockHackingMinigame::FinishFail(bool bFromOverload)
{
	if (Result != EShockHackResult::Playing)
	{
		return;
	}
	Result = EShockHackResult::Failed;
	if (AShockPlayer* Player = ResolvePlayer())
	{
		Player->ApplyAuthoredDamage(bFromOverload ? OverloadDamage : 5.0f);
	}
	RefreshStatusText();
	RebuildBoardVisual();
}

bool UShockHackingMinigame::RevealTile(int32 Index)
{
	if (Result != EShockHackResult::Playing || !Tiles.IsValidIndex(Index))
	{
		return false;
	}
	if (Tiles[Index].bRevealed)
	{
		return false;
	}
	Tiles[Index].bRevealed = true;
	RecomputePath();
	RebuildBoardVisual();
	return true;
}

bool UShockHackingMinigame::SwapTiles(int32 IndexA, int32 IndexB)
{
	if (Result != EShockHackResult::Playing)
	{
		return false;
	}
	if (!Tiles.IsValidIndex(IndexA) || !Tiles.IsValidIndex(IndexB) || IndexA == IndexB)
	{
		return false;
	}
	const int32 AX = IndexA % BoardWidth;
	const int32 AY = IndexA / BoardWidth;
	const int32 BX = IndexB % BoardWidth;
	const int32 BY = IndexB / BoardWidth;
	if (FMath::Abs(AX - BX) + FMath::Abs(AY - BY) != 1)
	{
		return false;
	}
	if (IndexA == SourceIndex || IndexA == TargetIndex || IndexB == SourceIndex
		|| IndexB == TargetIndex)
	{
		return false;
	}
	if (!Tiles[IndexA].bRevealed || !Tiles[IndexB].bRevealed)
	{
		return false;
	}

	const FShockHackTile Tmp = Tiles[IndexA];
	Tiles[IndexA] = Tiles[IndexB];
	Tiles[IndexB] = Tmp;
	RecomputePath();
	RebuildBoardVisual();
	return true;
}

void UShockHackingMinigame::AdvanceMinigame(float DeltaSeconds)
{
	if (!bOpen || Result != EShockHackResult::Playing || DeltaSeconds <= 0.0f)
	{
		return;
	}

	if (FluidDelayRemaining > 0.0f)
	{
		FluidDelayRemaining -= DeltaSeconds;
		RefreshStatusText();
		return;
	}

	RecomputePath();
	if (CurrentPath.Num() < 2)
	{
		FinishFail(false);
		return;
	}

	const float PathLen = static_cast<float>(CurrentPath.Num() - 1);
	FluidProgress += FluidSpeed * SpeedMultiplier * DeltaSeconds;

	const float Clamped = FMath::Clamp(FluidProgress, 0.0f, PathLen + 0.001f);
	const int32 Seg = FMath::Clamp(FMath::FloorToInt(Clamped), 0, CurrentPath.Num() - 1);
	for (int32 i = 0; i <= Seg; ++i)
	{
		const int32 Idx = CurrentPath[i];
		if (!Tiles.IsValidIndex(Idx) || HazardsTriggered.Contains(Idx))
		{
			continue;
		}
		HazardsTriggered.Add(Idx);
		const EShockHackHazard Hz = Tiles[Idx].Hazard;
		if (Hz == EShockHackHazard::SpeedUp)
		{
			SpeedMultiplier *= 1.75f;
		}
		else if (Hz == EShockHackHazard::Alarm)
		{
			if (AShockPlayer* Player = ResolvePlayer())
			{
				Player->SetSecurityAlarmOn(true, FName(TEXT("HackMinigame")));
				bDidRaiseAlarm = true;
				bAlarmTriggered = true;
			}
		}
		else if (Hz == EShockHackHazard::Overload)
		{
			FinishFail(true);
			return;
		}
	}

	TArray<int32> FullPath;
	const bool bComplete = FindPath(FullPath);
	if (bComplete && FluidProgress >= static_cast<float>(FullPath.Num() - 1) - KINDA_SMALL_NUMBER)
	{
		FluidProgress = static_cast<float>(FullPath.Num() - 1);
		FinishWin();
		return;
	}

	if (!bComplete && FluidProgress >= PathLen - KINDA_SMALL_NUMBER)
	{
		FinishFail(false);
		return;
	}

	RefreshStatusText();
	RebuildBoardVisual();
}

bool UShockHackingMinigame::TryBuyOut()
{
	if (!bOpen || Result != EShockHackResult::Playing)
	{
		return false;
	}
	AShockPlayer* Player = ResolvePlayer();
	if (!Player || !Player->SpendMoney(BuyOutCost))
	{
		RefreshStatusText();
		return false;
	}
	FinishWin();
	return true;
}

bool UShockHackingMinigame::TryAutoHack()
{
	if (!bOpen || Result != EShockHackResult::Playing)
	{
		return false;
	}
	AShockPlayer* Player = ResolvePlayer();
	if (!Player)
	{
		return false;
	}
	// Auto-Hack needs an Auto-Hack Tool in the inventory — no free wins.
	if (Player->GetInventoryStack(AutoHackItemClass) <= 0)
	{
		if (StatusText)
		{
			StatusText->SetText(FText::FromString(TEXT("NO AUTO-HACK TOOL")));
		}
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_HACK autohack=denied reason=no_tool"));
		return false;
	}
	Player->RemoveStackFromInventory(AutoHackItemClass, 1);
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_HACK autohack=used tool=%s"), *AutoHackItemClass.ToString());
	FinishWin();
	return true;
}

void UShockHackingMinigame::RefreshStatusText()
{
	if (!StatusText)
	{
		return;
	}
	AShockPlayer* Player = ResolvePlayer();
	const int32 Money = Player ? Player->GetMoney() : 0;
	FString Line;
	switch (Result)
	{
	case EShockHackResult::Won:
		Line = TEXT("HACK SUCCESS");
		break;
	case EShockHackResult::Failed:
		Line = TEXT("HACK FAILED");
		break;
	default:
		Line = FString::Printf(
			TEXT("fluid=%.2f speed=%.2f path=%d money=%d buyout=%d facedown=%d"),
			FluidProgress,
			FluidSpeed * SpeedMultiplier,
			CurrentPath.Num(),
			Money,
			BuyOutCost,
			GetFaceDownCount());
		break;
	}
	StatusText->SetText(FText::FromString(Line));
}

void UShockHackingMinigame::RebuildBoardVisual()
{
	EnsureWidgetTree();
	EnsureTextures();
	if (BezelImage)
	{
		if (BezelTexture)
		{
			BezelImage->SetBrushFromTexture(BezelTexture, true);
		}
		else
		{
			BezelImage->SetColorAndOpacity(FLinearColor(0.35f, 0.4f, 0.48f, 1.0f));
		}
	}
	if (HazardStripImage)
	{
		if (HazardStripTexture)
		{
			HazardStripImage->SetBrushFromTexture(HazardStripTexture, true);
		}
		else
		{
			HazardStripImage->SetColorAndOpacity(FLinearColor(0.45f, 0.2f, 0.15f, 1.0f));
		}
	}
	if (!BoardGrid)
	{
		return;
	}
	BoardGrid->ClearChildren();

	TSet<int32> OnPath;
	const int32 FluidSeg =
		FMath::Clamp(FMath::FloorToInt(FluidProgress), 0, FMath::Max(0, CurrentPath.Num() - 1));
	for (int32 i = 0; i <= FluidSeg && i < CurrentPath.Num(); ++i)
	{
		OnPath.Add(CurrentPath[i]);
	}

	for (int32 Y = 0; Y < BoardHeight; ++Y)
	{
		for (int32 X = 0; X < BoardWidth; ++X)
		{
			const int32 Idx = IndexAt(X, Y);
			if (!Tiles.IsValidIndex(Idx))
			{
				continue;
			}
			USizeBox* Cell = WidgetTree->ConstructWidget<USizeBox>(USizeBox::StaticClass());
			Cell->SetWidthOverride(48.0f);
			Cell->SetHeightOverride(48.0f);

			UButton* Btn = WidgetTree->ConstructWidget<UButton>(UButton::StaticClass());
			FButtonStyle Style = Btn->GetStyle();
			FSlateBrush Normal = Style.Normal;
			Normal.TintColor = FSlateColor(ShockHackPrivate::TileColor(
				Tiles[Idx], OnPath.Contains(Idx), Idx == SelectedTileIndex));
			Style.Normal = Normal;
			Style.Hovered = Normal;
			Style.Pressed = Normal;
			Btn->SetStyle(Style);

			UTextBlock* Label = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass());
			Label->SetText(FText::FromString(ShockHackPrivate::TileLabel(Tiles[Idx])));
			Label->SetJustification(ETextJustify::Center);
			Btn->AddChild(Label);
			Cell->AddChild(Btn);

			if (UUniformGridSlot* GridSlot = BoardGrid->AddChildToUniformGrid(Cell, Y, X))
			{
				GridSlot->SetHorizontalAlignment(HAlign_Center);
				GridSlot->SetVerticalAlignment(VAlign_Center);
			}
		}
	}

	if (OptionsRow)
	{
		OptionsRow->ClearChildren();
		auto AddOpt = [this](const FString& Text)
		{
			UTextBlock* Line = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass());
			Line->SetText(FText::FromString(Text));
			if (UHorizontalBoxSlot* OptSlot = OptionsRow->AddChildToHorizontalBox(Line))
			{
				OptSlot->SetPadding(FMargin(12.0f, 0.0f));
			}
		};
		AddOpt(FString::Printf(TEXT("[Buy-out $%d]"), BuyOutCost));
		AddOpt(TEXT("[Auto-Hack Tool]"));
		AddOpt(TEXT("(pipes = UMG shapes — vector sprites deferred)"));
	}
	RefreshStatusText();
}

void UShockHackingMinigame::OpenMinigame(float Difficulty01)
{
	bOpen = true;
	EnsureWidgetTree();
	EnsureTextures();
	BuildBoardForDifficulty(Difficulty01);
	BeginPlaying();
	RebuildBoardVisual();
	SetVisibility(ESlateVisibility::Visible);
	SetPaused(true);
	SetKeyboardFocus();
}

void UShockHackingMinigame::ForceOpenForCapture()
{
	bOpen = true;
	EnsureWidgetTree();
	EnsureTextures();
	if (Tiles.Num() == 0)
	{
		BuildBoardForDifficulty(0.5f);
		BeginPlaying();
	}
	RebuildBoardVisual();
	SetVisibility(ESlateVisibility::Visible);
}

void UShockHackingMinigame::CloseMinigame()
{
	bOpen = false;
	SetVisibility(ESlateVisibility::Collapsed);
	if (bDidPause)
	{
		SetPaused(false);
	}
}

void UShockHackingMinigame::NativeTick(const FGeometry& MyGeometry, float InDeltaTime)
{
	Super::NativeTick(MyGeometry, InDeltaTime);
	if (bOpen && Result == EShockHackResult::Playing && InDeltaTime > 0.0f)
	{
		AdvanceMinigame(InDeltaTime);
	}
}

FReply UShockHackingMinigame::NativeOnKeyDown(const FGeometry& InGeometry, const FKeyEvent& InKeyEvent)
{
	if (!bOpen)
	{
		return Super::NativeOnKeyDown(InGeometry, InKeyEvent);
	}
	if (InKeyEvent.GetKey() == EKeys::Escape)
	{
		CloseMinigame();
		return FReply::Handled();
	}
	if (InKeyEvent.GetKey() == EKeys::B && Result == EShockHackResult::Playing)
	{
		TryBuyOut();
		return FReply::Handled();
	}
	if (InKeyEvent.GetKey() == EKeys::H && Result == EShockHackResult::Playing)
	{
		TryAutoHack();
		return FReply::Handled();
	}
	return Super::NativeOnKeyDown(InGeometry, InKeyEvent);
}

bool UShockHackingMinigame::RunHeadlessHackingMinigameVerify(UObject* WorldContextObject)
{
	LastHackingMinigameVerifyError.Empty();

	UWorld* World = GEngine
		? GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::ReturnNull)
		: nullptr;
	if (!World)
	{
		LastHackingMinigameVerifyError = TEXT("no world");
		return false;
	}

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	AShockPlayer* Player = World->SpawnActor<AShockPlayer>(
		AShockPlayer::StaticClass(), FVector(40.0f, 60.0f, 100.0f), FRotator::ZeroRotator, Params);
	if (!Player)
	{
		LastHackingMinigameVerifyError = TEXT("spawn player failed");
		return false;
	}

	AShockTurret* Turret = World->SpawnActor<AShockTurret>(
		AShockTurret::StaticClass(), FVector(200.0f, 60.0f, 100.0f), FRotator::ZeroRotator, Params);
	if (!Turret)
	{
		Player->Destroy();
		LastHackingMinigameVerifyError = TEXT("spawn turret failed");
		return false;
	}
	Turret->ConfigureForVerify(FName(TEXT("HackMiniTurret")), 1 /*Hostile*/, 40.0f);

	auto Fail = [&](const FString& Msg) -> bool
	{
		LastHackingMinigameVerifyError = Msg;
		Turret->Destroy();
		Player->Destroy();
		return false;
	};

	Player->AddMoney(200);
	Player->EnsureHealthInitialized();

	UShockHackingMinigame* Menu =
		CreateWidget<UShockHackingMinigame>(World, UShockHackingMinigame::StaticClass());
	if (!Menu)
	{
		return Fail(TEXT("CreateWidget hacking minigame failed"));
	}
	Menu->BindDisplayPlayer(Player);
	Menu->BindDevice(Turret);

	Menu->OpenMinigame(0.1f);
	const int32 EasyW = Menu->GetBoardWidth();
	const int32 EasyH = Menu->GetBoardHeight();
	const int32 EasyFace = Menu->GetFaceDownCount();
	Menu->CloseMinigame();

	Menu->OpenMinigame(0.9f);
	const int32 HardW = Menu->GetBoardWidth();
	const int32 HardH = Menu->GetBoardHeight();
	const int32 HardFace = Menu->GetFaceDownCount();
	if (HardW < EasyW || HardH < EasyH)
	{
		Menu->RemoveFromParent();
		return Fail(TEXT("hard difficulty board not larger than easy"));
	}
	if (HardFace < EasyFace)
	{
		Menu->RemoveFromParent();
		return Fail(TEXT("hard difficulty should face-down at least as many tiles"));
	}
	Menu->CloseMinigame();

	TArray<int32> SwapA;
	TArray<int32> SwapB;
	Menu->OpenMinigame(0.25f);
	Menu->BuildScriptedWinBoard(SwapA, SwapB);
	if (SwapA.Num() == 0 || SwapA.Num() != SwapB.Num())
	{
		Menu->RemoveFromParent();
		return Fail(TEXT("scripted win board produced no swaps"));
	}
	if (Menu->HasPathSourceToTarget())
	{
		Menu->RemoveFromParent();
		return Fail(TEXT("scripted win board should start disconnected"));
	}
	for (int32 i = 0; i < SwapA.Num(); ++i)
	{
		if (!Menu->SwapTiles(SwapA[i], SwapB[i]))
		{
			Menu->RemoveFromParent();
			return Fail(FString::Printf(TEXT("swap %d failed"), i));
		}
	}
	if (!Menu->HasPathSourceToTarget())
	{
		Menu->RemoveFromParent();
		return Fail(TEXT("swaps did not create source-target path"));
	}
	for (int32 Step = 0; Step < 200 && Menu->GetResult() == EShockHackResult::Playing; ++Step)
	{
		Menu->AdvanceMinigame(0.1f);
	}
	if (Menu->GetResult() != EShockHackResult::Won || !Menu->DidCallSetSecurityHacked()
		|| !Player->IsSecurityHacked())
	{
		Menu->RemoveFromParent();
		return Fail(FString::Printf(
			TEXT("scripted win did not SetSecurityHacked (result=%d fluid=%.2f path=%d)"),
			static_cast<int32>(Menu->GetResult()),
			Menu->GetFluidProgress(),
			Menu->HasPathSourceToTarget() ? 1 : 0));
	}
	Menu->CloseMinigame();
	Player->SetSecurityHacked(false, 0.0f);

	Menu->OpenMinigame(0.25f);
	Menu->BuildScriptedLoseBoard();
	for (int32 Step = 0; Step < 80 && Menu->GetResult() == EShockHackResult::Playing; ++Step)
	{
		Menu->AdvanceMinigame(0.1f);
	}
	if (Menu->GetResult() != EShockHackResult::Failed || Menu->DidCallSetSecurityHacked()
		|| Player->IsSecurityHacked())
	{
		Menu->RemoveFromParent();
		return Fail(TEXT("scripted lose should fail without SetSecurityHacked"));
	}
	Menu->CloseMinigame();

	Player->SetSecurityAlarmOn(false, NAME_None);
	Menu->OpenMinigame(0.25f);
	Menu->BuildScriptedAlarmBoard();
	bool bSawAlarm = false;
	for (int32 Step = 0; Step < 80 && Menu->GetResult() == EShockHackResult::Playing; ++Step)
	{
		Menu->AdvanceMinigame(0.1f);
		if (Menu->DidRaiseAlarm())
		{
			bSawAlarm = true;
			break;
		}
	}
	if (!bSawAlarm)
	{
		Menu->RemoveFromParent();
		return Fail(TEXT("alarm hazard did not raise security alarm"));
	}
	Menu->CloseMinigame();
	Player->SetSecurityAlarmOn(false, NAME_None);
	Player->SetSecurityHacked(false, 0.0f);

	Menu->OpenMinigame(0.4f);
	Menu->BuildScriptedLoseBoard();
	const int32 MoneyBefore = Player->GetMoney();
	const int32 Cost = Menu->GetBuyOutCost();
	if (!Menu->TryBuyOut())
	{
		Menu->RemoveFromParent();
		return Fail(TEXT("TryBuyOut failed"));
	}
	if (Player->GetMoney() != MoneyBefore - Cost || !Menu->DidCallSetSecurityHacked())
	{
		Menu->RemoveFromParent();
		return Fail(TEXT("buy-out did not spend money / SetSecurityHacked"));
	}
	Menu->CloseMinigame();
	Menu->RemoveFromParent();

	Turret->Destroy();
	Player->Destroy();
	return true;
}
