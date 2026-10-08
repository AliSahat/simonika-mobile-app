# Google sign-in logo

`google_g.png` is the official 200 × 204 transparent Google G asset downloaded
from https://developers.google.com/static/identity/images/g-logo.png.

Usage guidance: https://developers.google.com/identity/branding-guidelines.
The button preserves its aspect ratio and colors, uses a white backing, and
renders it at 20 logical pixels. The bundled image needs no runtime download.

The current official SVG bundle uses `foreignObject`, conic gradients and SVG
filters that Flutter's SVG renderer does not support. The official high-resolution
PNG is used to preserve the supplied logo faithfully without a rendering package.
