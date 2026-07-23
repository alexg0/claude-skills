# Private test resources per workspace

Use workspace-private resources when a test suite mutates, truncates, resets, or drops local state and multiple Conductor workspaces may run concurrently. The same approach applies to databases, Redis namespaces, queue prefixes, search indexes, object-storage buckets, and filesystem paths.

## Naming contract

1. Use CONDUCTOR_WORKSPACE_NAME as the stable workspace input. Do not use a session identifier: sessions can change while the workspace remains the same.
2. When CONDUCTOR_WORKSPACE_NAME is absent or blank, preserve the project's conventional test resource name. This keeps CI and ordinary checkouts unchanged.
3. Normalize the workspace name to the resource's safe character set.
4. Bound the readable slug and append a short digest of the original, untruncated workspace name. A digest prevents collisions between names that normalize or truncate identically.
5. Include the application and environment in the final name, for example my_app_test_feature_x_a1b2c3d4.
6. Respect the resource's length limit. PostgreSQL identifiers are limited to 63 bytes; MySQL database names are limited to 64 characters.

Recommended algorithm:

~~~text
if workspace name is absent:
  use the existing test resource name
else:
  slug = lowercase(workspace name)
  slug = replace runs of unsafe characters with "_"
  slug = trim leading/trailing "_"
  slug = first 32 characters, or "workspace" when empty
  digest = first 8 hex characters of SHA-256(original workspace name)
  name = application + "_test_" + slug + "_" + digest
~~~

Compute the digest from the original workspace name, not the normalized or truncated slug.

## Rails and PostgreSQL example

Keep the derivation in application configuration so every Rails command resolves the same database without requiring callers to export DATABASE_URL.

~~~yaml
<%
require 'digest'

workspace_name = ENV['CONDUCTOR_WORKSPACE_NAME']
test_database = if workspace_name.nil? || workspace_name.empty?
  'my_app_test'
else
  workspace_slug = workspace_name
    .downcase
    .gsub(/[^a-z0-9]+/, '_')
    .gsub(/\A_+|_+\z/, '')[0, 32]
  workspace_slug = 'workspace' if workspace_slug.empty?
  workspace_digest = Digest::SHA256.hexdigest(workspace_name)[0, 8]

  "my_app_test_#{workspace_slug}_#{workspace_digest}"
end
%>

test:
  <<: *default
  database: <%= test_database %>
~~~

Use a project helper instead of inline ERB when the repository already centralizes environment naming. Add a small configuration test covering both the Conductor and fallback paths.

## Setup guidance

The workspace setup command must prepare every workspace-private resource that developers or agents will use. For Rails:

~~~toml
[scripts]
setup = "bundle install && bin/rails db:prepare && RAILS_ENV=test bin/rails db:prepare"
run_mode = "concurrent"
~~~

Only declare run_mode = "concurrent" after ports and all mutable local resources are isolated. If a required service cannot be namespaced, use run_mode = "nonconcurrent" or Spotlight testing.

Setup must be idempotent. Prefer framework-native prepare commands that create or migrate as needed. Do not automatically drop shared or fallback resources. If archive-time cleanup is desired, derive the exact same private name and refuse cleanup when the workspace variable is absent.

## Verification checklist

- With CONDUCTOR_WORKSPACE_NAME absent, configuration resolves to the existing test resource name.
- Two distinct workspace names resolve to distinct safe names.
- Names that normalize to the same slug still differ by digest.
- The final name stays within the backing service's identifier limit.
- The setup command creates or prepares the private test resource and is safe to rerun.
- Tests in two workspaces can run concurrently without truncating, locking, or deleting each other's state.
- CI configuration remains unchanged unless CI intentionally sets CONDUCTOR_WORKSPACE_NAME.
