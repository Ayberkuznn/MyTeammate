/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('user_stat', (table) => {
    table.increments('log_id').primary();
    table.integer('user_id').unsigned().notNullable().unique()
      .references('user_id').inTable('User')
      .onDelete('CASCADE');
    table.integer('total_matches').defaultTo(0);
    table.integer('matches_attended').defaultTo(0);
    table.integer('no_show').defaultTo(0);
    table.decimal('avg_rating', 3, 2).defaultTo(0);
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTableIfExists('user_stat');
};
