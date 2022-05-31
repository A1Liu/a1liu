export class ImageLoader {
    static cache = new Map<string, HTMLImageElement>()

    static load(assetPath: string) {
        if (!ImageLoader.cache.has(assetPath)) {
            const image = new Image()
            image.src = assetPath
            ImageLoader.cache.set(assetPath, image)
        }
        return ImageLoader.cache.get(assetPath)!
    }
}
