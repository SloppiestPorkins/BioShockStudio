class Script extends Actor
	native
	config
	placeable
	hidecategories(DrawScale3D,DisplayAdvanced,Lighting,Display,Movement,Advanced,Events,Object,Placement,Sound,Collision,Havok,Force,Pressure,Animation);

var(Scripting) Class<Message> scriptMessageClass;
var(Scripting) export editinline Message messageFilter;
var(Scripting) export editinline array<export editinline Action> Actions;
var(Scripting) travel bool enabled;
var(Scripting) travel bool ShouldExecuteCriticalActionsImmediately;
var bool bIsExecuting;
var Script BlockedParentScript;
var array<WatcherBase> watchers;
var private travel bool bExitScript;
var private travel bool bExitLoop;
var private Message CurrentMessage;
var array<Message> MessageQueue;
var travel array<Variable> variables;
var travel array<Variable> tempVariables;
var bool bExecuteCriticalActionsImmediately;
var int CurrentlyExecutingActionIndex;

function bool IsChildScript()
{
	return __NFUN_119__(BlockedParentScript, none);
	return;
	@NULL
}

function PreLevelTravel()
{
	// End:0x32
	if(__NFUN_130__(bIsExecuting, __NFUN_129__(IsChildScript())))
	{
		executeCriticalActionsImmediately();
		ClearStateFrame();
		super.PreLevelTravel();
	}
	return;
	@NULL
	Variable
}

// Export UScript::execClearStateFrame(FFrame&, void* const)
native function ClearStateFrame();

function BeginPlay()
{
	super.BeginPlay();
	setParentScript();
	// End:0x40
	if(__NFUN_123__(TriggeredBy, ""))
	{
		registerMessage(scriptMessageClass, TriggeredBy);
		return;
		@NULL
		Variable
		Variable
	}
	@NULL
}

function PostLoadGame()
{
	super.PostLoadGame();
	setParentScript();
	return;
	@NULL
}

function PostLevelTravel()
{
	super.PostLevelTravel();
	setParentScript();
	return;
	@NULL
}

function setParentScript()
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x53
	/*@Error*/
	Actions[i].setParentScript(self);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Variable
	stop;
	default.@NULL
}

simulated event SetInitialState()
{
	return;
}

function Timer()
{
	dispatchMessage(Class'Scripting.MessageTimerExpired'.static.Allocate(self)., Construct_Void());
	return;
	@NULL
}

function Variable findTempVariable(name VariableName)
{
	//native.VariableName;	
	@NULL
}

function Variable findVariable(name VariableName)
{
	//native.VariableName;	
	@NULL
}

function Variable findGlobalVariable(name VariableName)
{
	local int i;
	local array<Object> AllGlobalVariables;

	Level.GetGlobalTravelContainer().GetTravelObjectsOfClass(Class'Scripting.Variable', AllGlobalVariables);
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB3
	/*@Error*/
	J0x42:

	// End:0xA5 [Loop If]
	if(__NFUN_254__(AllGlobalVariables[i].Name, VariableName))
	{
		return Variable(AllGlobalVariables[i]);
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x42;
		return none;
		return;
		@NULL
		Variable
		stop;
		default.@NULL
	}
}

