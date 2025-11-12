# Refactorización: Separación de Recursos de Organización

## Resumen

Se ha reorganizado el código del módulo para mejorar la mantenibilidad y claridad, moviendo recursos específicos de organización desde `main.tf` a un nuevo archivo `organization.tf`.

> **⚠️ Nota Importante:** `organization.tf` contiene SOLO recursos que requieren `var.mode == "organization"`.
> Los recursos que funcionan en ambos modos (como `organization_ruleset` y `runner_groups`) permanecen en `main.tf`.

## Motivación

El archivo `main.tf` contenía tanto recursos organizacionales como lógica general del módulo, lo cual dificultaba:
- Localizar recursos específicos de organización
- Entender qué recursos solo aplican en modo organización
- Mantener y actualizar recursos organizacionales

## Cambios Realizados

### Archivo Nuevo: `organization.tf`

Creado un nuevo archivo dedicado exclusivamente a recursos que SOLO funcionan en modo organización (11KB, 8 recursos):

**Recursos Movidos:**

1. **Organization Settings**
   - `github_organization_settings` - Configuración general de la organización

2. **Organization Repository Roles**
   - `github_organization_custom_role` - Roles personalizados para repositorios

4. **Organization Webhooks**
   - `github_organization_webhook` - Webhooks a nivel organización

5. **Organization Security**
   - `github_organization_security_manager` - Gestores de seguridad

6. **Organization Custom Properties**
   - `github_organization_custom_properties` - Propiedades personalizadas (Enterprise Cloud)

7. **Organization Roles (Org-wide)**
   - `github_organization_role` - Roles personalizados a nivel organización
   - `github_organization_role_user` - Asignación de roles a usuarios
   - `github_organization_role_team` - Asignación de roles a equipos

**Locals Movidos:**
- `organization_role_ids` - Mapeo de nombres de roles a IDs
- `organization_role_user_assignments` - Asignaciones de usuarios aplanadas
- `organization_role_team_assignments` - Asignaciones de equipos aplanadas

### Archivo Actualizado: `main.tf`

Limpiado y simplificado (23KB, 7 recursos):

**Contenido Actual:**
- Locals (merge logic, repository configuration)
- Data sources (`github_repositories`, `github_organization`)
- Validation checks (plan validation, feature validation)
- Organization-wide variables y secrets (funcionan en ambos modos)
- Runner groups (funcionan en ambos modos)
- **Organization rulesets** (funcionan en ambos modos) ⚠️ DUAL-MODE

**Recursos en main.tf (Dual-Mode):**
1. `github_actions_organization_variable` - Variables de Actions
2. `github_actions_organization_secret` - Secretos de Actions (plaintext y encrypted)
3. `github_dependabot_organization_secret` - Secretos de Dependabot (plaintext y encrypted)
4. `github_actions_runner_group` - Grupos de runners
5. `github_organization_ruleset` - Rulesets (usa var.spec en project mode)

> **Nota Importante:** `github_organization_ruleset` NO está limitado a modo organización. En project mode usa `var.spec` para evitar colisiones de nombres y aplica solo a repos del módulo. Por eso permanece en `main.tf`.

### Archivo Sin Cambios: `repository.tf`

Se mantiene intacto (34KB, 27 recursos) - Contiene todos los recursos a nivel de repositorio.

## Estructura Resultante

```
📁 terraform-github-governance/
├── main.tf                    # 23KB - Core logic + dual-mode resources
│   ├── Locals (merge logic)
│   ├── Data sources
│   ├── Validation checks
│   ├── Variables & secrets (dual-mode)
│   ├── Runner groups (dual-mode)
│   └── Organization rulesets (dual-mode) ⚠️
│
├── organization.tf            # 11KB - Organization-exclusive resources (NEW)
│   ├── organization_settings
│   ├── organization_custom_role (repository roles)
│   ├── organization_webhook
│   ├── organization_security_manager
│   ├── organization_custom_properties
│   ├── organization_role (org-wide roles)
│   ├── organization_role_user
│   ├── organization_role_team
│   └── Locals for role management
│
├── repository.tf              # 34KB - Repository resources
│   └── All repository-level resources (27)
│
├── variables.tf               # 39KB - All inputs
├── outputs.tf                 # 7.9KB - All outputs
└── versions.tf                # 386B - Provider constraints
```

