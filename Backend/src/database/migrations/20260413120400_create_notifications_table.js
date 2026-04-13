/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('Notifications', (table) => {
    table.increments('log_id').primary();
    table.integer('user_id').unsigned().notNullable()
      .references('user_id').inTable('User')
      .onDelete('CASCADE');
    table.integer('notification_type').notNullable();
    table.text('massage');
    table.integer('related_match_id').unsigned()
      .references('match_id').inTable('Match')
      .onDelete('SET NULL');
    table.datetime('created_at').defaultTo(knex.fn.now());
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTableIfExists('Notifications');
};
