/*
	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
 */

package mxhx.resolver.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr.Error;
import haxe.macro.Expr.MetadataEntry;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import mxhx.manifest.MXHXManifestEntry;
import mxhx.resolver.IMXHXResolver;
import mxhx.resolver.MXHXResolvers;
import mxhx.symbols.IMXHXAbstractSymbol;
import mxhx.symbols.IMXHXAbstractToOrFromInfo;
import mxhx.symbols.IMXHXArgumentSymbol;
import mxhx.symbols.IMXHXClassSymbol;
import mxhx.symbols.IMXHXEnumFieldSymbol;
import mxhx.symbols.IMXHXEnumSymbol;
import mxhx.symbols.IMXHXEventSymbol;
import mxhx.symbols.IMXHXFieldSymbol;
import mxhx.symbols.IMXHXFunctionTypeSymbol;
import mxhx.symbols.IMXHXInterfaceSymbol;
import mxhx.symbols.IMXHXSymbol;
import mxhx.symbols.IMXHXTypeSymbol;
import mxhx.symbols.MXHXSymbolTools;
import mxhx.symbols.internal.MXHXAbstractSymbol;
import mxhx.symbols.internal.MXHXAbstractToOrFromInfo;
import mxhx.symbols.internal.MXHXArgumentSymbol;
import mxhx.symbols.internal.MXHXClassSymbol;
import mxhx.symbols.internal.MXHXEnumFieldSymbol;
import mxhx.symbols.internal.MXHXEnumSymbol;
import mxhx.symbols.internal.MXHXEventSymbol;
import mxhx.symbols.internal.MXHXFieldSymbol;
import mxhx.symbols.internal.MXHXFunctionTypeSymbol;
import mxhx.symbols.internal.MXHXInterfaceSymbol;

class MXHXMacroResolver implements IMXHXResolver {
	private static final MODULE_STD_TYPES = "StdTypes";
	private static final META_DEFAULT_XML_PROPERTY = "defaultXmlProperty";
	private static final META_ENUM = ":enum";
	private static final TYPE_DYNAMIC = "Dynamic";

	public function new() {
		manifests = MXHXResolvers.getMappings();
	}

	private var manifests:Map<String, Map<String, MXHXManifestEntry>> = [];
	private var qnameLookup:Map<String, IMXHXTypeSymbol> = [];
	private var pendingQnameLookup:Map<String, IMXHXTypeSymbol> = [];

	public function registerManifest(uri:String, mappings:Map<String, MXHXManifestEntry>):Void {
		manifests.set(uri, mappings);
	}

	public function resolveTag(tagData:IMXHXTagData):IMXHXSymbol {
		if (tagData == null) {
			return null;
		}
		if (!hasValidPrefix(tagData)) {
			return null;
		}
		var resolvedProperty = resolveTagAsPropertySymbol(tagData);
		if (resolvedProperty != null) {
			return resolvedProperty;
		}
		var resolvedEvent = resolveTagAsEventSymbol(tagData);
		if (resolvedEvent != null) {
			return resolvedEvent;
		}
		return resolveTagAsTypeSymbol(tagData);
	}

	public function resolveAttribute(attributeData:IMXHXTagAttributeData):IMXHXSymbol {
		if (attributeData == null) {
			return null;
		}
		var tagData:IMXHXTagData = attributeData.parentTag;
		var tagSymbol = resolveTag(tagData);
		if (tagSymbol == null || !(tagSymbol is IMXHXClassSymbol)) {
			return null;
		}

		var classSymbol:IMXHXClassSymbol = cast tagSymbol;
		var field = MXHXSymbolTools.resolveFieldByName(classSymbol, attributeData.shortName);
		if (field != null) {
			return field;
		}
		var event = MXHXSymbolTools.resolveEventByName(classSymbol, attributeData.shortName);
		if (event != null) {
			return event;
		}
		return null;
	}

	public function resolveTagField(tag:IMXHXTagData, fieldName:String):IMXHXFieldSymbol {
		var tagSymbol = resolveTag(tag);
		if (tagSymbol == null || !(tagSymbol is IMXHXClassSymbol)) {
			return null;
		}

		var classSymbol:IMXHXClassSymbol = cast tagSymbol;
		return MXHXSymbolTools.resolveFieldByName(classSymbol, fieldName);
	}

	public function resolveQname(qname:String):IMXHXTypeSymbol {
		if (qname == null) {
			return null;
		}
		var result = resolveQnameInternal(qname);
		// resolveQname() can be called recursively, if the Haxe compiler
		// decides that it needs to run another build macro before this method
		// returns. we don't want to return any symbols that are not yet
		// completely populated, so this fills in anything that wasn't completed
		// yet, at the potential cost of doing some work more than once.
		for (key => value in pendingQnameLookup) {
			qnameLookup.remove(key);
			resolveQnameInternal(key);
		}
		return result;
	}

	private function resolveQnameInternal(qname:String):IMXHXTypeSymbol {
		if (qname == null) {
			return null;
		}
		var qnameMacroType = resolveMacroTypeForQname(qname);
		if (qnameMacroType == null) {
			return null;
		}
		var qnameParams:Array<IMXHXTypeSymbol>;
		var paramsIndex = qname.indexOf("<");
		if (paramsIndex != -1) {
			qnameParams = qnameToParams(qname, paramsIndex);
		} else {
			var discoveredParams:Array<Type> = null;
			if (qnameMacroType != null) {
				switch (qnameMacroType) {
					case TInst(t, params):
						discoveredParams = params;
					case TAbstract(t, params):
						var abstractType = t.get();
						discoveredParams = params;
					case TEnum(t, params):
						discoveredParams = params;
					default:
				}
			}
			if (discoveredParams != null && discoveredParams.length > 0) {
				qname += "<";
				for (i in 0...discoveredParams.length) {
					var param = discoveredParams[i];
					if (i > 0) {
						qname += ",";
					}
					var paramQname = macroTypeToQname(param);
					if (paramQname == null) {
						paramQname = "%";
					}
					qname += paramQname;
				}
				qname += ">";
			}
		}
		var resolved = qnameLookup.get(qname);
		if (resolved != null) {
			return resolved;
		}
		switch (qnameMacroType) {
			case TInst(t, params):
				var classType = t.get();
				if (classType.isInterface) {
					return createMXHXInterfaceSymbolForClassType(classType, qnameParams);
				}
				return createMXHXClassSymbolForClassType(classType, qnameParams);
			case TAbstract(t, params):
				var abstractType = t.get();
				if (abstractType.meta.has(META_ENUM)) {
					return createMXHXEnumSymbolForAbstractEnumType(abstractType, qnameParams);
				} else {
					return createMXHXAbstractSymbolForAbstractType(abstractType, qnameParams);
				}
			case TEnum(t, params):
				var enumType = t.get();
				return createMXHXEnumSymbolForEnumType(enumType, qnameParams);
			case TFun(args, ret):
				return createMXHXFunctionTypeSymbolFromArgsAndRet(qname, args, ret);
			default:
				return null;
		}
	}

