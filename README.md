# Hotel Bookings - DevOps Assessment

Terraform infrastructure design for `Internet -> ALB -> ECS/Fargate -> RDS`,
plus a local PostgreSQL environment with migrations, seed data, an
optimized query, and backup/restore scripts.

Actual AWS deployment is not required or performed here. Terraform is
validated through `fmt` / `init` / `validate` / `plan`; the database
work is fully runnable locally via Docker Compose.

## Repo layout

```
infra/
  modules/
    network/   # VPC, public + private subnets, IGW, NAT gateway(s)
    ecs/       # ALB, security groups, ECS cluster/task/service (Fargate)
    rds/       # RDS instance + subnet group + security group
  envs/
    dev/       # smaller instance, 3-day backups, deletion protection off
    prod/      # larger instance, 30-day backups, deletion protection on
db/
  migrations/  # 001_create_tables.sql, 002_add_indexes.sql
  seed/        # generate_seed.py -> seed.sql (140 bookings, deterministic)
scripts/
  backup.sh    # timestamped pg_dump
  restore.sh   # restores into a fresh database + verification counts
docker-compose.yml
.github/workflows/terraform.yml
```

## Part 1-3: Terraform

### Architecture

`Internet -> ALB (public subnets) -> ECS/Fargate (private subnets) -> RDS (private subnets)`

- The **ALB security group** is the only one that accepts inbound traffic
  from `0.0.0.0/0`, and only on port 80.
- The **ECS task security group** only accepts traffic from the ALB
  security group - not from the internet directly.
- The **RDS security group** only accepts traffic from the ECS task
  security group(s) passed into the module (`allowed_security_group_ids`).
  RDS has `publicly_accessible = false` and lives in the private subnets.

### Environments

`infra/envs/dev` and `infra/envs/prod` both call the same three modules
but differ in the values passed in:

| Setting                  | dev                  | prod                 |
|---------------------------|----------------------|----------------------|
| NAT gateways              | 1 shared              | 1 per AZ             |
| RDS instance class         | `db.t4g.micro`        | `db.r6g.large`        |
| RDS multi-AZ                | false                 | true                  |
| Backup retention           | 3 days                | 30 days               |
| Deletion protection        | false                 | true                  |
| Skip final snapshot        | true                  | false                 |
| Fargate task size           | 256 CPU / 512 MB      | 1024 CPU / 2048 MB    |
| Desired / max task count   | 1 / 2                 | 2 / 6                 |

Each environment has its own `backend "s3"` block (placeholder
bucket/table names - replace with real resources before a first
`init`, or run with `-backend=false` to stay local) and its own
`*.tfvars` file.

### Running it

```bash
cd infra/envs/dev   # or infra/envs/prod
terraform fmt -check -recursive ../../..
terraform init -backend=false
terraform validate
terraform plan -refresh=false -var-file=dev.tfvars
```

`db_password` is intentionally left out of both `.tfvars` files - supply
it via `TF_VAR_db_password` (or a real secrets backend) rather than
committing a password to source control.

This sandbox's outbound network doesn't reach `registry.terraform.io`,
so the `.tf` files here were syntax-checked with a Python HCL2 parser
and cross-checked so every variable a module call passes matches a
declared variable in that module (see git history / commit notes) -
run the commands above yourself once you have registry access to get a
real `terraform validate` / `plan`.

### CI (Part 3, optional)

`.github/workflows/terraform.yml` runs on pull requests touching
`infra/**`, for both `dev` and `prod`:

```
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform plan -refresh=false -var-file=<env>.tfvars
```

The plan step uses dummy AWS credentials plus a `ci_mode` provider flag
(`skip_credentials_validation` / `skip_requesting_account_id` /
`skip_metadata_api_check`) so it produces a real, readable plan without
needing an actual AWS account - the plan is posted as a PR comment and
uploaded as a workflow artifact.

## Part 4-5: Local database + query optimization

### Start it

```bash
docker compose up -d
```

Postgres's `docker-entrypoint-initdb.d` only scans top-level files (not
subdirectories) and runs them in lexical order, which is why
`docker-compose.yml` mounts the three files directly with numeric
prefixes:

1. `001_create_tables.sql` - creates `hotel_bookings` and `booking_events`
2. `002_add_indexes.sql` - adds the optimization index (see below)
3. `003_seed.sql` (generated as `db/seed/seed.sql`) - 140 bookings across
   6 cities, 8 orgs, and 5 statuses, plus events for ~60% of bookings

To regenerate the seed file: `python3 db/seed/generate_seed.py` (fixed
random seed, so output is reproducible).

### The query being optimized

```sql
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
```

### Index choice

```sql
CREATE INDEX idx_hotel_bookings_city_created_at
    ON hotel_bookings (city, created_at)
    INCLUDE (org_id, status, amount);
```

- `city` is an equality filter and the more selective of the two, so it
  leads the composite index.
- `created_at` is a range filter, and sits second so each `city` branch
  of the index is range-scannable.
- `org_id`, `status`, and `amount` are carried as `INCLUDE` columns
  (a covering index) since the query only ever reads them alongside the
  filter columns - this lets Postgres answer from the index without
  always going back to the heap.

**Measured impact** (this repo's actual `EXPLAIN ANALYZE` output, not
estimated): on the 140-row seed data the planner correctly chooses a
sequential scan - the table is too small for an index to pay off. To
get a meaningful before/after, the same query was run against the same
table bulk-loaded to 200,000 rows:

| | Plan | Execution time |
|---|---|---|
| Before index | Parallel Seq Scan | ~35.7 ms |
| After index  | Bitmap Index Scan on `idx_hotel_bookings_city_created_at` | ~3.4 ms |

Roughly a 10x reduction at that scale. Reproduce it yourself:

```bash
docker compose exec db psql -U app_admin -d hotel_bookings -c "EXPLAIN ANALYZE <query above>;"
```

## Part 6: Backup and restore

```bash
./scripts/backup.sh          # writes backups/hotel_bookings_<timestamp>.dump
                              # and updates backups/latest.dump
./scripts/restore.sh         # restores backups/latest.dump into a fresh
                              # database, hotel_bookings_restore
```

Both scripts read `DB_HOST` / `DB_PORT` / `DB_NAME` / `DB_USER` /
`PGPASSWORD` from the environment, defaulting to the values in
`docker-compose.yml`.

### How to verify the restore worked

`restore.sh` always restores into a **fresh** database
(`hotel_bookings_restore` by default - drop-then-create, so nothing
from a previous run lingers) and prints verification counts at the end:

```
hotel_bookings rows : 140
booking_events rows : 182
indexes on hotel_bookings : 2
```

Compare those numbers against the source database:

```bash
docker compose exec db psql -U app_admin -d hotel_bookings -c \
  "SELECT (SELECT COUNT(*) FROM hotel_bookings) AS bookings, (SELECT COUNT(*) FROM booking_events) AS events;"
```

A matching row count on both tables, plus 2 indexes on `hotel_bookings`
(the primary key plus `idx_hotel_bookings_city_created_at`), confirms
the restore is complete and correct.

## Submission checklist

- [x] Terraform infrastructure code (`infra/modules/*`)
- [x] dev and prod Terraform environments (`infra/envs/dev`, `infra/envs/prod`)
- [x] Docker Compose database setup (`docker-compose.yml`)
- [x] SQL migration files (`db/migrations/`)
- [x] Seed data script (`db/seed/generate_seed.py` + generated `seed.sql`)
- [x] Database backup script (`scripts/backup.sh`)
- [x] Database restore script (`scripts/restore.sh`)
- [x] README.md with setup and verification steps