function Variable newGlobalVariable(name VariableName, Class<Variable> variableType)
{
	local Variable V;

	V = findGlobalVariable(VariableName);
	// End:0x36
	if(__NFUN_119__(V, none))
	{
		return V;
		V = variableType.static.Allocate(self,, string(VariableName)).;
	}
	Construct_Void();
	Level.GetGlobalTravelContainer().AddTravelObject(V);
	return V;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function Variable newVariable(name VariableName, Class<Variable> variableType)
{
	local Variable V;

	V = findVariable(VariableName);
	// End:0x36
	if(__NFUN_119__(V, none))
	{
		return V;
		variables[variables.Length] = variableType.static.Allocate(self,, __NFUN_112__("Variable_", string(VariableName))).;
	}
	Construct_Void();
	return variables[__NFUN_147__(variables.Length, 1)];
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function Variable newTemporaryVariable(Class<Variable> variableType, optional string initValue, optional name VariableName)
{
	local Variable V;

	// End:0x9E
	if(__NFUN_255__(VariableName, 'None'))
	{
		V = findTempVariable(VariableName);
		// End:0x4D
		if(__NFUN_119__(V, none))
		{
			return V;
			V = variableType.static.Allocate(self,, __NFUN_112__("TempVariable_", string(VariableName))).;
		}
		Construct_Void();
		goto J0xD6;
		V = variableType.static.Allocate(self,,, 134217728).;
	}
	Construct_Void();
	tempVariables[tempVariables.Length] = V;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x12B
	/*@Error*/
	V.SetPropertyText("value", initValue);
	return V;
	return;
	@NULL
	Variable
	stop;
	default.@NULL
}

function addWatcher(WatcherBase newWatcher)
{
	watchers[watchers.Length] = newWatcher;
	return;
	@NULL
	Variable
	Variable
}

function setWatcherEnabled(name watcherName, bool enabled)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xAD
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x9F
	/*@Error*/
	watchers[i].enabled = enabled;
	watchers[i].__NFUN_113__('LookAtExpression');
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function Exit()
{
	bExitScript = true;
	// End:0x3A
	if(bIsExecuting)
	{
		Actions[CurrentlyExecutingActionIndex].OnScriptExit();
		return;
		@NULL
		Variable
		Variable
	}
	@NULL
}

function bool continueExecution()
{
	return __NFUN_129__(bExitScript);
	return;
	@NULL
}

function enterLoop()
{
	bExitLoop = false;
	return;
	@NULL
}

function bool keepLooping()
{
	return __NFUN_130__(__NFUN_129__(bExitLoop), __NFUN_129__(bExitScript));
	return;
	@NULL
	Variable
}

function exitLoop()
{
	bExitLoop = true;
	return;
	@NULL
}

function onMessage(Message msg)
{
	// End:0x9C
	if(__NFUN_129__(enabled))
	{
		log('ScriptLog', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " ("), string(Label)), ") IGNORING message "), string(msg.Class.Name)), " because script is disabled"));
		return;
		// End:0x1A4
		if(__NFUN_129__(__NFUN_258__(msg.Class, scriptMessageClass)))
		{
		}
		log('ScriptLog', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " ("), string(Label)), ") IGNORING message "), string(msg.Class.Name)), " because message is wrong class:"), string(msg.Class.Name)), " is not a "), string(scriptMessageClass.Name)));
		return;
		// End:0x272
		if(__NFUN_130__(__NFUN_119__(messageFilter, none), __NFUN_129__(msg.passesFilter(messageFilter))))
		{
			log('ScriptLog', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " ("), string(Label)), ") IGNORING message "), string(msg.Class.Name)), " because message failed message filter"));
		}
		return;
		log('ScriptLog', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " ("), string(Label)), ") ACCEPTED message "), string(msg.Class.Name)), " and will start action execution"), string(msg.Class.Name)));
	}
	execute(msg);
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function Message triggeringMessage()
{
	return CurrentMessage;
	return;
	@NULL
}

function execute(Message msg)
{
	local Message msgCopy;
	local name PropName;

	assert(__NFUN_119__(msg, none));
	bExitScript = false;
	msgCopy = msg.Class.static.Allocate(self).;
	Construct_Void();
	// End:0xD1
	foreach AllProperties(msg.Class, Class'Engine.Message', PropName)
	{
		msgCopy.SetPropertyText(string(PropName), msg.GetPropertyTextByName(PropName));				
		// End:0x102
		if(__NFUN_114__(CurrentMessage, none))
		{
			CurrentMessage = msgCopy;
			__NFUN_113__('ExecuteScript');
			goto J0x1A5;
			log('ScriptLog', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " ("), string(Label)), ") is already running, queueing message "), string(msg.Class.Name)), "."));
		}
	}
	MessageQueue[MessageQueue.Length] = msgCopy;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function executeFromExec()
{
	// End:0x63
	if(bIsExecuting)
	{
		log(,, __NFUN_112__(__NFUN_112__("Script ", string(Label)), " was denied execution because of attempted re-entry"));
		return;
		bExitScript = false;
	}
	__NFUN_113__('ExecuteScript');
	return;
	@NULL
	Variable
	Variable
}

