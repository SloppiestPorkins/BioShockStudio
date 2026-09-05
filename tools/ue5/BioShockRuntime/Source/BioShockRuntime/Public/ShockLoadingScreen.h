#pragma once

#include "Blueprint/UserWidget.h"
#include "ShockLoadingScreen.generated.h"

class UBorder;
class UTextBlock;
class UVerticalBox;

/**
 * Deco loading panel shown during OpenLevel travel: level name, "Now entering …", rotating tip.
 * Driven by UShockGameInstance PreLoadMap / PostLoadMapWithWorld hooks.
 */
UCLASS()
class BIOSHOCKRUNTIME_API UShockLoadingScreen : public UUserWidget
{
	GENERATED_BODY()

public:
	UShockLoadingScreen(const FObjectInitializer& ObjectInitializer);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Loading")
	void ShowForMap(const FString& MapPackagePath);

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Loading")
	void HideLoadingScreen();

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Loading")
	FString GetDisplayedLevelName() const { return DisplayedLevelName; }

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Loading")
	FString GetEnteringLine() const { return EnteringLine; }

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Loading")
	FString GetCurrentTip() const { return CurrentTip; }

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Loading")
	void RotateTip();

	UFUNCTION(BlueprintCallable, Category = "BioShock|UI|Loading")
	static bool RunHeadlessLoadingScreenVerify(UObject* WorldContextObject);

	UFUNCTION(BlueprintPure, Category = "BioShock|UI|Loading")
	static FString GetLastLoadingScreenVerifyError();

protected:
	virtual TSharedRef<SWidget> RebuildWidget() override;
	virtual void NativeConstruct() override;
	virtual void NativeTick(const FGeometry& MyGeometry, float InDeltaTime) override;

private:
	void EnsureWidgetTree();
	static FString PrettyMapName(const FString& PackagePath);

	UPROPERTY(Transient)
	TObjectPtr<UBorder> RootBorder = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UVerticalBox> Column = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> TitleText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> EnteringText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> TipText = nullptr;

	FString DisplayedLevelName;
	FString EnteringLine;
	FString CurrentTip;
	int32 TipIndex = 0;
	float TipTimer = 0.0f;

	static FString LastVerifyError;
};
