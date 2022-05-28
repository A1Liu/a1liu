import { Size } from "./sprite";

export function projectSize(initialSize: Size, screen: Size): Size {
  if (screen.width > screen.height) {
    return projectSizeByHeight(initialSize, screen.height);
  }
  return projectSizeByWidth(initialSize, screen.width);
}

export function projectSizeByWidth(size: Size, targetWidth: number): Size {
  return {
    width: targetWidth,
    height: targetWidth / (size.width / size.height),
  };
}

export function projectSizeByHeight(size: Size, targetHeight: number): Size {
  return {
    width: targetHeight * (size.width / size.height),
    height: targetHeight,
  };
}
