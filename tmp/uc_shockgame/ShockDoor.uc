class ShockDoor extends Door implements IPoweredByFuse
	abstract
	native
	config(ShockGame)
	hidecategories(DrawScale3D,DisplayAdvanced,Lighting,LightColor,Force);

enum EDynamicShadowBehavior
{
	EDS_NeverCast,                  // 0
	EDS_CastOnlyWhenMoving,         // 1
	EDS_AlwaysCast                  // 2
};

struct native atomic DoorAttachmentSpec
{
	var() StaticMesh StaticMesh;
	var() name AttachSocket;
	var() Vector AttachLocationOffset;
	var() Rotator AttachRotationOffset;
	var() bool InteractWithPhysicalObjects;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

var(Door) private edfindable FuseBox FuseBox;
var(Door) private bool bLocked;
var(Door) private bool bBroken;
var(Door) private bool bOpenable;
var(Door) private bool bInitiallyOpen;
var private bool bToldToClose;
var(Door) private config float StayOpenDuration;
var(Door) private config float DelayBeforeOpening;
var(Door) private Class<HavokForceActorPreset> HavokForceActorClass;
var HavokForceActor ForceActor;
var(Display) ShockDoor.EDynamicShadowBehavior DynamicShadowBehavior;
var private bool bButtonDoor;
var private bool bIsInOperation;
var private bool bIsMoving;
var(Door) private StaticMesh ClosedStaticMesh;
var(Door) private StaticMesh OpenedStaticMesh;
var(Door) array<DoorAttachmentSpec> Attachments;
var array<DoorAttachment> DoorAttachments;
var(Door) private const name OpenAnimationName;
var(Door) private const name CloseAnimationName;
var(Door) private const name BlockedAnimationName;
var(Door) private const name BrokenAnimationName;
var(Door) float OpenAnimationRate;
var(Door) float CloseAnimationRate;
var(Door) float BlockedAnimationRate;
var(Door) float BrokenAnimationRate;
var array<ShockPawn> PawnsInsideDoor;
var(Door) edfindable Brush DoorPortal;
var private config float DoorCloseRadiusMultiplier;

function PreBeginPlay()
{
	local int i;
	local DoorModel DoorModel;
	local DoorAttachment Attachment;

	log('Doors', 4, __NFUN_112__(string(self), "---ShockDoor::PreBeginPlay()."));
	super(Actor).PreBeginPlay();
	AssertWithDescription(__NFUN_119__(Mesh, none), __NFUN_112__(__NFUN_112__("The class ", string(Class.Name)), " has no Mesh set."));
	SetDrawType(2);
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x622
	/*@Error*/
	// End:0x320
	if(Attachments[i].InteractWithPhysicalObjects)
	{
		log('Doors', 5, "...Creating DoorModel:");
		log('Doors', 5, __NFUN_112__("...static mesh=", string(Attachments[i].StaticMesh)));
		log('Doors', 5, __NFUN_112__("...AttachSocket=", string(Attachments[i].AttachSocket)));
		DoorModel = __NFUN_278__(Class'ShockGame.DoorModel', self);
		assert(__NFUN_119__(DoorModel, none));
		DoorModel.Door = self;
		AttachToBone(DoorModel, Attachments[i].AttachSocket);
		DoorModel.SetRelativeLocation(Attachments[i].AttachLocationOffset);
		DoorModel.SetRelativeRotation(Attachments[i].AttachRotationOffset);
		DoorModel.SetStaticMesh(Attachments[i].StaticMesh);
		DoorModel.SetDrawScale3D(DrawScale3D);
		DoorAttachments.Insert(DoorAttachments.Length, 1);
		DoorAttachments[__NFUN_147__(DoorAttachments.Length, 1)] = DoorModel;
		goto J0x544;
		log('Doors', 5, "...Creating DoorAttachment:");
		log('Doors', 5, __NFUN_112__("...static mesh=", string(Attachments[i].StaticMesh)));
		log('Doors', 5, __NFUN_112__("...AttachSocket=", string(Attachments[i].AttachSocket)));
		Attachment = __NFUN_278__(Class'ShockGame.DoorAttachment', self);
		assert(__NFUN_119__(Attachment, none));
		Attachment.SetDrawScale3D(DrawScale3D);
		Attachment.SetRelativeLocation(Attachments[i].AttachLocationOffset);
	}
	Attachment.SetRelativeRotation(Attachments[i].AttachRotationOffset);
	Attachment.SetStaticMesh(Attachments[i].StaticMesh);
	AttachToBone(Attachment, Attachments[i].AttachSocket);
	DoorAttachments.Insert(DoorAttachments.Length, 1);
	DoorAttachments[__NFUN_147__(DoorAttachments.Length, 1)] = Attachment;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5B7
	/*@Error*/
	DoorAttachments[__NFUN_147__(DoorAttachments.Length, 1)].SpecialLitChannel = self.SpecialLitChannel;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x614
	/*@Error*/
	DoorAttachments[__NFUN_147__(DoorAttachments.Length, 1)].MaxLightsDynamic = self.MaxLightsDynamic;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0xA6;
	__NFUN_262__(true);
	__NFUN_283__(default.CollisionRadius, default.CollisionHeight);
	bOccludesSound = false;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6A0
	/*@Error*/
	ForceActor = __NFUN_278__(HavokForceActorClass, self,, Location);
	ForceActor.__NFUN_298__(self);
	ForceActor.SetEnabled(false);
	return;
	@NULL
	Item
	Item
	@NULL
}

function UpdateDoorOperationalStatus(bool IsCurrentlyInOperation)
{
	local bool ShouldCastDynamicShadows;
	local int i;
	local DoorAttachment Model;

	bIsInOperation = IsCurrentlyInOperation;
	bDoorOpen = IsCurrentlyInOperation;
	// End:0x5B
	if(__NFUN_119__(DoorPortal, none))
	{
		DoorPortal.bOpenPortals = bIsInOperation;
		// End:0x87
		if(__NFUN_154__(int(DynamicShadowBehavior), int(1)))
		{
			ShouldCastDynamicShadows = bIsInOperation;
			// [Explicit Continue]
			goto J0xCA;
		}
		// End:0xAA
		if(__NFUN_154__(int(DynamicShadowBehavior), int(2)))
		{
			ShouldCastDynamicShadows = true;
			goto J0xCA;
			assert(__NFUN_154__(int(DynamicShadowBehavior), int(0)));
			ShouldCastDynamicShadows = false;
		}
		SetCastShadowMapShadow(ShouldCastDynamicShadows);
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x165
		/*@Error*/
	}
	Model = DoorModel(DoorAttachments[i]);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x157
	/*@Error*/
	Model.SetCastShadowMapShadow(ShouldCastDynamicShadows);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0xE9;
	return;
	@NULL
	Item
	Item
	@NULL
}

function PostBeginPlay()
{
	log('Doors', 4, __NFUN_112__(string(self), "---ShockDoor::PostBeginPlay()."));
	super(Actor).PostBeginPlay();
	UpdateDoorOperationalStatus(false);
	// End:0x99
	if(bInitiallyOpen)
	{
		log('Doors', 3, __NFUN_112__(string(self), " starting initially open"));
		InitialState = 'DoorJumpOpening';
		return;
		@NULL
		Item
	}
	Item
}

function PostLoadGame()
{
	super(Actor).PostLoadGame();
	__NFUN_262__(true);
	__NFUN_283__(default.CollisionRadius, default.CollisionHeight);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function SetBrokenState(bool IsBroken)
{
	bBroken = IsBroken;
	return;
	@NULL
	Item
}

function AddUniquePawnToPawnsInsideDoor(ShockPawn iPawn)
{
	local int i;

	i = 0;
	// End:0x54
	if(__NFUN_150__(i, PawnsInsideDoor.Length))
	{
		// End:0x46
		if(__NFUN_114__(PawnsInsideDoor[i], iPawn))
		{
			return;
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x0B;
			PawnsInsideDoor[PawnsInsideDoor.Length] = iPawn;
		}
		iPawn.SetDoorPawnIsIn(self);
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function PawnInDoorWasDestroyed(ShockPawn iPawn)
{
	local int i;

	i = 0;
	// End:0x68
	if(__NFUN_150__(i, PawnsInsideDoor.Length))
	{
		// End:0x5A
		if(__NFUN_114__(PawnsInsideDoor[i], iPawn))
		{
			PawnsInsideDoor.Remove(i, 1);
			return;
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x0B;
			AssertWithDescription(false, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), " was told to remove a destroyed pawn from door, but "), string(iPawn)), " was not in the array."));
		}
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function Touch(Actor Other)
{
	local ShockPawn ThePawn;

	// End:0x1C
	if(Other.bStatic)
	{
		return;
		ThePawn = ShockPawn(Other);
	}
	// End:0x83
	if(__NFUN_132__(__NFUN_132__(__NFUN_114__(ThePawn, none), __NFUN_129__(ThePawn.IsAlive())), ThePawn.bHidden))
	{
		return;
		// End:0xA1
		if(__NFUN_129__(ThePawn.CanOpenDoors()))
		{
			return;
			log('Doors', 3, __NFUN_112__(__NFUN_112__(string(Other), " approached door "), string(self)));
		}
	}
	AddUniquePawnToPawnsInsideDoor(ThePawn);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1DF
	/*@Error*/
	// End:0x11B
	if(bLocked)
	{
		OnLockedDoorTouched(ThePawn);
		goto J0x1DF;
		// End:0x188
		if(__NFUN_129__(HasPower()))
		{
			log('Doors', 4, __NFUN_112__(string(Other), " approached door, but the door has no power. Not opening...."));
		}
		goto J0x1DF;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x1B2
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x1AF
		/*@Error*/
		__NFUN_113__('InBrokenOperation');
		goto J0x1DF;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x1DF
		/*@Error*/
		InitialState = 'DoorOpening';
		__NFUN_113__('DoorOpening');
	}
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function OnLockedDoorTouched(ShockPawn ThePawn)
{
	log('Doors', 4, __NFUN_112__(string(ThePawn), " approached door, but the door was locked. Not opening...."));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x86
	/*@Error*/
	TriggerEffectEvent('DoorLockedCannotOpen');
	return;
	@NULL
	Item
}

function Open()
{
	// End:0x5D
	if(bLocked)
	{
		AssertWithDescription(false, __NFUN_112__(string(self), " was told to open, but the door was locked. Not opening...."));
		goto J0xE4;
		// End:0xBE
		if(__NFUN_129__(HasPower()))
		{
		}
		AssertWithDescription(false, __NFUN_112__(string(self), " was told to open, but the door has no power. Not opening...."));
		goto J0xE4;
		// End:0xD9
		if(bBroken)
		{
			__NFUN_113__('InBrokenAnimation');
		}
		goto J0xE4;
		__NFUN_113__('DoorOpening');
		return;
		@NULL
	}
	Item
	Item
	@NULL
}

function OpenAndHold()
{
	bInitiallyOpen = true;
	bToldToClose = false;
	Open();
	return;
	@NULL
	Item
}

function bool AlivePawnsInsideDoor()
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x57
	/*@Error*/
	// End:0x49
	if(PawnsInsideDoor[i].IsAlive())
	{
		return true;
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x0B;
		return false;
		return;
		@NULL
		Item
	}
	Item
	@NULL
}

function OpenIfPossible()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x37
	/*@Error*/
	Open();
	return;
	@NULL
}

function OpenForLowDetailAI(ShockPawn AI)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x93
	/*@Error*/
	AddUniquePawnToPawnsInsideDoor(AI);
	InitialState = 'DoorOpening';
	__NFUN_113__('DoorOpening');
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function bool isIdle()
{
	return true;
	return;
}

// Export UShockDoor::execIsLocked(FFrame&, void* const)
native function bool IsLocked();

// Export UShockDoor::execIsClosed(FFrame&, void* const)
native function bool IsClosed();

// Export UShockDoor::execIsOpen(FFrame&, void* const)
native function bool IsOpen();

function bool IsOpenable()
{
	return bOpenable;
	return;
	@NULL
}

function unlock()
{
	log('Doors',, __NFUN_112__(string(self), " was unlocked."));
	TriggerEffectEvent('DoorWasUnlocked');
	bLocked = false;
	OpenIfPossible();
	return;
	@NULL
}

function Lock()
{
	log('Doors',, __NFUN_112__(string(self), " was locked."));
	TriggerEffectEvent('DoorWasLocked');
	bLocked = true;
	return;
	@NULL
}

function LockWithoutEffectEvents()
{
	log('Doors',, __NFUN_112__(string(self), " was locked without triggering any effect events."));
	bLocked = true;
	return;
	@NULL
}

function GivePermissionToClose()
{
	bInitiallyOpen = false;
	bToldToClose = true;
	return;
	@NULL
	Item
}

function ForceClose()
{
	// End:0x18
	if(bIsInOperation)
	{
		__NFUN_113__('DoorForceClosing');
		bInitiallyOpen = false;
	}
	bToldToClose = true;
	return;
	@NULL
	Item
	Item
}

function SetIsButtonDoor()
{
	bButtonDoor = true;
	return;
	@NULL
}

function bool IsBlocked()
{
	return AlivePawnsInsideDoor();
	return;
}

function bool IsMemberOfDoorAttachmentsArray(Actor inItem)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x54
	/*@Error*/
	// End:0x46
	if(__NFUN_114__(DoorAttachments[i], inItem))
	{
		return true;
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x0B;
		return false;
		return;
		@NULL
		Item
	}
	ShockPawn
	@NULL
}