	public function invalidateSymbol(symbol:IMXHXTypeSymbol):Void {
		qnameLookup.remove(symbol.qname);
	}

	public function getTagNamesForQname(qnameToFind:String):Map<String, String> {
		var result:Map<String, String> = [];
		for (uri => mappings in manifests) {
			for (tagName => manifestEntry in mappings) {
				if (manifestEntry.qname == qnameToFind) {
					result.set(uri, tagName);
				}
			}
		}
		return result;
	}

	public function getParamsForQname(qnameToFind:String):Array<String> {
		var index = qnameToFind.indexOf("<");
		if (index != -1) {
			qnameToFind = qnameToFind.substr(0, index);
		}
		for (uri => mappings in manifests) {
			for (tagName => manifestEntry in mappings) {
				if (manifestEntry.qname == qnameToFind) {
					var params = manifestEntry.params;
					if (params == null) {
						return [];
					}
					return params.copy();
				}
			}
		}
		return [];
	}

	public function getTypes():Array<IMXHXTypeSymbol> {
		var result:Map<String, IMXHXTypeSymbol> = [];
		// the following code resolves only known mappings,
		// but any class is technically able to be completed,
		// so this implementation is incomplete
		for (uri => mappings in manifests) {
			for (tagName => manifestEntry in mappings) {
				var qname = manifestEntry.qname;
				if (!result.exists(qname)) {
					var symbol = resolveQname(qname);
					if (symbol != null) {
						result.set(qname, symbol);
					}
				}
			}
		}
		return Lambda.array(result);
	}

	private function qnameToParams(qname:String, startIndex:Int):Array<IMXHXTypeSymbol> {
		var params:Array<IMXHXTypeSymbol> = [];
		var paramsStack = 1;
		var funArgsStack = 0;
		var funRetPending = false;
		var pendingStringStart = startIndex + 1;
		for (i in pendingStringStart...qname.length) {
			var currentChar = qname.charAt(i);
			if (currentChar == "<") {
				paramsStack++;
			} else if (currentChar == ">") {
				if (!funRetPending) {
					paramsStack--;
					if (paramsStack == 0) {
						var pendingString = StringTools.trim(qname.substring(pendingStringStart, i));
						if (pendingString.length > 0) {
							params.push(resolveQnameInternal(pendingString));
						}
						break;
					}
				} else {
					funRetPending = false;
				}
			} else if (currentChar == "(") {
				funArgsStack++;
			} else if (currentChar == ")") {
				funArgsStack--;
				funRetPending = true;
			} else if (currentChar == "," && funArgsStack == 0 && paramsStack == 1) {
				var pendingString = StringTools.trim(qname.substring(pendingStringStart, i));
				params.push(resolveQnameInternal(pendingString));
				pendingStringStart = i + 1;
				continue;
			}
		}
		return params;
	}

	private static function splitFunctionTypeQname(qname:String):{args:Array<String>, ret:String} {
		var argStrings:Array<String> = [];
		var retString:String = null;
		var funStack = 1;
		var paramsStack = 0;
		var pendingStringStart = 1;
		for (i in pendingStringStart...qname.length) {
			var currentChar = qname.charAt(i);
			if (currentChar == "<") {
				paramsStack++;
			} else if (currentChar == ">") {
				paramsStack--;
			} else if (currentChar == "(") {
				funStack++;
			} else if (currentChar == ")") {
				funStack--;
				if (funStack == 0) {
					var pendingString = StringTools.trim(qname.substring(pendingStringStart, i));
					if (pendingString.length > 0) {
						argStrings.push(pendingString);
					}
					retString = StringTools.trim(qname.substr(qname.indexOf(">", i + 1) + 1));
					break;
				}
			} else if (currentChar == "," && funStack == 1 && paramsStack == 0) {
				var pendingString = StringTools.trim(qname.substring(pendingStringStart, i));
				argStrings.push(pendingString);
				pendingStringStart = i + 1;
				continue;
			}
		}
		return {args: argStrings, ret: retString};
	}

	private function resolveParentTag(tagData:IMXHXTagData):IMXHXSymbol {
		var parentTag = tagData.parentTag;
		if (parentTag == null) {
			return null;
		}
		if (parentTag.prefix != tagData.prefix) {
			return null;
		}
		var resolvedParent = resolveTag(parentTag);
		if (resolvedParent != null) {
			return resolvedParent;
		}
		return null;
	}

	private function resolveTagAsPropertySymbol(tagData:IMXHXTagData):IMXHXFieldSymbol {
		var parentSymbol = resolveParentTag(tagData);
		if (parentSymbol == null || !(parentSymbol is IMXHXClassSymbol)) {
			return null;
		}
		var classSymbol:IMXHXClassSymbol = cast parentSymbol;
		return MXHXSymbolTools.resolveFieldByName(classSymbol, tagData.shortName);
	}

