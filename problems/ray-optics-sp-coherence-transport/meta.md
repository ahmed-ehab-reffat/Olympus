---
Repository: https://github.com/ricktu288/ray-optics
Issue: N/A
Commit: e55947ecf4cc86724085ec07b774f85e4b7dea46
Language: JavaScript
Category: feature-request
Title: Add polarization coherence transport to the primitive engine
---
# Add polarization coherence transport to the primitive engine

Add a coherence term between the s and p field components to the primitive ray contract and carry it through the CPU engine. Today a ray only has the two incoherent powers P_s and P_p, so a polarizer at an arbitrary angle cannot be written as a surface formula: two crossed diagonal polarizers still pass a quarter of the light.

Each ray also carries C = E_s times the complex conjugate of E_p, as a real and an imaginary part. The s direction points out of the simulation plane and the p direction is the ray direction turned by +90 degrees, (-d_y, d_x), which is the same basis in world coordinates and in the local surface frame. A source type may label the outputs `C_r` and `C_i`; a source that labels neither emits C = 0. Surface and detector formulas read the incoming value through the reserved inputs `C_0r` and `C_0i`, which cannot be declared as parameters, and a surface slot j may label `C_jr` and `C_ji` to set its outgoing value. A type that labels only one component of a pair is rejected with a TypeError during preprocessing. When a source or a labeled slot gives a C with |C|^2 above P_s P_p, it is scaled down to that bound keeping its phase, and a non-finite C makes the ray invalid or the slot inactive, the same as a non-finite power.

Every ray the engine produces carries C. A slot that labels no C gets the incoming C times sqrt(P_js P_jp / (P_0s P_0p)), negated when the outgoing ray stays on the incident side of the curve (as a mirror does), and 0 when either product is 0. A region boundary multiplies the transmitted C by sqrt(T_s T_p), and leaves it unchanged when the region does not partially reflect. The reflected C is multiplied by r_s r_p, the product of the Fresnel amplitude reflection coefficients in this basis; at normal incidence that product is -R, the same sign an ideal mirror gives. Total internal reflection uses the same two coefficients with cos(theta_t) replaced by -i sqrt(m^2 sin^2(theta_i) - 1), where m is the incident index divided by the transmitted index. A GRIN step scales C by the same absorption factor as the powers, and a detector passes it on unchanged. Whenever the engine rescales a ray's powers outside an optical interaction, C is rescaled by the same factor, so a ray's polarization state only changes where it interacts.

The WebGPU engine does not support coherence: its `prepare` rejects any scene with a source, surface or detector type that labels or reads C, so the existing CPU fallback runs such scenes.
