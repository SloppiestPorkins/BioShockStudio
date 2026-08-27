class ActionPropertyTest extends ActionBool
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

enum EOpTest
{
	OPTEST_LESS,                    // 0
	OPTEST_LESSEQUAL,               // 1
	OPTEST_EQUALS,                  // 2
	OPTEST_NOTEQUAL,                // 3
	OPTEST_GREATEREQUAL,            // 4
	OPTEST_GREATER                  // 5
};

var travel name Label;
var /*0x00000000-0x00100000*/ travel Class<Actor> actorClass;
var /*0x00000000-0x00100000*/ travel string propertyPath;
var travel string Value;
var travel int maxPasses;
var /*0x00000000-0x00100000*/ private transient Object testProperty;
var /*0x00000000-0x00100000*/ transient array<int> offsets;
var /*0x00000000-0x00100000*/ travel ActionPropertyTest.EOpTest opTest;

function Variable execute()
{
	local VariableBool retVar;

	retVar = VariableBool(newTemporaryVariable(Class'Scripting.VariableBool'));
	super.execute();
	// End:0x49
	if(__NFUN_114__(testProperty, none))
	{
		findTestProperty();
		retVar.Value = doPropertyTest();
	}
	return retVar;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x30
	if(__NFUN_155__(maxPasses, -1))
	{
		S = __NFUN_112__(string(maxPasses), " ");
		goto J0x40;
		S = "all ";
	}
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(S, string(Label)), "."), propertyPath), " "), getOperatorText()), " "), Value);
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function string getOperatorText()
{
	switch(opTest)
	{
		// End:0x17
		case 0:
			return "<";
			// End:0x5A
			break;
			// End:0x24
			case 1:
			return "<=";
			// End:0x5A
			break;
			// End:0x31
			case 2:
			return "==";
			// End:0x5A
			break;
			// End:0x3E
			case 3:
			return "!=";
			// End:0x5A
			break;
			// End:0x4B
			case 4:
			return ">=";
			// End:0x5A
			break;
			// End:0x57
			case 5:
			return ">";
			// End:0x5A
			break;
			// End:0xFFFF
			default:
				return;
				break;
		}/* !MISMATCHING REMOVE, tried Switch got Type:Case Position:0x007! *//* !MISMATCHING REMOVE, tried Case got Type:Switch Position:0x000! */
	@NULL
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:Switch Position:0x05A
	// Failed to format remaining nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 724
	// 1 & Type:Switch Position:0x05A
}

// Export UActionPropertyTest::execfindTestProperty(FFrame&, void* const)
private native function findTestProperty();

// Export UActionPropertyTest::execdoPropertyTest(FFrame&, void* const)
private native function bool doPropertyTest();

defaultproperties
{
	maxPasses=-1
	actionDisplayName="Test Property"
	actionHelp="Returns true if the property passes the operator test against value"
	Category="Watch"
}