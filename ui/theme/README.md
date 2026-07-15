# UI Theme Foundation

Presentation profiles are visual-only resources synchronized by review against `design/05_ui_ux/ui_tokens_v2.json`. Profile A is the universal fallback and must render every screen and outcome. No profile may own commands, focus order, content state, or gameplay behavior.

`one_bit_post_process.gdshader` applies the design-mandated 50% threshold at a viewport boundary. It converts dynamic-font rasterization and framebuffer rounding back to exact black/white pixels; it does not authorize gray source assets, alpha gradients, or antialiased UI art.
