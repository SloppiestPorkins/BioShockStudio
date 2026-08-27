class ActionSetLightProperties extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

struct atomic BaseLightProperty
{
	var() travel bool ChangeProperty "If this is set to false then the previous value will be ignored and no changes will be made to this property.";

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct atomic LightColorProperty extends BaseLightProperty
{
	var() travel Color LightColor;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct atomic LightTypeProperty extends BaseLightProperty
{
	var() travel Actor.ELightType LightType;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct atomic bCastsShadowMapShadowsProperty extends BaseLightProperty
{
	var() travel bool bCastsShadowMapShadows;

	structdefaultproperties
	{
		CheckpointTypePadding=452
	}
};

struct atomic bImportantDynamicLightProperty extends BaseLightProperty
{
	var() travel bool bImportantDynamicLight;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct LightBrightnessProperty extends BaseLightProperty
{
	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct atomic LightPeriodProperty extends BaseLightProperty
{
	var() travel byte LightPeriod;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct atomic LightPhaseProperty extends BaseLightProperty
{
	var() travel byte LightPhase;

	structdefaultproperties
	{
		CheckpointTypePadding=7471205
	}
};

var travel name Object;
var travel bCastsShadowMapShadowsProperty bCastsShadowMapShadows;
var travel LightBrightnessProperty LightBrightness;
var travel LightColorProperty LightColor;
var travel LightPeriodProperty LightPeriod;
var travel LightPhaseProperty LightPhase;
var travel LightTypeProperty LightType;

private invariant latent singular event Variable execute()
{
	local Light L;

	super.execute();
	// End:0x284
	foreach parentScript.allActorLabel(Class'Engine.Light', L, Object)
	{
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xE1
		/*@Error*/
		log(,, "WARNING: bCastsShadowMapShadows was set via scripting. This is not good.");
		L.bCastsShadowMapShadows = bCastsShadowMapShadows.bCastsShadowMapShadows;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x130
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		/*@Error*/;
		// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.get_CurrentToken() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 40
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 845
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
		// 1 & Type:ForEach Position:0x284
	}
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__("Set the properties of ", propertyDisplayString('Object'));
	return;
	@NULL
}

function enumScriptLabels(LevelInfo Level, out array<name> S)
{
	local Light L;

	// End:0xA8
	foreach Level.__NFUN_304__(Class'Engine.Light', L)
	{
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xA7
		/*@Error*/
		S[S.Length] = L.Label;				
		return;
		@NULL
		Variable
		stop;
		default.@NULL
	}
}

defaultproperties
{
	actionDisplayName="Set Light Properties"
	actionHelp="Sets new values for a given light"
	Category="Lights"
}