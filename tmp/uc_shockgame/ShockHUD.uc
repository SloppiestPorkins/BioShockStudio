class ShockHUD extends HUD
	transient
	native
	config(ShockHUD)
	hidecategories(DrawScale3D,DisplayAdvanced);

struct native atomic HealthBarInfo
{
	var ShockPawn Pawn;
	var float BeginFadeOutTime;
	var float EndFadeOutTime;
};

struct native atomic HealthColorPair
{
	var config float HealthAmount;
	var config Color DisplayColor;
};

var(GUIReticle) config int TickSize;
var(GUIReticle) config int CenterDotSize;
var(GUIReticle) config Color TickColor;
var(GUIReticle) config Color StickyTargetTickColor;
var(GUIReticle) config Color SoftLockTickColor;
var config Color MagicBulletRadiusColor;
var config Color MagicBulletActiveRadiusColor;
var config Color StickyTargetRadiusColor;
var config Color SoftLockRadiusColor;
var array<HealthBarInfo> HealthBars;
var config array<HealthColorPair> HealthBarColor;
var config float HealthBarDisplayTime;
var config float HealthBarFadeTime;
var config float HealthBarMinWidth;
var config float HealthBarMaxWidth;
var config float HealthBarMinHeight;
var config float HealthBarMaxHeight;
var config float HealthBarOffsetX;
var config float HealthBarOffsetY;
var config float HealthBarVerticalScalingModifier;
var config float HealthBarHorizontalScalingModifier;
var config Material HealthBarMaterial;
var config Material HealthBorderMaterial;
var config Material HealthBackgroundMaterial;
var config Material TopRightBracketImage;
var config Material TopLeftBracketImage;
var config Material BottomRightBracketImage;
var config Material BottomLeftBracketImage;
var config Color HealthBorderColor;
var config Color HealthBackgroundColor;
var bool DontRenderHud;
var bool bShowMagicBulletRadius;
var bool bShowStickyRadius;
var bool bShowSoftLockRadius;
var float LastChallengeTimerDisplayTime;

function ShockDisplayDebug(Canvas Canvas)
{
	local ShockPlayer thePlayer;

	Canvas.Font = SmallFont;
	thePlayer = ShockPlayer(PlayerOwner.Pawn);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x78
	/*@Error*/
	thePlayer.ShockDisplayDebug(Canvas);
	return;
	@NULL
	Item
	Item
	@NULL
}

function ShowMagicBulletRadius()
{
	bShowMagicBulletRadius = __NFUN_129__(bShowMagicBulletRadius);
	return;
	@NULL
	Item
}

function ShowStickyRadius()
{
	bShowStickyRadius = __NFUN_129__(bShowStickyRadius);
	return;
	@NULL
	Item
}

function ShowSoftLockRadius()
{
	bShowSoftLockRadius = __NFUN_129__(bShowSoftLockRadius);
	return;
	@NULL
	Item
}

