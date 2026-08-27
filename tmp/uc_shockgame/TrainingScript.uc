class TrainingScript extends Script
	native
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Lighting,Display,Movement,Advanced,Events,Object,Placement,Sound,Collision,Havok,Force,Pressure,Animation,Scripting);

enum ConflictResolutionStrategy
{
	CRS_Depth,                      // 0
	CRS_Breadth                     // 1
};

var export editinline travel array<export editinline TrainingConcept> Concepts;
var travel TrainingScript.ConflictResolutionStrategy ResolutionStrategy;
var travel int MaxConditionsExecutedPerFact;
var travel int MaxConditionsExecutedPerFrame;
var travel bool TravelWithPlayer;
var travel array<TrainingCondition> Agenda;
var private travel TrainingMessageTrigger TriggeredMessage;
var travel array<TrainingMessageTrigger> ClearedMessages;
var travel float tickTime;

// Export UTrainingScript::execPreBeginPlay(FFrame&, void* const)
native function PreBeginPlay();

function BeginPlay()
{
	super.BeginPlay();
	setParentScript();
	return;
	@NULL
}

function setParentScript()
{
	local int i;

	super.setParentScript();
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x76
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x68
	/*@Error*/
	Concepts[i].setParentScript(self);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x15;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function PostLoadGame()
{
	super.PostLoadGame();
	setParentScript();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5E
	/*@Error*/
	__NFUN_113__('ExecuteScript');
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function PostBeginPlay()
{
	super(Actor).PostBeginPlay();
	// End:0x54
	if(ShockGameDriver(Level.GetGameDriver()).GetTrainingMessageManager().EnableTrainingScripts)
	{
		__NFUN_113__('ExecuteScript');
		return;
		@NULL
		Item
		Item
	}
	@NULL
}

function PostLevelTravel()
{
	super.PostLevelTravel();
	// End:0x54
	if(ShockGameDriver(Level.GetGameDriver()).GetTrainingMessageManager().EnableTrainingScripts)
	{
		__NFUN_113__('ExecuteScript');
		return;
		@NULL
		Item
		Item
	}
	@NULL
}

function executeCriticalActionsImmediately()
{
	// End:0x11
	if(__NFUN_129__(enabled))
	{
		return;
		bExecuteCriticalActionsImmediately = true;
	}
	// End:0xCE
	if(__NFUN_119__(TriggeredMessage, none))
	{
		// End:0xAC
		if(ShockGameDriver(Level.GetGameDriver()).GetTrainingMessageManager().EnableTrainingLogs)
		{
			SLog("Performing actions after message is shown immediately");
			TriggeredMessage.executeCriticalShownActionsImmediately();
			TriggeredMessage = none;
		}
		destroyTempVariables();
		bExecuteCriticalActionsImmediately = false;
		bIsExecuting = false;
		return;
		@NULL
	}
	Item
	Item
	@NULL
}

function bool ExecuteTopAgenda()
{
	local int i;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x90
	/*@Error*/
	Agenda[i].executeActions();
	Agenda[i].Concept.ModifyKnowledge(Agenda[i].Weight);
	Agenda.Length = 0;
	return true;
	goto J0x92;
	return false;
	return;
	@NULL
	Collectable
	ShockPawn
	@NULL
}

function doActions()
{
	local int i;
	local bool Loop;

	// End:0x49
	if(TravelWithPlayer)
	{
		ShockPlayer(Level.GetLocalPlayerController().Pawn).AttachTrainingScript(self);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x2CB
		/*@Error*/
		tickTime = Level.TimeSeconds;
	}
	// End:0x11B
	if(__NFUN_119__(TriggeredMessage, none))
	{
		// End:0xF9
		if(ShockGameDriver(Level.GetGameDriver()).GetTrainingMessageManager().EnableTrainingLogs)
		{
			SLog("Performing actions after message is shown");
			TriggeredMessage.executeShownActions();
			TriggeredMessage = none;
			i = 0;
			// End:0x1EE
			if(__NFUN_150__(i, ClearedMessages.Length))
			{
			}
			// End:0x1BF
			if(ShockGameDriver(Level.GetGameDriver()).GetTrainingMessageManager().EnableTrainingLogs)
			{
			}
			SLog("Performing actions after message is cleared from queue");
			ClearedMessages[i].executeNotShownActions();
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x126;
			ClearedMessages.Length = 0;
			Loop = true;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x2B6
			/*@Error*/
			i = 0;
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x29C
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x28E
		/*@Error*/
	}
	Concepts[i].latentExecute();
	__NFUN_163__(i);
	goto J0x22D;
	ExecuteTopAgenda();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// [Loop Continue]
	/*@Error*/;
}

function AddToAgenda(TrainingCondition condition)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6F
	/*@Error*/
	// End:0x61
	if(__NFUN_151__(condition.Priority, Agenda[i].Priority))
	{
		goto J0x6F;
		__NFUN_165__(i);
		// [Loop Continue]
		goto J0x0B;
		Agenda[i] = condition;
		return;
		@NULL
	}
	Item
	Item
	@NULL
}

function TrainingMessageDisplayed(TrainingMessageTrigger Trigger)
{
	TriggeredMessage = Trigger;
	return;
	@NULL
	Item
}

function TrainingMessageClearedFromQueue(TrainingMessageTrigger Trigger)
{
	ClearedMessages[ClearedMessages.Length] = Trigger;
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	TravelWithPlayer=true
}