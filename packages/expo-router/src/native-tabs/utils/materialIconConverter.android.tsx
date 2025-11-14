import { loadAsync, renderToImageAsync } from 'expo-font';
import { androidSymbolToString, materialRegularWeight } from 'expo-symbols/internal';
import { type ImageSourcePropType } from 'react-native';

import { convertComponentSrcToImageSource } from './icon';
import { NativeTabsTriggerPromiseIcon, type MaterialIcon } from '../common/elements';

export function convertMaterialIconNameToImageSource(
  name: MaterialIcon['md']
): ReturnType<typeof convertComponentSrcToImageSource> {
  return convertComponentSrcToImageSource(
    <NativeTabsTriggerPromiseIcon loader={() => loadAsyncMaterialIcon(name)} />
  );
}

async function loadAsyncMaterialIcon(
  name: MaterialIcon['md']
): Promise<ImageSourcePropType | null> {
  const symbol = androidSymbolToString(name);
  if (!symbol) {
    return null;
  }
  await loadAsync({ [materialRegularWeight.name]: materialRegularWeight.font });
  const renderToImageResult = await renderToImageAsync(symbol, {
    fontFamily: materialRegularWeight.name,
    size: 48,
    color: 'white',
  });
  return renderToImageResult;
}
