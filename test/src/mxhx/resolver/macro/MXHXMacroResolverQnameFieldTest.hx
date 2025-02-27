package mxhx.resolver.macro;

import mxhx.symbols.IMXHXClassSymbol;
import utest.Test;
#if !macro
import utest.Assert;
#end

class MXHXMacroResolverQnameFieldTest extends Test {
	#if !macro
	public function testResolveAnyField():Void {
		var resolved = resolveFieldTypeQname("fixtures.TestPropertiesClass", "any");
		Assert.notNull(resolved);
		Assert.equals("Any", resolved);
	}

	public function testResolveArrayField():Void {
		var resolved = resolveFieldTypeQname("fixtures.TestPropertiesClass", "array");
		Assert.notNull(resolved);
		Assert.equals("Array<String>", resolved);

		var resolvedQnames = resolveFieldTypeParamQnames("fixtures.TestPropertiesClass", "array");
		Assert.notNull(resolvedQnames);
		Assert.equals(1, resolvedQnames.length);
		Assert.equals("String", resolvedQnames[0]);

		var resolvedParamNames = resolveFieldTypeParamNames("fixtures.TestPropertiesClass", "array");
		Assert.notNull(resolvedParamNames);
		Assert.equals(1, resolvedParamNames.length);
		Assert.equals("T", resolvedParamNames[0]);
	}

	public function testResolveBoolField():Void {
		var resolved = resolveFieldTypeQname("fixtures.TestPropertiesClass", "boolean");
		Assert.notNull(resolved);
		Assert.equals("Bool", resolved);
	}

	public function testResolveClassField():Void {
		var resolved = resolveFieldTypeQname("fixtures.TestPropertiesClass", "type");
		Assert.notNull(resolved);
		// TODO: fix the % that should be used only internally
		Assert.equals("Class<Dynamic<%>>", resolved);
	}

	public function testResolveDateField():Void {
		var resolved = resolveFieldTypeQname("fixtures.TestPropertiesClass", "date");
		Assert.notNull(resolved);
		Assert.equals("Date", resolved);
	}

	public function testResolveDynamicField():Void {
		var resolved = resolveFieldTypeQname("fixtures.TestPropertiesClass", "struct");
		Assert.notNull(resolved);
		// TODO: fix the % that should be used only internally
		Assert.equals("Dynamic<%>", resolved);
	}

	public function testResolveERegField():Void {
		var resolved = resolveFieldTypeQname("fixtures.TestPropertiesClass", "ereg");
		Assert.notNull(resolved);
		Assert.equals("EReg", resolved);
	}

	public function testResolveFloatField():Void {
		var resolved = resolveFieldTypeQname("fixtures.TestPropertiesClass", "float");
		Assert.equals("Float", resolved);
	}

	public function testResolveFunctionConstraintField():Void {
		var resolved = resolveFieldTypeQname("fixtures.TestPropertiesClass", "func");
		Assert.equals("haxe.Constraints.Function", resolved);
	}

	public function testResolveFunctionSignatureField():Void {
		var resolved = resolveFieldTypeQname("fixtures.TestPropertiesClass", "funcTyped");
		Assert.equals("() -> Void", resolved);
	}

	public function testResolveIntField():Void {
		var resolved = resolveFieldTypeQname("fixtures.TestPropertiesClass", "integer");
		Assert.notNull(resolved);
		Assert.equals("Int", resolved);
	}

	public function testResolveStringField():Void {
		var resolved = resolveFieldTypeQname("fixtures.TestPropertiesClass", "string");
		Assert.notNull(resolved);
		Assert.equals("String", resolved);
	}

	public function testResolveUIntField():Void {
		var resolved = resolveFieldTypeQname("fixtures.TestPropertiesClass", "unsignedInteger");
		Assert.notNull(resolved);
		Assert.equals("UInt", resolved);
	}

	public function testResolveXmlField():Void {
		var resolved = resolveFieldTypeQname("fixtures.TestPropertiesClass", "xml");
		Assert.notNull(resolved);
		Assert.equals("Xml", resolved);
	}

	public function testResolveNullField():Void {
		var resolved = resolveFieldTypeQname("fixtures.TestPropertiesClass", "canBeNull");
		Assert.notNull(resolved);
		Assert.equals("Null<Float>", resolved);

		var resolvedQnames = resolveFieldTypeParamQnames("fixtures.TestPropertiesClass", "canBeNull");
		Assert.notNull(resolvedQnames);
		Assert.equals(1, resolvedQnames.length);
		Assert.equals("Float", resolvedQnames[0]);

		var resolvedParamNames = resolveFieldTypeParamNames("fixtures.TestPropertiesClass", "canBeNull");
		Assert.notNull(resolvedParamNames);
		Assert.equals(1, resolvedParamNames.length);
		Assert.equals("T", resolvedParamNames[0]);
	}

	public function testResolveStrictlyTypedField():Void {
		var resolved = resolveFieldTypeQname("fixtures.TestPropertiesClass", "strictlyTyped");
		Assert.notNull(resolved);
		Assert.equals("fixtures.TestPropertiesClass", resolved);
	}

	public function testResolveStrictlyTypedInterfaceField():Void {
		var resolved = resolveFieldTypeQname("fixtures.TestPropertiesClass", "strictInterface");
		Assert.notNull(resolved);
		Assert.equals("fixtures.ITestPropertiesInterface", resolved);
	}

	public function testResolveAbstractEnumValueField():Void {
		var resolved = resolveFieldTypeQname("fixtures.TestPropertiesClass", "abstractEnumValue");
		Assert.notNull(resolved);
		Assert.equals("fixtures.TestPropertyAbstractEnum", resolved);
	}

