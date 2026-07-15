# Coding Standards

## 1. Language

Use typed GDScript for gameplay and tools unless a measured performance bottleneck justifies C# or GDExtension. Do not mix languages casually.

## 2. Naming

- files/classes: `PascalCase.gd`, `PascalCase.tscn`;
- variables/functions/signals: `snake_case`;
- constants: `UPPER_SNAKE_CASE`;
- private members: leading `_` only where it improves clarity;
- stable content IDs: lowercase dotted strings;
- booleans begin with `is_`, `has_`, `can_`, or `should_`.

## 3. Types and nullability

- annotate public APIs and collections;
- avoid untyped nested Dictionaries at system boundaries; parse into typed objects;
- validate external JSON before construction;
- use `StringName` for stable IDs in runtime hot paths;
- avoid implicit nullable state; express optional values deliberately.

## 4. Node discipline

- composition over deep inheritance;
- no `get_node("../../..")` chains;
- cache required child references via unique names or exports;
- scenes expose configuration methods rather than reading global state in `_ready`;
- free signal connections with owner lifecycle or use scoped connections;
- do not make one script own input, animation, state, and persistence.

## 5. Signals

Signals describe completed facts: `mode_completed`, `choice_committed`, `save_failed`. Commands are method calls or command objects. Avoid signals named like imperative requests when a direct dependency is clearer.

## 6. Error handling

- `assert` for developer invariants in debug;
- typed result objects for expected failures;
- errors include stable code, content ID, and context;
- never catch and discard parse/save errors;
- release UI never exposes local file paths.

## 7. Comments and documentation

Comments explain why a constraint exists, not what obvious code does. Public systems have a short contract header and an example fixture. Complex combat math cites its design document section.

## 8. Git hygiene

- one logical change per commit;
- data and generated output separated;
- generated indexes committed only if reproducibility requires it;
- no binary source art in code-review-only repositories without LFS policy;
- no secrets, API keys, personal paths, or downloaded reference assets;
- formatter/linter and validators run before PR.

## 9. Content safety

- no runtime network text generation;
- no unreviewed generated dialogue;
- no official ripped assets in test fixtures;
- placeholder IDs fail release build;
- fanon intensity and comfort tags are reviewable fields.
