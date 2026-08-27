class ArithmeticStatement extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

enum EArithmeticOp
{
	ARITHMETICOP_ADD,               // 0
	ARITHMETICOP_SUBTRACT,          // 1
	ARITHMETICOP_MULTIPLY,          // 2
	ARITHMETICOP_DIVIDE             // 3
};

var travel ArithmeticStatement.EArithmeticOp ArithmeticOp;
var travel string lhs;
var travel string rhs;

function Variable execute()
{
	local Variable vLhs;
	local Class<Variable> varClass;

	super.execute();
	Class'Scripting.Variable'.static.bestVariableClass(lhs, varClass);
	vLhs = newTemporaryVariable(varClass, lhs);
	switch(ArithmeticOp)
	{
		// End:0x8C
		case 0:
			vLhs.Add(rhs);
			// End:0x107
			break;
			// End:0xB4
			case 1:
				vLhs.subtract(rhs);
				// End:0x107
				break;
				// End:0xDC
				case 2:
					vLhs.multiply(rhs);
				// End:0x107
				break;
				// End:0x104
				case 3:
					vLhs.divide(rhs);
				// End:0x107
				break;
				// End:0xFFFF
				default:
					return vLhs;
					break;
			}/* !MISMATCHING REMOVE, tried Switch got Type:Case Position:0x064! */
			return;
			@NULL
			Variable
			Variable
		@NULL
	// Failed to format remaining nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 724
	// 1 & Type:Switch Position:0x107
}

function string logicOpDisplayString()
{
	switch(ArithmeticOp)
	{
		// End:0x17
		case 0:
			return "+";
			// End:0x3E
			break;
			// End:0x23
			case 1:
			return "-";
			// End:0x3E
			break;
			// End:0x2F
			case 2:
			return "*";
			// End:0x3E
			break;
			// End:0x3B
			case 3:
			return "/";
			// End:0x3E
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
	// 1 & Type:Switch Position:0x03E
	// Failed to format remaining nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 724
	// 1 & Type:Switch Position:0x03E
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("(", propertyDisplayString('lhs')), " "), logicOpDisplayString()), " "), propertyDisplayString('rhs')), ")");
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Arithmetic Statement"
	actionHelp="Returns the result of evaluating an arithmetic on lhs and rhs"
	returnType=Class'Scripting.Variable'
	Category="Math"
}