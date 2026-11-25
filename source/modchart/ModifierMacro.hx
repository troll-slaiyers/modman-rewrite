package modchart;

// is based on some code by srt
// TODO: Cleanup ,most of this code was ritten on an all nighter LOL

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Expr.Field;
using StringTools;

typedef ModifierValue = Float;
typedef ModifierSubValue = Float;
typedef ModifierBool = Bool;
typedef ModifierSubBool = Bool;

final class ModifierMacro {
    public static macro function build():Array<Field> 
    {
		final fields = Context.getBuildFields();
		final pos = Context.currentPos();
        final localClass = Context.getLocalClass().get();
        final name = localClass.name;
        final meta = localClass.meta == null ? [] : localClass.meta.get();
        
        var activeValues: Array<String> = [];
        var prefix: String = '';

        var allModifierFields: Array<Field> = [];
        var isBaseModifier: Bool = false;

        if(localClass.meta.get() != null){
            for(meta in localClass.meta.get()){
                if(meta.name == ":base") // means this modifier doesnt do anything on its own and exists for other modifiers to extend
                    isBaseModifier = true;
            }
        }

        if(!isBaseModifier){
            fields.push({
                name: "__init__",
                access: [AStatic],
                kind: FFun({
                    args: [],
                    expr: macro {
                        if(ModManager.modifiersToAdd == null)ModManager.modifiersToAdd = []; // usually isnt created by this point #lol
                        ModManager.modifiersToAdd.push($i{name});
                    }
                }),
                pos: pos
            });
        }else 
            return fields;
        

        for (field in fields)
        {
            switch(field.kind)
            {
                case FVar(TPath(p), _):
                    if(p.name == "ModifierValue" || p.name == "ModifierBool"){
                        activeValues.push(field.name);
                        allModifierFields.push(field);
                    }else if(p.name == "ModifierSubValue" || p.name == "ModifierSubBool")
                        allModifierFields.push(field);
                default:
                    // have no need to do anything else here
            }
        }
        

        if(allModifierFields.length == 0)return fields;

        var aliasResolve: Map<String, String> = [];
        var columnAliasResolve: Map<String, String> = [];

        var defaults: Map<String, Float> = [];
        var columnDefaults: Map<String, Float> = [];

        for(field in allModifierFields)
        {
            var modName: String = field.name.toLowerCase();
            var columnName: String;

            var defaultValue: Float = 0;
            var isColumn: Bool = false;
            var isAdditiveColumn: Bool = false;

            if(field.meta != null)
            {
                var aliases: Array<String> = [];

                for(meta in field.meta){
                    if(meta.name == ":alias" || meta.name == ":aliases"){
                        for(param in meta.params){
                            switch (param.expr) {
                                case EConst(CIdent(s) | CString(s)):
                                    aliases.push(s);
                                default:
                            }
                        }
                    }else if(meta.name == ":columnModifier"){
                        isColumn = true;
                        if(isAdditiveColumn){
                            Context.error(":addColumn and :columnModifier are mutually exclusive!", pos);
                            return fields;
                        }
                        if(meta.params.length > 0){
                            switch (meta.params[0].expr) {
                                case EConst(CIdent(s) | CString(s)):
                                    modName = s;
                                default:
                            }
                        }else
                            modName = modName.replace("column", "%c"); // for making it easier 

                        if(!modName.contains("%c"))
                            modName = modName + "%c";
                    }else if(meta.name == ":addColumn"){
                        isAdditiveColumn = true;
                        if(isColumn){
                            Context.error(":addColumn and :columnModifier are mutually exclusive!", pos);
                            return fields;
                        }
                        if(meta.params.length > 0){
                            switch (meta.params[0].expr) {
                                case EConst(CIdent(s) | CString(s)):
                                    columnName = s;
                                default:
                            }
                        }else{
                            columnName = modName.replace("column", "%c"); // for making it easier 
                            modName = modName.replace("column", "");
                        }

                        if(!columnName.contains("%c"))
                            columnName = columnName + "%c";

                    }else if(meta.name == "modName"){
                        if(isColumn){
                            Context.error(":modName is not for column modifiers! Use the first argument of @:columnModifier to set the name!", pos);
                        }else if(meta.params.length > 0){
                            switch (meta.params[0].expr) {
                                case EConst(CString(s)):
                                    modName = s;
                                default:
                            }
                        }else 
                            Context.error(":modName expects 1 argument of String", pos);
                    }
                }
                    

                if(!isColumn){
                    for(a in aliases){
                        if(isAdditiveColumn && a.contains("%c"))
                             columnAliasResolve.set(a.toLowerCase(), modName);
                        else
                            aliasResolve.set(a.toLowerCase(), modName);
                    }
                }else{
                    for(a in aliases){
                        if(!a.contains("%c"))
                            a = a + "%c";
                        columnAliasResolve.set(a.toLowerCase(), modName);
                    }
                }
            }

            switch(field.kind){
                case FVar(_, {expr: EConst(CInt(f, s) | CFloat(f, s))}): // modifier values
                    defaultValue = Std.parseFloat(f);
                case FVar(_, {expr: EConst(CIdent("true"))}): // modifier bools
                    defaultValue = 1;
                default:
                    defaultValue = 0;
            }

            if(!isColumn){
                aliasResolve.set(modName, modName);
                defaults.set(modName, defaultValue);
            }else{
                columnName = modName;
            }

            if(isAdditiveColumn || isColumn){
                columnAliasResolve.set(columnName, columnName);
                columnDefaults.set(columnName, defaultValue);
            }


            var soloTarget: Expr = macro $v{modName};
            var columnTarget: Expr = macro StringTools.replace($v{columnName}, "%c", Std.string(parent.workingColumn));

            var target: Expr = isColumn ? columnTarget : soloTarget;

            switch(field.kind){
                case FVar(TPath(p), _):
                    if(p.name == "ModifierValue" || p.name == "ModifierSubValue"){
                        field.kind = FProp("get", "never", (macro:Float));
                        fields.push({
                            name: "get_" + field.name,
                            access: [AInline, APrivate],
                            kind: FFun({
                                args: [],
                                expr: isAdditiveColumn ? macro {
                                    return getValue(${soloTarget}, parent.workingPlayer) + getValue(${columnTarget}, parent.workingPlayer);
                                } : macro {
                                    return getValue(${target}, parent.workingPlayer);
                                }
                            }),
                            pos: pos
                        });
                    } else if(p.name == "ModifierBool" || p.name == "ModifierSubBool"){
                        field.kind = FProp("get", "never", (macro:Bool));
                        fields.push({
                            name: "get_" + field.name,
                            access: [AInline, APrivate],
                            kind: FFun({
                                args: [],
                                expr: isAdditiveColumn ? macro {
                                    return getValue(${soloTarget}, parent.workingPlayer) + getValue(${columnTarget}, parent.workingPlayer) > 0 ? true : false;
                                } : macro {
                                    return getValue(${target}, parent.workingPlayer) > 0 ? true : false;
                                }
                            }),
                            pos: pos
                        });
                    }
                default:
            }
        }

        var valueInfo: Array<Expr> = [];
        for(alias => mod in aliasResolve)
            valueInfo.push(macro $v{alias} => $v{mod});


        if(allModifierFields.length != activeValues.length){
            fields.push({
                name: "isActive",
                access: [AOverride, APublic],
                kind: FFun({
                    args: [{
                        name: "values",
                        type: macro: Map<String, Float>
                    }],
                    expr: macro {
                        for(val in $v{activeValues}){
                            if(values.get(val) != 0.0) // TODO: change to check the default value
                                return true;
                        }
                        return false;
                    }
                }),
                pos: pos
            });
        }

        fields.push({
            name: "getValueInfo",
            access: [AOverride, APublic],
            kind: FFun({
                args: [],
                expr: macro {
                    var newValues: Map<String, String> = [];

                    for(k => v in $v{aliasResolve})
                        newValues.set(k, v);
                    
                    
                    var temp: Map<String, String> = $v{columnAliasResolve};
                    for(k => v in temp){
                        for(i in 0...4){
                            var stringified: String = Std.string(i);

                            newValues.set(StringTools.replace(k, "%c", stringified), StringTools.replace(v, "%c", stringified));
                        }
                    }
                    return newValues;
                }
            }),
            pos: pos
        });

        fields.push({
            name: "addNewValues",
            access: [AOverride, APublic],
            kind: FFun({
                args: [],
                expr: macro {
                    var newValues: Map<String, Float> = [];
                    for(k => v in $v{defaults}){
                        newValues.set(k, v);
                    }
                    
                    var temp: Map<String, Float> = $v{columnDefaults};
                    for(k => v in temp){
                        for(i in 0...4){
                            newValues.set(StringTools.replace(k, "%c", Std.string(i)), v);
                        }
                    }
                    
                    values.push(newValues);
                    finalizedValues.push(newValues.copy());
                    keyArray.push([for(k in newValues.keys())k]);


                    active.push(false);
                    finalizedActive.push(false);
                }
            }),
            pos: pos
        });
        

        
        return fields;
    }
}

#else
typedef ModifierValue = Float;
typedef ModifierSubValue = Float;
typedef ModifierBool = Bool;
typedef ModifierSubBool = Bool;
#end