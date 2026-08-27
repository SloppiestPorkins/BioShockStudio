class EventReactionAction extends BioshockCharacterAction
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private config float TurnToFaceEventLocationDegrees;
var private MoveToGoal CurrentMoveToGoal;
var private bool StopTrackingInCleanup;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	// End:0x33
	if(__NFUN_119__(CurrentMoveToGoal, none))
	{
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		ShockAI().AddLocomotionKeyword('ReactToEvent', Class'ShockAI.ShockAI'.-1);
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x8B
	/*@Error*/
	ShockAI().StopTracking();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyPausedDueToExclusivity()
{
	super(AI_RunnableAction).NotifyPausedDueToExclusivity();
	instantSucceed();
	return;
	@NULL
}

function Actor GetEventSourceActor()
{
	return EventReactionGoal(achievingGoal).GetEventSourceActor();
	return;
	@NULL
	CommanderAction
}

function Vector GetEventSourceLocation()
{
	return EventReactionGoal(achievingGoal).GetEventSourceLocation();
	return;
	@NULL
	CommanderAction
}

function Vector GetSecondaryEventLocation()
{
	return EventReactionGoal(achievingGoal).GetSecondaryEventLocation();
	return;
	@NULL
	CommanderAction
}

function AIEventNotification.EAIEventNotificationType GetEventNotificationType()
{
	return EventReactionGoal(achievingGoal).GetEventNotificationType();
	return;
	@NULL
	CommanderAction
}

function float GetEventReactionChance()
{
	return EventReactionGoal(achievingGoal).GetEventReactionChance();
	return;
	@NULL
	CommanderAction
}

function TurnTowardsReaction(EventReactionSpecifier Specifier)
{
	bExclusiveAction = true;
	// End:0x4F
	if(__NFUN_119__(GetEventSourceActor(), none))
	{
		ShockAI().QuickLook(GetEventSourceActor(), 30.0000000);
		StopTrackingInCleanup = true;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xD6
		/*@Error*/
	}
	StartMovement();
	// End:0xC9
	if(__NFUN_129__(Class'ShockAI.MoveToAction'.static.IsRotatedTo(m_Pawn.Rotation, Rotator(__NFUN_216__(GetEventSourceLocation(), m_Pawn.Location)))))
	{
		yield();
		// [Loop Continue]
		goto J0x66;
		RemoveMovementGoal();
		goto J0xDE;
		__NFUN_256__(2.0000000);
		return;
		@NULL
		EcologyAI
	}
	EcologyFighterCommanderAction
	@NULL
}

function LookTowardsReaction(EventReactionSpecifier Specifier)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x144
	/*@Error*/
	log('AI', 4, __NFUN_112__(__NFUN_112__("Quick looking.", string(Specifier.Duration.Min)), string(Specifier.Duration.Max)));
	ShockAI().QuickLook(GetEventSourceActor(), RandRange(Specifier.Duration.Min, Specifier.Duration.Max));
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function SearchReaction(EventReactionSpecifier Specifier)
{
	local EcologyFighter EcologyFighterAI;

	bExclusiveAction = true;
	TurnTowardsReaction(Specifier);
	EcologyFighterAI = EcologyFighter(m_Pawn);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x78
	/*@Error*/
	EcologyFighterAI.Investigate(GetSecondaryEventLocation(), vect(0.0000000, 0.0000000, 0.0000000));
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function React()
{
	local EventReactionSpecifier Specifier;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x14B
	/*@Error*/
	Specifier = ShockAI().GetEventReactionSpecifier(GetEventNotificationType());
	log('AI', 4, __NFUN_112__("Specifier: ", string(Specifier.ReactionType)));
	__NFUN_256__(RandRange(Specifier.Delay.Min, Specifier.Delay.Max));
	switch(Specifier.ReactionType)
	{
		// End:0x112
		case 1:
			LookTowardsReaction(Specifier);
			// End:0x14B
			break;
			// End:0x12D
			case 2:
				TurnTowardsReaction(Specifier);
				// End:0x14B
				break;
				// End:0x148
				case 3:
					SearchReaction(Specifier);
					// End:0x14B
					break;
					// End:0xFFFF
					default:
						return;
						break;
				}/* !MISMATCHING REMOVE, tried Switch got Type:Case Position:0x0DD! */
				@NULL
				EcologyAI
				EcologyFighterCommanderAction
				@NULL
	// Failed to format remaining nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 724
	// 1 & Type:Case Position:0x112
}

function bool ShouldRotateToFaceEventLocation()
{
	return __NFUN_129__(Class'ShockAI.MoveToAction'.static.IsRotatedTo(m_Pawn.Rotation, Rotator(__NFUN_216__(GetEventSourceLocation(), m_Pawn.Location)), int(__NFUN_171__(TurnToFaceEventLocationDegrees, 182.0444489))));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool GetRotationToEventLocation(out Rotator DesiredRotation)
{
	DesiredRotation = Rotator(__NFUN_216__(GetEventSourceLocation(), m_Pawn.Location));
	return true;
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function OnMoveStarted()
{
	return;
}

function OnMoveEnded()
{
	return;
}

function StartMovement()
{
	assert(__NFUN_114__(CurrentMoveToGoal, none));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, m_Pawn.Location);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetRotationToEventLocation;
	CurrentMoveToGoal.__OnMoveStarted__Delegate = OnMoveStarted;
	CurrentMoveToGoal.__OnMoveEnded__Delegate = OnMoveEnded;
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	CurrentMoveToGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function RemoveMovementGoal()
{
	assert(__NFUN_119__(CurrentMoveToGoal, none));
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	// End:0x47
	if(ShockAI().CanPlayEventReaction())
	{
		ShockAI().AddLocomotionKeyword('ReactToEvent', 1);
		React();
	}
	succeed();
	stop;		
}

defaultproperties
{
	TurnToFaceEventLocationDegrees=20.0000000
	satisfiesGoal=Class'ShockAI.EventReactionGoal'
}