#include "ShockLoadingScreen.h"

#include "Blueprint/WidgetTree.h"
#include "Components/Border.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Components/VerticalBoxSlot.h"
#include "Engine/Engine.h"
#include "Engine/World.h"
#include "Styling/CoreStyle.h"

FString UShockLoadingScreen::LastVerifyError;

namespace
{
FSlateFontInfo LoadFont(int32 Size, bool bBold = false)
{
	return FCoreStyle::GetDefaultFontStyle(bBold ? TEXT("Bold") : TEXT("Regular"), Size);
}

FLinearColor DecoGold() { return FLinearColor(0.92f, 0.78f, 0.35f, 1.0f); }
FLinearColor DecoCream() { return FLinearColor(0.92f, 0.88f, 0.75f, 1.0f); }

const TArray<FString>& LoadingTips()
{
	static const TArray<FString> Tips = {
		TEXT("Hack security devices to turn them against your foes."),
		TEXT("First Aid Kits restore health. Carry a few into every fight."),
		TEXT("Research enemies with the camera to unlock damage bonuses."),
		TEXT("Plasmids spend EVE. Hypo needles top it back up."),
		TEXT("Vending machines restock ammo — and sometimes plasmids."),
	};
	return Tips;
}
}

UShockLoadingScreen::UShockLoadingScreen(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	SetVisibility(ESlateVisibility::Collapsed);
}

FString UShockLoadingScreen::GetLastLoadingScreenVerifyError()
{
	return LastVerifyError;
}

FString UShockLoadingScreen::PrettyMapName(const FString& PackagePath)
{
	FString Name = PackagePath;
	int32 Slash = INDEX_NONE;
	if (Name.FindLastChar(TEXT('/'), Slash))
	{
		Name = Name.Mid(Slash + 1);
	}
	Name.ReplaceInline(TEXT("1-"), TEXT(""));
	Name.ReplaceInline(TEXT("0-"), TEXT(""));
	Name.ReplaceInline(TEXT("2-"), TEXT(""));
	Name.ReplaceInline(TEXT("3-"), TEXT(""));
	Name.ReplaceInline(TEXT("4-"), TEXT(""));
	Name.ReplaceInline(TEXT("5-"), TEXT(""));
	Name.ReplaceInline(TEXT("_"), TEXT(" "));
	return Name.IsEmpty() ? TEXT("Rapture") : Name;
}

void UShockLoadingScreen::EnsureWidgetTree()
{
	if (!WidgetTree || RootBorder)
	{
		return;
	}

	RootBorder = WidgetTree->ConstructWidget<UBorder>(UBorder::StaticClass(), TEXT("LoadRoot"));
	WidgetTree->RootWidget = RootBorder;
	RootBorder->SetBrushColor(FLinearColor(0.02f, 0.05f, 0.08f, 0.96f));
	RootBorder->SetPadding(FMargin(48.0f));

	Column = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(), TEXT("LoadColumn"));
	RootBorder->AddChild(Column);

	TitleText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("LoadTitle"));
	TitleText->SetFont(LoadFont(42, true));
	TitleText->SetColorAndOpacity(DecoGold());
	TitleText->SetJustification(ETextJustify::Center);
	if (UVerticalBoxSlot* BoxSlot = Column->AddChildToVerticalBox(TitleText))
	{
		BoxSlot->SetHorizontalAlignment(HAlign_Fill);
		BoxSlot->SetPadding(FMargin(0.0f, 120.0f, 0.0f, 24.0f));
	}

	EnteringText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("LoadEntering"));
	EnteringText->SetFont(LoadFont(24, false));
	EnteringText->SetColorAndOpacity(DecoCream());
	EnteringText->SetJustification(ETextJustify::Center);
	if (UVerticalBoxSlot* BoxSlot = Column->AddChildToVerticalBox(EnteringText))
	{
		BoxSlot->SetHorizontalAlignment(HAlign_Fill);
		BoxSlot->SetPadding(FMargin(0.0f, 8.0f, 0.0f, 48.0f));
	}

	TipText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("LoadTip"));
	TipText->SetFont(LoadFont(18, false));
	TipText->SetColorAndOpacity(FLinearColor(0.7f, 0.75f, 0.8f, 1.0f));
	TipText->SetJustification(ETextJustify::Center);
	if (UVerticalBoxSlot* BoxSlot = Column->AddChildToVerticalBox(TipText))
	{
		BoxSlot->SetHorizontalAlignment(HAlign_Fill);
		BoxSlot->SetPadding(FMargin(80.0f, 8.0f));
	}
}

