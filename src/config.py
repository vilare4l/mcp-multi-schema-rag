"""
Configuration for multi-schema support.
Allows prefixing table and RPC function names via environment variables.
"""
import os

# Prefixes configurable via environment variables
TABLE_PREFIX = os.getenv('TABLE_PREFIX', '')
RPC_PREFIX = os.getenv('RPC_PREFIX', '')

# For backward compatibility, export as module-level constants
__all__ = ['TABLE_PREFIX', 'RPC_PREFIX']
