#include "ShockDeathOverlayWidget.h"

#include "Blueprint/WidgetTree.h"
#include "Components/TextBlock.h"

UShockDeathOverlayWidget::UShockDeathOverlayWidget(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
}

void UShockDeathOverlayWidget::EnsureWidgetTree()
{
	if (!WidgetTree || DeathText)
	{
		return;
	}

	DeathText = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("DeathText"));
	DeathText->SetText(FText::FromString(TEXT("YOU DIED")));
	DeathText->SetJustification(ETextJustify::Center);
	FSlateFontInfo Font = DeathText->GetFont();
	Font.Size = 64;
	DeathText->SetFont(Font);
	DeathText->SetColorAndOpacity(FSlateColor(FLinearColor(0.9f, 0.1f, 0.1f, 1.0f)));
	WidgetTree->RootWidget = DeathText;
}

TSharedRef<SWidget> UShockDeathOverlayWidget::RebuildWidget()
{
	EnsureWidgetTree();
	return Super::RebuildWidget();
}

void UShockDeathOverlayWidget::NativeConstruct()
{
	EnsureWidgetTree();
	Super::NativeConstruct();
	if (DeathText)
	{
		DeathText->SetVisibility(ESlateVisibility::Hidden);
	}
}

void UShockDeathOverlayWidget::ShowDeathMessage()
{
	EnsureWidgetTree();
	bDeathMessageVisible = true;
	if (DeathText)
	{
		DeathText->SetVisibility(ESlateVisibility::Visible);
	}
}

void UShockDeathOverlayWidget::FadeOutBeforeRespawn()
{
	bDeathMessageVisible = false;
	if (DeathText)
	{
		DeathText->SetVisibility(ESlateVisibility::Hidden);
	}
	RemoveFromParent();
}
