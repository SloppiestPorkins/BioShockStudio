class Trigger extends Actor
	abstract
	config
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced,Lighting,Display,Movement,Events,Object,Sound,Havok,Force,Pressure,Animation);

var string DebugLogString;
var const bool TriggeredOnlyByPawns;
var const array<name> triggeredByFilter;
var const bool AllowTheDeadToTriggerOnEnter;
var const bool AllowTheDeadToTriggerOnExit;
var bool Disabled;

function PreBeginPlay()
{
	super.PreBeginPlay();
	OnlyAffectPawns(TriggeredOnlyByPawns);
	return;
	@NULL
	Variable
	Variable
}

function bool CanTrigger(Actor TestActor, optional bool TestActorIsExiting)
{
	local int i;
	local bool ShouldIgnoreTriggersFromDeadPawns;

	// End:0x0F
	if(Disabled)
	{
		return false;
		// End:0x36
		if(TestActorIsExiting)
		{
		}
		ShouldIgnoreTriggersFromDeadPawns = __NFUN_129__(AllowTheDeadToTriggerOnExit);
		goto J0x4D;
		ShouldIgnoreTriggersFromDeadPawns = __NFUN_129__(AllowTheDeadToTriggerOnEnter);
		// End:0x9F
		if(__NFUN_130__(__NFUN_130__(__NFUN_129__(ShouldIgnoreTriggersFromDeadPawns), __NFUN_119__(Pawn(TestActor), none)), __NFUN_129__(Pawn(TestActor).IsAlive())))
		{
		}
		return false;
		// End:0xB1
		if(__NFUN_154__(triggeredByFilter.Length, 0))
		{
			return true;
			i = 0;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x112
			/*@Error*/
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x104
			/*@Error*/
		}
	}
	return true;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0xBC;
	return false;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function dispatchMessage(Message msg)
{
	// End:0x62
	if(__NFUN_123__(DebugLogString, ""))
	{
		SLog(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Class.Name), " "), string(Label)), " DEBUG STRING: "), DebugLogString));
		SLog(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Class.Name), " "), string(Label)), " is sending message "), string(msg.Class.Name)));
	}
	super.dispatchMessage(msg);
	return;
	@NULL
	Variable
	Variable
	@NULL
}

defaultproperties
{
	TriggeredOnlyByPawns=true
	bHidden=true
	Texture=Texture'Scripting.Engine_res.S_Trigger'
	bCollideActors=true
	bBlockZeroExtentTraces=false
}