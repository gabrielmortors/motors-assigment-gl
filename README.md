# Motors Meetup Analytics

A dbt project that transforms raw Meetup JSON data into analytics-ready models using Databricks.

## Project Structure

This project follows a medallion architecture approach with the following layers:

### Raw Layer
- Contains minimally transformed data with proper typing and field renaming
- Preserves nested structures (arrays) for downstream processing
- Models: `raw_events`, `raw_groups`, `raw_users`, `raw_venues`

### Staging Layer
- Standardizes and cleanses data from the raw layer
- Flattens nested structures into separate models
- Implemented incremental processing for efficient data updates and `event_id` sanitization for Databricks compatibility (e.g., ensuring consistent casing and replacing characters unsuitable for partition column values to create a reliable `event_id_clean` for joins and partitioning).
- Models: `stg_events`, `stg_groups`, `stg_users`, `stg_venues`, `stg_event_rsvps` (formerly `stg_rsvps`), `stg_group_topics`, `stg_memberships` (formerly `stg_user_memberships`)

### Intermediate Layer
- Implements business logic and relationships between entities.
- Generates surrogate keys using `dbt_utils` and establishes data relationships.
- Tracks versioning for key entities (events, RSVPs, memberships).
- Includes comprehensive documentation and data quality tests.
- Models: `int_events_with_venues`, `int_event_rsvps`, `int_user_memberships_with_groups`.
- Implemented incremental processing strategies tailored for Databricks.

### Marts Layer
- Creates final dimensional models for business users.
- Organizes data by business domain into `dim` (dimensions) and `fact` (facts) subdirectories.
- All mart models are built into a schema configured dynamically per environment in `dbt_project.yml` (e.g., `dbt_gabrielmortors_marts` for local, `marts` for cloud dev/prod).
- Models include:
  - `dim_date`: A standard date dimension table, providing attributes like day, month, year, day of week, etc., for time-based analysis.
  - `dim_events`: Stores descriptive attributes of Meetup events, such as name, description, status, and venue details. This serves as a central reference for event information.
  - `fact_rsvps`: Contains RSVP-level data, linking individual users to specific events they have RSVP'd to, including their response (yes, no, waitlist) and number of guests.
  - `fact_event_attendance` (formerly `fact_events`): Provides aggregated attendance metrics for each event, such as total RSVPs, 'yes' counts, and capacity utilization, linking to `dim_events`.

### PBI Layer
- **Purpose**: Provides a dedicated presentation layer optimized for Power BI.
- **Key Transformation**: Casts surrogate key columns (e.g., `user_sk`, `event_sk`) from their native binary/hash format to `STRING` type. This is crucial as Power BI does not effectively handle binary keys for relationships and filtering.
- **Structure**: Models in this layer are typically views that select from the corresponding `marts` layer models, applying only the necessary key casting.
- **Schema**: Configured in `dbt_project.yml` to be `dbt_gabrielmortors_pbi` for the `development` target and `pbi` for `dev` and `prd` targets.
- **Models**: Located in the `models/pbi/` directory (e.g., `pbi_dim_users`, `pbi_fact_events`).

## Key Milestones & Features

- **Full Medallion Architecture:** Successfully implemented Raw, Staging, Intermediate, and Mart layers, providing a robust and scalable data pipeline.
- **Incremental Data Processing:** Applied incremental load strategies (e.g., `merge`) to staging and intermediate models for efficiency, optimized for Databricks Delta Lake.
- **Databricks Optimization:** Addressed Databricks-specific SQL syntax and limitations, including `partition_by` requirements, usage of `LATERAL VIEW EXPLODE` for array unnesting, and `event_id` sanitization for compatibility.
- **Custom dbt Macros:** Developed reusable macros for common transformations, such as Unix timestamp conversion (`to_timestamp_from_unix`) and millisecond to second conversion (`convert_milliseconds_to_seconds`), enhancing code modularity and maintainability.
- **Data Quality & Documentation:** Established comprehensive YAML documentation and dbt tests (including primary key, not-null, and relationship tests) for models across all layers, ensuring data integrity and understanding.
- **Source Data Monitoring:** Implemented source freshness checks to monitor the timeliness of incoming raw data, with warnings configured for stale data (e.g., for the `events` source).
- **Standardized Schema Management:** Centralized and dynamic schema configuration for all model layers in `dbt_project.yml`, promoting consistency across environments.
- **Code Conventions:** Adherence to SQL formatting (leading commas) and project structure best practices throughout the development process.

## Data Sources

The project uses the following JSON data sources:

- **events.json**: Meetup events with RSVPs as nested arrays
- **groups.json**: Group information with topics as nested arrays
- **users.json**: User profiles with memberships as nested arrays 
- **venues.json**: Venue location information

## Getting Started

### Prerequisites

- Python (version 3.10-3.12)
- dbt-databricks
- Access to a Databricks workspace

### Windows Setup Requirements

If using Windows, you'll need to:

1. Run PowerShell as administrator
2. Set execution policy to allow scripts:
   ```powershell
   # Temporarily allow unsigned scripts in this session
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```

### Setup