function executeScriptFromScriptAction(bool blockCallingScript, Script inBlockedParentScript)
{
	// End:0x11
	if(__NFUN_129__(enabled))
	{
		return;
		bExitScript = false;
	}
	// End:0x64
	if(blockCallingScript)
	{
		assert(__NFUN_119__(inBlockedParentScript, none));
		BlockedParentScript = inBlockedParentScript;
		executeActions();
		BlockedParentScript = none;
		goto J0x6F;
		__NFUN_113__('ExecuteScript');
		return;
		@NULL
		MessageTriggerVolume
		Variable
	}
	@NULL
}

function doActions()
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x8F
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x81
	/*@Error*/
	CurrentlyExecutingActionIndex = i;
	Actions[i].latentExecute();
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x0B;
	CurrentlyExecutingActionIndex = 0;
	return;
	@NULL
	MessageTriggerVolume
	WatcherBase
	@NULL
}

function executeCriticalActionsInternal()
{
	J0x00:
	// End:0x97 [Loop If]
	if(__NFUN_130__(__NFUN_150__(CurrentlyExecutingActionIndex, Actions.Length), __NFUN_129__(bExitScript)))
	{
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x89
		/*@Error*/
		Actions[CurrentlyExecutingActionIndex].execute();
		__NFUN_165__(CurrentlyExecutingActionIndex);
		// [Loop Continue]
		goto J0x00;
		destroyTempVariables();
		return;
		@NULL
		Variable
		ActionBool
		@NULL
	}
}

function executeCriticalActionsImmediately()
{
	local int i;

	// End:0x20
	if(__NFUN_129__(__NFUN_132__(bIsExecuting, enabled)))
	{
		return;
		SLog(__NFUN_112__("Starting Critical,Immediate execution of script ", string(Label)));
	}
	bIsExecuting = true;
	bExecuteCriticalActionsImmediately = true;
	executeCriticalActionsInternal();
	ClearCurrentMessage();
	i = 0;
	// End:0x161
	if(__NFUN_150__(i, MessageQueue.Length))
	{
		log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__("Executing queued message ", string(__NFUN_146__(i, 1))), " of "), string(MessageQueue.Length)));
		// End:0x121
		if(__NFUN_132__(__NFUN_129__(enabled), bExitScript))
		{
			goto J0x161;
			CurrentMessage = MessageQueue[i];
			CurrentlyExecutingActionIndex = 0;
			executeCriticalActionsInternal();
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0xA0;
			ClearMessageQueue();
		}
		CurrentMessage = none;
		CurrentlyExecutingActionIndex = 0;
		bExitScript = true;
		bExecuteCriticalActionsImmediately = false;
		bIsExecuting = false;
		SLog(__NFUN_112__("Finished Critical,Immediate executing script ", string(Label)));
	}
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function executeActions()
{
	SLog(__NFUN_112__(__NFUN_112__(__NFUN_112__("Starting execution of script ", string(Label)), " at time "), string(Level.TimeSeconds)));
	bIsExecuting = true;
	doActions();
	ClearCurrentMessage();
	destroyTempVariables();
	bIsExecuting = false;
	SLog(__NFUN_112__(__NFUN_112__(__NFUN_112__("Finished executing script ", string(Label)), " at time "), string(Level.TimeSeconds)));
	return;
	@NULL
	MessageTriggerVolume
	ActionBool
	@NULL
}

// Export UScript::execdestroyTempVariables(FFrame&, void* const)
native function destroyTempVariables();

