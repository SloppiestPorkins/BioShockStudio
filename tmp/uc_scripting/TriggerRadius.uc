class TriggerRadius extends Trigger
	config
	placeable
	hidecategories(DrawScale3D,DisplayAdvanced,Lighting,Display,Movement,Events,Object,Sound,Havok,Force,Pressure,Animation);

var int MaxEnterCount;
var int MaxExitCount;
var bool RequireClearTrace;
var bool RequireIsVisible;
var private int EnterCount;
var private int ExitCount;

function Touch(Actor Other)
{
	local int i;

	// End:0x42
	if(IsOverlapping(Other))
	{
		// End:0x3F
		if(MeetsTriggerCriteria(Other))
		{
			DispatchEnter(Other);
			goto J0x133;
			i = 0;
			// End:0xAB
			if(__NFUN_150__(i, Touching.Length))
			{
			}
		}
		J0x4D:

		// End:0x9D [Loop If]
		if(__NFUN_114__(Touching[i], Other))
		{
			Touching.Remove(i, 1);
			goto J0xAB;
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x4D;
			i = 0;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x133
			/*@Error*/
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x125
			/*@Error*/
		}
	}
	Other.Touching.Remove(i, 1);
	goto J0x133;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0xB6;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function UnTouch(Actor Other)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xBB
	/*@Error*/
	SLog(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Class.Name), " "), string(Label)), " exited by "), string(Other.Label)), " of class "), string(Other.Class.Name)));
	DispatchExit(Other);
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function bool MeetsTriggerCriteria(Actor Triggerer)
{
	return __NFUN_130__(MeetsTraceCriteria(Triggerer), MeetsVisibilityCriteria(Triggerer));
	return;
	@NULL
	Variable
}

function bool MeetsTraceCriteria(Actor Triggerer)
{
	local Vector HitLocation, HitNormal;

	return __NFUN_132__(__NFUN_129__(RequireClearTrace), __NFUN_114__(Triggerer, __NFUN_277__(HitLocation, HitNormal, Triggerer.Location)));
	return;
	@NULL
	Variable
	ActionBool
	@NULL
}

function bool MeetsVisibilityCriteria(Actor Triggerer)
{
	local Pawn TriggeringPawn;

	// End:0x11
	if(__NFUN_129__(RequireIsVisible))
	{
		return true;
		TriggeringPawn = Pawn(Triggerer);
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x91
	/*@Error*/
	// End:0x75
	if(__NFUN_119__(none, PlayerController(TriggeringPawn.Controller)))
	{
		return Triggerer.__NFUN_532__();
		goto J0x8E;
		return TriggeringPawn.CanSee(self);
		goto J0x93;
		return true;
		return;
		@NULL
		Variable
	}
	ActionBool
	@NULL
}

function DispatchEnter(Actor Instigator)
{
	local bool CanBeTriggeredByThisActor, MaxCountExceeded;

	CanBeTriggeredByThisActor = CanTrigger(Instigator);
	MaxCountExceeded = __NFUN_130__(__NFUN_151__(MaxEnterCount, -1), __NFUN_153__(EnterCount, MaxEnterCount));
	SLog(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Class.Name), " '"), string(Label)), "' ENTERED by '"), string(Instigator.Label)), "' of class "), string(Instigator.Class.Name)), "(CanBeTriggeredByThisActor: "), string(CanBeTriggeredByThisActor)), ", maxEnterCount exceeded: "), string(MaxCountExceeded)), ")"));
	// End:0x168
	if(__NFUN_132__(__NFUN_129__(CanBeTriggeredByThisActor), MaxCountExceeded))
	{
		return;
		__NFUN_163__(EnterCount);
		dispatchMessage(Class'Scripting.MessageTriggerEnter'.static.Allocate(self)., construct_NameName(Label, Instigator.Label));
		return;
	}
	@NULL
	Variable
	ActionBool
	@NULL
}

function DispatchExit(Actor Instigator)
{
	local bool CanBeTriggeredByThisActor, MaxCountExceeded;

	CanBeTriggeredByThisActor = CanTrigger(Instigator, true);
	MaxCountExceeded = __NFUN_130__(__NFUN_151__(MaxExitCount, -1), __NFUN_153__(ExitCount, MaxExitCount));
	SLog(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Class.Name), " '"), string(Label)), "' EXITED by '"), string(Instigator.Label)), "' of class "), string(Instigator.Class.Name)), "(CanBeTriggeredByThisActor: "), string(CanBeTriggeredByThisActor)), ", maxEnterCount exceeded: "), string(MaxCountExceeded)), ")"));
	// End:0x168
	if(__NFUN_132__(__NFUN_129__(CanBeTriggeredByThisActor), MaxCountExceeded))
	{
		return;
		__NFUN_163__(ExitCount);
		dispatchMessage(Class'Scripting.MessageTriggerExit'.static.Allocate(self)., construct_NameName(Label, Instigator.Label));
		return;
	}
	@NULL
	Variable
	ActionBool
	@NULL
}

defaultproperties
{
	MaxEnterCount=-1
	MaxExitCount=-1
	CollisionRadius=40.0000000
	CollisionHeight=40.0000000
	bUseCylinderCollision=true
}