class VariableBool extends Variable
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel bool Value;

function Add(string rhs)
{
	return;
}

function subtract(string rhs)
{
	return;
}

function multiply(string rhs)
{
	return;
}

function divide(string rhs)
{
	return;
}

function bool less(string rhs)
{
	return false;
	return;
}

function bool lessEqual(string rhs)
{
	return false;
	return;
}

function bool equal(string rhs)
{
	return __NFUN_242__(Value, bool(rhs));
	return;
	@NULL
	Variable
}

function bool notEqual(string rhs)
{
	return __NFUN_243__(Value, bool(rhs));
	return;
	@NULL
	Variable
}

function bool greaterEqual(string rhs)
{
	return false;
	return;
}

function bool greater(string rhs)
{
	return false;
	return;
}

function bool and(string rhs)
{
	return __NFUN_130__(Value, bool(rhs));
	return;
	@NULL
	Variable
}

function bool or(string rhs)
{
	return __NFUN_132__(Value, bool(rhs));
	return;
	@NULL
	Variable
}

function bool not()
{
	return __NFUN_129__(Value);
	return;
	@NULL
}

function bool truth()
{
	return Value;
	return;
	@NULL
}
