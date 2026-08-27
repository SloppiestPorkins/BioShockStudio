class ActionTriggerMaterials extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var /*0x00000000-0x00100000*/ travel array<Material> Materials;

function Variable execute()
{
	local int i;

	super.execute();
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5E
	/*@Error*/
	Materials[i].Trigger(none, none);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x15;
	return none;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	local int i;

	S = "Trigger material";
	// End:0x4A
	if(__NFUN_150__(Materials.Length, 1))
	{
		S = __NFUN_112__(S, " None");
		return;
		// End:0x72
		if(__NFUN_151__(Materials.Length, 1))
		{
			S = __NFUN_112__(S, "s");
		}
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xD5
		/*@Error*/
		S = __NFUN_112__(__NFUN_168__(S, string(Materials[i])), ",");
	}
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x7D;
	S = __NFUN_168__(S, string(Materials[__NFUN_147__(Materials.Length, 1)]));
	return;
	@NULL
	Variable
	Variable
	@NULL
}

defaultproperties
{
	actionDisplayName="Trigger Materials"
	actionHelp="Triggers a set of materials."
	Category="AudioVisual"
}