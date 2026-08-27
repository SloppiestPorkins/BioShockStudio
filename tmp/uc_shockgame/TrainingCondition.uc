class TrainingCondition extends Action
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var export editinline travel array<export editinline ActionBool> testsAnd;
var export editinline travel array<export editinline Action> ThenAction;
var /*0x00000000-0x00100000*/ travel float Weight;
var /*0x00000000-0x00100000*/ travel int TickDelay;
var /*0x00000000-0x00100000*/ travel int Priority;
var int DelayedTickCount;
var travel TrainingConcept Concept;
var private travel bool TrueLastFrame;
var private travel float LastTrueTime;
var private travel float LastFiredTime;

function setParentScript(Script S)
{
	local int i;

	super.setParentScript(S);
	i = 0;
	// End:0x87
	if(__NFUN_150__(i, testsAnd.Length))
	{
		// End:0x79
		if(__NFUN_119__(testsAnd[i], none))
		{
			testsAnd[i].setParentScript(S);
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x1E;
			i = 0;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0xFB
			/*@Error*/
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0xED
			/*@Error*/
		}
		ThenAction[i].setParentScript(S);
	}
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x92;
	DelayedTickCount = __NFUN_167__(__NFUN_146__(TickDelay, 1));
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	local int i;
	local string actionString;

	S = "If ";
	// End:0x40
	if(__NFUN_154__(testsAnd.Length, 0))
	{
		S = __NFUN_112__(S, "nothing");
		goto J0x15A;
		i = 0;
		// End:0x15A
		if(__NFUN_150__(i, testsAnd.Length))
		{
		}
		// End:0x14C
		if(__NFUN_119__(testsAnd[i], none))
		{
			testsAnd[i].editorDisplayString(actionString);
			// End:0xF7
			if(testsAnd[i].__NFUN_303__('ActionScriptNote'))
			{
				S = __NFUN_112__(__NFUN_112__(__NFUN_112__(S, "'"), actionString), "'");
				goto J0x14C;
				S = __NFUN_112__(S, actionString);
				// End:0x14C
				if(__NFUN_150__(i, __NFUN_147__(testsAnd.Length, 1)))
				{
					S = __NFUN_112__(S, " AND ");
					__NFUN_165__(i);
					// [Loop Continue]
					goto J0x4B;
					S = __NFUN_112__(S, " Then ");
				}
				// End:0x1BF
				if(__NFUN_154__(ThenAction.Length, 0))
				{
					S = __NFUN_112__(__NFUN_112__(S, "modify weight by "), string(Weight));
					goto J0x2CD;
					// End:0x207
					if(__NFUN_151__(ThenAction.Length, 2))
					{
					}
				}
				S = __NFUN_112__(__NFUN_112__(__NFUN_112__(S, "do "), string(ThenAction.Length)), " actions");
			}
			goto J0x2CD;
			i = 0;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x2CD
			/*@Error*/
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x2BF
			/*@Error*/
			ThenAction[i].editorDisplayString(actionString);
		}
		S = __NFUN_112__(S, actionString);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x2BF
		/*@Error*/
		S = __NFUN_112__(S, ", ");
		__NFUN_165__(i);
		goto J0x212;
		return;
		@NULL
	}
	Item
	Item
	J0x212:

	@NULL
}

function bool editorInDropDown(Action parentAction)
{
	return __NFUN_130__(__NFUN_119__(parentAction, none), __NFUN_258__(parentAction.Class, Class'ShockGame.TrainingConcept'));
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function executeActions()
{
	local int i;
	local string Desc;

	// End:0xB8
	if(ShockGameDriver(parentScript.Level.GetGameDriver()).GetTrainingMessageManager().EnableTrainingLogs)
	{
		editorDisplayString(Desc);
		SLog(__NFUN_168__(__NFUN_168__(__NFUN_112__(__NFUN_112__("Condition (", Desc), ") for concept"), string(Concept.ConceptName)), "executed"));
		ConditionsMet();
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x149
		/*@Error*/
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x13B
	/*@Error*/
	ThenAction[i].latentExecute();
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0xCD;
	LastFiredTime = TrainingScript(parentScript).tickTime;
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function bool ConditionsMet()
{
	local int i;
	local Variable temp;
	local VariableBool Result;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xC3
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB5
	/*@Error*/
	testsAnd[i].latentExecute();
	// BadToken (0x55)
	temp = ((return Result = VariableBool(temp)) ? Engine : );
	1
	none	
	__NFUN_242__(Result.Value, false);	
	return false;
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x0B;
	return true;
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function Variable latentExecute()
{
	local string Desc;
	local bool Result;

	super.latentExecute();
	ConditionsMet();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1A0
	/*@Error*/
	DispenserMachine
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x400
	/*@Error*/;
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.get_CurrentToken() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 40
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 834
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 4 & Type:Case Position:0x400
	// Failed to format remaining nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.get_CurrentToken() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 40
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 834
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 724
	// 4 & Type:Case Position:0x400
}

defaultproperties
{
	TickDelay=10
	actionDisplayName="A condition that affect knowledge of a concept"
	actionHelp=""
	Category="Training"
	bIsGameCritical=false
}