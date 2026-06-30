# /assets/icons — intentionally empty

The Flutter doctor app does NOT bundle any custom icon files. Every icon
is a Material Icon referenced inline (`Icons.<name>`), rendered from
Flutter's built-in MaterialIcons font.

## For the web rebuild

Pick **one** of these icon delivery mechanisms — do not bundle SVGs here:

1. **Material Symbols Rounded** webfont (recommended for visual parity):

   ```html
   <link
     rel="stylesheet"
     href="https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@24,400,0,0&display=swap"
   />
   ```

   Usage: `<span class="material-symbols-rounded">favorite</span>`.

2. **`@mui/icons-material`** (best DX with React):

   ```bash
   npm i @mui/icons-material @mui/material @emotion/react @emotion/styled
   ```

   Usage: `import Favorite from '@mui/icons-material/Favorite';`.

3. **`lucide-react`** (smaller bundle, but visuals differ slightly from
   Material).

See `web-rebuild-context/DESIGN_SYSTEM.md` §6 for the complete list of
icons used by every doctor screen.
