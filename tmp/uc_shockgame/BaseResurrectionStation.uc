class BaseResurrectionStation extends Actor
	abstract
	native
	config(Machines)
	placeable
	hidecategories(DrawScale3D,DisplayAdvanced);

struct native atomic ResurrectionStationModelSpec
{
	var() StaticMesh StaticMesh;
	var() name AttachSocket;
	var() Vector AttachLocationOffset;
	var() Rotator AttachRotationOffset;
	var() bool InteractWithPhysicalObjects;
	var() bool IsADoor "True if it's a part of the doors of the station.";

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

var private config localized string FriendlyName;
var private config localized string ActivatedFriendlyName;
var private config localized string UnavailableFriendlyName;
var private config localized string UseVerbText;
var private config localized string ActivatedUseVerbText;
var private config localized string ResurrectionMessage;
var private const config float ResurrectionHealthPercentage;
var private const config float ResurrectionHealthMax;
var private const config int ResurrectionCreditCost;
var private const config float DoorCloseTickDelta;
var private const config bool ActivateByPlayer;
var array<ResurrectionStationAttachment> StationAttachments;
var(ResurrectionStation) array<ResurrectionStationModelSpec> Attachments;
var(ResurrectionStation) private const name OpenAnimationName;
var(ResurrectionStation) private const name CloseAnimationName;
var(ResurrectionStation) private const name PlayerStartBone;
var(ResurrectionStation) private const int ActivatedMaterialSwitchIndex;
var(ResurrectionStation) private const int DeactivatedMaterialSwitchIndex;
var private bool bIsActivated;
var(ResurrectionStation) private bool bIsAvailable;
var private int CurrentAnimationHandle;
var private ShockPlayer LastPlayerToUseDoors;

function BaseResurrectionStation GetClosestStation(ShockPlayer Player)
{
	//native.Player;	
	@NULL
}

function bool ResurrectShockPlayer(ShockPlayer Player, BaseResurrectionStation ClosestStation)
{
	local Coords PlayerStartCoords;
	local bool MoveSuccessful;
	local int CreditsToRemove;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x3BF
	/*@Error*/
	PlayerStartCoords = ClosestStation.GetPlayerStartCoords();
	MoveSuccessful = ClosestStation.MovePlayerToStation(Player, PlayerStartCoords.Origin);
	// End:0xCA
	if(__NFUN_129__(MoveSuccessful))
	{
		log(,, __NFUN_112__("Could not move the player to ", string(PlayerStartCoords.Origin)));
		return false;
		ClosestStation.SetDoorsClosed();
		Player.Controller.__NFUN_299__(OrthoRotation(PlayerStartCoords.XAxis, PlayerStartCoords.YAxis, PlayerStartCoords.ZAxis));
	}
	assert(__NFUN_180__(Player.GetHealth(), float(0)));
	Player.AddHealth(float(__NFUN_249__(int(__NFUN_171__(Player.GetMaxHealth(), ClosestStation.ResurrectionHealthPercentage)), int(ClosestStation.ResurrectionHealthMax))), true);
	log('Player', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(Player.Name), " has been resurrected with "), string(Player.GetHealth())), " health."));
	CreditsToRemove = ClosestStation.ResurrectionCreditCost;
	// End:0x2BB
	if(__NFUN_151__(ClosestStation.ResurrectionCreditCost, Player.GetCredits()))
	{
		CreditsToRemove = Player.GetCredits();
		Player.RemoveCredits(CreditsToRemove);
		Player.PrepareToResurrect();
		Player.Controller.ConsoleCommand("PUSHINPUTCONTEXT InResurrectionStation");
		ClosestStation.TriggerEffectEvent('ResurrectedPlayer');
		Player.TriggerEffectEvent('WasResurrected');
		Player.dispatchMessage(Class'ShockGame.MessagePlayerResurrected'.static.Allocate(self)., Construct_Void());
	}
	return true;
	return false;
	return;
	@NULL
	Item
	Class'ShockGame.Item'
	@NULL
}

function bool MovePlayerToStation(ShockPlayer Player, Vector NewLocation)
{
	//native.Player;
	//native.NewLocation;	
	@NULL
	@NULL
}

function bool IsActivated()
{
	return bIsActivated;
	return;
	@NULL
}

