class TrainingConcept extends Action
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var /*0x00000000-0x00100000*/ travel name ConceptName;
var /*0x00000000-0x00100000*/ private travel float KnowledgeLevel;
var export editinline travel array<export editinline TrainingCondition> Conditions;
var export editinline travel array<export editinline TrainingMessageTrigger> MessageTriggers;
var private travel bool enabled;
var private travel float LastTriggeredKnowledgeLevel;

function editorDisplayString(out string S)
{
	S = __NFUN_168__(__NFUN_168__(__NFUN_168__("Concept", string(ConceptName)), "with initial knowledge of"), string(KnowledgeLevel));
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function bool editorInDropDown(Action parentAction)
{
	return __NFUN_130__(__NFUN_114__(parentAction, none), __NFUN_258__(parentScript.Class, Class'ShockGame.TrainingScript'));
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function SetEnabled(bool enabled)
{
	self.enabled = enabled;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xE7
	/*@Error*/
	// End:0xAE
	if(enabled)
	{
		SLog(__NFUN_168__(__NFUN_168__("Training concept", string(ConceptName)), " is enabled"));
		goto J0xE7;
		SLog(__NFUN_168__(__NFUN_168__("Training concept", string(ConceptName)), " is disabled"));
	}
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function setParentScript(Script S)
{
	local int i;

	super.setParentScript(S);
	i = 0;
	// End:0xA9
	if(__NFUN_150__(i, Conditions.Length))
	{
		// End:0x9B
		if(__NFUN_119__(Conditions[i], none))
		{
			Conditions[i].Concept = self;
			Conditions[i].setParentScript(S);
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x1E;
			i = 0;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x13F
			/*@Error*/
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x131
			/*@Error*/
			MessageTriggers[i].Concept = self;
		}
	}
	MessageTriggers[i].setParentScript(S);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0xB4;
	return;
	@NULL
	Item
	Item
	@NULL
}

function float GetKnowledge()
{
	return KnowledgeLevel;
	return;
	@NULL
}

function SetKnowledge(float KnowledgeLevel)
{
	self.KnowledgeLevel = KnowledgeLevel;
	// End:0x85
	if(__NFUN_132__(__NFUN_130__(__NFUN_176__(LastTriggeredKnowledgeLevel, KnowledgeLevel), __NFUN_178__(KnowledgeLevel, 0.0000000)), __NFUN_130__(__NFUN_177__(LastTriggeredKnowledgeLevel, KnowledgeLevel), __NFUN_177__(KnowledgeLevel, 0.0000000))))
	{
		LastTriggeredKnowledgeLevel = KnowledgeLevel;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x110
		/*@Error*/
	}
	SLog(__NFUN_168__(__NFUN_168__(__NFUN_168__("Knowledge of concept", string(ConceptName)), "="), string(KnowledgeLevel)));
	return;
	@NULL
	Item
	Item
	@NULL
}

function ModifyKnowledge(float Weight)
{
	local float NewKnowledgeLevel;

	NewKnowledgeLevel = __NFUN_246__(__NFUN_174__(KnowledgeLevel, Weight), -1.0000000, 1.0000000);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x54
	/*@Error*/
	SetKnowledge(NewKnowledgeLevel);
	return;
	@NULL
	Item
	Item
	@NULL
}

function TriggerMessage(TrainingMessageTrigger Trigger)
{
	KnowledgeLevel = Trigger.KnowledgeLevel;
	LastTriggeredKnowledgeLevel = Trigger.KnowledgeLevel;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xE5
	/*@Error*/
	SLog(__NFUN_168__(__NFUN_168__(__NFUN_168__("Setting Knowledge of concept", string(ConceptName)), "to triggered value:"), string(KnowledgeLevel)));
	Trigger.latentExecute();
	return;
	@NULL
	Collectable
	ShockPawn
	@NULL
}

function PossiblyTriggerMessage()
{
	local int TriggerIndex, i;
	local bool TriggerConditionsMet;

	TriggerIndex = -1;
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x25A
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x24C
	/*@Error*/
	MessageTriggers[i].ConditionsMet();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x24C
	/*@Error*/
	// BadToken (0x51)
	// BadToken (0x4E)
	goto __NFUN_165__(i);
	// [Loop Continue]
	goto J0x1A;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x28A
	/*@Error*/
	TriggerMessage(MessageTriggers[TriggerIndex]);
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function TrainingMessageDisplayed(TrainingMessageTrigger Trigger)
{
	TrainingScript(parentScript).TrainingMessageDisplayed(Trigger);
	return;
	@NULL
	Item
	Item
}

function TrainingMessageClearedFromQueue(TrainingMessageTrigger Trigger)
{
	TrainingScript(parentScript).TrainingMessageClearedFromQueue(Trigger);
	return;
	@NULL
	Item
	Item
}

function Variable latentExecute()
{
	local int i;

	// End:0x11
	if(__NFUN_129__(enabled))
	{
		return none;
		super.latentExecute();
	}
	PossiblyTriggerMessage();
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x14B
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x13D
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x11B
	/*@Error*/
	Conditions[i].DelayedTickCount = 0;
	Conditions[i].latentExecute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x118
	/*@Error*/
	return none;
	goto J0x13D;
	__NFUN_163__(Conditions[i].DelayedTickCount);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x30;
	return none;
	return;
	@NULL
	Collectable
	Item
	@NULL
}

defaultproperties
{
	enabled=true
	actionDisplayName="A Concept that requires training"
	actionHelp=""
	Category="Training"
	bIsGameCritical=false
}