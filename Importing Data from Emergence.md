Issues
------
**Problem:**
ENUM fields are escaped differently in PostgreSQL. 

**Sample Error:**
```
2015-07-21T15:20:28.936000+03:00 ERROR Database error 22P02: invalid input value for enum contact_points_class: "Emergence\People\ContactPoint\Email"
```

**Solution:**
Add a single backslash variation for each class type.

To find tables that will need to be altered prior to input, run the following query on the source MySQL server:
```sql
SELECT DISTINCT TABLE_NAME, COLUMN_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE COLUMN_NAME IN ('Class')
        AND TABLE_SCHEMA='<your emergence database>';
```
