/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('match_archive', (table) => {
    table.increments('id').primary();
    table.integer('match_id').unsigned().notNullable()
      .references('match_id').inTable('Match')
      .onDelete('CASCADE');
    table.string('reason', 30).notNullable().defaultTo('full');
    table.timestamp('archived_at', { useTz: true }).defaultTo(knex.fn.now());
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTableIfExists('match_archive');
};
