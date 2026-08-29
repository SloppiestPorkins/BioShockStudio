#include "ShockMainMenuWidget.h"

#include "Blueprint/WidgetTree.h"
#include "Components/Button.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Components/VerticalBoxSlot.h"
#include "Engine/World.h"
#include "Kismet/GameplayStatics.h"
#include "Kismet/KismetSystemLibrary.h"

namespace
{
constexpr const TCHAR* DefaultPlayLevel = TEXT("/Game/BioShockSlice/1-Medical");
constexpr const TCHAR* DefaultTravelOptions = TEXT("game=/Script/BioShockRuntime.ShockGameMode");

UButton* MakeMenuButton(UWidgetTree* Tree, FName Name, const FString& Label)
{
	UButton* Button = Tree->ConstructWidget<UButton>(UButton::StaticClass(), Name);
	UTextBlock* Caption = Tree->ConstructWidget<UTextBlock>(
		UTextBlock::StaticClass(), FName(*(Name.ToString() + TEXT("_Label"))));
	Caption->SetText(FText::FromString(Label));
	FSlateFontInfo Font = Caption->GetFont();
	Font.Size = 28;
	Caption->SetFont(Font);
	Button->AddChild(Caption);
	return Button;
}
}

UShockMainMenuWidget::UShockMainMenuWidget(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	PlayLevelPath = DefaultPlayLevel;
	PlayTravelOptions = DefaultTravelOptions;
}

FString UShockMainMenuWidget::GetResolvedPlayLevelPath() const
{
	if (!PlayLevelPath.IsEmpty())
	{
		return PlayLevelPath;
	}
	return DefaultPlayLevel;
}

void UShockMainMenuWidget::EnsureWidgetTree()
{
	if (!WidgetTree)
	{
		return;
	}
	if (RootBox)
	{
		return;
	}

	RootBox = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(), TEXT("MenuRoot"));
	WidgetTree->RootWidget = RootBox;

	TitleText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("Title"));
	TitleText->SetText(FText::FromString(TEXT("BIOSHOCK")));
	FSlateFontInfo TitleFont = TitleText->GetFont();
	TitleFont.Size = 72;
	TitleText->SetFont(TitleFont);
	if (UVerticalBoxSlot* TitleSlot = RootBox->AddChildToVerticalBox(TitleText))
	{
		TitleSlot->SetHorizontalAlignment(HAlign_Center);
		TitleSlot->SetPadding(FMargin(0.0f, 80.0f, 0.0f, 48.0f));
	}

	PlayButton = MakeMenuButton(WidgetTree, TEXT("PlayButton"), TEXT("Play"));
	OptionsButton = MakeMenuButton(WidgetTree, TEXT("OptionsButton"), TEXT("Options"));
	QuitButton = MakeMenuButton(WidgetTree, TEXT("QuitButton"), TEXT("Quit"));

	for (UButton* Button : {PlayButton, OptionsButton, QuitButton})
	{
		if (UVerticalBoxSlot* BoxSlot = RootBox->AddChildToVerticalBox(Button))
		{
			BoxSlot->SetHorizontalAlignment(HAlign_Center);
			BoxSlot->SetPadding(FMargin(0.0f, 8.0f));
		}
	}

	OptionsButton->SetIsEnabled(false);
}

TSharedRef<SWidget> UShockMainMenuWidget::RebuildWidget()
{
	EnsureWidgetTree();
	return Super::RebuildWidget();
}

void UShockMainMenuWidget::NativeConstruct()
{
	EnsureWidgetTree();
	Super::NativeConstruct();
	BindButtons();

	if (APlayerController* PC = GetOwningPlayer())
	{
		if (PlayButton)
		{
			PlayButton->SetKeyboardFocus();
		}
	}
}

void UShockMainMenuWidget::BindButtons()
{
	if (bButtonsBound)
	{
		return;
	}
	if (PlayButton)
	{
		PlayButton->OnClicked.AddDynamic(this, &UShockMainMenuWidget::OnPlayClicked);
	}
	if (OptionsButton)
	{
		OptionsButton->OnClicked.AddDynamic(this, &UShockMainMenuWidget::OnOptionsClicked);
	}
	if (QuitButton)
	{
		QuitButton->OnClicked.AddDynamic(this, &UShockMainMenuWidget::OnQuitClicked);
	}
	bButtonsBound = true;
}

void UShockMainMenuWidget::OnPlayClicked()
{
	const FString PackageName = GetResolvedPlayLevelPath();
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_MENU_PLAY map=%s options=%s"),
		*PackageName,
		*PlayTravelOptions);

	const FName LevelName(*PackageName);
	UGameplayStatics::OpenLevel(this, LevelName, true, PlayTravelOptions);
}

void UShockMainMenuWidget::OnOptionsClicked()
{
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_MENU_OPTIONS placeholder"));
}

void UShockMainMenuWidget::OnQuitClicked()
{
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_MENU_QUIT"));
	UKismetSystemLibrary::QuitGame(
		this, GetOwningPlayer(), EQuitPreference::Quit, /*bIgnorePlatformRestrictions=*/false);
}
