class Action extends Object
	abstract
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

struct native atomic ParameterResolveInfo
{
	var export editinline travel Action Action;
	var travel name Variable;
	var travel name PropertyName;
	var transient pointer Property;

	structdefaultproperties
	{
		CheckpointTypePadding=7471205
	}
};

var travel string actionDisplayName;
var travel string actionHelp;
var travel Class<Variable> returnType;
var travel string Category;
var editconst travel Script parentScript;
var travel bool acceptAllTypes;
var /*0x00000000-0x00100000*/ travel bool bIsGameCritical;
var travel array<ParameterResolveInfo> resolveInfoList;

function setParentScript(Script S)
{
	//native.S;	
	@NULL
}

// Export UAction::execresolveParameters(FFrame&, void* const)
native function resolveParameters();

function OnScriptExit()
{
	return;
}

function logError(string Reason)
{
	local string S;

	editorDisplayString(S);
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("ERROR: ", string(parentScript.Name)), ", Action "), S), ": "), Reason);
	SLog(S);
	return;
	@NULL
	Variable
	stop;
	default.@NULL
}

function Actor findByLabel(Class<Actor> actorClass, name Label)
{
	return parentScript.super(Action).findByLabel(actorClass, Label);
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function Variable newVariable(name VariableName, Class<Variable> variableType)
{
	// End:0x47
	if(__NFUN_124__(__NFUN_128__(string(VariableName), 7), "Global_"))
	{
		return parentScript.newGlobalVariable(VariableName, variableType);
		return parentScript.newVariable(VariableName, variableType);
	}
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function Variable newTemporaryVariable(Class<Variable> variableType, optional string initValue, optional name VariableName)
{
	return parentScript.newTemporaryVariable(variableType, initValue, VariableName);
	return;
	@NULL
	Variable
	stop;
	default.@NULL
}

function Variable findVariable(coerce string VariableName)
{
	local Variable V;

	V = Class'Scripting.Variable'.static.findVariable(VariableName, parentScript);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x70
	/*@Error*/
	logError(__NFUN_112__(__NFUN_112__("Variable ", VariableName), " not found"));
	return V;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function Variable tryFindVariable(coerce string VariableName)
{
	local Variable V;

	V = Class'Scripting.Variable'.static.findVariable(VariableName, parentScript);
	return V;
	return;
	@NULL
	Variable
	stop;
	default.@NULL
}

latent function Variable latentExecute()
{
	return execute();
	return;
}

function Variable execute()
{
	// End:0x1A
	if(__NFUN_151__(resolveInfoList.Length, 0))
	{
		resolveParameters();
		return none;
		return;
	}
	@NULL
}

function string propertyDisplayString(name PropName)
{
	local string S;
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x12E
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x120
	/*@Error*/
	// End:0xC7
	if(__NFUN_119__(resolveInfoList[i].Action, none))
	{
		resolveInfoList[i].Action.editorDisplayString(S);
		return S;
		goto J0x120;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x120
		/*@Error*/
		return string(resolveInfoList[i].Variable);
		__NFUN_165__(i);
		// [Loop Continue]
		goto J0x0B;
		return GetPropertyTextByName(PropName);
	}
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = actionDisplayName;
	return;
	@NULL
	Variable
}

event bool editorInDropDown(Action parentAction)
{
	return true;
	return;
}

function enumScriptLabels(LevelInfo Level, out array<name> S)
{
	local Actor A;

	// End:0xA8
	foreach Level.__NFUN_304__(Class'Engine.Actor', A)
	{
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xA7
		/*@Error*/
		S[S.Length] = A.Label;				
		return;
		@NULL
		Variable
		stop;
		default.@NULL
	}
}

function enumScripts(LevelInfo Level, out array<name> S)
{
	local Script aScript;

	// End:0x75
	foreach Level.__NFUN_304__(Class'Scripting.Script', aScript)
	{
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x74
		/*@Error*/
		S[S.Length] = aScript.Label;				
		return;
		@NULL
		Variable
		stop;
		default.@NULL
	}
}

event PostCheckpointRestore()
{
	return;
}

event Actor PrecacheGetSkinChangeTarget()
{
	return;
}

event Actor PrecacheDoSkinChange()
{
	return;
}

defaultproperties
{
	actionDisplayName="<actionDisplayName>"
	actionHelp="<actionHelp>"
	Category="Default Category"
	bIsGameCritical=true
}