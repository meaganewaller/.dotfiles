# Tradeoff: PostgreSQL Quoting Strategy for pg_get_serial_sequence

**Branch:** mw/improper-quoting-in-postgres_241
**Files:** Database query generation code (pg_get_serial_sequence argument handling)
**Source:** auto-capture

## Decision Summary

Fixed a bug in PostgreSQL sequence detection by switching from identifier quoting (`@quoter.table()`) to string literal quoting (`@quoter.quote()`) for the table name argument to `pg_get_serial_sequence()`. This required understanding PostgreSQL's distinction between identifiers (double-quoted) and string literals (single-quoted) for different SQL contexts.

## What Was Chosen

Changed `@quoter.table(@table_name)` → `@quoter.quote(@table_name)` when passing arguments to `pg_get_serial_sequence(table_name, column_name)`.

The correct SQL now generates:
```sql
SELECT pg_get_serial_sequence('agencies', 'id')  -- string literals
```

This correctly passes the table and column names as string arguments to the PostgreSQL function, allowing it to look up the sequence name in the system catalog.

## Alternatives Considered

1. **Continue using `@quoter.table()` with identifier quoting** - Would generate `pg_get_serial_sequence("agencies", "id")` which treats arguments as column references rather than string values, causing the function to fail with "column does not exist" error. This was the bug.

2. **Use raw unquoted strings** - Would generate `pg_get_serial_sequence(agencies, id)` which are bare identifiers that PostgreSQL would interpret differently. Less safe than explicit string literals.

3. **Create a new quoting method** - Unnecessary complexity; existing `@quoter.quote()` method already provided correct string literal quoting.

## Trade-offs

- **Safety vs Simplicity**: Required deep understanding of PostgreSQL's quoting semantics (identifiers vs literals), but using the existing `quote()` method kept the implementation simple.
- **Context-dependent quoting**: Different parts of the SQL statement need different quoting strategies - `FROM "agencies"` uses identifiers (correct), but function arguments need literals (also correct). This increases cognitive load for future maintainers.

## Principles Applied

1. **Type Correctness**: Understand function signatures and pass correct argument types (string literals, not identifiers).
2. **Single Responsibility**: Each quoting method has one job - `table()` for identifiers, `quote()` for string literals.
3. **Semantic Accuracy**: SQL syntax must match PostgreSQL's semantic expectations for each context.
4. **Minimal Change**: Fixed only what was broken, left working code (FROM clause quoting) unchanged.

## Revisit If

- PostgreSQL changes how `pg_get_serial_sequence()` interprets arguments
- A new SQL generation abstraction layer is introduced that handles context-dependent quoting automatically
- Other PostgreSQL functions need similar identifier-vs-literal handling, suggesting a pattern worth generalizing
