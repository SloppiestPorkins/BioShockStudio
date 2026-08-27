class Variable extends Object
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

function logError(string rval, string Reason)
{
	SLog(__NFUN_112__(__NFUN_112__(__NFUN_112__("ERROR: Could not resolve rval ", rval), ", no variable of that name or "), Reason));
	return;
	@NULL
	Variable
}

function Variable findVariable(coerce string Name, Script requestingScript)
{
	//native.Name;
	//native.requestingScript;	
	@NULL
	@NULL
}

function nativeClassToVariableClass(string nativeClass, out Class<Variable> varClass)
{
	// End:0x32
	if(__NFUN_122__(nativeClass, "NameProperty"))
	{
		varClass = Class'Scripting.VariableName';
		goto J0xD6;
		// End:0x66
		if(__NFUN_122__(nativeClass, "StringProperty"))
		{
		}
		varClass = Class'Scripting.VariableString';
		goto J0xD6;
		// End:0x99
		if(__NFUN_122__(nativeClass, "FloatProperty"))
		{
		}
		varClass = Class'Scripting.VariableFloat';
		goto J0xD6;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xCB
		/*@Error*/
		varClass = Class'Scripting.VariableBool';
		goto J0xD6;
	}
	varClass = none;
	return;
	@NULL
	Variable
	false
	default.@NULL
}

function variableClassToNativeClass(Class<Variable> varClass, out string nativeClass)
{
	// End:0x32
	if(__NFUN_114__(varClass, Class'Scripting.VariableName'))
	{
		nativeClass = "NameProperty";
		goto J0xDB;
		// End:0x66
		if(__NFUN_114__(varClass, Class'Scripting.VariableString'))
		{
		}
		nativeClass = "StringProperty";
		goto J0xDB;
		// End:0x99
		if(__NFUN_114__(varClass, Class'Scripting.VariableFloat'))
		{
			nativeClass = "FloatProperty";
		}
		goto J0xDB;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xCB
		/*@Error*/
		nativeClass = "BoolProperty";
		goto J0xDB;
	}
	nativeClass = "None";
	return;
	@NULL
	Variable
	false
	default.@NULL
}

function bestVariableClass(string Val, out Class<Variable> varClass)
{
	//native.Val;
	//native.varClass;	
	@NULL
	@NULL
}

event Add(string rhs)
{
	return;
}

event subtract(string rhs)
{
	return;
}

event multiply(string rhs)
{
	return;
}

event divide(string rhs)
{
	return;
}

event bool less(string rhs)
{
	return false;
	return;
}

event bool lessEqual(string rhs)
{
	return false;
	return;
}

event bool equal(string rhs)
{
	return false;
	return;
}

event bool notEqual(string rhs)
{
	return false;
	return;
}

event bool greaterEqual(string rhs)
{
	return false;
	return;
}

event bool greater(string rhs)
{
	return false;
	return;
}

event bool and(string rhs)
{
	return false;
	return;
}

event bool or(string rhs)
{
	return false;
	return;
}

event bool not()
{
	return false;
	return;
}

event bool truth()
{
	return false;
	return;
}
