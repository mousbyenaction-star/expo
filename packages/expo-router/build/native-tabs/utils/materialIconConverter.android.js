"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.convertMaterialIconNameToImageSource = convertMaterialIconNameToImageSource;
const expo_font_1 = require("expo-font");
const internal_1 = require("expo-symbols/internal");
const icon_1 = require("./icon");
const elements_1 = require("../common/elements");
function convertMaterialIconNameToImageSource(name) {
    return (0, icon_1.convertComponentSrcToImageSource)(<elements_1.NativeTabsTriggerPromiseIcon loader={() => loadAsyncMaterialIcon(name)}/>);
}
async function loadAsyncMaterialIcon(name) {
    const symbol = (0, internal_1.androidSymbolToString)(name);
    if (!symbol) {
        return null;
    }
    await (0, expo_font_1.loadAsync)({ [internal_1.materialRegularWeight.name]: internal_1.materialRegularWeight.font });
    const renderToImageResult = await (0, expo_font_1.renderToImageAsync)(symbol, {
        fontFamily: internal_1.materialRegularWeight.name,
        size: 48,
        color: 'white',
    });
    return renderToImageResult;
}
//# sourceMappingURL=materialIconConverter.android.js.map