function PostRender(Canvas Canvas)
{
	local ShockPlayer thePlayer;
	local Holdable ActiveItem;
	local ICanBeFocused ActiveFocus;
	local Color OldColor;
	local float DisplayTime, FlashUpdateDelayInSeconds;
	local int SecondsPart, MilliSecondsPart;

	super.PostRender(Canvas);
	ShockDisplayDebug(Canvas);
	// End:0x35
	if(DontRenderHud)
	{
		return;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x4D3
		/*@Error*/
	}
	OldColor = Canvas.DrawColor;
	Canvas.DrawColor = TickColor;
	ActiveFocus = ShockPlayerController(PlayerOwner).GetCurrentUseFocus();
	thePlayer = ShockPlayer(PlayerOwner.Pawn);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4D3
	/*@Error*/
	ActiveItem = thePlayer.GetActiveHoldable();
	RenderReticle(Canvas, ActiveItem, PlayerOwner.FovAngle);
	// End:0x24A
	if(__NFUN_130__(Level.bIsDLC1Level, thePlayer.bChallengeTimerIsStarted))
	{
		FlashUpdateDelayInSeconds = 0.0500000;
		DisplayTime = thePlayer.GetChallengeTimeInSeconds();
		// End:0x24A
		if(__NFUN_177__(__NFUN_175__(DisplayTime, LastChallengeTimerDisplayTime), FlashUpdateDelayInSeconds))
		{
			SecondsPart = thePlayer.GetChallengeTimeSecondsPart();
			MilliSecondsPart = thePlayer.GetChallengeTimeMilliSecondsPart();
			LastChallengeTimerDisplayTime = DisplayTime;
			UpdateUIChallengeTimer(SecondsPart, MilliSecondsPart);
			ShockPlayerController(PlayerOwner).ShowEnemyInfoHud(ShockPawn(PlayerOwner.AimTarget));
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x3A3
			/*@Error*/
			// End:0x2E0
			if(thePlayer.bChallengeTimerIsStarted)
			{
				FlashUpdateDelayInSeconds = 0.0500000;
				goto J0x2EF;
				FlashUpdateDelayInSeconds = 0.0000000;
				DisplayTime = thePlayer.GetChallengeTimeInSeconds();
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x3A3
				/*@Error*/
				SecondsPart = thePlayer.GetChallengeTimeSecondsPart();
			}
		}
		MilliSecondsPart = thePlayer.GetChallengeTimeMilliSecondsPart();
		LastChallengeTimerDisplayTime = DisplayTime;
		UpdateUIChallengeTimer(SecondsPart, MilliSecondsPart);
		thePlayer.DisplayPhoto(Canvas);
		thePlayer.DisplayPhotoLight(Canvas);
		thePlayer.DrawBathysphereUI(Canvas);
		thePlayer.GPSDebug(Canvas);
	}
	J0x2EF:

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4D3
	/*@Error*/
	Canvas.SetPos(__NFUN_174__(__NFUN_172__(Canvas.ClipX, 2.0000000), float(40)), __NFUN_172__(Canvas.ClipY, 2.0000000));
	Canvas.__NFUN_465__(string(thePlayer.GetStaticIlluminationLevel()));
	return;
	@NULL
	Item
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

function RenderHealthBars(Canvas Canvas)
{
	//native.Canvas;	
	@NULL
}

function UpdateUIChallengeTimer(int SecondsPart, int MilliSecondsPart)
{
	//native.SecondsPart;
	//native.MilliSecondsPart;	
	@NULL
	@NULL
}

function RenderReticle(Canvas Canvas, Holdable Item, float FovAngle)
{
	local float AimError, ReticleRadius;
	local string CurrentReticleType;
	local Weapon Weapon;
	local PlayerController Player;

	Player = Level.GetLocalPlayerController();
	Weapon = Weapon(Item);
	// End:0x85
	if(ShockPlayer(Player.Pawn).ShouldHideReticle())
	{
		CurrentReticleType = "NoReticle";
		goto J0x201;
		// End:0x187
		if(ShockPlayer(Player.Pawn).CanHitMagicBulletTarget())
		{
			// End:0x173
			if(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_119__(ShockPawn(Player.AimTarget), none), __NFUN_119__(Weapon, none)), __NFUN_119__(Weapon.GetDamageDataClass(), none)), __NFUN_177__(ShockPawn(Player.AimTarget).GetDamageResistanceTo(Weapon.GetDamageDataClass()), 1.0000000)))
			{
			}
			CurrentReticleType = "Vulnerable";
			goto J0x184;
			CurrentReticleType = "Hover";
			goto J0x201;
			// End:0x1BB
			if(__NFUN_119__(Player.ActionTarget, none))
			{
				CurrentReticleType = "AimAssist";
				goto J0x201;
				// End:0x1EE
				if(__NFUN_119__(Player.AimTarget, none))
				{
					CurrentReticleType = "SoftLock";
				}
				goto J0x201;
				CurrentReticleType = "Default";
				AimError = 0.0000000;
			}
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x659
			/*@Error*/
			AimError = Weapon.GetAccuracy();
			// End:0x3A2
			if(bShowMagicBulletRadius)
			{
			}
			// End:0x2A0
			if(ShockPlayer(Player.Pawn).CanHitMagicBulletTarget())
			{
				Canvas.DrawColor = MagicBulletActiveRadiusColor;
			}
			goto J0x2FF;
			// End:0x2DF
			if(__NFUN_119__(Player.AimTarget, none))
			{
				Canvas.DrawColor = MagicBulletRadiusColor;
				goto J0x2FF;
				Canvas.DrawColor = SoftLockRadiusColor;
				Canvas.SetPos(__NFUN_171__(float(Canvas.SizeX), 0.5000000), __NFUN_171__(float(Canvas.SizeY), 0.5000000));
				Canvas.DrawCircle(__NFUN_171__(__NFUN_171__(float(Canvas.SizeY), Weapon.MagicBulletRadius), 0.5000000));
			}
			// End:0x489
			if(bShowStickyRadius)
			{
				Canvas.DrawColor = StickyTargetRadiusColor;
				Canvas.SetPos(__NFUN_171__(float(Canvas.SizeX), 0.5000000), __NFUN_171__(float(Canvas.SizeY), 0.5000000));
			}
			Canvas.DrawCircle(__NFUN_171__(__NFUN_171__(float(Canvas.SizeY), GamepadPlayerInput(Player.GetInput()).ActionTargetRadius), 0.5000000));
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x659
			/*@Error*/
			Canvas.DrawColor = SoftLockRadiusColor;
			Canvas.SetPos(__NFUN_175__(__NFUN_171__(float(Canvas.SizeX), 0.5000000), __NFUN_171__(__NFUN_171__(float(Canvas.SizeY), GamepadPlayerInput(Player.GetInput()).SoftLockOnRadius), 0.5000000)), __NFUN_175__(__NFUN_171__(float(Canvas.SizeY), 0.5000000), __NFUN_171__(__NFUN_171__(float(Canvas.SizeY), GamepadPlayerInput(Player.GetInput()).SoftLockOnRadius), 0.5000000)));
		}
		Canvas.DrawBox(Canvas, __NFUN_171__(float(Canvas.SizeY), GamepadPlayerInput(Player.GetInput()).SoftLockOnRadius), __NFUN_171__(float(Canvas.SizeY), GamepadPlayerInput(Player.GetInput()).SoftLockOnRadius));
	}
	ReticleRadius = __NFUN_172__(__NFUN_171__(Canvas.ClipX, __NFUN_189__(__NFUN_172__(__NFUN_171__(0.0174533, AimError), 2.0000000))), __NFUN_189__(__NFUN_172__(__NFUN_171__(0.0174533, FovAngle), 2.0000000)));
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodString("SetReticleInfo", CurrentReticleType);
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function RenderZoomOverlay(Canvas Canvas, Material ZoomOverlay)
{
	Canvas.SetPos(0.0000000, 0.0000000);
	Canvas.__NFUN_466__(ZoomOverlay, Canvas.ClipX, Canvas.ClipY, 0.0000000, 0.0000000, 512.0000000, 512.0000000);
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function ShowNeedleElement()
{
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("ShowNeedleMeter");
	return;
	@NULL
	Item
}

function HideNeedleElement()
{
	Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodVoid("HideNeedleMeter");
	return;
	@NULL
	Item
}

defaultproperties
{
	TickSize=64
	CenterDotSize=4
	TickColor=(R=255,G=255,B=255,A=255)
	SoftLockTickColor=(R=255,G=255,B=255,A=255)
	MagicBulletRadiusColor=(R=255,G=255,B=255,A=128)
	MagicBulletActiveRadiusColor=(R=255,G=0,B=0,A=128)
	StickyTargetRadiusColor=(R=0,G=255,B=0,A=128)
	SoftLockRadiusColor=(R=0,G=0,B=255,A=128)
	HealthBarColor[0]=(HealthAmount=1.0000000,DisplayColor=(R=162,G=207,B=82,A=255))
	HealthBarColor[1]=(HealthAmount=0.7500000,DisplayColor=(R=162,G=207,B=82,A=255))
	HealthBarColor[2]=(HealthAmount=0.5000000,DisplayColor=(R=247,G=152,B=29,A=255))
	HealthBarColor[3]=(HealthAmount=0.2500000,DisplayColor=(R=235,G=32,B=36,A=255))
	HealthBarColor[4]=(HealthAmount=0.0000000,DisplayColor=(R=235,G=32,B=36,A=255))
	HealthBarDisplayTime=25.0000000
	HealthBarFadeTime=3.0000000
	HealthBarMinWidth=25.0000000
	HealthBarMaxWidth=100.0000000
	HealthBarMinHeight=6.0000000
	HealthBarMaxHeight=30.0000000
	HealthBarVerticalScalingModifier=12.0000000
	HealthBarHorizontalScalingModifier=60.0000000
	HealthBarMaterial=Texture'ShockGame.EnemyHealth.EnemyHealth_barGradient'
	HealthBackgroundMaterial=Texture'ShockGame.EnemyHealth.EnemyHealth_BG'
	TopRightBracketImage=Texture'ShockGame.Reticle.top_right'
	TopLeftBracketImage=Texture'ShockGame.Reticle.top_left'
	BottomRightBracketImage=Texture'ShockGame.Reticle.bottom_right'
	BottomLeftBracketImage=Texture'ShockGame.Reticle.bottom_left'
	HealthBorderColor=(R=255,G=255,B=255,A=255)
	HealthBackgroundColor=(R=100,G=100,B=100,A=255)
}