function bool IsAvailable()
{
	return bIsAvailable;
	return;
	@NULL
}

// Export UBaseResurrectionStation::execCanResurrectHere(FFrame&, void* const)
native function bool CanResurrectHere();

function bool CanBeActivated()
{
	return __NFUN_130__(bIsAvailable, __NFUN_129__(bIsActivated));
	return;
	@NULL
	Item
}

function DisableStation()
{
	bIsAvailable = false;
	return;
	@NULL
}

function EnableStation()
{
	bIsAvailable = true;
	return;
	@NULL
}

function ActivateStation(Pawn Activator)
{
	bIsActivated = true;
	Activator.ClientMessage("", 'UseFocus');
	SetMaterialSwitchIndex(ActivatedMaterialSwitchIndex);
	TriggerEffectEvent('OnActivated');
	return;
	@NULL
	Item
	Item
}

function DeactivateStation(Pawn Activator)
{
	bIsActivated = false;
	Activator.ClientMessage("", 'UseFocus');
	SetMaterialSwitchIndex(DeactivatedMaterialSwitchIndex);
	TriggerEffectEvent('OnDeactivated');
	return;
	@NULL
	Item
	Item
}

function SetMaterialSwitchIndex(int Index)
{
	//native.Index;	
	@NULL
}

function bool CanOpenDoors(Pawn User)
{
	return __NFUN_130__(__NFUN_130__(__NFUN_254__(__NFUN_284__(), 'DoorClosed'), User.__NFUN_548__(User.Location, GetPlayerStartCoords().Origin)), IsPointWithinCylinder(User.Location, Location, CollisionRadius, CollisionHeight));
	return;
	@NULL
	Item
	Item
	@NULL
}

function Coords GetPlayerStartCoords()
{
	return GetBoneCoords(PlayerStartBone, true);
	return;
	@NULL
	Item
}