	public function testResolveEnumValueField():Void {
		var resolved = resolveFieldTypeQname("fixtures.TestPropertiesClass", "enumValue");
		Assert.notNull(resolved);
		Assert.equals("fixtures.TestPropertyEnum", resolved);
	}

	public function testResolveClassFromModuleWithDifferentName():Void {
		var resolved = resolveFieldTypeQname("fixtures.TestPropertiesClass", "classFromModuleWithDifferentName");
		Assert.notNull(resolved);
		Assert.equals("fixtures.ModuleWithClassThatHasDifferentName.ThisClassHasADifferentNameThanItsModule", resolved);
	}

	public function testResolveFieldWithTypeParameter():Void {
		var resolvedArrayField = resolveFieldTypeQname("fixtures.ArrayCollection", "array");
		Assert.notNull(resolvedArrayField);
		// TODO: fix the % that should be used only internally
		Assert.equals("Array<%>", resolvedArrayField);

		var resolvedQnames = resolveFieldTypeParamQnames("fixtures.ArrayCollection", "array");
		Assert.notNull(resolvedQnames);
		Assert.equals(1, resolvedQnames.length);
		Assert.isNull(resolvedQnames[0]);

		var resolvedParamNames = resolveFieldTypeParamNames("fixtures.ArrayCollection", "array");
		Assert.notNull(resolvedParamNames);
		Assert.equals(1, resolvedParamNames.length);
		Assert.equals("T", resolvedParamNames[0]);

		var resolvedGetField = resolveFieldTypeQname("fixtures.ArrayCollection", "get");
		Assert.notNull(resolvedGetField);
		Assert.equals("(Int) -> Dynamic", resolvedGetField);

		var resolvedSetField = resolveFieldTypeQname("fixtures.ArrayCollection", "set");
		Assert.notNull(resolvedSetField);
		Assert.equals("(Int, Dynamic) -> Void", resolvedSetField);
	}

	public function testResolveFieldsWithInheritedTypeParameter():Void {
		var resolvedArrayField = resolveFieldTypeQname("fixtures.ArrayCollection<Float>", "array");
		Assert.notNull(resolvedArrayField);
		Assert.equals("Array<Float>", resolvedArrayField);

		var resolvedQnames = resolveFieldTypeParamQnames("fixtures.ArrayCollection<Float>", "array");
		Assert.notNull(resolvedQnames);
		Assert.equals(1, resolvedQnames.length);
		Assert.equals("Float", resolvedQnames[0]);

		var resolvedParamNames = resolveFieldTypeParamNames("fixtures.ArrayCollection<Float>", "array");
		Assert.notNull(resolvedParamNames);
		Assert.equals(1, resolvedParamNames.length);
		Assert.equals("T", resolvedParamNames[0]);

		var resolvedGetField = resolveFieldTypeQname("fixtures.ArrayCollection<Float>", "get");
		Assert.notNull(resolvedGetField);
		Assert.equals("(Int) -> Float", resolvedGetField);

		var resolvedSetField = resolveFieldTypeQname("fixtures.ArrayCollection<Float>", "set");
		Assert.notNull(resolvedSetField);
		Assert.equals("(Int, Float) -> Void", resolvedSetField);
	}

	public function testResolveMethod():Void {
		var resolved = resolveFieldTypeQname("fixtures.TestPropertiesClass", "testMethod");
		Assert.notNull(resolved);
		Assert.equals("() -> Void", resolved);
		var isWritable:Bool = isFieldWritable("fixtures.TestPropertiesClass", "testMethod");
		Assert.isFalse(isWritable);
	}

	public function testResolveDynamicMethod():Void {
		var resolved = resolveFieldTypeQname("fixtures.TestPropertiesClass", "testDynamicMethod");
		Assert.notNull(resolved);
		Assert.equals("() -> Void", resolved);
		var isWritable:Bool = isFieldWritable("fixtures.TestPropertiesClass", "testDynamicMethod");
		Assert.isTrue(isWritable);
	}
	#end

	public static macro function resolveFieldTypeQname(qname:String, fieldName:String):haxe.macro.Expr {
		var resolver = new MXHXMacroResolver();
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname(qname);
		var field = Lambda.find(resolvedClass.fields, field -> field.name == fieldName);
		var resolvedType = resolver.resolveQname(field.type.qname);
		return macro $v{resolvedType.qname};
	}

	public static macro function resolveFieldTypeParamNames(qname:String, fieldName:String):haxe.macro.Expr {
		var resolver = new MXHXMacroResolver();
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname(qname);
		var field = Lambda.find(resolvedClass.fields, field -> field.name == fieldName);
		var resolvedType = resolver.resolveQname(field.type.qname);
		return macro $v{resolvedType.paramNames};
	}

	public static macro function resolveFieldTypeParamQnames(qname:String, fieldName:String):haxe.macro.Expr {
		var resolver = new MXHXMacroResolver();
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname(qname);
		var field = Lambda.find(resolvedClass.fields, field -> field.name == fieldName);
		var resolvedType = resolver.resolveQname(field.type.qname);
		return macro $v{resolvedType.params.map(param -> param != null ? param.qname : null)};
	}

	public static macro function isFieldWritable(qname:String, fieldName:String):haxe.macro.Expr {
		var resolver = new MXHXMacroResolver();
		var resolvedClass:IMXHXClassSymbol = cast resolver.resolveQname(qname);
		var field = Lambda.find(resolvedClass.fields, field -> field.name == fieldName);
		return macro $v{field.isWritable};
	}
}
