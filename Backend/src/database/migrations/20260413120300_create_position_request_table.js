/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('Position_request', (table) => {
    table.increments('log_id').primary();
    table.integer('match_id').unsigned().notNullable()
      .references('match_id').inTable('Match')
      .onDelete('CASCADE');
    table.integer('user_id').unsigned().notNullable()
      .references('user_id').inTable('User')
      .onDelete('CASCADE');
    table.string('position_applied').notNullable();
    table.text('massage');
    table.timestamp('applied_at').defaultTo(knex.fn.now());
    table.timestamp('response_at');
    table.integer('status').defaultTo(0); // 0: pending, 1: accepted, 2: rejected
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTableIfExists('Position_request');
};
