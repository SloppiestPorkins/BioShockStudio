class ActionControlPlant extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var /*0x00000000-0x00100000*/ travel array<PlantShader> PlantShaders;
var travel float Duration;
var travel bool bRevive;

function Variable latentExecute()
{
	local int i;
	local float LastTime, CurrentControlTime, NewTransitionWeight;
	local ShockGameInfo GI;

	resolveParameters();
	GI = ShockGameInfo(parentScript.Level.Game);
	// End:0x12F
	if(__NFUN_180__(Duration, 0.0000000))
	{
		// End:0x72
		if(bRevive)
		{
			NewTransitionWeight = 0.0000000;
			goto J0x81;
			NewTransitionWeight = 1.0000000;
			i = 0;
			// End:0x12C
			if(__NFUN_150__(i, PlantShaders.Length))
			{
			}
			GI.PlantShaders[GI.PlantShaders.Length] = PlantShaders[i];
			GI.PlantShaderTransitionWeights[GI.PlantShaderTransitionWeights.Length] = NewTransitionWeight;
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x8C;
			goto J0x2B6;
			CurrentControlTime = 0.0000000;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x2B6
			/*@Error*/
			NewTransitionWeight = __NFUN_172__(CurrentControlTime, Duration);
			// End:0x19A
			if(bRevive)
			{
				NewTransitionWeight = __NFUN_175__(1.0000000, NewTransitionWeight);
				i = 0;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x245
				/*@Error*/
			}
			GI.PlantShaders[GI.PlantShaders.Length] = PlantShaders[i];
		}
		GI.PlantShaderTransitionWeights[GI.PlantShaderTransitionWeights.Length] = NewTransitionWeight;
		__NFUN_163__(i);
		goto J0x1A5;
		LastTime = parentScript.Level.TimeSeconds;
	}
	__NFUN_256__(0.0000000);
	__NFUN_184__(CurrentControlTime, __NFUN_175__(parentScript.Level.TimeSeconds, LastTime));
	// [Loop Continue]
	goto J0x13E;
	return none;
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function Variable execute()
{
	super.execute();
	return none;
	return;
	@NULL
}

function editorDisplayString(out string S)
{
	S = "Control plant life";
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Control plant"
	actionHelp="Controls the life/death of a plant."
	Category="AudioVisual"
}