class ActionFor extends Action
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var /*0x00000000-0x00100000*/ travel name counterName;
var travel float beginValue;
var travel float EndValue;
var export editinline travel array<export editinline Action> forActions;
var private int CurrentIndex;
var private VariableFloat CounterVar;
var private float End;

function OnScriptExit()
{
	// End:0x30
	if(__NFUN_153__(CurrentIndex, 0))
	{
		forActions[CurrentIndex].OnScriptExit();
		return;
		@NULL
		Variable
	}
	Variable
}

function setParentScript(Script S)
{
	local int i;

	super.setParentScript(S);
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6E
	/*@Error*/
	forActions[i].setParentScript(S);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x1E;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function Variable latentExecute()
{
	resolveParameters();
	CounterVar = VariableFloat(newVariable(counterName, Class'Scripting.VariableFloat'));
	// End:0x83
	if(__NFUN_114__(CounterVar, none))
	{
		logError("The counter variable must be a float variable");
		return none;
		CounterVar.Value = beginValue;
	}
	End = EndValue;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x165
	/*@Error*/
	CurrentIndex = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x148
	/*@Error*/
	forActions[CurrentIndex].latentExecute();
	__NFUN_163__(CurrentIndex);
	// [Loop Continue]
	goto J0xE5;
	CounterVar.Add("1");
	// [Loop Continue]
	goto J0xB6;
	CurrentIndex = -1;
	return none;
	return;
	@NULL
	MessageTriggerVolume
	Variable
	@NULL
}

function Variable execute()
{
	super.execute();
	// End:0xD4
	if(__NFUN_154__(CurrentIndex, -1))
	{
		CounterVar = VariableFloat(newVariable(counterName, Class'Scripting.VariableFloat'));
		// End:0x96
		if(__NFUN_114__(CounterVar, none))
		{
			logError("The counter variable must be a float variable");
			return none;
			CounterVar.Value = beginValue;
			End = EndValue;
		}
		CurrentIndex = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x1A7
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x17F
		/*@Error*/
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x171
	/*@Error*/
	J0xF8:

	forActions[CurrentIndex].execute();
	__NFUN_163__(CurrentIndex);
	// [Loop Continue]
	goto J0xF8;
	CurrentIndex = 0;
	CounterVar.Add("1");
	// [Loop Continue]
	goto J0xD4;
	CurrentIndex = -1;
	return none;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("For ", string(counterName)), " = "), propertyDisplayString('beginValue')), " to "), propertyDisplayString('EndValue'));
	return;
	@NULL
	Variable
}

defaultproperties
{
	counterName="forCounter"
	CurrentIndex=-1
	actionDisplayName="For Statement"
	actionHelp="Executes a list of actions n times."
	Category="Script"
}