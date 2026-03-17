# Build UI with MCP

End-to-end workflow for building Unity UI features via MCP tools and debugging display issues.

## Phase 1: Prefab Structure Setup

### 1.1 Verify Canvas exists
// turbo
```
Use find_gameobjects(by_component, "Canvas") to find existing Canvas.
If none: create Canvas with CanvasScaler (Scale With Screen Size, 720x1600, match=0.5).
```

### 1.2 Create root UI panel UNDER Canvas
```
Use manage_gameobject(create) with parent="Canvas".
CRITICAL: Always create UI objects UNDER Canvas — never at root.
Objects created outside Canvas get wrong localScale (e.g., 160x instead of 1x).
```

### 1.3 Build child hierarchy
```
For each child element:
  manage_gameobject(create, parent=<parent_name>)
  manage_components(add, "Image"/"Button"/"TextMeshProUGUI"/etc.)
  manage_components(set_property) for RectTransform anchors, sizeDelta, anchoredPosition
```

### 1.4 Save as prefab
```
manage_prefabs(create_from_gameobject, target=<root>, prefab_path="Assets/.../MyPanel.prefab")
```

## Phase 2: ScrollView Setup

### 2.1 Create ScrollView structure
```
Required hierarchy:
  ScrollView (ScrollRect + RectTransform)
    └─ Viewport (RectTransform + Mask + Image)
        └─ Content (RectTransform + VerticalLayoutGroup + ContentSizeFitter)
```

### 2.2 Configure Viewport
```
CRITICAL CHECKS:
  ✅ Image component MUST have alpha > 0 (alpha=0 → Mask hides EVERYTHING)
  ✅ Mask component enabled
  ✅ RectTransform: stretch anchors (0,0)-(1,1), offsetMin/Max = 0
  ✅ Image color = white (1,1,1,1) — use "Show Mask Graphic = false" if you don't want to see it
```

### 2.3 Configure Content
```
  ✅ Anchor: top-stretch (anchorMin=0,1  anchorMax=1,1  pivot=0.5,1)
  ✅ ContentSizeFitter: verticalFit = PreferredSize
  ✅ VerticalLayoutGroup: childAlignment=UpperCenter, childForceExpandWidth=true
```

### 2.4 Wire ScrollRect
```
  manage_components(set_property, "ScrollRect", "content", <Content>)
  manage_components(set_property, "ScrollRect", "viewport", <Viewport>)
  manage_components(set_property, "ScrollRect", "horizontal", false)
```

## Phase 3: Row/Item Prefabs

### 3.1 Create prefab elements UNDER Canvas
```
ALWAYS create prefab source objects under an active Canvas.
Then save as prefab via manage_prefabs(create_from_gameobject).
Delete the temporary scene instance after saving.
```

### 3.2 Required components on row prefabs
```
Each row prefab needs:
  ✅ RectTransform.sizeDelta matching parent Content width (e.g., 720x130)
  ✅ LayoutElement (minWidth, preferredWidth, preferredHeight)
  ✅ Image for background (with visible color, NOT alpha=0)
  ✅ HorizontalLayoutGroup (if row has multiple columns)
```

### 3.3 Required components on item prefabs
```
Each item prefab needs:
  ✅ RectTransform.sizeDelta appropriate (e.g., 100x120)
  ✅ LayoutElement (minWidth, preferredWidth, preferredHeight)
  ✅ Image for background
```

## Phase 4: Script Wiring

### 4.1 Assign script to prefab
```
manage_prefabs(modify_contents, components_to_add=["MyScript"])
```

### 4.2 Wire SerializeField references
```
manage_prefabs(modify_contents, component_properties={
  "MyScript": {
    "_fieldName": {"path": "Assets/.../child.prefab"}  // or {"instanceID": ...}
  }
})
```

### 4.3 Serialized values vs code defaults
```
⚠️ WARNING: Serialized values in prefab OVERRIDE C# field defaults.
If you change a default in code (e.g., Color field from 0.15 to 0.95),
the prefab keeps the OLD value unless explicitly updated via modify_contents.

FIX: After code changes, always update prefab serialized values:
manage_prefabs(modify_contents, component_properties={
  "MyScript": {"_colorField": {"r":0.95, "g":0.95, "b":0.95, "a":1}}
})
```

## Phase 5: Runtime Instantiation

### 5.1 localScale reset after Instantiate
```csharp
// ALWAYS reset localScale after Instantiate under Canvas
var obj = Instantiate(prefab, parent);
obj.transform.localScale = Vector3.one;  // ← CRITICAL
```
Without this, prefabs get scale drift from Canvas/CanvasScaler.

### 5.2 Demo data
```
For features without API, hardcode demo data in a CreateDemoData() method.
For sprites not yet available, use procedural colored sprites created at runtime.
```

## Phase 6: Verification

### 6.1 Compile check
```
refresh_unity(compile="request", mode="force")
read_console(types=["error"])  → must be 0
```

### 6.2 Play Mode check
```
manage_editor(play)
find_gameobjects(by_component, "MyScript")  → verify instance count
read_console(types=["error"])  → must be 0
```

### 6.3 Visual check
```
manage_camera(screenshot, capture_source="scene_view", view_target=<root>, include_image=true)
```

### 6.4 Save
```
manage_scene(save)
```

---

## Debug Checklist: UI Not Displaying

When UI elements are invisible, check IN THIS ORDER:

### Layer 1: Canvas
```
□ Canvas exists and has CanvasScaler?
□ Canvas renderMode correct? (0=Overlay renders on top, 1=Camera needs camera ref)
□ Canvas.localScale — driven by CanvasScaler at runtime, tiny in Edit Mode is NORMAL
```

### Layer 2: Viewport / Mask
```
□ Viewport Image.color.alpha > 0?  ← MOST COMMON BUG (alpha=0 hides everything)
□ Mask component enabled?
□ Viewport RectTransform: stretch anchors, zero offsets?
```

### Layer 3: Content & Layout
```
□ Content anchored to top? (anchorMin=0,1  anchorMax=1,1  pivot=0.5,1)
□ ContentSizeFitter vertical = PreferredSize?
□ VerticalLayoutGroup childForceExpandWidth = true?
□ Content sizeDelta.y > 0 at runtime? (check with read_resource)
```

### Layer 4: Row/Item Elements
```
□ Items actually spawned? → find_gameobjects(by_component) count > 0?
□ localScale = (1,1,1)? (check lossyScale at runtime)
□ RectTransform.sizeDelta width matches parent? (e.g., 720, not 430)
□ Image components have alpha > 0?
□ Background color visible? (not black on black)
```

### Layer 5: Serialized Fields
```
□ Script SerializeField refs wired? (_bgImage, _iconImage not null)
□ Sprite refs assigned? (or fallback mechanism exists)
□ Color values match code defaults? (prefab serialized values override code)
```

### Layer 6: Prefab Origin
```
□ Prefab was created UNDER Canvas? (not at world root)
□ Children have correct RectTransform anchors/sizes?
□ LayoutElement components present with valid min/preferred values?
```

### Evidence-Gathering Commands
```
# Find instances
find_gameobjects(by_component, "MyComponent")

# Check RectTransform + components
read_resource(mcpforunity://scene/gameobject/{id}/components)

# Check runtime scale chain
# Compare localScale vs lossyScale at each parent level

# Check console
read_console(types=["error", "warning"])
```