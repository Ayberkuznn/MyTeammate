/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('match_participants', (table) => {
    table.increments('log_id').primary();
    table.integer('match_id').unsigned().notNullable()
      .references('match_id').inTable('Match')
      .onDelete('CASCADE');
    table.integer('user_id').unsigned().notNullable()
      .references('user_id').inTable('User')
      .onDelete('CASCADE');
    table.string('position');
    table.string('attendance_status').defaultTo('pending'); // pending, attended, no_show
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTableIfExists('match_participants');
};
