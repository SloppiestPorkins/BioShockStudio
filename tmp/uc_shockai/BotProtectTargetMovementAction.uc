class BotProtectTargetMovementAction extends BotBaseMovementBehaviorAction
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn ProtectTarget;
var private MoveToGoal CurrentMoveToGoal;
var private Vector HoverPoint;
var private Vector HoverPointOffset;
var private Rotator DesiredBotRotation;
var private bool UseDesiredBotRotation;
var private SecurityBot MyBot;
var private bool CanPerformSillyAction;
var private float NextSillyActionTime;
var private float VerticalSwayEnableTime;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	MyBot = SecurityBot(m_Pawn);
	assert(__NFUN_119__(MyBot, none));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	MyBot.SetEnableVerticalSway(false);
	// End:0x41
	if(__NFUN_119__(CurrentMoveToGoal, none))
	{
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		super(AI_CharacterAction).Cleanup();
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
	@NULL
}

function InitializeMovement()
{
	assert(__NFUN_114__(CurrentMoveToGoal, none));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, m_Pawn.Location, true);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__GetUpdatedDestination__Delegate = GetUpdatedDestination;
	CurrentMoveToGoal.__OnMoveStarted__Delegate = OnMoveStarted;
	CurrentMoveToGoal.__OnMoveEnded__Delegate = OnMoveEnded;
	CurrentMoveToGoal.__OnDestinationReached__Delegate = OnDestinationReached;
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetDesiredRotationOverride;
	CurrentMoveToGoal.__NotifyCannotFindWayToDestination__Delegate = NotifyCannotFindWayToDestination;
	CurrentMoveToGoal.SetAlignmentAllowedDeltaYaw(MyBot.AlignmentAllowedDeltaYaw);
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	CurrentMoveToGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool PointIsValidHoverPoint(out Vector TestHoverPoint)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x59
	/*@Error*/
	return true;
	return false;
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

// Export UBotProtectTargetMovementAction::execGetAdditionalProtectTargetVelocityModifier(FFrame&, void* const)
protected native function Vector GetAdditionalProtectTargetVelocityModifier();

function Vector GetCurrentHoverPointFromOffset()
{
	return __NFUN_215__(__NFUN_215__(ProtectTarget.Location, HoverPointOffset), GetAdditionalProtectTargetVelocityModifier());
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function bool SetNextHoverPoint(bool ForceNewHoverOffset)
{
	local Vector NewPoint;
	local bool Found;

	NewPoint = GetCurrentHoverPointFromOffset();
	// End:0xC8
	if(__NFUN_132__(__NFUN_132__(ForceNewHoverOffset, __NFUN_129__(PointIsValidHoverPoint(NewPoint))), IsNearlyZero(HoverPointOffset)))
	{
		Found = FindCylinderPoint(ProtectTarget, NewPoint);
		// End:0xC5
		if(Found)
		{
			HoverPoint = NewPoint;
			HoverPointOffset = __NFUN_216__(HoverPoint, ProtectTarget.Location);
			goto J0xDB;
			HoverPoint = NewPoint;
			log('AI_Security', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn), " new HoverPoint = "), string(HoverPoint)), ", HoverPointOffset = "), string(HoverPointOffset)));
		}
	}
	return Found;
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function bool FindCylinderPoint(ShockPawn Target, out Vector oResult)
{
	local float DistanceFromTarget, HeightAboveTarget;
	local int FailedPoints;
	local Vector HoverVector;
	local float HoverAngle, SectorSize;
	local Vector TestPoint;

	SectorSize = __NFUN_172__(__NFUN_171__(2.0000000, 3.1415927), float(Target.GetNumSectors()));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x250
	/*@Error*/
	DistanceFromTarget = MyBot.GetRandomDesiredDistanceWhileProtecting();
	HeightAboveTarget = MyBot.GetRandomDesiredHeightWhileProtecting();
	HoverAngle = RandRange(__NFUN_171__(SectorSize, float(MyBot.GetSector())), __NFUN_171__(SectorSize, float(__NFUN_146__(MyBot.GetSector(), 1))));
	HoverVector.X = __NFUN_171__(__NFUN_188__(HoverAngle), DistanceFromTarget);
	HoverVector.Y = __NFUN_171__(__NFUN_187__(HoverAngle), DistanceFromTarget);
	HoverVector.Z = HeightAboveTarget;
	TestPoint = __NFUN_215__(Target.Location, HoverVector);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x214
	/*@Error*/
	oResult = TestPoint;
	return true;
	MyBot.SetSector(ProtectTarget.GetAvailableSector());
	__NFUN_163__(FailedPoints);
	// [Loop Continue]
	goto J0x31;
	return false;
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function UpdateBotRotation()
{
	assert(__NFUN_119__(MoveToAction(CurrentMoveToGoal.achievingAction), none));
	MoveToAction(CurrentMoveToGoal.achievingAction).UpdateRotation();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function GetUpdatedDestination(out Actor outDestinationActor, out Vector outDestinationLocation)
{
	outDestinationLocation = HoverPoint;
	return;
	@NULL
	CommanderAction
}

function OnDestinationReached()
{
	CanPerformSillyAction = true;
	NextSillyActionTime = __NFUN_174__(MyBot.Level.TimeSeconds, MyBot.GetRandomSillyActionDelta());
	DesiredBotRotation = Rotator(__NFUN_216__(MyBot.Location, ProtectTarget.Location));
	UseDesiredBotRotation = true;
	UpdateBotRotation();
	VerticalSwayEnableTime = __NFUN_174__(MyBot.Level.TimeSeconds, MyBot.VerticalSwayDelay);
	MyBot.PlaySpeech('ReachedProtectTarget');
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool GetDesiredRotationOverride(out Rotator DesiredRotation)
{
	DesiredRotation = DesiredBotRotation;
	return UseDesiredBotRotation;
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function NotifyCannotFindWayToDestination()
{
	log('AI_Security', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn), " cannot find it's way to the destination "), string(HoverPoint)), ", offset is "), string(HoverPointOffset)), "."));
	SetNextHoverPoint(true);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function bool PointIsInValidProtectTargetRange(Vector TargetPoint, ShockPawn Target)
{
	//native.TargetPoint;
	//native.Target;	
	@NULL
	@NULL
}

