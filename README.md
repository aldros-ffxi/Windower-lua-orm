# Lua ORM Framework

This ORM framework provides a simple way to interact with SQLite databases in Lua. It offers functionality to define models, perform CRUD operations, and track synchronization status between in-memory rows and database rows.

## Usage

1. Include the ORM framework in your project:
   ```lua
   local ORM = require("lua-orm")
   -- If you've put this in a libs/ directory, instead use:
   local ORM = require("libs/lua-orm")
   ```

## Features

- Define models for database tables.
- Perform create, read, update, and delete operations.
- Track synchronization status of in-memory rows.
- Supports table schema validation.

## Example Usage

### Initializing the ORM
```lua
local ORM = require("lua-orm")

-- Open or create a database
-- Note that if not specified, the database path is relative to FFXI's execution directory
local addon_path = windower.addon_path:gsub('\\', '/')
local orm = ORM.new(addon_path.."/example.db")
```

### Defining a Table Model
```lua
-- Define a Model for a table with a schema
local Users = orm:Table("users", "id INTEGER PRIMARY KEY, name TEXT, email TEXT")
```

### Loading a Table Model with an existing table
```lua
-- Define a Model for an existing table
local Users = orm:Table("users")
```

### Adding Rows
```lua
-- Add rows to the table
local user1 = Users({id = 1, name = "Alice", email = "alice@example.com"})
local user2 = Users({id = 2, name = "Bob", email = "bob@example.com"})
local multiple_users = Users({id = 3, name = "Carol", email = "carol@example.com"},
                             {id = 4, name = "Dave", email = "dave@example.com"}, ...)

-- Save rows to the database
user1:save()
user2:save()
multiple_users:save()
```

### Querying Rows
```lua
-- Query rows using a WHERE clause
local users = Users():where("name LIKE 'A%'")
print(users)

-- Get the first matching row
local first_user = users:first()
print(first_user)
```

### Deleting Rows
```lua
-- Delete rows from the database
multiple_users:delete()
-- Note this retains the copy in memory, so you could easily re-save them
```

### Tracking Sync Status
```lua
-- Check sync status of rows
local status = users:sync_status()
for _, entry in ipairs(status) do
    print(entry.row, entry.synced)
end
```

### Closing the ORM
```lua
-- Close the database connection
orm:close()
```

## Documentation

### ORM Class

#### `ORM.new(database)`
Creates a new ORM instance.
- **database**: Path to the SQLite database.
- **Returns**: An ORM instance.

#### `ORM:Table(table_name, schema)`
Defines or retrieves a table model.
- **table_name**: Name of the table.
- **schema**: Schema for the table (optional).
- **Returns**: A model for the table.

#### `ORM:close()`
Closes the database connection.

### Model Class

#### `Model.new(db, table_name, ...)`
Internal constructor for the model. Use `ORM:Table()` instead.

#### `Model:save()`
Saves rows to the database, populating incomplete rows with default values.

#### `Model:where(expr)`
Queries rows matching a SQL `WHERE` clause.
- **expr**: SQL WHERE expression.
- **Returns**: The model instance. Note this destroys any previous rows in memory and replaces them.

#### `Model:addwhere(expr)`
Adds rows matching a `WHERE` clause to the existing rows in memory.
- **expr**: SQL WHERE expression.
- **Returns**: The updated model instance.

#### `Model:first()`
Returns a new Model with the first row from the given Model.

#### `Model:delete()`
Deletes the rows in the model from the database.

#### `Model:sync_status()`
Returns the sync status and values of rows in the model.

#### `Model:__tostring()`
Converts the model rows to a string representation showing sync status and values.
This allows you to print(model_instance)

## License

This ORM framework is open-source. Contributions are welcome!