## Beneficios

### 1. **Separación Clara de Responsabilidades**
- **`organization.tf`**: SOLO recursos que requieren `var.mode == "organization"` (exclusivos)
- **`main.tf`**: Lógica central + recursos dual-mode (funcionan en ambos modos)
- **`repository.tf`**: Solo recursos a nivel de repositorio

### 2. **Mejor Mantenibilidad**
- Fácil localizar recursos organizacionales
- Cambios a features de organización en un solo archivo
- Documentación en contexto del tipo de recurso

### 3. **Comprensión Mejorada**
- Estructura de archivos refleja la arquitectura de GitHub
- Developers pueden entender rápidamente qué recursos hay disponibles
- Nuevos colaboradores pueden navegar el código más fácilmente

### 4. **Menos Conflictos en PRs**
- Cambios organizacionales no afectan `main.tf`
- Cambios en repositorios no afectan `organization.tf`
- Reducción de merge conflicts

### 5. **Onboarding Simplificado**
```hcl
# ¿Recurso que SOLO funciona en modo organización?
# → organization.tf (requiere var.mode == "organization")

# ¿Recurso que funciona en AMBOS modos?
# → main.tf (dual-mode: organization + project)

# ¿Recurso a nivel de repositorio?
# → repository.tf

# ¿Lógica de merge o validación?
# → main.tf
```

## Validación

### Tests Ejecutados

```bash
# ✅ Formato correcto
$ terraform fmt -recursive

# ✅ Validación exitosa
$ terraform validate
Success! The configuration is valid.

# ⚠️ Advertencia esperada (no es error)
Warning: Deprecated Resource
  with github_organization_custom_role.this,
  on organization.tf line 196
  (Nota: Esperamos migrar a github_organization_repository_role)
```

### Conteo de Recursos

| Archivo | Tamaño | Recursos | Tipo |
|---------|--------|----------|------|
| `main.tf` | 23KB | 7 | Core + dual-mode |
| `organization.tf` | 11KB | 8 | Organization-exclusive |
| `repository.tf` | 34KB | 27 | Repository-only |
| **Total** | **68KB** | **42** | - |

## Compatibilidad Hacia Atrás

✅ **100% Compatible** - No hay cambios funcionales:
- Mismos recursos
- Mismas variables
- Mismos outputs
- Mismo comportamiento
- Mismo state

Esta es una **refactorización puramente organizacional** - el state de Terraform no se ve afectado.

## Próximos Pasos

### Mejoras Futuras Sugeridas

1. **Migración de Repository Roles**
   ```hcl
   # Migrar de (deprecated):
   resource "github_organization_custom_role"

   # A (nuevo):
   resource "github_organization_repository_role"
   ```

2. **Documentación por Archivo**
   - Agregar header comments explicando el propósito de cada archivo
   - Documentar dependencias entre archivos

3. **Separar Secrets y Variables**
   - Considerar `secrets.tf` para todos los recursos de secrets
   - Mejor control de acceso y auditoría

4. **Tests por Tipo**
   - Tests específicos para recursos organizacionales
   - Tests específicos para recursos de repositorio
   - Validación de modo (organization vs project)

## Recursos Adicionales

- **Documentación Actualizada**: `README.md` ahora incluye sección "File Structure"
- **Guía de Organization Roles**: `docs/ORGANIZATION_ROLES.md`
- **Ejemplos Actualizados**: `examples/complete/main.tf` con todos los features

## Autores

- **Refactorización**: Victor
- **Fecha**: Noviembre 2024
- **Versión del Módulo**: 2.0.0

---

**Nota**: Esta refactorización fue parte de la implementación de Organization Roles (v2.0.0) y mejora la estructura del módulo para futuras features organizacionales.