function PerformSillyAction()
{
	local int SillyActionNumber;

	SillyActionNumber = __NFUN_167__(1);
	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " is performing silly action."));
	switch(SillyActionNumber)
	{
		// End:0x64
		case 0:
			PerformLookAtProtectTargetSillyAction();
			// End:0x67
			break;
			// End:0xFFFF
			default:
				return;
				break;
		}/* !MISMATCHING REMOVE, tried Switch got Type:Case Position:0x047! */
		@NULL
		EcologyAI
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:Case Position:0x064
	EcologyFighterCommanderAction
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:Case Position:0x064
	// Failed to format remaining nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 724
	// 1 & Type:Case Position:0x064
}

function PerformLookAtProtectTargetSillyAction()
{
	local int i;

	DesiredBotRotation = Rotator(__NFUN_216__(ProtectTarget.Location, MyBot.Location));
	UseDesiredBotRotation = true;
	UpdateBotRotation();
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xF1
	/*@Error*/
	__NFUN_256__(1.0000000);
	// End:0xB4
	if(__NFUN_132__(__NFUN_114__(ProtectTarget, none), __NFUN_129__(PointIsInValidProtectTargetRange(MyBot.Location, ProtectTarget))))
	{
		return;
		// End:0xE3
		if(__NFUN_154__(i, 1))
		{
			MyBot.PlaySpeech('FriendlySpeech');
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x5B;
		}
		DesiredBotRotation = ProtectTarget.Rotation;
		UpdateBotRotation();
		return;
		@NULL
		EcologyAI
		EcologyFighterCommanderAction
	}
	@NULL
}

function StayWithTarget()
{
	SetNextHoverPoint(true);
	J0x0B:

	// End:0x1E0 [Loop If]
	if(__NFUN_119__(ProtectTarget, none))
	{
		// End:0xD8
		if(__NFUN_132__(__NFUN_129__(PointIsInValidProtectTargetRange(HoverPoint, ProtectTarget)), __NFUN_129__(PointIsInValidProtectTargetRange(MyBot.Location, ProtectTarget))))
		{
			SetNextHoverPoint(false);
			CanPerformSillyAction = false;
			UseDesiredBotRotation = false;
			MyBot.SetEnableVerticalSway(false);
			VerticalSwayEnableTime = -1.0000000;
			MyBot.PlaySpeech('MovingToProtectTarget');
			goto J0x1D5;
			// End:0x145
			if(__NFUN_130__(__NFUN_179__(VerticalSwayEnableTime, 0.0000000), __NFUN_176__(VerticalSwayEnableTime, MyBot.Level.TimeSeconds)))
			{
			}
			MyBot.SetEnableVerticalSway(true);
			VerticalSwayEnableTime = -1.0000000;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x1D5
			/*@Error*/
			PerformSillyAction();
			NextSillyActionTime = __NFUN_174__(MyBot.Level.TimeSeconds, MyBot.GetRandomSillyActionDelta());
		}
		__NFUN_256__(0.2000000);
		// [Loop Continue]
		goto J0x0B;
		return;
		@NULL
		EcologyAI
		EcologyFighterCommanderAction
		@NULL
	}
}

state Running
{Begin:

	// End:0x88
	if(__NFUN_114__(ProtectTarget, none))
	{
		log('AI_Security', 2, __NFUN_112__(string(m_Pawn), " no longer has a protect target.  Exiting from BotProtectTargetMovementAction."));
		fail(1);
		InitializeMovement();
	}
	StayWithTarget();
	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " protect target is None, leaving BotProtectTargetMovementAction."));
	succeed();
	stop;		
	@NULL
	@NULL
	@NULL
}

defaultproperties
{
	VerticalSwayEnableTime=-1.0000000
	satisfiesGoal=Class'ShockAI.BotProtectTargetMovementGoal'
}