1. Clone this repository
2. Install dependencies: `pip install -r requirements.txt`
3. Configure your Databricks connection in `profiles.yml`
4. Run the models: `dbt run`

## Environment Configuration

This dbt project is configured to support three distinct environments:

1.  **`development` (Local)**: Used for local development and testing. This is the default target.
    *   **Catalog**: `workspace`
    *   **Models built into schemas like**: `dbt_gabrielmortors_raw`, `dbt_gabrielmortors_staging`, etc.
    *   **Example FQN**: `workspace.dbt_gabrielmortors_raw.your_model_name`
2.  **`dev` (Cloud Development)**: Used for development and testing on a shared cloud Databricks environment.
    *   **Catalog**: `dev`
    *   **Models built into schemas like**: `raw`, `staging`, etc.
    *   **Example FQN**: `dev.raw.your_model_name`
3.  **`prd` (Cloud Production)**: Used for the production deployment of models.
    *   **Catalog**: `prd`
    *   **Models built into schemas like**: `raw`, `staging`, etc.
    *   **Example FQN**: `prd.raw.your_model_name`

### `profiles.yml` Setup

Your `~/.dbt/profiles.yml` file should be configured with `outputs` for `development`, `dev`, and `prd` targets under the `motors_meetup` profile. The `development` target should be set as the default.

Key configurations for each target:

*   **`development` target:**
    ```yaml
    development:
      type: databricks
      schema: dbt_gabrielmortors # Base connection schema
      catalog: workspace
      # ... other connection details (host, http_path, token) ...
    ```
*   **`dev` target:**
    ```yaml
    dev:
      type: databricks
      schema: main # Base connection schema
      catalog: dev
      # ... other connection details ...
    ```
*   **`prd` target:**
    ```yaml
    prd:
      type: databricks
      schema: main # Base connection schema
      catalog: prd
      # ... other connection details ...
    ```

### Model Naming and Schema Management

The project uses a combination of configurations in `dbt_project.yml` and a custom macro (`macros/generate_schema_name.sql`) to achieve the desired model naming:

*   **Catalog**: Dynamically set based on the target (`workspace`, `dev`, `prd`) via global `+catalog` in `dbt_project.yml`.
*   **Schema**:
    *   For the `development` target, schemas are constructed as `dbt_gabrielmortors_<layer_name>` (e.g., `dbt_gabrielmortors_raw`).
    *   For `dev` and `prd` targets, schemas are named directly after the layer (e.g., `raw`, `staging`).
    *   These are defined in `dbt_project.yml` within each model layer's configuration (e.g., under `models.motors_meetup.raw.+schema`).
    *   The `macros/generate_schema_name.sql` macro ensures these schema definitions are used directly, overriding dbt's default behavior of prepending the `profiles.yml` schema.

### Running dbt for Specific Environments

*   To run using the default `development` target:
    ```bash
    dbt run
    dbt test
    ```
*   To run using the `dev` target:
    ```bash
    dbt run --target dev
    dbt test --target dev
    ```
*   To run using the `prd` target:
    ```bash
    dbt run --target prd
    dbt test --target prd
    ```

## CI/CD Pipeline

This project leverages dbt Cloud and GitHub webhooks to implement a robust CI/CD pipeline, ensuring code quality and automated deployments.

**Workflow:**

1.  **Development**: Developers work on feature branches (e.g., `feature/my-new-model`).
2.  **Pull/Merge Request (PR/MR)**: When a PR/MR is opened against the `main` branch:
    *   A GitHub webhook triggers a dbt Cloud job named "Merge Request Test".
    *   This job runs in a dedicated `dev` environment, using a temporary schema prefixed with `dbt_cloud_pr_`.
    *   **Selective Build & Test**: The job executes `dbt build --select state:modified+`. This command builds and tests only the models that have changed since the last successful run on `main`, plus their downstream dependencies.
    *   **Deferral**: Unchanged upstream models are referenced from the `prd` environment (`Defer to prd`), ensuring the modified models are tested against production-like data without rebuilding the entire project.
    *   **Quality Gates**:
        *   The dbt Cloud job must complete successfully (all models build, all tests pass).
        *   At least one team member must approve the PR/MR.
        *   *(Future enhancement: Incorporate `sqlfluff` for automated SQL linting in this step).*
