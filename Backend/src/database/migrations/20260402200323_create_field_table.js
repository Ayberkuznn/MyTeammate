/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('Field', (table) => {
    table.increments('field_id').primary();
    table.string('field_name').notNullable();
    table.string('city').notNullable();
    table.string('district').notNullable();
    table.text('address').notNullable();
    table.integer('capacity').notNullable();
    table.boolean('has_shower').defaultTo(false);
    table.boolean('has_parking').defaultTo(false);
    table.decimal('locationX', 10, 7);
    table.decimal('locationY', 10, 7);
    table.string('phone_number');
    table.date('created_at').defaultTo(knex.fn.now());
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTableIfExists('Field');
};