function PreBeginPlay()
{
	local int i;
	local ResurrectionStationModel Model;
	local ResurrectionStationAttachment Attachment;

	super.PreBeginPlay();
	AssertWithDescription(__NFUN_119__(Mesh, none), __NFUN_112__(__NFUN_112__("The class ", string(Class.Name)), " has no Mesh set."));
	SetDrawType(2);
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x491
	/*@Error*/
	// End:0x255
	if(Attachments[i].InteractWithPhysicalObjects)
	{
		Model = __NFUN_278__(Class'ShockGame.ResurrectionStationModel', self);
		assert(__NFUN_119__(Model, none));
		AttachToBone(Model, Attachments[i].AttachSocket);
		Model.SetRelativeLocation(Attachments[i].AttachLocationOffset);
		Model.SetRelativeRotation(Attachments[i].AttachRotationOffset);
		Model.SetStaticMesh(Attachments[i].StaticMesh);
		Model.SetDrawScale3D(DrawScale3D);
		Model.SetDoorFlag(Attachments[i].IsADoor);
		Model.OwnerStation = self;
		StationAttachments[StationAttachments.Length] = Model;
		goto J0x3B9;
		Attachment = __NFUN_278__(Class'ShockGame.ResurrectionStationAttachment', self);
		assert(__NFUN_119__(Attachment, none));
		AttachToBone(Attachment, Attachments[i].AttachSocket);
		Attachment.SetRelativeLocation(Attachments[i].AttachLocationOffset);
		Attachment.SetRelativeRotation(Attachments[i].AttachRotationOffset);
		Attachment.SetStaticMesh(Attachments[i].StaticMesh);
		Attachment.SetDrawScale3D(DrawScale3D);
		Attachment.OwnerStation = self;
		StationAttachments[StationAttachments.Length] = Attachment;
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x426
	/*@Error*/
	StationAttachments[StationAttachments.Length].SpecialLitChannel = self.SpecialLitChannel;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x483
	/*@Error*/
	StationAttachments[__NFUN_147__(StationAttachments.Length, 1)].MaxLightsDynamic = self.MaxLightsDynamic;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x72;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4B4
	/*@Error*/
	SetMaterialSwitchIndex(ActivatedMaterialSwitchIndex);
	goto J0x4C7;
	SetMaterialSwitchIndex(DeactivatedMaterialSwitchIndex);
	__NFUN_262__(false, false, false);
	UnavailableFriendlyName = "!!! BUG THIS. IF YOU CAN READ THIS PAUL HELLQUIST DID NOT DO HIS JOB. LOVE, KLINE";
	return;
	@NULL
	Item
	Item
	@NULL
}

function DestroyAttachmentsOnDoors()
{
	local int i;
	local ResurrectionStationModel StationModel;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x99
	/*@Error*/
	StationModel = ResurrectionStationModel(StationAttachments[i]);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x8B
	/*@Error*/
	StationModel.DestroyAttachments();
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function OnActorAttached(ResurrectionStationModel StationModel, Actor Other)
{
	local StickyProjectile OtherStickyProjectile;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x82
	/*@Error*/
	OtherStickyProjectile = StickyProjectile(Other);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x82
	/*@Error*/
	OtherStickyProjectile.ExplodeOnNextTick();
	return;
	@NULL
	Item
	Item
	@NULL
}

private function OpenDoor(ShockPlayer DoorOpener)
{
	return;
}

function SetDoorsClosed()
{
	local int Handle;
	local float animationLength;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x91
	/*@Error*/
	Handle = PlayAnimationOnChannel(0, CloseAnimationName, 2);
	animationLength = GetAnimationLengthAbsolute(Handle);
	SetAnimationCurrentTime(Handle, animationLength);
	bUseCylinderCollision = false;
	__NFUN_262__(false, false, false);
	UpdateAttachmentLocations();
	__NFUN_113__('DoorClosed');
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool CanBeUsedNow(ResurrectionStationModel Model)
{
	local ShockPlayer Player;

	Player = ShockPlayer(Level.GetLocalPlayerController().Pawn);
	assert(__NFUN_119__(Player, none));
	// End:0xA6
	if(ActivateByPlayer)
	{
		return __NFUN_130__(bIsAvailable, __NFUN_132__(__NFUN_129__(bIsActivated), __NFUN_130__(Model.IsADoor(), CanOpenDoors(Player))));
		goto J0xD6;
		return __NFUN_130__(Model.IsADoor(), CanOpenDoors(Player));
		return;
		@NULL
	}
	Item
	Item
	@NULL
}

function OnUsed(Pawn Pawn, ResurrectionStationModel Model)
{
	local ShockPlayer Player;

	log(,, __NFUN_112__("Player has used the resurrection station, Model = ", string(Model)));
	Player = ShockPlayer(Pawn);
	assert(__NFUN_119__(Player, none));
	// End:0xA5
	if(__NFUN_130__(ActivateByPlayer, CanBeActivated()))
	{
		ActivateStation(Pawn);
		goto J0xEA;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xEA
		/*@Error*/
	}
	OpenDoor(Player);
	return;
	@NULL
	Item
	Item
	@NULL
}

function string GetUseVerbText(ResurrectionStationModel Model)
{
	// End:0x1A
	if(bIsActivated)
	{
		return ActivatedUseVerbText;
		goto J0x24;
		return UseVerbText;
		return;
	}
	@NULL
	Item
	J0x24:

	Item
}

function bool CanBeFocusedNow(ResurrectionStationModel Model)
{
	return true;
	return;
}

function string GetFocusDisplayName(ResurrectionStationModel Model)
{
	// End:0x34
	if(bIsAvailable)
	{
		// End:0x27
		if(bIsActivated)
		{
			return ActivatedFriendlyName;
			goto J0x31;
			return FriendlyName;
			goto J0x3E;
			return UnavailableFriendlyName;
		}
		return;
		@NULL
		J0x31:

		Item
	}
	Item
	@NULL
}

function string GetHUDMessageForFocusAttained(ResurrectionStationModel Model)
{
	return GetFocusDisplayName(Model);
	return;
	@NULL
}

function bool ShouldHighlightWhenFocused(ResurrectionStationModel Model)
{
	return true;
	return;
}

function bool ShouldShowHelpTagWhenFocused(ResurrectionStationModel Model)
{
	local ShockPlayer Player;

	Player = ShockPlayer(Level.GetLocalPlayerController().Pawn);
	assert(__NFUN_119__(Player, none));
	return __NFUN_129__(CanOpenDoors(Player));
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnFocusStarted(ResurrectionStationModel Model)
{
	local int i;

	log(,, __NFUN_112__(string(self), " highlighted."));
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x97
	/*@Error*/
	log(,, __NFUN_112__("	", string(StationAttachments[i])));
	StationAttachments[i].TriggerEffectEvent('BecameUseFocus');
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x26;
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnFocusStopped(ResurrectionStationModel Model)
{
	local int i;

	log(,, __NFUN_112__(string(self), " unhighlighted."));
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x99
	/*@Error*/
	log(,, __NFUN_112__("	", string(StationAttachments[i])));
	StationAttachments[i].UnTriggerEffectEvent('BecameUseFocus');
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x28;
	return;
	@NULL
	Item
	Item
	@NULL
}

function SetAttachmentsCollision(bool EnableCollision)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xDD
	/*@Error*/
	// End:0x52
	if(__NFUN_129__(EnableCollision))
	{
		StationAttachments[i].__NFUN_262__(false, false, false);
		goto J0xCF;
		StationAttachments[i].__NFUN_262__(StationAttachments[i].default.bCollideActors, StationAttachments[i].default.bBlockActors, StationAttachments[i].default.bBlockPlayers);
	}
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	Item
	@NULL
}

auto state DoorClosed
{	stop;
}

state DoorOpening
{Begin:

	DestroyAttachmentsOnDoors();
	TriggerEffectEvent('DoorOpening');
	bUseCylinderCollision = true;
	__NFUN_262__(true, true, false);
	FinishAnimation(CurrentAnimationHandle);
	UpdateAttachmentLocations();
	__NFUN_113__('DoorOpen');
	stop;				
	@NULL
	@NULL
	@NULL
	@NULL
}

state DoorOpen
{Begin:

	log(,, "Looking for player in resurrection station...");
	J0x36:

	// End:0x6C [Loop If]
	if(__NFUN_130__(__NFUN_119__(LastPlayerToUseDoors, none), TouchingActor(LastPlayerToUseDoors)))
	{
		__NFUN_256__(DoorCloseTickDelta);
		// [Loop Continue]
		goto J0x36;
		log(,, "Player has left the resurrection station, closing doors.");
	}
	LastPlayerToUseDoors = none;
	__NFUN_262__(,, true);
	CurrentAnimationHandle = PlayAnimationOnChannel(0, CloseAnimationName, 2);
	__NFUN_113__('DoorClosing');
	stop;		
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

state DoorClosing
{Begin:

	DestroyAttachmentsOnDoors();
	TriggerEffectEvent('DoorClosing');
	FinishAnimation(CurrentAnimationHandle);
	CurrentAnimationHandle = 0;
	bUseCylinderCollision = false;
	__NFUN_262__(false, false, false);
	UpdateAttachmentLocations();
	__NFUN_113__('DoorClosed');
	stop;	
	@NULL
	@NULL
	@NULL
	@NULL
}

defaultproperties
{
	FriendlyName="Vita-Chamber (Deactivated)"
	ActivatedFriendlyName="Vita-Chamber"
	UnavailableFriendlyName="Vita-Chamber (Broken)"
	UseVerbText="activate"
	ActivatedUseVerbText="Open Doors"
	ResurrectionMessage="%credits% dollars consumed in resurrection."
	ResurrectionHealthPercentage=0.5000000
	ResurrectionHealthMax=9999.0000000
	DoorCloseTickDelta=0.2000000
	ActivateByPlayer=true
	OpenAnimationName="Opening"
	CloseAnimationName="Closing"
	PlayerStartBone="PlayerStart"
	bIsAvailable=true
	DrawType=8
	bAcceptsProjectors=true
	bInGameRenderable=true
	Mesh=SkeletalMesh'SimpleAnim.SimpleAnim'
	bCastStaticShadow=true
	CollisionRadius=175.0000000
	CollisionHeight=260.0000000
	bCollideActors=true
	bBlockActors=true
	bBlockZeroExtentTraces=false
	bDirectional=true
	bPathColliding=true
	bTriggerEffectEventsBeforeGameStarts=true
	bNeedLifetimeEffectEvents=true
	ShouldSerializeSkeletonInstance=true
	bCastShadowMapShadow=true
}