	private function resolveTagAsEventSymbol(tagData:IMXHXTagData):IMXHXEventSymbol {
		var parentSymbol = resolveParentTag(tagData);
		if (parentSymbol == null || !(parentSymbol is IMXHXClassSymbol)) {
			return null;
		}
		var classSymbol:IMXHXClassSymbol = cast parentSymbol;
		return MXHXSymbolTools.resolveEventByName(classSymbol, tagData.shortName);
	}

	private function resolveTagAsTypeSymbol(tagData:IMXHXTagData):IMXHXSymbol {
		var parentTag = tagData.parentTag;
		var assignedToField:IMXHXFieldSymbol = null;
		if (parentTag != null) {
			var resolvedParentTag = resolveTag(parentTag);
			if ((resolvedParentTag is IMXHXClassSymbol)) {
				var resolvedParentClass:IMXHXClassSymbol = cast resolvedParentTag;
				var defaultProperty = resolvedParentClass.defaultProperty;
				if (defaultProperty != null) {
					assignedToField = MXHXSymbolTools.resolveFieldByName(resolvedParentClass, defaultProperty);
				}
			} else if ((resolvedParentTag is IMXHXFieldSymbol)) {
				assignedToField = cast resolvedParentTag;
			}
		}

		var prefix = tagData.prefix;
		var uri = tagData.uri;
		var localName = tagData.shortName;

		if (uri != null && manifests.exists(uri)) {
			var mappings = manifests.get(uri);
			if (mappings.exists(localName)) {
				var manifestEntry = mappings.get(localName);
				var qname = manifestEntry.qname;
				var paramNames = manifestEntry.params;
				var qnameMacroType = resolveMacroTypeForQname(qname);
				var discoveredParams:Array<Type> = null;
				if (qnameMacroType != null) {
					switch (qnameMacroType) {
						case TInst(t, params):
							discoveredParams = params;
						case TAbstract(t, params):
							discoveredParams = params;
						case TEnum(t, params):
							discoveredParams = params;
						default:
					}
				}

				if ((paramNames != null && paramNames.length > 0) || (discoveredParams != null && discoveredParams.length > 0)) {
					var resolvedParams:Array<IMXHXTypeSymbol> = [];

					// highest priority: explicit param names in XML attributes
					if (paramNames != null) {
						for (i in 0...paramNames.length) {
							var paramName = paramNames[i];
							var paramNameAttr = tagData.getAttributeData(paramName);
							if (paramNameAttr == null) {
								continue;
							}
							var itemType = resolveQnameInternal(paramNameAttr.rawValue);
							if (tagData.stateName != null) {
								return null;
							}
							resolvedParams[i] = itemType;
						}
					}

					// next: discovered macro types
					if (discoveredParams != null) {
						for (i in 0...discoveredParams.length) {
							if (resolvedParams[i] != null) {
								continue;
							}
							var discoveredParam = discoveredParams[i];
							if (discoveredParam != null) {
								var paramQname = macroTypeToQname(discoveredParam);
								resolvedParams[i] = resolveQnameInternal(paramQname);
							} else {
								resolvedParams[i] = null;
							}
						}
					}

					// finally: inference from the field this tag is assigned to
					if (assignedToField != null && assignedToField.type != null) {
						var resolvedType = resolveQname(qname);
						if (resolvedType.paramNames.length > 0) {
							for (i in 0...resolvedParams.length) {
								var param = resolvedParams[i];
								if (param == null) {
									var paramName = resolvedType.paramNames[i];
									resolvedParams[i] = inferTypeParameterForAssignment(resolvedType, paramName, assignedToField.type);
								}
							}
						}
					}

					qname += "<";
					for (i in 0...resolvedParams.length) {
						var resolvedParam = resolvedParams[i];
						if (i > 0) {
							qname += ",";
						}
						if (resolvedParam != null) {
							qname += resolvedParam.qname;
						} else {
							qname += "%";
						}
					}
					qname += ">";
				}
				var type = resolveQname(qname);
				if (type != null) {
					if ((type is IMXHXEnumSymbol)) {
						var enumSymbol:IMXHXEnumSymbol = cast type;
						if (tagData.stateName == null) {
							return type;
						}
						return Lambda.find(enumSymbol.fields, field -> field.name == tagData.stateName);
					} else {
						if (tagData.stateName != null) {
							return null;
						}
						return type;
					}
				}
			}
		}

		if (tagData.stateName != null) {
			return null;
		}

		if (uri != "*" && !StringTools.endsWith(uri, ".*")) {
			return null;
		}
		var qname = uri.substr(0, uri.length - 1) + localName;
		// purposefully using resolveQname() instead of resolveQnameInternal()
		// here to enure that all pending qname symbols are populated.
		var qnameType = resolveQname(qname);
		if (qnameType == null) {
			return null;
		}
		return qnameType;
	}

	private function createMXHXFieldSymbolForClassField(classField:ClassField, isStatic:Bool, owner:IMXHXTypeSymbol):IMXHXFieldSymbol {
		var resolvedType:IMXHXTypeSymbol = null;
		var typeQname = macroTypeToQname(classField.type, owner);
		if (typeQname != null) {
			resolvedType = resolveQnameInternal(typeQname);
		}
		var isMethod = false;
		var isReadable = false;
		var isWritable = false;
		switch (classField.kind) {
			case FMethod(k):
				isMethod = true;
				switch (k) {
					case MethDynamic:
						isWritable = true;
					default:
				}
			case FVar(read, write):
				switch (read) {
					case AccCall, AccNormal:
						isReadable = true;
					default:
				};
				switch (write) {
					case AccCall, AccNormal:
						isWritable = true;
					default:
				};
			default:
		}
		var result = new MXHXFieldSymbol(classField.name, owner, resolvedType, isMethod, classField.isPublic, isStatic);
		result.isReadable = isReadable;
		result.isWritable = isWritable;
		final posInfos = Context.getPosInfos(classField.pos);
		result.file = posInfos.file;
		result.offsets = {start: posInfos.min, end: posInfos.max};
		return result;
	}

