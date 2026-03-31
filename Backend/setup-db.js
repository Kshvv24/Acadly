const mysql = require('mysql2');
const fs = require('fs');
const path = require('path');

// Create connection without database first
const connection = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: ''
});

connection.connect((err) => {
  if (err) {
    console.error('Error connecting to MySQL:', err);
    return;
  }
  console.log('Connected to MySQL server');

  // Read and execute schema
  const schemaPath = path.join(__dirname, 'config', 'schema.sql');
  const schema = fs.readFileSync(schemaPath, 'utf8');

  // Split by semicolon and execute each statement
  const statements = schema.split(';').filter(stmt => stmt.trim().length > 0);

  statements.forEach((statement, index) => {
    connection.query(statement, (err, results) => {
      if (err) {
        console.error(`Error executing statement ${index + 1}:`, err);
      } else {
        console.log(`Statement ${index + 1} executed successfully`);
      }

      // Close connection after last statement
      if (index === statements.length - 1) {
        connection.end();
        console.log('Database setup complete');
      }
    });
  });
});