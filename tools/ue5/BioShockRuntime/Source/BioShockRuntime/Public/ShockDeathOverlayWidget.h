#pragma once

#include "Blueprint/UserWidget.h"
#include "ShockDeathOverlayWidget.generated.h"

class UTextBlock;

/** Minimal "You Died" overlay — C++ widget tree, no designer asset required. */
UCLASS()
class BIOSHOCKRUNTIME_API UShockDeathOverlayWidget : public UUserWidget
{
	GENERATED_BODY()

public:
	UShockDeathOverlayWidget(const FObjectInitializer& ObjectInitializer);

	UFUNCTION(BlueprintCallable, Category="BioShock|Death")
	void ShowDeathMessage();

	UFUNCTION(BlueprintCallable, Category="BioShock|Death")
	void FadeOutBeforeRespawn();

	UFUNCTION(BlueprintPure, Category="BioShock|Death")
	bool IsDeathMessageVisible() const { return bDeathMessageVisible; }

protected:
	virtual TSharedRef<SWidget> RebuildWidget() override;
	virtual void NativeConstruct() override;

private:
	void EnsureWidgetTree();

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> DeathText = nullptr;

	bool bDeathMessageVisible = false;
};