	private function createMXHXEnumFieldSymbolForEnumField(enumField:EnumField, parent:IMXHXEnumSymbol):IMXHXEnumFieldSymbol {
		var args:Array<IMXHXArgumentSymbol> = null;
		switch (enumField.type) {
			case TFun(funArgs, funRet):
				args = funArgs.map(arg -> createMXHXArgumentSymbolForFunctionArg(arg, parent));
			default:
		}
		var result = new MXHXEnumFieldSymbol(enumField.name, parent, args);
		final posInfos = Context.getPosInfos(enumField.pos);
		result.file = posInfos.file;
		result.offsets = {start: posInfos.min, end: posInfos.max};
		return result;
	}

	private function createMXHXEnumFieldSymbolForAbstractField(abstractField:ClassField, parent:IMXHXEnumSymbol):IMXHXEnumFieldSymbol {
		var result = new MXHXEnumFieldSymbol(abstractField.name, parent, null);
		final posInfos = Context.getPosInfos(abstractField.pos);
		result.file = posInfos.file;
		result.offsets = {start: posInfos.min, end: posInfos.max};
		return result;
	}

	private function createMXHXArgumentSymbolForFunctionArg(functionArg:{name:String, opt:Bool, t:Type}, owner:IMXHXTypeSymbol):IMXHXArgumentSymbol {
		var qname = macroTypeToQname(functionArg.t, owner);
		var resolvedType = resolveQnameInternal(qname);
		return new MXHXArgumentSymbol(functionArg.name, resolvedType, functionArg.opt);
	}

	private function createMXHXInterfaceSymbolForClassType(classType:ClassType, params:Array<IMXHXTypeSymbol>):IMXHXInterfaceSymbol {
		var qname = MXHXResolverTools.definitionToQname(classType.name, classType.pack, classType.module,
			params != null ? params.map(param -> param != null ? param.qname : null) : null);
		var result:MXHXInterfaceSymbol = null;
		if (pendingQnameLookup.exists(qname)) {
			// may be called recursively before the symbol is completely
			// populated, so continue with the existing symbol.
			result = cast pendingQnameLookup.get(qname);
		} else {
			result = new MXHXInterfaceSymbol(classType.name, classType.pack.copy());
			result.qname = qname;
			result.module = classType.module;
			final posInfos = Context.getPosInfos(classType.pos);
			result.file = posInfos.file;
			result.offsets = {start: posInfos.min, end: posInfos.max};
			result.isPrivate = classType.isPrivate;
			pendingQnameLookup.set(qname, result);
		}
		// fields may reference this type, so make sure that it's available
		// before parsing anything else
		qnameLookup.set(qname, result);

		var paramsCount = classType.params.length;
		if (params != null && params.length < paramsCount) {
			params = params.copy();
			params.resize(paramsCount);
		}
		result.params = params != null ? params : classType.params.map(p -> null);
		result.paramNames = classType.params.map(typeParam -> typeParam.name);

		result.interfaces = classType.interfaces.map(i -> {
			var interfaceType = i.t.get();
			var interfaceQName = MXHXResolverTools.definitionToQname(interfaceType.name, interfaceType.pack, interfaceType.module,
				i.params.map(param -> macroTypeToQname(param, result)));
			var resolvedInterface = resolveQnameInternal(interfaceQName);
			if (resolvedInterface != null) {
				populateParamsMap(resolvedInterface, i, @:privateAccess result.__paramsMap);
			}
			return cast resolvedInterface;
		});

		for (i in 0...classType.interfaces.length) {
			var currentInterface = classType.interfaces[i];
			var resolvedInterface = result.interfaces[i];
			var interfaceParamsMap:Map<String, String> = [];
			for (j in 0...currentInterface.params.length) {
				var param = currentInterface.params[j];
				var resolved = resolvedInterface.params[j];
				if (resolved != null) {
					continue;
				}
				switch (param) {
					case TInst(t, params):
						var classType = t.get();
						switch (classType.kind) {
							case KTypeParameter(constraints):
								var classParamName = classType.name;
								var interfaceParamName = resolvedInterface.paramNames[j];
								interfaceParamsMap.set(interfaceParamName, classParamName);
							default:
						}
					default:
				}
			}
			@:privateAccess result.__paramsMap.set(resolvedInterface, interfaceParamsMap);
		}

		result.fields = classType.fields.get().map(classField -> createMXHXFieldSymbolForClassField(classField, false, result));
		result.meta = classType.meta.get().map(m -> {
			var params:Array<String> = null;
			if (m.params != null) {
				params = m.params.map(p -> ExprTools.toString(p));
			}
			return {name: m.name, params: params};
		});

		pendingQnameLookup.remove(qname);
		return result;
	}

