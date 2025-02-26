package mxhx.resolver.macro;

import utest.Test;
#if !macro
import utest.Assert;
#end

class MXHXMacroResolverQnameTest extends Test {
	#if !macro
	public function testResolveAny():Void {
		var resolved = resolveQname("Any");
		Assert.notNull(resolved);
		Assert.equals("Any", resolved);
	}

	public function testResolveArrayWithoutTypeParameter():Void {
		var resolved = resolveQname("Array");
		Assert.notNull(resolved);
		Assert.equals("Array", resolved);
		var paramNames = resolveParamNames("Array");
		Assert.notNull(paramNames);
		Assert.equals(1, paramNames.length);
		Assert.equals("T", paramNames[0]);
	}

	public function testResolveArrayWithTypeParameter():Void {
		var resolved = resolveQname("Array<Float>");
		Assert.notNull(resolved);
		Assert.equals("Array<Float>", resolved);
		var paramNames = resolveParamNames("Array<Float>");
		Assert.notNull(paramNames);
		Assert.equals(1, paramNames.length);
		Assert.equals("T", paramNames[0]);
	}

	public function testResolveBool():Void {
		var resolved = resolveQname("Bool");
		Assert.notNull(resolved);
		Assert.equals("Bool", resolved);
	}

	public function testResolveStdTypesBool():Void {
		var resolved = resolveQname("StdTypes.Bool");
		Assert.notNull(resolved);
		Assert.equals("Bool", resolved);
	}

	public function testResolveDynamic():Void {
		var resolved = resolveQname("Dynamic");
		Assert.notNull(resolved);
		Assert.equals("Dynamic", resolved);
	}

	public function testResolveEReg():Void {
		var resolved = resolveQname("EReg");
		Assert.notNull(resolved);
		Assert.equals("EReg", resolved);
	}

	public function testResolveFloat():Void {
		var resolved = resolveQname("Float");
		Assert.notNull(resolved);
		Assert.equals("Float", resolved);
	}

	public function testResolveStdTypesFloat():Void {
		var resolved = resolveQname("StdTypes.Float");
		Assert.notNull(resolved);
		Assert.equals("Float", resolved);
	}

	public function testResolveInt():Void {
		var resolved = resolveQname("Int");
		Assert.notNull(resolved);
		Assert.equals("Int", resolved);
	}

	public function testResolveStdTypesInt():Void {
		var resolved = resolveQname("StdTypes.Int");
		Assert.notNull(resolved);
		Assert.equals("Int", resolved);
	}

	public function testResolveString():Void {
		var resolved = resolveQname("String");
		Assert.notNull(resolved);
		Assert.equals("String", resolved);
	}

	public function testResolveUInt():Void {
		var resolved = resolveQname("UInt");
		Assert.notNull(resolved);
		Assert.equals("UInt", resolved);
	}

	public function testResolveQnameFromLocalClass():Void {
		var resolved = resolveQname("fixtures.TestPropertiesClass");
		Assert.notNull(resolved);
		Assert.equals("fixtures.TestPropertiesClass", resolved);
	}

	public function testResolveQnameFromLocalInterface():Void {
		var resolved = resolveQname("fixtures.ITestPropertiesInterface");
		Assert.notNull(resolved);
		Assert.equals("fixtures.ITestPropertiesInterface", resolved);
	}

	public function testResolveAbstract():Void {
		var resolved = resolveQname("fixtures.TestAbstractFrom");
		Assert.notNull(resolved);
		Assert.equals("fixtures.TestAbstractFrom", resolved);
	}

	public function testResolveAbstractFromModuleType():Void {
		var resolved = resolveQname("fixtures.TestAbstractFromModuleType");
		Assert.notNull(resolved);
		Assert.equals("fixtures.TestAbstractFromModuleType", resolved);
	}

	public function testResolveGenericWithoutParams():Void {
		var resolved = resolveQname("fixtures.ArrayCollection");
		Assert.notNull(resolved);
		Assert.equals("fixtures.ArrayCollection", resolved);
		var paramNames = resolveParamNames("fixtures.ArrayCollection");
		Assert.notNull(paramNames);
		Assert.equals(1, paramNames.length);
		Assert.equals("T", paramNames[0]);
	}

	public function testResolveGenericWithParams():Void {
		var resolved = resolveQname("fixtures.ArrayCollection<Float>");
		Assert.notNull(resolved);
		Assert.equals("fixtures.ArrayCollection<Float>", resolved);
		var paramNames = resolveParamNames("fixtures.ArrayCollection<Float>");
		Assert.notNull(paramNames);
		Assert.equals(1, paramNames.length);
		Assert.equals("T", paramNames[0]);
	}
	#end

	public static macro function resolveQname(qname:String):haxe.macro.Expr {
		var resolver = new MXHXMacroResolver();
		return macro $v{resolver.resolveQname(qname).qname};
	}

	public static macro function resolveParamNames(qname:String):haxe.macro.Expr {
		var resolver = new MXHXMacroResolver();
		return macro $v{resolver.resolveQname(qname).paramNames};
	}
}
