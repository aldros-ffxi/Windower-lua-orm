-- Author: Aldros-FFXI
-- Version: 1.0.0

-- Import the sqlite3 library
local sqlite3 = require("sqlite3")

-- ORM class
local ORM = {}
ORM.__index = ORM

--- Create a new sqlite3 database connection. This object is then used for subsequent calls
-- @param database The path to the database. By default, this is relative to FFXI's exeuction directory.
function ORM.new(database)
    local self = setmetatable({}, ORM)
    self.db = sqlite3.open(database)
    if not self.db then
        error("Failed to open database")
    end
    self.models = {}
    return self
end

--- Closes the ORM's database connection
function ORM:close()
    if self.db then
        self.db:close()
        self.db = nil
    end
end

--- Creates or returns an Model for a given table. This can be called multiple times to create multiple
-- models for each table.
-- @param table_name (Required) Name of the table to use.
-- @param schema (Optional if table exists, Required if new table) Database schema to use. Calling this to create a Model causes it to check if the table exists, creating a Model for the table if it does, otherwise it will create the table using the given schema. If the schema passed differs from the existing schema, then it will print a warning.
function ORM:Table(table_name, schema)
    if not self.models[table_name] then
        if schema then
            -- Create the table if it doesn't exist
            local create_stmt = string.format("CREATE TABLE IF NOT EXISTS %s (%s)", table_name, schema)
            self.db:exec(create_stmt)
            
            -- Define the Model for this table
            self.models[table_name] = function(...)
                return self.Model.new(self.db, table_name, ...)
            end
        else
            error("Schema required for new table")
        end
    elseif schema then
        -- Check if the existing table schema differs
        local check_stmt = string.format("PRAGMA table_info(%s)", table_name)
        local existing_schema = {}
        for row in self.db:nrows(check_stmt) do
            table.insert(existing_schema, row.name .. " " .. row.type)
        end
        local existing_schema_str = table.concat(existing_schema, ", ")

        if existing_schema_str ~= schema then
            print(string.format("Warning: Schema for table '%s' differs from the provided schema.", table_name))
        end
    end
    return self.models[table_name]
end

-- Model class under ORM
ORM.Model = {}
ORM.Model.__index = ORM.Model

--- This is the internal function that returns an instance of a Model for a given table. This shouldn't be called directly.
-- @param db The database connection that is used for backend operations
-- @param table_name The table name this model is targeting
-- @param ... An optional series of rows. These may or may not exist.
function ORM.Model.new(db, table_name, ...)
    local self = setmetatable({}, ORM.Model)
    self.db = db
    self.table_name = table_name
    self.rows = {...}
    self.synced = {} -- Keeps track of rows that match the database
    return self
end

--- Saves rows from a Model into the database.
function ORM.Model:save()
    for _, row in ipairs(self.rows) do
        local columns, values = {}, {}
        for k, v in pairs(row) do
            table.insert(columns, k)
            table.insert(values, string.format("'%s'", v))
        end
        local insert_stmt = string.format(
            "INSERT INTO %s (%s) VALUES (%s)",
            self.table_name,
            table.concat(columns, ", "),
            table.concat(values, ", ")
        )
        self.db:exec(insert_stmt)
    end
    return self
end

--- Drops the existing rows in the model and instead returns the set of rows that are retrieved from the given `expr`
-- @param expr A SQL match expression, which is used to retrieve the set of rows
function ORM.Model:where(expr)
    local rows = {}
    local query = string.format("SELECT * FROM %s WHERE %s", self.table_name, expr)
    for row in self.db:nrows(query) do
        table.insert(rows, row)
    end
    self.rows = rows
    return self
end

--- Adds the rows resulting from retrieving the given `expr` statement to the Model, this is non-destructive unless the rows overlap
-- @param 
function ORM.Model:addwhere(expr)
    local query = string.format("SELECT * FROM %s WHERE %s", self.table_name, expr)
    for row in self.db:nrows(query) do
        table.insert(self.rows, row)
    end
    return self
end

--- Returns a new Model instance containing just the first row from a given Model (if it exists)
function ORM.Model:first()
    if #self.rows > 0 then
        return ORM.Model.new(self.db, self.table_name, self.rows[1])
    else
        return ORM.Model.new(self.db, self.table_name)
    end
end

--- Deletes the given rows from the database, returning the Model with the un-committed rows.
function ORM.Model:delete()
    for _, row in ipairs(self.rows) do
        local conditions = {}
        for k, v in pairs(row) do
            table.insert(conditions, string.format("%s='%s'", k, v))
        end
        local delete_stmt = string.format("DELETE FROM %s WHERE %s", self.table_name, table.concat(conditions, " AND "))
        self.db:exec(delete_stmt)
    end
    return self
end

--- Prints the values of every row the table contains.
function ORM.Model:__tostring()
    local output = {}
    for _, row in ipairs(self.rows) do
        local row_values = {}
        local is_synced = true
        for k, v in pairs(row) do
            local query = string.format("SELECT %s FROM %s WHERE %s='%s'", k, self.table_name, k, v)
            local exists = false
            for _ in self.db:nrows(query) do
                exists = true
                break
            end
            if not exists then
                is_synced = false
                break
            end
            table.insert(row_values, string.format("%s='%s'", k, v))
        end
        table.insert(output, string.format("{%s} (Synced: %s)", table.concat(row_values, ", "), tostring(is_synced)))
    end
    return table.concat(output, "\n")
end

-- Return as a module
return ORM
