#include "ShockStubMenu.h"

#include "Blueprint/WidgetTree.h"
#include "Components/Button.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Components/VerticalBoxSlot.h"
#include "Input/Events.h"
#include "InputCoreTypes.h"
#include "Styling/CoreStyle.h"

namespace
{
FSlateFontInfo StubFont(int32 Size, bool bBold = false)
{
	return FCoreStyle::GetDefaultFontStyle(bBold ? TEXT("Bold") : TEXT("Regular"), Size);
}
}

UShockStubMenu::UShockStubMenu(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	SetVisibility(ESlateVisibility::Collapsed);
	SetIsFocusable(true);
}

void UShockStubMenu::EnsureWidgetTree()
{
	if (!WidgetTree || RootColumn)
	{
		return;
	}

	RootColumn = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(), TEXT("StubRoot"));
	WidgetTree->RootWidget = RootColumn;

	TitleText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("StubTitle"));
	TitleText->SetFont(StubFont(36, true));
	TitleText->SetColorAndOpacity(FLinearColor(0.92f, 0.78f, 0.35f, 1.0f));
	if (UVerticalBoxSlot* BoxSlot = RootColumn->AddChildToVerticalBox(TitleText))
	{
		BoxSlot->SetHorizontalAlignment(HAlign_Center);
		BoxSlot->SetPadding(FMargin(0.0f, 100.0f, 0.0f, 24.0f));
	}

	BodyText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("StubBody"));
	BodyText->SetFont(StubFont(22, false));
	BodyText->SetColorAndOpacity(FLinearColor(0.92f, 0.88f, 0.75f, 1.0f));
	BodyText->SetText(FText::FromString(TEXT("Not implemented")));
	BodyText->SetJustification(ETextJustify::Center);
	if (UVerticalBoxSlot* BoxSlot = RootColumn->AddChildToVerticalBox(BodyText))
	{
		BoxSlot->SetHorizontalAlignment(HAlign_Center);
		BoxSlot->SetPadding(FMargin(0.0f, 8.0f, 0.0f, 40.0f));
	}

	BackButton = WidgetTree->ConstructWidget<UButton>(UButton::StaticClass(), TEXT("StubBack"));
	UTextBlock* BackLabel =
		WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("StubBackLabel"));
	BackLabel->SetText(FText::FromString(TEXT("Back")));
	BackLabel->SetFont(StubFont(20, true));
	BackLabel->SetColorAndOpacity(FLinearColor(0.92f, 0.88f, 0.75f, 1.0f));
	BackButton->AddChild(BackLabel);
	BackButton->OnClicked.AddDynamic(this, &UShockStubMenu::OnBackClicked);
	if (UVerticalBoxSlot* BoxSlot = RootColumn->AddChildToVerticalBox(BackButton))
	{
		BoxSlot->SetHorizontalAlignment(HAlign_Center);
	}
}

TSharedRef<SWidget> UShockStubMenu::RebuildWidget()
{
	EnsureWidgetTree();
	return Super::RebuildWidget();
}

void UShockStubMenu::NativeConstruct()
{
	EnsureWidgetTree();
	Super::NativeConstruct();
}

void UShockStubMenu::OpenStub(const FString& Title)
{
	StubTitle = Title;
	EnsureWidgetTree();
	if (TitleText)
	{
		TitleText->SetText(FText::FromString(Title));
	}
	bOpen = true;
	SetVisibility(ESlateVisibility::Visible);
	SetKeyboardFocus();
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_STUB open=%s"), *Title);
}

void UShockStubMenu::CloseStub()
{
	bOpen = false;
	SetVisibility(ESlateVisibility::Collapsed);
	OnStubClosed.Broadcast();
}

void UShockStubMenu::OnBackClicked()
{
	CloseStub();
}

FReply UShockStubMenu::NativeOnKeyDown(const FGeometry& InGeometry, const FKeyEvent& InKeyEvent)
{
	if (!bOpen)
	{
		return Super::NativeOnKeyDown(InGeometry, InKeyEvent);
	}
	if (InKeyEvent.GetKey() == EKeys::Escape)
	{
		CloseStub();
		return FReply::Handled();
	}
	return Super::NativeOnKeyDown(InGeometry, InKeyEvent);
}
