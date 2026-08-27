class ActionExecuteScript extends Action
	abstract
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name targetScript;
var travel bool block;

function Script GetScriptToBeExecuted()
{
	local Script scriptToExecute;

	scriptToExecute = Script(findByLabel(Class'Scripting.Script', targetScript));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x26E
	/*@Error*/
	// End:0xD8
	if(__NFUN_130__(__NFUN_254__(parentScript.Level.Outer.Name, '2-Fisheries'), __NFUN_254__(scriptToExecute.Name, 'Script_170')))
	{
		parentScript.Level.Game.TempSavePlayerInventory();
		return none;
		goto J0x1D5;
		// End:0x1D5
		if(__NFUN_132__(__NFUN_130__(__NFUN_254__(parentScript.Level.Outer.Name, '2-Fisheries'), __NFUN_254__(scriptToExecute.Name, 'Script_368')), __NFUN_130__(__NFUN_254__(parentScript.Level.Outer.Name, '2-SubBay'), __NFUN_254__(scriptToExecute.Name, 'Script_56'))))
		{
		}
		parentScript.Level.Game.TempLoadPlayerInventory();
		return none;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x26B
		/*@Error*/
		log(,, __NFUN_112__(__NFUN_112__("Script ", string(targetScript)), " was denied execution because of attempted re-entry"));
	}
	return none;
	goto J0x2AA;
	logError(__NFUN_112__(__NFUN_112__("Could find script ", string(targetScript)), " to execute"));
	return none;
	return scriptToExecute;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function Variable latentExecute()
{
	local Script scriptToExecute;

	log(,, __NFUN_112__("Latent Script to be executed ", string(targetScript)));
	resolveParameters();
	scriptToExecute = GetScriptToBeExecuted();
	log(,, __NFUN_112__("Script = ", string(scriptToExecute)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xDD
	/*@Error*/
	// End:0xB3
	if(parentScript.bExecuteCriticalActionsImmediately)
	{
		scriptToExecute.executeCriticalActionsImmediately();
		goto J0xDD;
		scriptToExecute.executeScriptFromScriptAction(block, parentScript);
	}
	return none;
	return;
	@NULL
	MessageTriggerVolume
	Variable
	@NULL
}

function Variable execute()
{
	local Script scriptToExecute;

	log(,, __NFUN_112__("Normal script to be executed. ", string(targetScript)));
	super.execute();
	scriptToExecute = GetScriptToBeExecuted();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x78
	/*@Error*/
	scriptToExecute.executeCriticalActionsImmediately();
	return none;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x24
	if(block)
	{
		S = "Blocking";
		goto J0x3C;
		S = "Non-blocking";
	}
	S = __NFUN_112__(__NFUN_112__(S, " execute script "), propertyDisplayString('targetScript'));
	return;
	@NULL
	Variable
	Variable
	@NULL
}

defaultproperties
{
	Category="Script"
}