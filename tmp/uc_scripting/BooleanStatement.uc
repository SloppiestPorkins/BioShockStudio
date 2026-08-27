class BooleanStatement extends ActionBool
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

enum ELogicOp
{
	LOGICOP_LESS,                   // 0
	LOGICOP_LESSEQUAL,              // 1
	LOGICOP_EQUALS,                 // 2
	LOGICOP_NOTEQUAL,               // 3
	LOGICOP_GREATEREQUAL,           // 4
	LOGICOP_GREATER                 // 5
};

var travel BooleanStatement.ELogicOp logicOp;
var travel string lhs;
var travel string rhs;

// Export UBooleanStatement::execNativeExecute(FFrame&, void* const)
native function NativeExecute();

function Variable execute()
{
	super.execute();
	NativeExecute();
	return returnVar;
	return;
	@NULL
	Variable
}

function string logicOpDisplayString()
{
	switch(logicOp)
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

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(propertyDisplayString('lhs'), " "), logicOpDisplayString()), " "), propertyDisplayString('rhs'));
	return;
	@NULL
}

defaultproperties
{
	logicOp=2
	actionDisplayName="Boolean Statement"
	actionHelp="Returns the result of a logical evaluation"
	Category="Logic"
}