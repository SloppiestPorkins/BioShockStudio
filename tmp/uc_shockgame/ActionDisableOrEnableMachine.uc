class ActionDisableOrEnableMachine extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name MachineLabel;
var travel Class<ShockMachine> MachineClass;
var travel bool Enable;

function Variable execute()
{
	local Actor TheMachine;
	local Class<ShockMachine> findClass;

	super.execute();
	log('Machines', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("ActionDisableOrEnableMachine. Enable=", string(Enable)), ", class = "), string(MachineClass)), ", label = "), string(MachineLabel)));
	// End:0xAA
	if(__NFUN_114__(MachineClass, none))
	{
		findClass = Class'ShockGame.ShockMachine';
		goto J0xBD;
		findClass = MachineClass;
		// End:0x18D
		foreach parentScript.__NFUN_304__(findClass, TheMachine)
		{
		}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x099! */
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x18C
		/*@Error*/
		ShockMachine(TheMachine).ScriptDisabled = __NFUN_129__(Enable);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x174
		/*@Error*/
		TheMachine.__NFUN_113__('Waiting');
		goto J0x18C;
		TheMachine.__NFUN_113__('Dormant');				
		return none;
		return;
		@NULL
		Item
		Item
		@NULL
	}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x075! */
}

function editorDisplayString(out string S)
{
	// End:0x2A
	if(Enable)
	{
		S = "Enable Machine";
		goto J0x45;
		S = "Disable Machine";
	}
	// End:0x82
	if(__NFUN_119__(MachineClass, none))
	{
		S = __NFUN_112__(__NFUN_112__(S, " of class "), string(MachineClass));
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xC9
		/*@Error*/
		S = __NFUN_112__(__NFUN_112__(S, " with label "), string(MachineLabel));
	}
	S = __NFUN_112__(S, ".");
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="Enable or Disable a Machine."
	actionHelp="Enables or disables one or more machines."
	Category="Machines"
}