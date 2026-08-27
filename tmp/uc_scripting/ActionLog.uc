class ActionLog extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var /*0x00000000-0x00100000*/ travel string Text;

function Variable execute()
{
	local string Result;
	local int Current, Left, Right, NextInterval;
	local string VariableName;
	local Variable Variable;
	local string VariableValue;

	super.execute();
	Left = __NFUN_126__(__NFUN_127__(Text, Current, __NFUN_147__(__NFUN_125__(Text), Current)), "[");
	// End:0x68
	if(__NFUN_150__(Left, 0))
	{
		Result = Text;
		goto J0x2E4;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x2A5
		/*@Error*/
		Result = __NFUN_112__(Result, __NFUN_127__(Text, Current, __NFUN_147__(Left, Current)));
	}
	Right = __NFUN_146__(Left, __NFUN_126__(__NFUN_127__(Text, __NFUN_146__(Left, 1), __NFUN_147__(__NFUN_125__(Text), Left)), "]"));
	// End:0x158
	if(__NFUN_152__(Right, Left))
	{
		logError("Syntax error in log string: unterminated square bracket");
		goto J0x2A5;
		VariableName = __NFUN_127__(Text, __NFUN_146__(Left, 1), __NFUN_147__(Right, Left));
		Variable = tryFindVariable(VariableName);
		// End:0x1EC
		if(__NFUN_114__(Variable, none))
		{
			VariableValue = __NFUN_112__(__NFUN_112__("(variable ", VariableName), " not found)");
		}
		goto J0x216;
		VariableValue = Variable.GetPropertyTextByName('Value');
		Result = __NFUN_112__(Result, VariableValue);
		Current = __NFUN_146__(Right, 2);
		NextInterval = __NFUN_126__(__NFUN_127__(Text, Current, __NFUN_147__(__NFUN_125__(Text), Current)), "[");
		Left = __NFUN_146__(Current, NextInterval);
		// [Loop Continue]
		goto J0x68;
		Result = __NFUN_112__(Result, __NFUN_127__(Text, Current, __NFUN_147__(__NFUN_125__(Text), Current)));
	}
	SLog(Result);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x348
	/*@Error*/
	parentScript.Level.GetLocalPlayerController().ClientMessage(Result, 'Debug');
	return none;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Log '", Text), "'");
	return;
	@NULL
	Variable
}

defaultproperties
{
	actionDisplayName="Log"
	actionHelp="Outputs to the Unreal log file. Use [<varname>] to output variables, i.e. 'The value of MyCounter is [MyCounter]'"
	Category="Other"
}