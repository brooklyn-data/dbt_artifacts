/*
    A passing test whose compiled SQL is over 9,000 characters and contains a
    single quote, a backslash (path\to\file) and newlines.
    assert_previous_build_uploaded_test_execution_details checks that
    test_executions.compiled_sql stores it whole: over 8,000 characters is
    past SQL Server's varchar(8000), and the quote, backslash and newlines
    exercise each adapter's escaping.
    {{ 'x' * 9000 }}
*/
select 1 as failures from (select 2 as two) as foo where 1 = 2 and 'it''s' = 'it''s'
