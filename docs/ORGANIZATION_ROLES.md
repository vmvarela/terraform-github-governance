# Organization Roles - Guía de Uso

## Descripción General

Los **Organization Roles** (roles de organización) permiten crear roles personalizados a nivel de organización con permisos específicos que se aplican a toda la organización de GitHub, no solo a repositorios individuales.

**Requisitos:**
- GitHub Enterprise Cloud
- Permisos de administrador de organización
- Terraform GitHub Provider >= 6.0

## Recursos Implementados

### 1. `github_organization_role`
Crea roles personalizados a nivel de organización con permisos específicos.

### 2. `github_organization_role_user`
Asigna roles de organización a usuarios individuales.

### 3. `github_organization_role_team`
Asigna roles de organización a equipos completos.

## Diferencias con Repository Roles

| Aspecto | Repository Roles | Organization Roles |
|---------|------------------|-------------------|
| **Alcance** | Por repositorio | Toda la organización |
| **Permisos** | Repositorio específico | Org-wide (facturación, auditoría, etc.) |
| **Recurso** | `github_organization_custom_role` | `github_organization_role` |
| **Plan requerido** | Enterprise | Enterprise Cloud |
| **Ejemplo de uso** | "code-reviewer" con permisos de PR | "billing-admin" con acceso a facturación |

## Configuración

### Variables

#### `organization_roles`
Mapa de roles personalizados a crear:

```hcl
variable "organization_roles" {
  description = "Custom organization-wide roles with fine-grained permissions"
  type = map(object({
    description = optional(string)
    base_role   = optional(string) # read, triage, write, maintain, admin
    permissions = list(string)     # Minimum 1 permission required
  }))
  default = {}
}
```

#### `organization_role_assignments`
Asignaciones de roles a usuarios y equipos:

```hcl
variable "organization_role_assignments" {
  description = "Assign organization roles to users and teams"
  type = object({
    users = optional(map(list(string)), {}) # role_name => ["user1", "user2"]
    teams = optional(map(list(string)), {}) # role_name => ["team1", "team2"]
  })
  default = {
    users = {}
    teams = {}
  }
}
```

### Ejemplo Básico

```hcl
module "github" {
  source = "../../"
  mode   = "organization"
  organization = "my-org"

  # Definir roles personalizados
  organization_roles = {
    "security-admin" = {
      description = "Security administrators with audit access"
      base_role   = "read"
      permissions = [
        "read_audit_logs",
        "manage_organization_security"
      ]
    }

    "billing-viewer" = {
      description = "View billing and usage data"
      base_role   = "read"
      permissions = ["read_organization_billing"]
    }

    "content-moderator" = {
      description = "Manage discussions and content across the organization"
      permissions = [
        "moderate_organization_discussions",
        "manage_organization_content"
      ]
    }
  }

  # Asignar roles
  organization_role_assignments = {
    users = {
      "security-admin"    = ["alice", "bob"]
      "billing-viewer"    = ["charlie"]
      "content-moderator" = ["diana"]
    }

    teams = {
      "security-admin"    = ["security-team"]
      "billing-viewer"    = ["finance-team"]
      "content-moderator" = ["community-team"]
    }
  }
}
```

## Permisos Disponibles

### Permisos de Auditoría y Seguridad
- `read_audit_logs` - Ver logs de auditoría de la organización
- `manage_organization_security` - Gestionar configuración de seguridad
- `read_organization_security` - Ver configuración de seguridad

### Permisos de Facturación
- `read_organization_billing` - Ver datos de facturación y uso
- `manage_organization_billing` - Gestionar suscripciones y pagos

### Permisos de Contenido
- `moderate_organization_discussions` - Moderar discusiones
- `manage_organization_content` - Gestionar contenido de la organización

### Permisos de Gestión
- `manage_organization_settings` - Gestionar configuración general
- `manage_organization_members` - Gestionar miembros
- `manage_organization_teams` - Gestionar equipos

> **Nota:** La lista completa de permisos disponibles puede variar según tu plan de GitHub Enterprise Cloud. Consulta la [documentación oficial de GitHub](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-peoples-access-to-your-organization-with-roles/about-custom-organization-roles) para más detalles.

## Roles Predefinidos de GitHub

Además de roles personalizados, puedes asignar roles predefinidos usando sus IDs:

| Role ID | Nombre | Descripción |
|---------|--------|-------------|
| `8132` | Outside Collaborator | Acceso limitado a repos específicos |
| `8133` | Billing Manager | Gestión de facturación |
| `8134` | Repository Admin | Admin de repositorios |
| `8135` | Security Manager | Gestión de seguridad |
| `8136` | Organization Member | Miembro estándar |

### Ejemplo con Roles Predefinidos

```hcl
organization_role_assignments = {
  users = {
    "8133" = ["billing-user"]      # Asignar rol predefinido por ID
    "8135" = ["security-lead"]     # Security Manager
    "security-admin" = ["alice"]   # Role personalizado por nombre
  }

  teams = {
    "8133" = ["finance-team"]
    "security-admin" = ["security-team"]
  }
}
```

## Arquitectura de la Implementación

### Flujo de Recursos

