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
- Implemented incremental processing for efficient data updates and `event_id` sanitization for Databricks compatibility.
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
- All mart models are built into a dedicated `marts` schema, configured in `dbt_project.yml`.
- Models include `dim_date`, `dim_events`, `fact_rsvps`, `fact_events`.

## Key Milestones & Features

- **Full Medallion Architecture:** Successfully implemented Raw, Staging, Intermediate, and Mart layers, providing a robust and scalable data pipeline.
- **Incremental Data Processing:** Applied incremental load strategies (e.g., `merge`) to staging and intermediate models for efficiency, optimized for Databricks Delta Lake.
- **Databricks Optimization:** Addressed Databricks-specific SQL syntax and limitations, including `partition_by` requirements, usage of `LATERAL VIEW EXPLODE` for array unnesting, and `event_id` sanitization for compatibility.
- **Custom dbt Macros:** Developed reusable macros for common transformations, such as Unix timestamp conversion (`to_timestamp_from_unix`) and millisecond to second conversion (`convert_milliseconds_to_seconds`), enhancing code modularity and maintainability.
- **Data Quality & Documentation:** Established comprehensive YAML documentation and dbt tests for models across layers, ensuring data integrity and understanding.
- **Standardized Schema Management:** Centralized schema configuration for mart models in `dbt_project.yml`, promoting consistency.
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

### Connection Details

The project connects to Databricks with these parameters:
- Host: dbc-7945d99b-7aa0.cloud.databricks.com
- HTTP Path: /sql/1.0/warehouses/11ff00454b608c00
- Schema: meetup_dev

## Testing

The project includes data quality tests for key fields:
```bash
dbt test
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
- Develop a Power BI-compatible presentation layer, ensuring surrogate keys are in a PBI-friendly format (e.g., not binary).
- Configure and document dbt Cloud environments (development, staging, production).
- Explore advanced dbt features (e.g., snapshots for Type 2 SCDs, custom materializations if needed).
- Continuously refine and optimize model performance.

## Contributing

This project follows these conventions:
- SQL formatting uses leading commas
- The models folder structure follows medallion architecture
- Each layer has its own schema in the database
