/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('Penalty_log', (table) => {
    table.increments('log_id').primary();
    table.integer('user_id').unsigned().notNullable()
      .references('user_id').inTable('User')
      .onDelete('CASCADE');
    table.integer('related_match_id').unsigned().notNullable()
      .references('match_id').inTable('Match')
      .onDelete('CASCADE');
    table.integer('penalty').notNullable();
    table.string('reason');
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTableIfExists('Penalty_log');
};