	private function createMXHXClassSymbolForClassType(classType:ClassType, params:Array<IMXHXTypeSymbol>):IMXHXClassSymbol {
		var qname = MXHXResolverTools.definitionToQname(classType.name, classType.pack, classType.module,
			params != null ? params.map(param -> param != null ? param.qname : null) : null);

		var result:MXHXClassSymbol = null;
		if (pendingQnameLookup.exists(qname)) {
			// may be called recursively before the symbol is completely
			// populated, so continue with the existing symbol.
			result = cast pendingQnameLookup.get(qname);
		} else {
			result = new MXHXClassSymbol(classType.name, classType.pack.copy());
			result.qname = qname;
			result.module = classType.module;
			final posInfos = Context.getPosInfos(classType.pos);
			result.file = posInfos.file;
			result.offsets = {start: posInfos.min, end: posInfos.max};
			result.isPrivate = classType.isPrivate;
			pendingQnameLookup.set(qname, result);
		}
		// fields may reference this type, so make sure that it's available
		// before parsing anything else
		qnameLookup.set(qname, result);

		var paramsCount = classType.params.length;
		if (params != null && params.length < paramsCount) {
			params = params.copy();
			params.resize(paramsCount);
		}
		result.params = params != null ? params : classType.params.map(p -> null);
		result.paramNames = classType.params.map(param -> param.name);

		var superClassType = classType.superClass;
		var resolvedSuperClass:IMXHXClassSymbol = null;
		if (superClassType != null) {
			var superClass = superClassType.t.get();
			var superClassQName = MXHXResolverTools.definitionToQname(superClass.name, superClass.pack, superClass.module,
				superClass.params.map(param -> macroTypeToQname(param.t, result)));
			resolvedSuperClass = cast resolveQnameInternal(superClassQName);
			if (resolvedSuperClass != null) {
				populateParamsMap(resolvedSuperClass, superClassType, @:privateAccess result.__paramsMap);
			}
		}
		result.superClass = resolvedSuperClass;

		result.interfaces = classType.interfaces.map(i -> {
			var interfaceType = i.t.get();
			var interfaceQName = MXHXResolverTools.definitionToQname(interfaceType.name, interfaceType.pack, interfaceType.module,
				i.params.map(param -> macroTypeToQname(param, result)));
			var resolvedInterface = resolveQnameInternal(interfaceQName);
			if (resolvedInterface != null) {
				populateParamsMap(resolvedInterface, i, @:privateAccess result.__paramsMap);
			}
			return cast resolvedInterface;
		});

		result.fields = classType.fields.get().map(classField -> createMXHXFieldSymbolForClassField(classField, false, result));
		result.meta = classType.meta.get().map(m -> {
			var params:Array<String> = null;
			if (m.params != null) {
				params = m.params.map(p -> ExprTools.toString(p));
			}
			return {name: m.name, params: params};
		});
		result.events = classType.meta.extract(":event").map(eventMeta -> {
			if (eventMeta.params.length != 1) {
				return null;
			}
			var eventName = getEventName(eventMeta);
			if (eventName == null) {
				return null;
			}
			var eventTypeQname = getEventType(eventMeta);
			var resolvedType:IMXHXClassSymbol = cast resolveQnameInternal(eventTypeQname);
			var result:IMXHXEventSymbol = new MXHXEventSymbol(eventName, resolvedType);
			return result;
		}).filter(eventSymbol -> eventSymbol != null);
		result.defaultProperty = getDefaultProperty(classType);

		pendingQnameLookup.remove(qname);
		return result;
	}

	private function createMXHXAbstractSymbolForAbstractType(abstractType:AbstractType, params:Array<IMXHXTypeSymbol>):IMXHXAbstractSymbol {
		var qname = MXHXResolverTools.definitionToQname(abstractType.name, abstractType.pack, abstractType.module,
			params != null ? params.map(param -> param != null ? param.qname : null) : null);
		var result:MXHXAbstractSymbol = null;
		if (pendingQnameLookup.exists(qname)) {
			// may be called recursively before the symbol is completely
			// populated, so continue with the existing symbol.
			result = cast pendingQnameLookup.get(qname);
		} else {
			result = new MXHXAbstractSymbol(abstractType.name, abstractType.pack.copy());
			result.qname = qname;
			result.module = abstractType.module;
			final posInfos = Context.getPosInfos(abstractType.pos);
			result.file = posInfos.file;
			result.offsets = {start: posInfos.min, end: posInfos.max};
			result.isPrivate = abstractType.isPrivate;
			pendingQnameLookup.set(qname, result);
		}
		// fields may reference this type, so make sure that it's available
		// before parsing anything else
		qnameLookup.set(qname, result);

		var paramsCount = abstractType.params.length;
		if (params != null && params.length < paramsCount) {
			params = params.copy();
			params.resize(paramsCount);
		}
		result.params = params != null ? params : abstractType.params.map(p -> null);
		result.paramNames = abstractType.params.map(typeParam -> typeParam.name);

		var typeQname = macroTypeToQname(abstractType.type, result);
		result.type = resolveQnameInternal(typeQname);

		if (abstractType.impl != null) {
			result.impl = createMXHXClassSymbolForClassType(abstractType.impl.get(), []);
		}

		result.from = abstractType.from.map(function(from):IMXHXAbstractToOrFromInfo {
			var qname = macroTypeToQname(from.t, result);
			var resolvedType = resolveQnameInternal(qname);
			var resolvedField:IMXHXFieldSymbol = null;
			if (result.impl != null) {
				resolvedField = Lambda.find(result.impl.fields, fieldSymbol -> fieldSymbol.isStatic && fieldSymbol.name == from.field.name);
			}
			return new MXHXAbstractToOrFromInfo(resolvedField, resolvedType);
		});

		result.to = abstractType.to.map(function(to):IMXHXAbstractToOrFromInfo {
			var qname = macroTypeToQname(to.t, result);
			var resolvedType = resolveQnameInternal(qname);
			var resolvedField:IMXHXFieldSymbol = null;
			if (result.impl != null) {
				resolvedField = Lambda.find(result.impl.fields, fieldSymbol -> fieldSymbol.isStatic && fieldSymbol.name == to.field.name);
			}
			return new MXHXAbstractToOrFromInfo(resolvedField, resolvedType);
		});

		pendingQnameLookup.remove(qname);
		return result;
	}

	private function createMXHXEnumSymbolForAbstractEnumType(abstractType:AbstractType, params:Array<IMXHXTypeSymbol>):IMXHXEnumSymbol {
		var qname = MXHXResolverTools.definitionToQname(abstractType.name, abstractType.pack, abstractType.module,
			params != null ? params.map(param -> param != null ? param.qname : null) : null);
		var result:MXHXEnumSymbol = null;
		if (pendingQnameLookup.exists(qname)) {
			// may be called recursively before the symbol is completely
			// populated, so continue with the existing symbol.
			result = cast pendingQnameLookup.get(qname);
		} else {
			result = new MXHXEnumSymbol(abstractType.name, abstractType.pack.copy());
			result.qname = qname;
			result.module = abstractType.module;
			final posInfos = Context.getPosInfos(abstractType.pos);
			result.file = posInfos.file;
			result.offsets = {start: posInfos.min, end: posInfos.max};
			result.isPrivate = abstractType.isPrivate;
			pendingQnameLookup.set(qname, result);
		}
		// fields may reference this type, so make sure that it's available
		// before parsing anything else
		qnameLookup.set(qname, result);

		var paramsCount = abstractType.params.length;
		if (params != null && params.length < paramsCount) {
			params = params.copy();
			params.resize(paramsCount);
		}
		result.params = params != null ? params : abstractType.params.map(p -> null);
		result.paramNames = abstractType.params.map(typeParam -> typeParam.name);

		result.fields = abstractType.impl.get().statics.get().map(field -> createMXHXEnumFieldSymbolForAbstractField(field, result));
		result.meta = abstractType.meta.get().map(m -> {
			var params:Array<String> = null;
			if (m.params != null) {
				params = m.params.map(p -> ExprTools.toString(p));
			}
			return {name: m.name, params: params};
		});

		pendingQnameLookup.remove(qname);
		return result;
	}

