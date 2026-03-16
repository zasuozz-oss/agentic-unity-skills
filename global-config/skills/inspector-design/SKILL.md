---
name: inspector-design
description: "Unity Inspector design advisor. Use this when the user wants better SerializeField usage, Tooltip/Header organization, validation, CreateAssetMenu, RequireComponent, or cleaner authoring UX."
---

# Inspector Design

> Adapted from [Besty0728/Unity-Skills](https://github.com/Besty0728/Unity-Skills) (MIT License)

Use this skill when scripts need to be easier to author, configure, and review in the Inspector.

## Default Rules

- Prefer `private` fields with `[SerializeField]` over unnecessary public fields
- Use `[Header]`, `[Tooltip]`, `[Space]`, `[Range]`, `[Min]`, `[TextArea]` when they clarify intent
- Use `[RequireComponent]` for mandatory sibling dependencies
- Use `[CreateAssetMenu]` for config/data assets designers should create directly
- Use `OnValidate` only for lightweight editor-time validation
- Use `SerializeReference` only when polymorphic serialized data is genuinely needed

## Inspector Quality Checklist

- [ ] Are defaults safe?
- [ ] Are required references obvious?
- [ ] Are fields grouped by responsibility?
- [ ] Are tuning values constrained?
- [ ] Are debug-only fields separated from authoring fields?
- [ ] Will another person understand this script from Inspector alone?

## Output Format

- Field exposure strategy
- Recommended attributes
- Validation rules
- Authoring UX improvements
- Over-design to avoid

## Related Skills
- `@script-design-review` - Full script quality review
- `@custom-editor-scripting` - Custom inspectors and property drawers
