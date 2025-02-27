package mxhx.resolver.macro;

import mxhx.manifest.MXHXManifestEntry;
import mxhx.parser.MXHXParser;
import mxhx.resolver.macro.MXHXMacroResolver;
import mxhx.symbols.IMXHXFieldSymbol;
import mxhx.symbols.IMXHXTypeSymbol;
import utest.Test;
#if !macro
import utest.Assert;
#end

class MXHXMacroResolverTagFieldValueTypeTest extends Test {
	#if !macro
	public function testResolveFieldValueTypeAny():Void {
		var resolvedFieldType = resolveTagType('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:any>
					<mx:Float/>
				</tests:any>
			</tests:TestPropertiesClass>
		', 146);
		Assert.notNull(resolvedFieldType);
		// the field is typed as Any, but the value is more specific
		Assert.equals("Float", resolvedFieldType);
	}

	public function testResolveFieldValueTypeArray():Void {
		var resolvedFieldType = resolveTagType('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:array>
					<mx:Array type="String"/>
				</tests:array>
			</tests:TestPropertiesClass>
		', 148);
		Assert.notNull(resolvedFieldType);
		Assert.equals("Array<String>", resolvedFieldType);

		var resolvedParamQnames = resolveTagTypeParamQnames('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:array>
					<mx:Array type="String"/>
				</tests:array>
			</tests:TestPropertiesClass>
		', 148);
		Assert.notNull(resolvedParamQnames);
		Assert.equals(1, resolvedParamQnames.length);
		Assert.equals("String", resolvedParamQnames[0]);

		var resolvedParamNames = resolveTagTypeParamNames('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:array>
					<mx:Array type="String"/>
				</tests:array>
			</tests:TestPropertiesClass>
		', 148);
		Assert.notNull(resolvedParamNames);
		Assert.equals(1, resolvedParamNames.length);
		Assert.equals("T", resolvedParamNames[0]);
	}

	public function testResolveFieldValueTypeBool():Void {
		var resolvedFieldType = resolveTagType('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:boolean>
					<mx:Bool/>
				</tests:boolean>
			</tests:TestPropertiesClass>
		', 150);
		Assert.notNull(resolvedFieldType);
		Assert.equals("Bool", resolvedFieldType);
	}

	public function testResolveFieldValueTypeClass():Void {
		var resolvedFieldType = resolveTagType('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:type>
					<mx:Class>Float</mx:Class>
				</tests:type>
			</tests:TestPropertiesClass>
		', 147);
		Assert.notNull(resolvedFieldType);
		// TODO: fix the % that should be used only internally
		Assert.equals("Class<Dynamic<%>>", resolvedFieldType);
	}

	public function testResolveFieldValueTypeDate():Void {
		var resolvedFieldType = resolveTagType('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:date>
					<mx:Date/>
				</tests:date>
			</tests:TestPropertiesClass>
		', 147);
		Assert.notNull(resolvedFieldType);
		Assert.equals("Date", resolvedFieldType);
	}

	public function testResolveFieldValueTypeDynamic():Void {
		var resolvedFieldType = resolveTagType('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:struct>
					<mx:Struct/>
				</tests:struct>
			</tests:TestPropertiesClass>
		', 149);
		Assert.notNull(resolvedFieldType);
		// TODO: fix the % that should be used only internally
		Assert.equals("Dynamic<%>", resolvedFieldType);
	}

	public function testResolveFieldValueTypeEReg():Void {
		var resolvedFieldType = resolveTagType('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:ereg>
					<mx:EReg/>
				</tests:ereg>
			</tests:TestPropertiesClass>
		', 147);
		Assert.notNull(resolvedFieldType);
		Assert.equals("EReg", resolvedFieldType);
	}

	public function testResolveFieldValueTypeFloat():Void {
		var resolvedFieldType = resolveTagType('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:float>
					<mx:Float/>
				</tests:float>
			</tests:TestPropertiesClass>
		', 148);
		Assert.notNull(resolvedFieldType);
		Assert.equals("Float", resolvedFieldType);
	}

	public function testResolveFieldValueTypeFunction():Void {
		var resolvedFieldType = resolveTagType('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:func>
					<mx:Function/>
				</tests:func>
			</tests:TestPropertiesClass>
		', 147);
		Assert.notNull(resolvedFieldType);
		Assert.equals("haxe.Constraints.Function", resolvedFieldType);
	}

	public function testResolveFieldValueTypeFunctionSignature():Void {
		var resolvedFieldType = resolveTagType('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:funcTyped>
					<mx:Function/>
				</tests:funcTyped>
			</tests:TestPropertiesClass>
		', 152);
		Assert.notNull(resolvedFieldType);
		Assert.equals("haxe.Constraints.Function", resolvedFieldType);
	}

	public function testResolveFieldValueTypeInt():Void {
		var resolvedFieldType = resolveTagType('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:integer>
					<mx:Int/>
				</tests:integer>
			</tests:TestPropertiesClass>
		', 150);
		Assert.notNull(resolvedFieldType);
		Assert.equals("Int", resolvedFieldType);
	}

	public function testResolveFieldValueTypeString():Void {
		var resolvedFieldType = resolveTagType('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:string>
					<mx:String/>
				</tests:string>
			</tests:TestPropertiesClass>
		', 149);
		Assert.notNull(resolvedFieldType);
		Assert.equals("String", resolvedFieldType);
	}

	public function testResolveFieldValueTypeStruct():Void {
		var resolvedFieldType = resolveTagType('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:struct>
					<mx:Struct/>
				</tests:struct>
			</tests:TestPropertiesClass>
		', 149);
		Assert.notNull(resolvedFieldType);
		// TODO: fix the % that should be used only internally
		Assert.equals("Dynamic<%>", resolvedFieldType);
	}

	public function testResolveFieldValueTypeUInt():Void {
		var resolvedFieldType = resolveTagType('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:unsignedInteger>
					<mx:UInt/>
				</tests:unsignedInteger>
			</tests:TestPropertiesClass>
		', 158);
		Assert.notNull(resolvedFieldType);
		Assert.equals("UInt", resolvedFieldType);
	}

	public function testResolveFieldValueTypeXml():Void {
		var resolvedFieldType = resolveTagType('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:xml>
					<mx:Xml/>
				</tests:xml>
			</tests:TestPropertiesClass>
		', 146);
		Assert.notNull(resolvedFieldType);
		Assert.equals("Xml", resolvedFieldType);
	}

	public function testResolveFieldValueTypeAbstractEnumValueEmpty():Void {
		var resolvedFieldType = resolveTagType('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:abstractEnumValue>
					<tests:TestPropertyAbstractEnum/>
				</tests:abstractEnumValue>
			</tests:TestPropertiesClass>
		', 163);
		Assert.notNull(resolvedFieldType);
		Assert.equals("fixtures.TestPropertyAbstractEnum", resolvedFieldType);
	}

	public function testResolveFieldValueTypeAbstractEnumFieldValue():Void {
		var resolvedFieldType = resolveTagType('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:abstractEnumValue>
					<tests:TestPropertyAbstractEnum.Value1/>
				</tests:abstractEnumValue>
			</tests:TestPropertiesClass>
		', 188);
		Assert.notNull(resolvedFieldType);
		Assert.equals("Value1", resolvedFieldType);
	}

	public function testResolveFieldValueTypeEnumValueEmpty():Void {
		var resolvedFieldType = resolveTagType('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:enumValue>
					<tests:TestPropertyEnum/>
				</tests:enumValue>
			</tests:TestPropertiesClass>
		', 155);
		Assert.notNull(resolvedFieldType);
		Assert.equals("fixtures.TestPropertyEnum", resolvedFieldType);
	}

	public function testResolveFieldValueTypeEnumFieldValue():Void {
		var resolvedFieldType = resolveTagType('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:enumValue>
					<tests:TestPropertyEnum.Value1/>
				</tests:enumValue>
			</tests:TestPropertiesClass>
		', 172);
		Assert.notNull(resolvedFieldType);
		Assert.equals("Value1", resolvedFieldType);
	}

	public function testResolveFieldValueTypeNull():Void {
		var resolvedFieldType = resolveTagType('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:canBeNull>
					<mx:Float/>
				</tests:canBeNull>
			</tests:TestPropertiesClass>
		', 155);
		Assert.notNull(resolvedFieldType);
		Assert.equals("Float", resolvedFieldType);
	}

	public function testResolveFieldValueTypeStrict():Void {
		var resolvedFieldType = resolveTagType('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:strictlyTyped>
					<tests:TestPropertiesClass/>
				</tests:strictlyTyped>
			</tests:TestPropertiesClass>
		', 159);
		Assert.notNull(resolvedFieldType);
		Assert.equals("fixtures.TestPropertiesClass", resolvedFieldType);
	}

	public function testResolveFieldValueTypeStrictInterface():Void {
		var resolvedFieldType = resolveTagType('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:strictInterface>
					<tests:TestPropertiesClass/>
				</tests:strictlyTyped>
			</tests:strictInterface>
		', 161);
		Assert.notNull(resolvedFieldType);
		Assert.equals("fixtures.TestPropertiesClass", resolvedFieldType);
	}

	public function testResolveFieldValueTypeArrayCollectionInferredTypeNoChildren():Void {
		var resolvedFieldType = resolveTagType('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:arrayCollection>
					<tests:ArrayCollection/>
				</tests:arrayCollection>
			</tests:TestPropertiesClass>
		', 161);
		Assert.notNull(resolvedFieldType);
		Assert.equals("fixtures.ArrayCollection<Float>", resolvedFieldType);

		var resolvedParamQnames = resolveTagTypeParamQnames('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:arrayCollection>
					<tests:ArrayCollection/>
				</tests:arrayCollection>
			</tests:TestPropertiesClass>
		', 161);
		Assert.notNull(resolvedParamQnames);
		Assert.equals(1, resolvedParamQnames.length);
		Assert.equals("Float", resolvedParamQnames[0]);

		var resolvedParamNames = resolveTagTypeParamNames('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:arrayCollection>
					<tests:ArrayCollection/>
				</tests:arrayCollection>
			</tests:TestPropertiesClass>
		', 161);
		Assert.notNull(resolvedParamNames);
		Assert.equals(1, resolvedParamNames.length);
		Assert.equals("T", resolvedParamNames[0]);
	}

	public function testResolveFieldValueTypeArrayCollectionInferredTypeWithChildren():Void {
		var resolvedFieldType = resolveTagType('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:arrayCollection>
					<tests:ArrayCollection>
						<mx:Float>123.4</mx:Float>
						<mx:Float>56.78</mx:Float>
					</tests:ArrayCollection>
				</tests:arrayCollection>
			</tests:TestPropertiesClass>
		', 161);
		Assert.notNull(resolvedFieldType);
		Assert.equals("fixtures.ArrayCollection<Float>", resolvedFieldType);

		var resolvedParamQnames = resolveTagTypeParamQnames('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:arrayCollection>
					<tests:ArrayCollection>
						<mx:Float>123.4</mx:Float>
						<mx:Float>56.78</mx:Float>
					</tests:ArrayCollection>
				</tests:arrayCollection>
			</tests:TestPropertiesClass>
		', 161);
		Assert.notNull(resolvedParamQnames);
		Assert.equals(1, resolvedParamQnames.length);
		Assert.equals("Float", resolvedParamQnames[0]);

		var resolvedParamNames = resolveTagTypeParamNames('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:arrayCollection>
					<tests:ArrayCollection>
						<mx:Float>123.4</mx:Float>
						<mx:Float>56.78</mx:Float>
					</tests:ArrayCollection>
				</tests:arrayCollection>
			</tests:TestPropertiesClass>
		', 161);
		Assert.notNull(resolvedParamNames);
		Assert.equals(1, resolvedParamNames.length);
		Assert.equals("T", resolvedParamNames[0]);
	}

	public function testResolveFieldValueTypeArrayCollectionWithType():Void {
		var resolvedFieldType = resolveTagType('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:arrayCollection>
					<tests:ArrayCollection type="Float"/>
				</tests:arrayCollection>
			</tests:TestPropertiesClass>
		', 161);
		Assert.notNull(resolvedFieldType);
		Assert.equals("fixtures.ArrayCollection<Float>", resolvedFieldType);

		var resolvedParamQnames = resolveTagTypeParamQnames('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:arrayCollection>
					<tests:ArrayCollection type="Float"/>
				</tests:arrayCollection>
			</tests:TestPropertiesClass>
		', 161);
		Assert.notNull(resolvedParamQnames);
		Assert.equals(1, resolvedParamQnames.length);
		Assert.equals("Float", resolvedParamQnames[0]);

		var resolvedParamNames = resolveTagTypeParamNames('
			<tests:TestPropertiesClass xmlns:mx="https://ns.mxhx.dev/2024/basic" xmlns:tests="https://ns.mxhx.dev/2024/tests">
				<tests:arrayCollection>
					<tests:ArrayCollection type="Float"/>
				</tests:arrayCollection>
			</tests:TestPropertiesClass>
		', 161);
		Assert.notNull(resolvedParamNames);
		Assert.equals(1, resolvedParamNames.length);
		Assert.equals("T", resolvedParamNames[0]);
	}
	#end

	public static macro function resolveTagType(mxhxSource:String, start:Int):haxe.macro.Expr {
		var parser = new MXHXParser(mxhxSource, "source.mxhx");
		var mxhxData = parser.parse();
		var resolver = new MXHXMacroResolver();

		var manifestPath = haxe.io.Path.join([Sys.getCwd(), "mxhx-manifest.xml"]);
		var content = sys.io.File.getContent(manifestPath);
		var xml = Xml.parse(content);
		var mappings:Map<String, MXHXManifestEntry> = [];
		for (componentXml in xml.firstElement().elementsNamed("component")) {
			var xmlName = componentXml.get("id");
			var qname = componentXml.get("class");
			var params:Array<String> = null;
			if (componentXml.exists("params")) {
				params = componentXml.get("params").split(",");
			}
			mappings.set(xmlName, new MXHXManifestEntry(xmlName, qname, params));
		}
		resolver.registerManifest("https://ns.mxhx.dev/2024/tests", mappings);

		var offsetTag = mxhxData.findTagOrSurroundingTagContainingOffset(start);
		if (offsetTag == null) {
			return macro null;
		}
		var resolved = resolver.resolveTag(offsetTag);
		if (resolved == null) {
			return macro null;
		}
		if ((resolved is IMXHXTypeSymbol)) {
			var resolvedType:IMXHXTypeSymbol = cast resolved;
			return macro $v{resolvedType.qname};
		} else if ((resolved is IMXHXFieldSymbol)) {
			var resolvedField:IMXHXFieldSymbol = cast resolved;
			return macro $v{resolvedField.type.qname};
		}
		return macro $v{resolved.name};
	}

	public static macro function resolveTagTypeParamQnames(mxhxSource:String, start:Int):haxe.macro.Expr {
		var parser = new MXHXParser(mxhxSource, "source.mxhx");
		var mxhxData = parser.parse();
		var resolver = new MXHXMacroResolver();

		var manifestPath = haxe.io.Path.join([Sys.getCwd(), "mxhx-manifest.xml"]);
		var content = sys.io.File.getContent(manifestPath);
		var xml = Xml.parse(content);
		var mappings:Map<String, MXHXManifestEntry> = [];
		for (componentXml in xml.firstElement().elementsNamed("component")) {
			var xmlName = componentXml.get("id");
			var qname = componentXml.get("class");
			var params:Array<String> = null;
			if (componentXml.exists("params")) {
				params = componentXml.get("params").split(",");
			}
			mappings.set(xmlName, new MXHXManifestEntry(xmlName, qname, params));
		}
		resolver.registerManifest("https://ns.mxhx.dev/2024/tests", mappings);

		var offsetTag = mxhxData.findTagOrSurroundingTagContainingOffset(start);
		if (offsetTag == null) {
			return macro null;
		}
		var resolved = resolver.resolveTag(offsetTag);
		if (resolved == null) {
			return macro null;
		}
		if ((resolved is IMXHXTypeSymbol)) {
			var resolvedType:IMXHXTypeSymbol = cast resolved;
			return macro $v{resolvedType.params.map(param -> param != null ? param.qname : null)};
		} else if ((resolved is IMXHXFieldSymbol)) {
			var resolvedField:IMXHXFieldSymbol = cast resolved;
			return macro $v{resolvedField.type.params.map(param -> param != null ? param.qname : null)};
		}
		return macro null;
	}

	public static macro function resolveTagTypeParamNames(mxhxSource:String, start:Int):haxe.macro.Expr {
		var parser = new MXHXParser(mxhxSource, "source.mxhx");
		var mxhxData = parser.parse();
		var resolver = new MXHXMacroResolver();

		var manifestPath = haxe.io.Path.join([Sys.getCwd(), "mxhx-manifest.xml"]);
		var content = sys.io.File.getContent(manifestPath);
		var xml = Xml.parse(content);
		var mappings:Map<String, MXHXManifestEntry> = [];
		for (componentXml in xml.firstElement().elementsNamed("component")) {
			var xmlName = componentXml.get("id");
			var qname = componentXml.get("class");
			var params:Array<String> = null;
			if (componentXml.exists("params")) {
				params = componentXml.get("params").split(",");
			}
			mappings.set(xmlName, new MXHXManifestEntry(xmlName, qname, params));
		}
		resolver.registerManifest("https://ns.mxhx.dev/2024/tests", mappings);

		var offsetTag = mxhxData.findTagOrSurroundingTagContainingOffset(start);
		if (offsetTag == null) {
			return macro null;
		}
		var resolved = resolver.resolveTag(offsetTag);
		if (resolved == null) {
			return macro null;
		}
		if ((resolved is IMXHXTypeSymbol)) {
			var resolvedType:IMXHXTypeSymbol = cast resolved;
			return macro $v{resolvedType.paramNames};
		} else if ((resolved is IMXHXFieldSymbol)) {
			var resolvedField:IMXHXFieldSymbol = cast resolved;
			return macro $v{resolvedField.type.paramNames};
		}
		return macro null;
	}
}