function ClearCurrentMessage()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x47
	/*@Error*/
	Level.MessageDispatcher.deleteMessage(CurrentMessage);
	CurrentMessage = none;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function ClearMessageQueue()
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x68
	/*@Error*/
	Level.MessageDispatcher.deleteMessage(MessageQueue[i]);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	MessageQueue.Remove(0, MessageQueue.Length);
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function enumValidMessages(LevelInfo L, out array< Class<Message> > S)
{
	local Class C, Base;
	local Class<Message> M;
	local Actor triggeredByActor;
	local name triggeredByActorLabel, triggeredByActorName;
	local array<string> triggeredByNames;
	local int i, j;
	local bool inArray;
	local string triggeredByName;

	// End:0x12
	if(__NFUN_122__(TriggeredBy, ""))
	{
		return;
		Base = Class'Engine.Message';
	}
	Split(TriggeredBy, ",", triggeredByNames);
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4BB
	/*@Error*/
	triggeredByActor = none;
	triggeredByActorLabel = 'None';
	triggeredByActorName = 'None';
	triggeredByName = ChopWhitespace(triggeredByNames[i]);
	triggeredByActor = findByLabel(Class'Engine.Actor', string(triggeredByName));
	// End:0x143
	if(__NFUN_119__(triggeredByActor, none))
	{
		triggeredByActorLabel = triggeredByActor.Label;
		triggeredByActorName = triggeredByActor.Class.Name;
		// End:0x28E
		if(__NFUN_124__(triggeredByName, "player"))
		{
			// End:0x28A
			foreach AllClasses(Base, C)
			{
				M = Class<Message>(C);
				// End:0x289
				if(__NFUN_130__(__NFUN_254__(M.default.specificTo.Name, 'ShockPlayer'), __NFUN_123__(M.static.editorDisplay(triggeredByActorLabel, none), "")))
				{
				}
				inArray = false;
				j = 0;
				// End:0x25C
				if(__NFUN_150__(j, S.Length))
				{
					// End:0x24E
					if(__NFUN_114__(S[j], M))
					{
						inArray = true;
						goto J0x25C;
						__NFUN_163__(j);
						goto J0x206;
						// End:0x289
						if(__NFUN_129__(inArray))
						{
							S[S.Length] = M;														
							goto J0x4AD;
							/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
								
							*/

							// End:0x376
							/*@Error*/
							S.Length = 0;
							// End:0x373
							foreach AllClasses(Base, C)
							{
								M = Class<Message>(C);
								/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
									
								*/

								// End:0x372
								/*@Error*/
								S[S.Length] = M;
							}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x1EF! */														
						}
						J0x25C:

						return;
						// End:0x4AC
						foreach AllClasses(Base, C)
						{
							M = Class<Message>(C);
							/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
								
							*/

							// End:0x4AB
							/*@Error*/
						}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x25E! */
					}
				}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x15E! */
			}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x0E5! */
			inArray = false;
			j = 0;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x47E
			/*@Error*/
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x470
			/*@Error*/
			inArray = true;
			goto J0x47E;
			__NFUN_163__(j);
			goto J0x428;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x4AB
			/*@Error*/
			S[S.Length] = M;						
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x4F;
			return;
			@NULL
			Variable
			Variable
			@NULL
		}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x0D3! */
	}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x097! */
}

function string editorDisplayMessage(Class<Message> Input)
{
	// End:0x2C
	if(__NFUN_122__(TriggeredBy, ""))
	{
		return "'TriggeredBy' is empty";
		goto J0x81;
		// End:0x55
		if(__NFUN_114__(Input, none))
		{
		}
		return "No message specified";
		goto J0x81;
		return Input.static.editorDisplay(string(TriggeredBy), messageFilter);
	}
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function string editorDisplayFilter(Message Input)
{
	local string displayString;
	local name PropName;
	local string filterProp;

	// End:0x16
	if(__NFUN_114__(Input, none))
	{
		return "None";
		// End:0x6B
		if(__NFUN_114__(scriptMessageClass, none))
		{
		}
		return "None (must set scriptMessageClass before you can use messageFilter)";
		displayString = editorDisplayMessage(scriptMessageClass);
	}
	// End:0x162
	foreach AllEditableProperties(scriptMessageClass, Class'Engine.Message', PropName)
	{
		filterProp = messageFilter.GetPropertyTextByName(PropName);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x161
		/*@Error*/
		displayString = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(displayString, ", "), string(PropName)), "="), filterProp);				
		return displayString;
		return;
		@NULL
		Variable
		Variable
		@NULL
	}
}

state ExecuteScript
{
	ignores BeginState;
Begin:

	executeActions();
	// End:0x57
	if(__NFUN_130__(__NFUN_151__(MessageQueue.Length, 0), enabled))
	{
		CurrentMessage = MessageQueue[0];
		MessageQueue.Remove(0, 1);
		goto 'Begin';
		goto J0xE5;
		// End:0xDA
		if(__NFUN_151__(MessageQueue.Length, 0))
		{
			log('ScriptLog', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " ("), string(Label)), ") has queued messages but is disabled.  Clearing queue."));
		}
		ClearMessageQueue();
		__NFUN_113__('None');
		stop;				
	}
	@NULL
	J0xE5:

	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

defaultproperties
{
	enabled=true
	bHidden=true
	Texture=Texture'Scripting.Engine_res.S_Script'
}