3.  **Merge to `main`**: Once all checks pass and the PR/MR is approved, it can be merged into the `main` branch.
4.  **Production Deployment (Manual Trigger / Future Enhancement)**:
    *   Currently, after a PR is merged to `main`, the production deployment is a manually triggered dbt Cloud job. This job runs a full `dbt build` in the `prd` environment to update all production models.
    *   *(Note: The production dbt Cloud job ensures that `dev` and `prd` environments use separate schemas/catalogs, preventing any cross-contamination).*
    *   *(Future Enhancement: We plan to automate this step by configuring a dbt Cloud job to trigger automatically upon merges to `main`. Additionally, these production jobs will be scheduled to run at specific frequencies (e.g., daily, hourly) using dbt Cloud's scheduler, and we will leverage dbt tags for more granular control over production runs.)*
5.  **Observability**:
    *   dbt Cloud run results and logs are visible directly within the GitHub PR/MR interface.
    *   *(Future enhancement: Configure notifications (e.g., Slack/Teams) for job failures).*

**Benefits:**

*   **Continuous Integration (CI)**: Automated testing on every PR/MR catches issues early, preventing broken code from reaching `main`.
*   **Continuous Delivery/Deployment (CD)**: A deterministic path pushes validated code changes to the production environment upon merging to `main`.
*   **Efficiency**: Selective builds (`state:modified+`) and deferral significantly speed up CI checks.
*   **Confidence**: Mandatory approvals and automated tests increase confidence in deployments.

This setup ensures that all code is reviewed, tested, and deployed in a consistent and automated manner.

## Orchestration

The project's data transformation workflows are orchestrated using scheduled jobs in dbt Cloud. This ensures that data is processed reliably, tests are run consistently, and data freshness is maintained across different environments.

**Key dbt Cloud Jobs:**

*   **Periodic Full Refresh (`dbt run --full-refresh`)**:
    *   **Purpose**: Scheduled periodically (e.g., weekly or as needed) to perform a full rebuild of specified models or the entire project.
    *   **Benefits**: Helps eliminate data drift, cleans up tombstoned records in Delta tables, and can be used to reprocess historical data or apply structural changes that incremental models might not fully address.
    *   **Significance**: Demonstrates an understanding of long-term data maintenance and the need for occasional "resets" beyond daily incremental runs.

*   **Main Production Build (`dbt build`)**:
    *   **Purpose**: This is the primary scheduled job (e.g., daily or multiple times a day) for the `prd` (production) environment.
    *   **Execution Steps**:
        1.  `dbt source freshness`: As a pre-check, this command validates that upstream source data has arrived on time. The job will fail fast if sources are stale, preventing transformations on incomplete or outdated data.
        2.  `dbt run`: Executes models (typically incrementally) to process new or updated data.
        3.  `dbt test`: Runs all defined data quality and integrity tests to validate the transformations and the resulting data.
    *   **Benefits**: Ensures that production data models are regularly updated, thoroughly tested, and validated against source data timeliness.
    *   **Significance**: Highlights a commitment to data quality by treating tests and source freshness as integral parts of the production pipeline.

*   **Documentation Generation (`dbt docs generate`)**:
    *   **Purpose**: Typically scheduled to run after successful main production builds (e.g., nightly).
    *   **Benefits**: Keeps the project's data documentation current, reflecting the latest state of the production models and their metadata.
    *   **Significance**: Shows adherence to good documentation practices, making the data landscape understandable and accessible.

*   **Other Operational Jobs (Examples & Future Considerations)**:
    *   **Snapshots (`dbt snapshot`)**: If using dbt snapshots for Type 2 Slowly Changing Dimensions, these would be scheduled as needed.
    *   **Tag-based Runs (`dbt run --select tag:hourly` or `dbt build --select tag:finance`)**: *(Future Enhancement: Implement tag-based scheduling to run subsets of models at different frequencies or for specific business domains, aligning with varying data SLAs or processing needs.)*

**Job Sequencing & Safety Mechanisms:**

*   **Freshness First**: Source freshness checks are designed to run before main transformation jobs to prevent processing stale or incomplete data, saving compute and providing early warnings of upstream issues.
*   **Build Before Docs**: Documentation is generated after a successful build to ensure it accurately reflects the current, validated state of the data models.
*   **Environment Isolation**: As detailed in the "Environment Configuration" and "CI/CD Pipeline" sections, dbt Cloud jobs operate within distinct environments (`dev`, `prd`) with separate schemas/catalogs. This is crucial for preventing data leakage and ensuring that development or test runs do not impact the production environment.
*   **Alerting**: *(Future Enhancement: Configure dbt Cloud jobs to send notifications (e.g., to a dedicated Slack channel like `#data-alerts`) on run failures. Critical production job failures could also be configured to page an on-call resource.)*

This orchestration setup provides a reliable, observable, and scalable way to manage the data pipeline, ensuring that data products are timely, accurate, and well-documented.

## Testing

The project includes data quality tests for key fields:
```bash
dbt test
```

To check the freshness of your source data:
```bash
dbt source freshness
```

## Documentation

The project includes comprehensive YAML documentation for all models:
```bash
dbt docs generate
dbt docs serve
```

## Dependencies

- dbt-utils (v1.3.0): Used for surrogate key generation in intermediate models

## TO DO

- Implement other relevant fact tables (e.g., `fact_user_engagement`, `fact_group_growth`).
- Enhance data validation with more comprehensive dbt tests across all layers.
- ~~Develop a Power BI-compatible presentation layer, ensuring surrogate keys are in a PBI-friendly format (e.g., not binary).~~ (Completed: See PBI Layer section)
- Explore advanced dbt features (e.g., snapshots for Type 2 SCDs, custom materializations if needed).
- Continuously refine and optimize model performance.

## Contributing

This project follows these conventions:
- SQL formatting uses leading commas
- The models folder structure follows medallion architecture
- Each layer has its own schema in the database