TSharedRef<SWidget> UShockLoadingScreen::RebuildWidget()
{
	EnsureWidgetTree();
	return Super::RebuildWidget();
}

void UShockLoadingScreen::NativeConstruct()
{
	EnsureWidgetTree();
	Super::NativeConstruct();
}

void UShockLoadingScreen::NativeTick(const FGeometry& MyGeometry, float InDeltaTime)
{
	Super::NativeTick(MyGeometry, InDeltaTime);
	if (GetVisibility() == ESlateVisibility::Collapsed)
	{
		return;
	}
	TipTimer += InDeltaTime;
	if (TipTimer >= 4.0f)
	{
		TipTimer = 0.0f;
		RotateTip();
	}
}

void UShockLoadingScreen::RotateTip()
{
	const TArray<FString>& Tips = LoadingTips();
	if (Tips.Num() == 0)
	{
		return;
	}
	TipIndex = (TipIndex + 1) % Tips.Num();
	CurrentTip = Tips[TipIndex];
	if (TipText)
	{
		TipText->SetText(FText::FromString(CurrentTip));
	}
}

void UShockLoadingScreen::ShowForMap(const FString& MapPackagePath)
{
	EnsureWidgetTree();
	DisplayedLevelName = PrettyMapName(MapPackagePath);
	EnteringLine = FString::Printf(TEXT("Now entering %s"), *DisplayedLevelName);
	TipIndex = 0;
	CurrentTip = LoadingTips()[0];
	TipTimer = 0.0f;

	if (TitleText)
	{
		TitleText->SetText(FText::FromString(DisplayedLevelName));
	}
	if (EnteringText)
	{
		EnteringText->SetText(FText::FromString(EnteringLine));
	}
	if (TipText)
	{
		TipText->SetText(FText::FromString(CurrentTip));
	}

	SetVisibility(ESlateVisibility::Visible);
	if (UWorld* World = GetWorld())
	{
		if (World->IsGameWorld() && !IsInViewport())
		{
			AddToViewport(1000);
		}
	}
}

void UShockLoadingScreen::HideLoadingScreen()
{
	SetVisibility(ESlateVisibility::Collapsed);
	RemoveFromParent();
}

bool UShockLoadingScreen::RunHeadlessLoadingScreenVerify(UObject* WorldContextObject)
{
	LastVerifyError.Empty();
	UWorld* World = GEngine
		? GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::ReturnNull)
		: nullptr;
	if (!World)
	{
		LastVerifyError = TEXT("no world");
		return false;
	}

	UShockLoadingScreen* Screen =
		CreateWidget<UShockLoadingScreen>(World, UShockLoadingScreen::StaticClass());
	if (!Screen)
	{
		LastVerifyError = TEXT("CreateWidget loading screen failed");
		return false;
	}

	Screen->ShowForMap(TEXT("/Game/BioShockSlice/1-Medical"));
	if (Screen->GetDisplayedLevelName().IsEmpty() || Screen->GetEnteringLine().IsEmpty()
		|| Screen->GetCurrentTip().IsEmpty())
	{
		LastVerifyError = TEXT("loading screen text empty after ShowForMap");
		Screen->HideLoadingScreen();
		return false;
	}
	if (!Screen->GetEnteringLine().Contains(TEXT("Now entering")))
	{
		LastVerifyError = TEXT("entering line missing 'Now entering'");
		Screen->HideLoadingScreen();
		return false;
	}

	Screen->HideLoadingScreen();
	return true;
}
