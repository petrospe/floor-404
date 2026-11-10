## Visual Orientation and Mirroring Rules (MANDATORY)

### 1. No Mirrored Text or Images

All text, signs, symbols, logos, decals and directional graphics MUST appear correctly oriented and readable from the player's intended viewing position.

This includes:
- EXIT signs and emergency signage.
- Room numbers and labels.
- Electrical panel labels and instructions.
- Elevator buttons and floor indicators.
- Posters, paintings, logos and decorative images.
- Directional arrows and safety symbols.

**Never deliver mirrored, reversed, upside-down or unintentionally rotated visual content.**

### 2. Blender Object Transform Rules

- Do not use negative object scaling to mirror objects containing text, symbols, decals or directional textures.
- Prefer proper object rotation instead of negative scaling.
- Apply transforms appropriately before exporting assets to Godot.
- Check face normals and UV orientation after any mirroring operation.
- If geometry must be mirrored, ensure all text and graphics retain their correct reading direction.
- Do not change the orientation of existing working assets without an explicit reason.

### 3. Godot Scene Rules

- Avoid negative scale values on `Node3D`, `MeshInstance3D` or parent nodes containing text or directional graphics.
- Check inherited transforms from parent nodes.
- Ensure `Label3D`, `Sprite3D`, `Decal` and textured meshes face the player's intended viewing direction.
- Do not assume that a sign is correctly oriented simply because it is visible in the editor.
- Do not globally flip textures or UV coordinates to fix one incorrectly oriented object.

### 4. Mandatory Visual Verification

Before marking a visual task as completed, the agent MUST:

1. Inspect the object from the player's intended viewing position.
2. Verify that all letters are readable from left to right.
3. Verify that images, arrows and symbols have the intended orientation.
4. Verify that no parent transform causes accidental mirroring.
5. Check the object in the running Godot scene whenever possible.
6. Correct any reversed text or graphics before completing the task.

For directional signs, verify that the arrow points toward the actual intended destination.

### 5. Existing Asset Protection

- Preserve the orientation of all correctly functioning existing assets.
- Never mirror an entire room, corridor or scene without checking every sign, decal and directional texture inside it.
- When reusing modular assets in different orientations, rotate the geometry normally and verify the resulting text and graphics.
- If an asset requires mirrored geometry, separate the text and signage into independent child objects with correctly oriented transforms.

### 6. Acceptance Criteria

A visual task is NOT considered complete if:
- Any text appears mirrored or upside down.
- Any directional symbol points the wrong way.
- Any image is unintentionally flipped.
- Any signage is readable only from the wrong side.
- The agent has not verified orientation from the player's intended viewpoint.

If visual verification cannot be performed, the agent MUST explicitly report that the orientation remains unverified rather than claiming the task is complete.
