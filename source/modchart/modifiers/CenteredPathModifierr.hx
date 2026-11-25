package modchart.modifiers;

import modchart.ModifierMacro.ModifierBool;
import modchart.ModifierMacro.ModifierValue;


class CenteredPathModifier extends Modifier {
    @:addColumn @:alias("movepath", "centered2") var centeredpath: ModifierValue = 0;
    @:addColumn var transformpath: ModifierValue = 0;

    var centeredpathtype: ModifierValue = 0;

}