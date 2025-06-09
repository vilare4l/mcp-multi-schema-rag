# Multi-Schema Support

This fork adds support for multiple database schemas via environment variable prefixes.

## New Features

- **TABLE_PREFIX**: Prefix for table names (crawled_pages, sources, code_examples)
- **RPC_PREFIX**: Prefix for RPC function names (match_crawled_pages, match_code_examples)

## Usage

### Environment Variables
```bash
# For lean management schema
TABLE_PREFIX=lean_
RPC_PREFIX=lean_

# For construction schema  
TABLE_PREFIX=construction_
RPC_PREFIX=construction_