	private function createMXHXEnumSymbolForEnumType(enumType:EnumType, params:Array<IMXHXTypeSymbol>):IMXHXEnumSymbol {
		var qname = MXHXResolverTools.definitionToQname(enumType.name, enumType.pack, enumType.module,
			params != null ? params.map(param -> param != null ? param.qname : null) : null);
		var result:MXHXEnumSymbol = null;
		if (pendingQnameLookup.exists(qname)) {
			// may be called recursively before the symbol is completely
			// populated, so continue with the existing symbol.
			result = cast pendingQnameLookup.get(qname);
		} else {
			result = new MXHXEnumSymbol(enumType.name, enumType.pack.copy());
			result.qname = qname;
			result.module = enumType.module;
			final posInfos = Context.getPosInfos(enumType.pos);
			result.file = posInfos.file;
			result.offsets = {start: posInfos.min, end: posInfos.max};
			result.isPrivate = enumType.isPrivate;
			pendingQnameLookup.set(qname, result);
		}
		// fields may reference this type, so make sure that it's available
		// before parsing anything else
		qnameLookup.set(qname, result);

		var paramsCount = enumType.params.length;
		if (params != null && params.length < paramsCount) {
			params = params.copy();
			params.resize(paramsCount);
		}
		result.params = params != null ? params : enumType.params.map(p -> null);
		result.paramNames = enumType.params.map(typeParam -> typeParam.name);

		var fields:Array<IMXHXEnumFieldSymbol> = [];
		for (key => value in enumType.constructs) {
			fields.push(createMXHXEnumFieldSymbolForEnumField(value, result));
		}
		result.fields = fields;
		result.meta = enumType.meta.get().map(m -> {
			var params:Array<String> = null;
			if (m.params != null) {
				params = m.params.map(p -> ExprTools.toString(p));
			}
			return {name: m.name, params: params};
		});

		pendingQnameLookup.remove(qname);
		return result;
	}

	private function createMXHXFunctionTypeSymbolFromArgsAndRet(qname:String, args:Array<{name:String, opt:Bool, t:Type}>, ret:Type):IMXHXFunctionTypeSymbol {
		var retQname = macroTypeToQname(ret);
		var argSymbols = args.map(arg -> createMXHXArgumentSymbolForFunctionArg(arg, null));
		var retSymbol = resolveQnameInternal(retQname);
		var functionType = new MXHXFunctionTypeSymbol(qname, argSymbols, retSymbol);
		functionType.qname = qname;
		qnameLookup.set(qname, functionType);
		return functionType;
	}

	private function populateParamsMap(resolvedType:IMXHXTypeSymbol, classType:{t:Ref<ClassType>, params:Array<Type>},
			paramsMap:Map<IMXHXTypeSymbol, Map<String, String>>):Void {
		var innerParamsMap:Map<String, String> = [];
		for (j in 0...classType.params.length) {
			var param = classType.params[j];
			var resolved = resolvedType.params[j];
			if (resolved != null) {
				continue;
			}
			switch (param) {
				case TInst(t, params):
					var paramClassType = t.get();
					switch (paramClassType.kind) {
						case KTypeParameter(constraints):
							var classParamName = paramClassType.name;
							var resolvedTypeParamName = resolvedType.paramNames[j];
							innerParamsMap.set(resolvedTypeParamName, classParamName);
						default:
					}
				default:
			}
		}
		paramsMap.set(resolvedType, innerParamsMap);
	}

	private function hasValidPrefix(tag:IMXHXTagData):Bool {
		var prefixMap = tag.compositePrefixMap;
		if (prefixMap == null) {
			return false;
		}
		return prefixMap.containsPrefix(tag.prefix) && prefixMap.containsUri(tag.uri);
	}

	private static function getEventName(eventMeta:MetadataEntry):String {
		if (eventMeta.name != ":event") {
			throw new Error("getEventNames() requires :event meta", Context.currentPos());
		}
		var typedExprDef = Context.typeExpr(eventMeta.params[0]).expr;
		if (typedExprDef == null) {
			return null;
		}
		var result:String = null;
		while (true) {
			switch (typedExprDef) {
				case TConst(TString(s)):
					return s;
				case TCast(e, _):
					typedExprDef = e.expr;
				case TField(e, FStatic(c, cf)):
					var classField = cf.get();
					var classFieldExpr = classField.expr();
					if (classFieldExpr == null) {
						// can't find the string value, so generate it from the
						// name of the field based on standard naming convention
						var parts = classField.name.split("_");
						var result = "";
						for (i in 0...parts.length) {
							var part = parts[i].toLowerCase();
							if (i == 0) {
								result += part;
							} else {
								result += part.charAt(0).toUpperCase() + part.substr(1);
							}
						}
						return result;
					}
					typedExprDef = classField.expr().expr;
				default:
					return null;
			}
		}
		return null;
	}

