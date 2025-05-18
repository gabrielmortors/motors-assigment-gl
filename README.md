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
- Models: `stg_events`, `stg_groups`, `stg_users`, `stg_venues`, `stg_rsvps`, `stg_group_topics`, `stg_user_memberships`

### Intermediate Layer (Coming Soon)
- Will implement business logic and relationships between entities
- Will generate surrogate keys and establish data relationships

### Marts Layer (Coming Soon)
- Will create final dimensional models for business users
- Will organize data by business domain

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

## Contributing

This project follows these conventions:
- SQL formatting uses leading commas
- The models folder structure follows medallion architecture
- Each layer has its own schema in the database
