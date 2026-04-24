# Image Interactions & Filters Design

## Overview
This document outlines the architecture and technical approach for bringing image layer interactions up to par with the existing text layers in Deen Studio. The primary goals are to allow precise image manipulation directly on the video preview canvas and to implement professional, hardware-accelerated image filters.

## 1. Smart Bounding Box (Canvas Interaction)
- **Constraint-Based Scaling**: Image layers will be integrated into the existing `_buildSmartBoundingBoxWrapper` in `video_preview.dart`.
- **Proportional Scaling Mode**: A new constraint mode will be added to the bounding box. When `isProportionalOnly` is enabled (for images), the side handles (width/height stretchers) will be hidden or disabled. Only the 4 corner handles will remain, ensuring the aspect ratio is strictly maintained during scaling gestures.
- **Drag & Drop**: Native drag-to-move functionality will be automatically inherited from the wrapper.

## 2. Toolbar & Inspector Integration
- **Contextual Menu**: When an image layer is selected, the `EditorToolbar` will display an image-specific toolset.
- **Tools**:
  - **Replace**: Opens the Pixabay/Gallery picker to swap the image content while maintaining the layer's ID, position, and scale.
  - **Filters**: Opens a bottom sheet with predefined visual filters.
  - **Adjustments**: Opens sliders for Brightness, Contrast, Saturation, and Opacity.
  - **Delete/Duplicate**: Standard layer management tools.

## 3. Filter Rendering Engine
- **Technology Choice**: Native Flutter `ColorFiltered` with `ColorMatrix`. This guarantees 60 FPS performance, has zero external dependencies, and integrates well with FFmpeg exports (which can replicate standard color matrices natively).
- **Matrix Composition**: 
  - A matrix generator will combine predefined filter LUTs (e.g., Sepia, Vintage, Black & White) with user-defined adjustments (brightness, contrast, saturation).
  - The final calculated matrix will be applied to the `Image.file` widget using a `ColorFiltered` parent.

## 4. Data Model Strategy
- The current `Layer` model already contains `filterId` and `colorGrading`.
- **Basic Adjustments**: `style['brightness']`, `style['contrast']`, `style['saturation']`, and `style['opacity']` will be used for granular control.
- **Preset Filters**: `style['filterId']` (or the existing `layer.filterId`) will map to constant matrices defined in the rendering engine.
- This data structure ensures complete compatibility with project persistence and future video exports.