	/**
		Gets the type of an event from an `:event` metadata entry.
	**/
	private static function getEventType(eventMeta:MetadataEntry):String {
		if (eventMeta.name != ":event") {
			throw new Error("getEventType() requires :event meta", Context.currentPos());
		}
		var typedExprType = Context.typeExpr(eventMeta.params[0]).t;
		return switch (typedExprType) {
			case TAbstract(t, params):
				var abstractType = t.get();
				var qname = MXHXResolverTools.definitionToQname(abstractType.name, abstractType.pack, abstractType.module);
				if ("openfl.events.EventType" != qname) {
					return "openfl.events.Event";
				}
				switch (params[0]) {
					case TInst(t, params): t.toString();
					default: null;
				}
			default: "openfl.events.Event";
		};
	}

	private static function getDefaultProperty(t:BaseType):String {
		var metaDefaultXmlProperty = META_DEFAULT_XML_PROPERTY;
		if (!t.meta.has(metaDefaultXmlProperty)) {
			metaDefaultXmlProperty = ":" + metaDefaultXmlProperty;
			if (!t.meta.has(metaDefaultXmlProperty)) {
				return null;
			}
		}
		var defaultPropertyMeta = t.meta.extract(metaDefaultXmlProperty)[0];
		if (defaultPropertyMeta.params.length != 1) {
			throw new Error('The @${metaDefaultXmlProperty} meta must have one property name', defaultPropertyMeta.pos);
		}
		var param = defaultPropertyMeta.params[0];
		var propertyName:String = null;
		switch (param.expr) {
			case EConst(c):
				switch (c) {
					case CString(s, kind):
						propertyName = s;
					default:
				}
			default:
		}
		if (propertyName == null) {
			throw new Error('The @${META_DEFAULT_XML_PROPERTY} meta param must be a string', param.pos);
			return null;
		}
		return propertyName;
	}

	private static function functionArgsAndRetToQname(args:Array<{name:String, opt:Bool, t:Type}>, ret:Type, ?typeParameterContext:IMXHXTypeSymbol):String {
		var qname = '(';
		for (i in 0...args.length) {
			var arg = args[i];
			if (i > 0) {
				qname += ', ';
			}
			if (arg.opt) {
				qname += '?';
			}
			var argTypeName = macroTypeToQname(arg.t, typeParameterContext);
			if (argTypeName == null) {
				argTypeName = TYPE_DYNAMIC;
			}
			qname += argTypeName;
		}
		var retName = macroTypeToQname(ret, typeParameterContext);
		if (retName == null) {
			retName = TYPE_DYNAMIC;
		}
		qname += ') -> ${retName}';
		return qname;
	}

	private static function getTypeParameterNamed(paramName:String, type:IMXHXTypeSymbol):IMXHXTypeSymbol {
		var params = type.params;
		var paramNames = type.paramNames;
		for (i in 0...paramNames.length) {
			var other = paramNames[i];
			if (paramName == other) {
				return params[i];
			}
		}
		return null;
	}

	private static function inferTypeParameterForAssignment(type:IMXHXTypeSymbol, paramName:String, assignToType:IMXHXTypeSymbol):IMXHXTypeSymbol {
		if (assignToType == null) {
			return null;
		}
		var param = getTypeParameterNamed(paramName, type);
		if (param != null) {
			return param;
		}
		var assignToTypeQnameToFind = assignToType.qname;
		var index = assignToTypeQnameToFind.indexOf("<");
		if (index != -1) {
			assignToTypeQnameToFind = assignToTypeQnameToFind.substr(0, index);
		}
		var typeQname = type.qname;
		var index = typeQname.indexOf("<");
		if (index != -1) {
			typeQname = typeQname.substr(0, index);
		}
		if (assignToTypeQnameToFind == typeQname) {
			return getTypeParameterNamed(paramName, assignToType);
		}
		if ((type is MXHXClassSymbol)) {
			var typeAsClass:MXHXClassSymbol = cast type;
			var superClass = typeAsClass.superClass;
			if (superClass != null && (assignToType is IMXHXClassSymbol)) {
				var superClassQname = superClass.qname;
				var index = superClassQname.indexOf("<");
				if (index != -1) {
					superClassQname = superClassQname.substr(0, index);
				}
				if (superClassQname == assignToTypeQnameToFind) {
					var superClassParamsMap = @:privateAccess typeAsClass.__paramsMap.get(superClass);
					for (key => value in superClassParamsMap) {
						if (value == paramName) {
							return getTypeParameterNamed(key, assignToType);
						}
					}
				}
			} else if ((assignToType is IMXHXInterfaceSymbol)) {
				for (currentInterface in typeAsClass.interfaces) {
					var currentInterfaceQname = currentInterface.qname;
					var index = currentInterfaceQname.indexOf("<");
					if (index != -1) {
						currentInterfaceQname = currentInterfaceQname.substr(0, index);
					}
					if (currentInterfaceQname == assignToTypeQnameToFind) {
						var interfaceParamsMap = @:privateAccess typeAsClass.__paramsMap.get(currentInterface);
						for (key => value in interfaceParamsMap) {
							if (value == paramName) {
								return getTypeParameterNamed(key, assignToType);
							}
						}
					}
				}
			}
		}
		if ((type is MXHXInterfaceSymbol)) {
			var typeAsInterface:MXHXInterfaceSymbol = cast type;
			if ((assignToType is IMXHXInterfaceSymbol)) {
				for (currentInterface in typeAsInterface.interfaces) {
					var currentInterfaceQname = currentInterface.qname;
					var index = currentInterfaceQname.indexOf("<");
					if (index != -1) {
						currentInterfaceQname = currentInterfaceQname.substr(0, index);
					}
					if (currentInterfaceQname == assignToTypeQnameToFind) {
						var interfaceParamsMap = @:privateAccess typeAsInterface.__paramsMap.get(currentInterface);
						for (key => value in interfaceParamsMap) {
							if (value == paramName) {
								return getTypeParameterNamed(key, assignToType);
							}
						}
					}
				}
			}
		}
		return null;
	}

