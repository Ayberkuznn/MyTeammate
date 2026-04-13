/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('Match_req', (table) => {
    table.increments('log_id').primary();
    table.integer('match_id').unsigned().notNullable()
      .references('match_id').inTable('Match')
      .onDelete('CASCADE');
    table.string('position').notNullable();
    table.integer('req_count').notNullable();
    table.integer('filled_count').defaultTo(0);
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTableIfExists('Match_req');
};
