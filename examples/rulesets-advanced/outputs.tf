# ============================================================================
# RULESET SUMMARY OUTPUTS
# ============================================================================

output "total_rulesets" {
  description = "Total number of rulesets configured"
  value       = length(module.github_org.ruleset_ids)
}

output "rulesets_by_enforcement" {
  description = "Rulesets grouped by enforcement level"
  value = {
    active   = length([for k, v in module.github_org.ruleset_ids : k if can(regex("active", k))])
    evaluate = length([for k, v in module.github_org.ruleset_ids : k if can(regex("evaluate", k))])
    disabled = length([for k, v in module.github_org.ruleset_ids : k if can(regex("disabled", k))])
  }
}

output "rulesets_by_target" {
  description = "Rulesets grouped by target type (branch vs tag)"
  value = {
    branch = length([for k, v in module.github_org.ruleset_ids : k if !can(regex("tag", k))])
    tag    = length([for k, v in module.github_org.ruleset_ids : k if can(regex("tag", k))])
  }
}

# ============================================================================
# EDGE CASE CATEGORY OUTPUTS
# ============================================================================

output "edge_cases_by_category" {
  description = "Number of edge cases demonstrated per category"
  value = {
    enforcement_levels = 3 # active, evaluate, disabled
    ref_patterns       = 3 # ~DEFAULT_BRANCH, ~ALL, wildcards
    bypass_actors      = 2 # all types, none
    pull_request_rules = 2 # comprehensive, minimal
    status_checks      = 2 # comprehensive, minimal
    commit_patterns    = 2 # with email patterns, with negation
    branch_patterns    = 4 # starts_with, ends_with, contains, regex
    tag_patterns       = 3 # semver, calver, prefix
    boolean_rules      = 2 # all enabled, creation prevention
    deployments        = 2 # multiple environments, single
    code_scanning      = 3 # high, medium, all severities
    scope              = 1 # organization-level
    complexity         = 1 # maximum complexity
    negation_patterns  = 1 # negated matches
    special_regex      = 2 # escaping, lookahead
    minimal_rulesets   = 2 # minimal branch, minimal tag
    exclusion_patterns = 1 # complex wildcards
    combining_rulesets = 2 # multiple on same branch
    anti_patterns      = 1 # impossible match
  }
}

# ============================================================================
# FEATURE COVERAGE OUTPUTS
# ============================================================================

output "features_demonstrated" {
  description = "GitHub ruleset features covered in this example"
  value = {
    enforcement_levels = ["active", "evaluate", "disabled"]

    ref_patterns = [
      "~DEFAULT_BRANCH",
      "~ALL",
      "wildcards (**)",
      "specific refs"
    ]

    bypass_actors = [
      "organization_admins",
      "repository_roles",
      "teams",
      "integrations"
    ]

    pr_requirements = [
      "required_approving_review_count",
      "dismiss_stale_reviews_on_push",
      "require_code_owner_review",
      "require_last_push_approval",
      "required_review_thread_resolution"
    ]

    status_check_options = [
      "strict_required_status_checks_policy",
      "required_checks with context",
      "integration_id filtering"
    ]

    pattern_types = [
      "commit_message_pattern",
      "commit_author_email_pattern",
      "committer_email_pattern",
      "branch_name_pattern",
      "tag_name_pattern"
    ]

    pattern_operators = [
      "starts_with",
      "ends_with",
      "contains",
      "regex"
    ]

    boolean_rules = [
      "creation",
      "deletion",
      "update",
      "required_linear_history",
      "required_signatures"
    ]

    advanced_features = [
      "required_deployments",
      "code_scanning with CodeQL",
      "security_alerts_threshold",
      "pattern negation",
      "complex regex with lookahead"
    ]
  }
}

# ============================================================================
# SPECIFIC RULESET IDS
# ============================================================================

output "enforcement_level_examples" {
  description = "Ruleset IDs for each enforcement level"
  value = {
    active   = module.github_org.ruleset_ids["edge-case-active-enforcement"]
    evaluate = module.github_org.ruleset_ids["edge-case-evaluate-mode"]
    disabled = module.github_org.ruleset_ids["edge-case-disabled-ruleset"]
  }
}

output "pattern_type_examples" {
  description = "Ruleset IDs demonstrating different pattern types"
  value = {
    default_branch = module.github_org.ruleset_ids["edge-case-default-branch-pattern"]
    all_branches   = module.github_org.ruleset_ids["edge-case-all-branches-pattern"]
    wildcard       = module.github_org.ruleset_ids["edge-case-wildcard-patterns"]
    starts_with    = module.github_org.ruleset_ids["edge-case-branch-starts-with"]
    ends_with      = module.github_org.ruleset_ids["edge-case-branch-ends-with"]
    contains       = module.github_org.ruleset_ids["edge-case-branch-contains"]
    regex_complex  = module.github_org.ruleset_ids["edge-case-branch-regex-complex"]
  }
}

output "security_examples" {
  description = "Ruleset IDs for security-focused configurations"
  value = {
    no_bypass      = module.github_org.ruleset_ids["edge-case-no-bypass-actors"]
    max_complexity = module.github_org.ruleset_ids["edge-case-maximum-complexity"]
    code_scanning  = module.github_org.ruleset_ids["edge-case-code-scanning-high-severity"]
    commit_signing = module.github_org.ruleset_ids["edge-case-all-boolean-rules"]
  }
}

# ============================================================================
# TESTING AIDS
# ============================================================================

output "test_repositories" {
  description = "Test repositories created for demonstrating rulesets"
  value = {
    total = length(module.github_org.repositories)
    repos = keys(module.github_org.repositories)
  }
}

output "rulesets_full_list" {
  description = "Complete list of all rulesets with IDs"
  value       = module.github_org.ruleset_ids
}