	private static function macroTypeToQname(type:Type, ?typeParameterContext:IMXHXTypeSymbol):String {
		var current = type;
		while (current != null) {
			switch (current) {
				case TInst(t, params):
					var classType = t.get();
					switch (classType.kind) {
						case KTypeParameter(constraints):
							if (typeParameterContext != null) {
								var paramNames = typeParameterContext.paramNames;
								if (paramNames.length > 0) {
									for (i in 0...paramNames.length) {
										var paramName = paramNames[i];
										if (paramName == classType.name) {
											var contextParam = typeParameterContext.params[i];
											if (contextParam != null) {
												return contextParam.qname;
											}
										}
									}
								}
							}
							return null;
						default:
					}
					return MXHXResolverTools.definitionToQname(classType.name, classType.pack, classType.module,
						params.map(param -> macroTypeToQname(param, typeParameterContext)));
				case TEnum(t, params):
					var enumType = t.get();
					return MXHXResolverTools.definitionToQname(enumType.name, enumType.pack, enumType.module, params.map(param -> macroTypeToQname(param)));
				case TAbstract(t, params):
					var abstractType = t.get();
					return MXHXResolverTools.definitionToQname(abstractType.name, abstractType.pack, abstractType.module,
						params.map(param -> macroTypeToQname(param)));
				case TDynamic(t):
					return TYPE_DYNAMIC + "<%>";
				case TFun(args, ret):
					return functionArgsAndRetToQname(args, ret, typeParameterContext);
				case TMono(t):
					current = t.get();
				case TType(t, params):
					current = t.get().type;
				case TLazy(f):
					try {
						current = f();
					} catch (e:Dynamic) {
						// avoid Accessing a type while it's being typed exception
						return null;
					}
				default:
					return null;
			}
		}
		return null;
	}

	private static function resolveMacroTypeForQname(qname:String):Type {
		if (qname.charAt(0) == "(") {
			var splitResult = splitFunctionTypeQname(qname);
			var argStrings = splitResult.args;
			var retString = splitResult.ret;
			var args = argStrings.map(argString -> {
				var opt = argString.charAt(0) == "?";
				if (opt) {
					argString = argString.substr(1);
				}
				var argName:String = null;
				var colonIndex = argString.indexOf(":");
				if (colonIndex != -1) {
					argName = argString.substring(0, colonIndex);
					argString = argString.substring(colonIndex + 1);
				}
				return {
					opt: opt,
					name: argName,
					t: argString
				};
			}).map((arg:{opt:Bool, name:String, t:Dynamic}) -> {
				arg.t = resolveMacroTypeForQname(arg.t);
				return arg;
			});
			var ret = resolveMacroTypeForQname(retString);
			return TFun(args, ret);
		}
		var paramIndex = qname.indexOf("<");
		if (paramIndex != -1) {
			qname = qname.substr(0, paramIndex);
		}

		// first try to find the qname by module
		// we need to do this because types with @:generic will cause the Haxe
		// compiler to crash when we omit the type parameter for
		// Context.getType(). it won't throw. it will just crash!
		var resolvedType:Type = null;
		try {
			resolvedType = Lambda.find(Context.getModule(qname), type -> {
				var moduleTypeQname = macroTypeToQname(type);
				var paramIndex = moduleTypeQname.indexOf("<");
				if (paramIndex != -1) {
					moduleTypeQname = moduleTypeQname.substr(0, paramIndex);
				}
				return moduleTypeQname == qname;
			});
		} catch (e:Dynamic) {}
		if (resolvedType == null) {
			// next, try to determine if it's in a module, but not the main type
			var moduleName = qname;
			if (qname.indexOf(".") != -1) {
				var qnameParts = qname.split(".");
				qnameParts.pop();
				moduleName = qnameParts.join(".");
				try {
					resolvedType = Lambda.find(Context.getModule(moduleName), type -> {
						var moduleTypeQname = macroTypeToQname(type);
						var paramIndex = moduleTypeQname.indexOf("<");
						if (paramIndex != -1) {
							moduleTypeQname = moduleTypeQname.substr(0, paramIndex);
						}
						return moduleTypeQname == qname;
					});
				} catch (e:Dynamic) {}
			}
			if (resolvedType == null) {
				// final fallback to Context.getType()
				try {
					resolvedType = Context.getType(qname);
				} catch (e:Dynamic) {}
			}
		}
		return resolvedType;
	}
}

#elseif doc_gen
/**
	An MXHX resolver that uses the [Haxe Macro Context](https://haxe.org/manual/macro-context.html)
	to resolve symbols.
**/
class MXHXMacroResolver implements mxhx.resolver.IMXHXResolver {
	/**
		Registers the classes available in a particular MXHX namespace.
	**/
	public function registerManifest(uri:String, mappings:Map<String, mxhx.manifest.MXHXManifestEntry>):Void {}

	/**
		Resolves the symbol that a tag represents.
	**/
	public function resolveTag(tagData:mxhx.IMXHXTagData):mxhx.symbols.IMXHXSymbol {
		return null;
	}

	/**
		Resolves the symbol that an MXHX tag attribute represents.
	**/
	public function resolveAttribute(attributeData:mxhx.IMXHXTagAttributeData):mxhx.symbols.IMXHXSymbol {
		return null;
	}

	/**
		Resolves a field of a tag.
	**/
	public function resolveTagField(tag:IMXHXTagData, fieldName:String):mxhx.symbols.IMXHXFieldSymbol {
		return null;
	}

	/**
		Resolves a type from its fully-qualified name.
	**/
	public function resolveQname(qname:String):mxhx.symbols.IMXHXTypeSymbol {
		return null;
	}

	/**
		Gets the tag names registered for a fully-qualified name.
	**/
	public function getTagNamesForQname(qnameToFind:String):Map<String, String> {
		return null;
	}

	/**
		Gets the params registered for a fully-qualified name.
	**/
	public function getParamsForQname(qnameToFind:String):Array<String> {
		return null;
	}

	/**
		Gets all types.
	**/
	public function getTypes():Array<mxhx.symbols.IMXHXTypeSymbol> {
		return null;
	}
}
#end