```
1. github_organization_role
   └─> Crea roles personalizados
       └─> Genera role_ids

2. local.organization_role_ids
   └─> Mapea nombres → IDs para referencia

3. local.organization_role_user_assignments
   └─> Aplana estructura para iteración

4. github_organization_role_user
   └─> Asigna roles a usuarios

5. github_organization_role_team
   └─> Asigna roles a equipos
```

### Lifecycle Management

Todos los recursos tienen protección de lifecycle:

```hcl
lifecycle {
  prevent_destroy         = true
  create_before_destroy   = true
}
```

- **prevent_destroy**: Previene eliminación accidental
- **create_before_destroy**: Permite updates sin downtime

### Dependencies

```
github_organization_role
    ↓
    ├─> github_organization_role_user (depends_on)
    └─> github_organization_role_team (depends_on)
```

## Outputs

### `organization_role_ids`
Mapa de nombres de roles personalizados a sus IDs:

```hcl
output "organization_role_ids" {
  value = module.github.organization_role_ids
}
# Output: {
#   "security-admin" = 12345
#   "billing-viewer" = 12346
# }
```

### `governance_summary`
Incluye contadores de roles:

```hcl
output "governance_summary" {
  value = module.github.governance_summary
}
# Output incluye:
#   custom_organization_roles = 3
#   role_user_assignments = 5
#   role_team_assignments = 2
```

## Validaciones

### 1. Permisos Mínimos
```hcl
validation {
  condition     = length(var.organization_roles) == 0 || alltrue([
    for role_name, role in var.organization_roles :
    length(role.permissions) > 0
  ])
  error_message = "Each organization role must have at least one permission"
}
```

### 2. Base Role Válidos
```hcl
validation {
  condition     = alltrue([
    for role_name, role in var.organization_roles :
    try(role.base_role, null) == null || contains(
      ["read", "triage", "write", "maintain", "admin"],
      role.base_role
    )
  ])
  error_message = "base_role must be one of: read, triage, write, maintain, admin"
}
```

### 3. Formato de Usuario
```hcl
validation {
  condition     = alltrue([
    for role_name, users in var.organization_role_assignments.users :
    alltrue([for user in users : can(regex("^[a-zA-Z0-9-]+$", user))])
  ])
  error_message = "User logins must be valid GitHub usernames"
}
```

### 4. Formato de Team
```hcl
validation {
  condition     = alltrue([
    for role_name, teams in var.organization_role_assignments.teams :
    alltrue([for team in teams : can(regex("^[a-zA-Z0-9-_]+$", team))])
  ])
  error_message = "Team slugs must be valid GitHub team slugs"
}
```

## Casos de Uso

### 1. Equipo de Seguridad con Acceso a Auditoría

```hcl
organization_roles = {
  "security-auditor" = {
    description = "Security team with audit log access"
    base_role   = "read"
    permissions = [
      "read_audit_logs",
      "read_organization_security"
    ]
  }
}

organization_role_assignments = {
  teams = {
    "security-auditor" = ["security-team"]
  }
  users = {
    "security-auditor" = ["security-lead"]
  }
}
```

### 2. Acceso de Solo Lectura a Facturación

```hcl
organization_roles = {
  "billing-readonly" = {
    description = "Read-only access to billing information"
    base_role   = "read"
    permissions = ["read_organization_billing"]
  }
}

organization_role_assignments = {
  users = {
    "billing-readonly" = ["finance-analyst-1", "finance-analyst-2"]
  }
}
```

### 3. Moderadores de Comunidad

```hcl
organization_roles = {
  "community-moderator" = {
    description = "Manage discussions and community content"
    permissions = [
      "moderate_organization_discussions",
      "manage_organization_content"
    ]
  }
}

organization_role_assignments = {
  teams = {
    "community-moderator" = ["community-team"]
  }
}
```

### 4. Rol de Auditor Externo (Temporal)

```hcl
# Para auditores externos con acceso temporal
organization_roles = {
  "external-auditor" = {
    description = "External auditor with read-only access"
    base_role   = "read"
    permissions = [
      "read_audit_logs",
      "read_organization_security",
      "read_organization_billing"
    ]
  }
}

organization_role_assignments = {
  users = {
    "external-auditor" = ["auditor-temp-user"]
  }
}
```

## Mejores Prácticas

### 1. Principio de Menor Privilegio
Solo otorga los permisos estrictamente necesarios:

```hcl
# ✅ BIEN - Solo permisos necesarios
organization_roles = {
  "billing-viewer" = {
    base_role   = "read"
    permissions = ["read_organization_billing"]
  }
}

# ❌ MAL - Demasiados permisos
organization_roles = {
  "billing-viewer" = {
    base_role   = "admin"  # Demasiado acceso
    permissions = ["read_organization_billing"]
  }
}
```

### 2. Descripción Descriptivas
Usa descripciones claras para documentar el propósito:

```hcl
organization_roles = {
  "security-admin" = {
    description = "Security team lead: audit logs, security config, incident response"
    permissions = [...]
  }
}
```

### 3. Asignación por Equipos Preferentemente
Usa equipos en lugar de usuarios individuales cuando sea posible:

```hcl
# ✅ BIEN - Gestión centralizada por equipo
organization_role_assignments = {
  teams = {
    "security-admin" = ["security-team"]
  }
}

# ⚠️ MENOS IDEAL - Muchos usuarios individuales
organization_role_assignments = {
  users = {
    "security-admin" = ["user1", "user2", "user3", "user4"]
  }
}
```

### 4. Separación de Responsabilidades
Crea roles específicos en lugar de roles "todopoderosos":

```hcl
# ✅ BIEN - Roles separados
organization_roles = {
  "billing-viewer" = {
    permissions = ["read_organization_billing"]
  }
  "security-viewer" = {
    permissions = ["read_audit_logs"]
  }
}

# ❌ MAL - Un solo rol con todo
organization_roles = {
  "super-admin" = {
    permissions = [
      "read_organization_billing",
      "read_audit_logs",
      "manage_organization_settings",
      # ... muchos más
    ]
  }
}
```

### 5. Documentación en Código
Añade comentarios explicando el propósito:

```hcl
organization_roles = {
  # Security team: Read-only access to audit logs for compliance reporting
  # SOX requirement: SEC-001
  "compliance-auditor" = {
    description = "SOX compliance audit access"
    base_role   = "read"
    permissions = ["read_audit_logs"]
  }
}
```

## Limitaciones y Consideraciones

### 1. Requisitos de Plan
- **Requerido**: GitHub Enterprise Cloud
- **No funciona en**: Free, Team, o Enterprise Server

### 2. Permisos Disponibles
Los permisos disponibles dependen de tu plan específico de Enterprise Cloud. Algunos permisos pueden no estar disponibles en todas las configuraciones.

### 3. Lifecycle Protection
Los recursos tienen `prevent_destroy = true` por defecto. Para eliminar:

```bash
# Temporal: remover del state
terraform state rm 'module.github.github_organization_role.this["role-name"]'

# Permanente: quitar lifecycle block manualmente
```

### 4. No hay Update en Asignaciones
Los recursos de asignación (user/team) son ForceNew - cualquier cambio destruye y recrea:

```hcl
# Cambiar el role_id forzará recreación
github_organization_role_user.this["user-security-admin"]
# ~ role_id = 12345 -> 67890 # forces replacement
```

### 5. Importación Manual
Para importar roles existentes:

```bash
# Importar role
terraform import 'module.github.github_organization_role.this["role-name"]' "role-name"

# Importar asignación de usuario
terraform import 'module.github.github_organization_role_user.this["key"]' "12345:username"

# Importar asignación de equipo
terraform import 'module.github.github_organization_role_team.this["key"]' "12345:team-slug"
```

## Troubleshooting

### Error: "Organization role not found"

```bash
# Verificar que el rol existe
terraform state show 'module.github.github_organization_role.this["role-name"]'

# Verificar el role_id
terraform console
> local.organization_role_ids
```

### Error: "User not found in organization"

```bash
# El usuario debe ser miembro de la organización primero
# Verificar membresía:
gh api /orgs/YOUR-ORG/members/USERNAME
```

### Error: "Team not found"

```bash
# Verificar que el team existe
gh api /orgs/YOUR-ORG/teams/TEAM-SLUG

# Listar todos los teams
gh api /orgs/YOUR-ORG/teams
```

### Validar Permisos Aplicados

```bash
# Ver roles de un usuario
gh api /orgs/YOUR-ORG/organization-roles/users/USERNAME

# Ver roles de un equipo
gh api /orgs/YOUR-ORG/organization-roles/teams/TEAM-SLUG
```

## Migración desde Repository Roles

Si actualmente usas `github_organization_custom_role` (repository roles) y quieres roles de organización:

```hcl
# ANTES - Repository role
# github_organization_custom_role (deprecated)
resource "github_organization_custom_role" "code_reviewer" {
  name        = "code-reviewer"
  base_role   = "read"
  permissions = ["pull"]
}

# DESPUÉS - Organization role
organization_roles = {
  "security-admin" = {
    description = "Organization-wide security administration"
    base_role   = "read"
    permissions = [
      "read_audit_logs",
      "manage_organization_security"
    ]
  }
}
```

**Nota importante**: No es una migración 1:1. Los roles de organización tienen permisos completamente diferentes (org-wide vs repo-specific).

## Referencias

- [GitHub Docs: Custom Organization Roles](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-peoples-access-to-your-organization-with-roles/about-custom-organization-roles)
- [GitHub API: Organization Roles](https://docs.github.com/en/rest/orgs/organization-roles)
- [Terraform Provider GitHub](https://registry.terraform.io/providers/integrations/github/latest/docs)

## Changelog

### v2.0.0 - Organization Roles
- ✅ Agregado soporte para `github_organization_role`
- ✅ Agregado soporte para `github_organization_role_user`
- ✅ Agregado soporte para `github_organization_role_team`
- ✅ Agregados outputs para role IDs
- ✅ Agregada validación de permisos y base roles
- ✅ Documentación completa en español

---

**Última actualización**: 2024
**Módulo**: terraform-github-governance
**Mantenedor**: Victor