function PlayAnimAndWaitForFinish(name inAnimation, float PlaybackRate)
{
	local int Handle;

	log('Doors', 5, __NFUN_112__(__NFUN_112__(__NFUN_112__("...inAnimation=", string(inAnimation)), ", index="), string(inAnimation)));
	LogDefaultAnims();
	Handle = PlayAnimationOnChannel(0, inAnimation, 4);
	SetAnimationPlaybackRate(Handle, PlaybackRate);
	__NFUN_256__(GetAnimationLengthScaled(Handle));
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function PlayAnimAndJumpToEnd(name inAnimation)
{
	local int Handle;
	local float animationLength;

	Handle = PlayAnimationOnChannel(0, inAnimation, 4);
	animationLength = GetAnimationLengthAbsolute(Handle);
	SetAnimationCurrentTime(Handle, animationLength);
	return;
	@NULL
	Item
	Item
	@NULL
}

function LogDefaultAnims()
{
	local array<name> theAnims;
	local int i;

	theAnims = GetAllAnimationsInGroup('Default');
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA5
	/*@Error*/
	log('Doors', 5, __NFUN_112__(__NFUN_112__(__NFUN_112__("......index=", string(theAnims[i])), ", name="), string(theAnims[i])));
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x28;
	return;
	@NULL
	Item
	Item
	@NULL
}

function DestroyAttachmentsOnDoors()
{
	local int i;
	local DoorModel DoorPiece;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x7D
	/*@Error*/
	DoorPiece = DoorModel(DoorAttachments[i]);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6F
	/*@Error*/
	DoorPiece.DestroyAttachments();
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function OnActorAttached(DoorModel DoorPiece, Actor Other)
{
	local StickyProjectile OtherStickyProjectile;

	OtherStickyProjectile = StickyProjectile(Other);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x8E
	/*@Error*/
	OtherStickyProjectile.ExplodeOnNextTick();
	return;
	@NULL
	Item
	Item
	@NULL
}

function FuseBox GetFuseBox()
{
	return FuseBox;
	return;
	@NULL
}

protected function OnFuseBlown()
{
	return;
}

protected function OnFuseReplaced()
{
	OpenIfPossible();
	return;
}

function bool HasPower()
{
	return __NFUN_132__(__NFUN_114__(FuseBox, none), FuseBox.HasFuse());
	return;
	@NULL
	Item
}

state InBrokenOperation
{Begin:

	log('Doors', 4, __NFUN_112__(string(self), "Playing broken animation"));
	PlayAnimAndWaitForFinish(BrokenAnimationName, BrokenAnimationRate);
	__NFUN_113__('DoorClosed');
	stop;	
	@NULL
	@NULL
}

state DoorOpening
{
	ignores Open;

	function bool isIdle()
	{
		return false;
		return;
	}
Begin:

	log('Doors', 4, __NFUN_112__(string(self), " opening..."));
	log('Doors', 4, __NFUN_112__(string(self), " at Begin of state 'DoorOpening'."));
	DestroyAttachmentsOnDoors();
	// End:0x8B
	if(__NFUN_119__(ForceActor, none))
	{
		ForceActor.SetEnabled(false);
		UpdateDoorOperationalStatus(true);
	}
	// End:0xDD
	if(__NFUN_130__(__NFUN_119__(DoorPortal, none), __NFUN_176__(__NFUN_175__(Level.TimeSeconds, LastRenderTime), float(5))))
	{
		__NFUN_256__(DelayBeforeOpening);
		TriggerEffectEvent('DoorOpened');
		dispatchMessage(Class'ShockGame.MessageDoorOpen'.static.Allocate(self)., construct_Name(Label));
	}
	bIsMoving = true;
	PlayAnimAndWaitForFinish(OpenAnimationName, OpenAnimationRate);
	bIsMoving = false;
	UpdateAttachmentLocations();
	// End:0x183
	if(bInitiallyOpen)
	{
		__NFUN_113__('DoorHoldingOpen');
		goto J0x18E;
		__NFUN_113__('DoorOpen');
		stop;		
		@NULL
		@NULL
		@NULL
		@NULL
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		/*@Error*/
		// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.get_CurrentToken() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 40
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 845
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
		// 1 & Type:If Position:0x183
	}
}

state DoorJumpOpening
{
	ignores Open;

	function bool isIdle()
	{
		return false;
		return;
	}
Begin:

	log('Doors', 4, __NFUN_112__(string(self), " opening..."));
	log('Doors', 4, __NFUN_112__(string(self), " at Begin of state 'DoorJumpOpening'."));
	DestroyAttachmentsOnDoors();
	// End:0x8F
	if(__NFUN_119__(ForceActor, none))
	{
		ForceActor.SetEnabled(false);
		UpdateDoorOperationalStatus(true);
	}
	bIsMoving = true;
	PlayAnimAndJumpToEnd(OpenAnimationName);
	bIsMoving = false;
	__NFUN_256__(0.1000000);
	UpdateAttachmentLocations();
	// End:0xF2
	if(bInitiallyOpen)
	{
		__NFUN_113__('DoorHoldingOpen');
		goto J0xFD;
		__NFUN_113__('DoorOpen');
		stop;				
	}
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

state DoorOpen
{
	ignores Open;

	function bool isIdle()
	{
		return false;
		return;
	}
Begin:

	// End:0x27
	if(__NFUN_119__(ForceActor, none))
	{
		ForceActor.SetEnabled(false);
		// End:0x43
		if(AlivePawnsInsideDoor())
		{
		}
		__NFUN_256__(StayOpenDuration);
		// [Loop Continue]
		goto J0x27;
		__NFUN_113__('DoorClosing');
		stop;
	}	
	@NULL
	@NULL
	@NULL
}

state DoorClosing
{
	ignores Open;

	function bool isIdle()
	{
		return false;
		return;
	}
Begin:

	DestroyAttachmentsOnDoors();
	// End:0x9C
	if(IsBlocked())
	{
		log('Doors', 4, __NFUN_112__(string(self), " is blocked. Playing blocked animation."));
		TriggerEffectEvent('DoorWasBlocked');
		SetAnimationPlaybackRate(PlayAnimationOnChannel(0, BlockedAnimationName, 4), BlockedAnimationRate);
		__NFUN_113__('DoorOpen');
		log('Doors', 4, __NFUN_112__(string(self), " closing..."));
	}
	TriggerEffectEvent('DoorClosed');
	// End:0xF8
	if(__NFUN_119__(ForceActor, none))
	{
		ForceActor.SetEnabled(true);
		bIsMoving = true;
		PlayAnimAndWaitForFinish(CloseAnimationName, CloseAnimationRate);
	}
	bIsMoving = false;
	UpdateDoorOperationalStatus(false);
	UpdateAttachmentLocations();
	// End:0x16D
	if(__NFUN_130__(__NFUN_129__(IsLocked()), IsBlocked()))
	{
		__NFUN_113__('DoorOpening');
		goto J0x178;
		__NFUN_113__('DoorClosed');
		stop;						
		@NULL
	}
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

state DoorForceClosing
{
	ignores Open;

	function bool isIdle()
	{
		return false;
		return;
	}
Begin:

	log('Doors', 4, __NFUN_112__(string(self), " closing..."));
	TriggerEffectEvent('DoorClosed');
	DestroyAttachmentsOnDoors();
	// End:0x66
	if(__NFUN_119__(ForceActor, none))
	{
		ForceActor.SetEnabled(true);
		bIsMoving = true;
	}
	PlayAnimAndWaitForFinish(CloseAnimationName, CloseAnimationRate);
	bIsMoving = false;
	UpdateDoorOperationalStatus(false);
	UpdateAttachmentLocations();
	// End:0xDB
	if(__NFUN_130__(__NFUN_129__(IsLocked()), IsBlocked()))
	{
		__NFUN_113__('DoorOpening');
		goto J0xE6;
		__NFUN_113__('DoorClosed');
		stop;		
	}
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

state DoorClosed
{Begin:

	stop;			
}

state DoorHoldingOpen
{
	ignores Open;

	function bool isIdle()
	{
		return false;
		return;
	}
Begin:

	// End:0x27
	if(__NFUN_119__(ForceActor, none))
	{
		ForceActor.SetEnabled(false);
		// End:0x41
		if(__NFUN_129__(bToldToClose))
		{
		}
		__NFUN_256__(0.2500000);
		// [Loop Continue]
		goto J0x27;
		__NFUN_113__('DoorClosing');
		stop;
	}			
	@NULL
	@NULL
	@NULL
}

defaultproperties
{
	StayOpenDuration=5.0000000
	DelayBeforeOpening=0.2500000
	DynamicShadowBehavior=2
	OpenAnimationName="TestDoorOpen"
	CloseAnimationName="TestDoorClose"
	BlockedAnimationName="TestDoorStuck"
	BrokenAnimationName="DoorBroken"
	OpenAnimationRate=1.0000000
	CloseAnimationRate=1.0000000
	BlockedAnimationRate=1.0000000
	BrokenAnimationRate=1.0000000
	DoorCloseRadiusMultiplier=1.5000000
	bDoNotSpawnAIs=true
	Physics=10
	DrawType=8
	bStatic=false
	bHidden=false
	bOccludesSound=true
	bInGameRenderable=true
	Mesh=SkeletalMesh'SimpleAnim.SimpleAnim'
	bCollideWhenPlacing=false
	CollisionRadius=90.0000000
	CollisionHeight=80.0000000
	bCollideActors=true
	bBlockZeroExtentTraces=false
	bUseCylinderCollision=true
	bDirectional=true
	bPathColliding=true
	ShouldSerializeSkeletonInstance=true
}