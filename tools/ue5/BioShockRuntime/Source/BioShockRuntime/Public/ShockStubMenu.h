#pragma once

#include "Blueprint/UserWidget.h"
#include "ShockStubMenu.generated.h"

class UButton;
class UTextBlock;
class UVerticalBox;

/** Shared "Not implemented" panel with Back for Options / Credits / Museum / etc. */
UCLASS()
class BIOSHOCKRUNTIME_API UShockStubMenu : public UUserWidget
{
	GENERATED_BODY()

public:
	UShockStubMenu(const FObjectInitializer& ObjectInitializer);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Menu")
	void OpenStub(const FString& Title);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Menu")
	void CloseStub();

	UFUNCTION(BlueprintPure, Category = "BioShock|Menu")
	FString GetStubTitle() const { return StubTitle; }

	DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnStubClosed);
	UPROPERTY(BlueprintAssignable, Category = "BioShock|Menu")
	FOnStubClosed OnStubClosed;

protected:
	virtual TSharedRef<SWidget> RebuildWidget() override;
	virtual void NativeConstruct() override;
	virtual FReply NativeOnKeyDown(const FGeometry& InGeometry, const FKeyEvent& InKeyEvent) override;

private:
	void EnsureWidgetTree();

	UPROPERTY(Transient)
	TObjectPtr<UVerticalBox> RootColumn = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> TitleText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> BodyText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UButton> BackButton = nullptr;

	FString StubTitle;
	bool bOpen = false;

	UFUNCTION()
	void OnBackClicked();
};
